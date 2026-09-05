extends Control

@onready var vbox = $VBoxContainer

func _ready():
	var botoes = vbox.get_children()
	
	for botao in botoes:
		if botao is Button:
			botao.pivot_offset = botao.size / 2
			
			botao.focus_entered.connect(_on_button_focus_entered.bind(botao))
			botao.focus_exited.connect(_on_button_focus_exited.bind(botao))
			
			botao.mouse_entered.connect(botao.grab_focus)
			
			_aplicar_estilo_normal(botao)
	
	if botoes.size() > 0:
		botoes[0].grab_focus()

func _unhandled_input(_event: InputEvent) -> void:
	var is_select = Input.is_action_just_pressed("customAction_player1_select") or \
					Input.is_action_just_pressed("customAction_player2_select") or \
					Input.is_action_just_pressed("ui_accept")
					
	if is_select:
		var focused_node = get_viewport().gui_get_focus_owner()
		if focused_node and focused_node is Button and vbox.get_children().has(focused_node):
			get_viewport().set_input_as_handled()
			focused_node.emit_signal("pressed")

func _on_button_focus_entered(botao: Button):
	var tween = create_tween()
	tween.tween_property(botao, "scale", Vector2(1.1, 1.1), 0.15).set_trans(Tween.TRANS_SINE)
	_aplicar_estilo_focado(botao)

func _on_button_focus_exited(botao: Button):
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
	var stage_scene = load("res://scenes/selectMusic.tscn")
	var old_stage_id = get_tree().root.get_node("Main").get_child_count() - 1
	if stage_scene:
		var stage = stage_scene.instantiate()
		get_tree().root.get_node("Main").add_child(stage)
		get_tree().root.get_node("Main").get_child(old_stage_id).queue_free()
	else:
		print("Erro: Não conseguimos encontrar a cena.")

func _on_multiplayer_pressed() -> void:
	Globals.is_single_player = false
	var stage_scene = load("res://scenes/selectMusic.tscn")
	var old_stage_id = get_tree().root.get_node("Main").get_child_count() - 1
	if stage_scene:
		var stage = stage_scene.instantiate()
		get_tree().root.get_node("Main").add_child(stage)
		get_tree().root.get_node("Main").get_child(old_stage_id).queue_free()
	else:
		print("Erro: Não conseguimos encontrar a cena.")
