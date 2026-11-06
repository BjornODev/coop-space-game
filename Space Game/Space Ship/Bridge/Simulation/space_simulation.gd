## Authoritative state of the trip from planet A to planet B: the ship, its suction arm, and every asteroid.
## Nothing here is drawn. Bridge screens hold a reference to this node and display what it holds.
## A run is generated in _ready() when generate_on_ready is on. Call start_run() to generate a fresh one.
class_name SpaceSimulation extends Node

## Emitted after a run is generated. Displays should drop old asteroid visuals and rebuild from get_asteroids().
signal run_started
## Emitted once per run, when the ship first comes within arrival_radius of planet B.
signal arrived_at_destination
## Emitted when the ship bumps into an asteroid. Fires again for the same asteroid only after they separate.
signal asteroid_hit(asteroid: BridgeAsteroid)
## Emitted when an asteroid finishes being scanned.
signal asteroid_scanned(asteroid: BridgeAsteroid)
## Emitted when an asteroid leaves the simulation for good. Displays should drop its visual.
signal asteroid_removed(asteroid: BridgeAsteroid)
## Emitted when the nozzle captures an asteroid. data is a processing item: {"Texture", "Status", "Purity"}.
signal asteroid_harvested(data: Dictionary)

@export_group("Route")
## Where the ship starts.
@export var planet_a_position: Vector2 = Vector2.ZERO
## The destination.
@export var planet_b_position: Vector2 = Vector2(60000.0, -12000.0)
## How close the ship's center has to get to planet B to count as arrived.
@export var arrival_radius: float = 400.0
## No asteroid is placed within this distance of either planet.
@export var planet_clear_radius: float = 1500.0

@export_group("Ship")
## How fast boosting speeds the ship up along its heading, in simulation units per second squared.
@export var boost_acceleration: float = 200.0
## How fast reverse thrust pushes the ship backwards against its heading, in simulation units per second squared.
@export var reverse_acceleration: float = 150.0
## The ship never goes faster than this, in simulation units per second.
@export var max_speed: float = 400.0
## How fast the ship slows down while coasting, in simulation units per second squared. 0 coasts forever.
@export var coast_deceleration: float = 0.0
## How fast the heading turns at full stick, in degrees per second.
@export var turn_rate_degrees: float = 60.0
## Collision radius of the ship. The default roughly matches the ship marker on a radar at the default range,
## so blips stop at the marker's edge instead of sliding under it.
@export var ship_radius: float = 60.0
## How much of the ship's speed into an asteroid is kept as a bounce away from it. 0 stops dead, 1 bounces fully.
@export_range(0.0, 1.0) var collision_bounciness: float = 0.4
## Extra distance at which the ship still counts as touching an asteroid, so resting against one doesn't
## flicker in and out of contact and fire asteroid_hit over and over.
@export var contact_tolerance: float = 1.0

@export_group("Asteroid Clusters")
## Generate a run as soon as this node is ready.
@export var generate_on_ready: bool = true
## Seed for asteroid placement. 0 picks a new random layout every run.
@export var random_seed: int = 0
## Number of clusters placed between the planets.
@export var cluster_count: int = 60
## Asteroids scattered around each cluster center. Fewer may appear if some land too close to a planet.
@export var asteroids_per_cluster: int = 24
## How far asteroids can be scattered from their cluster center.
@export var cluster_radius: float = 800.0
## How far cluster centers can sit to either side of the straight line from planet A to planet B.
@export var route_spread: float = 1500.0
## Tries per cluster center or asteroid before giving up, when it keeps landing too close to a planet.
@export var placement_attempts: int = 20

@export_group("Asteroids")
## Smallest asteroid radius.
@export var asteroid_radius_min: float = 25.0
## Largest asteroid radius.
@export var asteroid_radius_max: float = 120.0
## Fraction of asteroids that drift. The rest stay still.
@export_range(0.0, 1.0) var drifting_fraction: float = 0.4
## Slowest drift speed, in simulation units per second.
@export var drift_speed_min: float = 5.0
## Fastest drift speed, in simulation units per second.
@export var drift_speed_max: float = 30.0
## Most fuel the smallest possible asteroid could hold.
@export var fuel_capacity_at_min_size: int = 10
## Most fuel the largest possible asteroid could hold. Also the top of the color gradient.
@export var fuel_capacity_at_max_size: int = 100
## Seconds to scan the smallest asteroid.
@export var base_scan_time: float = 1.5
## Extra seconds added to the scan of the largest asteroid. Sizes in between get a proportional share.
@export var scan_time_size_scaling: float = 3.0

@export_group("Suction Arm")
## How far ahead of the ship's center the arm is mounted. The default matches the nose of the ship marker
## on a radar at the default range.
@export var arm_mount_offset: float = 75.0
## How far the arm can swing to either side of straight ahead, in degrees. 90 reaches straight out each side.
@export var arm_swing_limit_degrees: float = 90.0
## Arm angle at the start of a run, in degrees. 0 is straight ahead, negative is toward the ship's left, positive its right.
@export var arm_start_angle_degrees: float = 0.0
## How fast the arm swings at full stick, in degrees per second.
@export var arm_swing_speed_degrees: float = 60.0
## Shortest arm length, from the mount to the nozzle tip. Each run starts at this length.
@export var arm_min_length: float = 150.0
## Longest arm length, from the mount to the nozzle tip.
@export var arm_max_length: float = 700.0
## How fast the arm extends and retracts at full stick, in simulation units per second.
@export var arm_extend_speed: float = 200.0
## Radius of the nozzle tip. An asteroid touching this is captured.
@export var nozzle_radius: float = 30.0

@export_group("Suction")
## Full width of the suction cone, in degrees.
@export_range(1.0, 179.0) var suction_cone_angle_degrees: float = 40.0
## How far the suction cone reaches past the nozzle tip.
@export var suction_cone_length: float = 500.0
## Pull speed on the smallest asteroid, in simulation units per second.
@export var suction_base_pull_speed: float = 300.0
## How much size slows the pull. The largest asteroid is pulled at base speed / (1 + this).
@export var suction_size_scaling: float = 2.0
## Purity of a captured asteroid holding the most fuel possible. Processing treats Purity as a percentage.
@export var harvested_max_purity: int = 100

## Current arm angle in degrees. 0 is straight ahead, negative is toward the ship's left, positive its right.
var arm_angle_degrees: float = 0.0
## Current arm length, from the mount to the nozzle tip.
var arm_length: float = 0.0

## Ship position in simulation space.
var ship_position: Vector2 = Vector2.ZERO
## Ship heading in radians. 0 points along +x, increasing clockwise. Boosting pushes the ship this way.
var ship_heading: float = 0.0
## Ship velocity in simulation units per second. Kept after a boost ends, so the ship coasts.
var ship_velocity: Vector2 = Vector2.ZERO

## Turn input from the pilot, from -1 (left) to 1 (right).
var _turn_input: float = 0.0
## True while the pilot holds boost.
var _boost_input: bool = false
## True while the pilot holds reverse.
var _reverse_input: bool = false
## Swing input from the harvester, from -1 (toward the ship's left) to 1 (toward its right).
var _arm_swing_input: float = 0.0
## Extend input from the harvester, from -1 (retract) to 1 (extend).
var _arm_extend_input: float = 0.0
## True while the harvester holds suction.
var _suction_input: bool = false
var _asteroids: Array[BridgeAsteroid] = []
var _clusters: Array[BridgeAsteroidCluster] = []
## Asteroids the ship is touching right now, so asteroid_hit only fires when contact starts.
var _touching: Dictionary[BridgeAsteroid, bool] = {}
var _has_arrived: bool = false
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	_reset_arm()
	if generate_on_ready:
		start_run()

func _physics_process(delta: float) -> void:
	ship_heading = wrapf(ship_heading + _turn_input * deg_to_rad(turn_rate_degrees) * delta, -PI, PI)
	if _boost_input or _reverse_input:
		if _boost_input:
			ship_velocity += get_ship_direction() * boost_acceleration * delta
		if _reverse_input:
			ship_velocity -= get_ship_direction() * reverse_acceleration * delta
		ship_velocity = ship_velocity.limit_length(max_speed)
	else:
		ship_velocity = ship_velocity.move_toward(Vector2.ZERO, coast_deceleration * delta)
	ship_position += ship_velocity * delta
	_update_arm(delta)
	var nozzle: Vector2 = get_nozzle_position()
	for asteroid: BridgeAsteroid in _asteroids:
		asteroid.pull_velocity = _get_pull_velocity(asteroid, nozzle)
		asteroid.position += asteroid.get_current_velocity() * delta
	_capture_touching_asteroids(nozzle)
	_check_collisions()
	_check_arrival()

## Puts the ship back at planet A, at rest and facing planet B, resets the arm, and scatters a new set of asteroids.
func start_run() -> void:
	if random_seed == 0:
		_rng.randomize()
	else:
		_rng.seed = random_seed
	_asteroids.clear()
	_clusters.clear()
	_touching.clear()
	_has_arrived = false
	clear_pilot_input()
	clear_arm_input()
	_reset_arm()
	ship_position = planet_a_position
	ship_heading = planet_a_position.angle_to_point(planet_b_position)
	ship_velocity = Vector2.ZERO

	for _i: int in cluster_count:
		var center: Vector2 = _pick_cluster_center()
		var cluster: BridgeAsteroidCluster = BridgeAsteroidCluster.new()
		for _j: int in asteroids_per_cluster:
			var asteroid: BridgeAsteroid = _try_create_asteroid(center)
			if asteroid != null:
				cluster.asteroids.append(asteroid)
				_asteroids.append(asteroid)
		if not cluster.asteroids.is_empty():
			_clusters.append(cluster)
	run_started.emit()

## Sets the pilot's controls. turn goes from -1 (left) to 1 (right). Call every frame while someone is flying.
## reverse pushes the ship backwards against its heading, to slow down or back away.
func set_pilot_input(turn: float, boost: bool, reverse: bool = false) -> void:
	_turn_input = clampf(turn, -1.0, 1.0)
	_boost_input = boost
	_reverse_input = reverse

## Releases the controls, so the ship coasts along its current velocity.
func clear_pilot_input() -> void:
	_turn_input = 0.0
	_boost_input = false
	_reverse_input = false

## Sets the harvester's controls. swing goes from -1 (toward the ship's left) to 1 (toward its right),
## extend from -1 (retract) to 1 (extend). Call every frame while someone is harvesting.
func set_arm_input(swing: float, extend: float, suction: bool) -> void:
	_arm_swing_input = clampf(swing, -1.0, 1.0)
	_arm_extend_input = clampf(extend, -1.0, 1.0)
	_suction_input = suction

## Releases the controls. The arm holds its angle and length, and suction stops.
func clear_arm_input() -> void:
	_arm_swing_input = 0.0
	_arm_extend_input = 0.0
	_suction_input = false

## Adds delta seconds of scanning to asteroid. Returns true if this call finished the scan.
func scan_asteroid(asteroid: BridgeAsteroid, delta: float) -> bool:
	if asteroid == null or asteroid.is_scanned:
		return false
	var finished: bool = asteroid._add_scan_progress(delta)
	if finished:
		asteroid_scanned.emit(asteroid)
	return finished

func get_asteroids() -> Array[BridgeAsteroid]:
	return _asteroids

## Every cluster of this run, in a stable order. A cluster stays listed with no asteroids once all of them are captured.
func get_clusters() -> Array[BridgeAsteroidCluster]:
	return _clusters

## Where the arm attaches to the ship, in simulation space.
func get_arm_mount_position() -> Vector2:
	return ship_position + get_ship_direction() * arm_mount_offset

## Unit vector the arm points along, from the mount out to the nozzle.
func get_arm_direction() -> Vector2:
	# with heading along +x and y pointing down, the ship's right is +y, so a positive angle turns toward the right
	return get_ship_direction().rotated(deg_to_rad(arm_angle_degrees))

## Position of the nozzle tip in simulation space.
func get_nozzle_position() -> Vector2:
	return get_arm_mount_position() + get_arm_direction() * arm_length

func is_suction_active() -> bool:
	return _suction_input

## How many asteroids suction is pulling right now.
func get_pulled_asteroid_count() -> int:
	var count: int = 0
	for asteroid: BridgeAsteroid in _asteroids:
		if asteroid.is_being_pulled():
			count += 1
	return count

## Unit vector the ship is facing.
func get_ship_direction() -> Vector2:
	return Vector2.from_angle(ship_heading)

func get_ship_speed() -> float:
	return ship_velocity.length()

func is_boosting() -> bool:
	return _boost_input

func is_reversing() -> bool:
	return _reverse_input

func has_arrived() -> bool:
	return _has_arrived

func get_distance_to_destination() -> float:
	return ship_position.distance_to(planet_b_position)

## The most fuel any asteroid could hold. Scanned colors are normalized against this.
func get_highest_possible_fuel() -> int:
	return maxi(fuel_capacity_at_min_size, fuel_capacity_at_max_size)

## Asteroids are solid: the ship is pushed out of any it overlaps and bounces off.
## Asteroids are treated as immovable, so a drifting one shoves the ship along with it.
func _check_collisions() -> void:
	for asteroid: BridgeAsteroid in _asteroids:
		var away: Vector2 = ship_position - asteroid.position
		var min_distance: float = ship_radius + asteroid.radius
		var touching: bool = away.length() <= min_distance + contact_tolerance
		if not touching:
			_touching.erase(asteroid)
			continue
		var normal: Vector2 = away.normalized() if not away.is_zero_approx() else -get_ship_direction()
		if away.length() < min_distance:
			ship_position = asteroid.position + normal * min_distance
		# only the part of the velocity heading into the asteroid is reflected, so the ship can slide along it
		var closing_speed: float = (ship_velocity - asteroid.get_current_velocity()).dot(normal)
		if closing_speed < 0.0:
			ship_velocity -= normal * closing_speed * (1.0 + collision_bounciness)
		if not _touching.has(asteroid):
			_touching[asteroid] = true
			asteroid_hit.emit(asteroid)

func _reset_arm() -> void:
	arm_angle_degrees = clampf(arm_start_angle_degrees, -arm_swing_limit_degrees, arm_swing_limit_degrees)
	arm_length = arm_min_length

func _update_arm(delta: float) -> void:
	arm_angle_degrees = clampf(arm_angle_degrees + _arm_swing_input * arm_swing_speed_degrees * delta, -arm_swing_limit_degrees, arm_swing_limit_degrees)
	arm_length = clampf(arm_length + _arm_extend_input * arm_extend_speed * delta, arm_min_length, arm_max_length)

## Velocity toward the nozzle for an asteroid inside the active suction cone, or zero for any other asteroid.
func _get_pull_velocity(asteroid: BridgeAsteroid, nozzle: Vector2) -> Vector2:
	if not _suction_input or not _is_in_suction_cone(asteroid, nozzle):
		return Vector2.ZERO
	var size_ratio: float = 1.0
	if asteroid_radius_max > asteroid_radius_min:
		size_ratio = inverse_lerp(asteroid_radius_min, asteroid_radius_max, asteroid.radius)
	var speed: float = suction_base_pull_speed / (1.0 + suction_size_scaling * size_ratio)
	return asteroid.position.direction_to(nozzle) * speed

## True if any part of asteroid overlaps the suction cone, which is the triangle shown on the harvesting radar:
## its point at the nozzle, opening along the arm direction, with a flat far edge suction_cone_length away.
func _is_in_suction_cone(asteroid: BridgeAsteroid, nozzle: Vector2) -> bool:
	var direction: Vector2 = get_arm_direction()
	var offset: Vector2 = asteroid.position - nozzle
	var along: float = offset.dot(direction)
	if along < -asteroid.radius or along > suction_cone_length + asteroid.radius:
		return false
	var half_angle: float = deg_to_rad(suction_cone_angle_degrees) * 0.5
	var sideways: float = absf(offset.dot(direction.orthogonal()))
	return sideways <= along * tan(half_angle) + asteroid.radius / cos(half_angle)

## Captures every asteroid touching the nozzle tip, whether or not suction is running.
func _capture_touching_asteroids(nozzle: Vector2) -> void:
	# backwards, so removing an asteroid doesn't skip the next one
	for i: int in range(_asteroids.size() - 1, -1, -1):
		var asteroid: BridgeAsteroid = _asteroids[i]
		if asteroid.position.distance_to(nozzle) <= asteroid.radius + nozzle_radius:
			_capture_asteroid(i)

func _capture_asteroid(index: int) -> void:
	var asteroid: BridgeAsteroid = _asteroids[index]
	_asteroids.remove_at(index)
	_touching.erase(asteroid)
	for cluster: BridgeAsteroidCluster in _clusters:
		cluster.asteroids.erase(asteroid)
	asteroid_removed.emit(asteroid)
	asteroid_harvested.emit(_create_harvested_item(asteroid))

## Converts asteroid to the item dictionary used by processing, in the format of the default in grab_area.gd.
## A captured asteroid is raw material, and more fuel means a purer item.
func _create_harvested_item(asteroid: BridgeAsteroid) -> Dictionary:
	return {
		"Texture": preload("res://Framework/Assets/icon.svg"),
		"Status": "unrefined",
		"Purity": roundi(asteroid.value_ratio * harvested_max_purity),
		"is_scanned" : asteroid.is_scanned
	}

func _check_arrival() -> void:
	if not _has_arrived and get_distance_to_destination() <= arrival_radius:
		_has_arrived = true
		arrived_at_destination.emit()

## Random point near the route line, retried while it lands inside a planet's clear zone.
func _pick_cluster_center() -> Vector2:
	var route: Vector2 = planet_b_position - planet_a_position
	var side: Vector2 = route.orthogonal().normalized()
	var center: Vector2 = planet_a_position
	for _attempt: int in placement_attempts:
		center = planet_a_position + route * _rng.randf() + side * _rng.randf_range(-route_spread, route_spread)
		if _is_clear_of_planets(center, 0.0):
			break
	return center

## Places one asteroid somewhere around center, or returns null if every try landed too close to a planet.
func _try_create_asteroid(center: Vector2) -> BridgeAsteroid:
	var radius: float = _rng.randf_range(asteroid_radius_min, asteroid_radius_max)
	for _attempt: int in placement_attempts:
		# sqrt spreads points evenly over the disk instead of bunching them at the center
		var offset: Vector2 = Vector2.from_angle(_rng.randf() * TAU) * cluster_radius * sqrt(_rng.randf())
		var position: Vector2 = center + offset
		if _is_clear_of_planets(position, radius):
			return _create_asteroid(position, radius)
	return null

func _create_asteroid(position: Vector2, radius: float) -> BridgeAsteroid:
	var asteroid: BridgeAsteroid = BridgeAsteroid.new()
	asteroid.position = position
	asteroid.radius = radius
	var size_ratio: float = 1.0
	if asteroid_radius_max > asteroid_radius_min:
		size_ratio = inverse_lerp(asteroid_radius_min, asteroid_radius_max, radius)
	asteroid.max_fuel = roundi(lerpf(fuel_capacity_at_min_size, fuel_capacity_at_max_size, size_ratio))
	asteroid.fuel = _rng.randi_range(0, asteroid.max_fuel)
	var highest: int = get_highest_possible_fuel()
	asteroid.value_ratio = float(asteroid.fuel) / highest if highest > 0 else 0.0
	asteroid.scan_time = base_scan_time + scan_time_size_scaling * size_ratio
	if _rng.randf() < drifting_fraction:
		var speed: float = _rng.randf_range(drift_speed_min, drift_speed_max)
		asteroid.velocity = Vector2.from_angle(_rng.randf() * TAU) * speed
	return asteroid

func _is_clear_of_planets(point: Vector2, margin: float) -> bool:
	var clearance: float = planet_clear_radius + margin
	return point.distance_to(planet_a_position) > clearance and point.distance_to(planet_b_position) > clearance
