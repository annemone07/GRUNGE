extends Node3D

var active_notes_queue = {1: [], 2: [], 3: [], 4: [], 5: [], 6: [], 7: [], 8: []}
var hit_window: float = 2.0

var instrument = ""
var song_pos = -100.0

var inputs_enabled: bool = true

var localBeatmaps = beatmaps.new()

const TESTNOTE = preload("res://scenes/notes/note_test.tscn")
const SQ_TESTNOTE = preload("uid://mmkbxecgs3ho")

@onready var player_track: Node3D = $"."
@onready var camera: Camera3D = $Camera3D 

var current_beatmap: Dictionary = {}
var dynamic_travel_time: float = 0.0
var spawned_notes: Dictionary = {} 

var paths = {
	"detect_base_1": "{instrumento}/noteTrack{i}/detect",
	"detect_base_2": "{instrumento}/noteTrack{i}/detect",
}

func _ready() -> void:
	add_to_group("player_tracks")

	if Globals.selected_music in localBeatmaps:
		current_beatmap = localBeatmaps[Globals.selected_music].duplicate(true)
	else:
		current_beatmap = localBeatmaps.music_1.duplicate(true)

	if name == "PlayerTrack":
		instrument = Globals.instrumento_1
	elif name == "PlayerTrack2":
		instrument = Globals.instrumento_2

	_adjust_camera_for_instrument()

	if Globals.selected_music in localBeatmaps:
		current_beatmap = localBeatmaps[Globals.selected_music]
	else:
		current_beatmap = localBeatmaps.music_1

func _process(delta: float) -> void:
	if name == "PlayerTrack":
		math_check_inputs("detect_base_1")
	elif name == "PlayerTrack2":
		math_check_inputs("detect_base_2")

func _physics_process(delta: float) -> void:
	if dynamic_travel_time == 0.0 and instrument != "":
		var path_spawn = "{instrumento}/noteTrack1/spawn".format({"instrumento": instrument})
		var path_detect = "{instrumento}/noteTrack1/detect".format({"instrumento": instrument})
		var spawn_node = get_node_or_null(path_spawn)
		var detect_node = get_node_or_null(path_detect)
		
		if spawn_node and detect_node:
			var distance = abs(detect_node.global_position.z - spawn_node.global_position.z)
			dynamic_travel_time = distance / Globals.note_speed

	if instrument in current_beatmap:
		var notes_dict = current_beatmap[instrument]
		
		for hit_time in notes_dict.keys():
			if spawned_notes.has(hit_time):
				continue
				
			var trigger_time = hit_time - dynamic_travel_time + Globals.hit_offset
			
			if song_pos >= trigger_time:
				spawned_notes[hit_time] = true 
				
				var tracksToSpawn = notes_dict[hit_time].keys()
				for noteNum in tracksToSpawn:
					var testNote = null
					if notes_dict[hit_time][noteNum] == "c":
						testNote = TESTNOTE.instantiate()
					else:
						testNote = SQ_TESTNOTE.instantiate()

					testNote.add_to_group("notes")
					add_child(testNote)
					
					var spawn_pos_node = player_track.get_node_or_null("{instrumento}/noteTrack{num}/spawn".format({"instrumento": instrument, "num": noteNum}))
					var track_node = player_track.get_node_or_null("{instrumento}/noteTrack{num}".format({"instrumento": instrument, "num": noteNum}))
					
					if spawn_pos_node and track_node:
						testNote.global_position = spawn_pos_node.global_position
						testNote.rotation.z = track_node.rotation.z
						active_notes_queue[noteNum].append(testNote)

func add_score(amount: int) -> void:
	Globals.combo += 1
	
	if "current_life" in Globals:
		Globals.current_life += 2.5

	var multiplier = 1
	if Globals.combo >= 30:
		multiplier = 4
	elif Globals.combo >= 20:
		multiplier = 3
	elif Globals.combo >= 10:
		multiplier = 2

	Globals.score += amount * multiplier

func register_miss() -> void:
	Globals.combo = 0

func _on_music_make_note(pos_beats: Variant, song_position: Variant) -> void:
	song_pos = song_position

func _adjust_camera_for_instrument() -> void:
	if not camera:
		return
	
	camera.fov = 60.0
	camera.position = Vector3(0, 8.0, 12.0)

func disable_inputs() -> void:
	inputs_enabled = false

func math_check_inputs(detect_key: String) -> void:
	if not inputs_enabled: return
	
	var max_buttons = 8 if instrument == "drums" else 4

	for track_i in range(1, max_buttons + 1):
		if Input.is_action_just_pressed("bt" + str(track_i)):
			active_notes_queue[track_i] = active_notes_queue[track_i].filter(func(n): return is_instance_valid(n))
			
			var acertou = false
			if active_notes_queue[track_i].size() > 0:
				var target_note = active_notes_queue[track_i][0]
				var detector_path = "{instrumento}/noteTrack{i}/detect".format({"instrumento": instrument, "i": track_i})
				var detector = get_node_or_null(detector_path)
				
				if detector:
					var dist = abs(target_note.global_position.z - detector.global_position.z)
					
					if dist <= hit_window:
						add_score(100)
						target_note.queue_free()
						active_notes_queue[track_i].pop_front()
						acertou = true
			
			if not acertou:
				register_miss()
