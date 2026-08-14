extends Node3D

@onready var menu_button: MenuButton = $Control/MenuButton
@onready var menu_button_2: MenuButton = $Control/MenuButton2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	



func _on_button_pressed() -> void:
	Globals.instrumento_1 = "guitar"

func _on_button_2_pressed() -> void:
	Globals.instrumento_1 = "drums"

func _on_button_3_pressed() -> void:
	Globals.instrumento_2 = "guitar"

func _on_button_4_pressed() -> void:
	Globals.instrumento_2 = "drums"


func _on_button_5_pressed() -> void:
	var stage_scene = load("res://scenes/play_map.tscn")
	var old_stage_id = get_tree().root.get_node("Main").get_child_count()-1
	if stage_scene:
		var stage = stage_scene.instantiate()
		get_tree().root.get_node("Main").add_child(stage)
		get_tree().root.get_node("Main").get_child(old_stage_id).queue_free()
	else:
		print("Erro: Não conseguimos encontrar a cena.")


func _on_check_button_toggled(toggled_on: bool) -> void:
	pass # Replace with function body.
