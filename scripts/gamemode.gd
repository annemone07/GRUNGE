extends Control

@onready var vbox = $VBoxContainer

func _ready():
	# fiz com IA pq nao sei arrumar bonitinho esses efeitos visuais, espero q n se incomode
	var botoes = vbox.get_children()
	
	for botao in botoes:
		if botao is Button:
			# Centraliza o eixo de escala para o botão crescer a partir do meio
			botao.pivot_offset = botao.size / 2
			
			# Conecta os sinais de foco
			botao.focus_entered.connect(_on_button_focus_entered.bind(botao))
			botao.focus_exited.connect(_on_button_focus_exited.bind(botao))
			
			# Faz o mouse também puxar o foco (opcional, mas bom para PC)
			botao.mouse_entered.connect(botao.grab_focus)
			
			# Aplica o estilo inicial (sem fundo)
			_aplicar_estilo_normal(botao)
	
	if botoes.size() > 0:
		botoes[0].grab_focus()

func _on_button_focus_entered(botao: Button):
	# Tween para crescer o botão
	var tween = create_tween()
	tween.tween_property(botao, "scale", Vector2(1.1, 1.1), 0.15).set_trans(Tween.TRANS_SINE)
	
	_aplicar_estilo_focado(botao)

func _on_button_focus_exited(botao: Button):
	# Tween para voltar ao tamanho original
	var tween = create_tween()
	tween.tween_property(botao, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_SINE)
	
	_aplicar_estilo_normal(botao)

func _aplicar_estilo_normal(botao: Button):
	# Estilo invisível/vazio
	var estilo = StyleBoxEmpty.new()
	
	botao.add_theme_stylebox_override("normal", estilo)
	botao.add_theme_stylebox_override("hover", estilo)
	botao.add_theme_stylebox_override("focus", estilo)
	botao.add_theme_color_override("font_color", Color.WHITE)

func _aplicar_estilo_focado(botao: Button):
	# Estilo com fundo preto e bordas arredondadas (fofinho)
	var estilo = StyleBoxFlat.new()
	estilo.bg_color = Color(0, 0, 0, 1) # Preto
	estilo.corner_radius_top_left = 12
	estilo.corner_radius_top_right = 12
	estilo.corner_radius_bottom_left = 12
	estilo.corner_radius_bottom_right = 12
	
	# Margem para o texto não ficar colado nas bordas pretas
	estilo.expand_margin_left = 10
	estilo.expand_margin_right = 10
	estilo.expand_margin_top = 5
	estilo.expand_margin_bottom = 5
	
	# O botão fica com esse estilo quando está em foco ou com mouse em cima
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
