extends Control

@onready var audio_player: AudioStreamPlayer = $AudioPreviewPlayer

var songs_cache: Array[Dictionary] = []
var selected_song: Dictionary = {}
var pending_play_beatmap_path: String = ""

# Containers principais
var song_list_vbox: VBoxContainer
var modal_overlay: ColorRect
var modal_content: VBoxContainer

# Controles do Player de Áudio
var is_seeking: bool = false
var progress_slider: HSlider
var time_label: Label
var btn_play_pause: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	size = get_viewport_rect().size
	_build_base_ui()
	refresh_gallery()

func _process(_delta: float) -> void:
	if audio_player.stream and progress_slider and not is_seeking:
		if audio_player.playing:
			progress_slider.value = audio_player.get_playback_position()
		time_label.text = "%s / %s" % [
			SoundtrackFS.format_time(progress_slider.value),
			SoundtrackFS.format_time(audio_player.stream.get_length())
		]

func _build_base_ui() -> void:
	# Fundo escuro estilo estúdio

	
	var bg := ColorRect.new()
	bg.color = Color("#121216")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var main_margin := MarginContainer.new()
	main_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_margin.add_theme_constant_override("margin_left", 48)
	main_margin.add_theme_constant_override("margin_right", 48)
	main_margin.add_theme_constant_override("margin_top", 32)
	main_margin.add_theme_constant_override("margin_bottom", 32)
	add_child(main_margin)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 16)
	main_margin.add_child(root_vbox)

	# Cabeçalho
	var header := HBoxContainer.new()
	root_vbox.add_child(header)

	var title_lbl := Label.new()
	title_lbl.text = "GRUNGE // GALERIA DE MÚSICAS"
	title_lbl.add_theme_font_size_override("font_size", 28)
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_lbl)
	
	var btn_folder := Button.new()
	btn_folder.text = "ABRIR PASTA"
	btn_folder.custom_minimum_size = Vector2(150, 44)
	btn_folder.pressed.connect(func(): OS.shell_open(SoundtrackFS.get_soundtrack_root()))
	header.add_child(btn_folder)

	var btn_import := Button.new()
	btn_import.text = "+ NOVA MÚSICA (MP3/OGG)"
	btn_import.custom_minimum_size = Vector2(240, 44)
	btn_import.pressed.connect(_open_import_dialog)
	header.add_child(btn_import)

	var btn_back_game := Button.new()
	btn_back_game.text = "VOLTAR AO GRUNGE"
	btn_back_game.custom_minimum_size = Vector2(180, 44)
	btn_back_game.pressed.connect(_on_back_to_grunge_pressed)
	header.add_child(btn_back_game)

	# Cabeçalho das colunas
	var cols_header := HBoxContainer.new()
	cols_header.add_theme_constant_override("separation", 12)
	root_vbox.add_child(cols_header)
	for col_info in [["MÚSICA", 360], ["AUTOR", 260], ["DURAÇÃO", 110], ["NOTAS", 110], ["BEATMAPS", 120]]:
		var l := Label.new()
		l.text = col_info[0]
		l.custom_minimum_size.x = col_info[1]
		l.modulate = Color(0.65, 0.65, 0.7)
		cols_header.add_child(l)

	# Lista rolável de músicas (VBoxContainer dentro de ScrollContainer)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(scroll)

	song_list_vbox = VBoxContainer.new()
	song_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	song_list_vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(song_list_vbox)

	# Overlay de Modais (Subtelas)
	modal_overlay = ColorRect.new()
	modal_overlay.color = Color(0, 0, 0, 0.82)
	modal_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal_overlay.visible = false
	add_child(modal_overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(680, 0)
	center.add_child(panel)

	var panel_margin := MarginContainer.new()
	panel_margin.add_theme_constant_override("margin_left", 28)
	panel_margin.add_theme_constant_override("margin_right", 28)
	panel_margin.add_theme_constant_override("margin_top", 24)
	panel_margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(panel_margin)

	modal_content = VBoxContainer.new()
	modal_content.add_theme_constant_override("separation", 14)
	panel_margin.add_child(modal_content)

func refresh_gallery() -> void:
	for child in song_list_vbox.get_children():
		song_list_vbox.remove_child(child)
		child.queue_free()

	songs_cache = SoundtrackFS.scan_all_songs()
	print("Gallery atualizada! Músicas encontradas: ", songs_cache.size(), " em ", SoundtrackFS.get_soundtrack_root())

	if songs_cache.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "Nenhuma música encontrada em: %s\nClique em '+ NOVA MÚSICA' para começar." % SoundtrackFS.get_soundtrack_root()
		song_list_vbox.add_child(empty_lbl)
		return

	for song in songs_cache:
		var row_btn := Button.new()
		row_btn.custom_minimum_size = Vector2(0, 56)
		row_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row_btn.pressed.connect(func(): _open_song_actions_menu(song))
		song_list_vbox.add_child(row_btn)

		var hbox := HBoxContainer.new()
		hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_theme_constant_override("separation", 12)
		row_btn.add_child(hbox)

		_add_cell(hbox, "  " + song["title"], 360)
		_add_cell(hbox, song["artist"], 260)
		_add_cell(hbox, SoundtrackFS.format_time(song["duration"]), 110)
		_add_cell(hbox, "%d notas" % song["total_notes"], 110)
		_add_cell(hbox, "%d versões" % song["beatmaps"].size(), 120)


func _add_cell(parent: Control, text_val: String, min_w: float) -> void:
	var lbl := Label.new()
	lbl.text = text_val
	lbl.custom_minimum_size.x = min_w
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.clip_text = true
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(lbl)

func _clear_modal() -> void:
	audio_player.stop()
	progress_slider = null
	for child in modal_content.get_children():
		child.queue_free()
	modal_overlay.visible = true

func _close_modal() -> void:
	audio_player.stop()
	progress_slider = null
	modal_overlay.visible = false
	refresh_gallery()

# ==============================================================================
# TELA 1: MENU PRINCIPAL DA MÚSICA SELECIONADA
# ==============================================================================
func _open_song_actions_menu(song: Dictionary) -> void:
	selected_song = song
	_clear_modal()

	var header := Label.new()
	header.text = "%s — %s" % [song["title"], song["artist"]]
	header.add_theme_font_size_override("font_size", 22)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_content.add_child(header)

	var options := [
		["OUVIR MÚSICA", _open_listen_view],
		["BEATMAPS (%d)" % song["beatmaps"].size(), _open_beatmaps_view],
		["EDITAR DETALHES", _open_edit_details_view],
		["EXCLUIR MÚSICA", _open_delete_confirm_view],
		["VOLTAR", _close_modal]
	]

	for opt in options:
		var btn := Button.new()
		btn.text = opt[0]
		btn.custom_minimum_size = Vector2(0, 46)
		btn.pressed.connect(opt[1])
		modal_content.add_child(btn)

# ==============================================================================
# TELA 2: OUVIR MÚSICA
# ==============================================================================
func _open_listen_view() -> void:
	_clear_modal()

	var top_bar := HBoxContainer.new()
	modal_content.add_child(top_bar)

	var title := Label.new()
	title.text = "OUVIR: %s" % selected_song["title"]
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(title)

	var btn_x := Button.new()
	btn_x.text = " X "
	btn_x.pressed.connect(func(): _open_song_actions_menu(selected_song))
	top_bar.add_child(btn_x)

	audio_player.stream = SoundtrackFS.load_audio_stream(selected_song["audio_path"])
	audio_player.play()

	progress_slider = HSlider.new()
	progress_slider.min_value = 0.0
	progress_slider.max_value = audio_player.stream.get_length() if audio_player.stream else 1.0
	progress_slider.step = 0.1
	progress_slider.drag_started.connect(func(): is_seeking = true)
	progress_slider.drag_ended.connect(func(_changed):
		is_seeking = false
		audio_player.seek(progress_slider.value)
	)
	modal_content.add_child(progress_slider)

	time_label = Label.new()
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_content.add_child(time_label)

	var controls := HBoxContainer.new()
	controls.alignment = BoxContainer.ALIGNMENT_CENTER
	controls.add_theme_constant_override("separation", 12)
	modal_content.add_child(controls)

	var btn_back := Button.new()
	btn_back.text = "<< -5s"
	btn_back.pressed.connect(func(): audio_player.seek(maxf(0.0, audio_player.get_playback_position() - 5.0)))
	controls.add_child(btn_back)

	btn_play_pause = Button.new()
	btn_play_pause.text = "PAUSAR"
	btn_play_pause.custom_minimum_size.x = 120
	btn_play_pause.pressed.connect(func():
		audio_player.stream_paused = not audio_player.stream_paused
		btn_play_pause.text = "CONTINUAR" if audio_player.stream_paused else "PAUSAR"
	)
	controls.add_child(btn_play_pause)

	var btn_fwd := Button.new()
	btn_fwd.text = "+5s >>"
	btn_fwd.pressed.connect(func(): audio_player.seek(audio_player.get_playback_position() + 5.0))
	controls.add_child(btn_fwd)

	# Controle de Volume
	var vol_box := HBoxContainer.new()
	modal_content.add_child(vol_box)
	var vol_lbl := Label.new()
	vol_lbl.text = "Volume: "
	vol_box.add_child(vol_lbl)

	var vol_slider := HSlider.new()
	vol_slider.min_value = 0.0
	vol_slider.max_value = 1.0
	vol_slider.step = 0.05
	vol_slider.value = 0.8
	vol_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vol_slider.value_changed.connect(func(v): audio_player.volume_db = linear_to_db(v))
	vol_box.add_child(vol_slider)

# ==============================================================================
# TELA 3: BEATMAPS DA MÚSICA (JOGAR / EDITAR / OFICIAL / EXCLUIR)
# ==============================================================================
func _open_beatmaps_view() -> void:
	_clear_modal()
	# Recarrega lista atualizada do disco
	var beatmaps_list := SoundtrackFS.list_beatmaps(selected_song["charts_dir"], selected_song["index"])

	var header := HBoxContainer.new()
	modal_content.add_child(header)

	var lbl := Label.new()
	lbl.text = "BEATMAPS DE: %s" % selected_song["title"]
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(lbl)

	var btn_new := Button.new()
	btn_new.text = "+ NOVO BEATMAP"
	btn_new.pressed.connect(func():
		SoundtrackFS.create_new_beatmap(selected_song)
		_open_beatmaps_view()
	)
	header.add_child(btn_new)

	var list_vbox := VBoxContainer.new()
	list_vbox.add_theme_constant_override("separation", 8)
	modal_content.add_child(list_vbox)

	for bmp in beatmaps_list:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		list_vbox.add_child(row)

		var name_lbl := Label.new()
		name_lbl.text = "%s (%d notas)" % [bmp["name"], bmp["note_count"]]
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_lbl)

		var btn_play := Button.new()
		btn_play.text = "JOGAR"
		btn_play.pressed.connect(func(): _open_quickplay_instrument_picker(bmp["path"]))
		row.add_child(btn_play)

		var btn_edit := Button.new()
		btn_edit.text = "EDITAR"
		btn_edit.pressed.connect(func(): _open_editor_placeholder(bmp["path"]))
		row.add_child(btn_edit)

		var btn_official := Button.new()
		btn_official.text = "USAR NO JOGO"
		btn_official.tooltip_text = "Define este beatmap como o music_%d.json oficial" % selected_song["index"]
		btn_official.pressed.connect(func():
			SoundtrackFS.publish_beatmap_as_official(bmp["path"], selected_song["official_json_path"])
			_open_beatmaps_view()
		)
		row.add_child(btn_official)

		var btn_del := Button.new()
		btn_del.text = "EXCLUIR"
		btn_del.pressed.connect(func():
			DirAccess.remove_absolute(bmp["path"])
			_open_beatmaps_view()
		)
		row.add_child(btn_del)

	var btn_back := Button.new()
	btn_back.text = "VOLTAR"
	btn_back.pressed.connect(func(): _open_song_actions_menu(selected_song))
	modal_content.add_child(btn_back)

func _open_quickplay_instrument_picker(beatmap_path: String) -> void:
	pending_play_beatmap_path = beatmap_path
	_clear_modal()

	var lbl := Label.new()
	lbl.text = "QUICK PLAY — ESCOLHA O INSTRUMENTO"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_content.add_child(lbl)

	for inst in ["guitar", "drums", "vocal", "bass"]:
		var btn := Button.new()
		btn.text = inst.to_upper()
		btn.custom_minimum_size = Vector2(0, 44)
		btn.pressed.connect(func():
			Globals.instrumento_1 = inst
			Globals.is_single_player = true
			Globals.set_meta("quickplay_chart_path", pending_play_beatmap_path)
			Globals.set_meta("quickplay_audio_path", selected_song["audio_path"])
			get_tree().change_scene_to_file("res://scenes/gameplay/play_map.tscn")
		)
		modal_content.add_child(btn)

	var btn_cancel := Button.new()
	btn_cancel.text = "CANCELAR"
	btn_cancel.pressed.connect(_open_beatmaps_view)
	modal_content.add_child(btn_cancel)

func _open_editor_placeholder(beatmap_path: String) -> void:
	_clear_modal()
	var lbl := Label.new()
	lbl.text = "[PLACEHOLDER DO CHART EDITOR]\nBeatmap pronto para edição:\n%s" % beatmap_path
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_content.add_child(lbl)

	var btn_back := Button.new()
	btn_back.text = "VOLTAR PARA BEATMAPS"
	btn_back.pressed.connect(_open_beatmaps_view)
	modal_content.add_child(btn_back)

# ==============================================================================
# TELA 4: EDITAR DETALHES
# ==============================================================================
func _open_edit_details_view() -> void:
	_clear_modal()

	var title_input := LineEdit.new()
	title_input.text = selected_song["title"]
	title_input.placeholder_text = "Nome da Música"
	modal_content.add_child(title_input)

	var author_input := LineEdit.new()
	author_input.text = selected_song["artist"]
	author_input.placeholder_text = "Nome do Autor"
	modal_content.add_child(author_input)

	var btn_save := Button.new()
	btn_save.text = "SALVAR ALTERAÇÕES"
	btn_save.pressed.connect(func():
		SoundtrackFS.update_song_metadata(selected_song, title_input.text, author_input.text)
		selected_song["title"] = title_input.text
		selected_song["artist"] = author_input.text
		_open_song_actions_menu(selected_song)
	)
	modal_content.add_child(btn_save)

	var btn_back := Button.new()
	btn_back.text = "CANCELAR"
	btn_back.pressed.connect(func(): _open_song_actions_menu(selected_song))
	modal_content.add_child(btn_back)

# ==============================================================================
# TELA 5: CONFIRMAR EXCLUSÃO DA MÚSICA
# ==============================================================================
func _open_delete_confirm_view() -> void:
	_clear_modal()

	var warn := Label.new()
	warn.text = "Você quer mesmo excluir essa música?\n(%s)" % selected_song["title"]
	warn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_content.add_child(warn)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 20)
	modal_content.add_child(hbox)

	var btn_del := Button.new()
	btn_del.text = "EXCLUIR"
	btn_del.custom_minimum_size = Vector2(150, 44)
	btn_del.pressed.connect(func():
		SoundtrackFS.delete_song_folder(selected_song["folder_path"])
		_close_modal()
	)
	hbox.add_child(btn_del)

	var btn_back := Button.new()
	btn_back.text = "VOLTAR"
	btn_back.custom_minimum_size = Vector2(150, 44)
	btn_back.pressed.connect(func(): _open_song_actions_menu(selected_song))
	hbox.add_child(btn_back)
	
func _on_back_to_grunge_pressed() -> void:
	audio_player.stop()
	var main_node = get_tree().root.get_node_or_null("Main")
	var settings_scene = load("res://scenes/telas/settings_menu.tscn")
	if main_node and settings_scene:
		var old_stage_id = main_node.get_child_count() - 1
		var stage = settings_scene.instantiate()
		main_node.add_child(stage)
		main_node.get_child(old_stage_id).queue_free()
	elif settings_scene:
		# Fallback caso a Gallery tenha sido aberta diretamente com F6
		get_tree().change_scene_to_file("res://scenes/telas/settings_menu.tscn")

# ==============================================================================
# IMPORTAR NOVA MÚSICA (ARQUIVO MP3/OGG DO PC)
# ==============================================================================
func _open_import_dialog() -> void:
	var fd := FileDialog.new()
	fd.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	fd.access = FileDialog.ACCESS_FILESYSTEM
	fd.use_native_dialog = true # Abre o explorador nativo do sistema!
	fd.filters = PackedStringArray(["*.mp3, *.ogg, *.wav ; Arquivos de Áudio"])
	fd.file_selected.connect(func(path: String):
		print("Importando áudio: ", path)
		var default_title := path.get_file().get_basename()
		var ok := SoundtrackFS.import_new_song(path, default_title, "Autor", 120.0)
		print("Resultado da importação: ", ok, " -> ", SoundtrackFS.get_soundtrack_root())
		fd.queue_free()
		call_deferred("refresh_gallery")
	)
	fd.canceled.connect(func(): fd.queue_free())
	add_child(fd)
	fd.popup_centered(Vector2i(800, 500))
