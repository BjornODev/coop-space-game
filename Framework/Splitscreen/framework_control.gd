# This node is in control of handling player viewports for games.
class_name FrameworkControl extends Control

# Temporary macOS mapping fix for the club's 8BitDo Ultimate 2C controllers.
# Standard controls work, but some extra buttons are mapped incorrectly.
# If controller compatibility becomes an issue, replace this with
# a more robust, platform-specific mapping system. (Easy I am just lazy)
#The on ready portion is on line 75 btw
const EIGHTBITDO_ULTIMATE_2C_MAC = "03003919c82d00001d30000001000000,8BitDo Ultimate 2C Wired Controller,a:b0,b:b1,y:b4,x:b3,start:b11,back:b10,leftstick:b13,rightstick:b14,leftshoulder:b6,rightshoulder:b7,dpup:b11,dpleft:b13,dpdown:b12,dpright:b14,leftx:a0,lefty:a1,rightx:a2,righty:a3,lefttrigger:a5,righttrigger:a4,platform:Mac OS X"

## Always 4, but I'd rather it be obvious when 4 shows up in code.
const MAX_PLAYER_COUNT = 4

@onready var grid_container: GridContainer = %"GridContainer" as GridContainer
@onready var player_view_p1: PlayerView = %"Player View P1" as PlayerView
@onready var player_view_p2: PlayerView = %"Player View P2" as PlayerView
@onready var player_view_p3: PlayerView = %"Player View P3" as PlayerView
@onready var player_view_p4: PlayerView = %"Player View P4" as PlayerView
@onready var player_viewport_containers: Array[PlayerView] = [
	player_view_p1,
	player_view_p2,
	player_view_p3,
	player_view_p4
]

## The game starts with this screen to connect players before starting.
const PLAYER_SELECT_SCREEN = preload("uid://d2he756o6q1d4")

## We should assign this to a base Node scene we create for them so they don't have to touch this part.
@export_file("*.tscn") var GAME_SCENE : String

## Determines the minimum number of players your game can have. Ranges from 1 to 4.
## This will likely be fetched from export settings on the developer's actual game in the future.
@export_range(1, 4, 1) var minimum_players: int = 1

## Determines the max number of players your game can have. Ranges from 1 to 4.
## This will likely be fetched from export settings on the developer's actual game in the future.
@export_range(1, 4, 1) var maximum_players: int = 4

## Allows players to connect to the game with WASD controls.
@export var allow_wasd: bool = true
## Allows players to connect to the game with arrow key controls.
@export var allow_arrow_keys: bool = true
## Allows players to connect to the game with a controller.
@export var allow_controller: bool = true

## If true, the game will load 3D cameras instead of 2D ones.
var in_3d: bool = false

## Set to false if you want all players to share the same screen.
@export var splitscreen: bool = true
## When true: screen is split by a | (vertically) when playing with 2 players.
## When false: screen is split by a - (horizontally) when playing with 2 players.
@export var vertical_2_player_splitscreen: bool = true
## Set to 0 to remove black lines between screens entirely, or increase if you want bigger lines between screens.
@export var splitscreen_line_thickness: int = 2
## If true, when playing a 2d splitscreen game, cameras will zoom out as the player count increases to prevent loss of visibility.
## If this makes your textures look weird, set to false instead.
@export var zoom_matching: bool = true

## Number of players. Used to set up splitscreen, and also passed into children.
var player_count: int = 4

## This becomes the player select scene once instantiated.
#var player_select: Node

## This becomes the instantiated game scene. Referenced for cameras.
# var world: Node

## Swaps between player_select and actual game world.
var player_select_screen : PlayerSelectScreen
var game_scene : Game

func _ready() -> void:
	#This is the other portion of the MACOS Controller Fix <:
	if OS.get_name() == "macOS":
		Input.add_joy_mapping(EIGHTBITDO_ULTIMATE_2C_MAC, true)
	# readies cameras, individually instead of a loop to prevent writing a setter that devs might accidentally use
	set_3d(in_3d)
	# modifies grid container to match splitscreen preferences
	grid_container.add_theme_constant_override("h_separation", splitscreen_line_thickness)
	grid_container.add_theme_constant_override("v_separation", splitscreen_line_thickness)
	start_player_select()

## Changes the cameras that the game uses. If true, sets the game to 3D and disables 2D cameras. If false, vice versa. This is useful if you want to load a 2D menu with no 3D elements in an otherwise 3D game.
func set_3d(now_in_3d: bool) -> void:
	in_3d = now_in_3d
	Cameras.P1 = player_view_p1.get_camera(in_3d)
	Cameras.P2 = player_view_p2.get_camera(in_3d)
	Cameras.P3 = player_view_p3.get_camera(in_3d)
	Cameras.P4 = player_view_p4.get_camera(in_3d)

## Modifies the number of viewports on screen to match the number of players. Also updates properties such as splitscreen, etc.
func update_player_view_count() -> void:
	# if you aren't playing in splitscreen, disable the rest of the viewports and doesn't do anything else
	if !splitscreen:
		grid_container.columns = 1
		for i in range(1, MAX_PLAYER_COUNT):
			player_viewport_containers[i].hide()
		return
	
	# if you ARE playing in splitscreen, starts by capping player count
	player_count = clampi(player_count, 1, MAX_PLAYER_COUNT)
	
	# then handles layout of viewports by modifying columns
	if player_count >= 2:
		if player_count == 2 and !vertical_2_player_splitscreen:
			grid_container.columns = 1
		else:
			grid_container.columns = 2
	else:
		grid_container.columns = 1
	
	# iterates through every other viewport and sets their world to the world of the primary viewport, indexed at 0
	if player_count > 1:
		for i in range(1, player_count):
			player_viewport_containers[i].set_viewport_world_2d(player_view_p1.get_viewport_world_2d())
			player_viewport_containers[i].set_viewport_world_3d(player_view_p1.get_viewport_world_3d())
	# every unused viewport should be deactivated
	for i in range(0, MAX_PLAYER_COUNT):
		if i >= player_count:
			player_viewport_containers[i].hide()
		else:
			player_viewport_containers[i].show()

## Starts up player select.
func start_player_select() -> void:
	player_count = 1
	
	if game_scene != null:
		game_scene.queue_free()
		await game_scene.tree_exited
	if player_select_screen != null:
		player_select_screen.queue_free()
		await player_select_screen.tree_exited
	
	player_select_screen = PLAYER_SELECT_SCREEN.instantiate() as PlayerSelectScreen
	player_select_screen.assign_framework_control(self)
	player_view_p1.add_game(player_select_screen)
	player_select_screen.player_select_screen_start(minimum_players, maximum_players, allow_wasd, allow_arrow_keys, allow_controller)
	update_player_view_count()

## Starts up actual game.
func start_game(new_player_count: int, joined_players: Array[bool], zoom_match: bool) -> void:
	player_count = new_player_count
	
	if game_scene != null:
		game_scene.queue_free()
		await game_scene.tree_exited
	if player_select_screen != null:
		player_select_screen.queue_free()
		await player_select_screen.tree_exited
	
	game_scene = (load(GAME_SCENE) as PackedScene).instantiate() as Game
	
	# checking for if the game is 2D or 3D here means the player won't have to set 
	# the in_3d var manually anymore!
	if game_scene is Game2D:
		set_3d(false)
	else:
		set_3d(true)
	
	player_view_p1.add_game(game_scene)
	# Game should have this method so we can give it player count.
	game_scene.start(player_count, joined_players, zoom_match)
	update_player_view_count()

## This method is purely for testing. Reduces player count by 1 every time it times out, then updates screens to match.
func _on_timer_timeout() -> void:
	@warning_ignore("narrowing_conversion")
	player_count = move_toward(player_count, 0, 1)
	update_player_view_count()
