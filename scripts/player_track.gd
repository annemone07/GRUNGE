extends Node3D

var position_in_beats = 0
var instrument = ""
var song_pos = 0

var inputs_enabled: bool = true

var localBeatmaps = beatmaps.new()
var tracksToSpawn = []

const TESTNOTE = preload("res://scenes/notes/note_test.tscn")
const SQ_TESTNOTE = preload("uid://mmkbxecgs3ho")

@onready var player_track: Node3D = $"."
@onready var camera: Camera3D = $Camera3D 

var current_beatmap: Dictionary = {}

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
		check_inputs("detect_base_1")
	elif name == "PlayerTrack2":
		check_inputs("detect_base_2")

	if instrument in current_beatmap and len(current_beatmap[instrument].keys()) > 0:
		if song_pos >= current_beatmap[instrument].keys()[0]:
			var firstElementKey = current_beatmap[instrument].keys()[0]
			tracksToSpawn = current_beatmap[instrument][firstElementKey].keys()
			for noteNum in tracksToSpawn:
				var testNote = null
				if current_beatmap[instrument][firstElementKey][noteNum] == "c":
					testNote = TESTNOTE.instantiate()
				else:
					testNote = SQ_TESTNOTE.instantiate()

				testNote.add_to_group("notes")
				add_child(testNote)
				
				testNote.global_position = player_track.get_node("{instrumento}/noteTrack{num}/spawn".format({"instrumento": instrument, "num": noteNum})).global_position
				testNote.rotation.z = player_track.get_node("{instrumento}/noteTrack{num}".format({"instrumento": instrument, "num": noteNum})).rotation.z
				
			current_beatmap[instrument].erase(firstElementKey)
		tracksToSpawn.clear()

func check_inputs(detect_key: String) -> void:
	if not inputs_enabled:
		return

	var max_buttons = 4
	if instrument == "drums":
		max_buttons = 8
	elif instrument == "vocal" or instrument == "guitar" or instrument == "bass":
		max_buttons = 4

	for i in range(1, max_buttons + 1):
		if Input.is_action_just_pressed("bt" + str(i)):
			var detector_path = paths[detect_key].format({"instrumento": instrument, "i": i})
			var detector = get_node_or_null(detector_path)

			if detector:
				var overlap = detector.get_overlapping_areas()
				if overlap.size() > 0:
					for note in overlap:
						add_score(100)
						note.queue_free()
				else:
					register_miss()

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
	
	if "current_life" in Globals:
		Globals.current_life -= 5.0

func _on_music_make_note(pos_beats: Variant, song_position: Variant) -> void:
	position_in_beats = pos_beats
	song_pos = song_position

func _adjust_camera_for_instrument() -> void:
	if not camera:
		return
	
	camera.fov = 60.0
	camera.position = Vector3(0, 8.0, 12.0)

func disable_inputs() -> void:
	inputs_enabled = false
