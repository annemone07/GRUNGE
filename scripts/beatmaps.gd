class_name beatmaps

const SONG_PATHS := {
	"music_1": "res://assets/beatmaps/music_1.json",
	"1": "res://assets/beatmaps/music_1.json",
	"music_2": "res://assets/beatmaps/music_2.json",
	"2": "res://assets/beatmaps/music_2.json",
	"music_3": "res://assets/beatmaps/music_3.json",
	"3": "res://assets/beatmaps/music_3.json"
}

var _cache: Dictionary = {}

func load_song(song_key: String) -> Dictionary:
	var path: String = SONG_PATHS.get(song_key, SONG_PATHS["music_1"])
	
	# Retorna uma cópia do cache se já tiver sido carregado do disco
	if _cache.has(path):
		return _cache[path].duplicate(true)

	if not FileAccess.file_exists(path):
		push_error("Beatmap JSON não encontrado: " + path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Erro de sintaxe ao ler JSON do beatmap: " + path)
		return {}

	# Carrega o arquivo de áudio a partir do "audio_path" definido no JSON
	var audio_path: String = parsed.get("audio_path", "")
	if audio_path != "" and ResourceLoader.exists(audio_path):
		parsed["music"] = load(audio_path)
	else:
		push_warning("Áudio não encontrado para o beatmap: " + audio_path)

	# Garante que todas as notas de cada instrumento estejam ordenadas cronologicamente
	var tracks: Dictionary = parsed.get("tracks", {})
	for inst in tracks.keys():
		var notes_array: Array = tracks[inst]
		notes_array.sort_custom(func(a, b): return float(a["time"]) < float(b["time"]))

	_cache[path] = parsed
	return parsed.duplicate(true)

# Mantém compatibilidade com local_beatmaps[music_key] e local_beatmaps.music_1
func _get(property: StringName):
	var key := String(property)
	if SONG_PATHS.has(key):
		return load_song(key)
	return null

# Mantém compatibilidade com "if music_key in local_beatmaps:" no play_map.gd
func _get_property_list() -> Array[Dictionary]:
	var props: Array[Dictionary] = []
	for key in SONG_PATHS.keys():
		props.append({
			"name": key,
			"type": TYPE_DICTIONARY
		})
	return props
