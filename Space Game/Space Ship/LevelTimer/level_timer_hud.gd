## The level countdown, shown once at the top center of the whole window, across every splitscreen view.
## Shows mm:ss, turns red in the final stretch, and shows OVERTIME m:ss during the grace period.
## In the final stretch and overtime it pulses on MusicManager's beat, so it stays locked to the music.
class_name LevelTimerHud extends CanvasLayer

@export var level_timer: LevelTimer
## Text color before the final stretch.
@export var normal_color: Color = Color(0.9, 0.9, 0.9)
## Text color in the final stretch and overtime.
@export var urgent_color: Color = Color(1.0, 0.25, 0.2)
## Scale at the top of each beat pulse.
@export var pulse_scale: float = 1.15
## Length of each pulse, in beats of the final stretch music (160 BPM).
@export_range(0.05, 1.0) var pulse_beats: float = 0.4
## Fraction of the pulse spent growing. The rest shrinks back.
@export_range(0.05, 0.95) var pulse_attack: float = 0.25

const FINAL_BPM: float = 160.0

@onready var _panel: PanelContainer = $Panel
@onready var _label: Label = $Panel/TimeLabel

var _pulse_tween: Tween = null

func _ready() -> void:
	# draws on the window itself instead of the first player's view, so everyone sees the same timer
	custom_viewport = get_tree().root
	MusicManager.beat.connect(_on_beat)
	_panel.visible = false

func _process(_delta: float) -> void:
	if level_timer == null or level_timer.time_limit <= 0.0:
		_panel.visible = false
		return
	_panel.visible = true
	if level_timer.is_overtime:
		_label.text = "OVERTIME %s" % _format(level_timer.grace_remaining, false)
	else:
		_label.text = _format(level_timer.time_remaining, true)
	_label.modulate = urgent_color if _is_urgent() else normal_color
	# keep the panel centered at the top as the window or text changes size
	var window_width: float = get_tree().root.get_visible_rect().size.x
	_panel.size = _panel.get_combined_minimum_size()
	_panel.position = Vector2((window_width - _panel.size.x) * 0.5, _panel.position.y)
	_panel.pivot_offset = _panel.size * 0.5

func _is_urgent() -> bool:
	return level_timer.is_final_stretch or level_timer.is_overtime

## Whole seconds rounded up, so the display reads 0:00 only when time is really up.
func _format(seconds: float, pad_minutes: bool) -> String:
	var total: int = ceili(maxf(seconds, 0.0))
	return ("%02d:%02d" if pad_minutes else "%d:%02d") % [total / 60, total % 60]

func _on_beat() -> void:
	if level_timer == null or not level_timer.is_running or not _is_urgent():
		return
	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()
	var pulse_seconds: float = pulse_beats * 60.0 / FINAL_BPM
	_panel.scale = Vector2.ONE
	_pulse_tween = create_tween()
	_pulse_tween.tween_property(_panel, "scale", Vector2.ONE * pulse_scale, pulse_seconds * pulse_attack) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_pulse_tween.tween_property(_panel, "scale", Vector2.ONE, pulse_seconds * (1.0 - pulse_attack)) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
