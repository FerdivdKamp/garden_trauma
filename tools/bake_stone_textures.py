"""Bake four stone albedos and make a Godot-ready GLB (Blender 5.2).

Run with rock_stylized.blend open. Original meshes retain MAT_StylizedStone;
the Baked Export collection contains copies with simple image materials.
"""

from pathlib import Path

import bpy


STONE_NAMES = ("Icosphere", "Icosphere.001", "Icosphere.002", "Icosphere.003")
SOURCE_MATERIAL = "MAT_StylizedStone"
EXPORT_COLLECTION = "Baked Export"
SIZE = 512


def project_root():
    blend = Path(bpy.data.filepath).resolve()
    for parent in blend.parents:
        if (parent / "project.godot").exists():
            return parent
    raise RuntimeError("Could not find the Godot project above this blend file")


def ensure_uv(stone):
    layer = stone.data.uv_layers.active
    if layer and len(layer.data) == len(stone.data.loops):
        coords = [loop.uv for loop in layer.data]
        if coords and max(uv.x for uv in coords) > min(uv.x for uv in coords) \
                and max(uv.y for uv in coords) > min(uv.y for uv in coords):
            return
    # Only create a new unwrap for a missing or degenerate UV map.
    bpy.ops.object.select_all(action="DESELECT")
    stone.select_set(True)
    bpy.context.view_layer.objects.active = stone
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(island_margin=0.02)
    bpy.ops.object.mode_set(mode="OBJECT")
    print(f"Generated Smart UVs for {stone.name}")


def image_for(stone, folder):
    name = f"{stone.name}_albedo"
    image = bpy.data.images.get(name)
    if image is None:
        image = bpy.data.images.new(name, width=SIZE, height=SIZE, alpha=False)
    elif tuple(image.size) != (SIZE, SIZE):
        image.scale(SIZE, SIZE)
    image.filepath_raw = str(folder / f"{name}.png")
    image.file_format = "PNG"
    return image


def bake_one(stone, source, folder):
    ensure_uv(stone)
    image = image_for(stone, folder)
    # Each copy has its own active image node. The shared artist material stays intact.
    temporary = source.copy()
    temporary.name = f"TEMP_Bake_{stone.name}"
    tree = temporary.node_tree
    output = tree.nodes.get("Material Output")
    emission = tree.nodes.get("Bake color via Emit")
    if output is None or emission is None:
        raise RuntimeError("Run create_stone_shader.py before baking")
    prior = [link.from_socket for link in output.inputs["Surface"].links]
    image_node = tree.nodes.new("ShaderNodeTexImage")
    image_node.name = "Bake target"
    image_node.image = image
    tree.nodes.active = image_node
    tree.links.new(emission.outputs["Emission"], output.inputs["Surface"])
    prior_materials = list(stone.data.materials)
    try:
        stone.data.materials.clear()
        stone.data.materials.append(temporary)
        bpy.ops.object.select_all(action="DESELECT")
        stone.select_set(True)
        bpy.context.view_layer.objects.active = stone
        bpy.ops.object.bake(type="EMIT")
        image.save()
        if not Path(image.filepath_raw).is_file():
            raise RuntimeError("Blender did not write the baked PNG")
    finally:
        # Restore the output even on failure, then restore the source assignment.
        for link in list(output.inputs["Surface"].links):
            tree.links.remove(link)
        for socket in prior:
            tree.links.new(socket, output.inputs["Surface"])
        stone.data.materials.clear()
        for material in prior_materials:
            stone.data.materials.append(material)
        bpy.data.materials.remove(temporary)
    image.filepath = bpy.path.relpath(image.filepath_raw)
    return image


def baked_material(stone, image):
    name = f"MAT_{stone.name}_Baked"
    material = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    material.use_nodes = True
    nodes = material.node_tree.nodes
    nodes.clear()
    links = material.node_tree.links
    texture = nodes.new("ShaderNodeTexImage")
    texture.name = "Baked albedo"
    texture.image = image
    texture.location = (-400, 0)
    shader = nodes.new("ShaderNodeBsdfPrincipled")
    shader.name = "Export stone"
    shader.location = (-100, 0)
    shader.inputs["Roughness"].default_value = 0.85
    output = nodes.new("ShaderNodeOutputMaterial")
    output.location = (220, 0)
    links.new(texture.outputs["Color"], shader.inputs["Base Color"])
    links.new(shader.outputs["BSDF"], output.inputs["Surface"])
    return material


def make_export_collection(stones, images):
    old = bpy.data.collections.get(EXPORT_COLLECTION)
    if old:
        for item in list(old.all_objects):
            bpy.data.objects.remove(item, do_unlink=True)
        bpy.data.collections.remove(old)
    collection = bpy.data.collections.new(EXPORT_COLLECTION)
    bpy.context.scene.collection.children.link(collection)
    copies = []
    for stone, image in zip(stones, images):
        # A mesh copy keeps the source geometry and UVs independently inspectable.
        copy = stone.copy()
        copy.data = stone.data.copy()
        copy.name = f"{stone.name}_baked"
        copy.data.materials.clear()
        copy.data.materials.append(baked_material(stone, image))
        collection.objects.link(copy)
        copies.append(copy)
    return collection, copies


def main():
    if not bpy.data.filepath or Path(bpy.data.filepath).name != "rock_stylized.blend":
        raise RuntimeError("Open rock_stylized.blend before running this script")
    stones = [bpy.data.objects.get(name) for name in STONE_NAMES]
    source = bpy.data.materials.get(SOURCE_MATERIAL)
    if source is None or any(stone is None or stone.type != "MESH" for stone in stones):
        raise RuntimeError("The four source stones and MAT_StylizedStone are required")
    root = project_root()
    texture_folder = root / "textures" / "stepping_stones"
    texture_folder.mkdir(parents=True, exist_ok=True)
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 64
    scene.render.bake.margin = 8
    scene.render.bake.use_clear = True
    results = []
    for stone in stones:
        try:
            image = bake_one(stone, source, texture_folder)
            results.append((stone, image))
            print(f"BAKED {stone.name}: {image.filepath_raw}")
        except Exception as exc:
            print(f"FAILED {stone.name}: {exc}")
    if len(results) != len(stones):
        raise RuntimeError(f"Only {len(results)} of {len(stones)} stones baked; blend not saved")

    collection, copies = make_export_collection(
        [item[0] for item in results], [item[1] for item in results]
    )
    # The bake leaves its last source object selected. Export only the copies.
    bpy.ops.object.select_all(action="DESELECT")
    for copy in copies:
        copy.select_set(True)
    bpy.context.view_layer.objects.active = copies[0]
    output = root / "assets" / "models" / "props" / "border" / "rock_stylized.glb"
    output.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=str(output), export_format="GLB",
        use_selection=True, use_active_scene=True,
    )
    bpy.ops.object.select_all(action="DESELECT")
    # Keep the artist scene uncluttered while retaining inspectable export copies.
    collection.hide_viewport = True
    collection.hide_render = True
    legacy_scene = bpy.data.scenes.get(EXPORT_COLLECTION)
    if legacy_scene and legacy_scene != scene:
        for item in list(legacy_scene.objects):
            bpy.data.objects.remove(item, do_unlink=True)
        bpy.data.scenes.remove(legacy_scene)
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath)
    print(f"EXPORTED {output}")
    print("All four albedos baked. Source scene still uses MAT_StylizedStone.")


if __name__ == "__main__":
    main()
