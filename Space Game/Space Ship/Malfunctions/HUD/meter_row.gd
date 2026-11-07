## One failure meter on the HUD: its name, a bar, and the time until it fills.
class_name MeterRow extends HBoxContainer

@onready var _name_label: Label = $NameLabel
@onready var _bar: ProgressBar = $Bar
@onready var _time_label: Label = $TimeLabel

## Sets the meter's name and bar color.
func setup(display_name: String, color: Color) -> void:
	_name_label.text = display_name
	_name_label.modulate = color
	# each row gets its own fill style so the colors don't overwrite each other
	var fill: StyleBoxFlat = (_bar.get_theme_stylebox("fill") as StyleBoxFlat).duplicate()
	fill.bg_color = color
	_bar.add_theme_stylebox_override("fill", fill)

## value goes from 0 to 1. countdown_text is empty while the meter isn't filling.
func show_value(value: float, countdown_text: String) -> void:
	_bar.value = value * _bar.max_value
	_time_label.text = countdown_text
