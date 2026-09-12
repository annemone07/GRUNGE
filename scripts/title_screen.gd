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
			
			var stage_scene = load("res://scenes/StarterMenu.tscn")
			var old_stage_id = get_tree().root.get_node("Main").get_child_count()-1
			if stage_scene:
				var stage = stage_scene.instantiate()
				get_tree().root.get_node("Main").add_child(stage)
				get_tree().root.get_node("Main").get_child(old_stage_id).queue_free()
			else:
				print("Erro: Não conseguimos encontrar a cena.")
