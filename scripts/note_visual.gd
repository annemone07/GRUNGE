extends Node3D

@onready var head: Node3D = $Head
@onready var tail: Node3D = $Tail
@onready var tail_mesh: MeshInstance3D = $Tail/note_test

# Cores padrão de cada trilha (1 a 8) caso o mesh não tenha StandardMaterial3D
const TRACK_COLORS: Dictionary = {
	1: Color("#22c55e"), # Verde
	2: Color("#ef4444"), # Vermelho
	3: Color("#eab308"), # Amarelo
	4: Color("#3b82f6"), # Azul
	5: Color("#f97316"), # Laranja
	6: Color("#a855f7"), # Roxo
	7: Color("#ec4899"), # Rosa
	8: Color("#06b6d4"), # Ciano
}

var speed: float = 10.0
var hold_duration: float = 0.0
var remaining_hold: float = 0.0
var is_holding: bool = false
var hold_dropped: bool = false
var hitzone_z: float = 0.0
var is_square_note: bool = false

func _physics_process(delta: float) -> void:
	# Se estiver segurando o sustain na hitzone, não avança no Z
	if is_holding:
		return
	
	var current_speed: float = Globals.note_speed if "note_speed" in Globals else speed
	global_position.z += current_speed * delta

func definir_cor_da_trilha(track_num: int, is_square: bool = false, duration: float = 0.0, note_speed: float = 10.0) -> void:
	is_square_note = is_square
	
	# 1. Esconde todas as malhas dentro de Head e ativa só a certa
	for child in head.get_children():
		if child is Node3D:
			child.visible = false
	
	var target_name: String = ("sqr_cor" if is_square else "cor") + str(track_num)
	var target_mesh: Node = head.get_node_or_null(target_name)
	if target_mesh:
		target_mesh.visible = true
	else:
		push_warning("Malha de nota não encontrada: " + target_name)

	# 2. Pega a cor da trilha a partir do material do mesh ativo (ou fallback do dicionário)
	var note_color: Color = TRACK_COLORS.get(track_num, Color.WHITE)
	if target_mesh is MeshInstance3D:
		var mat: Material = target_mesh.get_active_material(0)
		if mat is StandardMaterial3D:
			note_color = mat.albedo_color

	# 3. Configura o Tail (sustain)
	setup_tail(duration, note_speed, note_color)

func setup_tail(duration: float, note_speed: float, note_color: Color) -> void:
	hold_duration = duration
	remaining_hold = duration
	speed = note_speed
	
	is_holding = false
	hold_dropped = false
	head.visible = true

	if hold_duration <= 0.0:
		tail.visible = false
		return

	tail.visible = true
	tail.scale.z = hold_duration * speed

	var base_mat: Material = tail_mesh.get_active_material(0)
	var unique_mat: StandardMaterial3D
	
	if base_mat is StandardMaterial3D:
		unique_mat = base_mat.duplicate() as StandardMaterial3D
	else:
		unique_mat = StandardMaterial3D.new()
		unique_mat.roughness = 0.4
		unique_mat.metallic = 0.2

	unique_mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	unique_mat.albedo_color = note_color
	tail_mesh.set_surface_override_material(0, unique_mat)

func start_hold(target_hitzone_z: float) -> void:
	if hold_duration <= 0.0:
		queue_free()
		return

	is_holding = true
	hitzone_z = target_hitzone_z
	global_position.z = hitzone_z
	head.visible = false

func release_hold() -> void:
	if not is_holding:
		return

	if remaining_hold <= 0.1:
		queue_free()
		return

	is_holding = false
	hold_dropped = true

	var mat: StandardMaterial3D = tail_mesh.get_surface_override_material(0) as StandardMaterial3D
	if mat:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = mat.albedo_color.darkened(0.5)
		mat.albedo_color.a = 0.35

func update_sustain(delta: float) -> bool:
	if not is_holding:
		return false

	global_position.z = hitzone_z
	remaining_hold -= delta
	tail.scale.z = maxf(0.0, remaining_hold * speed)

	if remaining_hold <= 0.0:
		queue_free()
		return false

	return true
