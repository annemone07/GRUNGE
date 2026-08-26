extends Area3D

@export var speed: float = 15.0 

@export var miss_z_limit: float = 3.0 

func _ready() -> void:
	speed = Globals.note_speed
	if not is_in_group("notes"):
		add_to_group("notes")

func _physics_process(delta: float) -> void:
	global_position.z += speed * delta

	if global_position.z > miss_z_limit:
		_trigger_auto_miss()

func _trigger_auto_miss() -> void:
	Globals.combo = 0

	if "current_life" in Globals:
		Globals.current_life -= 5.0
		queue_free()
