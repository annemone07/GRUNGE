extends Node3D

@onready var p1_guitar_btn: Button = $Control/Button
@onready var p1_drums_btn: Button = $Control/Button2
@onready var p2_guitar_btn: Button = $Control/Button3
@onready var p2_drums_btn: Button = $Control/Button4
@onready var coop_check: CheckButton = $Control/CheckButton

func _ready() -> void:
	_update_visual_selection()

func _update_visual_selection() -> void:
	# Player 1
	p1_guitar_btn.disabled = (Globals.instrumento_1 == "guitar")
	p1_drums_btn.disabled = (Globals.instrumento_1 == "drums")
	
	# Player 2
	p2_guitar_btn.disabled = (Globals.instrumento_2 == "guitar")
	p2_drums_btn.disabled = (Globals.instrumento_2 == "drums")

# Player 1 
func _on_button_pressed() -> void:
	Globals.instrumento_1 = "guitar"
	_update_visual_selection()

func _on_button_2_pressed() -> void:
	Globals.instrumento_1 = "drums"
	_update_visual_selection()

# Player 2 
func _on_button_3_pressed() -> void:
	Globals.instrumento_2 = "guitar"
	_update_visual_selection()

func _on_button_4_pressed() -> void:
	Globals.instrumento_2 = "drums"
	_update_visual_selection()

# Botão Continuar
func _on_button_5_pressed() -> void:
	var stage_scene = load("res://scenes/play_map.tscn")
	var old_stage_id = get_tree().root.get_node("Main").get_child_count() - 1
	if stage_scene:
		var stage = stage_scene.instantiate()
		get_tree().root.get_node("Main").add_child(stage)
		get_tree().root.get_node("Main").get_child(old_stage_id).queue_free()
	else:
		print("Erro: Não conseguimos encontrar a cena.")

# Botão de Co-op
func _on_check_button_toggled(toggled_on: bool) -> void:
	p2_guitar_btn.visible = toggled_on
	p2_drums_btn.visible = toggled_on
	$Control/Label2.visible = toggled_on
