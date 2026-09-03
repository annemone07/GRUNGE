extends Node3D

const INSTRUMENT_SCENE = preload("res://scenes/instruments.tscn")

@onready var players_container = $Control/HBoxContainer
@onready var continue_btn = $Control/Button5 

func _ready() -> void:
	for child in players_container.get_children():
		child.queue_free()

	if Globals.instrumento_1 == "" or Globals.instrumento_1 == null:
		Globals.instrumento_1 = "guitar"
	_instantiate_player_panel(1)

	if not Globals.is_single_player:
		if Globals.instrumento_2 == "" or Globals.instrumento_2 == null:
			Globals.instrumento_2 = "guitar"
		_instantiate_player_panel(2)

func _instantiate_player_panel(id: int) -> void:
	var panel = INSTRUMENT_SCENE.instantiate()
	panel.player_id = id
	players_container.add_child(panel)

func _on_continue_pressed() -> void:
	var stage_scene = load("res://scenes/play_map.tscn")
	var old_stage_id = get_tree().root.get_node("Main").get_child_count() - 1
	if stage_scene:
		var stage = stage_scene.instantiate()
		get_tree().root.get_node("Main").add_child(stage)
		get_tree().root.get_node("Main").get_child(old_stage_id).queue_free()
	else:
		print("Erro: Não conseguimos encontrar a cena.")
