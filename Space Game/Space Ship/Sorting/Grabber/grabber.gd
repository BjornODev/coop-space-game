extends CharacterBody2D

@export var speed : int = 250
@export var stop_speed : float = 450
var player_number : int = 0

var spinning_mode : bool = false
@export_category("Claw Changables")
@export_range(0,1,0.1) var claw_grab_weight : float = 0.5
@export var spin_speed : float = 20
var claw_radius : float = 56 # claw radius, min 22, max 56
@export_range(1,7,1) var num_grabber_claws : int = 3
const GRABBER_CLAW = preload("res://Space Game/Space Ship/Sorting/Grabber/grabber_claw.tscn")
var grabber_claws : Dictionary = {}

@onready var instructions: Label = $Instructions

func _ready() -> void:
	for i in range(num_grabber_claws):
		var grabber_claw = GRABBER_CLAW.instantiate()
		add_child(grabber_claw)
		var angle  : float = i * 2.0 * PI / num_grabber_claws
		var pos = polar_to_cartesian(claw_radius,angle)
		grabber_claw.set_position(pos)
		grabber_claws[grabber_claw] = angle

func _physics_process(delta: float) -> void:
	var direction : Vector2 
	
	if not player_number:
		instructions.visible = false
		return
	
	instructions.visible = true
	var player_action = CoopInput.get_player(player_number)
	if Input.is_action_pressed(player_action.UP):
		direction.y = -1
	elif Input.is_action_pressed(player_action.DOWN):
		direction.y = 1
	
	if Input.is_action_pressed(player_action.LEFT):
		direction.x = -1
	elif Input.is_action_pressed(player_action.RIGHT):
		direction.x = 1
	
	call_grabber_controls(delta)
	
	if direction:
		velocity = velocity.move_toward(direction.normalized() * speed,delta * speed) 
	else:
		velocity = velocity.move_toward(Vector2(0,0),delta * stop_speed)
	
	move_and_slide()

func call_grabber_controls(delta : float) -> void:
	if not player_number:
		return
	
	var player_action = CoopInput.get_player(player_number)
	if Input.is_action_pressed(player_action.A):
		claw_radius = lerpf(claw_radius,22, claw_grab_weight)
		for claw in grabber_claws.keys():
			var angle = grabber_claws[claw]
			claw.set_position(polar_to_cartesian(claw_radius,angle))
	elif Input.is_action_just_released(player_action.A):
			claw_radius = lerpf(claw_radius,56, 1)
			for claw in grabber_claws.keys():
				var angle = grabber_claws[claw]
				claw.set_position(polar_to_cartesian(claw_radius,angle))
		
	if Input.is_action_just_pressed(player_action.X):
		spinning_mode = not spinning_mode
	
	if spinning_mode:
		for claw in grabber_claws.keys():
			grabber_claws[claw] += spin_speed * delta
			var angle = grabber_claws[claw]
			claw.set_position(polar_to_cartesian(claw_radius,angle))
	
func polar_to_cartesian(radius : float, angle : float) -> Vector2:
	return Vector2(radius * cos(angle),radius * sin(angle))
