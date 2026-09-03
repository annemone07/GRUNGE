extends Control # ou VBoxContainer, dependendo de qual você escolheu para a raiz

# Variável para sabermos se este seletor representa o Player 1 ou 2
var player_id: int = 1

# Ajuste os caminhos abaixo conforme a sua árvore de nós
@onready var label = $Control/Label 
@onready var btn_guitar = $Control/HBoxContainer/Guitar 
@onready var btn_bass = $Control/HBoxContainer/Bass 
@onready var btn_vocal = $Control/HBoxContainer/Vocal 
@onready var btn_drums = $Control/HBoxContainer/Drums 

func _ready():
	# Atualiza o texto visual (ex: de "Player x" para "Player 1")[cite: 1]
	label.text = "Player " + str(player_id)

	# Conecta os sinais dos instrumentos via código para economizar trabalho no Inspector[cite: 1]
	btn_guitar.pressed.connect(_on_instrument_selected.bind("guitar"))
	btn_bass.pressed.connect(_on_instrument_selected.bind("bass"))
	btn_vocal.pressed.connect(_on_instrument_selected.bind("vocal"))
	btn_drums.pressed.connect(_on_instrument_selected.bind("drums"))

	_update_visual_selection()

func _on_instrument_selected(instrument_name: String):
	# Atualiza o Globals correto dependendo de quem clicou
	if player_id == 1:
		Globals.instrumento_1 = instrument_name
	else:
		Globals.instrumento_2 = instrument_name

	_update_visual_selection()

func _update_visual_selection() -> void:
	# Descobre qual instrumento checar no Globals baseado no player_id
	var current_instrument = Globals.instrumento_1 if player_id == 1 else Globals.instrumento_2

	# Desabilita o botão do instrumento que já está selecionado[cite: 1]
	btn_guitar.disabled = (current_instrument == "guitar")
	btn_bass.disabled = (current_instrument == "bass")
	btn_vocal.disabled = (current_instrument == "vocal")
	btn_drums.disabled = (current_instrument == "drums")
