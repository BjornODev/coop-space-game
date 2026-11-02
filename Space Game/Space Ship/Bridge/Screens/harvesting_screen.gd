## Bridge screen for the ship's suction arm. One player at a time.
## Stick left and right swings the arm, stick up extends it and stick down retracts it. Holding A runs suction,
## and B leaves. The arm holds its angle and length when nobody is using this screen.
## Captured asteroids come out of SpaceSimulation.asteroid_harvested.
## The screen is small in the world. Text and prompts only show while someone is using it and the camera is zoomed in.
class_name HarvestingScreen extends Interactable

## The simulation this screen controls and displays.
@export var simulation: SpaceSimulation
## Suction label color while suction is on.
@export var suction_on_color: Color = Color(0.2, 1.0, 0.9)
## Suction label color while suction is off.
@export var suction_off_color: Color = Color(0.35, 0.35, 0.35)

@onready var _radar: RadarDisplay = $Display/RadarDisplay
@onready var _details: Control = $Display/Details
@onready var _idle_label: Label = $Display/IdleLabel
@onready var _suction_label: Label = $Display/Details/Side/SuctionLabel
@onready var _pulling_label: Label = $Display/Details/Side/PullingLabel
@onready var _captured_label: Label = $Display/Details/Side/CapturedLabel
@onready var _arm_prompt: ButtonPrompt = $Display/Details/Side/ArmPrompt
@onready var _suction_prompt: ButtonPrompt = $Display/Details/Side/SuctionPrompt
@onready var _exit_prompt: ButtonPrompt = $Display/Details/Side/ExitPrompt

## Suction only works after A has been let go once, so the press that opened this screen doesn't start it.
var _suction_armed: bool = false
## Asteroids captured so far this run.
var _captured_count: int = 0

func _ready() -> void:
	if simulation == null:
		push_warning("HarvestingScreen has no simulation assigned.")
	else:
		simulation.asteroid_harvested.connect(_on_asteroid_harvested)
		simulation.run_started.connect(_on_run_started)
	_radar.set_simulation(simulation)
	_show_details_for(null)

func _process(_delta: float) -> void:
	if simulation == null or not _details.visible:
		return
	var suction: bool = simulation.is_suction_active()
	_suction_label.text = "SUCTION ON" if suction else "SUCTION OFF"
	_suction_label.modulate = suction_on_color if suction else suction_off_color
	_suction_prompt.set_active(suction)
	_pulling_label.text = "Pulling: %d" % simulation.get_pulled_asteroid_count()
	_captured_label.text = "Captured: %d" % _captured_count

#region Interactable hooks

func _on_interaction_started(_player: Player) -> void:
	_suction_armed = false
	_show_details_for(get_player_input())

func _on_interaction_ended(_player: Player) -> void:
	if is_instance_valid(simulation):
		simulation.clear_arm_input()
	_arm_prompt.set_active(false)
	_suction_prompt.set_active(false)
	_show_details_for(null)

func _interaction_process(_player: Player, _delta: float) -> void:
	var input: PlayerInput = get_player_input()
	if Input.is_action_just_pressed(input.B):
		end_interaction()
		return
	var suction_held: bool = Input.is_action_pressed(input.A)
	if not suction_held:
		_suction_armed = true
	var swing: float = Input.get_axis(input.LEFT, input.RIGHT)
	var extend: float = Input.get_axis(input.DOWN, input.UP)
	simulation.set_arm_input(swing, extend, suction_held and _suction_armed)
	_arm_prompt.set_active(not is_zero_approx(swing) or not is_zero_approx(extend))

#endregion

func _on_asteroid_harvested(_data: Dictionary) -> void:
	_captured_count += 1

func _on_run_started() -> void:
	_captured_count = 0

## Shows the readouts with input's keys on the prompts, or the simple idle look when input is null.
func _show_details_for(input: PlayerInput) -> void:
	_details.visible = input != null
	_idle_label.visible = input == null
	if input == null:
		return
	_arm_prompt.show_for_actions([input.UP, input.LEFT, input.DOWN, input.RIGHT])
	_suction_prompt.show_for_actions([input.A])
	_exit_prompt.show_for_actions([input.B])
