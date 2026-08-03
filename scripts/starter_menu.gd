extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_start_button_pressed() -> void:
	var stage = load("res://scenes/play_map.tscn")
	get_tree().root.add_child(stage)
	get_tree().current_scene.queue_free()
