extends Node3D

var menu_scenes = [
	"res://scenes/telas/Main.tscn",
	"res://scenes/ui/Title_screen.tscn",
	"res://scenes/telas/starter_menu.tscn",
	"res://scenes/telas/credits_menu.tscn",
	"res://scenes/telas/settings_menu.tscn",
	"res://scenes/telas/gamemode_menu.tscn",
	"res://scenes/telas/select_music_menu.tscn",
	"res://scenes/telas/select_character_menu.tscn"
	
]

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	var current_scene = scene_file_path
	
	for child in get_children():
		if child.scene_file_path != "" and not child.is_queued_for_deletion():
			current_scene = child.scene_file_path
			
	if current_scene in menu_scenes:
		if not MenuMusic.playing:
			MenuMusic.play()
	else:
		MenuMusic.stop()
