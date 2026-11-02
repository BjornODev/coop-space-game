## North-up map of the whole trip, framed to fit planet A and planet B.
## Shows both planets, the ship and its heading, and each asteroid cluster as one translucent box.
## Call set_simulation() before it can show anything.
class_name RouteView extends Control

## Scene instanced once per asteroid cluster. It is resized to cover the cluster.
@export var cloud_scene: PackedScene
## Simulation units of empty space kept around the two planets when framing the map.
@export var frame_padding: float = 9000.0
## Ship marker size as a fraction of the map's width.
@export var ship_marker_fraction: float = 0.05
## Clouds never get smaller than this many pixels in radius.
@export var min_cloud_radius: float = 6.0
@export var ship_color: Color = Color(1.0, 1.0, 1.0)
## Ship marker color while boosting.
@export var ship_boost_color: Color = Color(1.0, 0.5, 0.0)
## Ship marker color while reversing.
@export var ship_reverse_color: Color = Color(0.0, 0.8, 1.0)
@export var cloud_color: Color = Color(0.255, 0.412, 0.882, 0.4)
@export var planet_a_color: Color = Color(0.0, 1.0, 1.0)
@export var planet_b_color: Color = Color(1.0, 0.0, 1.0)

@onready var _route_line: Line2D = $RouteLine
@onready var _cloud_layer: Control = $Clouds
@onready var _planet_a: ColorRect = $PlanetA
@onready var _planet_b: ColorRect = $PlanetB
@onready var _ship_marker: Polygon2D = $ShipMarker

var _simulation: SpaceSimulation = null
## One cloud per cluster, in the same order as SpaceSimulation.get_clusters().
var _clouds: Array[Control] = []

func _ready() -> void:
	_planet_a.color = planet_a_color
	_planet_b.color = planet_b_color

func _process(_delta: float) -> void:
	if _simulation == null:
		return
	var map_a: Vector2 = world_to_map(_simulation.planet_a_position)
	var map_b: Vector2 = world_to_map(_simulation.planet_b_position)
	_route_line.points = PackedVector2Array([map_a, map_b])
	_planet_a.position = map_a - _planet_a.size * 0.5
	_planet_b.position = map_b - _planet_b.size * 0.5

	var clusters: Array[BridgeAsteroidCluster] = _simulation.get_clusters()
	for i: int in mini(clusters.size(), _clouds.size()):
		# a cluster with every asteroid captured has no position left to show
		_clouds[i].visible = not clusters[i].asteroids.is_empty()
		var radius: float = maxf(clusters[i].get_extent() * get_pixels_per_unit(), min_cloud_radius)
		_clouds[i].position = world_to_map(clusters[i].get_center()) - Vector2.ONE * radius
		_clouds[i].size = Vector2.ONE * radius * 2.0

	_ship_marker.position = world_to_map(_simulation.ship_position)
	# the marker's polygon points up, and heading 0 points along +x
	_ship_marker.rotation = _simulation.ship_heading + PI * 0.5
	_ship_marker.scale = Vector2.ONE * size.x * ship_marker_fraction
	if _simulation.is_boosting():
		_ship_marker.color = ship_boost_color
	elif _simulation.is_reversing():
		_ship_marker.color = ship_reverse_color
	else:
		_ship_marker.color = ship_color

## Sets which simulation this map shows.
func set_simulation(simulation: SpaceSimulation) -> void:
	if _simulation != null and _simulation.run_started.is_connected(_rebuild_clouds):
		_simulation.run_started.disconnect(_rebuild_clouds)
	_simulation = simulation
	if _simulation != null:
		_simulation.run_started.connect(_rebuild_clouds)
	_rebuild_clouds()

## Area of simulation space shown on the map: both planets plus frame_padding on every side.
func get_world_bounds() -> Rect2:
	return Rect2(_simulation.planet_a_position, Vector2.ZERO).expand(_simulation.planet_b_position).grow(frame_padding)

func get_pixels_per_unit() -> float:
	var bounds: Rect2 = get_world_bounds()
	return minf(size.x / bounds.size.x, size.y / bounds.size.y)

## Converts a simulation position to this control's local pixels.
func world_to_map(world_position: Vector2) -> Vector2:
	return size * 0.5 + (world_position - get_world_bounds().get_center()) * get_pixels_per_unit()

func _rebuild_clouds() -> void:
	for cloud: Control in _clouds:
		cloud.queue_free()
	_clouds.clear()
	if _simulation == null:
		return
	for _cluster: BridgeAsteroidCluster in _simulation.get_clusters():
		var cloud: Control = cloud_scene.instantiate() as Control
		cloud.modulate = cloud_color
		_cloud_layer.add_child(cloud)
		_clouds.append(cloud)
