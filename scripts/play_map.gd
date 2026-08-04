extends Node3D

const TESTNOTE = preload("res://scenes/notes/note_test.tscn")
@onready var world: Node3D = $World
@onready var reset_color: Timer = $resetColor

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	guitarInputs()


func _on_create_test_note_timeout() -> void:
	var testNote = TESTNOTE.instantiate()
	var noteNum = randi_range(1,5) 
	var track = 0
	testNote.global_position = world.get_node("PlayerTrack/notesSpawns/spawn{num}".format({"num":noteNum})).global_position - Vector3(4,0,0)
	add_child(testNote)


func guitarInputs():
	if Input.is_action_pressed("guitar1"):
		reset_color.start()
		var overlap = world.get_node("PlayerTrack/guitar/detect1").get_overlapping_areas()
		world.get_node("PlayerTrack/guitar/MeshInstance3D").visible = true
		for note in overlap:
			note.queue_free()
	if Input.is_action_pressed("guitar2"):
		reset_color.start()
		var overlap = world.get_node("PlayerTrack/guitar/detect2").get_overlapping_areas()
		world.get_node("PlayerTrack/guitar/MeshInstance3D2").visible = true
		for note in overlap:
			note.queue_free()
	if Input.is_action_pressed("guitar3"):
		reset_color.start()
		var overlap = world.get_node("PlayerTrack/guitar/detect3").get_overlapping_areas()
		world.get_node("PlayerTrack/guitar/MeshInstance3D3").visible = true
		for note in overlap:
			note.queue_free()
	if Input.is_action_pressed("guitar4"):
		reset_color.start()
		var overlap = world.get_node("PlayerTrack/guitar/detect4").get_overlapping_areas()
		world.get_node("PlayerTrack/guitar/MeshInstance3D4").visible = true
		for note in overlap:
			note.queue_free()
	if Input.is_action_pressed("guitar5"):
		reset_color.start()
		var overlap = world.get_node("PlayerTrack/guitar/detect5").get_overlapping_areas()
		world.get_node("PlayerTrack/guitar/MeshInstance3D5").visible = true
		for note in overlap:
			note.queue_free()


func _on_reset_color_timeout() -> void:
	world.get_node("PlayerTrack/guitar/MeshInstance3D").visible = false
	world.get_node("PlayerTrack/guitar/MeshInstance3D2").visible = false
	world.get_node("PlayerTrack/guitar/MeshInstance3D3").visible = false
	world.get_node("PlayerTrack/guitar/MeshInstance3D4").visible = false
	world.get_node("PlayerTrack/guitar/MeshInstance3D5").visible = false
