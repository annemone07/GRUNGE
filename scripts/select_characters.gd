extends Node2D

const PANEL_SCENE = preload("res://scenes/character_panel.tscn")
# Carrega a sua fonte logo no início
const FONTE_NOME = preload("res://assets/fonts/Roboto_Condensed-Medium.ttf")

var label_inst_p1: Label
var label_inst_p2: Label

@onready var players_container = $UI 

var sprite_p1: Sprite2D
var sprite_p2: Sprite2D

# Variáveis para guardar os nossos textos
var label_p1: Label
var label_p2: Label

func _input(event: InputEvent) -> void:
	if (
		event.is_action_pressed("customAction_player1_pedal")
		or event.is_action_pressed("customAction_player2_pedal")
	):
		_on_start_game_pressed()

func _ready() -> void:
	Globals.personagem_1 = ""
	Globals.personagem_2 = ""
	
	for child in players_container.get_children():
		child.queue_free()
		
	var estilo_texto = LabelSettings.new()
	if FONTE_NOME:
		estilo_texto.font = FONTE_NOME
	estilo_texto.font_size = 55
			
	# --- PAINEL DO PLAYER 1 ---
	var panel_p1 = PANEL_SCENE.instantiate()
	panel_p1.player_id = 1
	players_container.add_child(panel_p1)
	
	var caixa_p1 = Control.new()
	caixa_p1.custom_minimum_size = Vector2(300, 0)
	players_container.add_child(caixa_p1)
	
	# Cria o Texto
	label_p1 = Label.new()
	label_p1.label_settings = estilo_texto
	label_p1.custom_minimum_size = Vector2(300, 0) 
	label_p1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_p1.position = Vector2(100, 80) 
	caixa_p1.add_child(label_p1)
	
	# Cria a imagem mantendo a posição que você definiu!
	sprite_p1 = Sprite2D.new()
	sprite_p1.scale = Vector2(0.5, 0.5) 
	sprite_p1.position = Vector2(250, 350) 
	caixa_p1.add_child(sprite_p1)
	
	panel_p1.cursor_moveu.connect(_on_cursor_moveu)
	
	# Variáveis para a caixa do P2 (criadas aqui para uso posterior)
	var caixa_p2: Control
	
	if Globals.is_single_player:
		players_container.alignment = BoxContainer.ALIGNMENT_BEGIN
		players_container.offset_left = 150
		players_container.add_theme_constant_override("separation", 150) 
	else:
		players_container.alignment = BoxContainer.ALIGNMENT_CENTER
		players_container.offset_left = 0
		players_container.add_theme_constant_override("separation", 50)
			
		# --- SPRITE E PAINEL DO PLAYER 2 ---
		caixa_p2 = Control.new()
		caixa_p2.custom_minimum_size = Vector2(300, 0) 
		players_container.add_child(caixa_p2)
		
		# Texto do P2
		label_p2 = Label.new()
		label_p2.label_settings = estilo_texto
		label_p2.custom_minimum_size = Vector2(300, 0)
		label_p2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label_p2.position = Vector2(0, 80) 
		caixa_p2.add_child(label_p2)
		
		sprite_p2 = Sprite2D.new()
		sprite_p2.scale = Vector2(0.5, 0.5)
		sprite_p2.position = Vector2(150, 350)
		caixa_p2.add_child(sprite_p2)
		
		var panel_p2 = PANEL_SCENE.instantiate()
		panel_p2.player_id = 2
		var label_p2_ui = panel_p2.get_node_or_null("Label")
		if label_p2_ui:
			label_p2_ui.text = "PLAYER 2"
		players_container.add_child(panel_p2)
		
		panel_p2.cursor_moveu.connect(_on_cursor_moveu)
		
	# --- ESTILO PARA O TEXTO DO INSTRUMENTO (TAMANHO 22) ---
	var estilo_inst = LabelSettings.new()
	if FONTE_NOME:
		estilo_inst.font = FONTE_NOME
	estilo_inst.font_size = 22

	# --- CRIANDO LABEL DO INSTRUMENTO (PLAYER 1) ---
	label_inst_p1 = Label.new()
	label_inst_p1.label_settings = estilo_inst
	label_inst_p1.custom_minimum_size = Vector2(300, 0)
	label_inst_p1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_inst_p1.position = Vector2(100, 160) 
	caixa_p1.add_child(label_inst_p1)

	# --- CRIANDO LABEL DO INSTRUMENTO (PLAYER 2) ---
	# Só cria e adiciona se o multiplayer estiver ativo e a caixa_p2 existir
	if not Globals.is_single_player and caixa_p2:
		label_inst_p2 = Label.new()
		label_inst_p2.label_settings = estilo_inst
		label_inst_p2.custom_minimum_size = Vector2(300, 0)
		label_inst_p2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label_inst_p2.position = Vector2(0, 160) 
		caixa_p2.add_child(label_inst_p2)

# --- A MÁGICA DOS NOMES E INSTRUMENTOS ---
func _on_cursor_moveu(nome_base: String, p_id: int) -> void:
	var caminho = "res://assets/personagens/" + nome_base + "_capa.png"
	
	# Transforma o nome para CAPSLOCK
	var nome_maiusculo = nome_base.to_upper()
	
	# Dicionário para traduzir o instrumento para o cargo correspondente
	var cargo_instrumento = ""
	var nome_minusculo = nome_base.to_lower()
	
	if nome_minusculo in ["locs", "mago"]:
		cargo_instrumento = "BAIXISTA"
	elif nome_minusculo in ["emo", "et"]:
		cargo_instrumento = "GUITARRISTA"
	elif nome_minusculo in ["macaco", "palhaco"]:
		cargo_instrumento = "BATERISTA"
	elif nome_minusculo in ["robo", "nana"]:
		cargo_instrumento = "VOCALISTA"
	
	if ResourceLoader.exists(caminho):
		var nova_textura = load(caminho)
		
		if p_id == 1:
			if sprite_p1: sprite_p1.texture = nova_textura
			if label_p1: label_p1.text = nome_maiusculo
			if label_inst_p1: label_inst_p1.text = cargo_instrumento
				
		elif p_id == 2:
			if sprite_p2: sprite_p2.texture = nova_textura
			if label_p2: label_p2.text = nome_maiusculo
			if label_inst_p2: label_inst_p2.text = cargo_instrumento
	else:
		print("Faltou a imagem no diretório: ", caminho)


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
