extends Node2D

const PANEL_SCENE = preload("res://scenes/character_panel.tscn")

# Aponta direto para o HBoxContainer que organiza o layout
@onready var players_container = $UI 

func _ready() -> void:
	Globals.personagem_1 = ""
	Globals.personagem_2 = ""
	
	for child in players_container.get_children():
		child.queue_free()
			
	if Globals.is_single_player:
		players_container.alignment = BoxContainer.ALIGNMENT_BEGIN
		players_container.offset_left = 150
	else:
		players_container.alignment = BoxContainer.ALIGNMENT_CENTER
		players_container.offset_left = 0
			
	# Instancia o painel do Player 1
	var panel_p1 = PANEL_SCENE.instantiate()
	panel_p1.player_id = 1
	players_container.add_child(panel_p1)
	
	# Se for multiplayer, instancia o painel do Player 2 ao lado
	if not Globals.is_single_player:
		var panel_p2 = PANEL_SCENE.instantiate()
		panel_p2.player_id = 2
		var label_p2 = panel_p2.get_node_or_null("Label")
		if label_p2:
			label_p2.text = "PLAYER 2"
		players_container.add_child(panel_p2)
		
	_focar_primeiro_card(panel_p1)

func _focar_primeiro_card(panel) -> void:
	var grid = panel.get_node_or_null("GridContainer")
	if grid and grid.get_child_count() > 0:
		var primeiro_card = grid.get_child(0)
		var botao = primeiro_card.get_node_or_null("Button")
		if botao:
			botao.grab_focus()

func _on_start_game_pressed() -> void:
	print("P1 Personagem: ", Globals.personagem_1)
	if not Globals.is_single_player:
		print("P2 Personagem: ", Globals.personagem_2)

	if Globals.personagem_1 != "":
		if not Globals.is_single_player and Globals.personagem_2 == "":
			print("Aguardando o Player 2 escolher...")
			return
			
		_iniciar_play_map()

func _iniciar_play_map() -> void:
	var stage_scene = load("res://scenes/play_map.tscn")
	var old_stage_id = get_tree().root.get_node("Main").get_child_count() - 1
	if stage_scene:
		var stage = stage_scene.instantiate()
		get_tree().root.get_node("Main").add_child(stage)
		get_tree().root.get_node("Main").get_child(old_stage_id).queue_free()
	else:
		print("ERRO LOG: Não foi possível carregar play_map.tscn")
