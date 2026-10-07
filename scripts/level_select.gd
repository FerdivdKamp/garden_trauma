extends Control

@onready var level_list: VBoxContainer = $Center/Panel/Content/Levels


func _ready() -> void:
	for level in LevelProgress.LEVELS:
		var id: String = level.id
		var button := Button.new()
		button.custom_minimum_size = Vector2(280, 52)
		button.disabled = not LevelProgress.is_unlocked(id)
		var state := "Completed" if LevelProgress.is_completed(id) else ("Available" if not button.disabled else "Locked")
		button.text = "%s  -  %s" % [level.title, state]
		button.pressed.connect(_play_level.bind(id))
		level_list.add_child(button)
	$Center/Panel/Content/Back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))


func _play_level(id: String) -> void:
	if LevelProgress.select_level(id):
		get_tree().change_scene_to_file(LevelProgress.BATTLE_SCENE)
