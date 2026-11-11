# Voice recording processor

This separate, local tool splits recordings into reviewable takes. It never changes the source files. It uses FFmpeg silence detection and the English faster-whisper model; recognition and category suggestions can be wrong, especially for shouting or nonverbal sounds. Listen to every clip and check for missed phrases or false splits.

## Setup (Windows PowerShell)

Install Python 3.13 and FFmpeg (both `ffmpeg` and `ffprobe`) and make them available on PATH. Create an environment and install the Python dependency from the repository root:

```powershell
python -m venv .venv-voices
.\.venv-voices\Scripts\Activate.ps1
python -m pip install -r tools/voice_processor/requirements.txt
ffmpeg -version
ffprobe -version
```

The first analysis downloads the selected Whisper model from Hugging Face; subsequent runs use its local cache. No API key or paid service is used. CPU and int8 inference are used by default. `--model tiny.en` is faster, while the default `small.en` is generally more accurate. Allow time and disk space for the download.

## Workflow

Run from the repository root. Assign one speaker to each recording or directory; analyze mixed-speaker sessions separately.

```powershell
python tools/voice_processor/process_voices.py analyze sound/raw/reaching_objective_1.m4a --speaker attacker
python tools/voice_processor/process_voices.py analyze sound/raw/losing.m4a --speaker defender
python tools/voice_processor/process_voices.py review
python tools/voice_processor/process_voices.py export
```

After running `review`, leave that PowerShell window open and visit **http://127.0.0.1:8765/** in your browser. Do not open `review.html` directly: the local server supplies the manifest and audio. If you specify `--port`, use the address printed by the command instead. Save each edited row, then stop the server with Ctrl+C. Export reads the same manifest without transcription. It writes mono 44.1 kHz 16-bit WAVs to `assets/audio/voices/<speaker>/<category>/`. `--output` changes that destination. Files are numbered without overwriting unrelated files; re-export updates the same clip's file. Changing a clip's destination or filename creates a new output and leaves the old one for you to remove if desired.

Only clips saved as **accepted** are exported. **Rejected** and **needs_review** clips remain in the manifest but are skipped. Older `reviewed` entries also need an explicit acceptance. Rejecting a clip does not delete any file exported in an earlier run.

The game loads exported WAVs in `assets/audio/voices/attacker/objective_reached/` when a battle starts. Godot must import newly exported files (open or refocus the project in the editor) before testing or exporting the game. A random clip can play when an enemy reaches the objective, with at least five seconds between starts and no overlapping voice clips. If the folder is empty, the game simply plays no voice reaction.

If one clip contains several phrases, play it and pause between phrases. Use **Add current time** for each boundary, in increasing order, then **Split clip**. Times are relative to the displayed clip. The original segment remains on disk; its manifest entry is replaced by the new segments, which start with blank transcriptions and need review. Type each phrase during review, or stop the server and run `retry-transcription` to suggest text for the new segments before reopening review. Splitting does not update or remove an output exported previously.

For automatic suggestions on an existing clip, set **Silence threshold** and **Minimum pause**, then select **Suggest cuts**. The proposed times appear in the split field; listen, adjust them if needed, and select **Split clip** to apply them. A higher threshold (for example -40 instead of -52 dB) treats quieter sounds as silence; a shorter pause detects briefer gaps but can split between words. The wide slider seeks within the clip. For new recordings, `analyze --threshold -40 --pause 0.3` sets the same values; omit `--threshold` for the automatic level. Longer pauses between takes make detection easier.

To undo a cut, use **Merge these two clips** between the two labelled cards. This appears for consecutive clips whose timestamps touch in the same recording. Save other edits first: merging reloads the page. The merged clip combines the saved transcriptions, keeps the first speaker, and returns to `needs_review` with an unidentified category and filename so you can check it. The source segments remain on disk; previously exported files are not removed.

The default `voice_work/manifest.json` and `voice_work/segments/` are your editable review record and unprocessed, padded PCM segments. Back up the whole workspace together; segment paths are absolute, so update them in the manifest if moving it. `--workspace` before the command selects a different workspace. Keep your original recordings as well. The content hash prevents duplicate analysis of the same recording, even under a different name; use a fresh workspace if you want to analyze it again with different settings. Each completed recording is saved before the next one begins.

If transcription failed or returned no text, `python tools/voice_processor/process_voices.py retry-transcription` retries unreviewed clips with empty transcriptions using their saved segments. It keeps manually chosen categories and filenames. Mark an intentionally blank clip as reviewed to exclude it from retries.

Silence detection adapts its threshold to the recording's mean level. `--pause 0.8` keeps longer gaps within a phrase; a shorter value splits more readily. Around 100 ms is retained at detected boundaries. Background noise and changing levels can still cause missed or extra segments; inspect results and re-record or adjust settings where needed. No noise reduction is applied. Export uses FFmpeg loudness normalization with a true-peak ceiling; `--loudness -23` changes its target and `--highpass` enables an 80 Hz rumble filter. Normalization changes relative loudness between takes, so listen for expression.

Edit `phrases.json` or supply `analyze --mapping path/to/mapping.json` to change category suggestions. Each rule has a `phrase`, a `category`, and optionally a `speaker`. Similar phrase matching helps with small transcription differences; ambiguous or weak matches go to `unidentified`. General reactions such as “gotcha” and “woohoo” are deliberately left unidentified because they can fit several events. The filename is a suggestion: edit it to group equivalent takes under the same base name. Empty transcriptions are retained as unidentified.

Run the focused tests with `python -m unittest discover -s tests -p test_voice_processor.py`.
