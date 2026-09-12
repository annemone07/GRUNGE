extends Control

@onready var start_button: Button = $menuContainer/startButton

@onready var menu_container: VBoxContainer = $menuContainer
@onready var settings_container: Panel = $settingsContainer
@onready var highscores_container: Panel = $highscoresContainer
@onready var credits_container: Panel = $creditsContainer

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
	menuButtons = menu_container.get_children()
	menuButtonCount = menu_container.get_child_count()
	moldura_pos.global_position = Vector2(start_button.position.x, menu_container.position.y+start_button.size.y/2)
	
	var nome_base = menuButtons[boxId].name.to_lower()
	cursor_moveu.emit(nome_base, player_id)

	
	
	
func _process(delta: float) -> void:
	await get_tree().create_timer(0.1).timeout
	
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

	# 2. Voltar com controle/teclado
	var is_back = Input.is_action_just_pressed("customAction_player1_back") or \
				  Input.is_action_just_pressed("customAction_player2_back") or \
				  Input.is_action_just_pressed("ui_cancel")

	if is_back:
		# Se algum painel secundário estiver aberto, o botão de voltar fecha ele
		if highscores_container.visible or credits_container.visible or settings_container.visible:
			get_viewport().set_input_as_handled()
			_on_back_button_pressed()

func _on_start_button_pressed() -> void:
	var stage_scene = load("res://scenes/gamemode.tscn")
	var main_node = get_tree().root.get_node_or_null("Main")
	if main_node and stage_scene:
		var old_stage_id = main_node.get_child_count() - 1
		var stage = stage_scene.instantiate()
		main_node.add_child(stage)
		main_node.get_child(old_stage_id).queue_free()
	else:
		print("Erro: Não conseguimos encontrar a cena.")

func _on_settings_button_pressed() -> void:
	var stage_scene = load("res://scenes/settings.tscn")
	var main_node = get_tree().root.get_node_or_null("Main")
	if main_node and stage_scene:
		var old_stage_id = main_node.get_child_count() - 1
		var stage = stage_scene.instantiate()
		main_node.add_child(stage)
		main_node.get_child(old_stage_id).queue_free()
	else:
		print("Erro: Não conseguimos encontrar a cena.")

func _on_exit_button_pressed() -> void:
	get_tree().quit()

func _on_back_button_pressed() -> void:
	settings_container.visible = false
	highscores_container.visible = false
	credits_container.visible = false
	menu_container.visible = true
	#_focus_main_menu()

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


func _on_credits_button_pressed() -> void:
	var stage_scene = load("res://scenes/creditos.tscn")
	var main_node = get_tree().root.get_node_or_null("Main")
	if main_node and stage_scene:
		var old_stage_id = main_node.get_child_count() - 1
		var stage = stage_scene.instantiate()
		main_node.add_child(stage)
		main_node.get_child(old_stage_id).queue_free()
	else:
		print("Erro: Não conseguimos encontrar a cena.")
