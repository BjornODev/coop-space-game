class_name Player extends CharacterBody2D

@onready var sprite = $"Sprite2D"

var camera: Camera2D

const MAX_SPEED = 250.0
const ACCELERATION = 1500.0
const FRICTION = 1200.0
## How quickly the camera moves and zooms when going into or out of an interaction.
const CAMERA_TRANSITION_SPEED = 8.0

var player_number: int = 1

## The object this player is currently interacting with. Movement is disabled while this is set.
var current_interaction: Interactable = null

## Interactables whose range this player is standing in.
var _nearby_interactables: Array[Interactable] = []
## The camera's zoom outside of interactions, set by the game based on player count.
var _base_zoom: Vector2 = Vector2.ONE
## True while the camera is easing back to the player after an interaction.
var _camera_returning: bool = false
## Physics frame the last interaction ended on, so the button that ended it doesn't start a new one.
var _interaction_ended_frame: int = -1

func _physics_process(delta: float) -> void:
	# while interacting, the interactable is in charge: no movement, camera focuses on it
	if current_interaction != null:
		velocity = Vector2.ZERO
		_move_camera_toward(current_interaction.get_focus_position(), _base_zoom * current_interaction.zoom_multiplier, delta)
		return

	var input: PlayerInput = CoopInput.get_player(player_number)
	var direction: Vector2 = Input.get_vector(input.LEFT, input.RIGHT, input.UP, input.DOWN)

	# speeds up toward the input direction, or slows to a stop when there's no input
	if direction != Vector2.ZERO:
		velocity = velocity.move_toward(direction * MAX_SPEED, ACCELERATION * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	move_and_slide()

	if Input.is_action_just_pressed(input.A) and Engine.get_physics_frames() != _interaction_ended_frame:
		_try_interact()

	# cameras live in the splitscreen viewports, not on the player, so we move ours manually
	if camera != null:
		if _camera_returning:
			_camera_returning = not _move_camera_toward(global_position, _base_zoom, delta)
		else:
			camera.global_position = global_position

## Sets which controls this player uses and picks their sprite.
func set_player_num(player_num: int) -> void:
	player_number = player_num
	sprite.frame = player_num - 1

## Gives this player the camera for their slice of the screen. Its current zoom becomes the normal zoom.
func set_camera(new_camera: Camera2D) -> void:
	camera = new_camera
	camera.global_position = global_position
	_base_zoom = camera.zoom

## Called by an Interactable when this player enters its range.
func enter_interaction_range(interactable: Interactable) -> void:
	if not _nearby_interactables.has(interactable):
		_nearby_interactables.append(interactable)

## Called by an Interactable when this player leaves its range.
func exit_interaction_range(interactable: Interactable) -> void:
	_nearby_interactables.erase(interactable)

## Called by an Interactable when an interaction starts. Use Interactable.interact() instead of calling this directly.
func start_interaction(interactable: Interactable) -> void:
	current_interaction = interactable
	velocity = Vector2.ZERO
	_camera_returning = false

## Called by an Interactable when an interaction ends. Use Interactable.end_interaction() instead of calling this directly.
func stop_interaction(interactable: Interactable) -> void:
	if current_interaction != interactable:
		return
	current_interaction = null
	_camera_returning = true
	_interaction_ended_frame = Engine.get_physics_frames()

## Interacts with the closest interactable in range that will accept this player.
func _try_interact() -> void:
	var candidates: Array = _nearby_interactables.filter(func(i): return is_instance_valid(i) and i.can_interact(self))
	if candidates.is_empty():
		return
	candidates.sort_custom(func(a, b): return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position))
	candidates[0].interact(self)

## Eases the camera toward a position and zoom. Returns true once it has arrived.
func _move_camera_toward(target_position: Vector2, target_zoom: Vector2, delta: float) -> bool:
	if camera == null:
		return true
	var weight: float = 1.0 - exp(-CAMERA_TRANSITION_SPEED * delta)
	camera.global_position = camera.global_position.lerp(target_position, weight)
	camera.zoom = camera.zoom.lerp(target_zoom, weight)
	if camera.global_position.distance_to(target_position) < 1.0 and camera.zoom.distance_to(target_zoom) < 0.01:
		camera.global_position = target_position
		camera.zoom = target_zoom
		return true
	return false
