"""Build the editable stone material in rock_bisect.blend (Blender 5.2).

Open the source blend and press Run Script in Blender's Scripting workspace.
The original blend is left alone; the result is rock_stylized.blend beside it.
"""

from pathlib import Path

import bpy


MATERIAL_NAME = "MAT_StylizedStone"
STONE_NAMES = ("Icosphere", "Icosphere.001", "Icosphere.002", "Icosphere.003")

# Artist controls. Colors are scene-linear RGB, as Blender shader sockets expect.
DARK_STONE = (0.19, 0.24, 0.29, 1.0)
MID_STONE = (0.32, 0.39, 0.45, 1.0)
LIGHT_STONE = (0.46, 0.52, 0.57, 1.0)
EDGE_COLOR = (0.67, 0.72, 0.75, 1.0)
EDGE_INTENSITY = 0.48
AO_STRENGTH = 0.42


def node(nodes, kind, name, frame, x, y):
    item = nodes.new(kind)
    item.name = name
    item.label = name
    item.parent = frame
    item.location = (x, y)
    return item


def frame(nodes, name, x, y):
    item = nodes.new("NodeFrame")
    item.name = name
    item.label = name
    item.location = (x, y)
    item.use_custom_color = True
    item.color = (0.18, 0.24, 0.30)
    return item


def make_material():
    material = bpy.data.materials.get(MATERIAL_NAME) or bpy.data.materials.new(MATERIAL_NAME)
    material.use_nodes = True
    tree = material.node_tree
    tree.nodes.clear()  # Rerunning the script updates the material instead of stacking nodes.
    nodes, links = tree.nodes, tree.links

    base = frame(nodes, "Base Color", -1200, 420)
    noise = node(nodes, "ShaderNodeTexNoise", "Broad stone variation", base, 0, 0)
    noise.inputs["Scale"].default_value = 2.8
    noise.inputs["Detail"].default_value = 2.0
    noise.inputs["Roughness"].default_value = 0.55
    ramp = node(nodes, "ShaderNodeValToRGB", "Three stone colors", base, 230, 0)
    ramp.color_ramp.elements.remove(ramp.color_ramp.elements[1])
    for position, color in ((0.20, DARK_STONE), (0.50, MID_STONE), (0.80, LIGHT_STONE)):
        stop = ramp.color_ramp.elements.new(position)
        stop.color = color
    links.new(noise.outputs["Fac"], ramp.inputs["Fac"])

    edge = frame(nodes, "Edge Highlights", -1200, -40)
    geometry = node(nodes, "ShaderNodeNewGeometry", "Geometry pointiness (Cycles)", edge, 0, 0)
    edge_ramp = node(nodes, "ShaderNodeValToRGB", "Convex edge mask", edge, 230, 0)
    edge_ramp.color_ramp.elements[0].position = 0.48
    edge_ramp.color_ramp.elements[1].position = 0.68
    links.new(geometry.outputs["Pointiness"], edge_ramp.inputs["Fac"])
    edge_gain = node(nodes, "ShaderNodeMath", "Edge intensity", edge, 470, 0)
    edge_gain.operation = "MULTIPLY"
    edge_gain.inputs[1].default_value = EDGE_INTENSITY
    links.new(edge_ramp.outputs["Color"], edge_gain.inputs[0])
    edge_mix = node(nodes, "ShaderNodeMixRGB", "Lighten convex edges", edge, 690, 0)
    edge_mix.blend_type = "MIX"
    edge_mix.inputs[2].default_value = EDGE_COLOR
    links.new(edge_gain.outputs[0], edge_mix.inputs[0])
    links.new(ramp.outputs["Color"], edge_mix.inputs[1])

    cavity = frame(nodes, "Cavity Shading", -420, -40)
    ao = node(nodes, "ShaderNodeAmbientOcclusion", "Local ambient occlusion", cavity, 0, 0)
    ao.inputs["Distance"].default_value = 0.25
    cavity_gain = node(nodes, "ShaderNodeMapRange", "Cavity intensity", cavity, 230, 0)
    cavity_gain.inputs["From Min"].default_value = 0.0
    cavity_gain.inputs["From Max"].default_value = 1.0
    cavity_gain.inputs["To Min"].default_value = 1.0 - AO_STRENGTH
    cavity_gain.inputs["To Max"].default_value = 1.0
    links.new(ao.outputs["AO"], cavity_gain.inputs["Value"])
    cavity_mix = node(nodes, "ShaderNodeMixRGB", "Darken recesses", cavity, 470, 0)
    cavity_mix.blend_type = "MULTIPLY"
    cavity_mix.inputs[0].default_value = 1.0
    links.new(edge_mix.outputs["Color"], cavity_mix.inputs[1])
    links.new(cavity_gain.outputs["Result"], cavity_mix.inputs[2])

    detail = frame(nodes, "Surface Detail", -350, -530)
    fine = node(nodes, "ShaderNodeTexNoise", "Soft fine grain", detail, 0, 0)
    fine.inputs["Scale"].default_value = 38.0
    fine.inputs["Detail"].default_value = 2.0
    bump = node(nodes, "ShaderNodeBump", "Subtle bump", detail, 230, 0)
    bump.inputs["Strength"].default_value = 0.1
    bump.inputs["Distance"].default_value = 0.025
    links.new(fine.outputs["Fac"], bump.inputs["Height"])

    output_frame = frame(nodes, "Output", 380, 390)
    principled = node(nodes, "ShaderNodeBsdfPrincipled", "Matte stone", output_frame, 0, 0)
    principled.inputs["Roughness"].default_value = 0.85
    links.new(cavity_mix.outputs["Color"], principled.inputs["Base Color"])
    links.new(bump.outputs["Normal"], principled.inputs["Normal"])
    emission = node(nodes, "ShaderNodeEmission", "Bake color via Emit", output_frame, 0, -450)
    links.new(cavity_mix.outputs["Color"], emission.inputs["Color"])
    surface = node(nodes, "ShaderNodeOutputMaterial", "Material Output", output_frame, 360, 0)
    links.new(principled.outputs["BSDF"], surface.inputs["Surface"])
    return material


def main():
    if not bpy.data.filepath:
        raise RuntimeError("Open rock_bisect.blend before running this script")
    stones = [bpy.data.objects.get(name) for name in STONE_NAMES]
    if any(item is None or item.type != "MESH" for item in stones):
        raise RuntimeError("Expected the four Icosphere mesh objects from rock_bisect.blend")
    material = make_material()
    for stone in stones:
        stone.data.materials.clear()
        stone.data.materials.append(material)
    bpy.context.scene.render.engine = "CYCLES"  # Pointiness and AO need a Cycles preview.
    destination = Path(bpy.data.filepath).with_name("rock_stylized.blend")
    bpy.ops.wm.save_as_mainfile(filepath=str(destination))
    print(f"Stone shader assigned to four objects; saved {destination}")


if __name__ == "__main__":
    main()
