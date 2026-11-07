## Schedules fires and mission control check-ins. Hull breaches come only from asteroid hits and filters clog
## on their own, so the director never starts those, but they still fill meters and show alerts.
## The closer the ship gets to planet B, the shorter the time between new malfunctions and the more
## director malfunctions can be active at once. More players also raise that limit.
## Each room on fire and each pending check-in counts as one active director malfunction.
class_name MalfunctionDirector extends Node

## Emitted when the director starts a malfunction.
signal malfunction_started(type: Malfunction.Type)

## Trip progress is read from here.
@export var simulation: SpaceSimulation
@export var fire_system: FireSystem
@export var comms_panel: CommsPanel

## Seconds before the first malfunction of a run.
@export var first_malfunction_delay: float = 40.0

@export_group("Escalation")
## Seconds between malfunctions when leaving planet A.
@export var interval_at_start: float = 50.0
## Seconds between malfunctions when arriving at planet B.
@export var interval_at_end: float = 18.0
## Each interval is randomly stretched or shrunk by up to this fraction.
@export_range(0.0, 1.0) var interval_randomness: float = 0.25
## Most director malfunctions active at once when leaving planet A, before the player count multiplier.
@export var max_active_at_start: float = 1.0
## Most director malfunctions active at once when arriving at planet B, before the player count multiplier.
@export var max_active_at_end: float = 3.0
## Multiplies the active limit, indexed by player count minus 1. The result is rounded, and is never below 1.
@export var player_count_multipliers: Array[float] = [0.75, 1.0, 1.35, 1.7]

@export_group("Choosing")
## Chance weight of starting a fire.
@export var fire_weight: float = 1.0
## Chance weight of starting a check-in.
@export var comms_weight: float = 1.0
## A type that is already active has its weight multiplied by this, so repeats are less likely but still possible.
@export_range(0.0, 1.0) var already_active_weight_multiplier: float = 0.35

## Number of players this run. Set by the game.
var player_count: int = 1

var _time_left: float = 0.0

func _ready() -> void:
	_time_left = first_malfunction_delay

func _process(delta: float) -> void:
	_time_left -= delta
	if _time_left > 0.0:
		return
	_time_left = get_current_interval() * (1.0 + randf_range(-interval_randomness, interval_randomness))
	if get_active_count() < get_max_active():
		start_random_malfunction()

## How far along the trip the ship is, from 0 at planet A to 1 at planet B.
func get_progress() -> float:
	if simulation == null:
		return 0.0
	var trip: float = simulation.planet_a_position.distance_to(simulation.planet_b_position)
	if trip <= 0.0:
		return 1.0
	return clampf(1.0 - simulation.get_distance_to_destination() / trip, 0.0, 1.0)

## Seconds between malfunctions at the current progress, before randomness.
func get_current_interval() -> float:
	return lerpf(interval_at_start, interval_at_end, get_progress())

## Most director malfunctions allowed at once right now.
func get_max_active() -> int:
	var multiplier: float = 1.0
	if not player_count_multipliers.is_empty():
		multiplier = player_count_multipliers[clampi(player_count - 1, 0, player_count_multipliers.size() - 1)]
	return maxi(roundi(lerpf(max_active_at_start, max_active_at_end, get_progress()) * multiplier), 1)

## Director malfunctions active right now: each room on fire plus each pending check-in.
func get_active_count() -> int:
	var count: int = 0
	if fire_system != null:
		count += fire_system.get_burning_room_count()
	if comms_panel != null:
		count += comms_panel.get_pending_count()
	return count

## Picks fire or a check-in by weight and starts it.
func start_random_malfunction() -> void:
	var fire_chance: float = fire_weight
	if fire_system != null and fire_system.get_burning_tile_count() > 0:
		fire_chance *= already_active_weight_multiplier
	var comms_chance: float = comms_weight
	if comms_panel != null and comms_panel.get_pending_count() > 0:
		comms_chance *= already_active_weight_multiplier
	if fire_system == null:
		fire_chance = 0.0
	if comms_panel == null:
		comms_chance = 0.0
	if fire_chance + comms_chance <= 0.0:
		return
	if randf() * (fire_chance + comms_chance) < fire_chance:
		if fire_system.start_random_fire():
			malfunction_started.emit(Malfunction.Type.FIRE)
	else:
		comms_panel.start_check_in()
		malfunction_started.emit(Malfunction.Type.COMMS)
