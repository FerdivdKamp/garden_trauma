"""Checks for the tower and unit export inventory and batch selection."""

import contextlib
import io
import json
from pathlib import Path
import sys
import unittest
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import export_models


class ModelExportTests(unittest.TestCase):
    def test_inventory_covers_game_definitions(self):
        models = export_models.load_models(export_models.MANIFEST)
        for kind, folder in (("tower", "towers"), ("unit", "units")):
            expected = {json.loads(path.read_text(encoding="utf-8"))["id"]
                        for path in (ROOT / "data" / folder).glob("*.json")}
            self.assertEqual(expected, {model["id"] for model in models if model["kind"] == kind})

    def test_batch_exports_only_active_entries_and_continues_after_failure(self):
        calls = []

        def fake_export(root, source, executable, collection, output_name):
            calls.append((source.name, collection, output_name))
            if collection == "tower_laser_mk2":
                raise RuntimeError("test failure")
            return root / "output.glb", "ok"

        with mock.patch.object(sys, "argv", ["export_models.py", "export"]), \
             mock.patch.object(export_models, "export_asset", side_effect=fake_export), \
             contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            result = export_models.main()
        self.assertEqual(result, 1)
        self.assertEqual(len(calls), 6)
        self.assertEqual(calls[-2:], [("robot.blend", None, None), ("race_car.blend", None, None)])
        self.assertEqual([call[1] for call in calls[:4]],
                         [f"tower_laser_mk{number}" for number in range(1, 5)])


if __name__ == "__main__":
    unittest.main()
