extends Node2D

@onready var control_terminal: TerminalPort = $ControlTerminal
@onready var sorting_minigame: Node2D = $SubViewportContainer/SubViewport/SortingMinigame

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	control_terminal.connect("player_playing",toggle_minigame)

func toggle_minigame(player_num : int) -> void:
	# if player is playing, passes player number and starts
	# otherwise if 0, then stops the game
	sorting_minigame.set_player_number(player_num)
