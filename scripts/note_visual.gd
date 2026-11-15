extends Node3D

@onready var head: Node3D = $Head
@onready var tail: Node3D = $Tail
@onready var tail_mesh: MeshInstance3D = $Tail/note_test

const TRACK_COLORS: Dictionary = {
	1: Color("#22c55e"),
	2: Color("#ef4444"),
	3: Color("#eab308"),
	4: Color("#3b82f6"),
	5: Color("#f97316"),
	6: Color("#a855f7"),
	7: Color("#ec4899"),
	8: Color("#06b6d4"),
}

var speed: float = 10.0
var hold_duration: float = 0.0
var remaining_hold: float = 0.0
var is_holding: bool = false
var hold_dropped: bool = false
var is_missed: bool = false
var hitzone_z: float = 0.0
var despawn_z: float = 15.0
var is_square_note: bool = false
var active_head_mesh: MeshInstance3D = null

func _physics_process(delta: float) -> void:
	# Enquanto estiver segurando na hitzone, o update_sustain trava a posição Z
	if is_holding:
		return
	
	var current_speed: float = Globals.note_speed if "note_speed" in Globals else speed
	global_position.z += current_speed * delta
	
	# Só destrói a nota depois que a ponta final da cauda (tail) passar do limite da esteira
	var tail_length: float = maxf(0.0, remaining_hold * current_speed)
	if global_position.z - tail_length > despawn_z:
		queue_free()

func definir_cor_da_trilha(track_num: int, is_square: bool = false, duration: float = 0.0, note_speed: float = 10.0) -> void:
	is_square_note = is_square
	is_missed = false
	active_head_mesh = null
	
	for child in head.get_children():
		if child is Node3D:
			child.visible = false
	
	var target_name: String = ("sqr_cor" if is_square else "cor") + str(track_num)
	var target_mesh: Node = head.get_node_or_null(target_name)
	if target_mesh:
		target_mesh.visible = true
		if target_mesh is MeshInstance3D:
			active_head_mesh = target_mesh
	else:
		push_warning("Malha de nota não encontrada: " + target_name)

	var note_color: Color = TRACK_COLORS.get(track_num, Color.WHITE)
	if active_head_mesh:
		var mat: Material = active_head_mesh.get_active_material(0)
		if mat is StandardMaterial3D:
			note_color = mat.albedo_color

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
	_apply_dimmed_visual()

# Chamado quando a nota passa direto da hitzone sem ser acertada
func mark_as_missed() -> void:
	if is_missed:
		return
	is_missed = true
	is_holding = false
	_apply_dimmed_visual()

func _apply_dimmed_visual() -> void:
	# Escurece e aplica transparência na cabeça (se ainda estiver visível)
	if active_head_mesh and active_head_mesh.visible:
		var base_head_mat: Material = active_head_mesh.get_active_material(0)
		var dim_head_mat: StandardMaterial3D
		if base_head_mat is StandardMaterial3D:
			dim_head_mat = base_head_mat.duplicate() as StandardMaterial3D
		else:
			dim_head_mat = StandardMaterial3D.new()
		
		dim_head_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		dim_head_mat.albedo_color = dim_head_mat.albedo_color.darkened(0.5)
		dim_head_mat.albedo_color.a = 0.35
		active_head_mesh.set_surface_override_material(0, dim_head_mat)

	# Escurece e aplica transparência na cauda (se tiver sustain)
	if tail.visible:
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
