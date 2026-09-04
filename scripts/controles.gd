extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var player=1
	var id=0
	for child in get_children():
		if child is VBoxContainer: 
			child.player = player
			for button in child.get_children():
				button.name=ControlesAutoload.REBINDABLE[id]
				button.update_button_text()
				id+=1
			player+=1


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_pressed() -> void:
	var stage_scene = load("res://scenes/StarterMenu.tscn")
	var old_stage_id = get_tree().root.get_node("Main").get_child_count()-1
	if stage_scene:
		var stage = stage_scene.instantiate()
		get_tree().root.get_node("Main").add_child(stage)
		get_tree().root.get_node("Main").get_child(old_stage_id).queue_free()
	else:
		print("Erro: Não conseguimos encontrar a cena.")
