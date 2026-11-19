## Pause menu over the whole window, across every player's screen. Any player's Start opens it, and that player
## moves through it with up/down, picks with A, and closes it with B. Any player's Start closes it too.
## The game makes one in start() and calls setup(). Keeps running while the game is paused.
class_name PauseMenu extends CanvasLayer

## Emitted when the crew picks Restart Run.
signal restart_requested
## Emitted when the crew picks Quit to Player Select.
signal quit_requested

@export var normal_color: Color = Color(0.85, 0.85, 0.85)
@export var selected_color: Color = Color(0.2, 1.0, 0.9)

@onready var _root: Control = $Root
@onready var _title_label: Label = $Root/Panel/Content/TitleLabel
@onready var _hint_label: Label = $Root/Panel/Content/HintLabel
## In the order they are listed on screen.
@onready var _buttons: Array[Button] = [
	$Root/Panel/Content/ResumeButton,
	$Root/Panel/Content/RestartButton,
	$Root/Panel/Content/QuitButton,
]

## Player numbers whose Start button opens the menu.
var _player_numbers: Array[int] = []
## Player number moving through the menu, the one who opened it.
var _controlling_player: int = 1
var _selected: int = 0
var _enabled: bool = true
## Each button's text without the selection marks.
var _labels: Array[String] = []

func _ready() -> void:
	visible = false
	for button: Button in _buttons:
		_labels.append(button.text)
	_buttons[0].pressed.connect(resume)
	_buttons[1].pressed.connect(_on_restart)
	_buttons[2].pressed.connect(_on_quit)

## Lets the players in player_numbers open the menu, and draws it over the whole window.
## Call after adding the menu to the tree.
func setup(player_numbers: Array[int]) -> void:
	_player_numbers = player_numbers.duplicate()
	custom_viewport = get_tree().root

## Turns the menu off, for when the run is over and another screen has taken over. Closes it if open.
func set_enabled(enabled: bool) -> void:
	_enabled = enabled
	if not enabled:
		visible = false

func is_open() -> bool:
	return visible

## Pauses the game and opens the menu for player_number. Does nothing if something else already paused the game.
func open(player_number: int) -> void:
	if not _enabled or visible or get_tree().paused:
		return
	get_tree().paused = true
	_controlling_player = player_number
	_title_label.text = "PAUSED (P%d)" % player_number
	_hint_label.text = _get_hint_text(CoopInput.get_player(player_number))
	_select(0)
	visible = true

## Closes the menu and unpauses the game.
func resume() -> void:
	if not visible:
		return
	visible = false
	get_tree().paused = false

func _process(_delta: float) -> void:
	if not _enabled:
		return
	_root.size = get_tree().root.get_visible_rect().size
	for player_number: int in _player_numbers:
		if Input.is_action_just_pressed(CoopInput.get_player(player_number).START):
			if visible:
				resume()
			else:
				open(player_number)
			return
	if not visible:
		return
	var input: PlayerInput = CoopInput.get_player(_controlling_player)
	if Input.is_action_just_pressed(input.UP):
		_select(_selected - 1)
	elif Input.is_action_just_pressed(input.DOWN):
		_select(_selected + 1)
	elif Input.is_action_just_pressed(input.B):
		resume()
	elif Input.is_action_just_pressed(input.A):
		_buttons[_selected].pressed.emit()

func _select(index: int) -> void:
	_selected = wrapi(index, 0, _buttons.size())
	for i: int in _buttons.size():
		var color: Color = selected_color if i == _selected else normal_color
		_buttons[i].add_theme_color_override("font_color", color)
		_buttons[i].add_theme_color_override("font_hover_color", color)
		_buttons[i].text = "> %s <" % _labels[i] if i == _selected else _labels[i]

func _on_restart() -> void:
	visible = false
	restart_requested.emit()

func _on_quit() -> void:
	visible = false
	quit_requested.emit()

## Control hints for input, with keyboard key names when it's a keyboard player.
func _get_hint_text(input: PlayerInput) -> String:
	var up: String = ButtonPrompt.get_key_name(input.UP)
	var down: String = ButtonPrompt.get_key_name(input.DOWN)
	var move: String = "%s/%s" % [up, down] if not up.is_empty() and not down.is_empty() else "Stick"
	return "%s: Move   %s: Select   %s: Back" % [move, _key_or(input.A, "A"), _key_or(input.B, "B")]

func _key_or(action: String, fallback: String) -> String:
	var key_name: String = ButtonPrompt.get_key_name(action)
	return key_name if not key_name.is_empty() else fallback
