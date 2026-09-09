extends Control

@onready var menu_container: VBoxContainer = $menuContainer
@onready var settings_container: Panel = $settingsContainer
@onready var highscores_container: Panel = $highscoresContainer
@onready var credits_container: Panel = $creditsContainer

func _ready() -> void:
	# Define o foco inicial no primeiro botão (Play Game)
	_focus_main_menu()

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

	# 2. Voltar com controle/teclado
	var is_back = Input.is_action_just_pressed("customAction_player1_back") or \
				  Input.is_action_just_pressed("customAction_player2_back") or \
				  Input.is_action_just_pressed("ui_cancel")

	if is_back:
		# Se algum painel secundário estiver aberto, o botão de voltar fecha ele
		if highscores_container.visible or credits_container.visible or settings_container.visible:
			get_viewport().set_input_as_handled()
			_on_back_button_pressed()

func _focus_main_menu() -> void:
	if menu_container and menu_container.get_child_count() > 0:
		var start_btn = menu_container.get_node_or_null("startButton")
		if start_btn:
			start_btn.grab_focus()

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

func _on_highscores_button_pressed() -> void:
	menu_container.visible = false
	highscores_container.visible = true
	var back_btn = highscores_container.get_node_or_null("backButton")
	if back_btn:
		back_btn.grab_focus()

func _on_credits_button_pressed() -> void:
	menu_container.visible = false
	credits_container.visible = true
	var back_btn = credits_container.get_node_or_null("backButton")
	if back_btn:
		back_btn.grab_focus()

func _on_exit_button_pressed() -> void:
	get_tree().quit()

func _on_back_button_pressed() -> void:
	settings_container.visible = false
	highscores_container.visible = false
	credits_container.visible = false
	menu_container.visible = true
	_focus_main_menu()
