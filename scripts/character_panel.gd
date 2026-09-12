extends VBoxContainer

var tween_movimento: Tween
var player_id: int = 1
var confirmado: bool = false
var pode_interagir: bool = false

# Guarda a última direção do analógico para evitar que o cursor fique correndo descontroladamente
var last_stick_dir: Vector2 = Vector2.ZERO

signal cursor_moveu(nome_personagem, player_id)

@export var ajuste_posicao: Vector2 = Vector2(0, 0)

@onready var personagens = {
	"Locs":"bass",
	"Mago":"bass",
	"Emo":"guitar",
	"ET":"guitar",
	"Monkey":"drums",
	"Clown":"drums",
	"Robo":"vocal",
	"Nana":"vocal",
}
var boxId = 0
var menuCards = []
var menu_size = 0

@onready var grid_container = $GridContainer
@onready var moldura = $Control/TextureRect2 # Pega a referência da moldura

func _ready() -> void:
	# Garantir que a moldura fique por cima de tudo
	$Control.z_index = 1 
	
	menu_size = grid_container.get_child_count()
	menuCards = grid_container.get_children()
	
	# Chama a atualização visual no primeiro frame para configurar o estado inicial
	call_deferred("_atualizar_visual")
	get_tree().create_timer(1.0).timeout.connect(func(): pode_interagir = true)

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
	var analog_left = (stick_dir.x < 0 and last_stick_dir.x >= 0)
	var analog_right = (stick_dir.x > 0 and last_stick_dir.x <= 0)
	
	last_stick_dir = stick_dir
	
	# --- CHECAGEM DE ENTRADAS (BOTÕES / D-PAD / ANALÓGICO) ---
	if Input.is_action_just_pressed("customAction_player" + str(player_id) + "_up") or analog_up:
		boxId -= 2
		mudou_selecao = true
	elif Input.is_action_just_pressed("customAction_player" + str(player_id) + "_down") or analog_down:
		boxId += 2
		mudou_selecao = true
	elif Input.is_action_just_pressed("customAction_player" + str(player_id) + "_left") or analog_left:
		boxId -= 1
		mudou_selecao = true
	elif Input.is_action_just_pressed("customAction_player" + str(player_id) + "_right") or analog_right:
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
		
	if Input.is_action_just_pressed("customAction_player" + str(player_id) + "_select"):
		_on_character_pressed(personagens.keys()[boxId], personagens.values()[boxId])


func _atualizar_visual() -> void:
	# 1. Atualizar as texturas dos cards
	for i in range(menu_size):
		var card = menuCards[i]
		var esta_selecionado = (i == boxId)
		if card.has_method("atualizar_selecao"):
			card.atualizar_selecao(esta_selecionado)
	
	# 2. Mover a moldura COM TWEEN
	var card_atual = menuCards[boxId]
	var offset_x = (moldura.size.x - card_atual.size.x) / 2.0
	var offset_y = (moldura.size.y - card_atual.size.y) / 2.0
	
	var posicao_alvo = card_atual.global_position - Vector2(offset_x, offset_y) + ajuste_posicao
	
	if tween_movimento:
		tween_movimento.kill()
		
	tween_movimento = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween_movimento.tween_property(moldura, "global_position", posicao_alvo, 0.15)
	
	var nome_base = card_atual.name.to_lower().replace("_card", "")
	
	# Emite o sinal avisando qual personagem está focado agora
	cursor_moveu.emit(nome_base, player_id)


func _on_character_pressed(nome: String, instrumento: String) -> void:
	confirmado = true
	moldura.modulate = Color(0.2, 1.0, 0.2)
	print("Player ", player_id, " escolheu o personagem: ", nome, " (Instrumento: ", instrumento, ")")
	
	if player_id == 1:
		Globals.personagem_1 = nome
		Globals.instrumento_1 = instrumento
	else:
		Globals.personagem_2 = nome
		Globals.instrumento_2 = instrumento
