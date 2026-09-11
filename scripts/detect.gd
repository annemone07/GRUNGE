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

func animar_hit() -> void:
	var sprite_alvo = null
	
	if circulo_normal.visible:
		sprite_alvo = circulo_levantado
	elif sqr_normal.visible:
		sprite_alvo = sqr_levantado
		
	if sprite_alvo:
		# Se já houver uma animação rodando, interrompe antes de começar outra
		if hit_tween and hit_tween.is_running():
			hit_tween.kill()
		
		sprite_alvo.visible = true
		sprite_alvo.scale = Vector3.ONE
		
		hit_tween = create_tween()
		hit_tween.set_parallel(true)
		
		hit_tween.tween_property(sprite_alvo, "scale", Vector3(1.1, 1.1, 1.1), 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

		hit_tween.chain().tween_callback(func():
			sprite_alvo.visible = false
			sprite_alvo.scale = Vector3.ONE # Garante o resete da escala ao esconder
		)
