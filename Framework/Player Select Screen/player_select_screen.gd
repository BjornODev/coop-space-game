class_name PlayerSelectScreen extends Node2D

@onready var anim : AnimationPlayer = $"AnimationPlayer" as AnimationPlayer
@onready var start_game_button: StartGameButton = %"Start Game" as StartGameButton

@onready var player_input_card_1: PlayerInputCard = %"Player Input Card" as PlayerInputCard
@onready var player_input_card_2: PlayerInputCard = %"Player Input Card2" as PlayerInputCard
@onready var player_input_card_3: PlayerInputCard = %"Player Input Card3" as PlayerInputCard
@onready var player_input_card_4: PlayerInputCard = %"Player Input Card4" as PlayerInputCard

@onready var player_input_cards: Array[PlayerInputCard] = [
	player_input_card_1,
	player_input_card_2,
	player_input_card_3,
	player_input_card_4
]

@onready var player_cursor_1: PlayerCursor = $"CanvasLayer/Player Cursor 1" as PlayerCursor
@onready var player_cursor_2: PlayerCursor = $"CanvasLayer/Player Cursor 2" as PlayerCursor
@onready var player_cursor_3: PlayerCursor = $"CanvasLayer/Player Cursor 3" as PlayerCursor
@onready var player_cursor_4: PlayerCursor = $"CanvasLayer/Player Cursor 4" as PlayerCursor

@onready var player_cursors: Array[CharacterBody2D] = [
	player_cursor_1,
	player_cursor_2,
	player_cursor_3,
	player_cursor_4
]

## When true, prevents a player from joining on the given frame. Prevents disconnect button from instantly causing player to rejoin.
var just_removed_player: bool = false

## Always 4.
const MAX_PLAYER_COUNT: int = 4

## Holds all possible control types. At the start of the project, the allowed controls are added.
var allowed_control_types: Array[String] = []

## Stores controls currently being used to prevent multiple players from joining with the same input controller.
var currently_used_controls: Array[String] = ["", "", "", ""]

## Used to determine which player to add new inputs to.
var player_count : int = 0

## Determines the minimum number of players your game can have. Ranges from 1 to 4.
var minimum_players: int = 1
#@export_range(1, 4, 1) var minimum_players: int = 1

## Determines the max number of players your game can have. Ranges from 1 to 4.
## This will likely be fetched from export settings on the developer's actual game in the future.
var maximum_players: int = 4
#@export_range(1, 4, 1) var maximum_players: int = 4

## Allows players to connect to the game with WASD controls.
var allow_wasd: bool = true
#@export var allow_wasd: bool = true
## Allows players to connect to the game with arrow key controls.
var allow_arrow_keys: bool = true
#@export var allow_arrow_keys: bool = true
## Allows players to connect to the game with a controller.
var allow_controller: bool = true
#@export var allow_controller: bool = true

## I am resisting the urge to get_parent().get_parent().get_parent().get_parent().
## Referenced when starting up the actual game.
var framework_control: FrameworkControl

## Little animation variable.
var instructions_visible = true

func player_select_screen_start(min_players: int, max_players: int, wasd: bool, arrow_keys: bool, controller: bool) -> void:
	minimum_players = min_players
	maximum_players = max_players
	allow_wasd = wasd
	allow_arrow_keys = arrow_keys
	allow_controller = controller
	anim.play("show_prompt")
	
	# gray-out all players that COULD join, but don't have to join. Colors in the rest.
	for i in range(0, MAX_PLAYER_COUNT):
		# also makes sure controller hints work
		player_input_cards[i].set_valid_controls(allow_wasd, allow_arrow_keys, allow_controller)
		if i < minimum_players:
			player_input_cards[i].set_needs_to_exist_to_play_game(true)
		else:
			player_input_cards[i].set_needs_to_exist_to_play_game(false)
		player_input_cards[i].disconnect_control_type()
		player_input_cards[i].set_player_select_screen(self)
	
	# hide all players that can never join
	for i in range(0, MAX_PLAYER_COUNT):
		if i >= maximum_players:
			player_input_cards[i].hide()
		else:
			player_input_cards[i].show()
	
	# set-up for allowed controls
	if allow_wasd:
		allowed_control_types.append("keyboard_wasd")
	if allow_arrow_keys:
		allowed_control_types.append("keyboard_arrow_keys")
	if allow_controller:
		allowed_control_types.append("controller_1")
		allowed_control_types.append("controller_2")
		allowed_control_types.append("controller_3")
		allowed_control_types.append("controller_4")

func _process(_delta: float) -> void:
	# the reason we can't use a "keyboard_join" input is because control sticks ignore negative inputs when you do this. Don't know why. 
	if !just_removed_player:
		if Input.is_action_just_pressed("keyboard_wasd_join"):
			add_new_player("keyboard_wasd")
		if Input.is_action_just_pressed("keyboard_arrow_keys_join"):
			add_new_player("keyboard_arrow_keys")
		if (Input.is_action_just_pressed("controller_1_join") or Input.is_action_just_pressed("controller_1_join_alt")):
			add_new_player("controller_1")
		if (Input.is_action_just_pressed("controller_2_join") or Input.is_action_just_pressed("controller_2_join_alt")):
			add_new_player("controller_2")
		if (Input.is_action_just_pressed("controller_3_join") or Input.is_action_just_pressed("controller_3_join_alt")):
			add_new_player("controller_3")
		if (Input.is_action_just_pressed("controller_4_join") or Input.is_action_just_pressed("controller_4_join_alt")):
			add_new_player("controller_4")
	else:
		just_removed_player = false

## Assigns the node that will be called to start the game once the game starts.
func assign_framework_control(parent_parent_parent_parent: FrameworkControl) -> void:
	framework_control = parent_parent_parent_parent

## TRIES to add a new player with the given control scheme. Can fail.
func add_new_player(control_name: String) -> void:
	# fails if controls are already being used
	if currently_used_controls.has(control_name): return
	# also fails if controls are not in the allowed list
	if !allowed_control_types.has(control_name): return
	# prevents player count from exceeding max players and causing major issues
	if player_count >= maximum_players: return
	# otherwise, add the player! :D
	var player_num: int = currently_used_controls.find("") + 1
	player_input_cards[player_num - 1].connect_control_type(control_name)
	currently_used_controls[player_num - 1] = control_name
	player_count += 1
	CoopInput.get_player(player_num)._assign_inputs(control_name)
	
	# activates corresponding cursor
	(player_cursors[player_num - 1] as PlayerCursor).activate(player_input_cards[player_num - 1].global_position)
	
	# cosmetic anim
	if instructions_visible:
		instructions_visible = false
		anim.stop(true)
		anim.play("hide_prompt")
	
	# enable/disable start game button
	if player_count >= minimum_players:
		start_game_button.set_valid(true)
	else:
		start_game_button.set_valid(false)

## Removes player at given player number.
func remove_player(player_num: int) -> void:
	# just do the opposite of add_new_player
	player_input_cards[player_num - 1].disconnect_control_type()
	# set control type of the removed player to nothing
	currently_used_controls[player_num - 1] = ""
	#currently_used_controls.pop_at(player_num - 1)
	player_count -= 1
	# activates corresponding cursor
	(player_cursors[player_num - 1] as PlayerCursor).deactivate()
	just_removed_player = true
	
	# enable/disable start game button
	if player_count >= minimum_players:
		start_game_button.set_valid(true)
	else:
		start_game_button.set_valid(false)

## TRIES to start game. Fails if there aren't enough players.
func start_game() -> void:
	if player_count < minimum_players: return
	if framework_control != null:
		# apparently need this nonsense to make Godot not freak out about my static typed methods
		var joined_players: Array[bool]
		# an array of booleans that equals [true, false, true, true], etc. that contains the existence of P1, P2, P3, and P4
		joined_players.assign([(currently_used_controls[0] != ""), (currently_used_controls[1] != ""), (currently_used_controls[2] != ""), (currently_used_controls[3] != "")])
		# then actually start the thing
		framework_control.start_game(player_count, joined_players, framework_control.zoom_matching)
