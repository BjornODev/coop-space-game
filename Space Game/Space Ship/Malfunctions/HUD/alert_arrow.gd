## An arrow at the edge of a player's screen pointing toward an off-screen malfunction, with its meter's countdown.
## PlayerHud creates, positions, and hides these.
class_name AlertArrow extends Node2D

## How far the countdown sits from the arrow, toward the middle of the screen, in pixels.
@export var label_distance: float = 44.0
## Size of an urgent arrow compared to a normal one.
@export var urgent_scale: float = 1.35
## How fast an urgent arrow pulses, in pulses per second.
@export var urgent_pulse_rate: float = 2.5

@onready var _pointer: Node2D = $Pointer
@onready var _arrow: Polygon2D = $Pointer/Arrow
@onready var _countdown_label: Label = $CountdownLabel

## Points the arrow along angle (radians, 0 is right) in color, and shows countdown_text next to it.
## urgent makes the arrow bigger, pulsing, and drawn over the others, for the malfunction that needs fixing first.
func show_alert(angle: float, color: Color, countdown_text: String, urgent: bool = false) -> void:
	visible = true
	z_index = 1 if urgent else 0
	if urgent:
		var pulse: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.001 * TAU * urgent_pulse_rate)
		_pointer.scale = Vector2.ONE * lerpf(1.0, urgent_scale, pulse)
	else:
		_pointer.scale = Vector2.ONE
	_pointer.rotation = angle
	_arrow.color = color
	_countdown_label.text = countdown_text
	_countdown_label.modulate = color
	# keep the countdown on the inner side of the arrow so it never goes off screen
	_countdown_label.position = -Vector2.from_angle(angle) * label_distance - _countdown_label.size * 0.5

## Where an arrow goes on the edge of arrow_rect so it points from the rect's center toward screen_position.
static func get_edge_position(arrow_rect: Rect2, screen_position: Vector2) -> Vector2:
	var center: Vector2 = arrow_rect.get_center()
	var half: Vector2 = arrow_rect.size * 0.5
	var direction: Vector2 = center.direction_to(screen_position)
	# slide out from the center along direction until reaching the rectangle's edge
	var reach_x: float = half.x / absf(direction.x) if not is_zero_approx(direction.x) else INF
	var reach_y: float = half.y / absf(direction.y) if not is_zero_approx(direction.y) else INF
	return center + direction * minf(reach_x, reach_y)
