extends SceneTree

const ROCKS_SCRIPT = preload("res://scripts/level_border_rocks.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var rocks := ROCKS_SCRIPT.new()
	root.add_child(rocks)
	rocks.build(20, 20)
	assert(rocks.get_child_count() == 8, "Place four stones and four outside ground strips")
	for rock: MeshInstance3D in rocks.get_children():
		if rock.name.begins_with("Ground"):
			var ground_bounds := rock.get_aabb()
			var ground_low := rock.transform * ground_bounds.position
			var ground_high := rock.transform * ground_bounds.end
			assert(ground_high.x <= -20.0 or ground_low.x >= 20.0
				or ground_high.z <= -20.0 or ground_low.z >= 20.0,
				"Ground strip must not cover playable tiles")
			continue
		var low := Vector3(INF, INF, INF)
		var high := Vector3(-INF, -INF, -INF)
		for corner in 8:
			var point := rock.transform * rock.get_aabb().get_endpoint(corner)
			low = low.min(point)
			high = high.max(point)
		assert(high.x < -21.0 or low.x > 21.0,
			"Stone %s must stay outside the 20 m fence edge" % rock.name)
		assert(absf(low.y + 0.08) < 0.02, "Stone base should sit just below the ground")
	print("Four baked stones sit outside the fence, with grounded bases")
	quit()
