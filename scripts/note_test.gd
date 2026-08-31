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

# NOVA FUNÇÃO: Controla a visibilidade dos nós filhos da nota
func definir_cor_da_trilha(track_num: int) -> void:
	# 1. Varre e esconde todos os sprites de cor (1 ao 8) para limpar a nota
	for i in range(1, 9):
		var cor_normal = find_child("cor" + str(i), true, false)
		if cor_normal: 
			cor_normal.visible = false
			
		var cor_quadrada = find_child("sqr_cor" + str(i), true, false)
		if cor_quadrada: 
			cor_quadrada.visible = false
			
	# 2. Descobre se esta instância é a nota quadrada (olhando o nome do arquivo)
	var is_square = scene_file_path.contains("sq") or str(name).contains("sq")
	
	# 3. Liga a visibilidade APENAS do modelo correspondente à trilha atual
	if is_square:
		var cor_certa = find_child("sqr_cor" + str(track_num), true, false)
		if cor_certa: 
			cor_certa.visible = true
	else:
		var cor_certa = find_child("cor" + str(track_num), true, false)
		if cor_certa: 
			cor_certa.visible = true
