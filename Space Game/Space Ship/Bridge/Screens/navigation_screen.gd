## Bridge screen for flying the ship. One player at a time.
## The stick turns the ship, holding A boosts along the heading, holding X pushes backwards, Y switches between the route map and the
## heading-up radar, and B leaves. The ship only changes speed while thrusting and coasts the rest of the time,
## including when nobody is using this screen.
## The screen is small in the world. Text and prompts only show while someone is using it and the camera is zoomed in.
class_name NavigationScreen extends Interactable

## Emitted when the screen switches between the route map and the radar.
signal view_changed(view: View)
## emitted when the player presses to use the fuel for the first time
signal requesting_boost(status : bool)

enum View { ROUTE, RADAR }

## The simulation this screen flies and displays.
@export var simulation: SpaceSimulation
## View shown when the game starts.
@export var starting_view: View = View.ROUTE
## Boost label color while boosting.
@export var boost_on_color: Color = Color(1.0, 0.5, 0.0)
## Boost label color while not boosting.
@export var boost_off_color: Color = Color(0.35, 0.35, 0.35)
## Reverse label color while reversing.
@export var reverse_on_color: Color = Color(0.0, 0.8, 1.0)
## Reverse label color while not reversing.
@export var reverse_off_color: Color = Color(0.35, 0.35, 0.35)

@onready var _route_view: RouteView = $Display/RouteView
@onready var _radar: RadarDisplay = $Display/RadarDisplay
@onready var _details: Control = $Display/Details
@onready var _idle_label: Label = $Display/IdleLabel
@onready var _view_label: Label = $Display/Details/ViewLabel
@onready var _speed_label: Label = $Display/Details/Side/SpeedLabel
@onready var _distance_label: Label = $Display/Details/Side/DistanceLabel
@onready var fuel_label: Label = $Display/Details/Side/FuelLabel
@onready var _boost_label: Label = $Display/Details/Side/BoostLabel
@onready var _reverse_label: Label = $Display/Details/Side/ReverseLabel
@onready var _steer_prompt: ButtonPrompt = $Display/Details/Side/SteerPrompt
@onready var _boost_prompt: ButtonPrompt = $Display/Details/Side/BoostPrompt
@onready var _reverse_prompt: ButtonPrompt = $Display/Details/Side/ReversePrompt
@onready var _view_prompt: ButtonPrompt = $Display/Details/Side/ViewPrompt
@onready var _exit_prompt: ButtonPrompt = $Display/Details/Side/ExitPrompt

var _view: View = View.ROUTE
## Boost only works after A has been let go once, so the press that opened this screen doesn't boost.
var _boost_armed: bool = false

func _ready() -> void:
	if simulation == null:
		push_warning("NavigationScreen has no simulation assigned.")
	_route_view.set_simulation(simulation)
	_radar.set_simulation(simulation)
	_set_view(starting_view)
	_show_details_for(null)

func _process(_delta: float) -> void:
	if simulation == null or not _details.visible:
		return
	var boosting: bool = simulation.is_boosting()
	_speed_label.text = "Speed: %d" % roundi(simulation.get_ship_speed())
	if simulation.has_arrived():
		_distance_label.text = "Arrived at B"
	else:
		_distance_label.text = "To B: %d" % roundi(simulation.get_distance_to_destination())
	_boost_label.modulate = boost_on_color if boosting else boost_off_color
	_boost_prompt.set_active(boosting)
	var reversing: bool = simulation.is_reversing()
	_reverse_label.modulate = reverse_on_color if reversing else reverse_off_color
	_reverse_prompt.set_active(reversing)

#region Interactable hooks

func _on_interaction_started(_player: Player) -> void:
	_boost_armed = false
	_show_details_for(get_player_input())

func _on_interaction_ended(_player: Player) -> void:
	if is_instance_valid(simulation):
		simulation.clear_pilot_input()
	_steer_prompt.set_active(false)
	_view_prompt.set_active(false)
	_show_details_for(null)

func _interaction_process(_player: Player, _delta: float) -> void:
	var input: PlayerInput = get_player_input()
	if Input.is_action_just_pressed(input.B):
		end_interaction()
		return
	if Input.is_action_just_pressed(input.Y):
		toggle_view()
	_view_prompt.set_active(Input.is_action_pressed(input.Y))

	var boost_held: bool = Input.is_action_pressed(input.A)
	if not boost_held:
		_boost_armed = true
	
	if Input.is_action_just_pressed(input.A) and boost_held:
		emit_signal("requesting_boost",true)
	elif Input.is_action_just_released(input.A):
		emit_signal("requesting_boost",false)
	elif Input.is_action_just_pressed(input.X):
		emit_signal("requesting_boost",true)
	elif Input.is_action_just_released(input.X):
		emit_signal("requesting_boost",false)
	
	var turn: float = Input.get_axis(input.LEFT, input.RIGHT)
	simulation.set_pilot_input(turn, boost_held and _boost_armed, Input.is_action_pressed(input.X))
	_steer_prompt.set_active(not is_zero_approx(turn))

#endregion

## Switches between the route map and the radar.
func toggle_view() -> void:
	_set_view(View.RADAR if _view == View.ROUTE else View.ROUTE)

func get_view() -> View:
	return _view

func _set_view(view: View) -> void:
	_view = view
	_route_view.visible = view == View.ROUTE
	_radar.visible = view == View.RADAR
	_view_label.text = "ROUTE VIEW" if view == View.ROUTE else "RADAR VIEW"
	view_changed.emit(view)

## Shows the detailed readouts with input's keys on the prompts, or the simple idle look when input is null.
func _show_details_for(input: PlayerInput) -> void:
	_details.visible = input != null
	_idle_label.visible = input == null
	if input == null:
		return
	_steer_prompt.show_for_actions([input.LEFT, input.RIGHT])
	_boost_prompt.show_for_actions([input.A])
	_reverse_prompt.show_for_actions([input.X])
	_view_prompt.show_for_actions([input.Y])
	_exit_prompt.show_for_actions([input.B])
