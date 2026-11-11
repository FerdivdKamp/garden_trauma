"""Turn long recordings into reviewable, locally transcribed voice clips."""
import argparse
import hashlib
import json
import re
import subprocess
import sys
import uuid
from difflib import SequenceMatcher
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parent
CATEGORIES = ("objective_reached", "attacker_victory", "attacker_defeat", "defender_victory", "defender_defeat", "tower_attack", "enemy_destroyed", "wave_start", "other", "unidentified")
SPEAKERS = ("attacker", "defender")
FORMATS = {".wav", ".mp3", ".m4a", ".flac"}


def run(args):
    try:
        return subprocess.run(args, check=True, capture_output=True, text=True, encoding="utf-8", errors="replace")
    except FileNotFoundError as exc:
        raise RuntimeError(f"{args[0]} was not found. Install FFmpeg and add it to PATH.") from exc
    except subprocess.CalledProcessError as exc:
        raise RuntimeError(f"{args[0]} failed: {exc.stderr[-2000:]}") from exc


def slug(text):
    value = re.sub(r"[^a-z0-9]+", "_", text.lower().replace("'", ""))
    return value.strip("_")[:60].rstrip("_") or "unidentified"


def classify(text, speaker, mapping):
    normalized = slug(text).replace("_", " ")
    if not normalized or normalized == "unidentified":
        return "unidentified", 0.0
    scores = {}
    for rule in mapping:
        if rule.get("speaker") not in (None, speaker):
            continue
        phrase = slug(rule["phrase"]).replace("_", " ")
        score = SequenceMatcher(None, normalized, phrase).ratio()
        if re.search(r"(?<!\w)" + re.escape(phrase) + r"(?!\w)", normalized):
            score = max(score, 0.9)
        category = rule["category"]
        scores[category] = max(scores.get(category, 0), score)
    ranked = sorted(scores.items(), key=lambda item: item[1], reverse=True)
    if not ranked or ranked[0][1] < 0.82 or (len(ranked) > 1 and ranked[0][1] - ranked[1][1] < 0.12):
        return "unidentified", round(ranked[0][1], 2) if ranked else 0.0
    return ranked[0][0], round(ranked[0][1], 2)


def regions(duration, silences, padding=0.1, min_silence=0.65):
    """Only long pauses divide phrases; padding never extends past the source."""
    result, start = [], 0.0
    for left, right in silences:
        if right - left < min_silence:
            continue
        if left > start:
            result.append((max(0.0, start - padding), min(duration, left + padding)))
        start = max(start, right)
    if start < duration:
        result.append((max(0.0, start - padding), duration))
    return [(round(a, 3), round(b, 3)) for a, b in result if b - a >= 0.15]


def detect(source, pause, threshold=None):
    duration = float(run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "default=noprint_wrappers=1:nokey=1", str(source)]).stdout.strip())
    if threshold is None:
        volume = run(["ffmpeg", "-hide_banner", "-i", str(source), "-af", "volumedetect", "-f", "null", "-"]).stderr
        match = re.search(r"mean_volume:\s*(-?[\d.]+) dB", volume)
        threshold = max(-55.0, min(-25.0, (float(match.group(1)) - 16) if match else -40.0))
    log = run(["ffmpeg", "-hide_banner", "-i", str(source), "-af", f"silencedetect=noise={threshold}dB:d={pause}", "-f", "null", "-"]).stderr
    events = re.findall(r"silence_(start|end):\s*([\d.]+)", log)
    silences, start = [], None
    for kind, value in events:
        if kind == "start":
            start = float(value)
        elif start is not None:
            silences.append((start, float(value)))
            start = None
    if start is not None:
        silences.append((start, duration))
    return regions(duration, silences, min_silence=pause)


def load_manifest(path):
    if not path.exists():
        return {"version": 1, "clips": []}
    data = json.loads(path.read_text(encoding="utf-8"))
    if data.get("version") != 1 or not isinstance(data.get("clips"), list):
        raise ValueError("Unsupported or invalid manifest")
    return data


def save_manifest(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(".tmp")
    temporary.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    temporary.replace(path)


def transcribe_clip(model, path):
    # Decode with the same FFmpeg installation used for segmentation. Passing
    # samples avoids depending on PyAV's version-specific decoding API.
    import numpy as np
    try:
        audio = subprocess.run(["ffmpeg", "-nostdin", "-v", "error", "-i", str(path), "-f", "f32le", "-ac", "1", "-ar", "16000", "-"], check=True, capture_output=True).stdout
    except subprocess.CalledProcessError as exc:
        raise RuntimeError(exc.stderr.decode("utf-8", errors="replace")) from exc
    segments, _ = model.transcribe(np.frombuffer(audio, dtype="<f4"), language="en", beam_size=5, condition_on_previous_text=False)
    return " ".join(s.text.strip() for s in segments).strip()


def analyze(args, manifest, data):
    try:
        from faster_whisper import WhisperModel
    except ImportError as exc:
        raise RuntimeError("Install faster-whisper using the instructions in README.md.") from exc
    source = Path(args.input).resolve()
    files = sorted(p for p in (source.rglob("*") if source.is_dir() else [source]) if p.is_file() and p.suffix.lower() in FORMATS)
    if not files:
        raise ValueError("No supported recordings found.")
    mapping = json.loads(Path(args.mapping).read_text(encoding="utf-8"))
    existing = {c["source_id"] for c in data["clips"]}
    model = None
    for recording in files:
        digest = hashlib.sha256()
        with recording.open("rb") as stream:
            for chunk in iter(lambda: stream.read(1024 * 1024), b""):
                digest.update(chunk)
        source_id = digest.hexdigest()
        if source_id in existing:
            print(f"Skipping already analyzed recording: {recording}")
            continue
        spans = detect(recording, args.pause, args.threshold)
        if not spans:
            print(f"No phrases detected in {recording}; adjust --pause or check the recording.")
            continue
        if model is None:
            model = WhisperModel(args.model, device="cpu", compute_type="int8")
        new_clips = []
        for index, (start, end) in enumerate(spans, 1):
            clip_id = f"{source_id[:16]}_{index:04d}"
            raw = manifest.parent / "segments" / f"{clip_id}.wav"
            raw.parent.mkdir(parents=True, exist_ok=True)
            run(["ffmpeg", "-nostdin", "-y", "-v", "error", "-ss", str(start), "-i", str(recording), "-t", str(end - start), "-vn", "-c:a", "pcm_s16le", str(raw)])
            try:
                transcript = transcribe_clip(model, raw)
            except Exception as exc:
                print(f"Transcription failed for {clip_id}: {exc}", file=sys.stderr)
                transcript = ""
            category, confidence = classify(transcript, args.speaker, mapping)
            new_clips.append({"id": clip_id, "source_id": source_id, "source": str(recording), "start": start, "end": end, "segment": str(raw.resolve()), "transcription": transcript, "speaker": args.speaker, "category": category, "filename": slug(transcript), "confidence": confidence, "review_status": "needs_review", "output_path": ""})
        data["clips"].extend(new_clips)
        save_manifest(manifest, data)
        existing.add(source_id)
        print(f"Analyzed {recording.name}: {len(new_clips)} clips")


def retry_transcription(args, manifest, data):
    from faster_whisper import WhisperModel
    mapping = json.loads(Path(args.mapping).read_text(encoding="utf-8"))
    candidates = [c for c in data["clips"] if not c.get("transcription") and c.get("review_status") == "needs_review"]
    if not candidates:
        print("No unreviewed clips with empty transcriptions.")
        return
    model = WhisperModel(args.model, device="cpu", compute_type="int8")
    for clip in candidates:
        try:
            transcript = transcribe_clip(model, clip["segment"])
        except Exception as exc:
            print(f"Transcription failed for {clip['id']}: {exc}", file=sys.stderr)
            continue
        clip["transcription"] = transcript
        # Preserve manually entered categories and filenames.
        if clip["category"] == "unidentified":
            clip["category"], clip["confidence"] = classify(transcript, clip["speaker"], mapping)
        if clip["filename"] == "unidentified":
            clip["filename"] = slug(transcript)
        save_manifest(manifest, data)
        print(f"{clip['id']}: {transcript or '(no speech recognized)'}", flush=True)


def validate_clip(clip):
    if clip.get("speaker") not in SPEAKERS or clip.get("category") not in CATEGORIES:
        raise ValueError("Invalid speaker or category")
    if not isinstance(clip.get("filename"), str) or not clip["filename"].strip():
        raise ValueError("Filename must not be empty")


def export(args, manifest, data):
    destination = Path(args.output).resolve()
    for clip in data["clips"]:
        if clip.get("review_status") != "accepted":
            continue
        validate_clip(clip)
        folder = destination / clip["speaker"] / clip["category"]
        folder.mkdir(parents=True, exist_ok=True)
        base = slug(clip["filename"])
        previous = Path(clip["output_path"]) if clip.get("output_path") else None
        # Reuse this clip's own path on re-export, but never overwrite another file.
        if previous and previous.parent == folder and re.fullmatch(re.escape(base) + r"_\d+\.wav", previous.name):
            target = previous
        else:
            number = 1
            while (folder / f"{base}_{number:02d}.wav").exists():
                number += 1
            target = folder / f"{base}_{number:02d}.wav"
        filters = []
        if args.highpass:
            filters.append("highpass=f=80")
        # Peak-limited loudness normalization avoids clipping while retaining dynamics.
        filters.append(f"loudnorm=I={args.loudness}:TP=-1.5:LRA=11")
        temporary = target.with_suffix(".tmp.wav")
        run(["ffmpeg", "-nostdin", "-y", "-v", "error", "-i", clip["segment"], "-af", ",".join(filters), "-ac", "1", "-ar", "44100", "-c:a", "pcm_s16le", str(temporary)])
        temporary.replace(target)
        clip["output_path"] = str(target)
        save_manifest(manifest, data)
        print(target)


def review(manifest, data, port):
    class Handler(BaseHTTPRequestHandler):
        def respond(self, code, content, mime, extra_headers=None):
            self.send_response(code)
            self.send_header("Content-Type", mime)
            self.send_header("Content-Length", str(len(content)))
            for name, value in (extra_headers or {}).items():
                self.send_header(name, value)
            self.end_headers()
            self.wfile.write(content)

        def do_GET(self):
            path = urlparse(self.path).path
            if path == "/":
                self.respond(200, (ROOT / "review.html").read_bytes(), "text/html; charset=utf-8")
            elif path == "/manifest":
                self.respond(200, json.dumps(data).encode(), "application/json")
            elif path.startswith("/audio/"):
                clip = next ( (c for c in data["clips"] if c["id"] == path[7:]), None)
                if clip and Path(clip["segment"]).is_file():
                    content = Path(clip["segment"]).read_bytes()
                    requested = self.headers.get("Range")
                    if requested:
                        match = re.fullmatch(r"bytes=(\d+)-(\d*)", requested)
                        if not match or int(match.group(1)) >= len(content):
                            self.send_response(416)
                            self.send_header("Content-Range", f"bytes */{len(content)}")
                            self.end_headers()
                            return
                        start = int(match.group(1))
                        end = min(int(match.group(2)) if match.group(2) else len(content) - 1, len(content) - 1)
                        if end < start:
                            self.send_error(416)
                            return
                        self.respond(206, content[start:end + 1], "audio/wav", {"Content-Range": f"bytes {start}-{end}/{len(content)}", "Accept-Ranges": "bytes"})
                    else:
                        self.respond(200, content, "audio/wav", {"Accept-Ranges": "bytes"})
                else:
                    self.send_error(404)
            else:
                self.send_error(404)

        def do_POST(self):
            if self.path not in ("/save", "/split", "/detect", "/merge") or self.headers.get("Origin") != f"http://127.0.0.1:{port}":
                self.send_error(403)
                return
            try:
                length = int(self.headers.get("Content-Length", "0"))
                if length > 1000000:
                    raise ValueError("Request too large")
                edit = json.loads(self.rfile.read(length))
                clip = next(c for c in data["clips"] if c["id"] == edit["id"])
                if self.path == "/merge":
                    merge_clips(manifest, data, clip, edit["next_id"])
                    self.respond(200, b"ok", "text/plain")
                    return
                if self.path == "/detect":
                    pause, threshold = float(edit["pause"]), float(edit["threshold"])
                    if not 0.05 <= pause <= 10 or not -100 <= threshold <= 0:
                        raise ValueError("Pause must be 0.05–10 seconds and threshold -100–0 dB")
                    spans = detect(Path(clip["segment"]), pause, threshold)
                    # Cut midway through each detected gap so no recorded audio is lost.
                    cuts = [round((left[1] + right[0]) / 2, 3) for left, right in zip(spans, spans[1:])]
                    self.respond(200, json.dumps({"cuts": cuts}).encode(), "application/json")
                    return
                if self.path == "/split":
                    split_clip(manifest, data, clip, edit["times"])
                    self.respond(200, b"ok", "text/plain")
                    return
                changes = {key: edit[key] for key in ("transcription", "speaker", "category", "filename", "review_status")}
                validate_clip(changes)
                if changes["review_status"] not in ("needs_review", "accepted", "rejected"):
                    raise ValueError("Invalid review status")
                clip.update(changes)
                save_manifest(manifest, data)
                self.respond(200, b"ok", "text/plain")
            except (ValueError, KeyError, StopIteration, OSError, RuntimeError) as exc:
                self.send_error(400, str(exc))

    server = ThreadingHTTPServer(("127.0.0.1", port), Handler)
    print(f"Review at http://127.0.0.1:{port}/ (Ctrl+C to stop)", flush=True)
    server.serve_forever()


def can_merge(first, second):
    return (first["source_id"] == second["source_id"]
            and abs(first["end"] - second["start"]) <= 0.005)


def merge_clips(manifest, data, first, next_id):
    """Join adjacent segments without modifying either original segment."""
    index = data["clips"].index(first)
    if index + 1 >= len(data["clips"]):
        raise ValueError("There is no next clip")
    second = data["clips"][index + 1]
    if second["id"] != next_id or not can_merge(first, second):
        raise ValueError("Clips must be consecutive and touch in the same recording")
    merged_id = f"merge_{uuid.uuid4().hex}"
    segment = manifest.parent / "segments" / f"{merged_id}.wav"
    merged = first.copy()
    merged.update({"id": merged_id, "end": second["end"], "segment": str(segment.resolve()),
                   "transcription": " ".join(c.get("transcription", "").strip() for c in (first, second)).strip(),
                   "category": "unidentified", "filename": "unidentified", "confidence": 0.0,
                   "review_status": "needs_review", "output_path": ""})
    try:
        run(["ffmpeg", "-nostdin", "-y", "-v", "error", "-i", first["segment"], "-i", second["segment"],
             "-filter_complex", "[0:a][1:a]concat=n=2:v=0:a=1[out]", "-map", "[out]", "-c:a", "pcm_s16le", str(segment)])
        updated = {**data, "clips": data["clips"][:index] + [merged] + data["clips"][index + 2:]}
        save_manifest(manifest, updated)
    except Exception:
        segment.unlink(missing_ok=True)
        raise
    data["clips"] = updated["clips"]


def split_clip(manifest, data, clip, times):
    """Split a saved segment at playback times; retain its original WAV on disk."""
    duration = clip["end"] - clip["start"]
    if not isinstance(times, list) or not times:
        raise ValueError("Provide at least one split time")
    cuts = [float(t) for t in times]
    if any(not 0 < t < duration for t in cuts) or cuts != sorted(set(cuts)):
        raise ValueError("Split times must be unique, increasing, and inside the clip")
    boundaries = [0.0, *cuts, duration]
    children = []
    paths = [manifest.parent / "segments" / f"{clip['id']}_s{index:02d}.wav" for index in range(1, len(boundaries))]
    if any(path.exists() for path in paths):
        raise ValueError("A split segment already exists; choose another workspace or remove the abandoned split files")
    generated = []
    try:
        for index, (start, end) in enumerate(zip(boundaries, boundaries[1:]), 1):
            child = clip.copy()
            child_id = f"{clip['id']}_s{index:02d}"
            segment = paths[index - 1]
            generated.append(segment)
            run(["ffmpeg", "-nostdin", "-y", "-v", "error", "-ss", str(start), "-i", clip["segment"], "-t", str(end - start), "-c:a", "pcm_s16le", str(segment)])
            child.update({"id": child_id, "start": round(clip["start"] + start, 3), "end": round(clip["start"] + end, 3), "segment": str(segment.resolve()), "transcription": "", "category": "unidentified", "filename": "unidentified", "confidence": 0.0, "review_status": "needs_review", "output_path": ""})
            children.append(child)
    except Exception:
        for path in generated:
            path.unlink(missing_ok=True)
        raise
    index = data["clips"].index(clip)
    data["clips"][index:index + 1] = children
    save_manifest(manifest, data)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--workspace", default="voice_work", help="manifest and raw segment directory")
    commands = parser.add_subparsers(dest="command", required=True)
    a = commands.add_parser("analyze")
    a.add_argument("input")
    a.add_argument("--speaker", required=True, choices=SPEAKERS)
    a.add_argument("--model", default="small.en")
    a.add_argument("--pause", type=float, default=0.65, help="seconds of silence between phrases")
    a.add_argument("--threshold", type=float, help="silence threshold in dB (default: automatic)")
    a.add_argument("--mapping", default=str(ROOT / "phrases.json"))
    retry = commands.add_parser("retry-transcription", help="retry unreviewed clips with empty transcriptions")
    retry.add_argument("--model", default="small.en")
    retry.add_argument("--mapping", default=str(ROOT / "phrases.json"))
    r = commands.add_parser("review")
    r.add_argument("--port", type=int, default=8765)
    e = commands.add_parser("export")
    e.add_argument("--output", default="assets/audio/voices")
    e.add_argument("--loudness", type=float, default=-20.0, help="target integrated LUFS")
    e.add_argument("--highpass", action="store_true")
    args = parser.parse_args()
    try:
        manifest = Path(args.workspace).resolve() / "manifest.json"
        data = load_manifest(manifest)
        if args.command == "analyze":
            if args.pause <= 0:
                raise ValueError("--pause must be positive")
            if args.threshold is not None and not -100 <= args.threshold <= 0:
                raise ValueError("--threshold must be between -100 and 0 dB")
            analyze(args, manifest, data)
        elif args.command == "retry-transcription":
            retry_transcription(args, manifest, data)
        elif args.command == "review":
            review(manifest, data, args.port)
        else:
            export(args, manifest, data)
    except (ValueError, OSError, RuntimeError) as exc:
        parser.exit(1, f"Error: {exc}\n")
    except KeyboardInterrupt:
        print("\nStopped.")


if __name__ == "__main__":
    main()
