class_name Player extends CharacterBody2D

@onready var visuals: Node2D = $Visuals
@onready var sprite: Sprite2D = $Visuals/Sprite2D
## Draws just the legs, below the held item, so a stepping leg passes under the item instead of over it.
@onready var legs_sprite: Sprite2D = $Visuals/Sprite2D/LegsSprite
@onready var item_sprite: Sprite2D = $Visuals/Sprite2D/ItemSprite
@onready var item_manager: Node = $ItemManager
## Shown in front of the astronaut while spraying an extinguisher. Its polygon is a unit cone scaled to the spray range.
@onready var spray_cone: Polygon2D = $Visuals/SprayCone

## Spritesheet used when walking empty-handed. Frames face right, laid out in one row.
@export var walk_texture: Texture2D
## Spritesheet used when walking while holding an item. Frames face right, laid out in one row.
@export var carry_walk_texture: Texture2D
## Size of a held item's longest side, in sprite pixels (one astronaut frame is 16).
@export var held_item_size: float = 7.0
## How far in front of the astronaut's center the spray starts, in pixels.
@export var spray_origin_offset: float = 30.0

var camera: Camera2D

const MAX_SPEED = 250.0
const ACCELERATION = 1500.0
const FRICTION = 1200.0
## How quickly the camera moves and zooms when going into or out of an interaction.
const CAMERA_TRANSITION_SPEED = 8.0
## How quickly the astronaut turns to face where it's going.
const TURN_SPEED = 14.0
## Walk animation frames per second at full speed. Slower movement plays it slower.
const WALK_FPS_AT_MAX_SPEED = 12.0
## Below this speed the astronaut stands still on its idle frame.
const IDLE_SPEED = 10.0
const WALK_FRAMES = 12
const CARRY_WALK_FRAMES = 10
## Where the middle of the hands is on each carry walk frame, in sprite pixels from the frame's centre.
## The held item sits here, so it sways with the arms.
const CARRY_HAND_OFFSETS: Array[Vector2] = [
	Vector2(6, 0), Vector2(6, 1.5), Vector2(6, 1.5), Vector2(6, 1.5), Vector2(6, 1.5),
	Vector2(6, 0), Vector2(6, -1.5), Vector2(6, -1.5), Vector2(6, -1.5), Vector2(6, -1.5),
]
## Tints the white parts of the suit (not the visor or gloves) so players can tell each other apart. Indexed by player number - 1.
const PLAYER_TINTS: Array[Color] = [
	Color(0.35, 0.5, 1.0), Color(1.0, 0.5, 0.5), Color(0.5, 1.0, 0.5), Color(1.0, 0.95, 0.6),
]

var player_number: int = 1

## The ship's fire. Set by the game. Slows players on burning tiles and takes extinguisher spray.
var fire_system: FireSystem = null

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
## The direction the astronaut is turning toward, as an angle. Sprites face right at 0.
var _facing_angle: float = 0.0
## Where we are in the walk cycle, in frames. Fractional so slow walking still advances.
var _anim_time: float = 0.0
var _was_carrying: bool = false
## Pull from hull breaches this physics frame, in pixels per second. Cleared after each move.
var _pull_velocity: Vector2 = Vector2.ZERO
## True from pressing A at a fire with an extinguisher until A is let go.
var _spraying: bool = false

func _ready() -> void:
	item_manager.set_item_texture.connect(_set_held_item_texture)
	_set_held_item_texture(null,1,0)
	_update_animation(0.0)

func _process(delta: float) -> void:
	visuals.rotation = lerp_angle(visuals.rotation, _facing_angle, 1.0 - exp(-TURN_SPEED * delta))
	_update_animation(delta)

func _physics_process(delta: float) -> void:
	# while interacting, the interactable is in charge: no movement, camera focuses on it
	if current_interaction != null:
		velocity = Vector2.ZERO
		_pull_velocity = Vector2.ZERO
		_set_spraying(false)
		_move_camera_toward(current_interaction.get_focus_position(), _base_zoom * current_interaction.zoom_multiplier, delta)
		return

	var input: PlayerInput = CoopInput.get_player(player_number)
	var direction: Vector2 = Input.get_vector(input.LEFT, input.RIGHT, input.UP, input.DOWN)

	# speeds up toward the input direction, or slows to a stop when there's no input
	var max_speed: float = MAX_SPEED
	if fire_system != null:
		max_speed *= fire_system.get_speed_multiplier_at(global_position)
	if direction != Vector2.ZERO:
		velocity = velocity.move_toward(direction * max_speed, ACCELERATION * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	# hull breaches drag the player along on top of their own movement, without becoming part of it
	velocity += _pull_velocity
	move_and_slide()
	velocity -= _pull_velocity
	_pull_velocity = Vector2.ZERO

	if direction != Vector2.ZERO:
		_facing_angle = direction.angle()

	if Input.is_action_just_pressed(input.A) and Engine.get_physics_frames() != _interaction_ended_frame:
		# an extinguisher aimed at fire sprays instead of using stations or dropping
		if _is_holding_extinguisher() and fire_system.has_fire_in_spray(_get_spray_origin(), _get_facing_direction()):
			_set_spraying(true)
		else:
			_try_interact()
	if _spraying:
		if Input.is_action_pressed(input.A) and _is_holding_extinguisher():
			_set_spraying(fire_system.spray(item_manager.item_being_held, _get_spray_origin(), _get_facing_direction(), delta))
		else:
			_set_spraying(false)

	# cameras live in the splitscreen viewports, not on the player, so we move ours manually
	if camera != null:
		if _camera_returning:
			_camera_returning = not _move_camera_toward(global_position, _base_zoom, delta)
		else:
			camera.global_position = global_position

## Sets which controls this player uses and picks their sprite.
func set_player_num(player_num: int) -> void:
	player_number = player_num
	# player_tint.gdshader applies this to the suit only; the material is local to each player instance
	var tint: Color = PLAYER_TINTS[(player_num - 1) % PLAYER_TINTS.size()]
	sprite.material.set_shader_parameter("tint", tint)
	legs_sprite.material.set_shader_parameter("tint", tint)

## Gives this player the camera for their slice of the screen. Its current zoom becomes the normal zoom.
func set_camera(new_camera: Camera2D) -> void:
	camera = new_camera
	camera.global_position = global_position
	_base_zoom = camera.zoom

## Drags this player toward a hull breach this physics frame. pull is a speed in pixels per second.
func apply_pull(pull: Vector2) -> void:
	_pull_velocity += pull

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
		item_manager.drop_held_item(get_global_position())
		return
	candidates.sort_custom(func(a, b): return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position))
	candidates[0].interact(self)
	

func _is_holding_extinguisher() -> bool:
	return fire_system != null and ShipItems.has_status(item_manager.item_being_held, ShipItems.STATUS_EXTINGUISHER)

func _get_facing_direction() -> Vector2:
	return Vector2.from_angle(_facing_angle)

func _get_spray_origin() -> Vector2:
	return global_position + _get_facing_direction() * spray_origin_offset

## Starts or stops spraying, and shows the spray cone sized to the fire system's spray range and angle.
func _set_spraying(spraying: bool) -> void:
	_spraying = spraying
	spray_cone.visible = spraying
	if spraying and fire_system != null:
		var half_angle: float = deg_to_rad(fire_system.spray_cone_degrees) * 0.5
		# the cone's far edge runs from (1, -1) to (1, 1), like the suction cone on the bridge radar
		spray_cone.position = Vector2.RIGHT * spray_origin_offset
		spray_cone.scale = Vector2(fire_system.spray_range, fire_system.spray_range * tan(half_angle))

## Picks the walk or carry walk sheet, advances the cycle with movement speed, and keeps the held item in the hands.
func _update_animation(delta: float) -> void:
	var carrying: bool = not item_manager.item_being_held.is_empty()
	if carrying != _was_carrying:
		_was_carrying = carrying
		sprite.frame = 0 # reset first so the frame is never out of range for the new sheet
		legs_sprite.frame = 0
		sprite.texture = carry_walk_texture if carrying else walk_texture
		sprite.hframes = CARRY_WALK_FRAMES if carrying else WALK_FRAMES
	var frame_count: int = sprite.hframes

	var speed: float = velocity.length()
	if speed < IDLE_SPEED:
		_anim_time = 0.0 # frame 0 is the neutral standing pose on both sheets
	else:
		_anim_time = fmod(_anim_time + delta * WALK_FPS_AT_MAX_SPEED * speed / MAX_SPEED, frame_count)
	sprite.frame = int(_anim_time) % frame_count
	legs_sprite.texture = sprite.texture
	legs_sprite.hframes = sprite.hframes
	legs_sprite.frame = sprite.frame

	item_sprite.visible = carrying
	if carrying:
		item_sprite.position = CARRY_HAND_OFFSETS[sprite.frame]

## Shows a held item's texture, scaled so any texture size fits between the hands.
func _set_held_item_texture(texture: Texture2D, h_frame : int, frame : int) -> void:
	item_sprite.texture = texture
	if texture == null:
		return
	item_sprite.hframes = h_frame
	item_sprite.frame = frame
	if h_frame > 1:
		var shortest_side: float = minf(texture.get_width(), texture.get_height())
		item_sprite.scale = Vector2.ONE * held_item_size / shortest_side
	else:
		var longest_side: float = maxf(texture.get_width(), texture.get_height())
		item_sprite.scale = Vector2.ONE * held_item_size / longest_side

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
