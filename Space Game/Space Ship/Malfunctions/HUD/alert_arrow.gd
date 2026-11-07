## An arrow at the edge of a player's screen pointing toward an off-screen malfunction, with its meter's countdown.
## PlayerHud creates, positions, and hides these.
class_name AlertArrow extends Node2D

## How far the countdown sits from the arrow, toward the middle of the screen, in pixels.
@export var label_distance: float = 44.0

@onready var _pointer: Node2D = $Pointer
@onready var _arrow: Polygon2D = $Pointer/Arrow
@onready var _countdown_label: Label = $CountdownLabel

## Points the arrow along angle (radians, 0 is right) in color, and shows countdown_text next to it.
func show_alert(angle: float, color: Color, countdown_text: String) -> void:
	visible = true
	_pointer.rotation = angle
	_arrow.color = color
	_countdown_label.text = countdown_text
	_countdown_label.modulate = color
	# keep the countdown on the inner side of the arrow so it never goes off screen
	_countdown_label.position = -Vector2.from_angle(angle) * label_distance - _countdown_label.size * 0.5
