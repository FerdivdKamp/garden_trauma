"""Run inside Blender on one backed-up Garden grass tile source.

The original Displace modifier gives each two-meter tile a strong, low-density
heightfield. Bake it, add the same Simple Subdivision to every retained
variant, then reduce relief and taper it to a flat border. The broad color
variation remains in Godot's world-space shader.
"""

import bpy


GROUND_TOP = 0.25
HEIGHT_SCALE = 0.25
EDGE_FLAT_WIDTH = 0.16
EDGE_FADE_WIDTH = 0.30


def smoothstep(value):
    value = max(0.0, min(1.0, value))
    return value * value * (3.0 - 2.0 * value)


objects = [obj for obj in bpy.context.scene.objects if obj.type == 'MESH' and obj.name == 'tile_grass']
if len(objects) != 1 or len(objects[0].modifiers) != 1 or objects[0].modifiers[0].type != 'DISPLACE':
    raise RuntimeError('Expected one original grass mesh with its Displace modifier')

obj = objects[0]
subdivision = obj.modifiers.new('Consistent grass density', 'SUBSURF')
subdivision.subdivision_type = 'SIMPLE'
subdivision.levels = 2
subdivision.render_levels = 2

depsgraph = bpy.context.evaluated_depsgraph_get()
mesh = bpy.data.meshes.new_from_object(obj.evaluated_get(depsgraph), preserve_all_data_layers=True, depsgraph=depsgraph)
mesh.name = obj.data.name + '_softened'
top_vertices = {
    vertex_id
    for polygon in mesh.polygons
    if mesh.materials[polygon.material_index].name == 'GrassTop'
    for vertex_id in polygon.vertices
}

for vertex_id in top_vertices:
    vertex = mesh.vertices[vertex_id]
    edge_distance = min(1.0 - abs(vertex.co.x), 1.0 - abs(vertex.co.y))
    fade = smoothstep((edge_distance - EDGE_FLAT_WIDTH) / EDGE_FADE_WIDTH)
    vertex.co.z = GROUND_TOP + (vertex.co.z - GROUND_TOP) * HEIGHT_SCALE * fade

mesh.update()
obj.modifiers.clear()
obj.data = mesh
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath, compress=True)
print(f'Softened {bpy.data.filepath}: {len(mesh.vertices)} vertices, {len(mesh.polygons)} faces')
