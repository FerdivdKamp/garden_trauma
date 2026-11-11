"""List or export the tower and unit models recorded in model_exports.json."""

import argparse
import json
from pathlib import Path
import sys

from asset_pipeline import ASSET_NAME, DEFAULT_ROOT, export_asset, export_destination


MANIFEST = Path(__file__).with_name("model_exports.json")


def load_models(path: Path) -> list[dict]:
    with path.open(encoding="utf-8") as file:
        data = json.load(file)
    models = data.get("models")
    if not isinstance(models, list):
        raise ValueError("Manifest must contain a models list")
    seen = set()
    destinations = set()
    for model in models:
        if not isinstance(model, dict):
            raise ValueError("Each model must be an object")
        kind, model_id, status = (model.get(key) for key in ("kind", "id", "status"))
        if kind not in ("tower", "unit") or not isinstance(model_id, str) or not model_id:
            raise ValueError("Each model needs a tower/unit kind and a non-empty id")
        if (kind, model_id) in seen:
            raise ValueError(f"Duplicate model: {kind}/{model_id}")
        seen.add((kind, model_id))
        if status not in ("active", "candidate", "placeholder"):
            raise ValueError(f"Invalid status for {kind}/{model_id}")
        exports = model.get("exports")
        source = model.get("source")
        if not isinstance(exports, list) or (status == "active" and (not isinstance(source, str) or not exports)):
            raise ValueError(f"Invalid source or exports for {kind}/{model_id}")
        if status != "active" and exports:
            raise ValueError(f"Only active models may have exports: {kind}/{model_id}")
        for item in exports:
            if not isinstance(item, dict) or set(item) - {"collection", "output_name"}:
                raise ValueError(f"Invalid export options for {kind}/{model_id}")
            if any(not isinstance(value, str) or not value for value in item.values()):
                raise ValueError(f"Export options must be non-empty strings: {kind}/{model_id}")
            if "output_name" in item and not ASSET_NAME.fullmatch(item["output_name"]):
                raise ValueError(f"Invalid output name for {kind}/{model_id}")
            destination = export_destination(DEFAULT_ROOT, DEFAULT_ROOT / source)
            if item.get("output_name"):
                destination = destination.with_name(item["output_name"] + ".glb")
            if destination in destinations:
                raise ValueError(f"Duplicate output: {destination}")
            destinations.add(destination)
    return models


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("list", "export"))
    parser.add_argument("--kind", choices=("tower", "unit"), help="Limit to one category")
    parser.add_argument("--id", help="Limit to one model ID")
    parser.add_argument("--blender-exe", help="Blender executable if it is not on PATH")
    args = parser.parse_args()
    try:
        models = load_models(MANIFEST)
        selected = [model for model in models if (not args.kind or model["kind"] == args.kind)
                    and (not args.id or model["id"] == args.id)]
        if not selected:
            raise ValueError("No models match the requested filters")
        failures = 0
        count = 0
        for model in selected:
            label = f'{model["kind"]}/{model["id"]}'
            print(f'{label}: {model["status"]} | {model["source"] or "no Blender source"}', flush=True)
            print(f'  {model["note"]}', flush=True)
            if args.action == "list" or model["status"] != "active":
                for item in model["exports"]:
                    print(f'  collection={item.get("collection", "default")} output={item.get("output_name", "source filename")}', flush=True)
                continue
            for item in model["exports"]:
                try:
                    destination, output = export_asset(DEFAULT_ROOT, DEFAULT_ROOT / model["source"],
                                                       args.blender_exe, item.get("collection"), item.get("output_name"))
                    print(output)
                    print(f"  Exported: {destination}", flush=True)
                    count += 1
                except (OSError, ValueError, RuntimeError) as exc:
                    print(f"  FAILED {label} {item}: {exc}", file=sys.stderr, flush=True)
                    failures += 1
        if args.action == "export":
            print(f"Exported {count} GLB(s); {failures} failed. Candidates and placeholders were skipped.")
            if count == 0 and failures == 0:
                print("No active exports matched; nothing was written.")
        return 1 if failures else 0
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
