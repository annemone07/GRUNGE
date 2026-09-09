extends VBoxContainer

var tween_movimento: Tween
var player_id: int = 1
var confirmado: bool = false

@export var ajuste_posicao: Vector2 = Vector2(0, 0)

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
var boxId = 0
var menuCards = []
var menu_size = 0

@onready var grid_container = $GridContainer
@onready var moldura = $Control/TextureRect2 # Pega a referência da moldura

func _ready() -> void:
	# Garantir que a moldura fique por cima de tudo
	$Control.z_index = 1 
	
	menu_size = grid_container.get_child_count()
	menuCards = grid_container.get_children()
	
	# Chama a atualização visual no primeiro frame para configurar o estado inicial
	# Usamos call_deferred para garantir que os nós estejam posicionados corretamente na tela
	call_deferred("_atualizar_visual")

func _process(delta: float) -> void:
	if confirmado:
		return
	var mudou_selecao = false
	
	if Input.is_action_just_pressed("customAction_player"+str(player_id)+"_up"):
		boxId -= 2
		mudou_selecao = true
	elif Input.is_action_just_pressed("customAction_player"+str(player_id)+"_down"):
		boxId += 2
		mudou_selecao = true
	elif Input.is_action_just_pressed("customAction_player"+str(player_id)+"_left"):
		boxId -= 1
		mudou_selecao = true
	elif Input.is_action_just_pressed("customAction_player"+str(player_id)+"_right"):
		boxId += 1
		mudou_selecao = true
		
	# Limita o cursor
	if boxId < 0:
		boxId = 0
	elif boxId > menu_size - 1:
		boxId = menu_size - 1
		
	# Só atualiza a tela se o jogador moveu o cursor
	if mudou_selecao:
		_atualizar_visual()
		
	if Input.is_action_just_pressed("customAction_player"+str(player_id)+"_select"):
		_on_character_pressed(personagens.keys()[boxId], personagens.values()[boxId])


func _atualizar_visual() -> void:
	# 1. Atualizar as texturas dos cards (mantém igual)
	for i in range(menu_size):
		var card = menuCards[i]
		var esta_selecionado = (i == boxId)
		if card.has_method("atualizar_selecao"):
			card.atualizar_selecao(esta_selecionado)
	
	# 2. Mover a moldura COM TWEEN (animação suave)
	var card_atual = menuCards[boxId]
	var offset_x = (moldura.size.x - card_atual.size.x) / 2.0
	var offset_y = (moldura.size.y - card_atual.size.y) / 2.0
	
	var posicao_alvo = card_atual.global_position - Vector2(offset_x, offset_y) + ajuste_posicao
	
	# Mata a animação anterior se ela ainda estiver rodando
	if tween_movimento:
		tween_movimento.kill()
		
	# Cria uma nova animação de 0.15 segundos com curva de aceleração
	tween_movimento = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween_movimento.tween_property(moldura, "global_position", posicao_alvo, 0.15)


func _on_character_pressed(nome: String, instrumento: String) -> void:
	confirmado = true
	moldura.modulate = Color(0.2, 1.0, 0.2)
	print("Player ", player_id, " escolheu o personagem: ", nome, " (Instrumento: ", instrumento, ")")
	
	if player_id == 1:
		Globals.personagem_1 = nome
		Globals.instrumento_1 = instrumento
	else:
		Globals.personagem_2 = nome
		Globals.instrumento_2 = instrumento
