extends VBoxContainer

var player_id: int = 1

func _ready() -> void:
	for card in $GridContainer.get_children():
		var botao = card.get_node_or_null("Button")
		if botao:
			var nome = card.name.trim_suffix("_card")
			
			# Pega o instrumento configurado no card (ou define "guitar" como padrão)
			var inst = "guitar"
			if "instrumento_atribuido" in card:
				inst = card.instrumento_atribuido
			
			# Conecta o botão passando o nome do personagem e o seu instrumento
			botao.pressed.connect(_on_character_pressed.bind(nome, inst))

func _on_character_pressed(nome: String, instrumento: String) -> void:
	print("Player ", player_id, " escolheu o personagem: ", nome, " (Instrumento: ", instrumento, ")")
	
	if player_id == 1:
		Globals.personagem_1 = nome
		Globals.instrumento_1 = instrumento
	else:
		Globals.personagem_2 = nome
		Globals.instrumento_2 = instrumento
