## This is the basic Game node that holds declarations for 3 aspects that your game will need:
## 1. PLAYER_SCENE tells the framework what players to instantiate when setting up for multiple inputs
## 2. number_of_players is an automatically set variable that you can access to know how many
##    players exist in your game
## 3. the start(...) function gets run upon game start and sets up your players with inputs routed to them
##
## NOTE: This is an *abstract* class, meaning your game cannot directly inherit from this class
## Instead, look at game_2d.gd and game_3d.gd for classes to extend your game from!
@abstract class_name Game extends Node

## Your player scene!
@export_file("*.tscn") var PLAYER_SCENE : String

## Indicates the number of players in the game.
var number_of_players: int

## Sets up player inputs given a number of players. DO NOT CALL THIS FUNCTION ON YOUR OWN!!
@abstract func start(player_count: int, joined_players: Array[bool], zoom_matching: bool) -> void
