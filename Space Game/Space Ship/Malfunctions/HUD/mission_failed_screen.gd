## Covers a player's screen when a meter fills. Names the meter and offers a restart.
## Any player pressing A, or clicking the button, asks for a restart.
class_name MissionFailedScreen extends Control

## Emitted when the restart button is pressed.
signal restart_pressed

@onready var _reason_label: Label = $Panel/Content/ReasonLabel
@onready var _restart_button: Button = $Panel/Content/RestartButton
@onready var _restart_prompt: ButtonPrompt = $Panel/Content/RestartPrompt

func _ready() -> void:
	_restart_button.pressed.connect(_on_restart_button_pressed)

## Shows the screen for the meter that filled. input labels the restart prompt with that player's keys.
func show_failure(meter_name: String, color: Color, input: PlayerInput) -> void:
	show_reason("The %s meter filled up." % meter_name, color, input)

## Shows the screen with reason as the explanation. input labels the restart prompt with that player's keys.
func show_reason(reason: String, color: Color, input: PlayerInput) -> void:
	_reason_label.text = reason
	_reason_label.modulate = color
	if input != null:
		_restart_prompt.show_for_actions([input.A])
	visible = true

func _on_restart_button_pressed() -> void:
	restart_pressed.emit()
