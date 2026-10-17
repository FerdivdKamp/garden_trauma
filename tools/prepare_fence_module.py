"""Add a tile-length export collection to fence.blend, keeping its editable arrays.

Run with Blender in background on art/blender/props/border/fence.blend, then
export the fence_straight_01 collection through asset_pipeline.py.
"""

import bpy


scene = bpy.context.scene
old_collection = bpy.data.collections.get("fence_straight_01")
if old_collection is not None:
    for obj in list(old_collection.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    bpy.data.collections.remove(old_collection)

collection = bpy.data.collections.new("fence_straight_01")
scene.collection.children.link(collection)

wood = bpy.data.materials.get("WarmFenceWood") or bpy.data.materials.new("WarmFenceWood")
wood.diffuse_color = (0.48, 0.25, 0.105, 1.0)
wood.use_nodes = True
principled = wood.node_tree.nodes.get("Principled BSDF")
principled.inputs["Base Color"].default_value = wood.diffuse_color
principled.inputs["Roughness"].default_value = 0.82


def add_part(source_name, name, height):
    source = bpy.data.objects[source_name]
    part = bpy.data.objects.new(name, source.data.copy())
    collection.objects.link(part)
    # The source's first modifier rounds the wood edges. Its geometry-node
    # arrays stay on the artist's source objects, while this export uses one
    # post and two single rails per 2 m section.
    bevel = source.modifiers.get("Bevel")
    if bevel is not None:
        copied = part.modifiers.new("Soft edges", "BEVEL")
        copied.width = bevel.width
        copied.segments = bevel.segments
        copied.affect = bevel.affect
    part.location.z = height
    part.data.materials.clear()
    part.data.materials.append(wood)


add_part("fence_post", "fence_post_01", 0.25)
add_part("horizontal_beams", "lower_rail_01", 0.25)
add_part("horizontal_beams", "upper_rail_01", 0.75)

bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath, compress=True)
print("Prepared fence_straight_01: one post, two 2 m rails")
