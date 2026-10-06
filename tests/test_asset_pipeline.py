"""Tests for the optional Blender to Godot asset helper."""

import importlib.util
import json
import os
from pathlib import Path
import shutil
import struct
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "tools" / "asset_pipeline.py"
WORKSPACE = SCRIPT.parent.parent
spec = importlib.util.spec_from_file_location("asset_pipeline", SCRIPT)
pipeline = importlib.util.module_from_spec(spec)
spec.loader.exec_module(pipeline)


class AssetPipelineTests(unittest.TestCase):
    def test_folder_setup_and_source_mapping(self):
        with tempfile.TemporaryDirectory(dir=WORKSPACE) as temporary:
            root = Path(temporary)
            self.assertTrue(root.resolve().is_relative_to(WORKSPACE.resolve()))
            folders = pipeline.create_folders(root, blender=True, godot=False)
            self.assertEqual(len(folders), 4)
            self.assertTrue(all(folder.is_dir() for folder in folders))
            self.assertFalse((root / "assets").exists())
            source = root / "art" / "blender" / "towers" / "toy_tank.blend"
            source.touch()
            self.assertEqual(
                pipeline.export_destination(root, source),
                root / "assets" / "models" / "towers" / "toy_tank.glb",
            )
            bad_source = source.with_name("Toy Tank.blend")
            bad_source.touch()
            with self.assertRaisesRegex(ValueError, "snake_case"):
                pipeline.export_destination(root, bad_source)

    def test_real_blender_export(self):
        blender = os.environ.get("BLENDER_EXE") or shutil.which("blender")
        if not blender:
            self.skipTest("Set BLENDER_EXE or add Blender to PATH for integration test")
        with tempfile.TemporaryDirectory(dir=WORKSPACE) as temporary:
            root = Path(temporary)
            self.assertTrue(root.resolve().is_relative_to(WORKSPACE.resolve()))
            pipeline.create_folders(root, blender=True, godot=True)
            source = root / "art" / "blender" / "props" / "test_cube.blend"
            create = (
                "import bpy; "
                "bpy.ops.object.select_all(action='SELECT'); "
                "bpy.ops.object.delete(); "
                "bpy.ops.mesh.primitive_cube_add(); "
                "bpy.context.object.name='included_cube'; "
                "asset=bpy.context.object; "
                "collection=bpy.data.collections.new('Export'); "
                "bpy.context.scene.collection.children.link(collection); "
                "collection.objects.link(asset); "
                "bpy.ops.mesh.primitive_cube_add(); "
                "bpy.context.object.name='excluded_cube'; "
                f"bpy.ops.wm.save_as_mainfile(filepath={str(source)!r})"
            )
            subprocess.run(
                [blender, "--background", "--factory-startup", "--python-exit-code", "1", "--python-expr", create],
                check=True, capture_output=True, text=True,
            )
            exported, _ = pipeline.export_asset(root, source, blender)
            data = exported.read_bytes()
            self.assertEqual(data[:4], b"glTF")
            self.assertGreater(exported.stat().st_size, 100)
            json_length = struct.unpack_from("<I", data, 12)[0]
            gltf = json.loads(data[20:20 + json_length])
            names = {node.get("name") for node in gltf["nodes"]}
            self.assertIn("included_cube", names)
            self.assertNotIn("excluded_cube", names)


if __name__ == "__main__":
    unittest.main()
