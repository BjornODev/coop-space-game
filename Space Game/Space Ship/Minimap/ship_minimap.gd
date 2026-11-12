## A shared map of the ship, drawn once on the whole window between the splitscreen views:
## at the center where the views meet with 2 or 4 players, in the empty quadrant with 3, and in a corner with 1.
## Shows every room with its name, the corridors between them as a faint shape, and each player as an arrow in
## their suit tint pointing the way they face, with no box around it. A layout without rooms shows the ship's
## floor and walls instead.
## North stays up, like the world. Hidden while the game is paused.
class_name ShipMinimap extends CanvasLayer

## The ship tilemaps of both layouts. Whichever one the game keeps is drawn.
@export var tile_maps: Array[TileMapLayer] = []
## Parent of the ShipRoom nodes to outline and label. Optional: the small ship layout has no rooms.
@export var rooms_root: Node

@export_group("Size")
## Height of the map as a fraction of the window, with 2 or 4 players.
@export_range(0.1, 0.6) var height_fraction: float = 0.34
## Height of the map as a fraction of the window with 1 player, in the corner.
@export_range(0.1, 0.6) var single_player_height_fraction: float = 0.34
## Largest share of the empty quadrant the map fills with 3 players.
@export_range(0.3, 1.0) var empty_quadrant_fill: float = 0.85
## Gap between the map and the window edge with 1 player, in pixels.
@export var corner_margin: float = 16.0
## Space around the rooms inside the map's area, in pixels, so arrows at the edge aren't cut off.
@export var padding: float = 8.0

@export_group("Look")
## Floor and wall colors, used only on a layout without rooms.
@export var floor_color: Color = Color(0.22, 0.26, 0.32)
@export var wall_color: Color = Color(0.55, 0.6, 0.68)
## Floor outside the rooms (the corridors). Faint, so the rooms stand out.
@export var corridor_color: Color = Color(0.6, 0.75, 0.95, 0.3)
## Rooms are nearly opaque, since there's no box behind them to separate them from the game.
@export var room_fill_color: Color = Color(0.1, 0.14, 0.22, 0.9)
@export var room_outline_color: Color = Color(0.6, 0.75, 0.95)
@export var room_outline_width: float = 2.0
@export var room_label_color: Color = Color(0.92, 0.95, 1.0)
## Largest and smallest font size for room names. Names shrink and wrap to fit their room.
@export var max_label_size: int = 14
@export var min_label_size: int = 8
## Length of a player arrow, in pixels.
@export var marker_size: float = 16.0
@export var marker_outline_color: Color = Color(0.05, 0.05, 0.08)

@onready var _frame: Control = $Frame
@onready var _map: Control = $Frame/Map
@onready var _markers: Control = $Frame/Markers

var _tile_map: TileMapLayer = null
var _rooms: Array[ShipRoom] = []
var _floor_cells: Array[Vector2i] = []
var _wall_cells: Array[Vector2i] = []
## The ship's extent in world pixels.
var _world_bounds: Rect2 = Rect2()
var _cell_world_size: Vector2 = Vector2.ONE
## World pixels to map pixels.
var _scale: float = 1.0
var _offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	# draws on the window itself instead of the first player's view, so it sits between all the views
	custom_viewport = get_tree().root
	_frame.visible = false
	for layer: Control in [_map, _markers]:
		layer.offset_left = padding
		layer.offset_top = padding
		layer.offset_right = -padding
		layer.offset_bottom = -padding
	_map.draw.connect(_draw_map)
	_markers.draw.connect(_draw_markers)
	_map.resized.connect(_update_transform)
	# the game removes the unused layout in its own _ready, which runs after this one
	_collect_ship.call_deferred()

func _process(_delta: float) -> void:
	var player_count: int = _get_player_count()
	_frame.visible = _tile_map != null and player_count > 0 and not get_tree().paused
	if not _frame.visible:
		return
	_place_frame(player_count)
	_markers.queue_redraw()

func _collect_ship() -> void:
	for tile_map: TileMapLayer in tile_maps:
		if is_instance_valid(tile_map) and tile_map.is_inside_tree():
			_tile_map = tile_map
			break
	if _tile_map == null:
		push_warning("ShipMinimap has no ship tilemap in the scene.")
		return
	_floor_cells.clear()
	_wall_cells.clear()
	for cell: Vector2i in _tile_map.get_used_cells():
		var data: TileData = _tile_map.get_cell_tile_data(cell)
		if data == null:
			continue
		# same test as the fire and hull systems: tiles with collision are walls
		if data.get_collision_polygons_count(0) == 0:
			_floor_cells.append(cell)
		else:
			_wall_cells.append(cell)
	_cell_world_size = Vector2(_tile_map.tile_set.tile_size) * _tile_map.global_scale
	_rooms.clear()
	if is_instance_valid(rooms_root) and rooms_root.is_inside_tree():
		for child: Node in rooms_root.get_children():
			if child is ShipRoom:
				_rooms.append(child)
	if _rooms.is_empty():
		var used: Rect2i = _tile_map.get_used_rect()
		_world_bounds = Rect2(_cell_to_world_corner(used.position), Vector2(used.size) * _cell_world_size)
	else:
		# rooms and corridors are drawn, but not the outer walls, so the map fits tightly around the floor
		_world_bounds = _get_room_world_rect(_rooms[0])
		for room: ShipRoom in _rooms:
			_world_bounds = _world_bounds.merge(_get_room_world_rect(room))
		for cell: Vector2i in _floor_cells:
			_world_bounds = _world_bounds.expand(_cell_to_world_corner(cell)).expand(_cell_to_world_corner(cell) + _cell_world_size)
	_update_transform()

#region Layout

func _get_player_count() -> int:
	var game: Game = get_parent() as Game
	return game.number_of_players if game != null else 0

## Sizes the frame to the ship's shape and places it for player_count.
func _place_frame(player_count: int) -> void:
	var window: Vector2 = get_tree().root.get_visible_rect().size
	var aspect: float = _world_bounds.size.x / _world_bounds.size.y if _world_bounds.size.y > 0.0 else 1.0
	var size: Vector2
	var center: Vector2
	if player_count == 3:
		# the bottom right view is unused with 3 players, so the map gets that whole quadrant
		var quadrant: Vector2 = window * 0.5
		size = _fit(quadrant * empty_quadrant_fill, aspect)
		center = window * 0.75
	elif player_count == 1:
		var height: float = window.y * single_player_height_fraction
		size = _fit(Vector2(window.x * 0.4, height), aspect)
		center = window - size * 0.5 - Vector2.ONE * corner_margin
	else:
		size = _fit(Vector2(window.x * 0.4, window.y * height_fraction), aspect)
		center = window * 0.5
	_frame.size = size
	_frame.position = (center - size * 0.5).round()

## The largest frame inside bounds whose drawing area has the ship's aspect ratio.
func _fit(bounds: Vector2, aspect: float) -> Vector2:
	var inner: Vector2 = bounds - Vector2.ONE * padding * 2.0
	if inner.x / inner.y > aspect:
		inner.x = inner.y * aspect
	else:
		inner.y = inner.x / aspect
	return (inner + Vector2.ONE * padding * 2.0).floor()

func _update_transform() -> void:
	if _world_bounds.size.x <= 0.0 or _world_bounds.size.y <= 0.0:
		return
	var area: Vector2 = _map.size
	_scale = minf(area.x / _world_bounds.size.x, area.y / _world_bounds.size.y)
	_offset = (area - _world_bounds.size * _scale) * 0.5
	_map.queue_redraw()

func _world_to_map(world: Vector2) -> Vector2:
	return _offset + (world - _world_bounds.position) * _scale

func _cell_to_world_corner(cell: Vector2i) -> Vector2:
	return _tile_map.to_global(_tile_map.map_to_local(cell)) - _cell_world_size * 0.5

#endregion

#region Drawing

func _draw_map() -> void:
	if _tile_map == null:
		return
	# a hair larger than a cell so neighboring cells don't leave seams
	var cell_size: Vector2 = _cell_world_size * _scale + Vector2.ONE * 0.5
	if _rooms.is_empty():
		for cell: Vector2i in _floor_cells:
			_map.draw_rect(Rect2(_world_to_map(_cell_to_world_corner(cell)), cell_size), floor_color)
		for cell: Vector2i in _wall_cells:
			_map.draw_rect(Rect2(_world_to_map(_cell_to_world_corner(cell)), cell_size), wall_color)
	else:
		# corridor cells only, at their exact size: overlapping translucent cells would show up as darker lines
		var exact_size: Vector2 = _cell_world_size * _scale
		for cell: Vector2i in _floor_cells:
			if not _is_room_cell(cell):
				_map.draw_rect(Rect2(_world_to_map(_cell_to_world_corner(cell)), exact_size), corridor_color)
	for room: ShipRoom in _rooms:
		if not is_instance_valid(room):
			continue
		var rect: Rect2 = _get_room_map_rect(room)
		_map.draw_rect(rect, room_fill_color)
		_map.draw_rect(rect.grow(-room_outline_width * 0.5), room_outline_color, false, room_outline_width)
		_draw_room_label(room.room_name, rect)

func _is_room_cell(cell: Vector2i) -> bool:
	for room: ShipRoom in _rooms:
		if is_instance_valid(room) and room.has_cell(cell):
			return true
	return false

func _get_room_world_rect(room: ShipRoom) -> Rect2:
	var top_left: Vector2 = room.to_global(Vector2(room.tile_rect.position * room.tile_size))
	var bottom_right: Vector2 = room.to_global(Vector2(room.tile_rect.end * room.tile_size))
	return Rect2(top_left, bottom_right - top_left).abs()

func _get_room_map_rect(room: ShipRoom) -> Rect2:
	var world: Rect2 = _get_room_world_rect(room)
	var a: Vector2 = _world_to_map(world.position)
	var b: Vector2 = _world_to_map(world.end)
	return Rect2(a, b - a).abs()

## Draws text centered along the top of rect, wrapping at spaces and shrinking until it fits.
## The top keeps names clear of players, who mostly stand toward the middle of a room.
## A word that's still too wide at min_label_size spills past the room instead of being cut off.
func _draw_room_label(text: String, rect: Rect2) -> void:
	var font: Font = _map.get_theme_font(&"font", &"Label")
	var room_width: float = rect.size.x - 4.0
	var lines: PackedStringArray = [text]
	var font_size: int = max_label_size
	while font_size >= min_label_size:
		lines = [text]
		if _widest_line(font, lines, font_size) > room_width:
			lines = text.split(" ")
		if _widest_line(font, lines, font_size) <= room_width and lines.size() * font.get_height(font_size) <= rect.size.y:
			break
		font_size -= 1
	font_size = maxi(font_size, min_label_size)
	var line_height: float = font.get_height(font_size)
	var top: float = rect.position.y + 2.0
	for i: int in lines.size():
		var width: float = font.get_string_size(lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var baseline: Vector2 = Vector2(rect.get_center().x - width * 0.5, top + line_height * i + font.get_ascent(font_size)).round()
		# a dark outline keeps names readable over the floor and room colors
		_map.draw_string_outline(font, baseline, lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 3, marker_outline_color)
		_map.draw_string(font, baseline, lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, room_label_color)

func _widest_line(font: Font, lines: PackedStringArray, font_size: int) -> float:
	var widest: float = 0.0
	for line: String in lines:
		widest = maxf(widest, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
	return widest

func _draw_markers() -> void:
	var game: Node = get_parent()
	if game == null:
		return
	for child: Node in game.get_children():
		var player: Player = child as Player
		if player == null:
			continue
		var tint: Color = Player.PLAYER_TINTS[(player.player_number - 1) % Player.PLAYER_TINTS.size()]
		var tip_dir: Vector2 = Vector2.from_angle(player.visuals.rotation)
		var center: Vector2 = _world_to_map(player.global_position)
		var side: Vector2 = tip_dir.orthogonal()
		var points: PackedVector2Array = [
			center + tip_dir * marker_size * 0.6,
			center - tip_dir * marker_size * 0.4 + side * marker_size * 0.4,
			center - tip_dir * marker_size * 0.2,
			center - tip_dir * marker_size * 0.4 - side * marker_size * 0.4,
		]
		_markers.draw_colored_polygon(points, tint)
		points.append(points[0])
		_markers.draw_polyline(points, marker_outline_color, 1.5, true)

#endregion
