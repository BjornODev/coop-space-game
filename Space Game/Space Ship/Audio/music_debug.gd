## DEBUG ONLY. Keys for testing the level timer and music, plus an optional readout.
## MusicManager adds this in debug builds only. To strip it, delete this file and the DEBUG block
## in music_manager.gd's _ready(). The debug_* methods on MusicManager and LevelTimer are only called from here.
##
##   F1 / F2 / F3   force intensity 1 / 2 / 3 (press the same key again to follow the danger score)
##   F4             trigger the final stretch (jumps the timer to the final stretch threshold)
##   F5             skip the timer to 65 s remaining
##   F6             skip the timer to 0 (overtime)
##   F7 / F8 / F9   play stinger_alarm / stinger_fuel_received / stinger_task_failed
##   F10            show or hide the readout
extends Node

const KEYS: Dictionary[StringName, Key] = {
	&"debug_music_intensity_1": KEY_F1,
	&"debug_music_intensity_2": KEY_F2,
	&"debug_music_intensity_3": KEY_F3,
	&"debug_music_final_stretch": KEY_F4,
	&"debug_timer_skip_65": KEY_F5,
	&"debug_timer_skip_0": KEY_F6,
	&"debug_stinger_alarm": KEY_F7,
	&"debug_stinger_fuel_received": KEY_F8,
	&"debug_stinger_task_failed": KEY_F9,
	&"debug_music_readout": KEY_F10,
}

var _layer: CanvasLayer
var _label: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for action: StringName in KEYS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var event: InputEventKey = InputEventKey.new()
			event.physical_keycode = KEYS[action]
			InputMap.action_add_event(action, event)
	_layer = CanvasLayer.new()
	_layer.layer = 100
	_layer.visible = false
	add_child(_layer)
	_label = Label.new()
	_label.position = Vector2(12, 140)
	_label.add_theme_font_size_override("font_size", 16)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 4)
	_layer.add_child(_label)

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	for level: int in [1, 2, 3]:
		if event.is_action(StringName("debug_music_intensity_%d" % level)):
			MusicManager.debug_force_intensity(0 if MusicManager.debug_get_forced_intensity() == level else level)
	var timer: LevelTimer = _get_timer()
	if event.is_action(&"debug_music_final_stretch") and timer != null:
		timer.debug_set_time_remaining(minf(timer.time_remaining, timer.final_stretch_seconds))
	elif event.is_action(&"debug_timer_skip_65") and timer != null:
		timer.debug_set_time_remaining(65.0)
	elif event.is_action(&"debug_timer_skip_0") and timer != null:
		timer.debug_set_time_remaining(0.0)
	elif event.is_action(&"debug_stinger_alarm"):
		MusicManager.play_stinger(&"stinger_alarm")
	elif event.is_action(&"debug_stinger_fuel_received"):
		MusicManager.play_stinger(&"stinger_fuel_received")
	elif event.is_action(&"debug_stinger_task_failed"):
		MusicManager.play_stinger(&"stinger_task_failed")
	elif event.is_action(&"debug_music_readout"):
		_layer.visible = not _layer.visible

func _process(_delta: float) -> void:
	if not _layer.visible:
		return
	var timer: LevelTimer = _get_timer()
	var lines: PackedStringArray = []
	if timer != null:
		lines.append("time: %.1f / %.1f s  (elapsed %.2f, progress %.2f)" % [timer.time_remaining, timer.time_limit, timer.elapsed_fraction(), timer.get_distance_progress()])
		lines.append("overtime: %s  grace %.1f s  final stretch: %s  running: %s" % [timer.is_overtime, timer.grace_remaining, timer.is_final_stretch, timer.is_running])
	else:
		lines.append("no LevelTimer")
	var forced: int = MusicManager.debug_get_forced_intensity()
	lines.append("score: %.1f  level: %d%s" % [MusicManager.get_danger_score(), MusicManager.get_intensity(), "  (forced)" if forced > 0 else ""])
	lines.append("problems: %s" % ", ".join(PackedStringArray(MusicManager.get_active_problems())))
	lines.append("clip: %s" % MusicManager.get_current_clip_name())
	_label.text = "\n".join(lines)

func _get_timer() -> LevelTimer:
	return get_tree().get_first_node_in_group(LevelTimer.GROUP) as LevelTimer
