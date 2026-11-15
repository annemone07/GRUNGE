extends Node

# --- Configuração de Jogadores e Instrumentos ---
@export var instrumento_1: String = "guitar"
@export var instrumento_2: String = "drums"
var is_single_player: bool = true
var personagem_1: String = ""
var personagem_2: String = ""

# --- Velocidade, Sincronia e Calibração (segundos) ---
@export var note_speed: float = 15.0
@export var start_delay: float = 3.0
@export var audio_offset: float = 0.0 # Calibração global de latência de áudio

# --- Janelas de Julgamento Temporais (segundos) ---
@export var hit_window_perfect: float = 0.055  # ±55ms
@export var hit_window_good: float = 0.130     # ±130ms
@export var miss_window: float = 0.160         # +160ms após o tempo da nota = Miss
@export var release_tolerance: float = 0.120   # Tolerância ao soltar sustain perto do fim
@export var sustain_pts_per_sec: float = 250.0 # Pontos acumulados por segundo segurando

# --- Estatísticas da Partida ---
var max_combo: int = 0
var notes_hit: int = 0
var total_notes: int = 0

# --- Áudio ---
var master_bus: int = AudioServer.get_bus_index("Master")
var musica_bus: int = AudioServer.get_bus_index("Musica")
@export var volume_master: float = 1.0
@export var volume_music: float = 1.0

var selected_music: String = "music_1"

# --- Sinais e Estado Reativo ---
signal score_updated(new_score: int)
signal combo_updated(new_combo: int)
signal life_updated(new_life: float)

var score: int = 0:
	set(value):
		score = value
		score_updated.emit(score)

var combo: int = 0:
	set(value):
		combo = value
		combo_updated.emit(combo)

var max_life: float = 100.0
var current_life: float = 50.0:
	set(value):
		current_life = clampf(value, 0.0, max_life)
		life_updated.emit(current_life)

# --- Banco de Músicas (Compatibilidade com Menus) ---
var music_database: Dictionary = {
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

func reset_match_stats() -> void:
	score = 0
	combo = 0
	max_combo = 0
	notes_hit = 0
	total_notes = 0
	current_life = 50.0
