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
            source = root / "art" / "blender" / "towers" / "laser_tower.blend"
            source.touch()
            self.assertEqual(
                pipeline.export_destination(root, source),
                root / "assets" / "models" / "towers" / "laser_tower.glb",
            )
            nested = root / "art" / "blender" / "environment" / "garden" / "tiles" / "tile_grass3.blend"
            nested.parent.mkdir(parents=True)
            nested.touch()
            self.assertEqual(
                pipeline.export_destination(root, nested),
                root / "assets" / "models" / "environment" / "garden" / "tiles" / "tile_grass3.glb",
            )
            bad_source = source.with_name("Laser Tower.blend")
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
                "mesh=bpy.data.meshes.new('tile_mesh'); "
                "mesh.from_pydata([(-1,-1,0),(1,-1,0),(1,1,0),(-1,1,0),"
                "(-1,-1,.25),(1,-1,.25),(1,1,.25),(-1,1,.25),(0,0,.3124)],[],"
                "[(0,3,2,1),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7),"
                "(4,5,8),(5,6,8),(6,7,8),(7,4,8)]); "
                "asset=bpy.data.objects.new('tile_test',mesh); "
                "bpy.context.scene.collection.objects.link(asset); "
                "material=bpy.data.materials.new('GrassTop'); "
                "material.use_nodes=True; "
                "noise=material.node_tree.nodes.new('ShaderNodeTexNoise'); "
                "ramp=material.node_tree.nodes.new('ShaderNodeValToRGB'); "
                "shader=material.node_tree.nodes.get('Principled BSDF'); "
                "material.node_tree.links.new(noise.outputs['Fac'],ramp.inputs['Fac']); "
                "material.node_tree.links.new(ramp.outputs['Color'],shader.inputs['Base Color']); "
                "sides=bpy.data.materials.new('GrassSides'); "
                "sides.use_nodes=True; "
                "mesh.materials.append(sides); "
                "mesh.materials.append(material); "
                "for_face=[setattr(face,'material_index',1) for face in list(mesh.polygons)[5:]]; "
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
            validation = pipeline.validate_asset(root, source, blender)
            self.assertIn("[OK] tile_test: side dimensions (2.0, 2.0, 0.25)", validation)
            self.assertIn("[OK] Material GrassTop: procedural_noise_color_ramp", validation)
            self.assertNotIn("[WARN] tile_test: side dimensions", validation)
            self.assertFalse((root / "assets" / "models" / "props" / "test_cube.glb").exists())
            self.assertFalse((root / "assets" / "models" / "props" / "test_cube.materials.json").exists())
            exported, output = pipeline.export_asset(root, source, blender)
            self.assertIn("[OK] tile_test: side dimensions", output)
            self.assertIn("[WARN] Material GrassTop: procedural nodes", output)
            self.assertIn("[OK] Material GrassTop: procedural_noise_color_ramp", output)
            manifest = json.loads(exported.with_suffix(".materials.json").read_text(encoding="utf-8"))
            self.assertEqual(manifest["asset"], "test_cube")
            materials = {material["name"]: material for material in manifest["materials"]}
            self.assertEqual(materials["GrassSides"]["type"], "basic_principled")
            self.assertEqual(materials["GrassSides"]["classification"], "directly_exportable")
            self.assertEqual(materials["GrassTop"]["type"], "procedural_noise_color_ramp")
            self.assertEqual(materials["GrassTop"]["classification"], "translatable")
            self.assertEqual(materials["GrassTop"]["noise"]["scale"], 5.0)
            self.assertEqual(materials["GrassTop"]["color_ramp"]["color_mode"], "RGB")
            self.assertEqual(len(materials["GrassTop"]["color_ramp"]["elements"]), 2)
            data = exported.read_bytes()
            self.assertEqual(data[:4], b"glTF")
            self.assertGreater(exported.stat().st_size, 100)
            json_length = struct.unpack_from("<I", data, 12)[0]
            gltf = json.loads(data[20:20 + json_length])
            names = {node.get("name") for node in gltf["nodes"]}
            self.assertIn("tile_test", names)
            self.assertNotIn("excluded_cube", names)

            bad_source = source.with_name("tile_bad.blend")
            bad_script = (
                "import bpy; "
                "asset=bpy.data.objects['tile_test']; "
                "[setattr(asset.data.vertices[i].co,'z',.30) for i in (4,5,6,7)]; "
                "asset.scale.x=1.1; "
                "asset.name='Cube'; "
                "material=bpy.data.materials['GrassTop']; "
                "shader=material.node_tree.nodes.get('Principled BSDF'); "
                "voronoi=material.node_tree.nodes.new('ShaderNodeTexVoronoi'); "
                "material.node_tree.links.new(voronoi.outputs['Color'],shader.inputs['Base Color']); "
                f"bpy.ops.wm.save_as_mainfile(filepath={str(bad_source)!r})"
            )
            subprocess.run(
                [blender, "--background", str(source), "--python-exit-code", "1", "--python-expr", bad_script],
                check=True, capture_output=True, text=True,
            )
            bad_output = pipeline.validate_asset(root, bad_source, blender)
            self.assertIn("[WARN] Object Cube: replace the generic Blender name", bad_output)
            self.assertIn("[WARN] Cube: object scale is not applied", bad_output)
            self.assertIn("[WARN] Cube: side dimensions", bad_output)
            self.assertFalse((root / "assets" / "models" / "props" / "tile_bad.glb").exists())
            bad_export, bad_log = pipeline.export_asset(root, bad_source, blender)
            self.assertEqual(bad_export.read_bytes()[:4], b"glTF")
            self.assertIn("unsupported graph", bad_log)
            bad_manifest = json.loads(bad_export.with_suffix(".materials.json").read_text(encoding="utf-8"))
            bad_materials = {material["name"]: material for material in bad_manifest["materials"]}
            self.assertEqual(bad_materials["GrassTop"]["type"], "unsupported")
            self.assertEqual(bad_materials["GrassTop"]["classification"], "unsupported")
            self.assertIn("Base Color", bad_materials["GrassTop"]["reason"])

            empty_source = source.with_name("tile_empty.blend")
            empty_script = (
                "import bpy; "
                "bpy.data.objects['tile_test'].data.clear_geometry(); "
                f"bpy.ops.wm.save_as_mainfile(filepath={str(empty_source)!r})"
            )
            subprocess.run(
                [blender, "--background", str(source), "--python-exit-code", "1", "--python-expr", empty_script],
                check=True, capture_output=True, text=True,
            )
            with self.assertRaisesRegex(RuntimeError, r"\[ERROR\] tile_test: mesh has no usable faces"):
                pipeline.validate_asset(root, empty_source, blender)
            with self.assertRaisesRegex(RuntimeError, "Blender export failed"):
                pipeline.export_asset(root, empty_source, blender)
            self.assertFalse((root / "assets" / "models" / "props" / "tile_empty.glb").exists())
            self.assertFalse((root / "assets" / "models" / "props" / "tile_empty.materials.json").exists())


if __name__ == "__main__":
    unittest.main()
