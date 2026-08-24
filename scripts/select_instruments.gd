extends Node3D

@onready var p1_guitar_btn: Button = $Control/Button
@onready var p1_drums_btn: Button = $Control/Button2
@onready var p1_vocal_btn: Button = $Control/Button6
@onready var p1_bass_btn: Button = $Control/Button7

@onready var p2_guitar_btn: Button = $Control/Button3
@onready var p2_drums_btn: Button = $Control/Button4
@onready var p2_vocal_btn: Button = $Control/Button8
@onready var p2_bass_btn: Button = $Control/Button9

@onready var coop_check: CheckButton = $Control/CheckButton

func _ready() -> void:
	if Globals.instrumento_1 == "" or Globals.instrumento_1 == null:
		Globals.instrumento_1 = "guitar"
	if Globals.instrumento_2 == "" or Globals.instrumento_2 == null:
		Globals.instrumento_2 = "guitar"

	coop_check.button_pressed = true
	Globals.is_single_player = not coop_check.button_pressed
	
	_update_visual_selection()
	_update_coop_visibility(coop_check.button_pressed)

func _update_visual_selection() -> void:
	p1_guitar_btn.disabled = (Globals.instrumento_1 == "guitar")
	p1_drums_btn.disabled = (Globals.instrumento_1 == "drums")
	p1_vocal_btn.disabled = (Globals.instrumento_1 == "vocal")
	p1_bass_btn.disabled = (Globals.instrumento_1 == "bass")
	
	p2_guitar_btn.disabled = (Globals.instrumento_2 == "guitar")
	p2_drums_btn.disabled = (Globals.instrumento_2 == "drums")
	p2_vocal_btn.disabled = (Globals.instrumento_2 == "vocal")
	p2_bass_btn.disabled = (Globals.instrumento_2 == "bass")

func _update_coop_visibility(toggled_on: bool) -> void:
	Globals.is_single_player = not toggled_on
	
	p2_guitar_btn.visible = toggled_on
	p2_drums_btn.visible = toggled_on
	p2_vocal_btn.visible = toggled_on
	p2_bass_btn.visible = toggled_on
	
	if $Control.has_node("Label2"):
		$Control/Label2.visible = toggled_on

func _on_button_pressed() -> void:
	Globals.instrumento_1 = "guitar"
	_update_visual_selection()

func _on_button_2_pressed() -> void:
	Globals.instrumento_1 = "drums"
	_update_visual_selection()

func _on_button_6_pressed() -> void:
	Globals.instrumento_1 = "vocal"
	_update_visual_selection()

func _on_button_7_pressed() -> void:
	Globals.instrumento_1 = "bass"
	_update_visual_selection()

func _on_button_3_pressed() -> void:
	Globals.instrumento_2 = "guitar"
	_update_visual_selection()

func _on_button_4_pressed() -> void:
	Globals.instrumento_2 = "drums"
	_update_visual_selection()

func _on_button_8_pressed() -> void:
	Globals.instrumento_2 = "vocal"
	_update_visual_selection()

func _on_button_9_pressed() -> void:
	Globals.instrumento_2 = "bass"
	_update_visual_selection()

func _on_check_button_toggled(toggled_on: bool) -> void:
	_update_coop_visibility(toggled_on)

func _on_button_5_pressed() -> void:
	var stage_scene = load("res://scenes/play_map.tscn")
	var old_stage_id = get_tree().root.get_node("Main").get_child_count() - 1
	if stage_scene:
		var stage = stage_scene.instantiate()
		get_tree().root.get_node("Main").add_child(stage)
		get_tree().root.get_node("Main").get_child(old_stage_id).queue_free()
	else:
		print("Erro: Não conseguimos encontrar a cena.")
