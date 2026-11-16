class_name SoundtrackFS
extends RefCounted

# Retorna a pasta raiz onde ficam as pastas song_01, song_02, etc.
# No Editor: user://soundtrack/ (evita que o Godot trave reimportando MP3s em runtime)
# No .exe compilado: <pasta_do_executavel>/soundtrack/
static func get_soundtrack_root() -> String:
	var root_dir: String
	if OS.has_feature("editor"):
		root_dir = ProjectSettings.globalize_path("user://soundtrack/")
	else:
		root_dir = OS.get_executable_path().get_base_dir().path_join("soundtrack")
	
	if not DirAccess.dir_exists_absolute(root_dir):
		DirAccess.make_dir_recursive_absolute(root_dir)
		
	return root_dir

# Escaneia todas as pastas song_XX e retorna uma lista ordenada de dicionários com metadados
static func scan_all_songs() -> Array[Dictionary]:
	var songs: Array[Dictionary] = []
	var root := get_soundtrack_root()
	var dir := DirAccess.open(root)
	if not dir:
		return songs

	dir.list_dir_begin()
	var folder_name := dir.get_next()
	while folder_name != "":
		if dir.current_is_dir() and not folder_name.begins_with(".") and folder_name.begins_with("song_"):
			var song_info := _read_song_folder(root.path_join(folder_name), folder_name)
			if not song_info.is_empty():
				songs.append(song_info)
		folder_name = dir.get_next()
	dir.list_dir_end()

	songs.sort_custom(func(a, b): return a["index"] < b["index"])
	return songs

static func _read_song_folder(folder_path: String, folder_name: String) -> Dictionary:
	var idx_str := folder_name.replace("song_", "")
	var song_index := int(idx_str)
	var charts_dir := folder_path.path_join("charts")
	
	if not DirAccess.dir_exists_absolute(charts_dir):
		DirAccess.make_dir_recursive_absolute(charts_dir)

	var audio_path := _find_audio_in_dir(folder_path)
	if audio_path == "":
		return {}

	var beatmaps_list := list_beatmaps(charts_dir, song_index)
	
	var official_json_path := folder_path.path_join("music_%d.json" % song_index)
	var ref_json_path: String = official_json_path if FileAccess.file_exists(official_json_path) else (str(beatmaps_list[0]["path"]) if beatmaps_list.size() > 0 else "")

	var title := "Música %02d" % song_index
	var artist := "Artista Desconhecido"
	var bpm := 120.0
	var total_notes := 0

	if ref_json_path != "" and FileAccess.file_exists(ref_json_path):
		var data := load_json_dict(ref_json_path)
		title = str(data.get("title", title))
		artist = str(data.get("artist", artist))
		bpm = float(data.get("bpm", 120.0))
		total_notes = count_notes_in_chart(data)

	var stream := load_audio_stream(audio_path)
	var duration_sec := stream.get_length() if stream else 0.0

	return {
		"index": song_index,
		"folder_name": folder_name,
		"folder_path": folder_path,
		"charts_dir": charts_dir,
		"audio_path": audio_path,
		"official_json_path": official_json_path,
		"title": title,
		"artist": artist,
		"bpm": bpm,
		"duration": duration_sec,
		"total_notes": total_notes,
		"beatmaps": beatmaps_list
	}

static func _find_audio_in_dir(dir_path: String) -> String:
	var dir := DirAccess.open(dir_path)
	if not dir:
		return ""
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if not dir.current_is_dir():
			var ext := f.get_extension().to_lower()
			if ext in ["mp3", "ogg", "wav"]:
				dir.list_dir_end()
				return dir_path.path_join(f)
		f = dir.get_next()
	dir.list_dir_end()
	return ""

static func list_beatmaps(charts_dir: String, song_index: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var dir := DirAccess.open(charts_dir)
	if not dir:
		return result

	var prefix := "msc_%d_bmp_" % song_index
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if not dir.current_is_dir() and f.ends_with(".json") and f.begins_with(prefix):
			var num_str := f.replace(prefix, "").replace(".json", "")
			var bmp_idx := int(num_str)
			var full_path := charts_dir.path_join(f)
			var chart_data := load_json_dict(full_path)
			result.append({
				"bmp_index": bmp_idx,
				"name": f.get_basename(),
				"path": full_path,
				"note_count": count_notes_in_chart(chart_data),
				"bpm": float(chart_data.get("bpm", 120.0))
			})
		f = dir.get_next()
	dir.list_dir_end()

	result.sort_custom(func(a, b): return a["bmp_index"] < b["bmp_index"])
	return result

static func create_new_beatmap(song_info: Dictionary) -> String:
	var song_idx: int = song_info["index"]
	var existing: Array[Dictionary] = list_beatmaps(song_info["charts_dir"], song_idx)
	var next_bmp_idx := 1
	if existing.size() > 0:
		next_bmp_idx = existing[-1]["bmp_index"] + 1

	var file_name := "msc_%d_bmp_%d.json" % [song_idx, next_bmp_idx]
	var full_path: String = song_info["charts_dir"].path_join(file_name)

	var template := {
		"title": song_info["title"],
		"artist": song_info["artist"],
		"bpm": song_info["bpm"],
		"beat_divisor": 1,
		"free_snap_min": 0.05,
		"audio_path": song_info["audio_path"],
		"tracks": {
			"guitar": [],
			"drums": [],
			"vocal": [],
			"bass": []
		}
	}
	save_json_dict(full_path, template)
	return full_path

static func import_new_song(source_audio_path: String, title: String, artist: String, bpm: float) -> bool:
	var existing := scan_all_songs()
	var next_idx := 1
	if existing.size() > 0:
		next_idx = existing[-1]["index"] + 1

	var folder_name := "song_%02d" % next_idx
	var folder_path := get_soundtrack_root().path_join(folder_name)
	var charts_dir := folder_path.path_join("charts")
	DirAccess.make_dir_recursive_absolute(charts_dir)

	var ext := source_audio_path.get_extension().to_lower()
	var dest_audio := folder_path.path_join("music_%02d.%s" % [next_idx, ext])
	var err := DirAccess.copy_absolute(source_audio_path, dest_audio)
	if err != OK:
		push_error("Erro ao copiar áudio (%s) para (%s): código %d" % [source_audio_path, dest_audio, err])
		return false

	var song_stub := {
		"index": next_idx,
		"charts_dir": charts_dir,
		"audio_path": dest_audio,
		"title": title,
		"artist": artist,
		"bpm": bpm
	}
	var first_bmp := create_new_beatmap(song_stub)
	var official_path := folder_path.path_join("music_%d.json" % next_idx)
	DirAccess.copy_absolute(first_bmp, official_path)
	return true

static func update_song_metadata(song_info: Dictionary, new_title: String, new_artist: String) -> void:
	var files_to_update: Array[String] = []
	if FileAccess.file_exists(song_info["official_json_path"]):
		files_to_update.append(song_info["official_json_path"])
	for bmp in song_info["beatmaps"]:
		files_to_update.append(bmp["path"])

	for path in files_to_update:
		var data := load_json_dict(path)
		if not data.is_empty():
			data["title"] = new_title
			data["artist"] = new_artist
			save_json_dict(path, data)

static func publish_beatmap_as_official(beatmap_path: String, official_json_path: String) -> void:
	DirAccess.copy_absolute(beatmap_path, official_json_path)

static func delete_song_folder(folder_path: String) -> void:
	_remove_dir_recursive(folder_path)

static func _remove_dir_recursive(path: String) -> void:
	var dir := DirAccess.open(path)
	if not dir:
		return
	dir.list_dir_begin()
	var item := dir.get_next()
	while item != "":
		if item != "." and item != "..":
			var full := path.path_join(item)
			if dir.current_is_dir():
				_remove_dir_recursive(full)
			else:
				DirAccess.remove_absolute(full)
		item = dir.get_next()
	dir.list_dir_end()
	DirAccess.remove_absolute(path)

static func load_audio_stream(abs_path: String) -> AudioStream:
	if not FileAccess.file_exists(abs_path):
		return null
	var ext := abs_path.get_extension().to_lower()
	if ext == "mp3":
		return AudioStreamMP3.load_from_file(abs_path)
	elif ext == "ogg":
		return AudioStreamOggVorbis.load_from_file(abs_path)
	elif ext == "wav":
		return AudioStreamWAV.load_from_file(abs_path)
	return null

static func load_json_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(f.get_as_text())
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}

static func save_json_dict(path: String, data: Dictionary) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(data, "\t"))

static func count_notes_in_chart(data: Dictionary) -> int:
	var count := 0
	var tracks: Dictionary = data.get("tracks", {})
	for inst in tracks.keys():
		if typeof(tracks[inst]) == TYPE_ARRAY:
			count += tracks[inst].size()
	return count

static func format_time(seconds: float) -> String:
	var total := int(maxf(0.0, seconds))
	var mins := total / 60
	var secs := total % 60
	return "%02d:%02d" % [mins, secs]
