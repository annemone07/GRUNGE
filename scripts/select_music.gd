extends Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_pressed() -> void:
	var stage_scene = load("res://scenes/play_map.tscn")
	var old_stage_id = get_tree().root.get_node("Main").get_child_count()-1
	if stage_scene:
		var stage = stage_scene.instantiate()
		get_tree().root.get_node("Main").add_child(stage)
		get_tree().root.get_node("Main").get_child(old_stage_id).queue_free()
	else:
		print("Erro: Não conseguimos encontrar a cena.")


func _on_button_2_pressed() -> void:
	var stage_scene = load("res://scenes/play_map.tscn")
	var old_stage_id = get_tree().root.get_node("Main").get_child_count()-1
	if stage_scene:
		var stage = stage_scene.instantiate()
		get_tree().root.get_node("Main").add_child(stage)
		get_tree().root.get_node("Main").get_child(old_stage_id).queue_free()
	else:
		print("Erro: Não conseguimos encontrar a cena.")


func _on_button_3_pressed() -> void:
	var stage_scene = load("res://scenes/play_map.tscn")
	var old_stage_id = get_tree().root.get_node("Main").get_child_count()-1
	if stage_scene:
		var stage = stage_scene.instantiate()
		get_tree().root.get_node("Main").add_child(stage)
		get_tree().root.get_node("Main").get_child(old_stage_id).queue_free()
	else:
		print("Erro: Não conseguimos encontrar a cena.")
