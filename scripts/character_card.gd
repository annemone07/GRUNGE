extends Control

@export var nome_personagem: String = "Mago"
@export var instrumento_atribuido: String = "guitar"

@export var textura_selecionada: Texture2D
@export var textura_nao_selecionada: Texture2D

@onready var texture_rect: TextureRect = $TextureRect

var tween_animacao: Tween
var particulas: CPUParticles2D

func _ready() -> void:
	if textura_nao_selecionada:
		texture_rect.texture = textura_nao_selecionada
		
	# Mantém o pivô para o zoomzinho funcionar certinho a partir do centro
	texture_rect.pivot_offset = Vector2(45, 63)
	
	# Cria o efeito visual direto pelo código
	_criar_particulas()

# Função que gera as partículas 100% via código
func _criar_particulas() -> void:
	particulas = CPUParticles2D.new()
	particulas.emitting = false # Começa desligado
	particulas.amount = 15      # Quantidade de faíscas
	particulas.lifetime = 0.8   # Tempo que a faísca dura (segundos)
	
	# Define a área de onde as partículas saem (base do card)
	particulas.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particulas.emission_rect_extents = Vector2(40, 10) 
	particulas.position = Vector2(45, 110) # Posição perto do rodapé do card
	
	# Faz as partículas subirem
	particulas.direction = Vector2(0, -1)
	particulas.gravity = Vector2(0, -30) # Puxa levemente pra cima
	particulas.initial_velocity_min = 10.0
	particulas.initial_velocity_max = 30.0
	
	# Tamanho dos quadradinhos brilhantes
	particulas.scale_amount_min = 3.0
	particulas.scale_amount_max = 6.0
	
	# Cria um gradiente via código (Nasce Amarelo Forte -> Morre Transparente)
	var gradiente = Gradient.new()
	gradiente.set_color(0, Color(1.0, 0.9, 0.4, 1.0)) 
	gradiente.set_color(1, Color(1.0, 0.7, 0.1, 0.0)) 
	particulas.color_ramp = gradiente
	
	# Adiciona o nó na cena e joga pra trás do card (pra não ficar por cima do desenho)
	add_child(particulas)
	move_child(particulas, 0)

func atualizar_selecao(esta_selecionado: bool) -> void:
	if tween_animacao and tween_animacao.is_valid():
		tween_animacao.kill()
		
	tween_animacao = create_tween()
	
	if esta_selecionado:
		if textura_selecionada:
			texture_rect.texture = textura_selecionada
			
		# Dá o zoomzinho
		tween_animacao.tween_property(texture_rect, "scale", Vector2(1.08, 1.08), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		
		# Liga as partículas
		particulas.emitting = true
			
	else:
		if textura_nao_selecionada:
			texture_rect.texture = textura_nao_selecionada
			
		# Tira o zoom
		tween_animacao.tween_property(texture_rect, "scale", Vector2(1, 1), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		
		# Desliga as partículas
		particulas.emitting = false
