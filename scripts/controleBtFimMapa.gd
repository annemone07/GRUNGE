extends Control

@onready var moldura_pos: Node2D = $controlMoldura/Node2D
@onready var moldura: TextureRect = $controlMoldura/Node2D/TextureRect2

var boxId = 0
var menuButtons = []
var menuButtonCount = 0
var tween_movimento: Tween
var player_id: int = 1
var confirmado: bool = false
var pode_interagir: bool = false

# Guarda a última direção do analógico para evitar que o cursor fique correndo descontroladamente
var last_stick_dir: Vector2 = Vector2.ZERO

signal cursor_moveu(nome_personagem, player_id)

@export var ajuste_posicao: Vector2 = Vector2(0, 0)

func _ready() -> void:
	# Define o foco inicial no primeiro botão (Play Game)
	#_focus_main_menu()
	menuButtons = get_children()
	for child in menuButtons:
		if child is not Button:
			menuButtons.erase(child)
	menuButtonCount = len(menuButtons)
	
	
	moldura_pos.global_position = Vector2(menuButtons[0].position.x, position.y+menuButtons[0].size.y/2)
	
	var nome_base = menuButtons[boxId].name.to_lower()
	cursor_moveu.emit(nome_base, player_id)
	
	
func _process(delta: float) -> void:
	var mudou_selecao = false
	var device_id = player_id-1  # Player 1 = Controle 0, Player 2 = Controle 1
	
	
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
	var analog_left = (stick_dir.x < 0 and last_stick_dir.x >= 0)
	var analog_right = (stick_dir.x > 0 and last_stick_dir.x <= 0)
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
	elif boxId > menuButtonCount - 1:
		boxId = menuButtonCount - 1
		
	# Só atualiza a tela se o jogador moveu o cursor
	if mudou_selecao:
		_atualizar_visual()
	
	if (Input.is_action_just_pressed("customAction_player1_select") or Input.is_action_just_pressed("customAction_player2_select")):
		if menuButtons[boxId] is Button:
			print(menuButtons[boxId].name)
			menuButtons[boxId].pressed.emit()

func _unhandled_input(_event: InputEvent) -> void:
	# 1. Confirmação com controle/teclado
	var is_select = Input.is_action_just_pressed("customAction_player1_select") or \
					Input.is_action_just_pressed("customAction_player2_select") or \
					Input.is_action_just_pressed("ui_accept")

	if is_select:
		var focused_node = get_viewport().gui_get_focus_owner()
		if focused_node and focused_node is Button:
			get_viewport().set_input_as_handled()
			focused_node.emit_signal("pressed")

func _atualizar_visual() -> void:
		
	#Mover a moldura com tween
	var botaoAtual = menuButtons[boxId]
	
	var posicao_alvo = botaoAtual.global_position + Vector2(botaoAtual.size.x/2, botaoAtual.size.y/2)
	if tween_movimento:
		tween_movimento.kill()
		
	tween_movimento = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween_movimento.tween_property(moldura_pos, "global_position", posicao_alvo, 0.15)
	
	var nome_base = botaoAtual.name.to_lower()
	
	cursor_moveu.emit(nome_base, player_id)
