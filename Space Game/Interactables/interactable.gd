## Base class for anything a player can walk up to and interact with.
## To make one: extend this, add a CollisionShape2D child for the interaction range,
## and call end_interaction() (or connect any signal to it) when the interaction should finish.
@abstract
class_name Interactable extends Area2D

## Emitted after a player starts interacting with this object.
signal interaction_started(player: Player)
## Emitted after the interaction finishes and the player has control again.
signal interaction_ended(player: Player)

## How much further the player's camera zooms in while interacting, relative to their normal zoom.
@export var zoom_multiplier: float = 2.0
## Where the camera centers while interacting, relative to this object's position.
@export var focus_offset: Vector2 = Vector2.ZERO

## The player currently using this object, or null if nobody is.
var current_player: Player = null

## Physics frame the interaction started on, so the button press that started it isn't also read as minigame input.
var _started_frame: int = -1

func _init() -> void:
	# only looks for players (layer 2), and doesn't need to be detected by anything itself
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

# _notification runs for every script in the inheritance chain, so subclasses can freely
# write their own _ready/_physics_process without needing to call super().
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_READY:
			set_physics_process(true)
		NOTIFICATION_PHYSICS_PROCESS:
			if is_interacting() and Engine.get_physics_frames() > _started_frame:
				_interaction_process(current_player, get_physics_process_delta_time())
		NOTIFICATION_EXIT_TREE:
			# don't leave a player frozen if this object gets removed mid-interaction
			end_interaction()

#region Overridable hooks

## Override to decide who can use this object. By default, only one player at a time.
func can_interact(_player: Player) -> bool:
	return current_player == null

## Override to set things up when a player starts interacting (start a timer, show minigame UI, etc).
func _on_interaction_started(_player: Player) -> void:
	pass

## Override to clean up when the interaction finishes.
func _on_interaction_ended(_player: Player) -> void:
	pass

## Override to run logic every physics frame while a player is interacting. This is where minigame controls go,
## using get_player_input() to read the interacting player's buttons.
func _interaction_process(_player: Player, _delta: float) -> void:
	pass

#endregion

## Starts an interaction with the given player. Returns false if they aren't allowed to interact right now.
func interact(player: Player) -> bool:
	if is_interacting() or not can_interact(player):
		return false
	current_player = player
	_started_frame = Engine.get_physics_frames()
	player.start_interaction(self)
	_on_interaction_started(player)
	interaction_started.emit(player)
	return true

## Finishes the interaction: zooms the camera back out and gives the player control again.
## Connect any signal to this to make it the exit condition, e.g. timer.timeout.connect(end_interaction).
## For signals that pass arguments, use .unbind(), e.g. some_signal.connect(end_interaction.unbind(1)).
func end_interaction() -> void:
	if not is_interacting():
		return
	var player := current_player
	current_player = null
	player.stop_interaction(self)
	_on_interaction_ended(player)
	interaction_ended.emit(player)

func is_interacting() -> bool:
	return current_player != null

## Where the interacting player's camera should center.
func get_focus_position() -> Vector2:
	return global_position + focus_offset

## Inputs of the interacting player, for minigame controls. Returns null if nobody is interacting.
func get_player_input() -> PlayerInput:
	if not is_interacting():
		return null
	return CoopInput.get_player(current_player.player_number)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.enter_interaction_range(self)

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		body.exit_interaction_range(self)
