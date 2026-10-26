## Base class for objects a player can pick up and carry, such as canisters.
## Grabbing is instant and does not freeze the player (it is not an Interactable). A player holds at most one item.
## To make one: extend this and add a CollisionShape2D child for the grab range.
## A GrabRouter must be in the scene to turn interact presses into grabs and drops.
@abstract
class_name Grabbable extends Area2D

## Emitted after a player picks this up.
signal grabbed(player: Player)
## Emitted after the holding player lets go of this, whether by dropping it or handing it to something like a slot.
signal released(player: Player)

## Group every Grabbable joins, used to look up what a player is holding.
const GROUP: StringName = &"grabbables"

## Where this sits while held, relative to the holding player's position.
@export var hold_offset: Vector2 = Vector2(0.0, -70.0)

## The player holding this, or null if nobody is.
var holder: Player = null
## While true, nobody can grab this. Used while it is inside an insertion minigame.
var is_locked: bool = false

func _init() -> void:
	# only looks for players (layer 2), and doesn't need to be detected by anything itself
	collision_layer = 0
	collision_mask = 2
	add_to_group(GROUP)

# same pattern as Interactable, so subclasses can write their own _ready/_physics_process without calling super()
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_READY:
			set_physics_process(true)
		NOTIFICATION_PHYSICS_PROCESS:
			if holder == null:
				return
			if not is_instance_valid(holder):
				holder = null
				return
			global_position = holder.global_position + hold_offset

#region Overridable hooks

## Override to decide who can grab this. By default: nobody is holding it, it isn't locked, and the player's hands are empty.
func can_grab(player: Player) -> bool:
	return holder == null and not is_locked and Grabbable.get_held_by(player) == null

## Override to react to being picked up.
func _on_grabbed(_player: Player) -> void:
	pass

## Override to react to being let go of.
func _on_released(_player: Player) -> void:
	pass

#endregion

## Puts this in the given player's hands. Returns false if they aren't allowed to grab it right now.
func grab(player: Player) -> bool:
	if not can_grab(player):
		return false
	holder = player
	_on_grabbed(player)
	grabbed.emit(player)
	return true

## Lets go of this without moving it. Use drop() to put it on the floor instead.
func release() -> void:
	if holder == null:
		return
	var player := holder
	holder = null
	_on_released(player)
	released.emit(player)

## Lets go of this and puts it on the floor at the holding player's position.
func drop() -> void:
	if holder == null:
		return
	var drop_position := holder.global_position
	release()
	global_position = drop_position

func is_held() -> bool:
	return holder != null

## The item the given player is holding, or null if their hands are empty.
static func get_held_by(player: Player) -> Grabbable:
	if player == null or not player.is_inside_tree():
		return null
	for node in player.get_tree().get_nodes_in_group(GROUP):
		var grabbable := node as Grabbable
		if grabbable != null and grabbable.holder == player:
			return grabbable
	return null
