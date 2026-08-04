extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_pressed() -> void:
	var stage_scene = load("res://scenes/play_map.tscn")
	if stage_scene:
		var stage = stage_scene.instantiate()
		get_tree().root.add_child(stage)
	else:
		print("Erro: Não conseguimos encontrar a cena.")


func _on_button_2_pressed() -> void:
	var stage_scene = load("res://scenes/play_map.tscn")
	if stage_scene:
		var stage = stage_scene.instantiate()
		get_tree().root.add_child(stage)
	else:
		print("Erro: Não conseguimos encontrar a cena.")


func _on_button_3_pressed() -> void:
	var stage_scene = load("res://scenes/play_map.tscn")
	if stage_scene:
		var stage = stage_scene.instantiate()
		get_tree().root.add_child(stage)
	else:
		print("Erro: Não conseguimos encontrar a cena.")
