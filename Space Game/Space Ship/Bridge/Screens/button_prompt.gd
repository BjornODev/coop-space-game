## One on-screen control hint, like "A: Boost". Changes color while its control is in use.
## Shows controller names by default. Call show_for_actions() with a player's actions to show their keyboard keys instead.
class_name ButtonPrompt extends Label

## Button name for controller players, like "A" or "Stick".
@export var button_text: String = "A"
## What the control does, like "Boost".
@export var action_text: String = "Action"
## Button name for keyboard players when the keys have long names, like the arrow keys.
@export var long_keys_text: String = "Arrows"
## Text color while the control isn't in use.
@export var idle_color: Color = Color(0.9, 0.9, 0.9)
## Text color while the control is in use.
@export var active_color: Color = Color(0.0, 1.0, 0.0)

func _ready() -> void:
	show_default()
	set_active(false)

## Colors the prompt as in use, or back to normal.
func set_active(active: bool) -> void:
	modulate = active_color if active else idle_color

## Goes back to showing button_text.
func show_default() -> void:
	_show_button(button_text)

## Shows the keyboard keys bound to actions if they are keys, or button_text if they are controller inputs.
## Several single letter keys are joined, like "AD". Several longer key names show long_keys_text.
func show_for_actions(actions: Array[String]) -> void:
	var key_names: PackedStringArray = PackedStringArray()
	for action: String in actions:
		var key_name: String = _get_key_name(action)
		if key_name.is_empty():
			show_default()
			return
		key_names.append(key_name)
	if key_names.size() == 1:
		_show_button(key_names[0])
		return
	for key_name: String in key_names:
		if key_name.length() > 1:
			_show_button(long_keys_text)
			return
	_show_button("".join(key_names))

func _show_button(button_name: String) -> void:
	text = "%s: %s" % [button_name, action_text]

## Name of the first keyboard key bound to action, or an empty string if it has none.
func _get_key_name(action: String) -> String:
	if not InputMap.has_action(action):
		return ""
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey:
			var key_event: InputEventKey = event
			var keycode: Key = key_event.keycode if key_event.keycode != KEY_NONE else key_event.physical_keycode
			return OS.get_keycode_string(keycode)
	return ""
