extends Node

@export var instrumento_1 = "guitar"
@export var instrumento_2 = "drums"

@export var note_speed: float = 15.0
@export var start_delay: float = 3.0 
@export var hit_offset: float = 0.1

var is_single_player: bool = true

var max_combo: int = 0
var notes_hit: int = 0
var total_notes: int = 0

var master_bus = AudioServer.get_bus_index("Master")
var musica_bus = AudioServer.get_bus_index("Musica")
@export var volume_master = 1.0
@export var volume_music = 1.0

var selected_music: String = "music_1" 

signal score_updated(new_score: int)
signal combo_updated(new_combo: int)

var score: int = 0:
	set(value):
		score = value
		score_updated.emit(score)

var combo: int = 0:
	set(value):
		combo = value
		combo_updated.emit(combo)

signal life_updated(new_life)

var max_life: float = 100.0
var current_life: float = 50.0:
	set(value):
		current_life = clampf(value, 0.0, max_life)
		life_updated.emit(current_life)

var music_database = {
	"Música 01": {
		"title": "Música 01",
		"high_score": 0
	},
	"Música 02": {
		"title": "Música 02",
		"high_score": 0
	},
	"Música 03": {
		"title": "Música 03",
		"high_score": 0
	}
}

var personagem_1: String = ""
var personagem_2: String = ""

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass
