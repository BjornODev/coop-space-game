## Bridge screen for scanning asteroids. One player at a time.
## The stick moves a scanning square around a heading-up radar. Holding it over an unscanned asteroid scans it,
## and the fuel number appears next to its blip once done. Progress is kept if the square moves away early. B leaves.
## The screen is small in the world. The square, scan progress, fuel numbers, text and prompts
## only show while someone is using it and the camera is zoomed in.
class_name ScannerScreen extends Interactable

## Emitted when the asteroid being scanned changes, including to null when the square leaves every unscanned asteroid.
signal scan_target_changed(asteroid: BridgeAsteroid)

enum SquareState { IDLE, SEARCHING, SCANNING, ALREADY_SCANNED }

## The simulation this screen scans and displays.
@export var simulation: SpaceSimulation
## Width of the scanning square in radar pixels.
@export var square_size: float = 40.0
## How fast the square moves at full stick, in radar pixels per second.
@export var square_speed: float = 160.0
## Square color while not over an unscanned asteroid.
@export var searching_square_color: Color = Color(1.0, 1.0, 1.0)
## Square color while scanning.
@export var scanning_square_color: Color = Color(0.0, 1.0, 0.0)
## Square color while over asteroids that are all already scanned.
@export var already_scanned_square_color: Color = Color(1.0, 0.5, 0.0)

@onready var _radar: RadarDisplay = $Display/RadarDisplay
@onready var _square: ReferenceRect = $Display/RadarDisplay/ScanSquare
@onready var _details: Control = $Display/Details
@onready var _idle_label: Label = $Display/IdleLabel
@onready var _status_label: Label = $Display/Details/Side/StatusLabel
@onready var _last_scan_label: Label = $Display/Details/Side/LastScanLabel
@onready var _move_prompt: ButtonPrompt = $Display/Details/Side/MovePrompt
@onready var _exit_prompt: ButtonPrompt = $Display/Details/Side/ExitPrompt

## Square center relative to the radar center, in radar pixels. Kept between uses.
var _square_offset: Vector2 = Vector2.ZERO
var _target: BridgeAsteroid = null
var _square_state: SquareState = SquareState.IDLE

func _ready() -> void:
	if simulation == null:
		push_warning("ScannerScreen has no simulation assigned.")
	else:
		simulation.asteroid_scanned.connect(_on_asteroid_scanned)
		simulation.run_started.connect(_on_run_started)
	_radar.set_simulation(simulation)
	_show_details_for(null)

func _process(_delta: float) -> void:
	if not _details.visible:
		return
	_square.size = Vector2.ONE * square_size
	_square.position = _radar.get_center_px() + _square_offset - _square.size * 0.5
	match _square_state:
		SquareState.SEARCHING, SquareState.IDLE:
			_square.border_color = searching_square_color
			_status_label.text = "Move the square onto a blue asteroid"
		SquareState.SCANNING:
			_square.border_color = scanning_square_color
			_status_label.text = "Scanning... %d%%" % floori(_target.get_scan_ratio() * 100.0)
		SquareState.ALREADY_SCANNED:
			_square.border_color = already_scanned_square_color
			_status_label.text = "Already scanned"

#region Interactable hooks

func _on_interaction_started(_player: Player) -> void:
	_square_state = SquareState.SEARCHING
	_show_details_for(get_player_input())

func _on_interaction_ended(_player: Player) -> void:
	_set_target(null)
	_square_state = SquareState.IDLE
	_move_prompt.set_active(false)
	_show_details_for(null)

func _interaction_process(_player: Player, delta: float) -> void:
	var input: PlayerInput = get_player_input()
	if Input.is_action_just_pressed(input.B):
		end_interaction()
		return
	var move: Vector2 = Input.get_vector(input.LEFT, input.RIGHT, input.UP, input.DOWN)
	_square_offset = _clamp_to_radar(_square_offset + move * square_speed * delta)
	_move_prompt.set_active(move != Vector2.ZERO)
	_update_target()
	if _target != null:
		simulation.scan_asteroid(_target, delta)

#endregion

## The asteroid being scanned right now, or null.
func get_scan_target() -> BridgeAsteroid:
	return _target

## Picks the unscanned asteroid under the square nearest its center, and updates the square state to match.
func _update_target() -> void:
	var half: Vector2 = Vector2.ONE * square_size * 0.5
	var square_center: Vector2 = _radar.get_center_px() + _square_offset
	var square_rect: Rect2 = Rect2(square_center - half, half * 2.0)
	var best: BridgeAsteroid = null
	var best_distance: float = INF
	var over_scanned: bool = false
	for asteroid: BridgeAsteroid in simulation.get_asteroids():
		if not _radar.is_in_range(asteroid):
			continue
		var blip_center: Vector2 = _radar.world_to_radar(asteroid.position)
		var closest_point: Vector2 = blip_center.clamp(square_rect.position, square_rect.end)
		if closest_point.distance_to(blip_center) > _radar.get_blip_radius_px(asteroid):
			continue
		if asteroid.is_scanned:
			over_scanned = true
			continue
		var distance: float = blip_center.distance_to(square_center)
		if distance < best_distance:
			best = asteroid
			best_distance = distance
	_set_target(best)
	if best != null:
		_square_state = SquareState.SCANNING
	elif over_scanned:
		_square_state = SquareState.ALREADY_SCANNED
	else:
		_square_state = SquareState.SEARCHING

func _set_target(asteroid: BridgeAsteroid) -> void:
	if asteroid == _target:
		return
	_target = asteroid
	scan_target_changed.emit(asteroid)

## Keeps the whole square inside the radar.
func _clamp_to_radar(offset: Vector2) -> Vector2:
	var limit: float = maxf(_radar.get_radius_px() - square_size * 0.5, 0.0)
	return offset.clamp(Vector2(-limit, -limit), Vector2(limit, limit))

func _on_asteroid_scanned(asteroid: BridgeAsteroid) -> void:
	_last_scan_label.text = "Last scan: %d fuel" % asteroid.fuel

func _on_run_started() -> void:
	_set_target(null)
	_square_state = SquareState.SEARCHING if is_interacting() else SquareState.IDLE
	_last_scan_label.text = "Last scan: none"

## Shows the square, scan details and input's keys on the prompts, or the simple idle look when input is null.
func _show_details_for(input: PlayerInput) -> void:
	var active: bool = input != null
	_details.visible = active
	_square.visible = active
	_radar.show_scan_details = active
	_idle_label.visible = not active
	if not active:
		return
	_move_prompt.show_for_actions([input.UP, input.LEFT, input.DOWN, input.RIGHT])
	_exit_prompt.show_for_actions([input.B])
