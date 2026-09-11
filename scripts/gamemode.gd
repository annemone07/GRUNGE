extends Control

@onready var control_moldura: Control = $controlMoldura
@onready var control_botoes: Control = $VBoxContainer
@onready var moldura_pos: Node2D = $controlMoldura/Node2D
@onready var moldura: TextureRect = $controlMoldura/Node2D/TextureRect2

@onready var vbox = $VBoxContainer

var boxId = 0
var menuCards = []
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
	# Garantir que a moldura fique por cima de tudo
	var botoes = vbox.get_children()
	for botao in botoes:
		if botao is Button:
			botao.pivot_offset = botao.size / 2
			
			botao.focus_entered.connect(_button_selected.bind(botao))
			botao.mouse_entered.connect(_button_selected.bind(botao))
			botao.focus_exited.connect(_button_deselected.bind(botao))
			botao.mouse_exited.connect(_button_deselected.bind(botao))
			
			_aplicar_estilo_normal(botao)
	
	control_moldura.z_index = 1
	
	menu_size = control_botoes.get_child_count()
	menuCards = control_botoes.get_children()
	
	moldura_pos.position = menuCards[0].position
	
	# Chama a atualização visual no primeiro frame para configurar o estado inicial
	_atualizar_visual()
	get_tree().create_timer(0.2).timeout.connect(func(): pode_interagir = true)


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
			
	# Detecta o exato momento em que o jogador empurrou o analógico (funciona como just_pressed)
	var analog_up = (stick_dir.y < 0 and last_stick_dir.y >= 0)
	var analog_down = (stick_dir.y > 0 and last_stick_dir.y <= 0)
	
	
	last_stick_dir = stick_dir
	
	# --- CHECAGEM DE ENTRADAS (BOTÕES / D-PAD / ANALÓGICO) ---
	if (Input.is_action_just_pressed("customAction_player1_up") or Input.is_action_just_pressed("customAction_player2_up")) or analog_up:
		boxId -= 1
		mudou_selecao = true
	elif (Input.is_action_just_pressed("customAction_player1_down") or Input.is_action_just_pressed("customAction_player2_down")) or analog_down:
		boxId += 1
		mudou_selecao = true
		
	# Limita o cursor
	if boxId < 0:
		boxId = 0
	elif boxId > menu_size - 1:
		boxId = menu_size - 1
		
	# Só atualiza a tela se o jogador moveu o cursor
	if mudou_selecao:
		_atualizar_visual()
		for elemento in menuCards:
			if elemento!=menuCards[boxId]:
				_button_deselected(elemento)
			else:
				_button_selected(elemento)
	
	if (Input.is_action_just_pressed("customAction_player1_select") or Input.is_action_just_pressed("customAction_player2_select")):
		if menuCards[boxId] is Button:
			menuCards[boxId].pressed.emit()



func _atualizar_visual() -> void:
		
	# 2. Mover a moldura COM TWEEN
	var card_atual = menuCards[boxId]
	
	var posicao_alvo = card_atual.global_position + Vector2(card_atual.size.x/2, card_atual.size.y/2)
	if tween_movimento:
		tween_movimento.kill()
		
	tween_movimento = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween_movimento.tween_property(moldura_pos, "global_position", posicao_alvo, 0.15)
	
	var nome_base = card_atual.name.to_lower().replace("_card", "")
	
	# Emite o sinal avisando qual personagem está focado agora
	cursor_moveu.emit(nome_base, player_id)

func _unhandled_input(_event: InputEvent) -> void:
	var is_select = Input.is_action_just_pressed("customAction_player1_select") or \
					Input.is_action_just_pressed("customAction_player2_select") or \
					Input.is_action_just_pressed("ui_accept")
					
	if is_select:
		var focused_node = get_viewport().gui_get_focus_owner()
		if focused_node and focused_node is Button and vbox.get_children().has(focused_node):
			get_viewport().set_input_as_handled()
			focused_node.emit_signal("pressed")

func _button_selected(botao: Button):
	var tween = create_tween()
	tween.tween_property(botao, "scale", Vector2(1.1, 1.1), 0.15).set_trans(Tween.TRANS_SINE)
	_aplicar_estilo_focado(botao)

func _button_deselected(botao: Button):
	var tween = create_tween()
	tween.tween_property(botao, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_SINE)
	_aplicar_estilo_normal(botao)

func _aplicar_estilo_normal(botao: Button):
	var estilo = StyleBoxEmpty.new()
	botao.add_theme_stylebox_override("normal", estilo)
	botao.add_theme_stylebox_override("hover", estilo)
	botao.add_theme_stylebox_override("focus", estilo)
	botao.add_theme_color_override("font_color", Color.WHITE)

func _aplicar_estilo_focado(botao: Button):
	var estilo = StyleBoxFlat.new()
	estilo.bg_color = Color(0, 0, 0, 1) # Preto
	estilo.corner_radius_top_left = 12
	estilo.corner_radius_top_right = 12
	estilo.corner_radius_bottom_left = 12
	estilo.corner_radius_bottom_right = 12
	
	estilo.expand_margin_left = 10
	estilo.expand_margin_right = 10
	estilo.expand_margin_top = 5
	estilo.expand_margin_bottom = 5
	
	botao.add_theme_stylebox_override("normal", estilo)
	botao.add_theme_stylebox_override("hover", estilo)
	botao.add_theme_stylebox_override("focus", estilo)
	botao.add_theme_color_override("font_color", Color.WHITE)

func _on_solo_pressed() -> void:
	Globals.is_single_player = true
	var stage_scene = load("res://scenes/selectCharacters.tscn")
	var old_stage_id = get_tree().root.get_node("Main").get_child_count() - 1
	if stage_scene:
		var stage = stage_scene.instantiate()
		get_tree().root.get_node("Main").add_child(stage)
		get_tree().root.get_node("Main").get_child(old_stage_id).queue_free()
	else:
		print("Erro: Não conseguimos encontrar a cena.")

func _on_multiplayer_pressed() -> void:
	Globals.is_single_player = false
	var stage_scene = load("res://scenes/selectCharacters.tscn")
	var old_stage_id = get_tree().root.get_node("Main").get_child_count() - 1
	if stage_scene:
		var stage = stage_scene.instantiate()
		get_tree().root.get_node("Main").add_child(stage)
		get_tree().root.get_node("Main").get_child(old_stage_id).queue_free()
	else:
		print("Erro: Não conseguimos encontrar a cena.")
