extends Node2D

@onready var grabber: CharacterBody2D = $Grabber

func set_player_number(player_num : int) -> void:
	grabber.player_number = player_num
