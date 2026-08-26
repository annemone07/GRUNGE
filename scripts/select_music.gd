extends Node3D

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func change_scene_to_instruments():
	var stage_scene = load("res://scenes/select_instruments.tscn")
	var old_stage_id = get_tree().root.get_node("Main").get_child_count() - 1
	if stage_scene:
		var stage = stage_scene.instantiate()
		get_tree().root.get_node("Main").add_child(stage)
		get_tree().root.get_node("Main").get_child(old_stage_id).queue_free()
	else:
		print("Erro: Não conseguimos encontrar a cena.")

func _on_button_pressed() -> void:
	Globals.selected_music = "music_1"
	change_scene_to_instruments()

func _on_button_2_pressed() -> void:
	Globals.selected_music = "music_2"
	change_scene_to_instruments()

func _on_button_3_pressed() -> void:
	Globals.selected_music = "music_3"
	change_scene_to_instruments()
