extends Node2D

func _ready() -> void:
	var player = 1
	var id = 0
	
	for child in get_children():
		if child is VBoxContainer: 
			child.player = player # Define se o VBoxContainer é do Player 1 ou Player 2
			for button in child.get_children():
				if id < ControlesAutoload.REBINDABLE.size():
					var action = ControlesAutoload.REBINDABLE[id]
					button.action_name = action
					button.name = action
					button.update_button_text()
					id += 1
			player += 1

func _on_button_pressed() -> void:
	var stage_scene = load("res://scenes/StarterMenu.tscn")
	var main_node = get_tree().root.get_node_or_null("Main")
	if main_node and stage_scene:
		var old_stage_id = main_node.get_child_count() - 1
		var stage = stage_scene.instantiate()
		main_node.add_child(stage)
		main_node.get_child(old_stage_id).queue_free()
	else:
		get_tree().change_scene_to_file("res://scenes/StarterMenu.tscn")
