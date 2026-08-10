extends Node3D

var position_in_beats = 0
var instrument = ""
var song_pos = 0
var position_in_ticks = 0
var localBeatmaps = beatmaps.new()
var tracksToSpawn = []
const TESTNOTE = preload("res://scenes/notes/note_test.tscn")
@onready var player_track: Node3D = $"."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if name == "PlayerTrack":
		instrument = Globals.instrumento_1
	elif name == "PlayerTrack2":
		instrument = Globals.instrumento_2


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if len(localBeatmaps.music_1[instrument].keys())>0:
		if song_pos>=localBeatmaps.music_1[instrument].keys()[0]:
			var firstElementKey = localBeatmaps.music_1[instrument].keys()[0]
			tracksToSpawn = localBeatmaps.music_1[instrument][firstElementKey]
			for noteNum in tracksToSpawn:
				print("song pos: ",song_pos)
				print("key: ",firstElementKey)
				var testNote = TESTNOTE.instantiate()
				add_child(testNote)
				testNote.global_position = player_track.get_node("{instrumento}/noteTrack{num}/spawn".format({"instrumento":instrument,"num":noteNum})).global_position
				testNote.rotation.z = player_track.get_node("{instrumento}/noteTrack{num}".format({"instrumento":instrument,"num":noteNum})).rotation.z
			localBeatmaps.music_1[instrument].erase(firstElementKey)
		tracksToSpawn.clear()
	else:
		pass #encerramento das notas e da musica

func _on_music_make_note(pos_beats: Variant,song_position: Variant) -> void:
	position_in_beats = pos_beats
	song_pos = song_position
