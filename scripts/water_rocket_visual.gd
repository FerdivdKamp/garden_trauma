extends Node3D

# Blender's pivot owns both the rotating plate and launcher arm. The pump is
# separate: its scaler is at the bellows' bottom, so compression stays seated.
@onready var yaw_pivot: Node3D = $TowerModel/Base/pivot
@onready var pitch_pivot: Node3D = $TowerModel/Base/pivot/pitch
@onready var arm: Node3D = $TowerModel/Base/pivot/pitch/arm
@onready var tower_body: Node3D = $TowerModel/Base/base_mesh
@onready var accordion: Node3D = $TowerModel/Base/base_mesh/pump_scaler
@onready var muzzle: Node3D = $TowerModel/Base/pivot/pitch/arm/muzzle
@onready var loaded_rocket: Node3D = $TowerModel/Base/pivot/pitch/arm/muzzle/LoadedRocket

# In the source, the right arm points along local -Z; the front is local -X.
# Offset yaw so the front faces the target and the arm remains on its right.
const PLATE_YAW_OFFSET := -PI / 2.0
const CLOSE_ELEVATION := 45.0
const FAR_ELEVATION := 20.0

var pump_tween: Tween


func aim_pitch(distance: float, attack_range: float, turn_speed: float, delta: float) -> bool:
	# The body and plate share the same heading.
	tower_body.rotation.y = yaw_pivot.rotation.y
	# Elevation is measured from the ground; the Blender arm starts vertical.
	var distance_fraction := clampf(distance / maxf(attack_range, 0.01), 0.0, 1.0)
	var elevation := lerpf(CLOSE_ELEVATION, FAR_ELEVATION, distance_fraction)
	# Blender Y becomes Godot -Z. Positive Godot Z pitches the upright
	# rocket toward the tower's front, while the arm remains on the right.
	var desired_pitch := deg_to_rad(90.0 - elevation)
	pitch_pivot.rotation.z = move_toward(pitch_pivot.rotation.z, desired_pitch, deg_to_rad(turn_speed) * delta)
	return absf(pitch_pivot.rotation.z - desired_pitch) < deg_to_rad(5.0)


func launch_direction() -> Vector3:
	# The rocket's +Y axis follows the launcher as it pitches and turns.
	return muzzle.global_basis.y.normalized()


func pump_and_launch(launch: Callable) -> void:
	if pump_tween != null and pump_tween.is_running():
		pump_tween.kill()
	accordion.scale.y = 1.0
	loaded_rocket.visible = true
	pump_tween = create_tween()
	pump_tween.tween_property(accordion, "scale:y", 0.55, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	pump_tween.tween_callback(func() -> void:
		loaded_rocket.hide()
		launch.call()
	)
	pump_tween.tween_property(accordion, "scale:y", 1.06, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pump_tween.tween_property(accordion, "scale:y", 1.0, 0.10)
	pump_tween.tween_callback(loaded_rocket.show)
