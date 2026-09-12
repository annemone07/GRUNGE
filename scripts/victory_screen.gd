extends Node2D

const STAR_FULL = preload("res://assets/ui/estrela_cheia.png")
const STAR_EMPTY = preload("res://assets/ui/estrela_vazia.png")
@onready var stars_container: HBoxContainer = $Control/VBoxContainer/StarsContainer
@onready var accuracy_label: Label = $Control/VBoxContainer/AccuracyLabel

@onready var title_label: Label = $Control/VBoxContainer/TitleLabel
@onready var score_label: Label = $Control/VBoxContainer/ScoreLabel
@onready var combo_label: Label = $Control/VBoxContainer/ComboLabel
@onready var restart_button: Button = $Control/VBoxContainer/RestartButton
@onready var menu_button: Button = $Control/VBoxContainer/MenuButton

var _is_setup: bool = false

func _ready() -> void:
	if not _is_setup:
		setup_screen(true)

func setup_screen(is_victory: bool = true) -> void:
	_is_setup = true

	var restart_btn = $Control/VBoxContainer/RestartButton

	if is_victory:
		if restart_btn:
			restart_btn.hide() #pra esconder o botão de restart se o jogador vencer
		if menu_button:
			menu_button.text = "Continuar" #pra transformar o botao menu em "continuar" caso vencer.
		var accuracy: float = 0.0
		if "total_notes" in Globals and Globals.total_notes > 0:
			accuracy = (float(Globals.notes_hit) / float(Globals.total_notes)) * 100.0

		if accuracy_label:
			accuracy_label.text = "Precisão: " + str("%.1f" % accuracy) + "%"

		var stars: int = 1
		if accuracy >= 92.0:
			stars = 5
		elif accuracy >= 70.0:
			stars = 4
		elif accuracy >= 50.0:
			stars = 3
		elif accuracy >= 30.0:
			stars = 2

		if stars_container:
			var star_nodes = stars_container.get_children()
			
			for i in range(star_nodes.size()):
				if i < stars:
					star_nodes[i].texture = STAR_FULL
				else:
					star_nodes[i].texture = STAR_EMPTY

		if accuracy >= 85.0:
			var epic_titles = ["PERFEITO!!!", "DAMMNN!!", "O QUE!?? PERFEITO!"]
			title_label.text = epic_titles.pick_random()
		else:
			title_label.text = "Vocês mandaram muito!"
			
		title_label.modulate = Color("ffdf00")

	else:
		if restart_btn:
			restart_btn.show() #garante que vai mostrar o botão de restart se ele perdeu
		if menu_button:
			menu_button.text = "Menu" #pra mostrar o botao menu caso perca, ao inves de "continuar"
		var fail_titles = ["GAME OVER!", "DEU RUIM!", "FALHA!!", "A PLATÉIA OS EXPULSA DO PALCO!"]
		title_label.text = fail_titles.pick_random()
		title_label.modulate = Color("ff4d4d")
		
		if accuracy_label:
			accuracy_label.text = "Precisão: 0.0%"
		if stars_container:
			stars_container.hide()

	var max_combo_val = Globals.max_combo if "max_combo" in Globals else Globals.combo
	combo_label.text = "Maior Combo: x" + str(max_combo_val)

	var final_score = Globals.score
	score_label.text = "Pontuação: 0"
	
	var tween = create_tween()
	tween.tween_method(
		func(val: int): score_label.text = "Pontuação: " + str(val),
		0,
		final_score,
		1.2
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
func _on_restart_button_pressed() -> void:
	_reset_globals()
	
	var main_node = get_tree().root.get_node_or_null("Main")
	var stage_scene = load("res://scenes/play_map.tscn")
	
	if main_node and stage_scene:
		for child in main_node.get_children():
			child.queue_free()
			
		var stage = stage_scene.instantiate()
		main_node.add_child(stage)
	else:
		get_tree().reload_current_scene()

func _on_menu_button_pressed() -> void:
	_reset_globals()
	
	var menu_scene = load("res://scenes/StarterMenu.tscn")
	var main_node = get_tree().root.get_node_or_null("Main")
	
	if menu_scene and main_node:
		var menu = menu_scene.instantiate()
		main_node.add_child(menu)
		get_parent().get_parent().queue_free()
	else:
		get_tree().change_scene_to_packed(menu_scene)

func _reset_globals() -> void:
	Globals.score = 0
	Globals.combo = 0
	if "max_combo" in Globals: Globals.max_combo = 0
	if "notes_hit" in Globals: Globals.notes_hit = 0
	if "total_notes" in Globals: Globals.total_notes = 0
	if "current_life" in Globals: Globals.current_life = 100.0
