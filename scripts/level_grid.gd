class_name LevelGrid
extends Node3D

const TILE_SIZE := 2.0
const TILE_HEIGHT := 0.2
const TERRAIN := {".": "grass", "=": "path_sand", "#": "blocked", "S": "path_sand", "O": "path_sand"}
const TILE_SCENES := {
	"grass": preload("res://scenes/tiles/tile_grass.tscn"),
	"path_sand": preload("res://scenes/tiles/tile_path.tscn"),
	"blocked": preload("res://scenes/tiles/tile_blocked_placeholder.tscn"),
}

@export_file("*.json") var level_file := "res://levels/data/garden_test_01.json"
@export_file("*.json") var dressing_file := "res://data/dressing/garden.json"
@export var show_grid := false:
	set(value):
		show_grid = value
		if is_node_ready():
			_update_debug()
@export var show_coordinates := false:
	set(value):
		show_coordinates = value
		if is_node_ready():
			_update_debug()
@export var show_route := false:
	set(value):
		show_route = value
		if is_node_ready():
			_update_debug()

var width := 0
var height := 0
var level_name := ""
var level_seed := 0
var visual_seeds: Dictionary = {}
var tiles: Array[String] = []
var route: Array[Vector2i] = []
var spawn := Vector2i.ZERO
var objective := Vector2i.ZERO
var error_message := ""


func _ready() -> void:
	load_level(level_file)


func load_level(path: String) -> bool:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _fail("Cannot read level %s: %s" % [path, error_string(FileAccess.get_open_error())])
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return _fail("%s: root must be a JSON object" % path)
	var data: Dictionary = parsed
	var problem := _validate(data)
	if not problem.is_empty():
		return _fail("%s: %s" % [path, problem])
	level_name = str(data.get("name", "Unnamed level"))
	level_seed = int(data.level_seed)
	visual_seeds = data.get("visual_seeds", {}).duplicate()
	width = int(data.width)
	height = int(data.height)
	tiles.clear()
	for row in data.tiles:
		tiles.append(row)
	spawn = _cell(data.spawn)
	objective = _cell(data.objective)
	route.clear()
	for point in data.route:
		route.append(_cell(point))
	error_message = ""
	_rebuild_visuals()
	return true


func _validate(data: Dictionary) -> String:
	if not _valid_seed(data.get("level_seed")):
		return "level_seed must be an integer from 0 to 2147483647"
	if not data.get("visual_seeds", {}) is Dictionary:
		return "visual_seeds must be a coordinate-to-seed object"
	if not _json_integer(data.get("width")) or not _json_integer(data.get("height")):
		return "width and height must be integers"
	var w: int = data.width
	var h: int = data.height
	if w <= 0 or h <= 0:
		return "width and height must be positive"
	if not data.get("tiles") is Array or data.tiles.size() != h:
		return "tiles must contain exactly %d rows" % h
	for z in h:
		var row = data.tiles[z]
		if not row is String or row.length() != w:
			return "tile row %d must contain exactly %d characters" % [z, w]
		for x in w:
			if not TERRAIN.has(row.substr(x, 1)):
				return "unknown terrain at (%d, %d)" % [x, z]
	for key: String in data.get("visual_seeds", {}):
		var parts := key.split(",")
		if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():
			return "visual_seeds key must be an x,z coordinate: %s" % key
		var cell := Vector2i(int(parts[0]), int(parts[1]))
		if cell.x < 0 or cell.y < 0 or cell.x >= w or cell.y >= h:
			return "visual_seeds coordinate is outside the grid: %s" % key
		if not _valid_seed(data.visual_seeds[key]):
			return "visual_seeds value must be an integer from 0 to 2147483647: %s" % key
	for key in ["spawn", "objective"]:
		if not _valid_cell(data.get(key), w, h):
			return "%s must be an in-bounds integer [x, z]" % key
		var cell := _cell(data[key])
		if TERRAIN[data.tiles[cell.y].substr(cell.x, 1)] != "path_sand":
			return "%s must be on path_sand" % key
	if not data.get("route") is Array or data.route.size() < 2:
		return "route must contain at least two cells"
	var previous := Vector2i.ZERO
	for index in data.route.size():
		var raw = data.route[index]
		if not _valid_cell(raw, w, h):
			return "route point %d is outside the grid or is not an integer cell" % index
		var cell := _cell(raw)
		if TERRAIN[data.tiles[cell.y].substr(cell.x, 1)] != "path_sand":
			return "route point %d at %s is not path_sand" % [index, cell]
		if index > 0 and absi(cell.x - previous.x) + absi(cell.y - previous.y) != 1:
			return "route points %d and %d must be orthogonally adjacent" % [index - 1, index]
		previous = cell
	if _cell(data.route[0]) != _cell(data.spawn) or previous != _cell(data.objective):
		return "route must start at spawn and end at objective"
	return ""


func _valid_cell(value: Variant, w: int, h: int) -> bool:
	return value is Array and value.size() == 2 and _json_integer(value[0]) and _json_integer(value[1]) and value[0] >= 0 and value[0] < w and value[1] >= 0 and value[1] < h


func _json_integer(value: Variant) -> bool:
	# Godot's JSON parser represents JSON numbers as floats.
	return (value is int or value is float) and is_equal_approx(float(value), roundf(float(value)))


func _valid_seed(value: Variant) -> bool:
	return _json_integer(value) and value >= 0 and value <= 2147483647


func visual_seed_for(cell: Vector2i) -> int:
	var key := "%d,%d" % [cell.x, cell.y]
	if visual_seeds.has(key):
		return int(visual_seeds[key])
	# Keep tile choices stable regardless of build order or other random calls.
	return (level_seed + cell.x * 73856093 + cell.y * 19349663) % 2147483647


func _cell(raw: Array) -> Vector2i:
	return Vector2i(raw[0], raw[1])


func _fail(message: String) -> bool:
	error_message = message
	push_error(message)
	return false


# The grid is centered on the origin. For even dimensions, centers are odd
# world coordinates: on a 20x20 map (0, 0) is (-19, -19).
func grid_to_world(cell: Vector2i) -> Vector3:
	return Vector3((float(cell.x) - float(width - 1) * 0.5) * TILE_SIZE, 0.0, (float(cell.y) - float(height - 1) * 0.5) * TILE_SIZE)


func world_to_grid(point: Vector3) -> Vector2i:
	return Vector2i(floori(point.x / TILE_SIZE + float(width) * 0.5), floori(point.z / TILE_SIZE + float(height) * 0.5))


func contains_cell(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height


func terrain_at(cell: Vector2i) -> String:
	if not contains_cell(cell):
		return ""
	return TERRAIN[tiles[cell.y].substr(cell.x, 1)]


func is_buildable(cell: Vector2i) -> bool:
	return terrain_at(cell) == "grass"


func is_walkable(cell: Vector2i) -> bool:
	return terrain_at(cell) == "path_sand"


func _rebuild_visuals() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	for z in height:
		for x in width:
			var cell := Vector2i(x, z)
			var terrain := terrain_at(cell)
			var tile := TILE_SCENES[terrain].instantiate() as Node3D
			if terrain == "grass":
				(tile as GrassTileVisual).visual_seed = visual_seed_for(cell)
			elif terrain == "path_sand":
				(tile as PathTileVisual).visual_seed = visual_seed_for(cell)
			tile.name = "Tile_%d_%d" % [x, z]
			tile.position = grid_to_world(cell)
			add_child(tile)
	var dressing := LevelDressing.new()
	dressing.name = "Dressing"
	add_child(dressing)
	dressing.build(self, dressing_file)
	for pair in [[spawn, "SPAWN", Color("ef704e")], [objective, "GOAL", Color("6ab5ee")]]:
		var marker := Label3D.new()
		marker.name = pair[1]
		marker.text = pair[1]
		marker.modulate = pair[2]
		marker.font_size = 40
		marker.pixel_size = 0.008
		marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		marker.position = grid_to_world(pair[0]) + Vector3(0, 1.15, 0)
		add_child(marker)
	_update_debug()


func _update_debug() -> void:
	for overlay_name in ["GridOverlay", "Coordinates", "RouteOverlay"]:
		var old := get_node_or_null(overlay_name)
		if old != null:
			remove_child(old)
			old.queue_free()
	if show_grid:
		var mesh := ImmediateMesh.new()
		mesh.surface_begin(Mesh.PRIMITIVE_LINES)
		for x in width + 1:
			var px := (float(x) - float(width) * 0.5) * TILE_SIZE
			mesh.surface_add_vertex(Vector3(px, 0.03, -height * TILE_SIZE * 0.5))
			mesh.surface_add_vertex(Vector3(px, 0.03, height * TILE_SIZE * 0.5))
		for z in height + 1:
			var pz := (float(z) - float(height) * 0.5) * TILE_SIZE
			mesh.surface_add_vertex(Vector3(-width * TILE_SIZE * 0.5, 0.03, pz))
			mesh.surface_add_vertex(Vector3(width * TILE_SIZE * 0.5, 0.03, pz))
		mesh.surface_end()
		_add_overlay("GridOverlay", mesh, Color(0.08, 0.13, 0.08, 0.7))
	if show_coordinates:
		var labels := Node3D.new()
		labels.name = "Coordinates"
		add_child(labels)
		for z in height:
			for x in width:
				var label := Label3D.new()
				label.text = "%d,%d" % [x, z]
				label.font_size = 24
				label.pixel_size = 0.006
				label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
				label.position = grid_to_world(Vector2i(x, z)) + Vector3(0, 0.15, 0)
				labels.add_child(label)
	if show_route:
		var mesh := ImmediateMesh.new()
		mesh.surface_begin(Mesh.PRIMITIVE_LINES)
		for index in route.size() - 1:
			mesh.surface_add_vertex(grid_to_world(route[index]) + Vector3(0, 0.08, 0))
			mesh.surface_add_vertex(grid_to_world(route[index + 1]) + Vector3(0, 0.08, 0))
		mesh.surface_end()
		_add_overlay("RouteOverlay", mesh, Color.YELLOW)


func _add_overlay(node_name: String, mesh: Mesh, color: Color) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	instance.material_override = material
	add_child(instance)
