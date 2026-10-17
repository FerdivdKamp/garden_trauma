extends RefCounted

# Grid y is world z. This order also breaks equal-length ties: north first.
const DIRECTIONS: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
const NAMES := ["North", "East", "South", "West"]


static func lanes(grid: LevelGrid, origin: Vector2i) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for index in DIRECTIONS.size():
		var direction := DIRECTIONS[index]
		var cells: Array[Vector2i] = []
		var cell := origin + direction
		while grid.is_walkable(cell):
			cells.append(cell)
			cell += direction
		if not cells.is_empty():
			result.append({"direction": direction, "name": NAMES[index], "cells": cells})
	return result


static func longest_index(options: Array[Dictionary]) -> int:
	var best := -1
	var length := 0
	for index in options.size():
		if options[index].cells.size() > length:
			best = index
			length = options[index].cells.size()
	return best
