extends Node3D

var active_notes_queue = {1: [], 2: [], 3: [], 4: [], 5: [], 6: [], 7: [], 8: []}
var holding_notes = {1: null, 2: null, 3: null, 4: null, 5: null, 6: null, 7: null, 8: null}
var sustain_score_accum: float = 0.0

var hit_window: float = 2.0

var instrument = ""
var song_pos = -100.0

var player_id: int = 1
var inputs_enabled: bool = true

var localBeatmaps = beatmaps.new()

const TESTNOTE = preload("res://scenes/notes/note_test.tscn")

@onready var player_track: Node3D = $"."
@onready var camera: Camera3D = $Camera3D 

var track_notes: Array = []
var next_note_index: int = 0
var dynamic_travel_time: float = 0.0

func _ready() -> void:
	add_to_group("player_tracks")

	var loaded_song: Dictionary = {}
	if Globals.selected_music in localBeatmaps:
		loaded_song = localBeatmaps[Globals.selected_music]
	else:
		loaded_song = localBeatmaps.music_1

	if name == "PlayerTrack":
		instrument = Globals.instrumento_1
		player_id = 1
	elif name == "PlayerTrack2":
		instrument = Globals.instrumento_2
		player_id = 2

	_adjust_camera_for_instrument()

	var tracks: Dictionary = loaded_song.get("tracks", {})
	if instrument in tracks:
		track_notes = tracks[instrument]
	else:
		push_warning("Instrumento não encontrado no beatmap: " + instrument)

func _process(delta: float) -> void:
	_process_sustains(delta)
	math_check_inputs()

func _physics_process(delta: float) -> void:
	_clean_missed_notes()
	
	if dynamic_travel_time == 0.0 and instrument != "":
		var path_spawn = "{instrumento}/noteTrack1/spawn".format({"instrumento": instrument})
		var path_detect = "{instrumento}/noteTrack1/detect".format({"instrumento": instrument})
		var spawn_node = get_node_or_null(path_spawn)
		var detect_node = get_node_or_null(path_detect)
		
		if spawn_node and detect_node:
			var distance = abs(detect_node.global_position.z - spawn_node.global_position.z)
			dynamic_travel_time = distance / Globals.note_speed

	while next_note_index < track_notes.size():
		var note_data: Dictionary = track_notes[next_note_index]
		var hit_time: float = float(note_data.get("time", 0.0))
		var trigger_time: float = hit_time - dynamic_travel_time + Globals.audio_offset
		
		if song_pos >= trigger_time:
			next_note_index += 1
			
			var noteNum: int = int(note_data.get("lane", 1))
			var note_type: String = str(note_data.get("type", "c"))
			var is_square: bool = (note_type != "c")
			var duration: float = float(note_data.get("duration", 0.0))
			
			var testNote = TESTNOTE.instantiate()
			Globals.total_notes += 1
			
			testNote.add_to_group("notes")
			add_child(testNote)
			testNote.definir_cor_da_trilha(noteNum, is_square, duration, Globals.note_speed)
			
			var spawn_pos_node = player_track.get_node_or_null("{instrumento}/noteTrack{num}/spawn".format({"instrumento": instrument, "num": noteNum}))
			var track_node = player_track.get_node_or_null("{instrumento}/noteTrack{num}".format({"instrumento": instrument, "num": noteNum}))
			var detect_node = player_track.get_node_or_null("{instrumento}/noteTrack{num}/detect".format({"instrumento": instrument, "num": noteNum}))
			
			if spawn_pos_node and track_node:
				testNote.global_position = spawn_pos_node.global_position
				testNote.rotation.z = track_node.rotation.z
				if detect_node:
					# Define o limite de despawn bem depois do detector para a cauda inteira passar
					testNote.despawn_z = detect_node.global_position.z + 6.0
				active_notes_queue[noteNum].append(testNote)
		else:
			break

func _clean_missed_notes() -> void:
	if instrument == "":
		return
		
	var max_buttons: int = 8 if instrument == "drums" else 4
	for track_i in range(1, max_buttons + 1):
		while not active_notes_queue[track_i].is_empty():
			var front_note = active_notes_queue[track_i][0]
			if not is_instance_valid(front_note):
				active_notes_queue[track_i].pop_front()
				continue
				
			var detector = _get_detector(track_i)
			if detector and front_note.global_position.z > detector.global_position.z + hit_window:
				register_miss()
				front_note.mark_as_missed()
				active_notes_queue[track_i].pop_front()
			else:
				break

func _process_sustains(delta: float) -> void:
	var any_holding: bool = false
	for track_i in holding_notes.keys():
		var note = holding_notes[track_i]
		if is_instance_valid(note):
			if note.update_sustain(delta):
				any_holding = true
			else:
				holding_notes[track_i] = null
				_set_detector_holding(track_i, false)
		elif holding_notes[track_i] != null:
			holding_notes[track_i] = null
			_set_detector_holding(track_i, false)

	if any_holding:
		var pts_rate: float = Globals.sustain_pts_per_sec if "sustain_pts_per_sec" in Globals else 250.0
		sustain_score_accum += pts_rate * delta
		if sustain_score_accum >= 1.0:
			var pts: int = int(sustain_score_accum)
			sustain_score_accum -= pts
			Globals.score += pts

func _get_detector(track_i: int) -> Node3D:
	var detector_path := "{instrumento}/noteTrack{i}/detect".format({"instrumento": instrument, "i": track_i})
	return get_node_or_null(detector_path)

func _set_detector_holding(track_i: int, holding: bool) -> void:
	var detector := _get_detector(track_i)
	if detector and detector.has_method("set_holding"):
		detector.set_holding(holding)

func add_score(amount: int) -> void:
	Globals.combo += 1
	Globals.notes_hit += 1
	
	if "current_life" in Globals:
		Globals.current_life += 2.5
		
	if Globals.combo > Globals.max_combo:
		Globals.max_combo = Globals.combo

	var multiplier = 1
	if Globals.combo >= 40:
		multiplier = 6
	elif Globals.combo >= 10:
		multiplier = 4
	elif Globals.combo >= 5:
		multiplier = 2

	Globals.score += amount * multiplier

func register_miss() -> void:
	Globals.combo = 0
	
	if "current_life" in Globals:
		Globals.current_life -= 5.0
	
func _on_music_make_note(pos_beats: Variant, song_position: Variant) -> void:
	song_pos = song_position

func _adjust_camera_for_instrument() -> void:
	if not camera:
		return
	camera.fov = 40.0
	camera.position = Vector3(0, 8.0, 12.0)

func disable_inputs() -> void:
	inputs_enabled = false

func enable_inputs() -> void:
	inputs_enabled = true

func math_check_inputs() -> void:
	if not inputs_enabled: return
	
	var max_buttons = 8 if instrument == "drums" else 4

	for track_i in range(1, max_buttons + 1):
		var action_name = "customAction_player" + str(player_id) + "_bt" + str(track_i)
		
		if Input.is_action_just_released(action_name):
			var held_note = holding_notes[track_i]
			if is_instance_valid(held_note):
				held_note.release_hold()
			holding_notes[track_i] = null
			_set_detector_holding(track_i, false)
		
		if Input.is_action_just_pressed(action_name):
			active_notes_queue[track_i] = active_notes_queue[track_i].filter(func(n): return is_instance_valid(n))
			
			var acertou = false
			if active_notes_queue[track_i].size() > 0:
				var target_note = active_notes_queue[track_i][0]
				var detector = _get_detector(track_i)
				
				if detector:
					var dist = abs(target_note.global_position.z - detector.global_position.z)
					
					if dist <= hit_window:
						var detector_esta_no_quadrado = false
						var square_node = detector.get_node_or_null("sqr_normal")
						if square_node:
							detector_esta_no_quadrado = square_node.visible
						
						var nota_e_quadrado: bool = target_note.is_square_note
						
						if detector_esta_no_quadrado == nota_e_quadrado:
							add_score(100)
							active_notes_queue[track_i].pop_front()
							
							var is_sustain: bool = target_note.hold_duration > 0.0
							if is_sustain:
								holding_notes[track_i] = target_note
								_set_detector_holding(track_i, true)
							
							target_note.start_hold(detector.global_position.z)
							acertou = true
							
							if detector.has_method("animar_hit"):
								detector.animar_hit()
						else:
							register_miss()
							target_note.mark_as_missed()
							active_notes_queue[track_i].pop_front()
							acertou = true
			
			if not acertou:
				register_miss()
