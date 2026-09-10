extends Node2D
@onready var music_slider: HSlider = $Control3/controlBotoes/music_slider
@onready var master_slider: HSlider = $Control3/controlBotoes/master_slider

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	music_slider.value = Globals.volume_music
	master_slider.value = Globals.volume_master
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_music_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(Globals.musica_bus, linear_to_db(value))
	Globals.volume_music = value


func _on_master_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(Globals.master_bus, linear_to_db(value))
	Globals.volume_master = value


func _on_button_pressed() -> void:
	var stage_scene = load("res://scenes/StarterMenu.tscn")
	var old_stage_id = get_tree().root.get_node("Main").get_child_count()-1
	if stage_scene:
		var stage = stage_scene.instantiate()
		get_tree().root.get_node("Main").add_child(stage)
		get_tree().root.get_node("Main").get_child(old_stage_id).queue_free()
	else:
		print("Erro: Não conseguimos encontrar a cena.")


func _on_controles_pressed() -> void:
	var stage_scene = load("res://scenes/controles.tscn")
	var old_stage_id = get_tree().root.get_node("Main").get_child_count()-1
	if stage_scene:
		var stage = stage_scene.instantiate()
		get_tree().root.get_node("Main").add_child(stage)
		get_tree().root.get_node("Main").get_child(old_stage_id).queue_free()
	else:
		print("Erro: Não conseguimos encontrar a cena.")
