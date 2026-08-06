extends Node3D

@onready var world: Node3D = $World
@onready var reset_color: Timer = $resetColo

var instrumentos = ["guitar", "drums", "vocal", "bass"]
var noteNum = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Globals.instrumento_1 == "guitar":
		var guitarLoad = load("res://scenes/guitar.tscn")
		var guitar = guitarLoad.instantiate()
		get_tree().root.get_node("Main/playMap/World/PlayerTrack").add_child(guitar)
	elif Globals.instrumento_1 == "drums":
		var drumsLoad = load("res://scenes/drums.tscn")
		var drums = drumsLoad.instantiate()
		get_tree().root.get_node("Main/playMap/World/PlayerTrack").add_child(drums)
	if Globals.instrumento_2 == "guitar":
		var guitarLoad = load("res://scenes/guitar.tscn")
		var guitar = guitarLoad.instantiate()
		get_tree().root.get_node("Main/playMap/World/PlayerTrack2").add_child(guitar)
	elif Globals.instrumento_2 == "drums":
		var drumsLoad = load("res://scenes/drums.tscn")
		var drums = drumsLoad.instantiate()
		get_tree().root.get_node("Main/playMap/World/PlayerTrack2").add_child(drums)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	guitarInputs()
	
func _on_create_test_note_timeout() -> void:
	pass

func guitarInputs():
	if Input.is_action_pressed("bt1"):
		var overlap = world.get_node("PlayerTrack/{instrumento}/noteTrack1/detect".format({"instrumento":Globals.instrumento_1})).get_overlapping_areas()
		for note in overlap:
			note.queue_free()
	if Input.is_action_pressed("bt2"):
		var overlap = world.get_node("PlayerTrack/{instrumento}/noteTrack2/detect".format({"instrumento":Globals.instrumento_1})).get_overlapping_areas()
		for note in overlap:
			note.queue_free()
	if Input.is_action_pressed("bt3"):
		var overlap = world.get_node("PlayerTrack/{instrumento}/noteTrack3/detect".format({"instrumento":Globals.instrumento_1})).get_overlapping_areas()
		for note in overlap:
			note.queue_free()
	if Input.is_action_pressed("bt4"):
		var overlap = world.get_node("PlayerTrack/{instrumento}/noteTrack4/detect".format({"instrumento":Globals.instrumento_1})).get_overlapping_areas()
		for note in overlap:
			note.queue_free()
	if noteNum>4:
		if Input.is_action_pressed("bt5"):
			var overlap = world.get_node("PlayerTrack/{instrumento}/noteTrack5/detect".format({"instrumento":Globals.instrumento_1})).get_overlapping_areas()
			for note in overlap:
				note.queue_free()
		if Input.is_action_pressed("bt6"):
			var overlap = world.get_node("PlayerTrack/{instrumento}/noteTrack6/detect".format({"instrumento":Globals.instrumento_1})).get_overlapping_areas()
			for note in overlap:
				note.queue_free()
		if Input.is_action_pressed("bt7"):
			var overlap = world.get_node("PlayerTrack/{instrumento}/noteTrack7/detect".format({"instrumento":Globals.instrumento_1})).get_overlapping_areas()
			for note in overlap:
				note.queue_free()
		if Input.is_action_pressed("bt8"):
			var overlap = world.get_node("PlayerTrack/{instrumento}/noteTrack8/detect".format({"instrumento":Globals.instrumento_1})).get_overlapping_areas()
			for note in overlap:
				note.queue_free()


func _on_reset_color_timeout() -> void:
	pass
