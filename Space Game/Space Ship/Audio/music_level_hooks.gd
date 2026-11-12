## Feeds this level's game state to the MusicManager autoload, without the game systems knowing about music.
## Connects to signals the systems already have and polls state they already expose, then calls
## MusicManager.report_problem() and MusicManager.play_stinger(). Reports only while the LevelTimer is running.
##
## Not hooked up yet, because the game has no such state or event (report them from the owning system):
##   MusicManager.report_problem(&"asteroid_collision_course", active)
##   MusicManager.report_problem(&"off_course", active)
##   MusicManager.play_stinger(&"stinger_task_failed")  when a canister is wasted or a seal hold fails
class_name MusicLevelHooks extends Node

@export var level_timer: LevelTimer
@export var simulation: SpaceSimulation
## The EngineUnit. It is a single engine, reported as engine_dry_0.
@export var engine_unit: Node2D
## Optional. Missing on the small ship layout.
@export var comms_panel: CommsPanel

@export_group("Malfunctions")
## Optional, like the rest of this group: the small ship layout has no malfunctions.
@export var fire_system: FireSystem
@export var hull_breaches: HullBreachSystem
@export var life_support: LifeSupportUnit

func _ready() -> void:
	# siblings earlier in the tree are ready already, so the engine's capsule slots exist
	if simulation != null:
		simulation.asteroid_hit.connect(_on_asteroid_hit)
	if comms_panel != null:
		comms_panel.wrong_input_entered.connect(_on_comms_wrong_input)
		comms_panel.check_in_resolved.connect(_on_malfunction_fixed)
	if fire_system != null:
		fire_system.tile_extinguished.connect(_on_fire_tile_extinguished)
	if hull_breaches != null:
		hull_breaches.breach_closed.connect(_on_malfunction_fixed.unbind(1))
	if life_support != null:
		life_support.oxygen_failure_changed.connect(_on_oxygen_failure_changed)
	if engine_unit != null:
		for slot: Node in engine_unit.get("capsules"):
			var grabber: Node = slot.get("capsule_grabber")
			if grabber != null and grabber.has_signal(&"capsule_added"):
				grabber.capsule_added.connect(_on_capsule_added)

func _process(_delta: float) -> void:
	if level_timer == null or not level_timer.is_running:
		return
	if engine_unit != null:
		MusicManager.report_problem(&"engine_dry_0", int(engine_unit.get("fuel_available")) <= 0)
	MusicManager.report_problem(&"behind_schedule", level_timer.get_distance_progress() < level_timer.elapsed_fraction())

func _on_asteroid_hit(_asteroid: BridgeAsteroid) -> void:
	MusicManager.play_stinger(&"stinger_alarm")

func _on_comms_wrong_input() -> void:
	MusicManager.play_stinger(&"stinger_task_failed")

## A malfunction was fixed: a check-in resolved, a breach repaired, oxygen restored or a fire put out.
func _on_malfunction_fixed() -> void:
	MusicManager.play_stinger(&"stinger_fuel_received")

## Spraying puts out one tile at a time, so the fire only counts as fixed when the last tile goes out.
func _on_fire_tile_extinguished(_cell: Vector2i) -> void:
	if fire_system.get_burning_tile_count() == 0:
		_on_malfunction_fixed()

func _on_oxygen_failure_changed(failing: bool) -> void:
	if not failing:
		_on_malfunction_fixed()

## A canister was put into an engine slot. Only one with fuel in it counts as a delivery.
func _on_capsule_added(item: Dictionary) -> void:
	if int(item.get("Purity", 0)) > 0:
		MusicManager.play_stinger(&"stinger_fuel_received")
