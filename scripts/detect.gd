extends Area3D

var player_id: int = 1

@onready var circulo_normal: Node3D = $Circulo_normal
@onready var circulo_levantado: Node3D = $Circulo_levantado
@onready var sqr_normal: Node3D = $sqr_normal
@onready var sqr_levantado: Node3D = $sqr_levantado

var hit_tween: Tween # Armazena a referência do Tween ativo

func _ready() -> void:
	circulo_normal.visible = true
	sqr_normal.visible = false
	circulo_levantado.visible = false
	sqr_levantado.visible = false
	
	var root_track = get_tree().get_nodes_in_group("player_tracks")
	for track in root_track:
		if track.is_ancestor_of(self):
			player_id = track.player_id
			break

func _process(delta: float) -> void:
	var pedal_action = "customAction_player" + str(player_id) + "_pedal"
	
	if Input.is_action_just_pressed(pedal_action):
		circulo_normal.visible = !circulo_normal.visible
		sqr_normal.visible = !sqr_normal.visible
		circulo_levantado.visible = false
		sqr_levantado.visible = false

# Guarde as escalas originais definidas no Inspetor
@onready var escala_circulo: Vector3 = circulo_levantado.scale
@onready var escala_sqr: Vector3 = sqr_levantado.scale

func animar_hit() -> void:
	var sprite_alvo = null
	var escala_base = Vector3.ONE
	
	if circulo_normal.visible:
		sprite_alvo = circulo_levantado
		escala_base = escala_circulo
	elif sqr_normal.visible:
		sprite_alvo = sqr_levantado
		escala_base = escala_sqr
		
	if sprite_alvo:
		if hit_tween and hit_tween.is_running():
			hit_tween.kill()
		
		sprite_alvo.visible = true
		sprite_alvo.scale = escala_base
		
		hit_tween = create_tween()
		hit_tween.set_parallel(true)
		
		# Multiplica a escala original por 1.05 (aumenta 5% do tamanho real dela)
		hit_tween.tween_property(sprite_alvo, "scale", escala_base * 1.05, 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

		hit_tween.chain().tween_callback(func():
			sprite_alvo.visible = false
			sprite_alvo.scale = escala_base
		)
