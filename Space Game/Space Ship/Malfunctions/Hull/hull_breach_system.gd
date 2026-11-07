## Opens hull breaches when the ship hits asteroids. Breaches only ever come from SpaceSimulation.asteroid_hit.
## The breach appears on the side of the hull the asteroid hit, relative to the ship's heading, at a random hull wall tile
## on that side. The ship's front is up on the tilemap, so the ship's left is the tilemap's left.
## Hull wall tiles are walls with empty space next to them and a floor tile on the opposite side, so every breach can be reached.
## Keep this node at the tilemap's origin.
class_name HullBreachSystem extends Node2D

## Emitted when an asteroid hit opens a new breach.
signal breach_opened(breach: HullBreach)
## Emitted when a breach is patched.
signal breach_closed(breach: HullBreach)

enum HullSide { FRONT, BACK, LEFT, RIGHT }

## The simulation whose asteroid hits open breaches.
@export var simulation: SpaceSimulation
## The ship's floor and walls.
@export var tile_map: TileMapLayer
## Scene instanced for every breach. Its root must have the HullBreach script.
@export var breach_scene: PackedScene
## Hits are ignored while this many breaches are open.
@export var max_open_breaches: int = 6

## Outward direction on the tilemap for each side of the ship.
const SIDE_DIRECTIONS: Dictionary[HullSide, Vector2i] = {
	HullSide.FRONT: Vector2i.UP,
	HullSide.BACK: Vector2i.DOWN,
	HullSide.LEFT: Vector2i.LEFT,
	HullSide.RIGHT: Vector2i.RIGHT,
}

## Hull wall cells that face each side.
var _hull_cells: Dictionary[HullSide, Array] = {}
var _breaches: Dictionary[Vector2i, HullBreach] = {}

func _ready() -> void:
	for side: HullSide in SIDE_DIRECTIONS:
		_hull_cells[side] = []
	if tile_map == null:
		push_warning("HullBreachSystem has no tile_map assigned.")
	else:
		_find_hull_cells()
	if simulation == null:
		push_warning("HullBreachSystem has no simulation assigned.")
	else:
		simulation.asteroid_hit.connect(_on_asteroid_hit)

## Number of open breaches. Each one is an active Hull instance for the hull meter.
func get_open_breach_count() -> int:
	return _breaches.size()

func get_breaches() -> Array[HullBreach]:
	var breaches: Array[HullBreach] = []
	breaches.assign(_breaches.values())
	return breaches

## Shows text (the time until the hull meter fills) on every open breach.
func set_countdown_text(text: String) -> void:
	for breach: HullBreach in _breaches.values():
		breach.set_countdown_text(text)

## Which side of the ship asteroid is on, relative to the ship's heading.
func get_hit_side(asteroid: BridgeAsteroid) -> HullSide:
	# in the ship's frame, +x is straight ahead and +y is the ship's right
	var local: Vector2 = (asteroid.position - simulation.ship_position).rotated(-simulation.ship_heading)
	if absf(local.x) >= absf(local.y):
		return HullSide.FRONT if local.x >= 0.0 else HullSide.BACK
	return HullSide.RIGHT if local.y >= 0.0 else HullSide.LEFT

## Opens a breach on a random hull tile on side that doesn't have one yet. Returns null if none is free.
func open_breach(side: HullSide) -> HullBreach:
	if _breaches.size() >= max_open_breaches:
		return null
	var free_cells: Array[Vector2i] = []
	for cell: Vector2i in _hull_cells[side]:
		if not _breaches.has(cell):
			free_cells.append(cell)
	if free_cells.is_empty():
		return null
	var cell: Vector2i = free_cells.pick_random()
	var breach: HullBreach = breach_scene.instantiate() as HullBreach
	breach.setup(cell, Vector2(SIDE_DIRECTIONS[side]))
	add_child(breach)
	breach.global_position = tile_map.to_global(tile_map.map_to_local(cell))
	breach.repaired.connect(_on_breach_repaired)
	_breaches[cell] = breach
	breach_opened.emit(breach)
	return breach

func _on_asteroid_hit(asteroid: BridgeAsteroid) -> void:
	open_breach(get_hit_side(asteroid))

func _on_breach_repaired(breach: HullBreach) -> void:
	_breaches.erase(breach.cell)
	breach_closed.emit(breach)

## Sorts every wall cell with empty space on one side and floor on the opposite side by the side it faces.
func _find_hull_cells() -> void:
	for cell: Vector2i in tile_map.get_used_cells():
		if _is_floor(cell):
			continue
		for side: HullSide in SIDE_DIRECTIONS:
			var outward: Vector2i = SIDE_DIRECTIONS[side]
			if tile_map.get_cell_source_id(cell + outward) == -1 and _is_floor(cell - outward):
				_hull_cells[side].append(cell)

func _is_floor(cell: Vector2i) -> bool:
	var data: TileData = tile_map.get_cell_tile_data(cell)
	return data != null and data.get_collision_polygons_count(0) == 0
