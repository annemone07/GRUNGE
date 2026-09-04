extends VBoxContainer

var player=0

@onready var boxId=0
@onready var menu_items = get_children()
@onready var menu_size = get_child_count()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	for i in range(get_child_count()):
		if i == boxId:
			get_child(i).flat = true
		else:
			get_child(i).flat = false
	
	if Input.is_action_just_pressed("customAction_player"+str(player)+"_up"):
		boxId-=1
		if boxId<0:
			boxId=0
	elif Input.is_action_just_pressed("customAction_player"+str(player)+"_down"):
		boxId+=1
		if boxId>menu_size-1:
			boxId=menu_size-1
	elif Input.is_action_just_pressed("customAction_player"+str(player)+"_select"):
		menu_items[boxId]._pressed()
