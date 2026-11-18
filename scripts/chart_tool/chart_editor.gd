extends Control

@onready var song_player: AudioStreamPlayer = $SongPlayer
@onready var hitsound_player: AudioStreamPlayer = $HitSoundPlayer

# Cores oficiais das 4 lanes (iguais ao note_visual.gd)
const LANE_COLORS: Dictionary = {
	1: Color("#22c55e"), # Verde
	2: Color("#ef4444"), # Vermelho
	3: Color("#eab308"), # Amarelo
	4: Color("#3b82f6")  # Azul
}
const LANE_KEYS: Array[String] = ["D", "F", "J", "K"]
const INSTRUMENTS: Array[String] = ["guitar", "drums", "vocal", "bass"]

# Dados do Beatmap carregado
var beatmap_path: String = ""
var chart_data: Dictionary = {}
var current_instrument: String = "guitar"

# Parâmetros rítmicos e de edição
var bpm: float = 120.0
var beat_divisor: int = 1        # 1 = Beat inteiro, 2 = Semi-beat (1/2), 4 = 1/4, 8 = 1/8
var free_mode: bool = false      # false = Beat Lock, true = Arrastar livre com precisão mínima
var free_snap_min: float = 0.05  # Distância mínima entre notas no modo livre (segundos)
var current_shape: String = "c"  # "c" (Circular) ou "sq" (Quadrada/Pedal)
var hitsound_enabled: bool = true
var show_ghost_notes: bool = true

# Estado da Timeline e Reprodução
var playhead_time: float = 0.0
var is_playing: bool = false
var countdown_remaining: float = 0.0
var last_play_time: float = 0.0
var pixels_per_second: float = 220.0
var song_duration: float = 60.0

# Seleção, Arrasto e Undo/Redo
var selected_note: Dictionary = {} # Referência direta ao dicionário da nota selecionada
var is_creating_sustain: bool = false
var is_dragging_free: bool = false
var drag_note_ref: Dictionary = {}
var drag_start_time: float = 0.0
var live_held_notes: Dictionary = {} # lane (1..4) -> Dicionario da nota sendo segurada
var undo_stack: Array[String] = []
var redo_stack: Array[String] = []
var has_unsaved_changes: bool = false

# Nós de UI criados dinamicamente
var timeline_canvas: Control
var btn_play: Button
var lbl_time: Label
var lbl_status: Label
var btn_shape_c: Button
var btn_shape_sq: Button
var btn_mode_lock: Button
var btn_mode_free: Button
var spin_bpm: SpinBox
var opt_divisor: OptionButton
var spin_free_prec: SpinBox
var inst_buttons: Dictionary = {}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	size = get_viewport_rect().size
	
	# Recupera o caminho do beatmap enviado pela Gallery
	if Globals.has_meta("editing_beatmap_path"):
		beatmap_path = str(Globals.get_meta("editing_beatmap_path"))
	
	_load_chart_from_disk()
	_build_editor_ui()
	_push_undo_state()
	_update_ui_states()

func _load_chart_from_disk() -> void:
	if beatmap_path != "" and FileAccess.file_exists(beatmap_path):
		chart_data = SoundtrackFS.load_json_dict(beatmap_path)
	else:
		# Fallback caso abra direto com F6 para teste
		chart_data = {
			"title": "Teste Editor",
			"artist": "GRUNGE Dev",
			"bpm": 120.0,
			"beat_divisor": 1,
			"free_snap_min": 0.05,
			"audio_path": "",
			"tracks": {"guitar": [], "drums": [], "vocal": [], "bass": []}
		}

	bpm = float(chart_data.get("bpm", 120.0))
	beat_divisor = int(chart_data.get("beat_divisor", 1))
	free_snap_min = float(chart_data.get("free_snap_min", 0.05))

	if not chart_data.has("tracks"):
		chart_data["tracks"] = {}
	for inst in INSTRUMENTS:
		if not chart_data["tracks"].has(inst):
			chart_data["tracks"][inst] = []

	var audio_path := str(chart_data.get("audio_path", ""))
	if audio_path != "":
		var stream := SoundtrackFS.load_audio_stream(audio_path)
		if stream:
			song_player.stream = stream
			song_duration = stream.get_length()

func _process(delta: float) -> void:
	if countdown_remaining > 0.0:
		var prev_sec := int(ceil(countdown_remaining))
		countdown_remaining -= delta
		var cur_sec := int(ceil(countdown_remaining))
		if cur_sec < prev_sec and cur_sec > 0 and hitsound_player.stream:
			hitsound_player.play()
		if countdown_remaining <= 0.0:
			countdown_remaining = 0.0
			is_playing = true
			last_play_time = playhead_time
			song_player.play(playhead_time)
			btn_play.text = "⏸ PAUSAR (ESPAÇO)"
	elif is_playing and song_player.stream:
		var prev_t := last_play_time
		playhead_time = song_player.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
		playhead_time = maxf(0.0, playhead_time)
		
		# Atualiza o sustain de qualquer tecla (D/F/J/K) segurada ao vivo (mínimo de 1/2 beat inteiro)
		var min_key_sustain: float = (60.0 / maxf(1.0, bpm)) * 0.5
		for held_lane in live_held_notes.keys():
			var held_note: Dictionary = live_held_notes[held_lane]
			var held_dur: float = maxf(0.0, _snap_time(playhead_time) - float(held_note["time"]))
			if held_dur >= min_key_sustain:
				held_note["duration"] = snappedf(held_dur, 0.001)
				has_unsaved_changes = true
		
		if hitsound_enabled and hitsound_player.stream:
			for note in _get_current_notes():
				var nt := float(note["time"])
				if nt > prev_t and nt <= playhead_time:
					hitsound_player.play()
					break
		
		last_play_time = playhead_time
		if not song_player.playing:
			_stop_playback()
	
	if lbl_time:
		lbl_time.text = "%s / %s  (Beat %.2f)" % [
			SoundtrackFS.format_time(playhead_time),
			SoundtrackFS.format_time(song_duration),
			playhead_time / _get_beat_step()
		]
	
	if timeline_canvas:
		timeline_canvas.queue_redraw()


# ==============================================================================
# CONSTRUÇÃO DA INTERFACE DO ESTÚDIO (1366x768)
# ==============================================================================
func _build_editor_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#101014")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var main_vbox := VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 6)
	add_child(main_vbox)

	# --- BARRA SUPERIOR (Navegação, Instrumentos e Salvar) ---
	var top_bar := PanelContainer.new()
	main_vbox.add_child(top_bar)
	var top_hbox := HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 10)
	top_bar.add_child(top_hbox)

	var btn_back := Button.new()
	btn_back.text = "< GALERIA"
	btn_back.custom_minimum_size = Vector2(110, 38)
	btn_back.pressed.connect(_on_back_pressed)
	top_hbox.add_child(btn_back)

	var title_lbl := Label.new()
	title_lbl.text = "  %s" % str(chart_data.get("title", "Sem Título"))
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.clip_text = true
	top_hbox.add_child(title_lbl)

	# Abas dos 4 Instrumentos
	for inst in INSTRUMENTS:
		var b := Button.new()
		b.text = inst.to_upper()
		b.custom_minimum_size = Vector2(95, 38)
		b.pressed.connect(func(): _switch_instrument(inst))
		top_hbox.add_child(b)
		inst_buttons[inst] = b

	var sep1 := VSeparator.new()
	top_hbox.add_child(sep1)

	var btn_undo := Button.new()
	btn_undo.text = "UNDO"
	btn_undo.tooltip_text = "Desfazer (Ctrl+Z)"
	btn_undo.pressed.connect(_undo)
	top_hbox.add_child(btn_undo)

	var btn_redo := Button.new()
	btn_redo.text = "REDO"
	btn_redo.tooltip_text = "Refazer (Ctrl+Y)"
	btn_redo.pressed.connect(_redo)
	top_hbox.add_child(btn_redo)

	var btn_save := Button.new()
	btn_save.text = "SALVAR (Ctrl+S)"
	btn_save.custom_minimum_size = Vector2(140, 38)
	btn_save.pressed.connect(_save_chart)
	top_hbox.add_child(btn_save)
	
	var btn_test_play := Button.new()
	btn_test_play.text = "▶ JOGAR"
	btn_test_play.custom_minimum_size = Vector2(115, 38)
	btn_test_play.modulate = Color("#4ade80")
	btn_test_play.pressed.connect(_on_test_play_pressed)
	top_hbox.add_child(btn_test_play)

	# --- CORPO CENTRAL: PAINEL ESQUERDO (FERRAMENTAS) + TIMELINE ---
	var body_hbox := HBoxContainer.new()
	body_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_hbox.add_theme_constant_override("separation", 8)
	main_vbox.add_child(body_hbox)

	# Painel Lateral de Ferramentas Visuais (100% intuitivo para o mapper)
	var side_panel := PanelContainer.new()
	side_panel.custom_minimum_size = Vector2(280, 0)
	body_hbox.add_child(side_panel)

	var side_margin := MarginContainer.new()
	side_margin.add_theme_constant_override("margin_left", 14)
	side_margin.add_theme_constant_override("margin_right", 14)
	side_margin.add_theme_constant_override("margin_top", 12)
	side_margin.add_theme_constant_override("margin_bottom", 12)
	side_panel.add_child(side_margin)

	var side_vbox := VBoxContainer.new()
	side_vbox.add_theme_constant_override("separation", 12)
	side_margin.add_child(side_vbox)

	# 1. Seletor Visual de Forma da Nota (Circular vs Quadrada/Pedal)
	_add_section_label(side_vbox, "1. TIPO DA NOTA (TECLAS 1 / 2)")
	var shape_hbox := HBoxContainer.new()
	shape_hbox.add_theme_constant_override("separation", 8)
	side_vbox.add_child(shape_hbox)

	btn_shape_c = Button.new()
	btn_shape_c.text = "● CIRCULAR (c)"
	btn_shape_c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_shape_c.custom_minimum_size.y = 42
	btn_shape_c.pressed.connect(func(): _set_note_shape("c"))
	shape_hbox.add_child(btn_shape_c)

	btn_shape_sq = Button.new()
	btn_shape_sq.text = "■ PEDAL (sq)"
	btn_shape_sq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_shape_sq.custom_minimum_size.y = 42
	btn_shape_sq.pressed.connect(func(): _set_note_shape("sq"))
	shape_hbox.add_child(btn_shape_sq)

	# 2. Modo de Edição: Beat Lock vs Modo Livre
	_add_section_label(side_vbox, "2. MODO DE GRID / LOCK")
	var mode_hbox := HBoxContainer.new()
	mode_hbox.add_theme_constant_override("separation", 8)
	side_vbox.add_child(mode_hbox)

	btn_mode_lock = Button.new()
	btn_mode_lock.text = "BEAT LOCK"
	btn_mode_lock.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_mode_lock.custom_minimum_size.y = 38
	btn_mode_lock.pressed.connect(func(): _set_free_mode(false))
	mode_hbox.add_child(btn_mode_lock)

	btn_mode_free = Button.new()
	btn_mode_free.text = "MODO LIVRE"
	btn_mode_free.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_mode_free.custom_minimum_size.y = 38
	btn_mode_free.pressed.connect(func(): _set_free_mode(true))
	mode_hbox.add_child(btn_mode_free)

	# Configuração do Beat e Semi-Beat
	var bpm_row := HBoxContainer.new()
	side_vbox.add_child(bpm_row)
	var bpm_lbl := Label.new()
	bpm_lbl.text = "BPM da Música:"
	bpm_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bpm_row.add_child(bpm_lbl)

	spin_bpm = SpinBox.new()
	spin_bpm.min_value = 40.0
	spin_bpm.max_value = 320.0
	spin_bpm.step = 0.5
	spin_bpm.value = bpm
	spin_bpm.value_changed.connect(func(v):
		bpm = v
		chart_data["bpm"] = bpm
		has_unsaved_changes = true
	)
	bpm_row.add_child(spin_bpm)

	var div_row := HBoxContainer.new()
	side_vbox.add_child(div_row)
	var div_lbl := Label.new()
	div_lbl.text = "Subdivisão:"
	div_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	div_row.add_child(div_lbl)

	opt_divisor = OptionButton.new()
	opt_divisor.add_item("Beat (1/1)", 1)
	opt_divisor.add_item("Semi-Beat (1/2)", 2)
	opt_divisor.add_item("Tercina (1/3)", 3)
	opt_divisor.add_item("1/4 Beat", 4)
	opt_divisor.add_item("1/8 Beat", 8)
	for i in range(opt_divisor.item_count):
		if opt_divisor.get_item_id(i) == beat_divisor:
			opt_divisor.select(i)
	opt_divisor.item_selected.connect(func(idx):
		beat_divisor = opt_divisor.get_item_id(idx)
		chart_data["beat_divisor"] = beat_divisor
		has_unsaved_changes = true
	)
	div_row.add_child(opt_divisor)

	# Precisão editável do Modo Livre (para nunca encavalar notas)
	var prec_row := HBoxContainer.new()
	side_vbox.add_child(prec_row)
	var prec_lbl := Label.new()
	prec_lbl.text = "Trava Livre (s):"
	prec_lbl.tooltip_text = "Distância mínima em segundos entre duas notas no Modo Livre"
	prec_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prec_row.add_child(prec_lbl)

	spin_free_prec = SpinBox.new()
	spin_free_prec.min_value = 0.01
	spin_free_prec.max_value = 0.50
	spin_free_prec.step = 0.01
	spin_free_prec.value = free_snap_min
	spin_free_prec.value_changed.connect(func(v):
		free_snap_min = v
		chart_data["free_snap_min"] = free_snap_min
	)
	prec_row.add_child(spin_free_prec)

	# 3. Auxiliares de Áudio e Visual
	_add_section_label(side_vbox, "3. ÁUDIO & VISUAL")
	var chk_hit := CheckButton.new()
	chk_hit.text = "Hitsound (Tick nas notas)"
	chk_hit.button_pressed = hitsound_enabled
	chk_hit.toggled.connect(func(on): hitsound_enabled = on)
	side_vbox.add_child(chk_hit)

	var chk_ghost := CheckButton.new()
	chk_ghost.text = "Ghost Notes (Outros inst.)"
	chk_ghost.button_pressed = show_ghost_notes
	chk_ghost.toggled.connect(func(on): show_ghost_notes = on)
	side_vbox.add_child(chk_ghost)

	var speed_row := HBoxContainer.new()
	side_vbox.add_child(speed_row)
	var spd_lbl := Label.new()
	spd_lbl.text = "Velocidade:"
	spd_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	speed_row.add_child(spd_lbl)
	for spd in [0.5, 0.75, 1.0]:
		var sb := Button.new()
		sb.text = "%sx" % str(spd)
		sb.pressed.connect(func(): song_player.pitch_scale = spd)
		speed_row.add_child(sb)

	# Dicas rápidas para o mapper
	var help_lbl := Label.new()
	help_lbl.text = "\nATALHOS:\n• Clique Esq: Criar/Selecionar\n• Clique + Arrastar: Sustain\n• Clique Dir: Apagar nota\n• Setas ↑/↓ ou Scroll: Mover\n• Espaço: Play / Pause\n• D/F/J/K (tocando): Gravar ao vivo"
	help_lbl.modulate = Color(0.7, 0.7, 0.75)
	help_lbl.add_theme_font_size_override("font_size", 13)
	side_vbox.add_child(help_lbl)

	# --- ÁREA DA TIMELINE (PISTA 4 LANES) ---
	timeline_canvas = Control.new()
	timeline_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	timeline_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	timeline_canvas.clip_contents = true
	timeline_canvas.draw.connect(_on_timeline_draw)
	timeline_canvas.gui_input.connect(_on_timeline_gui_input)
	body_hbox.add_child(timeline_canvas)

	# --- BARRA INFERIOR DE CONTROLE DE REPRODUÇÃO ---
	var bottom_bar := PanelContainer.new()
	main_vbox.add_child(bottom_bar)
	var bot_hbox := HBoxContainer.new()
	bot_hbox.add_theme_constant_override("separation", 14)
	bottom_bar.add_child(bot_hbox)

	var btn_start := Button.new()
	btn_start.text = "|< INÍCIO"
	btn_start.pressed.connect(func():
		_stop_playback()
		playhead_time = 0.0
	)
	bot_hbox.add_child(btn_start)

	btn_play = Button.new()
	btn_play.text = "▶ PLAY (ESPAÇO)"
	btn_play.custom_minimum_size = Vector2(160, 38)
	btn_play.pressed.connect(_toggle_playback)
	bot_hbox.add_child(btn_play)

	lbl_time = Label.new()
	lbl_time.text = "00:00 / 00:00"
	bot_hbox.add_child(lbl_time)

	lbl_status = Label.new()
	lbl_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl_status.modulate = Color("#4ade80")
	bot_hbox.add_child(lbl_status)

func _add_section_label(parent: Control, txt: String) -> void:
	var l := Label.new()
	l.text = txt
	l.modulate = Color("#a1a1aa")
	l.add_theme_font_size_override("font_size", 13)
	parent.add_child(l)

# ==============================================================================
# DESENHO DA TIMELINE E HIGHWAY 2D DE EDIÇÃO
# ==============================================================================
func _on_timeline_draw() -> void:
	var rect := timeline_canvas.get_rect()
	var w := rect.size.x
	var h := rect.size.y

	# Fundo da highway
	timeline_canvas.draw_rect(Rect2(0, 0, w, h), Color("#18181f"))

	var track_w := minf(520.0, w - 140.0)
	var track_x := (w - track_w) * 0.5
	var lane_w := track_w / 4.0
	var hit_y := h - 110.0 # Linha vermelha/ciano onde fica a agulha (playhead)

	# Fundo escuro da pista de 4 lanes
	timeline_canvas.draw_rect(Rect2(track_x, 0, track_w, h), Color("#0d0d11"))

	# 1. Linhas de Grid do BPM (Beat inteiro + Subdivisões)
	var full_beat := 60.0 / maxf(1.0, bpm)
	var step := _get_beat_step()
	var min_visible_t := maxf(0.0, playhead_time - (h - hit_y) / pixels_per_second)
	var max_visible_t := playhead_time + hit_y / pixels_per_second

	var start_step_idx := int(floor(min_visible_t / step))
	var end_step_idx := int(ceil(max_visible_t / step))

	for idx in range(start_step_idx, end_step_idx + 1):
		var t := idx * step
		var y := hit_y - (t - playhead_time) * pixels_per_second
		var is_main_beat := (idx % beat_divisor) == 0
		var line_col := Color(1, 1, 1, 0.28) if is_main_beat else Color(1, 1, 1, 0.08)
		timeline_canvas.draw_line(Vector2(track_x, y), Vector2(track_x + track_w, y), line_col, 2.0 if is_main_beat else 1.0)
		if is_main_beat:
			timeline_canvas.draw_string(ThemeDB.fallback_font, Vector2(track_x - 52, y + 4), "%.1fs" % t, HORIZONTAL_ALIGNMENT_RIGHT, 46, 12, Color(0.6, 0.6, 0.65))

	# 2. Divisórias verticais das 4 lanes
	for i in range(5):
		var lx := track_x + i * lane_w
		timeline_canvas.draw_line(Vector2(lx, 0), Vector2(lx, h), Color(1, 1, 1, 0.18), 2.0)

	# 3. Ghost Notes (marcadores sutis dos outros instrumentos)
	if show_ghost_notes:
		for inst in INSTRUMENTS:
			if inst == current_instrument:
				continue
			for gnote in chart_data["tracks"][inst]:
				var gt := float(gnote["time"])
				if gt < min_visible_t or gt > max_visible_t:
					continue
				var gy := hit_y - (gt - playhead_time) * pixels_per_second
				var glane := clampi(int(gnote["lane"]), 1, 4)
				var gx := track_x + (glane - 0.5) * lane_w
				timeline_canvas.draw_circle(Vector2(gx, gy), 6.0, Color(1, 1, 1, 0.14))

	# 4. Notas do Instrumento Atual (Sustains + Cabeças)
	for note in _get_current_notes():
		var nt := float(note["time"])
		var dur := float(note.get("duration", 0.0))
		if nt + dur < min_visible_t or nt > max_visible_t:
			continue

		var lane := clampi(int(note["lane"]), 1, 4)
		var shape := str(note.get("type", "c"))
		var col: Color = LANE_COLORS[lane]
		var cx := track_x + (lane - 0.5) * lane_w
		var cy := hit_y - (nt - playhead_time) * pixels_per_second
		var is_sel: bool = (note == selected_note)

		# Desenha o Sustain (Tail) se duration > 0
		if dur > 0.01:
			var tail_h := dur * pixels_per_second
			var tail_rect := Rect2(cx - 10.0, cy - tail_h, 20.0, tail_h)
			timeline_canvas.draw_rect(tail_rect, Color(col.r, col.g, col.b, 0.55))
			timeline_canvas.draw_rect(tail_rect, col, false, 2.0)

		# Desenha a Cabeça da Nota: Círculo ("c") ou Quadrada/Pedal ("sq")
		if shape == "sq":
			var sq_rect := Rect2(cx - 20.0, cy - 14.0, 40.0, 28.0)
			timeline_canvas.draw_rect(sq_rect, col)
			timeline_canvas.draw_rect(sq_rect, Color.WHITE if is_sel else Color.BLACK, false, 3.0 if is_sel else 2.0)
		else:
			timeline_canvas.draw_circle(Vector2(cx, cy), 17.0, col)
			timeline_canvas.draw_arc(Vector2(cx, cy), 17.0, 0, TAU, 24, Color.WHITE if is_sel else Color.BLACK, 3.0 if is_sel else 2.0)

	# 5. Linha da Agulha (Playhead / Hitzone) e Botões das Lanes
	timeline_canvas.draw_line(Vector2(track_x - 16, hit_y), Vector2(track_x + track_w + 16, hit_y), Color("#38bdf8"), 3.0)
	for lane_i in range(1, 5):
		var bx := track_x + (lane_i - 0.5) * lane_w
		var bcol: Color = LANE_COLORS[lane_i]
		timeline_canvas.draw_circle(Vector2(bx, hit_y), 14.0, Color(bcol.r, bcol.g, bcol.b, 0.25))
		timeline_canvas.draw_string(ThemeDB.fallback_font, Vector2(bx - 6, hit_y + 32), LANE_KEYS[lane_i - 1], HORIZONTAL_ALIGNMENT_CENTER, 16, 16, bcol)

	# 6. Overlay visual da contagem regressiva de 3 segundos
	if countdown_remaining > 0.0:
		var sec_txt := str(int(ceil(countdown_remaining)))
		timeline_canvas.draw_rect(Rect2(track_x, 0, track_w, h), Color(0, 0, 0, 0.45))
		timeline_canvas.draw_string(ThemeDB.fallback_font, Vector2(track_x + track_w * 0.5 - 24, h * 0.45), sec_txt, HORIZONTAL_ALIGNMENT_CENTER, 48, 84, Color("#38bdf8"))
		
# ==============================================================================
# INTERAÇÃO DO MOUSE E TECLADO NA TIMELINE
# ==============================================================================
func _on_timeline_gui_input(event: InputEvent) -> void:
	var w := timeline_canvas.size.x
	var h := timeline_canvas.size.y
	var track_w := minf(520.0, w - 140.0)
	var track_x := (w - track_w) * 0.5
	var lane_w := track_w / 4.0
	var hit_y := h - 110.0

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_step_timeline(1)
			return
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_step_timeline(-1)
			return

	if event is InputEventMouseButton:
		var mpos: Vector2 = event.position
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			is_creating_sustain = false
			is_dragging_free = false
			drag_note_ref = {}
			_sort_current_notes()
			return

		if mpos.x < track_x or mpos.x > track_x + track_w:
			return

		var clicked_lane := clampi(int((mpos.x - track_x) / lane_w) + 1, 1, 4)
		var raw_time := maxf(0.0, playhead_time + (hit_y - mpos.y) / pixels_per_second)
		var snapped_t := _snap_time(raw_time)

		if event.pressed:
			var existing := _find_note_near(clicked_lane, raw_time, 0.14)

			# Botão Direito: Apaga a nota
			if event.button_index == MOUSE_BUTTON_RIGHT:
				if not existing.is_empty():
					_push_undo_state()
					_get_current_notes().erase(existing)
					if selected_note == existing:
						selected_note = {}
					has_unsaved_changes = true
					_set_status("Nota removida.")
				return

			# Botão Esquerdo
			if event.button_index == MOUSE_BUTTON_LEFT:
				if not existing.is_empty():
					selected_note = existing
					_update_ui_states()
					if free_mode:
						_push_undo_state()
						is_dragging_free = true
						drag_note_ref = existing
						drag_start_time = float(existing["time"])
					else:
						# No Beat Lock, clicar e arrastar uma nota existente permite editar o sustain dela!
						_push_undo_state()
						is_creating_sustain = true
					return

				if free_mode:
					_set_status("Modo Livre ativo: arraste notas existentes ou volte para BEAT LOCK para criar.")
					return

				if not _has_note_conflict(clicked_lane, snapped_t, {}):
					_push_undo_state()
					var new_note := {
						"time": snappedf(snapped_t, 0.001),
						"lane": clicked_lane,
						"type": current_shape,
						"duration": 0.0
					}
					_get_current_notes().append(new_note)
					_sort_current_notes()
					selected_note = new_note
					is_creating_sustain = true
					has_unsaved_changes = true
					_set_status("Nota criada em %.3fs (Arraste para cima para Sustain)" % new_note["time"])
				else:
					_set_status("Bloqueado: já existe uma nota nesse beat/lane!")

	elif event is InputEventMouseMotion:
		var mpos: Vector2 = event.position
		var raw_time := maxf(0.0, playhead_time + (hit_y - mpos.y) / pixels_per_second)

		# Estendendo Sustain ao arrastar para cima na timeline
		if is_creating_sustain and not selected_note.is_empty():
			var end_t := _snap_time(raw_time)
			var dur := maxf(0.0, end_t - float(selected_note["time"]))
			selected_note["duration"] = snappedf(dur, 0.001)
			has_unsaved_changes = true
			if dur > 0.0:
				_set_status("Sustain: %.3fs" % selected_note["duration"])

		# Movendo nota existente no Modo Livre
		elif is_dragging_free and not drag_note_ref.is_empty():
			var candidate_t := snappedf(raw_time, 0.005)
			if not _has_note_conflict(int(drag_note_ref["lane"]), candidate_t, drag_note_ref, free_snap_min):
				drag_note_ref["time"] = snappedf(candidate_t, 0.001)
				has_unsaved_changes = true
				_set_status("Posição livre: %.3fs" % drag_note_ref["time"])


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			_toggle_playback()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_UP:
			_step_timeline(1)
		elif event.keycode == KEY_DOWN:
			_step_timeline(-1)
		elif event.keycode == KEY_1:
			_set_note_shape("c")
		elif event.keycode == KEY_2:
			_set_note_shape("sq")
		elif event.keycode == KEY_DELETE or event.keycode == KEY_BACKSPACE:
			if not selected_note.is_empty():
				_push_undo_state()
				_get_current_notes().erase(selected_note)
				selected_note = {}
				has_unsaved_changes = true
		elif event.ctrl_pressed and event.keycode == KEY_S:
			_save_chart()
			get_viewport().set_input_as_handled()
		elif event.ctrl_pressed and event.keycode == KEY_Z:
			_undo()
			get_viewport().set_input_as_handled()
		elif event.ctrl_pressed and event.keycode == KEY_Y:
			_redo()
			get_viewport().set_input_as_handled()

		# Gravação ao vivo com teclas D, F, J, K enquanto a música toca
		elif is_playing and not free_mode:
			var key_map := {KEY_D: 1, KEY_F: 2, KEY_J: 3, KEY_K: 4}
			if key_map.has(event.keycode):
				var lane: int = key_map[event.keycode]
				var snapped_t := _snap_time(playhead_time)
				if not _has_note_conflict(lane, snapped_t, {}):
					_push_undo_state()
					var note := {
						"time": snappedf(snapped_t, 0.001),
						"lane": lane,
						"type": current_shape,
						"duration": 0.0
					}
					_get_current_notes().append(note)
					live_held_notes[lane] = note
					_sort_current_notes()
					has_unsaved_changes = true
					if hitsound_enabled and hitsound_player.stream:
						hitsound_player.play()
	
	elif event is InputEventKey and not event.pressed and is_playing:
		var key_map := {KEY_D: 1, KEY_F: 2, KEY_J: 3, KEY_K: 4}
		if key_map.has(event.keycode):
			var lane: int = key_map[event.keycode]
			if live_held_notes.has(lane):
				var note: Dictionary = live_held_notes[lane]
				var raw_held: float = playhead_time - float(note["time"])
				var final_dur: float = maxf(0.0, _snap_time(playhead_time) - float(note["time"]))
				var min_key_sustain: float = (60.0 / maxf(1.0, bpm)) * 0.5
				
				# Só mantém sustain no teclado se segurou por pelo menos 1/2 beat real
				if raw_held >= min_key_sustain * 0.85 and final_dur >= min_key_sustain:
					note["duration"] = snappedf(final_dur, 0.001)
				else:
					note["duration"] = 0.0
				live_held_notes.erase(lane)

# ==============================================================================
# LÓGICA DE GRID, CONFLITOS, UNDO/REDO E SALVAMENTO
# ==============================================================================
func _get_beat_step() -> float:
	var full_beat := 60.0 / maxf(1.0, bpm)
	return full_beat / float(maxi(1, beat_divisor))

func _snap_time(t: float) -> float:
	var step := _get_beat_step()
	return maxf(0.0, round(t / step) * step)

func _step_timeline(dir: int) -> void:
	if is_playing:
		_stop_playback()
	var step := _get_beat_step()
	playhead_time = maxf(0.0, _snap_time(playhead_time) + dir * step)

func _find_note_near(lane: int, target_t: float, tolerance: float) -> Dictionary:
	for note in _get_current_notes():
		if int(note["lane"]) == lane:
			var nt := float(note["time"])
			var dur := float(note.get("duration", 0.0))
			if abs(nt - target_t) <= tolerance or (target_t >= nt and target_t <= nt + dur):
				return note
	return {}

func _has_note_conflict(lane: int, candidate_t: float, ignore_note: Dictionary, custom_min_dist: float = -1.0) -> bool:
	var min_dist := custom_min_dist if custom_min_dist > 0.0 else (_get_beat_step() * 0.45)
	for note in _get_current_notes():
		if note == ignore_note:
			continue
		if int(note["lane"]) == lane:
			if abs(float(note["time"]) - candidate_t) < min_dist:
				return true
	return false

func _get_current_notes() -> Array:
	return chart_data["tracks"][current_instrument]

func _sort_current_notes() -> void:
	_get_current_notes().sort_custom(func(a, b): return float(a["time"]) < float(b["time"]))

func _set_note_shape(shape: String) -> void:
	current_shape = shape
	# Se houver uma nota selecionada, converte o formato dela imediatamente!
	if not selected_note.is_empty() and str(selected_note.get("type", "c")) != shape:
		_push_undo_state()
		selected_note["type"] = shape
		has_unsaved_changes = true
		_set_status("Nota convertida para: %s" % ("PEDAL (sq)" if shape == "sq" else "CIRCULAR (c)"))
	_update_ui_states()

func _set_free_mode(enabled: bool) -> void:
	free_mode = enabled
	_update_ui_states()
	_set_status("Modo Livre ATIVO (arraste notas)" if free_mode else "Beat Lock ATIVO (criação travada no grid)")

func _switch_instrument(inst: String) -> void:
	current_instrument = inst
	selected_note = {}
	_update_ui_states()
	_set_status("Editando pista: %s" % inst.to_upper())

func _update_ui_states() -> void:
	if btn_shape_c:
		btn_shape_c.modulate = Color("#38bdf8") if current_shape == "c" else Color.WHITE
	if btn_shape_sq:
		btn_shape_sq.modulate = Color("#f59e0b") if current_shape == "sq" else Color.WHITE
	if btn_mode_lock:
		btn_mode_lock.modulate = Color("#4ade80") if not free_mode else Color.WHITE
	if btn_mode_free:
		btn_mode_free.modulate = Color("#f43f5e") if free_mode else Color.WHITE
	for inst in inst_buttons.keys():
		inst_buttons[inst].modulate = Color("#38bdf8") if inst == current_instrument else Color.WHITE

func _toggle_playback() -> void:
	if is_playing or countdown_remaining > 0.0:
		_stop_playback()
	else:
		if not song_player.stream:
			_set_status("Sem áudio carregado para reproduzir.")
			return
		countdown_remaining = 3.0
		btn_play.text = "✖ CANCELAR (3s)"
		if hitsound_player.stream:
			hitsound_player.play()

func _stop_playback() -> void:
	countdown_remaining = 0.0
	is_playing = false
	song_player.stop()
	if btn_play:
		btn_play.text = "▶ PLAY (ESPAÇO)"
	live_held_notes.clear()


func _push_undo_state() -> void:
	undo_stack.append(JSON.stringify(chart_data["tracks"]))
	if undo_stack.size() > 50:
		undo_stack.pop_front()
	redo_stack.clear()

func _undo() -> void:
	if undo_stack.size() <= 1:
		return
	var current_snapshot: String = undo_stack.pop_back()
	redo_stack.append(current_snapshot)
	var prev_snapshot: String = undo_stack[-1]
	chart_data["tracks"] = JSON.parse_string(prev_snapshot)
	selected_note = {}
	has_unsaved_changes = true
	_set_status("Undo aplicado.")

func _redo() -> void:
	if redo_stack.is_empty():
		return
	var next_snapshot: String = redo_stack.pop_back()
	undo_stack.append(next_snapshot)
	chart_data["tracks"] = JSON.parse_string(next_snapshot)
	selected_note = {}
	has_unsaved_changes = true
	_set_status("Redo aplicado.")


func _save_chart() -> void:
	for inst in INSTRUMENTS:
		chart_data["tracks"][inst].sort_custom(func(a, b): return float(a["time"]) < float(b["time"]))
	if beatmap_path != "":
		SoundtrackFS.save_json_dict(beatmap_path, chart_data)
		has_unsaved_changes = false
		_set_status("✔ Beatmap salvo com sucesso!")
	else:
		_set_status("Modo teste (sem arquivo vinculado).")

func _set_status(msg: String) -> void:
	if lbl_status:
		lbl_status.text = msg + "  "

func _on_back_pressed() -> void:
	_stop_playback()
	var main_node := get_tree().root.get_node_or_null("Main")
	var gallery_scene := load("res://scenes/chart_tool/song_gallery.tscn")
	if main_node and gallery_scene:
		var old_stage_id := main_node.get_child_count() - 1
		var stage: Node = gallery_scene.instantiate()
		main_node.add_child(stage)
		main_node.get_child(old_stage_id).queue_free()
	elif gallery_scene:
		get_tree().change_scene_to_file("res://scenes/chart_tool/song_gallery.tscn")

func _on_test_play_pressed() -> void:
	_stop_playback()
	_save_chart()
	if beatmap_path == "":
		_set_status("Salve o beatmap antes de jogar.")
		return

	Globals.instrumento_1 = current_instrument
	Globals.is_single_player = true
	Globals.set_meta("quickplay_chart_path", beatmap_path)
	Globals.set_meta("quickplay_audio_path", str(chart_data.get("audio_path", "")))
	Globals.set_meta("return_to_editor", true)

	var main_node := get_tree().root.get_node_or_null("Main")
	var play_scene := load("res://scenes/gameplay/play_map.tscn") as PackedScene
	if main_node and play_scene:
		var old_stage_id := main_node.get_child_count() - 1
		var stage: Node = play_scene.instantiate()
		main_node.add_child(stage)
		main_node.get_child(old_stage_id).queue_free()
	elif play_scene:
		get_tree().change_scene_to_file("res://scenes/gameplay/play_map.tscn")
