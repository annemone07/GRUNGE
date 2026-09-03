extends HBoxContainer

signal music_selected(music_id: String)

@onready var btn_play: Button = $BtnPlay
@onready var lbl_score: Label = $LblScore

var music_id: String = ""

# --- Variáveis para o Efeito de Letreiro ---
var texto_original: String = ""
var texto_letreiro: String = ""
var rolando_texto: bool = false
var tempo_scroll: float = 0.0
var velocidade_scroll: float = 0.15 # Tempo em segundos para a letra andar
var limite_caracteres: int = 18 # Quantidade de letras que cabem no botão

func _ready() -> void:
	# Trava o tamanho do botão e impede que o texto vaze
	btn_play.custom_minimum_size = Vector2(220, 30)
	btn_play.clip_text = true
	
	btn_play.pressed.connect(_on_btn_play_pressed)
	btn_play.pivot_offset = btn_play.size / 2
	
	btn_play.focus_entered.connect(_on_focus_entered)
	btn_play.focus_exited.connect(_on_focus_exited)
	btn_play.mouse_entered.connect(btn_play.grab_focus)
	
	_aplicar_estilo_normal()

func setup(id: String, title: String, high_score: int) -> void:
	music_id = id
	lbl_score.text = str(high_score)
	
	texto_original = title
	
	# Prepara a string do letreiro com um espaço no final para o loop ficar suave
	if texto_original.length() > limite_caracteres:
		texto_letreiro = texto_original + "   ***   "
	else:
		texto_letreiro = texto_original
		
	btn_play.text = texto_original

# A mágica do texto rodando acontece aqui todo frame
func _process(delta: float) -> void:
	if rolando_texto and texto_original.length() > limite_caracteres:
		tempo_scroll += delta
		if tempo_scroll >= velocidade_scroll:
			tempo_scroll = 0.0
			texto_letreiro = texto_letreiro.substr(1) + texto_letreiro[0]
			btn_play.text = texto_letreiro

func _on_btn_play_pressed() -> void:
	music_selected.emit(music_id)

func _on_focus_entered() -> void:
	btn_play.pivot_offset = btn_play.size / 2
	
	var tween = create_tween()
	tween.tween_property(btn_play, "scale", Vector2(1.1, 1.1), 0.15).set_trans(Tween.TRANS_SINE)
	
	_aplicar_estilo_focado()
	
	# Liga o efeito de letreiro
	rolando_texto = true
	tempo_scroll = 0.0

func _on_focus_exited() -> void:
	var tween = create_tween()
	tween.tween_property(btn_play, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_SINE)
	
	_aplicar_estilo_normal()
	
	# Desliga o letreiro e reseta o texto para o normal
	rolando_texto = false
	btn_play.text = texto_original

func _aplicar_estilo_normal() -> void:
	var estilo = StyleBoxEmpty.new()
	btn_play.add_theme_stylebox_override("normal", estilo)
	btn_play.add_theme_stylebox_override("hover", estilo)
	btn_play.add_theme_stylebox_override("focus", estilo)
	btn_play.add_theme_color_override("font_color", Color.WHITE)

func _aplicar_estilo_focado() -> void:
	var estilo = StyleBoxFlat.new()
	estilo.bg_color = Color(0, 0, 0, 1)
	estilo.corner_radius_top_left = 12
	estilo.corner_radius_top_right = 12
	estilo.corner_radius_bottom_left = 12
	estilo.corner_radius_bottom_right = 12
	
	estilo.expand_margin_left = 10
	estilo.expand_margin_right = 10
	estilo.expand_margin_top = 5
	estilo.expand_margin_bottom = 5
	
	btn_play.add_theme_stylebox_override("normal", estilo)
	btn_play.add_theme_stylebox_override("hover", estilo)
	btn_play.add_theme_stylebox_override("focus", estilo)
	btn_play.add_theme_color_override("font_color", Color.WHITE)
