class_name TowerRules
extends RefCounted


static func can_detect(distance: float, detection_radius: float) -> bool:
	return distance <= detection_radius


static func can_attack(distance: float, attack_radius: float, detection_radius: float) -> bool:
	return can_detect(distance, detection_radius) and distance <= attack_radius


static func target_yaw(direction: Vector3) -> float:
	# Godot's forward direction is -Z; atan2 maps a world direction to Y rotation.
	return atan2(-direction.x, -direction.z)


static func step_yaw(current: float, target: float, speed_radians: float, delta: float) -> float:
	var remaining := angle_difference(current, target)
	return current + clampf(remaining, -speed_radians * delta, speed_radians * delta)


static func health_after_hit(health: float, damage: float) -> float:
	return maxf(0.0, health - maxf(0.0, damage))
