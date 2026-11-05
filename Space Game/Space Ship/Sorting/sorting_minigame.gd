extends Node2D

@onready var grabber: CharacterBody2D = $Grabber
@onready var suction_trash: TerminalPort = $SuctionTrash
@onready var suction_to_refining: TerminalPort = $SuctionToRefining
@onready var item_spawn_area: Node2D = $ItemSpawnArea

func set_player_number(player_num : int) -> void:
	grabber.player_number = player_num
