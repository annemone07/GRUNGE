extends Node2D
@onready var placeholder_amp: Sprite2D = $PlaceholderAmp

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_start_button_pressed() -> void:
	var stage_scene = load("res://scenes/selectMusic.tscn")
	var old_stage_id = get_tree().root.get_node("Main").get_child_count()-1
	if stage_scene:
		var stage = stage_scene.instantiate()
		get_tree().root.get_node("Main").add_child(stage)
		get_tree().root.get_node("Main").get_child(old_stage_id).queue_free()
	else:
		print("Erro: Não conseguimos encontrar a cena.")


@onready var menu_container: VBoxContainer = $menuContainer
@onready var settings_container: Panel = $settingsContainer
@onready var highscores_container: Panel = $highscoresContainer
@onready var credits_container: Panel = $creditsContainer

func _on_settings_button_pressed() -> void:
	var stage_scene = load("res://scenes/settings.tscn")
	var old_stage_id = get_tree().root.get_node("Main").get_child_count()-1
	if stage_scene:
		var stage = stage_scene.instantiate()
		get_tree().root.get_node("Main").add_child(stage)
		get_tree().root.get_node("Main").get_child(old_stage_id).queue_free()
	else:
		print("Erro: Não conseguimos encontrar a cena.")
	#menu_container.visible = false
	#settings_container.visible = true

func _on_highscores_button_pressed() -> void:
	menu_container.visible = false
	highscores_container.visible = true

func _on_credits_button_pressed() -> void:
	menu_container.visible = false
	credits_container.visible = true

func _on_exit_button_pressed() -> void:
	get_tree().quit()


func _on_back_button_pressed() -> void:
	settings_container.visible = false
	highscores_container.visible = false
	credits_container.visible = false
	menu_container.visible = true
