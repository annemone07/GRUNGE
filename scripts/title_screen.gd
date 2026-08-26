extends Node2D

@onready var press_text: Label = $Label

func _ready() -> void:
	if press_text:

		press_text.pivot_offset = press_text.size / 2.0
		
		var tween = create_tween().set_loops()
		
		tween.tween_property(press_text, "scale", Vector2(1.1, 1.1), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		tween.tween_property(press_text, "scale", Vector2(1.0, 1.0), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton:
		
		if event.is_pressed() and not event.is_echo():
			
			set_process_input(false)
			
			get_tree().change_scene_to_file("res://scenes/Main.tscn")
