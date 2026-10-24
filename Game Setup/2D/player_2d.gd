## Extend off of this class to set up a 2D player controller for your game!
## If you decide to make your own player control (ex: extended off of RigidBody2D), 
## copy/paste the functions from this code into your script!
##
## The camera param will be the camera that follows your player and shows the player
## what's around it!
## 
## player_number tells you which player this is!
class_name Player2D extends CharacterBody2D

## The camera parented to this player
var camera: Camera2D

## Denotes which player controls this character [1-4]
var player_number: int = 1


## Function used by the framework to set the player number
func set_player_num(player_num: int) -> void:
	player_number = player_num


## Function used by the framework to set the camera
func set_camera(new_camera: Camera2D) -> void:
	camera = new_camera
