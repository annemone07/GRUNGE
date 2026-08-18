extends Area3D

@onready var square: MeshInstance3D = $square
@onready var circle: MeshInstance3D = $circle

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("space"):
		square.visible = !square.visible
		circle.visible = !circle.visible
		if square.visible:
			collision_mask = 2
		else:
			collision_mask = 1
