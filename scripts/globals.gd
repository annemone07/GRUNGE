extends Node

@export var instrumento_1 = "guitar"
@export var instrumento_2 = "drums"
@export var selectedMusic = 1
@export var note_speed = 10
@export var note_dist = 40
@export var note_delay = note_dist/note_speed
var master_bus = AudioServer.get_bus_index("Master")
var musica_bus = AudioServer.get_bus_index("Musica")
@export var volume_master = 1.0
@export var volume_music = 1.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
