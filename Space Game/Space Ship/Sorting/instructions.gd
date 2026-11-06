extends VBoxContainer


@onready var move_prompt: ButtonPrompt = $MovePrompt
@onready var grab_prompt: ButtonPrompt = $GrabPrompt
@onready var spin_prompt: ButtonPrompt = $SpinPrompt
@onready var expand_prompt: ButtonPrompt = $ExpandPrompt
@onready var exit_prompt: ButtonPrompt = $ExitPrompt

var already_toggled : bool = false

func toggle_instructions(input : PlayerInput) -> void:
	if not input:
		visible = false
		already_toggled = false
		return
	elif already_toggled:
		return
	
	already_toggled = true
	visible = true
	
	move_prompt.show_for_actions([input.UP,input.LEFT,input.DOWN,input.RIGHT])
	grab_prompt.show_for_actions([input.A])
	spin_prompt.show_for_actions([input.X])
	expand_prompt.show_for_actions([input.Y])
	exit_prompt.show_for_actions([input.B])
