extends CharacterBody2D

@export var speed : int = 250
@export var stop_speed : float = 450
var player_number : int = 0

var spinning_mode : bool = false
var grabbing : bool = false
var claw_radius : float = 56 # claw radius, min 32
var claw_max_radius : float = 64 * 2

@export_category("Claw Changables")
@export_range(0,1,0.1) var claw_grab_weight : float = 0.3
@export var spin_speed : float = 5
@export_range(1,7,1) var num_grabber_claws : int = 4
const GRABBER_CLAW = preload("res://Space Game/Space Ship/Sorting/Grabber/grabber_claw.tscn")
var grabber_claws : Dictionary = {}

@onready var instructions: VBoxContainer = $Instructions

func _ready() -> void:
	for i in range(num_grabber_claws):
		var grabber_claw = GRABBER_CLAW.instantiate()
		add_child(grabber_claw)
		var angle  : float = i * 2.0 * PI / num_grabber_claws
		var pos = polar_to_cartesian(claw_radius,angle)
		grabber_claw.set_position(pos)
		grabber_claws[grabber_claw] = angle
		grabber_claw.rotation = angle

func _physics_process(delta: float) -> void:
	var direction : Vector2 
	
	if not player_number:
		instructions.toggle_instructions(null)
		return
	
	var player_action = CoopInput.get_player(player_number)
	instructions.toggle_instructions(player_action)
	
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
	
	# toggle grab
	if Input.is_action_just_pressed(player_action.A):
		grabbing = not grabbing
	
	if grabbing:
		claw_radius = lerpf(claw_radius,32, claw_grab_weight)
	else:
		claw_radius = lerpf(claw_radius,claw_max_radius, claw_grab_weight)
	
	for claw in grabber_claws.keys():
			var angle = grabber_claws[claw]
			claw.set_position(polar_to_cartesian(claw_radius,angle))
	
	# toggle push mode
	if Input.is_action_just_pressed(player_action.Y):
		if claw_max_radius == 64:
			claw_max_radius *= 2
		else:
			claw_max_radius = 64
		
	if Input.is_action_pressed(player_action.X):
		for claw in grabber_claws.keys():
			grabber_claws[claw] += spin_speed * delta
			var angle = grabber_claws[claw]
			claw.set_position(polar_to_cartesian(claw_radius,angle))
			claw.rotation = angle
	
func polar_to_cartesian(radius : float, angle : float) -> Vector2:
	return Vector2(radius * cos(angle),radius * sin(angle))
	
