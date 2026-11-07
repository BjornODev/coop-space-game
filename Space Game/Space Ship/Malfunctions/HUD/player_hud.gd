## One player's HUD: all four failure meters, arrows toward off-screen malfunctions, and the mission failed screen.
## The game makes one per player and draws it into that player's splitscreen viewport through custom_viewport,
## so the Framework's viewports don't need any changes. Keeps running while the game is paused.
class_name PlayerHud extends CanvasLayer

## Emitted when this player asks to restart from the mission failed screen.
signal restart_requested

## Scene instanced for each alert arrow. Its root must have the AlertArrow script.
@export var alert_arrow_scene: PackedScene
## Distance from the screen edge to the alert arrows, in pixels.
@export var arrow_edge_margin: float = 56.0
## A malfunction counts as on screen, and gets no arrow, once it is this many pixels inside the screen edge.
@export var on_screen_margin: float = 24.0

@onready var _root: Control = $Root
@onready var _arrow_layer: Node2D = $Root/Arrows
@onready var _failed_screen: MissionFailedScreen = $Root/MissionFailedScreen
## One row per meter, in the order of Malfunction.ALL_TYPES.
@onready var _meter_rows: Array[MeterRow] = [
	$Root/MeterPanel/Meters/FireRow,
	$Root/MeterPanel/Meters/OxygenRow,
	$Root/MeterPanel/Meters/CommsRow,
	$Root/MeterPanel/Meters/HullRow,
]

var _manager: MalfunctionManager = null
var _player: Player = null
var _player_viewport: Viewport = null
var _arrows: Array[AlertArrow] = []

func _ready() -> void:
	_failed_screen.visible = false
	_failed_screen.restart_pressed.connect(_on_restart_pressed)

## Connects the HUD to the meters and to the player it belongs to. player_viewport is the splitscreen viewport
## showing that player's camera. Call after adding the HUD to the tree.
func setup(manager: MalfunctionManager, player: Player, player_viewport: Viewport) -> void:
	_manager = manager
	_player = player
	_player_viewport = player_viewport
	custom_viewport = player_viewport
	for i: int in Malfunction.ALL_TYPES.size():
		var type: Malfunction.Type = Malfunction.ALL_TYPES[i]
		_meter_rows[i].setup(manager.get_display_name(type), manager.get_color(type))

func _process(_delta: float) -> void:
	if _manager == null or _player_viewport == null or not is_instance_valid(_player):
		return
	var screen_size: Vector2 = _player_viewport.get_visible_rect().size
	_root.size = screen_size
	for i: int in Malfunction.ALL_TYPES.size():
		var type: Malfunction.Type = Malfunction.ALL_TYPES[i]
		_meter_rows[i].show_value(_manager.get_meter(type), _manager.get_countdown_text(type))

	if _failed_screen.visible:
		_hide_arrows_from(0)
		if Input.is_action_just_pressed(CoopInput.get_player(_player.player_number).A):
			restart_requested.emit()
		return
	_update_arrows(screen_size)

## Covers this player's screen with the mission failed screen for the meter that filled.
func show_mission_failed(type: Malfunction.Type) -> void:
	var input: PlayerInput = CoopInput.get_player(_player.player_number) if is_instance_valid(_player) else null
	_failed_screen.show_failure(_manager.get_display_name(type), _manager.get_color(type), input)

## Places one arrow on the screen edge for every malfunction that is off this player's screen.
func _update_arrows(screen_size: Vector2) -> void:
	var canvas: Transform2D = _player_viewport.get_canvas_transform()
	var screen_rect: Rect2 = Rect2(Vector2.ZERO, screen_size)
	var visible_rect: Rect2 = screen_rect.grow(-on_screen_margin)
	var arrow_rect: Rect2 = screen_rect.grow(-arrow_edge_margin)
	var center: Vector2 = screen_size * 0.5
	var half: Vector2 = arrow_rect.size * 0.5
	var used: int = 0
	for target: AlertTarget in _manager.get_alert_targets(_player.global_position):
		var screen_position: Vector2 = canvas * target.position
		if visible_rect.has_point(screen_position):
			continue
		var direction: Vector2 = center.direction_to(screen_position)
		if direction == Vector2.ZERO:
			continue
		# slide out from the center along direction until reaching the arrow rectangle's edge
		var reach_x: float = half.x / absf(direction.x) if not is_zero_approx(direction.x) else INF
		var reach_y: float = half.y / absf(direction.y) if not is_zero_approx(direction.y) else INF
		var arrow: AlertArrow = _get_arrow(used)
		used += 1
		arrow.position = center + direction * minf(reach_x, reach_y)
		arrow.show_alert(direction.angle(), _manager.get_color(target.type), _manager.get_countdown_text(target.type))
	_hide_arrows_from(used)

## The arrow at index, creating more arrows as needed.
func _get_arrow(index: int) -> AlertArrow:
	while _arrows.size() <= index:
		var arrow: AlertArrow = alert_arrow_scene.instantiate() as AlertArrow
		_arrow_layer.add_child(arrow)
		_arrows.append(arrow)
	return _arrows[index]

func _hide_arrows_from(index: int) -> void:
	for i: int in range(index, _arrows.size()):
		_arrows[i].visible = false

func _on_restart_pressed() -> void:
	restart_requested.emit()
