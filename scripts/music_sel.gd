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
