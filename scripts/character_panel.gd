extends VBoxContainer

var player_id: int = 1

@export var textureRectId=1
@onready var personagens = {
	"Locs":"bass",
	"Mago":"bass",
	"Emo":"guitar",
	"ET":"guitar",
	"Monkey":"drums",
	"Clown":"drums",
	"Robo":"vocal",
	"Nana":"vocal",
}
var boxId=0
var menuCards=[]
var menu_size=0

func _ready() -> void:
	for child in get_children():
		if child is GridContainer:
			menu_size=child.get_child_count()
			menuCards=child.get_children()
#	for card in $GridContainer.get_children():
#		var botao = card.get_node_or_null("Button")
#		if botao:
#			var nome = card.name.trim_suffix("_card")
#			
#			# Pega o instrumento configurado no card (ou define "guitar" como padrão)
#			var inst = "guitar"
#			if "instrumento_atribuido" in card:
#				inst = card.instrumento_atribuido
#			
#			# Conecta o botão passando o nome do personagem e o seu instrumento
#			botao.pressed.connect(_on_character_pressed.bind(nome, inst))

func _process(delta: float) -> void:
	print(boxId)
	for i in range(menu_size):
		if i == boxId:
			menuCards[i].get_child(textureRectId).modulate.a = 0.5
		else:
			menuCards[i].get_child(textureRectId).modulate.a = 1
	
	if Input.is_action_just_pressed("customAction_player"+str(player_id)+"_up"):
		boxId-=2
		if boxId<0:
			boxId=0
	elif Input.is_action_just_pressed("customAction_player"+str(player_id)+"_down"):
		boxId+=2
		if boxId>menu_size-1:
			boxId=menu_size-1
	elif Input.is_action_just_pressed("customAction_player"+str(player_id)+"_left"):
		boxId-=1
		if boxId<0:
			boxId=0
	elif Input.is_action_just_pressed("customAction_player"+str(player_id)+"_right"):
		boxId+=1
		if boxId>menu_size-1:
			boxId=menu_size-1
	elif Input.is_action_just_pressed("customAction_player"+str(player_id)+"_select"):
		_on_character_pressed(personagens.keys()[boxId], personagens.values()[boxId])

func _on_character_pressed(nome: String, instrumento: String) -> void:
	print("Player ", player_id, " escolheu o personagem: ", nome, " (Instrumento: ", instrumento, ")")
	
	if player_id == 1:
		Globals.personagem_1 = nome
		Globals.instrumento_1 = instrumento
	else:
		Globals.personagem_2 = nome
		Globals.instrumento_2 = instrumento
