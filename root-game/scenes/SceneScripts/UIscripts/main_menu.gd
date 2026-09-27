extends Control

@onready var settings_tab = preload("res://scenes/UIBartka/settings_tab.tscn")

func _on_play_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://Level Data/LevelBase.tscn")

func _on_settings_btn_pressed() -> void:
	var settings_instance = settings_tab.instantiate()
	add_child(settings_instance)
	
	var screen_size = get_viewport_rect().size
	var target_x = (screen_size.x - settings_instance.size.x) / 2.0
	var target_y = (screen_size.y - settings_instance.size.y) / 2.0
	
	settings_instance.position = Vector2(-settings_instance.size.x, target_y)
	
	var tween = create_tween()
	tween.tween_property(settings_instance, "position", Vector2(target_x, target_y), 0.4)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)

func _on_exit_btn_pressed() -> void:
	get_tree().quit()

func _on_visit_itch_btn_pressed() -> void:
	pass #OS.shell_open("https://XYZ.itch.io")
