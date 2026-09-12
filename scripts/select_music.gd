extends Node3D

# Carrega a sua nova cena modular
const MUSIC_ITEM_SCENE = preload("res://scenes/music_sel.tscn")

@onready var vbox_container = $selectMusicScreen/HBoxContainer
@onready var control_moldura: Control = $controlMoldura
@onready var moldura_pos: Node2D = $controlMoldura/Node2D
@onready var moldura: TextureRect = $controlMoldura/Node2D/TextureRect2


var boxId = 0
var menuCards = []
var menuButtons = []
var menu_size = 0
var tween_movimento: Tween
var player_id: int = 1
var confirmado: bool = false
var pode_interagir: bool = false

# Guarda a última direção do analógico para evitar que o cursor fique correndo descontroladamente
var last_stick_dir: Vector2 = Vector2.ZERO

signal cursor_moveu(nome_personagem, player_id)

@export var ajuste_posicao: Vector2 = Vector2(0, 0)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for child in vbox_container.get_children():
		child.queue_free()
		
	_populate_music_list()
	
	# Garantir que a moldura fique por cima de tudo
	control_moldura.z_index = 1
	
	menuCards = vbox_container.get_children()
	
	for child in menuCards:
		for childer in child.get_children():
			if childer is Button:
				menuButtons.append(childer)
				menu_size+=1
	
	for button in menuButtons:
		button.focus_entered.connect(_button_selected)
		button.mouse_entered.connect(_button_selected)
		button.focus_exited.connect(_button_deselected)
		button.mouse_exited.connect(_button_deselected)
		
		_aplicar_estilo_normal(button)
	
	moldura_pos.position = menuButtons[0].position
	
	# Chama a atualização visual no primeiro frame para configurar o estado inicial
	_atualizar_visual()
	get_tree().create_timer(0.1).timeout.connect(func(): pode_interagir = true)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not pode_interagir:
		return
		
	var mudou_selecao = false
	var device_id = player_id - 1 # Player 1 = Controle 0, Player 2 = Controle 1
	
	# --- LEITURA DIRETA DO ANALÓGICO ---
	var raw_x = Input.get_joy_axis(device_id, JOY_AXIS_LEFT_X)
	var raw_y = Input.get_joy_axis(device_id, JOY_AXIS_LEFT_Y)
	
	var stick_dir = Vector2.ZERO
	# Deadzone de 0.5 para ignorar drift do controle
	if abs(raw_x) > 0.5 or abs(raw_y) > 0.5:
		if abs(raw_x) > abs(raw_y):
			stick_dir.x = 1.0 if raw_x > 0 else -1.0
		else:
			stick_dir.y = 1.0 if raw_y > 0 else -1.0
			
	# Detecta o exato momento em que o jogador empurrou o analógico
	var analog_left = (stick_dir.x < 0 and last_stick_dir.x >= 0)
	var analog_right = (stick_dir.x > 0 and last_stick_dir.x <= 0)
	var analog_up = (stick_dir.y < 0 and last_stick_dir.y >= 0)
	var analog_down = (stick_dir.y > 0 and last_stick_dir.y >= 0)
	
	last_stick_dir = stick_dir
	
	# --- CHECAGEM DE ENTRADAS (BOTÕES / D-PAD / ANALÓGICO) ---
	if (Input.is_action_just_pressed("customAction_player1_up") or Input.is_action_just_pressed("customAction_player2_up")) or analog_up:
		boxId -= 1
		mudou_selecao = true
	elif (Input.is_action_just_pressed("customAction_player1_down") or Input.is_action_just_pressed("customAction_player2_down")) or analog_down:
		boxId += 1
		mudou_selecao = true
		
	# Só atualiza a tela se o jogador moveu o cursor
	if mudou_selecao:
		if boxId < 0:
			boxId = 0
		elif boxId > menu_size - 1:
			boxId = menu_size - 1
			
		_atualizar_visual()
		
		# Dá o foco real do Godot para o botão correspondente, disparando o _button_selected corretamente
		if menuButtons.size() > boxId:
			menuButtons[boxId].grab_focus()
	
	if (Input.is_action_just_pressed("customAction_player1_select") or Input.is_action_just_pressed("customAction_player2_select")):
		if menuButtons.size() > boxId and menuButtons[boxId] is Button:
			menuButtons[boxId].pressed.emit()

func _atualizar_visual() -> void:
	if menuCards.size() <= boxId:
		return
		
	var card_atual = menuCards[boxId]
	var posicao_alvo = card_atual.global_position + Vector2(card_atual.size.x / 2, card_atual.size.y / 2)
	
	if tween_movimento:
		tween_movimento.kill()
		
	tween_movimento = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween_movimento.tween_property(moldura_pos, "global_position", posicao_alvo, 0.15)
	
	var nome_base = card_atual.name.to_lower().replace("_card", "")
	cursor_moveu.emit(nome_base, player_id)

func _populate_music_list() -> void:
	for m_id in Globals.music_database:
		var music_data = Globals.music_database[m_id]
		
		var item = MUSIC_ITEM_SCENE.instantiate()
		vbox_container.add_child(item)
		
		item.setup(m_id, music_data["title"], music_data["high_score"])
		
		# Conecta o sinal repassando diretamente o m_id daquela iteração exata do loop
		item.music_selected.connect(func(id): _on_music_item_selected(id))
		
	# Atualiza as referências dos cards e botões após popular a lista
	menuCards = vbox_container.get_children()
	menuButtons.clear()
	menu_size = 0
	
	for child in menuCards:
		for childer in child.get_children():
			if childer is Button:
				menuButtons.append(childer)
				menu_size += 1
				
	for button in menuButtons:
		button.focus_entered.connect(func(): _button_selected(button))
		button.mouse_entered.connect(func(): _button_selected(button))
		button.focus_exited.connect(func(): _button_deselected(button))
		button.mouse_exited.connect(func(): _button_deselected(button))
		_aplicar_estilo_normal(button)

func _unhandled_input(_event: InputEvent) -> void:
	# 1. Confirmação (P1, P2 ou UI padrão)
	var is_select = Input.is_action_just_pressed("customAction_player1_select") or \
					Input.is_action_just_pressed("customAction_player2_select") or \
					Input.is_action_just_pressed("ui_accept")
					
	if is_select:
		var focused_node = get_viewport().gui_get_focus_owner()
		if focused_node and focused_node is Button:
			get_viewport().set_input_as_handled()
			focused_node.emit_signal("pressed")

	# 2. Voltar para a tela anterior (P1, P2 ou UI cancel)
	var is_back = Input.is_action_just_pressed("customAction_player1_back") or \
				  Input.is_action_just_pressed("customAction_player2_back") or \
				  Input.is_action_just_pressed("ui_cancel")

	if is_back:
		get_viewport().set_input_as_handled()
		_go_back_to_gamemode()

func _go_back_to_gamemode() -> void:
	var stage_scene = load("res://scenes/gamemode.tscn")
	var main_node = get_tree().root.get_node_or_null("Main")
	if main_node and stage_scene:
		var old_stage_id = main_node.get_child_count() - 1
		var stage = stage_scene.instantiate()
		main_node.add_child(stage)
		main_node.get_child(old_stage_id).queue_free()

func _on_music_item_selected(selected_id: String) -> void:
	Globals.selected_music = selected_id
	change_scene_to_instruments()

func change_scene_to_instruments() -> void:
	var stage_scene = load("res://scenes/selectCharacters.tscn")
	var main_node = get_tree().root.get_node_or_null("Main")
	if main_node and stage_scene:
		var old_stage_id = main_node.get_child_count() - 1
		var stage = stage_scene.instantiate()
		main_node.add_child(stage)
		main_node.get_child(old_stage_id).queue_free()
	else:
		print("Erro: Não conseguimos encontrar a cena.")

func _button_selected(button: Node = null) -> void:
	# Encontra qual botão/card foi selecionado para atualizar o boxId corretamente
	var index = menuButtons.find(button)
	if index != -1 and index != boxId:
		boxId = index
		_atualizar_visual()

	if button:
		button.pivot_offset = button.size / 2
		var tween = create_tween()
		tween.tween_property(button, "scale", Vector2(1.1, 1.1), 0.15).set_trans(Tween.TRANS_SINE)
		_aplicar_estilo_focado(button)
		
		# Procura o card pai para ativar o letreiro
		var card = button.get_parent()
		if card in menuCards:
			card.rolando_texto = true
			card.tempo_scroll = 0.0

func _button_deselected(button: Node = null) -> void:
	if button:
		var tween = create_tween()
		tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_SINE)
		_aplicar_estilo_normal(button)
		
		var card = button.get_parent()
		if card in menuCards:
			card.rolando_texto = false
			button.text = card.texto_original



func _aplicar_estilo_normal(button) -> void:
	var estilo = StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", estilo)
	button.add_theme_stylebox_override("hover", estilo)
	button.add_theme_stylebox_override("focus", estilo)
	button.add_theme_color_override("font_color", Color.WHITE)

func _aplicar_estilo_focado(button) -> void:
	var estilo = StyleBoxFlat.new()
	estilo.bg_color = Color(0, 0, 0, 1)
	estilo.corner_radius_top_left = 12
	estilo.corner_radius_top_right = 12
	estilo.corner_radius_bottom_left = 12
	estilo.corner_radius_bottom_right = 12
	
	estilo.expand_margin_left = 10
	estilo.expand_margin_right = 10
	estilo.expand_margin_top = 5
	estilo.expand_margin_bottom = 5
	
	button.add_theme_stylebox_override("normal", estilo)
	button.add_theme_stylebox_override("hover", estilo)
	button.add_theme_stylebox_override("focus", estilo)
	button.add_theme_color_override("font_color", Color.WHITE)
