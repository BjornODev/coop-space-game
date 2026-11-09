## One burning floor tile. FireSystem creates, damages, and frees these; don't place them by hand.
## The origin is the tile's center.
class_name FireTile extends Node2D

## How fast the flames flicker, in cycles per second.
@export var flicker_speed: float = 5.0
## How much the flames grow and shrink while flickering, as a fraction of their size.
@export var flicker_amount: float = 0.12
## Hide the health bar until the tile has taken damage.
@export var hide_health_bar_when_full: bool = true

@onready var _flames: Node2D = $Flames
@onready var _health_bar: ProgressBar = $HealthBar
@onready var _countdown_label: Label = $CountdownLabel

## The tilemap cell this fire is on.
var cell: Vector2i = Vector2i.ZERO
var max_health: float = 100.0
var health: float = 100.0
## Seconds until this tile next tries to spread. FireSystem counts it down.
var spread_time_left: float = 0.0

var _flicker_time: float = 0.0

func _ready() -> void:
	# start each tile at a different point in the flicker so neighbors don't pulse together
	_flicker_time = randf() * TAU
	_update_health_bar()

func _process(delta: float) -> void:
	_flicker_time += delta * flicker_speed * TAU
	_flames.scale = Vector2.ONE * (1.0 + sin(_flicker_time) * flicker_amount)

## Sets the tile up before it is added to the tree.
func setup(new_cell: Vector2i, new_max_health: float, first_spread_time: float) -> void:
	cell = new_cell
	max_health = new_max_health
	health = new_max_health
	spread_time_left = first_spread_time

## Removes amount of health. Returns true once the fire is out.
func damage(amount: float) -> bool:
	health = maxf(health - amount, 0.0)
	_update_health_bar()
	return health <= 0.0

func set_countdown_text(text: String) -> void:
	_countdown_label.text = text

func _update_health_bar() -> void:
	if _health_bar == null:
		return
	_health_bar.max_value = max_health
	_health_bar.value = health
	_health_bar.visible = not (hide_health_bar_when_full and health >= max_health)
