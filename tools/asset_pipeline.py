"""Create asset folders and export Blender sources for this Godot project."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import queue
import re
import shutil
import subprocess
import sys
import tempfile
import threading


CATEGORIES = ("towers", "units", "props", "environment")
DEFAULT_ROOT = Path(__file__).resolve().parent.parent
EXPORT_SCRIPT = Path(__file__).with_name("blender_export.py")
ASSET_NAME = re.compile(r"^[a-z][a-z0-9_]*$")


def project_root(value: str | Path) -> Path:
    root = Path(value).expanduser().resolve()
    if not root.is_dir():
        raise ValueError(f"Project directory does not exist: {root}")
    return root


def create_folders(root: Path, blender: bool, godot: bool) -> list[Path]:
    folders = []
    for category in CATEGORIES:
        if blender:
            folders.append(root / "art" / "blender" / category)
        if godot:
            folders.append(root / "assets" / "models" / category)
    for folder in folders:
        folder.mkdir(parents=True, exist_ok=True)
    return folders


def export_destination(root: Path, source: Path) -> Path:
    source = source.expanduser().resolve()
    if not source.is_file() or source.suffix.lower() != ".blend":
        raise ValueError(f"Choose an existing .blend file: {source}")
    try:
        relative = source.relative_to(root / "art" / "blender")
    except ValueError as exc:
        raise ValueError("Source must be inside art/blender/<category>/") from exc
    if len(relative.parts) < 2 or relative.parts[0] not in CATEGORIES:
        raise ValueError("Source must be inside art/blender/<category>/")
    if not ASSET_NAME.fullmatch(source.stem):
        raise ValueError("Asset filename must use lowercase snake_case and start with a letter")
    return root / "assets" / "models" / relative.parent / (source.stem + ".glb")


def blender_executable(value: str | None) -> str:
    executable = value or shutil.which("blender")
    if not executable:
        raise ValueError("Blender was not found on PATH; provide --blender-exe or select it in the UI")
    if value and not Path(value).is_file() and not shutil.which(value):
        raise ValueError(f"Blender executable not found: {value}")
    return executable


def run_blender(source: Path, executable: str, *script_args: str) -> tuple[int, str]:
    result = subprocess.run(
        [executable, "--background", str(source.resolve()), "--python-exit-code", "1",
         "--python", str(EXPORT_SCRIPT), "--", *script_args],
        capture_output=True, text=True, encoding="utf-8", errors="replace", check=False,
    )
    output = "\n".join(part for part in (result.stdout.strip(), result.stderr.strip()) if part)
    return result.returncode, output


def validate_asset(root: Path, source: Path, blender_exe: str | None = None) -> str:
    export_destination(root, source)  # Apply the same source and naming rules as export.
    executable = blender_executable(blender_exe)
    returncode, output = run_blender(source, executable, "validate")
    if returncode != 0:
        raise RuntimeError(f"Blender validation failed (exit {returncode}).\n{output}")
    return output


def export_asset(root: Path, source: Path, blender_exe: str | None = None,
                 collection: str | None = None, output_name: str | None = None) -> tuple[Path, str]:
    destination = export_destination(root, source)
    if output_name:
        if not ASSET_NAME.fullmatch(output_name):
            raise ValueError("Output name must use lowercase snake_case and start with a letter")
        destination = destination.with_name(output_name + ".glb")
    manifest_destination = destination.with_suffix(".materials.json")
    executable = blender_executable(blender_exe)
    destination.parent.mkdir(parents=True, exist_ok=True)
    # Blender writes a temporary file so a failed export leaves the previous GLB intact.
    fd, temporary_name = tempfile.mkstemp(suffix=".glb", dir=destination.parent)
    os.close(fd)
    temporary = Path(temporary_name)
    manifest_fd, manifest_name = tempfile.mkstemp(suffix=".materials.json", dir=destination.parent)
    os.close(manifest_fd)
    temporary_manifest = Path(manifest_name)
    try:
        script_args = ["export", str(temporary), str(temporary_manifest)]
        if collection:
            script_args.extend(("--collection", collection))
        returncode, output = run_blender(source, executable, *script_args)
        if (returncode != 0 or temporary.stat().st_size == 0
                or temporary_manifest.stat().st_size == 0):
            raise RuntimeError(f"Blender export failed (exit {returncode}).\n{output}")
        with temporary_manifest.open(encoding="utf-8") as manifest_file:
            json.load(manifest_file)
        temporary.replace(destination)
        temporary_manifest.replace(manifest_destination)
        output += f"\nMaterial manifest: {manifest_destination}"
        return destination, output
    finally:
        temporary.unlink(missing_ok=True)
        temporary_manifest.unlink(missing_ok=True)


def run_gui(initial_root: Path) -> None:
    import tkinter as tk
    from tkinter import filedialog, messagebox, scrolledtext, ttk

    window = tk.Tk()
    window.title("Blender → Godot assets")
    window.resizable(True, True)
    frame = ttk.Frame(window, padding=12)
    frame.grid(sticky="nsew")
    window.columnconfigure(0, weight=1)
    window.rowconfigure(0, weight=1)
    frame.columnconfigure(1, weight=1)

    root_text = tk.StringVar(value=str(initial_root))
    source_text = tk.StringVar()
    blender_text = tk.StringVar(value=shutil.which("blender") or "")
    make_blender = tk.BooleanVar(value=True)
    make_godot = tk.BooleanVar(value=True)
    events: queue.Queue[tuple[bool, str]] = queue.Queue()

    def add_row(row: int, label: str, variable: tk.StringVar, browse) -> None:
        ttk.Label(frame, text=label).grid(row=row, column=0, sticky="w", pady=3)
        ttk.Entry(frame, textvariable=variable).grid(row=row, column=1, sticky="ew", padx=6)
        ttk.Button(frame, text="Browse…", command=browse).grid(row=row, column=2)

    def choose_root() -> None:
        chosen = filedialog.askdirectory(initialdir=root_text.get())
        if chosen:
            root_text.set(chosen)

    def choose_source() -> None:
        chosen = filedialog.askopenfilename(initialdir=root_text.get(), filetypes=[("Blender files", "*.blend")])
        if chosen:
            source_text.set(chosen)

    def choose_blender() -> None:
        chosen = filedialog.askopenfilename(filetypes=[("Executable", "*.exe"), ("All files", "*")])
        if chosen:
            blender_text.set(chosen)

    add_row(0, "Project root", root_text, choose_root)
    add_row(1, "Blender file", source_text, choose_source)
    add_row(2, "Blender executable", blender_text, choose_blender)
    ttk.Checkbutton(frame, text="Blender source folders", variable=make_blender).grid(row=3, column=0, columnspan=2, sticky="w")
    ttk.Checkbutton(frame, text="Godot model folders", variable=make_godot).grid(row=4, column=0, columnspan=2, sticky="w")

    log = scrolledtext.ScrolledText(frame, width=78, height=12, state="disabled")
    log.grid(row=6, column=0, columnspan=3, sticky="nsew", pady=(8, 0))
    frame.rowconfigure(6, weight=1)

    def write(message: str) -> None:
        log.configure(state="normal")
        log.insert("end", message + "\n")
        log.see("end")
        log.configure(state="disabled")

    def initialize() -> None:
        try:
            if not (make_blender.get() or make_godot.get()):
                raise ValueError("Select at least one folder group")
            folders = create_folders(project_root(root_text.get()), make_blender.get(), make_godot.get())
            write("Folders ready:\n" + "\n".join(str(path) for path in folders))
        except (OSError, ValueError) as exc:
            messagebox.showerror("Folder setup failed", str(exc))

    def finish_export() -> None:
        try:
            success, message = events.get_nowait()
        except queue.Empty:
            window.after(100, finish_export)
            return
        export_button.configure(state="normal")
        validate_button.configure(state="normal")
        write(message)
        if not success:
            messagebox.showerror("Asset check failed", message)

    def start_job(export: bool) -> None:
        try:
            root = project_root(root_text.get())
            source = Path(source_text.get())
            export_destination(root, source)
            executable = blender_executable(blender_text.get().strip() or None)
        except (OSError, ValueError) as exc:
            messagebox.showerror("Asset check failed", str(exc))
            return
        export_button.configure(state="disabled")
        validate_button.configure(state="disabled")
        write(f"{'Exporting' if export else 'Validating'} {source}…")

        def worker() -> None:
            try:
                if export:
                    destination, output = export_asset(root, source, executable)
                    events.put((True, f"Exported: {destination}\n{output}"))
                else:
                    events.put((True, validate_asset(root, source, executable)))
            except (OSError, ValueError, RuntimeError) as exc:
                events.put((False, str(exc)))

        threading.Thread(target=worker, daemon=True).start()
        window.after(100, finish_export)

    ttk.Button(frame, text="Create folders", command=initialize).grid(row=5, column=0, sticky="w", pady=(8, 0))
    validate_button = ttk.Button(frame, text="Validate asset", command=lambda: start_job(False))
    validate_button.grid(row=5, column=1, sticky="e", pady=(8, 0))
    export_button = ttk.Button(frame, text="Export asset", command=lambda: start_job(True))
    export_button.grid(row=5, column=2, sticky="e", pady=(8, 0))
    window.mainloop()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=DEFAULT_ROOT, help="Godot project root (default: this repository)")
    subcommands = parser.add_subparsers(dest="command", required=True)
    initialize = subcommands.add_parser("init", help="Create source and/or model folders")
    initialize.add_argument("--blender", action="store_true", help="Create only Blender folders unless --godot is also set")
    initialize.add_argument("--godot", action="store_true", help="Create only Godot folders unless --blender is also set")
    export = subcommands.add_parser("export", help="Export one .blend file to its matching .glb")
    export.add_argument("source", type=Path)
    export.add_argument("--blender-exe", help="Blender executable path if it is not on PATH")
    export.add_argument("--collection", help="Export this Blender collection, including hidden objects")
    export.add_argument("--output-name", help="GLB filename without extension (for collection variants)")
    validate = subcommands.add_parser("validate", help="Check one .blend file without exporting")
    validate.add_argument("source", type=Path)
    validate.add_argument("--blender-exe", help="Blender executable path if it is not on PATH")
    subcommands.add_parser("gui", help="Open the desktop window")
    args = parser.parse_args()
    try:
        root = project_root(args.root)
        if args.command == "init":
            folders = create_folders(root, args.blender or not args.godot, args.godot or not args.blender)
            for folder in folders:
                print(folder)
        elif args.command == "export":
            destination, output = export_asset(root, args.source, args.blender_exe,
                                               args.collection, args.output_name)
            if output:
                print(output)
            print(f"Exported: {destination}")
        elif args.command == "validate":
            print(validate_asset(root, args.source, args.blender_exe))
        else:
            run_gui(root)
    except (OSError, ValueError, RuntimeError) as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
