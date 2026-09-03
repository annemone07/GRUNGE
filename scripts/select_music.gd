extends Node3D

# Carrega a sua nova cena modular
const MUSIC_ITEM_SCENE = preload("res://scenes/music_sel.tscn")

@onready var vbox_container = $selectMusicScreen/HBoxContainer

func _ready() -> void:
	for child in vbox_container.get_children():
		child.queue_free()
		
	_populate_music_list()

func _populate_music_list() -> void:
	for m_id in Globals.music_database:
		var music_data = Globals.music_database[m_id]
		
		var item = MUSIC_ITEM_SCENE.instantiate()
		vbox_container.add_child(item)
		
		item.setup(m_id, music_data["title"], music_data["high_score"])
		item.music_selected.connect(_on_music_item_selected)
		
	if vbox_container.get_child_count() > 0:
		var primeiro_item = vbox_container.get_child(0)
		primeiro_item.btn_play.grab_focus()

func _on_music_item_selected(selected_id: String) -> void:
	Globals.selected_music = selected_id
	change_scene_to_instruments()

func change_scene_to_instruments() -> void:
	var stage_scene = load("res://scenes/select_instruments.tscn")
	var old_stage_id = get_tree().root.get_node("Main").get_child_count() - 1
	if stage_scene:
		var stage = stage_scene.instantiate()
		get_tree().root.get_node("Main").add_child(stage)
		get_tree().root.get_node("Main").get_child(old_stage_id).queue_free()
	else:
		print("Erro: Não conseguimos encontrar a cena.")
