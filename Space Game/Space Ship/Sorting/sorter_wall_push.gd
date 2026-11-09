## Keeps ore in the sorter from getting stuck on the walls. Ore near a wall is gently pushed back toward open floor,
## and ore in the sorter slides along walls instead of sticking to them.
## Ore near the suction ports isn't pushed, so it can still be pushed into them.
class_name SorterWallPush extends Node

## The sorter's walls.
@export var tile_map: TileMapLayer
## The node the ore is spawned under.
@export var item_parent: Node
## Ore within this many pixels of a wall, measured from the ore's center, is pushed away from it.
@export var push_distance: float = 64.0
## Push at the wall itself, in pixels per second squared. Fades to 0 at push_distance.
@export var push_strength: float = 900.0
## Ore within exempt_radius of these nodes (the suction ports) isn't pushed.
@export var exempt_nodes: Array[Node2D] = []
## See exempt_nodes. In pixels.
@export var exempt_radius: float = 110.0
## Friction of ore in the sorter. 0 lets ore slide along walls.
@export var item_friction: float = 0.0
## Bounciness of ore in the sorter.
@export_range(0.0, 1.0) var item_bounce: float = 0.3

var _material: PhysicsMaterial = null

func _ready() -> void:
	_material = PhysicsMaterial.new()
	_material.friction = item_friction
	_material.bounce = item_bounce
	if item_parent == null or tile_map == null:
		push_warning("SorterWallPush needs a tile_map and an item_parent.")
		return
	item_parent.child_entered_tree.connect(_on_item_added)
	for child: Node in item_parent.get_children():
		_on_item_added(child)

func _physics_process(_delta: float) -> void:
	if item_parent == null or tile_map == null:
		return
	for child: Node in item_parent.get_children():
		if child is PhysicsItem:
			_push_away_from_walls(child)

func _on_item_added(node: Node) -> void:
	if node is PhysicsItem:
		(node as PhysicsItem).physics_material_override = _material

func _push_away_from_walls(item: PhysicsItem) -> void:
	for exempt: Node2D in exempt_nodes:
		if exempt.global_position.distance_to(item.global_position) < exempt_radius:
			return
	var local: Vector2 = tile_map.to_local(item.global_position)
	var cell: Vector2i = tile_map.local_to_map(local)
	var tile_size: Vector2 = Vector2(tile_map.tile_set.tile_size)
	var reach: int = ceili(push_distance / minf(tile_size.x, tile_size.y))
	var push: Vector2 = Vector2.ZERO
	for x: int in range(-reach, reach + 1):
		for y: int in range(-reach, reach + 1):
			var wall_cell: Vector2i = cell + Vector2i(x, y)
			if not _is_wall(wall_cell):
				continue
			var wall_center: Vector2 = tile_map.map_to_local(wall_cell)
			var wall_rect: Rect2 = Rect2(wall_center - tile_size * 0.5, tile_size)
			var away: Vector2 = local - local.clamp(wall_rect.position, wall_rect.end)
			var distance: float = away.length()
			if distance >= push_distance:
				continue
			if is_zero_approx(distance):
				# the ore's center is inside the wall tile, so push out from the tile's center
				away = local - wall_center
			push += away.normalized() * (1.0 - distance / push_distance)
	if push == Vector2.ZERO:
		return
	var global_push: Vector2 = tile_map.global_transform.basis_xform(push.limit_length(1.0))
	item.apply_central_force(global_push * push_strength * item.mass)

func _is_wall(cell: Vector2i) -> bool:
	var data: TileData = tile_map.get_cell_tile_data(cell)
	return data != null and data.get_collision_polygons_count(0) > 0
