class_name StartGameButton extends TextureButton

@export var parent: PlayerSelectScreen

@onready var sprite : Sprite2D = $"FakeSprite" as Sprite2D

## When greater than 0, stays highlighted.
var bodies_inside: int = 0

## When false, it's grayed out.
var is_valid = false

func _ready() -> void:
	set_valid(false)

## Called by child when clicked.
func clicked() -> void:
	parent.start_game()

func _on_area_2d_area_entered(_area: Area2D) -> void:
	bodies_inside += 1
	if is_valid:
		sprite.frame = 1
	else:
		sprite.frame = 2

func _on_area_2d_area_exited(_area: Area2D) -> void:
	bodies_inside -= 1
	if !bodies_inside:
		if is_valid:
			sprite.frame = 0
		else:
			sprite.frame = 2

## Sets the button to gray if it ain't pressable.
func set_valid(valid: bool) -> void:
	is_valid = valid
	if is_valid:
		if bodies_inside:
			sprite.frame = 1
		else:
			sprite.frame = 0
	else:
		sprite.frame = 2
