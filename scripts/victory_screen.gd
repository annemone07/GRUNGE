extends Node2D

@onready var title_label: Label = $Control/VBoxContainer/TitleLabel
@onready var score_label: Label = $Control/VBoxContainer/ScoreLabel
@onready var combo_label: Label = $Control/VBoxContainer/ComboLabel

func _ready() -> void:
	_setup_screen()

func _setup_screen() -> void:
	var accuracy: float = 0.0
	if "total_notes" in Globals and Globals.total_notes > 0:
		accuracy = (float(Globals.notes_hit) / float(Globals.total_notes)) * 100.0
	else:
		accuracy = 88.0 

	if accuracy >= 85.0:
		var epic_titles = ["PERFEITO!!!", "DAMMNN!!", "O QUE!?? PERFEITO!"]
		title_label.text = epic_titles.pick_random()
	else:
		title_label.text = "Vocês mandaram muito!"

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
	
	var menu_scene = load("res://scenes/selectMusic.tscn")
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
