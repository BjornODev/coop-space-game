## One player's guide arrow. While the player carries ore or a canister, an arrow shows where to take it:
## ore goes to the refinery's input, a canister that isn't full goes to the capsule filling terminal,
## and a full canister goes to an empty engine slot.
## When the destination is off screen the arrow sits on the screen edge; on screen it hovers over the destination.
## The game makes one per player and draws it into that player's splitscreen viewport through custom_viewport.
class_name GuideHud extends CanvasLayer

## Scene instanced for the arrow. Its root must have the AlertArrow script.
@export var arrow_scene: PackedScene
## Distance from the screen edge to the arrow, in pixels.
@export var arrow_edge_margin: float = 56.0
## A destination counts as on screen once it is this many pixels inside the screen edge.
@export var on_screen_margin: float = 24.0
## How far above an on-screen destination the arrow hovers, in pixels on screen.
@export var hover_height: float = 70.0
## How far the hovering arrow bobs up and down, in pixels.
@export var bob_distance: float = 8.0
## How fast the hovering arrow bobs, in radians per second.
@export var bob_speed: float = 5.0

@export_group("Items")
## Status of ore that goes to the refinery.
@export var ore_status: String = ShipItems.STATUS_UNREFINED
## Status of canisters.
@export var canister_status: String = "capsule"
## A canister with at least this much Purity counts as full and goes to the engine.
@export var full_canister_amount: float = 100.0

@export_group("Look")
@export var ore_color: Color = Color(1.0, 0.6, 0.2)
@export var canister_color: Color = Color(0.3, 0.85, 1.0)
@export var refinery_text: String = "Refinery"
@export var filling_text: String = "Fill Canister"
@export var engine_text: String = "Engine"

@onready var _arrow_layer: Node2D = $Root/Arrows

var _player: Player = null
var _player_viewport: Viewport = null
var _refinery_input: Node2D = null
var _filling_terminal: Node2D = null
var _engine: Node2D = null
var _arrow: AlertArrow = null
var _time: float = 0.0

## Connects the HUD to its player and the stations it points at. player_viewport is the splitscreen viewport
## showing that player's camera. engine is the EngineUnit, whose empty capsule slots are pointed at.
## Call after adding the HUD to the tree.
func setup(player: Player, player_viewport: Viewport, refinery_input: Node2D, filling_terminal: Node2D, engine: Node2D) -> void:
	_player = player
	_player_viewport = player_viewport
	custom_viewport = player_viewport
	_refinery_input = refinery_input
	_filling_terminal = filling_terminal
	_engine = engine
	_arrow = arrow_scene.instantiate() as AlertArrow
	_arrow_layer.add_child(_arrow)
	_arrow.visible = false

func _process(delta: float) -> void:
	if _arrow == null or _player_viewport == null or not is_instance_valid(_player):
		return
	_time += delta
	var held: Dictionary = _player.item_manager.item_being_held
	if ShipItems.has_status(held, ore_status) and _refinery_input != null:
		_point_at(_refinery_input.global_position, ore_color, refinery_text)
	elif ShipItems.has_status(held, canister_status):
		if float(held.get("Purity", 0.0)) >= full_canister_amount and _engine != null:
			_point_at(_get_engine_slot_position(), canister_color, engine_text)
		elif _filling_terminal != null:
			_point_at(_filling_terminal.global_position, canister_color, filling_text)
		else:
			_arrow.visible = false
	else:
		_arrow.visible = false

## Shows the arrow toward world_position: on the screen edge when it is off screen, hovering over it when on screen.
func _point_at(world_position: Vector2, color: Color, text: String) -> void:
	var screen_size: Vector2 = _player_viewport.get_visible_rect().size
	var screen_position: Vector2 = _player_viewport.get_canvas_transform() * world_position
	var screen_rect: Rect2 = Rect2(Vector2.ZERO, screen_size)
	if screen_rect.grow(-on_screen_margin).has_point(screen_position):
		var bob: float = sin(_time * bob_speed) * bob_distance
		_arrow.position = screen_position + Vector2(0.0, -hover_height + bob)
		_arrow.show_alert(PI * 0.5, color, text)
		return
	var arrow_rect: Rect2 = screen_rect.grow(-arrow_edge_margin)
	if arrow_rect.get_center().is_equal_approx(screen_position):
		_arrow.visible = false
		return
	_arrow.position = AlertArrow.get_edge_position(arrow_rect, screen_position)
	_arrow.show_alert(arrow_rect.get_center().angle_to_point(screen_position), color, text)

## The nearest engine capsule slot with no canister in it, or the engine itself when every slot is taken.
func _get_engine_slot_position() -> Vector2:
	var best: Vector2 = _engine.global_position
	var best_distance: float = INF
	for slot: Control in _engine.capsules:
		if slot.capsule["Activated"]:
			continue
		var slot_position: Vector2 = (slot.capsule_grabber as Node2D).global_position
		var distance: float = slot_position.distance_squared_to(_player.global_position)
		if distance < best_distance:
			best_distance = distance
			best = slot_position
	return best
