@abstract
@tool class_name TerminalPort extends Interactable

@onready var label: Label = $Standin/Label
var text_holder : String = ""

@export var text : String = "":
	set(value):
		text = value
		text_holder = value
		if Engine.is_editor_hint():
			label.text = value

func _ready() -> void:
	label.text = text_holder
