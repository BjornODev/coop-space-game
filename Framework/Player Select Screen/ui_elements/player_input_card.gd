class_name PlayerInputCard extends Control

## Determines player that the card is hooked up to.
@export_range(1, 4) var player_num: int = 1

@onready var sprite : PlayerInputCardSprite = $"Player Input Card Sprite" as PlayerInputCardSprite
@onready var timer : Timer = $"InputHint Timer" as Timer
@onready var anim : AnimationPlayer = $"AnimationPlayer" as AnimationPlayer
@onready var disconnect_button : TextureButton = $"Disconnect" as TextureButton

## When true, this player needs to connect to the game for it to start.
var needs_to_exist_to_play_game: bool = false

## When true, you can disconnect.
var connected: bool = false

var player_select_screen: PlayerSelectScreen

## Determines what inputs are hinted when no player is connected.
## 1 represents keyboard_wasd, 2 represents keyboard_arrow_keys, 3 represents controller.
var allowed_input_methods = []

func _ready() -> void:
	sprite.setup_textures(player_num)

## Setter. When true, this player needs to connect to the game for it to start.
func set_needs_to_exist_to_play_game(needs_to: bool) -> void:
	needs_to_exist_to_play_game = needs_to

## Runs when controller is connected. Matches visual to the controller being used.
func connect_control_type(control_type: String) -> void:
	match control_type:
		"keyboard_wasd": sprite.set_child_frame(1)
		"keyboard_arrow_keys": sprite.set_child_frame(2)
		_: sprite.set_child_frame(3)
	sprite.set_connected(true)
	timer.stop()
	anim.stop(true)
	anim.play("connect")
	connected = true

## Runs when controller is disconnected. Stays colored if player must be connected for the game to start (like P1).
func disconnect_control_type() -> void:
	sprite.set_child_frame(0)
	if !true:#needs_to_exist_to_play_game:
		sprite.set_connected(true)
	else:
		sprite.set_connected(false)
	_on_input_hint_timer_timeout()
	anim.stop(true)
	anim.play("disconnect")
	connected = false

## Sets the controls that this input card will hint at.
func set_valid_controls(wasd: bool, arrow_keys: bool, controller: bool) -> void:
	if wasd:
		allowed_input_methods.append(1)
	if arrow_keys:
		allowed_input_methods.append(2)
	if controller:
		allowed_input_methods.append(3)

## On timeout, switches frame to one of the available input methods.
func _on_input_hint_timer_timeout() -> void:
	var current_index: int = allowed_input_methods.find(sprite.get_child_frame())
	if current_index == -1:
		current_index = 0
	else:
		current_index += 1
		if current_index >= allowed_input_methods.size():
			current_index = 0
	
	if allowed_input_methods.is_empty():
		# your game doesn't allow inputs!
		sprite.set_child_frame(0)
	else:
		sprite.set_child_frame(allowed_input_methods[current_index])
	# written this way to make the animation prettier when connecting/disconnecting
	timer.start()

## Runs whenever disconnect is pressed, either by mouse or cursor.
func disconnect_pressed() -> void:
	if connected and player_select_screen != null:
		player_select_screen.remove_player(player_num)

func _on_texture_button_pressed() -> void:
	disconnect_pressed()

func set_player_select_screen(screen: PlayerSelectScreen) -> void:
	player_select_screen = screen
