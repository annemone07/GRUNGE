extends Node3D

@onready var score_label: Label = $UI/MarginContainer/Control/ScoreUI/Score
@onready var combo_label: Label = $UI/MarginContainer/Control/ScoreUI/Combo
@onready var music_name_label: Label = $UI/MarginContainer/Control/MusicUI/MusicName
@onready var music_author_label: Label = $UI/MarginContainer/Control/MusicUI/MusicAuthor

@onready var life_bar: TextureProgressBar = $LifeBar

@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var world: Node3D = $World
@onready var reset_color: Timer = $resetColor
@onready var countdown_label: Label = $UI/CountdownLabel

var last_countdown_sec: int = -1
var is_game_over: bool = false
var local_beatmaps = beatmaps.new()
var time_elapsed: float = 0.0
var music_started: bool = false

func _ready() -> void:
	_setup_screen_mode()

	Globals.score_updated.connect(_on_score_updated)
	Globals.combo_updated.connect(_on_combo_updated)
	Globals.life_updated.connect(_on_life_updated)
	
	_on_score_updated(Globals.score)
	_on_combo_updated(Globals.combo)
	if life_bar:
		life_bar.value = Globals.current_life

	var music_key = Globals.selected_music
	var current_song = local_beatmaps[music_key] if music_key in local_beatmaps else local_beatmaps.music_1

	music_name_label.text = current_song["title"]
	music_author_label.text = current_song["artist"]

	music_player.stream = current_song["music"]
	music_player.finished.connect(_on_music_finished)
	
	time_elapsed = -Globals.start_delay

	_instantiate_instruments()

func _process(delta: float) -> void:
	if is_game_over:
		return
		
	var current_song_pos = 0.0
	
	if not music_started:
		var safe_delta = min(delta, 0.05)
		time_elapsed += safe_delta
		current_song_pos = time_elapsed
		
		var current_sec = int(ceil(-time_elapsed))
		
		if current_sec > 0 and current_sec != last_countdown_sec:
			last_countdown_sec = current_sec
			animate_countdown(str(current_sec))
		elif time_elapsed >= 0.0 and last_countdown_sec != 0:
			last_countdown_sec = 0
			animate_countdown("")
		
		if time_elapsed >= 0.0:
			music_started = true
			music_player.play()
	else:
		if music_player and music_player.playing:
			current_song_pos = music_player.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
			
	get_tree().call_group("player_tracks", "_on_music_make_note", 0, current_song_pos)

func _setup_screen_mode() -> void:
	var is_single = Globals.is_single_player if "is_single_player" in Globals else true
	
	if is_single:
		var grid_container = $World/GridContainer
		var track2_view = $World/GridContainer/track_2_view
		
		if grid_container:
			grid_container.columns = 1

		if track2_view:
			track2_view.queue_free()

func _instantiate_instruments() -> void:
	_add_instrument_to_track(Globals.instrumento_1, $World/GridContainer/track_1_view/SubViewport/PlayerTrack)

	var is_single = "is_single_player" in Globals and Globals.is_single_player
	if not is_single:
		_add_instrument_to_track(Globals.instrumento_2, $World/GridContainer/track_2_view/SubViewport/PlayerTrack2)

func _add_instrument_to_track(instrument_name: String, track_node: Node) -> void:
	if instrument_name == "" or instrument_name == null:
		return
		
	var path = "res://scenes/" + instrument_name + ".tscn"
	
	if ResourceLoader.exists(path):
		var instrument_scene = load(path).instantiate()
		track_node.add_child(instrument_scene)
		print("LOG: conseguiu carregar um ", instrument_name)
	else:
		print("LOG: erro, nao conseguiu carregar o instrumento", path)

func _on_score_updated(new_score: int) -> void:
	score_label.text = str(new_score)

func _on_combo_updated(new_combo: int) -> void:
	combo_label.text = "x" + str(new_combo)

func _on_life_updated(new_life: float) -> void:
	if life_bar:
		var tween = create_tween()
		tween.tween_property(life_bar, "value", new_life, 0.15)
		
	if new_life <= 0 and not is_game_over:
		_end_game(false)

func _on_music_finished() -> void:
	if not is_game_over:
		_end_game(true)

func _end_game(is_victory: bool) -> void:
	is_game_over = true
	
	get_tree().call_group("player_tracks", "disable_inputs")
	
	if music_player:
		music_player.stop()
		
	var status_text = "VITÓRIA!" if is_victory else "GAME OVER!"
	
	var end_scene = load("res://scenes/victory_screen.tscn")
	if end_scene:
		var end_instance = end_scene.instantiate()
		$UI.add_child(end_instance)
		
		if end_instance.has_method("setup_screen"):
			end_instance.setup_screen(is_victory)
	else:
		print("LOG: Erro ao carregar res://scenes/victory_screen.tscn")

func animate_countdown(text_value: String) -> void:
	if not countdown_label: return
	
	countdown_label.text = text_value
	
	# Estado inicial: invisível e um pouquinho menor (escala 0.8)
	countdown_label.modulate.a = 0.0
	countdown_label.scale = Vector2(0.8, 0.8)
	
	var tween = create_tween()
	
	tween.set_parallel(true)
	tween.tween_property(countdown_label, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(countdown_label, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	tween.set_parallel(false)
	tween.tween_property(countdown_label, "modulate:a", 0.0, 0.2).set_delay(0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
