## Electrical fire on the ship. Every burning floor tile is a FireTile scene sitting on a tilemap cell.
## Floor cells are read from the ship tilemap: any tile without collision. Fire spreads to the four neighboring
## floor cells, so it never crosses a wall, but it does go through doorways.
## Keep this node at the tilemap's origin. Players ask it how fast they can move and spray their extinguishers through it.
class_name FireSystem extends Node2D

## Emitted when a floor tile catches fire, from the director or from spreading.
signal tile_ignited(cell: Vector2i)
## Emitted when a burning tile is put out.
signal tile_extinguished(cell: Vector2i)

## The ship's floor and walls.
@export var tile_map: TileMapLayer
## Parent of the ShipRoom nodes. Burning tiles are grouped by these rooms.
@export var rooms_root: Node
## Scene instanced on every burning tile. Its root must have the FireTile script.
@export var fire_tile_scene: PackedScene

@export_group("Fire")
## Seconds between a burning tile's attempts to spread to a neighbor.
@export var spread_interval: float = 7.0
## Random seconds added to or taken from each spread interval, so tiles don't all spread at once.
@export var spread_interval_randomness: float = 2.0
## Health of each burning tile. Spraying removes health, and the fire goes out at 0.
@export var tile_max_health: float = 100.0
## Speed multiplier for players standing on a burning tile.
@export_range(0.0, 1.0) var burning_speed_multiplier: float = 0.5

@export_group("Extinguisher")
## How far in front of the player the spray reaches, in pixels.
@export var spray_range: float = 230.0
## Full width of the spray cone, in degrees.
@export_range(1.0, 180.0) var spray_cone_degrees: float = 50.0
## Burning tiles closer than this to the player are hit whichever way they face, in pixels.
@export var spray_point_blank_radius: float = 48.0
## Health removed from each tile in the spray per second.
@export var spray_damage_per_second: float = 120.0
## Extinguisher charge used per second of spraying. Only matters for extinguishers with limited charge.
@export var spray_charge_per_second: float = 1.0
## Distance between the points checked for walls along the spray, in pixels. Walls block the spray.
@export var spray_wall_check_step: float = 16.0

## Floor cells of the ship. Values are unused; this is a set.
var _floor_cells: Dictionary[Vector2i, bool] = {}
var _burning: Dictionary[Vector2i, FireTile] = {}
## Which room each floor cell counts toward. Cells outside every room (hallways) use the nearest room.
var _cell_rooms: Dictionary[Vector2i, ShipRoom] = {}

const NEIGHBORS: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]

func _ready() -> void:
	if tile_map == null:
		push_warning("FireSystem has no tile_map assigned.")
		return
	var rooms: Array[ShipRoom] = []
	if rooms_root != null:
		for child: Node in rooms_root.get_children():
			if child is ShipRoom:
				rooms.append(child)
	for cell: Vector2i in tile_map.get_used_cells():
		var data: TileData = tile_map.get_cell_tile_data(cell)
		if data != null and data.get_collision_polygons_count(0) == 0:
			_floor_cells[cell] = true
			_cell_rooms[cell] = _find_room(cell, rooms)

func _process(delta: float) -> void:
	# keys() is a copy, so tiles that ignite while looping wait for the next frame
	for cell: Vector2i in _burning.keys():
		var tile: FireTile = _burning.get(cell)
		if tile == null:
			continue
		tile.spread_time_left -= delta
		if tile.spread_time_left <= 0.0:
			tile.spread_time_left = _get_spread_time()
			_spread_from(cell)

#region Starting and stopping fire

## Sets a random floor tile that isn't burning yet on fire. Returns false if every floor tile is already burning.
func start_random_fire() -> bool:
	var candidates: Array[Vector2i] = []
	for cell: Vector2i in _floor_cells:
		if not _burning.has(cell):
			candidates.append(cell)
	if candidates.is_empty():
		return false
	ignite(candidates.pick_random())
	return true

## Sets cell on fire. Does nothing if it isn't a floor cell or is already burning.
func ignite(cell: Vector2i) -> void:
	if not _floor_cells.has(cell) or _burning.has(cell):
		return
	var tile: FireTile = fire_tile_scene.instantiate() as FireTile
	tile.setup(cell, tile_max_health, _get_spread_time())
	add_child(tile)
	tile.global_position = get_cell_center(cell)
	_burning[cell] = tile
	tile_ignited.emit(cell)

## Puts out the fire on cell, if there is one.
func extinguish(cell: Vector2i) -> void:
	var tile: FireTile = _burning.get(cell)
	if tile == null:
		return
	_burning.erase(cell)
	tile.queue_free()
	tile_extinguished.emit(cell)

#endregion

#region Queries

func is_burning(cell: Vector2i) -> bool:
	return _burning.has(cell)

## True if the floor tile under global_point is on fire.
func is_burning_at(global_point: Vector2) -> bool:
	return _burning.has(get_cell_at(global_point))

## Multiplier for a player's top speed at global_point: burning_speed_multiplier on fire, 1 elsewhere.
func get_speed_multiplier_at(global_point: Vector2) -> float:
	return burning_speed_multiplier if is_burning_at(global_point) else 1.0

## Number of burning tiles. Each one is an active Fire instance for the fire meter.
func get_burning_tile_count() -> int:
	return _burning.size()

## Number of rooms with at least one burning tile. The director counts each as one malfunction.
func get_burning_room_count() -> int:
	var rooms: Dictionary[ShipRoom, bool] = {}
	for cell: Vector2i in _burning:
		rooms[_cell_rooms.get(cell)] = true
	return rooms.size()

## One point per room on fire: the burning tile in that room nearest to viewer_position.
func get_alert_positions(viewer_position: Vector2) -> Array[Vector2]:
	var nearest: Dictionary[ShipRoom, Vector2] = {}
	for cell: Vector2i in _burning:
		var room: ShipRoom = _cell_rooms.get(cell)
		var center: Vector2 = get_cell_center(cell)
		if not nearest.has(room) or viewer_position.distance_squared_to(center) < viewer_position.distance_squared_to(nearest[room]):
			nearest[room] = center
	var positions: Array[Vector2] = []
	positions.assign(nearest.values())
	return positions

## Shows text (the time until the fire meter fills) on every burning tile.
func set_countdown_text(text: String) -> void:
	for tile: FireTile in _burning.values():
		tile.set_countdown_text(text)

## The tilemap cell under global_point.
func get_cell_at(global_point: Vector2) -> Vector2i:
	return tile_map.local_to_map(tile_map.to_local(global_point))

## Center of cell in global coordinates.
func get_cell_center(cell: Vector2i) -> Vector2:
	return tile_map.to_global(tile_map.map_to_local(cell))

#endregion

#region Extinguisher spray

## True if spraying from origin along direction would hit at least one burning tile.
func has_fire_in_spray(origin: Vector2, direction: Vector2) -> bool:
	return not _get_cells_in_spray(origin, direction).is_empty()

## Sprays an extinguisher held in item from origin along direction for delta seconds.
## Damages every burning tile in the spray cone and puts out any that reach 0 health.
## Returns false without spraying if the extinguisher has no charge left.
func spray(item: Dictionary, origin: Vector2, direction: Vector2, delta: float) -> bool:
	if not ShipItems.use_extinguisher_charge(item, spray_charge_per_second * delta):
		return false
	for cell: Vector2i in _get_cells_in_spray(origin, direction):
		if _burning[cell].damage(spray_damage_per_second * delta):
			extinguish(cell)
	return true

## Burning cells inside the spray cone that aren't behind a wall.
func _get_cells_in_spray(origin: Vector2, direction: Vector2) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var half_angle: float = deg_to_rad(spray_cone_degrees) * 0.5
	for cell: Vector2i in _burning:
		var center: Vector2 = get_cell_center(cell)
		var offset: Vector2 = center - origin
		var distance: float = offset.length()
		if distance <= spray_point_blank_radius:
			cells.append(cell)
			continue
		if distance > spray_range or absf(direction.angle_to(offset)) > half_angle:
			continue
		if _is_path_clear(origin, center):
			cells.append(cell)
	return cells

## True if every point along the line from start to end is over a floor cell.
func _is_path_clear(start: Vector2, end: Vector2) -> bool:
	var steps: int = maxi(ceili(start.distance_to(end) / maxf(spray_wall_check_step, 1.0)), 1)
	for i: int in steps + 1:
		if not _floor_cells.has(get_cell_at(start.lerp(end, float(i) / steps))):
			return false
	return true

#endregion

## Tries to set one random floor neighbor of cell on fire. Does nothing if every neighbor is a wall or already burning.
func _spread_from(cell: Vector2i) -> void:
	var options: Array[Vector2i] = []
	for offset: Vector2i in NEIGHBORS:
		var neighbor: Vector2i = cell + offset
		if _floor_cells.has(neighbor) and not _burning.has(neighbor):
			options.append(neighbor)
	if not options.is_empty():
		ignite(options.pick_random())

func _get_spread_time() -> float:
	return maxf(spread_interval + randf_range(-spread_interval_randomness, spread_interval_randomness), 0.1)

## The room containing cell, or the room whose center is nearest if no room contains it.
func _find_room(cell: Vector2i, rooms: Array[ShipRoom]) -> ShipRoom:
	var best: ShipRoom = null
	var best_distance: float = INF
	for room: ShipRoom in rooms:
		if room.has_cell(cell):
			return room
		var distance: float = room.get_center_cell().distance_squared_to(Vector2(cell))
		if distance < best_distance:
			best = room
			best_distance = distance
	return best
