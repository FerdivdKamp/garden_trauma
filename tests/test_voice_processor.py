import importlib.util
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location("voices", Path(__file__).resolve().parents[1] / "tools/voice_processor/process_voices.py")
voices = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(voices)


class VoiceProcessorTests(unittest.TestCase):
    def test_segmentation_keeps_short_pauses_and_pads(self):
        self.assertEqual(voices.regions(5, [(0, 1), (2, 2.2), (3, 4)]), [(0.9, 3.1), (3.9, 5)])
        self.assertEqual(voices.regions(2, [(0, 2)]), [])

    def test_names(self):
        self.assertEqual(voices.slug("That's in!"), "thats_in")
        self.assertEqual(voices.slug("!!!"), "unidentified")

    def test_classification_and_ambiguity(self):
        rules = [{"phrase": "get in there", "category": "objective_reached", "speaker": "attacker"}, {"phrase": "get in there", "category": "attacker_victory", "speaker": "defender"}]
        self.assertEqual(voices.classify("Get in there!", "attacker", rules)[0], "objective_reached")
        self.assertEqual(voices.classify("something else", "attacker", rules)[0], "unidentified")
        rules.append({"phrase": "get in there", "category": "attacker_victory"})
        self.assertEqual(voices.classify("get in there", "attacker", rules)[0], "unidentified")

    def test_manifest_round_trip_and_validation(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "work" / "manifest.json"
            data = voices.load_manifest(path)
            data["clips"].append({"id": "one", "transcription": "hello"})
            voices.save_manifest(path, data)
            self.assertEqual(voices.load_manifest(path), data)
            path.write_text('{"version": 2, "clips": []}')
            with self.assertRaises(ValueError):
                voices.load_manifest(path)

    def test_export_does_not_overwrite_existing_files_and_reuses_own_name(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            folder = root / "output" / "attacker" / "objective_reached"
            folder.mkdir(parents=True)
            (folder / "gotcha_01.wav").write_bytes(b"existing")
            clip = {"speaker": "attacker", "category": "objective_reached", "filename": "gotcha", "segment": "raw.wav", "output_path": "", "review_status": "accepted"}
            data = {"version": 1, "clips": [clip]}
            args = SimpleNamespace(output=root / "output", highpass=False, loudness=-20)
            def fake_ffmpeg(command):
                Path(command[-1]).write_bytes(b"processed")
            with patch.object(voices, "run", side_effect=fake_ffmpeg):
                voices.export(args, root / "manifest.json", data)
                voices.export(args, root / "manifest.json", data)
            self.assertEqual((folder / "gotcha_01.wav").read_bytes(), b"existing")
            self.assertEqual(Path(clip["output_path"]).name, "gotcha_02.wav")
            self.assertFalse((folder / "gotcha_03.wav").exists())

    def test_split_retains_source_and_creates_unreviewed_children(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "segments").mkdir()
            original = root / "segments" / "original.wav"
            original.write_bytes(b"original")
            clip = {"id": "original", "start": 10.0, "end": 14.0, "segment": str(original), "speaker": "attacker", "transcription": "several lines", "category": "other", "filename": "old", "confidence": 1, "review_status": "accepted", "output_path": ""}
            data = {"version": 1, "clips": [clip]}
            with patch.object(voices, "run", side_effect=lambda cmd: Path(cmd[-1]).write_bytes(b"part")):
                voices.split_clip(root / "manifest.json", data, clip, [1.5, 3])
            self.assertEqual([(c["start"], c["end"]) for c in data["clips"]], [(10, 11.5), (11.5, 13), (13, 14)])
            self.assertTrue(all(c["review_status"] == "needs_review" and not c["transcription"] for c in data["clips"]))
            self.assertEqual(original.read_bytes(), b"original")

    def test_merge_only_touching_neighbors_and_preserves_segments(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "segments").mkdir()
            first_path = root / "segments" / "first.wav"
            second_path = root / "segments" / "second.wav"
            first_path.write_bytes(b"first")
            second_path.write_bytes(b"second")
            first = {"id": "first", "source_id": "same", "start": 1.0, "end": 2.0, "segment": str(first_path), "speaker": "attacker", "transcription": "Get", "category": "other", "filename": "get", "confidence": 1, "review_status": "accepted", "output_path": ""}
            second = {**first, "id": "second", "start": 2.0, "end": 3.0, "segment": str(second_path), "transcription": "in!"}
            data = {"version": 1, "clips": [first, second]}
            with self.assertRaises(ValueError):
                voices.merge_clips(root / "manifest.json", data, first, "wrong")
            self.assertFalse(voices.can_merge(first, {**second, "start": 2.5}))
            with patch.object(voices, "run", side_effect=lambda cmd: Path(cmd[-1]).write_bytes(b"merged")):
                voices.merge_clips(root / "manifest.json", data, first, "second")
            self.assertEqual(len(data["clips"]), 1)
            merged = data["clips"][0]
            self.assertEqual((merged["start"], merged["end"], merged["transcription"], merged["review_status"]), (1.0, 3.0, "Get in!", "needs_review"))
            self.assertEqual(first_path.read_bytes(), b"first")
            self.assertEqual(second_path.read_bytes(), b"second")
            self.assertEqual(voices.load_manifest(root / "manifest.json"), data)


if __name__ == "__main__":
    unittest.main()
