## Mission control check-ins. The director calls start_check_in(), and the Comms malfunction stays active while
## any check-in is pending. Several can stack up; each one needs its own code.
## Using the panel shows a code made of face buttons and stick directions. Entering it in order resolves one check-in.
## A wrong input shows an error and makes a new code. Tapping B enters B, and holding B leaves.
## The screen is small in the world. The code, text and prompts only show while someone is using it and the camera is zoomed in.
class_name CommsPanel extends Interactable

## Emitted when mission control asks for a new check-in.
signal check_in_started
## Emitted when a check-in is resolved with a correct code.
signal check_in_resolved
## Emitted when the player enters a wrong input and gets a new code.
signal wrong_input_entered

enum CodeInput { A, B, X, Y, UP, DOWN, LEFT, RIGHT }

## Scene instanced once per step of the code. Its root must be a Label.
@export var code_step_scene: PackedScene
## Number of inputs in each code.
@export_range(1, 12) var code_length: int = 5
## Seconds B has to be held to leave the panel. Letting go sooner enters B.
@export var hold_to_exit_time: float = 0.6
## Seconds the error or success message stays up.
@export var message_time: float = 1.5
@export_group("Colors")
## Code steps already entered.
@export var step_done_color: Color = Color(0.2, 1.0, 0.4)
## The code step to enter next.
@export var step_current_color: Color = Color(1.0, 1.0, 1.0)
## Code steps after the next one.
@export var step_waiting_color: Color = Color(0.5, 0.5, 0.5)
## Message color after a wrong input.
@export var error_color: Color = Color(1.0, 0.25, 0.2)
## Message color after a correct code.
@export var success_color: Color = Color(0.2, 1.0, 0.4)
## Idle label color while a check-in is pending.
@export var pending_color: Color = Color(0.75, 0.45, 1.0)
## Idle label color while nothing is pending.
@export var quiet_color: Color = Color(0.9, 0.9, 0.9)

## Names shown for each input to controller players. Keyboard players see their own keys.
const CONTROLLER_NAMES: Dictionary[CodeInput, String] = {
	CodeInput.A: "A", CodeInput.B: "B", CodeInput.X: "X", CodeInput.Y: "Y",
	CodeInput.UP: "Up", CodeInput.DOWN: "Down", CodeInput.LEFT: "Left", CodeInput.RIGHT: "Right",
}
## Inputs read with just-pressed. B is handled separately because holding it leaves.
const PRESS_INPUTS: Array[CodeInput] = [
	CodeInput.A, CodeInput.X, CodeInput.Y, CodeInput.UP, CodeInput.DOWN, CodeInput.LEFT, CodeInput.RIGHT,
]

@onready var _details: Control = $Display/Details
@onready var _idle_label: Label = $Display/IdleLabel
@onready var _pending_label: Label = $Display/Details/PendingLabel
@onready var _code_row: HBoxContainer = $Display/Details/CodeRow
@onready var _status_label: Label = $Display/Details/StatusLabel
@onready var _exit_bar: ProgressBar = $Display/Details/ExitBar
@onready var _direction_prompt: ButtonPrompt = $Display/Details/Prompts/DirectionPrompt
@onready var _buttons_prompt: ButtonPrompt = $Display/Details/Prompts/ButtonsPrompt
@onready var _exit_prompt: ButtonPrompt = $Display/Details/Prompts/ExitPrompt
@onready var _countdown_label: Label = $CountdownLabel

var _pending_count: int = 0
var _code: Array[CodeInput] = []
## How many steps of the current code have been entered correctly.
var _entered: int = 0
var _b_holding: bool = false
var _b_hold_time: float = 0.0
var _message: String = ""
var _message_color: Color = Color.WHITE
var _message_time_left: float = 0.0

func _ready() -> void:
	_show_details_for(null)

func _process(delta: float) -> void:
	_message_time_left = maxf(_message_time_left - delta, 0.0)
	var pending: bool = _pending_count > 0
	_idle_label.text = "A:\nCHECK-IN!" if pending else "A:\nComms"
	_idle_label.modulate = pending_color if pending else quiet_color
	_countdown_label.visible = pending
	if not _details.visible:
		return
	_pending_label.text = "Check-ins pending: %d" % _pending_count
	if _message_time_left > 0.0:
		_status_label.text = _message
		_status_label.modulate = _message_color
	else:
		_status_label.text = "Enter the code in order" if pending else "No check-in pending"
		_status_label.modulate = Color.WHITE
	_code_row.visible = pending
	_update_code_steps()
	_exit_bar.value = (_b_hold_time / hold_to_exit_time if _b_holding and hold_to_exit_time > 0.0 else 0.0) * _exit_bar.max_value

## Mission control asks for another check-in.
func start_check_in() -> void:
	_pending_count += 1
	if _code.is_empty():
		_new_code()
	check_in_started.emit()

## Number of unresolved check-ins. Each one is an active Comms instance for the comms meter.
func get_pending_count() -> int:
	return _pending_count

## Where alert arrows point while a check-in is pending.
func get_alert_position() -> Vector2:
	return global_position

## Shows text (the time until the comms meter fills) above the panel while a check-in is pending.
func set_countdown_text(text: String) -> void:
	_countdown_label.text = text

#region Interactable hooks

func _on_interaction_started(_player: Player) -> void:
	_entered = 0
	_b_holding = false
	_b_hold_time = 0.0
	_show_details_for(get_player_input())

func _on_interaction_ended(_player: Player) -> void:
	_entered = 0
	_b_holding = false
	_b_hold_time = 0.0
	_show_details_for(null)

func _interaction_process(_player: Player, delta: float) -> void:
	var input: PlayerInput = get_player_input()

	# B is both a code input and the way out: a tap enters B on release, a long hold leaves
	if Input.is_action_just_pressed(input.B):
		_b_holding = true
		_b_hold_time = 0.0
	if _b_holding:
		if Input.is_action_pressed(input.B):
			_b_hold_time += delta
			if _b_hold_time >= hold_to_exit_time:
				end_interaction()
				return
		else:
			_b_holding = false
			_b_hold_time = 0.0
			_enter(CodeInput.B)
	_exit_prompt.set_active(_b_holding)

	for code_input: CodeInput in PRESS_INPUTS:
		if Input.is_action_just_pressed(_get_action(input, code_input)):
			# a wrong input makes a new code, so ignore anything else pressed on the same frame
			if not _enter(code_input):
				break
	_direction_prompt.set_active(Input.get_vector(input.LEFT, input.RIGHT, input.UP, input.DOWN) != Vector2.ZERO)
	_buttons_prompt.set_active(Input.is_action_pressed(input.A) or Input.is_action_pressed(input.X) or Input.is_action_pressed(input.Y))

#endregion

## Checks one input against the code. Returns false if it was wrong.
func _enter(code_input: CodeInput) -> bool:
	if _pending_count <= 0 or _code.is_empty():
		return true
	if code_input != _code[_entered]:
		_show_message("Wrong input! New code incoming.", error_color)
		_new_code()
		wrong_input_entered.emit()
		return false
	_entered += 1
	if _entered >= _code.size():
		_pending_count -= 1
		_show_message("Check-in complete!", success_color)
		check_in_resolved.emit()
		if _pending_count > 0:
			_new_code()
		else:
			_code.clear()
			_entered = 0
			_rebuild_code_steps()
	return true

func _new_code() -> void:
	_code.clear()
	for _i: int in code_length:
		_code.append(CodeInput.values().pick_random())
	_entered = 0
	_rebuild_code_steps()

func _show_message(text: String, color: Color) -> void:
	_message = text
	_message_color = color
	_message_time_left = message_time

func _rebuild_code_steps() -> void:
	for child: Node in _code_row.get_children():
		_code_row.remove_child(child)
		child.queue_free()
	var input: PlayerInput = get_player_input()
	for code_input: CodeInput in _code:
		var step: Label = code_step_scene.instantiate() as Label
		step.text = _get_input_name(input, code_input)
		_code_row.add_child(step)

func _update_code_steps() -> void:
	var steps: Array[Node] = _code_row.get_children()
	for i: int in steps.size():
		var step: Label = steps[i] as Label
		if i < _entered:
			step.modulate = step_done_color
		elif i == _entered:
			step.modulate = step_current_color
		else:
			step.modulate = step_waiting_color

## The action name in input for code_input.
func _get_action(input: PlayerInput, code_input: CodeInput) -> String:
	match code_input:
		CodeInput.A: return input.A
		CodeInput.B: return input.B
		CodeInput.X: return input.X
		CodeInput.Y: return input.Y
		CodeInput.UP: return input.UP
		CodeInput.DOWN: return input.DOWN
		CodeInput.LEFT: return input.LEFT
	return input.RIGHT

## What to show for code_input: the player's keyboard key if they use one, or the controller name.
func _get_input_name(input: PlayerInput, code_input: CodeInput) -> String:
	if input != null:
		var key_name: String = ButtonPrompt.get_key_name(_get_action(input, code_input))
		if not key_name.is_empty():
			return key_name
	return CONTROLLER_NAMES[code_input]

## Shows the details with input's keys on the prompts and code, or the simple idle look when input is null.
func _show_details_for(input: PlayerInput) -> void:
	_details.visible = input != null
	_idle_label.visible = input == null
	if input == null:
		return
	_direction_prompt.show_for_actions([input.UP, input.LEFT, input.DOWN, input.RIGHT])
	_buttons_prompt.show_for_actions([input.A, input.B, input.X, input.Y])
	_exit_prompt.show_for_actions([input.B])
	# the code is shown in this player's own keys
	_rebuild_code_steps()
