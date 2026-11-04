## A slot that takes a held canister through an align-then-push minigame. Used by the sealer and the engines.
## While inserting, movement input slides the canister along this node's local x axis (rotate the node to change it).
## Interact pushes: within align_tolerance of the opening the canister goes in, otherwise it bounces back to where it
## started and pushing is blocked for bounce_delay. Cancel (B) ends early and the player keeps the canister.
## A canister stays in the slot until someone grabs it out.
class_name CanisterSlot extends Interactable

## Emitted after a canister is pushed in successfully.
signal canister_inserted(canister: Canister)
## Emitted after the canister in the slot is grabbed out.
signal canister_removed(canister: Canister)
## Emitted when a push misses the opening and the canister bounces back.
signal insertion_bounced()

## How far the canister can slide to either side of the opening, in pixels.
@export var slide_range: float = 80.0
## How fast the canister slides with full movement input, in pixels per second.
@export var slide_speed: float = 120.0
## How far from the opening (in pixels, either side) a push still goes in.
@export var align_tolerance: float = 8.0
## The canister starts at least this far from the opening, in pixels, so every insertion needs some aligning.
@export var min_start_distance: float = 30.0
## Where the canister waits in front of the opening while aligning, relative to the slot point.
@export var approach_offset: Vector2 = Vector2(0.0, 50.0)
## Seconds the player has to wait to push again after a bounce.
@export var bounce_delay: float = 0.6

## The canister sitting in the slot, or null if it is empty.
var canister: Canister = null

## The canister in the insertion minigame, or null if nobody is inserting.
var _inserting: Canister = null
## Current slide position along the axis, where 0 lines up with the opening.
var _slide_offset: float = 0.0
## Slide position the current insertion started at, and returns to on a bounce.
var _start_offset: float = 0.0
## Seconds left before the player can push again.
var _bounce_time_left: float = 0.0

@onready var _slot_point: Marker2D = $SlotPoint
@onready var _opening: ColorRect = $Opening
@onready var _track: ColorRect = $Track
@onready var _status_label: Label = $StatusLabel

func _ready() -> void:
	# size the readout nodes to match the tuning values
	_opening.size.x = align_tolerance * 2.0
	_opening.position.x = _slot_point.position.x - align_tolerance
	_track.size.x = slide_range * 2.0
	_track.position = _slot_point.position + approach_offset - Vector2(slide_range, _track.size.y / 2.0)

func _process(_delta: float) -> void:
	_status_label.text = _get_status_text()

#region Interactable hooks

## The player must be holding a canister, and the slot must be empty.
func can_interact(player: Player) -> bool:
	return super.can_interact(player) and canister == null and Grabbable.get_held_by(player) is Canister

func _on_interaction_started(player: Player) -> void:
	_inserting = Grabbable.get_held_by(player) as Canister
	_inserting.release()
	_inserting.is_locked = true
	_start_offset = _pick_start_offset()
	_slide_offset = _start_offset
	_bounce_time_left = 0.0
	_place_inserting()

func _on_interaction_ended(player: Player) -> void:
	# still set means the insertion was cancelled, so the player keeps the canister
	if _inserting == null:
		return
	_inserting.is_locked = false
	if not _inserting.grab(player):
		_inserting.global_position = player.global_position
	_inserting = null

func _interaction_process(_player: Player, delta: float) -> void:
	var input := get_player_input()
	if Input.is_action_just_pressed(input.B):
		end_interaction()
		return

	var direction: Vector2 = Input.get_vector(input.LEFT, input.RIGHT, input.UP, input.DOWN)
	var axis: Vector2 = global_transform.x.normalized()
	_slide_offset = clampf(_slide_offset + direction.dot(axis) * slide_speed * delta, -slide_range, slide_range)
	_bounce_time_left = maxf(_bounce_time_left - delta, 0.0)

	if Input.is_action_just_pressed(input.A) and _bounce_time_left <= 0.0:
		if absf(_slide_offset) <= align_tolerance:
			_insert()
			end_interaction()
			return
		_slide_offset = _start_offset
		_bounce_time_left = bounce_delay
		insertion_bounced.emit()

	_place_inserting()

#endregion

func has_canister() -> bool:
	return canister != null

## Moves the canister from the minigame into the slot.
func _insert() -> void:
	canister = _inserting
	_inserting = null
	canister.is_locked = false
	canister.global_position = _slot_point.global_position
	canister.grabbed.connect(_on_canister_grabbed, CONNECT_ONE_SHOT)
	canister_inserted.emit(canister)

func _on_canister_grabbed(_player: Player) -> void:
	var removed := canister
	canister = null
	canister_removed.emit(removed)

func _place_inserting() -> void:
	_inserting.global_position = _slot_point.to_global(approach_offset + Vector2(_slide_offset, 0.0))

func _pick_start_offset() -> float:
	var distance: float = randf_range(minf(min_start_distance, slide_range), slide_range)
	return distance if randf() < 0.5 else -distance

func _get_status_text() -> String:
	if _inserting != null:
		if _bounce_time_left > 0.0:
			return "BOUNCED"
		return "ALIGN %d" % roundi(absf(_slide_offset))
	if canister != null:
		return "IN SLOT"
	return "EMPTY"
