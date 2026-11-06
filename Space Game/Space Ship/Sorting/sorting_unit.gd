extends Node2D

@onready var control_terminal: TerminalPort = $ControlTerminal
@onready var sorting_minigame: Node2D = $SubViewportContainer/SubViewport/SortingMinigame

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	control_terminal.connect("player_playing",toggle_minigame)
	
	var suction_trash : TerminalPort = sorting_minigame.suction_trash
	suction_trash.connect("suction_tube_entered",send_item_to_trash)
	
func toggle_minigame(player_num : int) -> void:
	# if player is playing, passes player number and starts
	# otherwise if 0, then stops the game
	sorting_minigame.set_player_number(player_num)

func send_item_to_trash(_item : Dictionary) -> void:
	pass 

func send_item_to_spawn_area(item : Dictionary) -> void:
	sorting_minigame.item_spawn_area.spawn_ore(item)
