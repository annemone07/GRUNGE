extends Node3D


var titleScreen = "res://scenes/ui/Title_screen.tscn"
var starterMenu = "res://scenes/StarterMenu.tscn"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	print(MenuMusic.playing)
	if (get_child(-1).scene_file_path == titleScreen or get_child(-1).scene_file_path == starterMenu):
		if not MenuMusic.playing:
			MenuMusic.play()
	else:
		MenuMusic.stop()
		
