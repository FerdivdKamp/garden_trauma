"""Run inside Blender to export the selected asset as a GLB."""

import sys

import bpy


def main() -> None:
    if "--" not in sys.argv or len(sys.argv) != sys.argv.index("--") + 2:
        raise ValueError("Expected one output .glb path after --")
    output = sys.argv[-1]
    export_collection = bpy.data.collections.get("Export")
    candidates = export_collection.all_objects if export_collection else bpy.context.scene.objects
    allowed_types = {"MESH", "CURVE", "FONT", "SURFACE", "META", "ARMATURE", "EMPTY"}
    objects = [obj for obj in candidates if obj.type in allowed_types and not obj.hide_render and obj.visible_get()]
    if not objects or not any(obj.type in {"MESH", "CURVE", "FONT", "SURFACE", "META"} for obj in objects):
        raise ValueError("No visible geometry to export. Add objects to the Export collection or make them visible.")
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.export_scene.gltf(filepath=output, export_format="GLB", use_selection=True, export_cameras=False, export_lights=False)
    print(f"Exported {len(objects)} objects to {output}")


if __name__ == "__main__":
    main()
