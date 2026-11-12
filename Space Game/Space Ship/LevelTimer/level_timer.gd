## Counts down the time the crew has to reach planet B. The limit is set once at level start from the route
## length and the player count. When it runs out, a short overtime grace period starts: arriving during it is a
## late win, and running out of grace is a loss. Stops counting while the game is paused.
## The level calls start_level(). Other systems read the state below or connect to the signals.
class_name LevelTimer extends Node

## Group the level's timer is in, so autoloads like MusicManager can find it.
const GROUP: StringName = &"level_timer"

## Emitted once when final_stretch_seconds or less remain, or at level start if the limit is already that short.
signal final_stretch_started
## Emitted when the time limit runs out before the ship arrives. The grace countdown starts.
signal overtime_started
## Emitted when the ship arrives. late is true when it arrived during overtime.
signal level_won(late: bool)
## Emitted when the grace countdown runs out before the ship arrives.
signal level_lost

## The trip this timer measures. Its route length sets the time limit and its arrival ends the level.
@export var simulation: SpaceSimulation

@export_group("Time Limit")
## Minutes for 2 players on a route of reference_route_length.
@export var base_minutes: float = 12.0
## Route length that gets exactly base_minutes. The default is the current level's route,
## planet A (0, 0) to planet B (60000, -12000).
@export var reference_route_length: float = 61188.23
## Time multiplier for 1 or 2 players.
@export var two_player_multiplier: float = 1.0
## Time multiplier for 3 players. More players get less time.
@export var three_player_multiplier: float = 0.875
## Time multiplier for 4 players.
@export var four_player_multiplier: float = 0.75

@export_group("Final Stretch and Overtime")
## The final stretch starts when this many seconds or fewer remain.
@export var final_stretch_seconds: float = 60.0
## Seconds of overtime after the limit runs out, during which arriving is still a (late) win.
@export var grace_seconds: float = 30.0

## Seconds the crew has for this level. Set by start_level().
var time_limit: float = 0.0
## Seconds left before overtime. 0 during overtime.
var time_remaining: float = 0.0
## Seconds of grace left. Counts down only during overtime.
var grace_remaining: float = 0.0
## True from overtime_started until the level ends.
var is_overtime: bool = false
## True from final_stretch_started on.
var is_final_stretch: bool = false
## True while the level is being timed.
var is_running: bool = false
## Length of the route used for the limit, and for distance progress.
var route_length: float = 0.0

func _enter_tree() -> void:
	add_to_group(GROUP)

func _ready() -> void:
	if simulation == null:
		push_warning("LevelTimer has no simulation assigned, so it can't measure the route or see the arrival.")
		return
	simulation.arrived_at_destination.connect(_on_arrived_at_destination)

func _process(delta: float) -> void:
	if not is_running:
		return
	if is_overtime:
		grace_remaining = maxf(grace_remaining - delta, 0.0)
		if grace_remaining <= 0.0:
			_finish()
			level_lost.emit()
		return
	time_remaining = maxf(time_remaining - delta, 0.0)
	_check_final_stretch()
	if time_remaining <= 0.0:
		_start_overtime()

## Sets the time limit for this route and player_count, and starts counting down.
func start_level(player_count: int) -> void:
	route_length = reference_route_length
	if simulation != null:
		route_length = simulation.planet_a_position.distance_to(simulation.planet_b_position)
	var route_ratio: float = route_length / reference_route_length if reference_route_length > 0.0 else 1.0
	time_limit = base_minutes * 60.0 * route_ratio * get_player_multiplier(player_count)
	time_remaining = time_limit
	grace_remaining = grace_seconds
	is_overtime = false
	is_final_stretch = false
	is_running = true
	_check_final_stretch()

## Stops counting without a result, for when the level ends some other way.
func stop() -> void:
	is_running = false

func get_player_multiplier(player_count: int) -> float:
	if player_count >= 4:
		return four_player_multiplier
	if player_count == 3:
		return three_player_multiplier
	return two_player_multiplier

## Elapsed time divided by the time limit, from 0 to 1. Stays at 1 during overtime.
func elapsed_fraction() -> float:
	if time_limit <= 0.0:
		return 0.0
	return clampf((time_limit - time_remaining) / time_limit, 0.0, 1.0)

## Distance progress along the route, from 0 at planet A to 1 at planet B. Based on the straight-line distance
## left to planet B, since the simulation doesn't track distance traveled.
func get_distance_progress() -> float:
	if simulation == null or route_length <= 0.0:
		return 0.0
	return clampf(1.0 - simulation.get_distance_to_destination() / route_length, 0.0, 1.0)

#region Debug hooks (used by music_debug.gd only)

## Jumps the countdown to seconds remaining. 0 starts overtime right away.
func debug_set_time_remaining(seconds: float) -> void:
	if not is_running or is_overtime:
		return
	time_remaining = maxf(seconds, 0.0)
	_check_final_stretch()
	if time_remaining <= 0.0:
		_start_overtime()

#endregion

func _check_final_stretch() -> void:
	if not is_final_stretch and time_remaining <= final_stretch_seconds:
		is_final_stretch = true
		final_stretch_started.emit()

func _start_overtime() -> void:
	is_overtime = true
	time_remaining = 0.0
	grace_remaining = grace_seconds
	overtime_started.emit()

func _finish() -> void:
	is_running = false

func _on_arrived_at_destination() -> void:
	if not is_running:
		return
	var late: bool = is_overtime
	_finish()
	level_won.emit(late)
