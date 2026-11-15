extends Node2D

@onready var button: Button = $Button

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#Transição
	$Transition.play() #Toca o audio da Transição
	
	#DELAY AO INICIAR A CENA
	get_viewport().gui_disable_input = true
	set_process_input(false)
	
	await get_tree().create_timer(0.65).timeout
	
	get_viewport().gui_disable_input = false
	set_process_input(true)
	#------------
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("customAction_player1_select") or Input.is_action_just_pressed("customAction_player1_select"):
		_on_button_pressed()


func _on_button_pressed() -> void:
	var stage_scene = load("res://scenes/telas/starter_menu.tscn")
	var main_node = get_tree().root.get_node_or_null("Main")
	if main_node and stage_scene:
		var old_stage_id = main_node.get_child_count() - 1
		var stage = stage_scene.instantiate()
		main_node.add_child(stage)
		main_node.get_child(old_stage_id).queue_free()
	else:
		print("Erro: Não conseguimos encontrar a cena.")
