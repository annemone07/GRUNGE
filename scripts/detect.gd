extends Area3D

@onready var circulo_normal: Node3D = $Circulo_normal
@onready var circulo_levantado: Node3D = $Circulo_levantado
@onready var sqr_normal: Node3D = $sqr_normal
@onready var sqr_levantado: Node3D = $sqr_levantado

func _ready() -> void:
	circulo_normal.visible = true
	sqr_normal.visible = false
	circulo_levantado.visible = false
	sqr_levantado.visible = false

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pedal"):
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
		sprite_alvo.visible = true
		sprite_alvo.scale = Vector3(1.0, 1.0, 1.0)
		
		var tween = create_tween()
		tween.set_parallel(true)
		
		tween.tween_property(sprite_alvo, "scale", Vector3(1.1, 1.1, 1.1), 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

		tween.chain().tween_callback(func(): sprite_alvo.visible = false)
		
