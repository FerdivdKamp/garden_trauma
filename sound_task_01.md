# Garden Defense — Voice Recording Processor

Build a Python-based tool to process voice recordings for my Godot 4 tower-defense game, Garden Defense.

## Context

The game features two kids playing against each other with toy soldiers, tanks, and towers in a garden.

- **Attacker:** A playful, cheeky kid celebrating when units reach the objective.
- **Defender:** A competitive kid celebrating victories, reacting to defeats, and destroying enemy units.

I will record one or more long audio files containing many short voice lines, potentially with multiple takes of the same phrase.

The recordings may contain phrases such as:
- "Gotcha!"
- "That's in!"
- "Get in there!"
- "POW!"
- "Woohoo!"
- "Nanana-na-naaa!"
- "I'll get you next time!"
- "Oh, come on!"

The recordings won't necessarily follow a predefined order.

## Goal

Automatically turn these recordings into separate, correctly named WAV files, ready for import into Godot.

## Requirements

### 1. Audio segmentation

- Accept WAV, MP3, M4A, and FLAC recordings.
- Detect individual spoken phrases using silence detection or voice activity detection (VAD).
- Avoid splitting phrases at brief pauses between words.
- Preserve approximately 100 ms of padding around each phrase.
- Handle variations in recording volume.
- Never modify the original recordings.

### 2. Speech recognition

Use a locally running speech recognition model, preferably faster-whisper.

- Transcribe each detected phrase.
- Support English.
- Recognize repeated takes of the same phrase.
- Handle expressive speech, shouting, and playful vocalizations as well as possible.
- Do not discard clips when transcription fails. Mark them as unidentified instead.

### 3. Automatic classification

Classify clips into game events based on their transcription and context.

Suggested categories:
- `objective_reached`
- `attacker_victory`
- `attacker_defeat`
- `defender_victory`
- `defender_defeat`
- `tower_attack`
- `enemy_destroyed`
- `wave_start`
- `other`
- `unidentified`

Allow the user to specify the speaker (attacker or defender) per input recording.

Use a configurable phrase-to-category mapping. Avoid relying on exact text matches only.

When classification is uncertain, put the clip in `unidentified` rather than guessing.

### 4. Naming and organization

Produce a directory structure such as:

audio/voices/
  attacker/
    objective_reached/
      gotcha_01.wav
      gotcha_02.wav
      thats_in_01.wav
    attacker_victory/
      nananana_01.wav
  defender/
    defender_victory/
      woohoo_01.wav
    defender_defeat/
      ill_get_you_next_time_01.wav

- Use lowercase snake_case filenames.
- Group repeated takes with numbered suffixes.
- Prevent filename collisions.
- Preserve the association between each clip and its original recording.

### 5. Audio processing

- Remove unnecessary leading and trailing silence.
- Apply configurable loudness normalization, preserving relative expression where possible.
- Avoid clipping.
- Optionally apply a high-pass filter to remove low-frequency rumble.
- Do not apply aggressive noise reduction by default.
- Export mono, 44.1 kHz, 16-bit PCM WAV files.

Keep the original audio segments available so processing can be adjusted later without re-recording.

### 6. Review and correction

Generate a review manifest in CSV or JSON containing:

- Source recording
- Start and end timestamps
- Detected transcription
- Speaker
- Suggested category
- Suggested filename
- Classification confidence or review status
- Output path

Allow me to edit the manifest and rerun the export without repeating transcription.

Provide a simple way to listen to individual clips during review, preferably a locally hosted web interface with audio playback, editable transcription, category, speaker, and filename.

Keep the interface lightweight.

### 7. Command-line interface

Provide commands similar to:

```bash
python process_voices.py analyze recordings/ --speaker attacker
python process_voices.py review
python process_voices.py export
```

Support processing multiple recordings and adding new recordings later without losing previous work.

### 8. Implementation

- Python 3.13, if supported by the chosen dependencies.
- FFmpeg for audio conversion and processing.
- faster-whisper for local speech recognition.
- A suitable VAD library or FFmpeg silence detection.
- No paid cloud services or API keys.
- Windows-compatible.
- Include installation instructions and dependency management.
- Add unit tests for segmentation, naming, categorization, and manifest handling.

## Development approach

First inspect the existing repository structure and conventions.

Propose a concise implementation plan before writing code. Prefer a simple, maintainable architecture over unnecessary complexity.

Implement the workflow incrementally, starting with segmentation, transcription, and manifest generation. Add the review interface after the core processing works.

The final result should let me record a long session of improvised voice lines, run the processor, quickly review any mistakes, and export clean, individually named audio assets for Godot.

Here are the raw example sounds files: `sound\raw`