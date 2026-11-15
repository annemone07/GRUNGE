extends Area3D

var player_id: int = 1
var is_holding: bool = false

@onready var circulo_normal: Node3D = get_node_or_null("Circulo_normal")
@onready var circulo_levantado: Node3D = get_node_or_null("Circulo_levantado")
@onready var sqr_normal: Node3D = get_node_or_null("sqr_normal")
@onready var sqr_levantado: Node3D = get_node_or_null("sqr_levantado")

var escala_circulo: Vector3 = Vector3.ONE
var escala_sqr: Vector3 = Vector3.ONE

var hit_tween: Tween

func _ready() -> void:
	if circulo_levantado:
		escala_circulo = circulo_levantado.scale
		circulo_levantado.visible = false
	if sqr_levantado:
		escala_sqr = sqr_levantado.scale
		sqr_levantado.visible = false
	if circulo_normal:
		circulo_normal.visible = true
	if sqr_normal:
		sqr_normal.visible = false
	
	var root_track = get_tree().get_nodes_in_group("player_tracks")
	for track in root_track:
		if track.is_ancestor_of(self):
			player_id = track.player_id
			break

func _process(delta: float) -> void:
	var pedal_action = "customAction_player" + str(player_id) + "_pedal"
	
	if Input.is_action_just_pressed(pedal_action):
		if circulo_normal:
			circulo_normal.visible = !circulo_normal.visible
		if sqr_normal:
			sqr_normal.visible = !sqr_normal.visible
		
		if is_holding:
			if circulo_levantado and circulo_normal:
				circulo_levantado.visible = circulo_normal.visible
			if sqr_levantado and sqr_normal:
				sqr_levantado.visible = sqr_normal.visible
		else:
			if circulo_levantado:
				circulo_levantado.visible = false
			if sqr_levantado:
				sqr_levantado.visible = false

func animar_hit() -> void:
	var sprite_alvo: Node3D = null
	var escala_base: Vector3 = Vector3.ONE
	
	if circulo_normal and circulo_normal.visible:
		sprite_alvo = circulo_levantado
		escala_base = escala_circulo
	elif sqr_normal and sqr_normal.visible:
		sprite_alvo = sqr_levantado
		escala_base = escala_sqr
		
	if sprite_alvo:
		if hit_tween and hit_tween.is_running():
			hit_tween.kill()
		
		sprite_alvo.visible = true
		sprite_alvo.scale = escala_base
		
		hit_tween = create_tween()
		hit_tween.set_parallel(true)
		hit_tween.tween_property(sprite_alvo, "scale", escala_base * 1.05, 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

		if not is_holding:
			hit_tween.chain().tween_callback(func():
				sprite_alvo.visible = false
				sprite_alvo.scale = escala_base
			)

func set_holding(holding: bool) -> void:
	is_holding = holding
	
	if not is_holding:
		if hit_tween and hit_tween.is_running():
			hit_tween.kill()
		
		if circulo_levantado:
			circulo_levantado.visible = false
			circulo_levantado.scale = escala_circulo
		if sqr_levantado:
			sqr_levantado.visible = false
			sqr_levantado.scale = escala_sqr
