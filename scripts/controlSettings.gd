extends Control

@onready var control_moldura: Control = $controlMoldura
@onready var control_botoes: Control = $controlBotoes
@onready var moldura_pos: Node2D = $controlMoldura/Node2D
@onready var moldura: TextureRect = $controlMoldura/Node2D/TextureRect2


var boxId = 0
var menuCards = []
var menu_size = 0
var tween_movimento: Tween
var player_id: int = 1
var confirmado: bool = false
var pode_interagir: bool = false
var slider_listening = false

# Guarda a última direção do analógico para evitar que o cursor fique correndo descontroladamente
var last_stick_dir: Vector2 = Vector2.ZERO

signal cursor_moveu(nome_personagem, player_id)

@export var ajuste_posicao: Vector2 = Vector2(0, 0)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Garantir que a moldura fique por cima de tudo
	control_moldura.z_index = 1
	
	menu_size = control_botoes.get_child_count()
	menuCards = control_botoes.get_children()
	
	moldura_pos.position = menuCards[0].position
	
	# Chama a atualização visual no primeiro frame para configurar o estado inicial
	call_deferred("_atualizar_visual")
	get_tree().create_timer(1.0).timeout.connect(func(): pode_interagir = true)


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
	var analog_left = (stick_dir.x < 0 and last_stick_dir.x >= 0)
	var analog_right = (stick_dir.x > 0 and last_stick_dir.x <= 0)
	
	
	last_stick_dir = stick_dir
	
	# --- CHECAGEM DE ENTRADAS (BOTÕES / D-PAD / ANALÓGICO) ---
	if (Input.is_action_just_pressed("customAction_player1_left") or Input.is_action_just_pressed("customAction_player2_left")) or analog_left:
		if not slider_listening:
			boxId -= 1
			mudou_selecao = true
		else:
			menuCards[boxId].value-=0.1
	elif (Input.is_action_just_pressed("customAction_player1_right") or Input.is_action_just_pressed("customAction_player2_right")) or analog_right:
		if not slider_listening:
			boxId += 1
			mudou_selecao = true
		else:
			menuCards[boxId].value+=0.1
	
	if slider_listening and (Input.is_action_just_pressed("customAction_player1_back") or Input.is_action_just_pressed("customAction_player2_back")):
		slider_listening=false
		
	# Limita o cursor
	if boxId < 0:
		boxId = 0
	elif boxId > menu_size - 1:
		boxId = menu_size - 1
		
	# Só atualiza a tela se o jogador moveu o cursor
	if mudou_selecao:
		_atualizar_visual()
	
	if (Input.is_action_just_pressed("customAction_player1_select") or Input.is_action_just_pressed("customAction_player2_select")):
		if menuCards[boxId] is Button:
			menuCards[boxId].pressed.emit()
		elif(menuCards[boxId] is HSlider):
			slider_listening=true



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
