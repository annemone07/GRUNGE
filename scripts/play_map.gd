extends Node3D

const TESTNOTE = preload("res://scenes/notes/note_test.tscn")
@onready var world: Node3D = $World
@onready var reset_color: Timer = $resetColor

var instrumentos = ["guitar", "drums", "vocal", "bass"]
var noteNum = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Globals.instrumento_1 = "drums"


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	guitarInputs()


func _on_create_test_note_timeout() -> void:
	noteNum = randi_range(1, world.get_node("PlayerTrack/{instrumento}".format({"instrumento":Globals.instrumento_1})).get_child_count())
	var testNote = TESTNOTE.instantiate()
	var track = 0
	testNote.global_position = world.get_node("PlayerTrack/{instrumento}/noteTrack{num}/spawn".format({"instrumento":Globals.instrumento_1,"num":noteNum})).global_position
	testNote.rotation.z = world.get_node("PlayerTrack/{instrumento}/noteTrack{num}".format({"instrumento":Globals.instrumento_1,"num":noteNum})).rotation.z
	print(testNote.rotation.z)
	add_child(testNote)


func guitarInputs():
	if Input.is_action_pressed("bt1"):
		#reset_color.start()
		var overlap = world.get_node("PlayerTrack/{instrumento}/noteTrack1/detect".format({"instrumento":Globals.instrumento_1})).get_overlapping_areas()
		#world.get_node("PlayerTrack/guitar/MeshInstance3D").visible = true
		for note in overlap:
			note.queue_free()
	if Input.is_action_pressed("bt2"):
		#reset_color.start()
		var overlap = world.get_node("PlayerTrack/{instrumento}/noteTrack2/detect".format({"instrumento":Globals.instrumento_1})).get_overlapping_areas()
		#world.get_node("PlayerTrack/guitar/MeshInstance3D").visible = true
		for note in overlap:
			note.queue_free()
	if Input.is_action_pressed("bt3"):
		#reset_color.start()
		var overlap = world.get_node("PlayerTrack/{instrumento}/noteTrack3/detect".format({"instrumento":Globals.instrumento_1})).get_overlapping_areas()
		#world.get_node("PlayerTrack/guitar/MeshInstance3D").visible = true
		for note in overlap:
			note.queue_free()
	if Input.is_action_pressed("bt4"):
		#reset_color.start()
		var overlap = world.get_node("PlayerTrack/{instrumento}/noteTrack4/detect".format({"instrumento":Globals.instrumento_1})).get_overlapping_areas()
		#world.get_node("PlayerTrack/guitar/MeshInstance3D").visible = true
		for note in overlap:
			note.queue_free()
	if noteNum>4:
		if Input.is_action_pressed("bt5"):
			#reset_color.start()
			var overlap = world.get_node("PlayerTrack/{instrumento}/noteTrack5/detect".format({"instrumento":Globals.instrumento_1})).get_overlapping_areas()
			#world.get_node("PlayerTrack/guitar/MeshInstance3D").visible = true
			for note in overlap:
				note.queue_free()
		if Input.is_action_pressed("bt6"):
			#reset_color.start()
			var overlap = world.get_node("PlayerTrack/{instrumento}/noteTrack6/detect".format({"instrumento":Globals.instrumento_1})).get_overlapping_areas()
			#world.get_node("PlayerTrack/guitar/MeshInstance3D").visible = true
			for note in overlap:
				note.queue_free()
		if Input.is_action_pressed("bt7"):
			#reset_color.start()
			var overlap = world.get_node("PlayerTrack/{instrumento}/noteTrack7/detect".format({"instrumento":Globals.instrumento_1})).get_overlapping_areas()
			#world.get_node("PlayerTrack/guitar/MeshInstance3D").visible = true
			for note in overlap:
				note.queue_free()
		if Input.is_action_pressed("bt8"):
			#reset_color.start()
			var overlap = world.get_node("PlayerTrack/{instrumento}/noteTrack8/detect".format({"instrumento":Globals.instrumento_1})).get_overlapping_areas()
			#world.get_node("PlayerTrack/guitar/MeshInstance3D").visible = true
			for note in overlap:
				note.queue_free()


func _on_reset_color_timeout() -> void:
	pass
	#world.get_node("PlayerTrack/guitar/MeshInstance3D").visible = false
	#world.get_node("PlayerTrack/guitar/MeshInstance3D2").visible = false
	#world.get_node("PlayerTrack/guitar/MeshInstance3D3").visible = false
	#world.get_node("PlayerTrack/guitar/MeshInstance3D4").visible = false
	#world.get_node("PlayerTrack/guitar/MeshInstance3D5").visible = false
