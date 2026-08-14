extends Node3D

@onready var world: Node3D = $World
@onready var reset_color: Timer = $resetColo

var instrumentos = ["guitar", "drums", "vocal", "bass"]

var paths = {
	"player_track": "Main/playMap/World/GridContainer/track_1_view/SubViewport/PlayerTrack",
	"player_track2": "Main/playMap/World/GridContainer/track_2_view/SubViewport/PlayerTrack2",
	"detect_base_1": "GridContainer/track_1_view/SubViewport/PlayerTrack/{instrumento}/noteTrack{i}/detect",
	"detect_base_2": "GridContainer/track_2_view/SubViewport/PlayerTrack2/{instrumento}/noteTrack{i}/detect",
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Globals.instrumento_1 == "guitar":
		var guitarLoad = load("res://scenes/guitar.tscn")
		var guitar = guitarLoad.instantiate()
		get_tree().root.get_node(paths["player_track"]).add_child(guitar)
	elif Globals.instrumento_1 == "drums":
		var drumsLoad = load("res://scenes/drums.tscn")
		var drums = drumsLoad.instantiate()
		get_tree().root.get_node(paths["player_track"]).add_child(drums)
	if Globals.instrumento_2 == "guitar":
		var guitarLoad = load("res://scenes/guitar.tscn")
		var guitar = guitarLoad.instantiate()
		get_tree().root.get_node(paths["player_track2"]).add_child(guitar)
	elif Globals.instrumento_2 == "drums":
		var drumsLoad = load("res://scenes/drums.tscn")
		var drums = drumsLoad.instantiate()
		get_tree().root.get_node(paths["player_track2"]).add_child(drums)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_reset_color_timeout() -> void:
	pass
