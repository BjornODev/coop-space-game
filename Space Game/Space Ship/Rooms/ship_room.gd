## One room of the ship: a rectangle of floor cells on the ship tilemap, with its name painted on the floor.
## Keep this node at the tilemap's origin so tile_rect lines up with the tiles.
## FireSystem groups burning tiles by room, for alert arrows and for the director's malfunction count.
@tool
class_name ShipRoom extends Node2D

## Name shown on the floor.
@export var room_name: String = "Room":
	set(value):
		room_name = value
		_update_label()
## The room's floor cells on the ship tilemap, not counting its walls.
@export var tile_rect: Rect2i = Rect2i(0, 0, 8, 8):
	set(value):
		tile_rect = value
		_update_label()
## Size of one tile in pixels. Must match the ship tilemap.
@export var tile_size: int = 64
## Where the name sits, relative to the room's top left corner, in pixels.
@export var label_offset: Vector2 = Vector2(16.0, 8.0)

@onready var _label: Label = $NameLabel

func _ready() -> void:
	_update_label()

## True if cell is one of this room's floor cells.
func has_cell(cell: Vector2i) -> bool:
	return tile_rect.has_point(cell)

## Center of the room in cell coordinates.
func get_center_cell() -> Vector2:
	return Vector2(tile_rect.position) + Vector2(tile_rect.size) * 0.5

func _update_label() -> void:
	if _label == null:
		return
	_label.text = room_name
	_label.position = Vector2(tile_rect.position * tile_size) + label_offset
