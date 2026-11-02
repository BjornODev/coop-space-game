## A square, heading-up radar centered on the ship. The world turns around the ship so its heading always points up.
## Every asteroid within range is shown as a RadarBlip at its true position and size, plus a line showing
## where the ship is drifting and the ship's suction arm. Planets are not shown, so finding planet B takes the route view.
## Used by the navigation, scanner, and harvesting screens. Call set_simulation() before it can show anything.
class_name RadarDisplay extends Control

## Scene instanced once per asteroid in range. Its root must have the RadarBlip script.
@export var blip_scene: PackedScene
## Asteroid colors, shared with every other bridge display.
@export var palette: AsteroidPalette
## Simulation units from the ship to the edge of the radar.
@export var radar_range: float = 1500.0
## Ship marker size as a fraction of the radar's width.
@export var ship_marker_fraction: float = 0.05
## Blips never get smaller than this many pixels in radius, so tiny asteroids stay visible.
@export var min_blip_radius: float = 2.0
## Show scan progress and fuel numbers on blips. The scanner turns this on while someone uses it.
@export var show_scan_details: bool = false
## Show the suction cone while suction is active. Only the harvesting radar turns this on.
@export var show_suction_cone: bool = false
@export var ship_color: Color = Color(1.0, 1.0, 1.0)
## Ship marker color while boosting.
@export var ship_boost_color: Color = Color(1.0, 0.5, 0.0)
## Ship marker color while reversing.
@export var ship_reverse_color: Color = Color(0.0, 0.8, 1.0)
## The velocity line reaches where the ship will be after this many seconds of coasting.
@export var velocity_line_seconds: float = 3.0

@onready var _blip_layer: Control = $Blips
@onready var _velocity_line: Line2D = $VelocityLine
@onready var _ship_marker: Polygon2D = $ShipMarker
@onready var _arm_view: SuctionArmView = $SuctionArmView

var _simulation: SpaceSimulation = null
var _blips: Dictionary[BridgeAsteroid, RadarBlip] = {}

func _process(_delta: float) -> void:
	if _simulation == null:
		return
	_update_ship_marker()
	_update_arm()
	_update_blips()

## Sets which simulation this radar shows.
func set_simulation(simulation: SpaceSimulation) -> void:
	if _simulation != null and _simulation.run_started.is_connected(_clear_blips):
		_simulation.run_started.disconnect(_clear_blips)
		_simulation.asteroid_removed.disconnect(_on_asteroid_removed)
	_simulation = simulation
	_clear_blips()
	if _simulation != null:
		_simulation.run_started.connect(_clear_blips)
		_simulation.asteroid_removed.connect(_on_asteroid_removed)

## Half the radar's width in pixels: the distance from the ship to the edge.
func get_radius_px() -> float:
	return minf(size.x, size.y) * 0.5

## Center of the radar (the ship) in this control's local pixels.
func get_center_px() -> Vector2:
	return size * 0.5

func get_pixels_per_unit() -> float:
	return get_radius_px() / radar_range

## Turns a simulation-space offset so the ship's heading points up.
func rotate_to_radar(offset: Vector2) -> Vector2:
	# heading points along +x at angle 0, so turn an extra quarter turn to make it point up
	return offset.rotated(-PI * 0.5 - _simulation.ship_heading)

## Converts a simulation position to this control's local pixels, with the ship's heading pointing up.
func world_to_radar(world_position: Vector2) -> Vector2:
	return get_center_px() + rotate_to_radar(world_position - _simulation.ship_position) * get_pixels_per_unit()

## Radius in pixels that asteroid is drawn at.
func get_blip_radius_px(asteroid: BridgeAsteroid) -> float:
	return maxf(asteroid.radius * get_pixels_per_unit(), min_blip_radius)

## True if any part of asteroid's blip lands on the radar.
func is_in_range(asteroid: BridgeAsteroid) -> bool:
	var radar_rect: Rect2 = Rect2(Vector2.ZERO, size).grow(get_blip_radius_px(asteroid))
	return radar_rect.has_point(world_to_radar(asteroid.position))

func _update_ship_marker() -> void:
	var center: Vector2 = get_center_px()
	_ship_marker.position = center
	_ship_marker.scale = Vector2.ONE * size.x * ship_marker_fraction
	if _simulation.is_boosting():
		_ship_marker.color = ship_boost_color
	elif _simulation.is_reversing():
		_ship_marker.color = ship_reverse_color
	else:
		_ship_marker.color = ship_color
	var drift: Vector2 = rotate_to_radar(_simulation.ship_velocity) * velocity_line_seconds * get_pixels_per_unit()
	_velocity_line.points = PackedVector2Array([center, center + drift])

func _update_arm() -> void:
	var nozzle: Vector2 = world_to_radar(_simulation.get_nozzle_position())
	var suction: bool = _simulation.is_suction_active()
	var pixels_per_unit: float = get_pixels_per_unit()
	_arm_view.show_arm(world_to_radar(_simulation.get_arm_mount_position()), nozzle, _simulation.nozzle_radius * pixels_per_unit, suction)
	if show_suction_cone and suction:
		var angle: float = rotate_to_radar(_simulation.get_arm_direction()).angle()
		var half_angle: float = deg_to_rad(_simulation.suction_cone_angle_degrees) * 0.5
		_arm_view.show_cone(nozzle, angle, _simulation.suction_cone_length * pixels_per_unit, half_angle)
	else:
		_arm_view.hide_cone()

func _update_blips() -> void:
	for asteroid: BridgeAsteroid in _simulation.get_asteroids():
		var blip: RadarBlip = _blips.get(asteroid)
		if not is_in_range(asteroid):
			if blip != null:
				blip.queue_free()
				_blips.erase(asteroid)
			continue
		if blip == null:
			blip = blip_scene.instantiate() as RadarBlip
			_blip_layer.add_child(blip)
			_blips[asteroid] = blip
		blip.position = world_to_radar(asteroid.position)
		blip.show_asteroid(asteroid, get_blip_radius_px(asteroid), palette.get_color(asteroid), show_scan_details)

func _on_asteroid_removed(asteroid: BridgeAsteroid) -> void:
	var blip: RadarBlip = _blips.get(asteroid)
	if blip != null:
		blip.queue_free()
		_blips.erase(asteroid)

func _clear_blips() -> void:
	for blip: RadarBlip in _blips.values():
		blip.queue_free()
	_blips.clear()
