## The suction arm on one radar: a line from the mount to the nozzle, plus the suction cone when asked for.
## RadarDisplay positions this every frame in radar pixels. Holds no state of its own.
class_name SuctionArmView extends Node2D

## Arm color while suction is off.
@export var arm_color: Color = Color(0.8, 0.8, 0.8)
## Arm color while suction is on.
@export var arm_suction_color: Color = Color(0.2, 1.0, 0.9)
## Arm thickness in pixels.
@export var arm_width: float = 2.0
## Nozzle color while suction is off.
@export var nozzle_color: Color = Color(1.0, 1.0, 1.0)
## Nozzle color while suction is on.
@export var nozzle_suction_color: Color = Color(0.2, 1.0, 0.9)
## The nozzle never gets smaller than this many pixels in radius, so it stays visible.
@export var min_nozzle_radius_px: float = 3.0
@export var cone_color: Color = Color(0.2, 1.0, 0.9, 0.3)

@onready var _cone: Polygon2D = $Cone
@onready var _arm_line: Line2D = $ArmLine
@onready var _nozzle: Polygon2D = $Nozzle

func _ready() -> void:
	_arm_line.width = arm_width
	_cone.color = cone_color

## Moves the arm to run from mount to nozzle, both in radar pixels.
func show_arm(mount: Vector2, nozzle: Vector2, nozzle_radius_px: float, suction_active: bool) -> void:
	_arm_line.points = PackedVector2Array([mount, nozzle])
	_arm_line.default_color = arm_suction_color if suction_active else arm_color
	_nozzle.position = nozzle
	_nozzle.scale = Vector2.ONE * maxf(nozzle_radius_px, min_nozzle_radius_px)
	_nozzle.color = nozzle_suction_color if suction_active else nozzle_color

## Shows the cone with its point at nozzle, opening along angle (radians), length_px long and half_angle (radians) to each side.
func show_cone(nozzle: Vector2, angle: float, length_px: float, half_angle: float) -> void:
	_cone.visible = true
	_cone.position = nozzle
	_cone.rotation = angle
	# the polygon is a triangle with its point at the origin and its far edge from (1, -1) to (1, 1)
	_cone.scale = Vector2(length_px, length_px * tan(half_angle))

func hide_cone() -> void:
	_cone.visible = false
