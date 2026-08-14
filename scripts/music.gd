extends AudioStreamPlayer

signal MakeNote(pos_beat, song_pos)

@onready var music: AudioStreamPlayer = $"."
@export var bpm = 125
@export var tick_res = 192
var song_position:float = 0.0
var song_position_beats = 0
var song_position_ticks = 0
@onready var start_music: Timer = $startMusic

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	start_music.wait_time = Globals.note_delay


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	song_position = music.get_playback_position() + Globals.note_delay - start_music.time_left + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
	song_position -= AudioServer.get_output_latency()
	#song_position_ticks = (song_position/60)*tick_res*bpm
	song_position_beats = int((song_position) * (bpm/60))
	MakeNote.emit(song_position_beats, song_position)


func _on_start_music_timeout() -> void:
	play()
