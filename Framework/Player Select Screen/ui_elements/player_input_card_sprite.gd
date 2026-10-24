class_name PlayerInputCardSprite extends Sprite2D

@onready var child_sprite: Sprite2D = $"Controls" as Sprite2D

## Loaded whenever the player is joined, for this sprite.
var primary_connected_texture: Texture
## Loaded whenever the player is joined, for this sprite's child sprite.
var secondary_connected_texture: Texture

## Loaded whenever the player is disconnected, for this sprite.
@onready var primary_disconnected_texture: Texture = load("res://Framework/Player Select Screen/assets/player_input_card/p0/base_light.png") as Texture
## Loaded whenever the player is disconnected, for this sprite's child sprite.
@onready var secondary_disconnected_texture: Texture = load("res://Framework/Player Select Screen/assets/player_input_card/p0/controls.png") as Texture

## Run when player number is assigned.
func setup_textures(player_num: int) -> void:
	primary_connected_texture = load("res://Framework/Player Select Screen/assets/player_input_card/p" + str(player_num) + "/base_light.png") as Texture
	secondary_connected_texture = load("res://Framework/Player Select Screen/assets/player_input_card/p" + str(player_num) + "/controls.png") as Texture

func set_connected(connected: bool) -> void:
	if connected:
		set_texture(primary_connected_texture)
		child_sprite.set_texture(secondary_connected_texture)
	else:
		set_texture(primary_disconnected_texture)
		child_sprite.set_texture(secondary_disconnected_texture)

## Sets frame of child sprite.
func set_child_frame(new_frame: int) -> void:
	child_sprite.frame = new_frame

## Gets frame of child sprite.
func get_child_frame() -> int:
	return child_sprite.frame
