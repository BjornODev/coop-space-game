## One asteroid in the SpaceSimulation. Plain data owned by the simulation, so every bridge screen
## reads the same position, fuel, and scan state. SpaceSimulation creates these; don't make them yourself.
class_name BridgeAsteroid extends RefCounted

## Emitted whenever scan progress changes. ratio goes from 0 to 1.
signal scan_progress_changed(ratio: float)
## Emitted once, when the scan finishes and the fuel value becomes known.
signal scanned

## Position in simulation space.
var position: Vector2 = Vector2.ZERO
## Drift per second. Zero for stationary asteroids.
var velocity: Vector2 = Vector2.ZERO
## Collision and display radius in simulation units.
var radius: float = 0.0
## The most fuel an asteroid of this size could hold.
var max_fuel: int = 0
## The fuel this asteroid actually holds. Only shown on the scanner once scanned.
var fuel: int = 0
## fuel divided by the highest fuel any asteroid could hold. Picks its color once scanned.
var value_ratio: float = 0.0
## Seconds of scanning needed to finish.
var scan_time: float = 1.0
## Seconds of scanning done so far. Kept when scanning stops early, so it resumes later.
var scan_progress: float = 0.0
## True once fully scanned. Scanned asteroids can't be scanned again.
var is_scanned: bool = false

## How far along the scan is, from 0 to 1.
func get_scan_ratio() -> float:
	if is_scanned:
		return 1.0
	if scan_time <= 0.0:
		return 0.0
	return clampf(scan_progress / scan_time, 0.0, 1.0)

## Adds scan time and returns true if this call finished the scan.
## Use SpaceSimulation.scan_asteroid() instead, so the simulation's asteroid_scanned signal fires too.
func _add_scan_progress(seconds: float) -> bool:
	if is_scanned:
		return false
	scan_progress = minf(scan_progress + seconds, scan_time)
	if scan_progress >= scan_time:
		is_scanned = true
	scan_progress_changed.emit(get_scan_ratio())
	if is_scanned:
		scanned.emit()
	return is_scanned
