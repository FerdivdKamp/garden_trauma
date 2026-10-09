"""Run inside Blender to validate or export the selected asset."""

import json
import os
import re
import sys

import bpy


ALLOWED_TYPES = {"MESH", "CURVE", "FONT", "SURFACE", "META", "ARMATURE", "EMPTY"}
GEOMETRY_TYPES = {"MESH", "CURVE", "FONT", "SURFACE", "META"}
GENERIC_NAME = re.compile(r"^(Cube|Cylinder|Sphere|UVSphere|Icosphere|Plane|Cone|Torus|Suzanne|Material)(\.\d+)?$", re.IGNORECASE)
PROCEDURAL_NODES = {
    "TEX_NOISE", "TEX_VORONOI", "TEX_WAVE", "TEX_MAGIC", "TEX_BRICK",
    "TEX_CHECKER", "TEX_GRADIENT", "TEX_WHITE_NOISE", "VALTORGB",
}
TILE_SIZE = (2.0, 2.0, 0.25)
TOLERANCE = 0.001


def selected_objects(collection_name=None):
    if collection_name:
        collection = bpy.data.collections.get(collection_name)
        if collection is None:
            raise ValueError(f"Collection not found: {collection_name}")
        # Explicit exports include versions hidden while another version is edited.
        return [obj for obj in collection.all_objects if obj.type in ALLOWED_TYPES]
    export_collection = bpy.data.collections.get("Export")
    candidates = export_collection.all_objects if export_collection else bpy.context.scene.objects
    return [obj for obj in candidates if obj.type in ALLOWED_TYPES and not obj.hide_render and obj.visible_get()]


def tile_side_dimensions(obj):
    """Measure side and bottom faces, excluding bumps in the top surface."""
    mesh = obj.data
    side_slots = {
        index for index, material in enumerate(mesh.materials)
        if material is not None and material.name.endswith("Sides")
    }
    # Prefer the artist's explicit side material. For untextured tiles, vertical
    # faces provide the same measurement without including uneven top faces.
    side_faces = (
        [face for face in mesh.polygons if face.material_index in side_slots]
        if side_slots else
        [face for face in mesh.polygons if abs(face.normal.z) < 0.2 and face.area > 0]
    )
    indices = {
        vertex_index
        for face in side_faces
        for vertex_index in face.vertices
    }
    if not indices:
        return None
    positions = [obj.matrix_world @ mesh.vertices[index].co for index in indices]
    return tuple(
        max(position[axis] for position in positions) - min(position[axis] for position in positions)
        for axis in range(3)
    )


def input_link(node, socket_name):
    socket = node.inputs.get(socket_name)
    if socket is None and socket_name == "Fac":
        socket = node.inputs.get("Factor")
    return next(iter(socket.links), None) if socket else None


def linked_inputs(node, except_names=()):
    return [socket.name for socket in node.inputs if socket.is_linked and socket.name not in except_names]


def unsupported_material(material, reason):
    return {"name": material.name, "classification": "unsupported", "type": "unsupported", "reason": reason}


def inspect_material(material):
    """Classify only connected graphs whose values V4 can read unambiguously."""
    if not material.node_tree:
        return unsupported_material(material, "No node-based Principled shader")
    nodes = material.node_tree.nodes
    output = next((node for node in nodes if node.type == "OUTPUT_MATERIAL" and node.is_active_output), None)
    if output is None:
        return unsupported_material(material, "No active Material Output")
    surface = input_link(output, "Surface")
    if surface is None or surface.from_node.type != "BSDF_PRINCIPLED":
        return unsupported_material(material, "Surface must connect directly from Principled BSDF")
    if linked_inputs(output, {"Surface"}):
        return unsupported_material(material, "Material Output has unsupported linked inputs")

    principled = surface.from_node
    properties = {
        "base_color": list(principled.inputs["Base Color"].default_value),
        "metallic": float(principled.inputs["Metallic"].default_value),
        "roughness": float(principled.inputs["Roughness"].default_value),
        "alpha": float(principled.inputs["Alpha"].default_value),
    }
    other_links = linked_inputs(principled, {"Base Color"})
    if other_links:
        return unsupported_material(material, f"Unsupported Principled input links: {', '.join(other_links)}")

    base_color = input_link(principled, "Base Color")
    if base_color is None:
        return {
            "name": material.name,
            "classification": "directly_exportable",
            "type": "basic_principled",
            "principled": properties,
        }
    if base_color.from_node.type != "VALTORGB" or base_color.from_socket.name != "Color":
        return unsupported_material(material, "Base Color must connect from Color Ramp Color")

    ramp = base_color.from_node
    factor = input_link(ramp, "Fac")
    if factor is None or factor.from_node.type != "TEX_NOISE" or factor.from_socket.name not in {"Fac", "Factor"}:
        return unsupported_material(material, "Color Ramp Factor must connect from Noise Texture Factor")
    noise = factor.from_node
    noise_links = linked_inputs(noise, {"Vector"})
    if noise_links:
        return unsupported_material(material, f"Unsupported Noise Texture input links: {', '.join(noise_links)}")
    vector = input_link(noise, "Vector")
    if vector is not None and (vector.from_node.type != "TEX_COORD" or vector.from_socket.name != "Generated"):
        return unsupported_material(material, "Noise Texture Vector must use Generated coordinates")

    return {
        "name": material.name,
        "classification": "translatable",
        "type": "procedural_noise_color_ramp",
        "noise": {
            "dimensions": noise.noise_dimensions,
            "coordinates": "Generated",
            "scale": float(noise.inputs["Scale"].default_value),
            "detail": float(noise.inputs["Detail"].default_value),
            "roughness": float(noise.inputs["Roughness"].default_value),
            "lacunarity": float(noise.inputs["Lacunarity"].default_value),
            "distortion": float(noise.inputs["Distortion"].default_value),
        },
        "color_ramp": {
            "color_mode": ramp.color_ramp.color_mode,
            "interpolation": ramp.color_ramp.interpolation,
            "elements": [
                {"position": float(element.position), "color": list(element.color)}
                for element in ramp.color_ramp.elements
            ],
        },
        "principled": properties,
    }


def material_manifest(objects):
    materials = {material.name: material for obj in objects if obj.type == "MESH" for material in obj.data.materials if material}
    entries = [inspect_material(materials[name]) for name in sorted(materials)]
    for entry in entries:
        if entry["type"] == "unsupported":
            print(f"[WARN] Material {entry['name']}: unsupported graph: {entry['reason']}; using GLB fallback")
        else:
            print(f"[OK] Material {entry['name']}: {entry['type']}")
    return {"schema_version": 1, "asset": os.path.splitext(bpy.path.basename(bpy.data.filepath))[0], "materials": entries}


def validate(objects) -> bool:
    errors = 0
    single_tile_mesh = bpy.path.basename(bpy.data.filepath).startswith("tile_") and sum(
        obj.type == "MESH" for obj in objects
    ) == 1
    if not any(obj.type in GEOMETRY_TYPES for obj in objects):
        print("[ERROR] No visible geometry to export. Add objects to the Export collection or make them visible.")
        errors += 1

    seen_names = set()
    checked_materials = set()
    for obj in objects:
        if obj.name in seen_names:
            print(f"[ERROR] Duplicate export object name: {obj.name}")
            errors += 1
        seen_names.add(obj.name)
        if GENERIC_NAME.fullmatch(obj.name):
            print(f"[WARN] Object {obj.name}: replace the generic Blender name with a descriptive name")
        if obj.type != "MESH":
            continue

        mesh = obj.data
        if not mesh.vertices or not mesh.polygons or not any(face.area > 0 for face in mesh.polygons):
            print(f"[ERROR] {obj.name}: mesh has no usable faces")
            errors += 1
        else:
            zero_area = sum(face.area <= 0 for face in mesh.polygons)
            if zero_area:
                print(f"[WARN] {obj.name}: {zero_area} zero-area faces")
        if any(abs(value - 1.0) > 0.0001 for value in obj.scale):
            print(f"[WARN] {obj.name}: object scale is not applied: {tuple(round(v, 4) for v in obj.scale)}")
        if not mesh.materials or all(material is None for material in mesh.materials):
            print(f"[WARN] {obj.name}: mesh has no material")
        elif any(material is None for material in mesh.materials):
            print(f"[WARN] {obj.name}: mesh has an empty material slot")

        if obj.name.startswith("tile_") or single_tile_mesh:
            dimensions = tile_side_dimensions(obj)
            if dimensions is None:
                print(f"[WARN] {obj.name}: no side faces found; tile side dimensions cannot be checked")
            elif any(abs(actual - expected) > TOLERANCE for actual, expected in zip(dimensions, TILE_SIZE)):
                size = tuple(round(value, 4) for value in dimensions)
                print(f"[WARN] {obj.name}: side dimensions {size} differ from tile convention {TILE_SIZE} m")
            else:
                print(f"[OK] {obj.name}: side dimensions {TILE_SIZE} m")

        for material in mesh.materials:
            if material is None or material.name in checked_materials:
                continue
            checked_materials.add(material.name)
            if GENERIC_NAME.fullmatch(material.name):
                print(f"[WARN] Material {material.name}: replace the generic Blender name")
            if material.node_tree:
                nodes = sorted({node.bl_label for node in material.node_tree.nodes if node.type in PROCEDURAL_NODES})
                if nodes:
                    print(f"[WARN] Material {material.name}: procedural nodes ({', '.join(nodes)}) may not survive GLB export; check the imported material in Godot")

    print("[ERROR] Validation failed" if errors else "[OK] Validation passed; export allowed")
    return errors == 0


def main() -> None:
    if "--" not in sys.argv:
        raise ValueError("Expected 'validate' or 'export <output.glb> <manifest.json>' after --")
    arguments = sys.argv[sys.argv.index("--") + 1:]
    collection_name = None
    if len(arguments) >= 2 and arguments[-2] == "--collection":
        collection_name = arguments[-1]
        arguments = arguments[:-2]
    if arguments == ["validate"]:
        mode = "validate"
    elif len(arguments) == 3 and arguments[0] == "export":
        mode = "export"
    else:
        raise ValueError("Expected 'validate' or 'export <output.glb> <manifest.json>' after --")

    objects = selected_objects(collection_name)
    if not validate(objects):
        raise ValueError("Asset validation failed")
    manifest = material_manifest(objects)
    if mode == "validate":
        return

    # A .blend saved while editing a mesh restores Edit mode in background
    # Blender; selection operators require Object mode before GLB export.
    if bpy.context.object is not None and bpy.context.object.mode != "OBJECT":
        bpy.ops.object.mode_set(mode="OBJECT")
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        if collection_name:
            obj.hide_set(False)
            obj.hide_viewport = False
            obj.hide_render = False
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.export_scene.gltf(
        filepath=arguments[1], export_format="GLB", use_selection=True,
        export_cameras=False, export_lights=False, export_apply=True,
    )
    with open(arguments[2], "w", encoding="utf-8") as manifest_file:
        json.dump(manifest, manifest_file, indent=2)
        manifest_file.write("\n")
    print(f"Exported {len(objects)} objects to {arguments[1]}")
    print(f"Material manifest: {arguments[2]}")


if __name__ == "__main__":
    main()
