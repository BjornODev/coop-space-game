## Autoload "MusicManager": adaptive level music and stingers.
##
## The music is one AudioStreamInteractive with three clips: Main (three stacked layers in an
## AudioStreamSynchronized), Transition (a one-bar lead-in) and Final (the final stretch loop).
## In Main, the number of audible layers follows a danger score built from reported problems.
## When the LevelTimer starts the final stretch, the music moves to Final on the next bar and stays there.
##
## Game code only talks to this node through start_level_music(), report_problem(), play_stinger(),
## end_level_music() and the beat signal. The level's LevelTimer is found through its group.
extends Node

## Emitted on every beat of the Final clip, timed to when players hear it.
signal beat

const AUDIO_DIR: String = "res://Space Game/Space Ship/Audio/"
const MUSIC_BUS: StringName = &"Music"
const SFX_BUS: StringName = &"SFX"

const CLIP_MAIN: StringName = &"Main"
const CLIP_TRANSITION: StringName = &"Transition"
const CLIP_FINAL: StringName = &"Final"
const CLIP_NAMES: Array[StringName] = [CLIP_MAIN, CLIP_TRANSITION, CLIP_FINAL]

const STINGER_ALARM: StringName = &"stinger_alarm"
const STINGER_FUEL_RECEIVED: StringName = &"stinger_fuel_received"
const STINGER_TASK_FAILED: StringName = &"stinger_task_failed"

## Problem ids understood by the danger score. Any other id counts with a weight of 1.
const PROBLEM_COLLISION_COURSE: StringName = &"asteroid_collision_course"
## Engines report as "engine_dry" or "engine_dry_<n>", one id per engine.
const PROBLEM_ENGINE_DRY: StringName = &"engine_dry"
const PROBLEM_OFF_COURSE: StringName = &"off_course"
const PROBLEM_BEHIND_SCHEDULE: StringName = &"behind_schedule"

## Layer volume when on and off, in dB.
const LAYER_ON_DB: float = 0.0
const LAYER_OFF_DB: float = -60.0

@export_group("Layers")
## Seconds a layer takes to fade in or out.
@export var layer_fade_seconds: float = 1.0
## Seconds the music takes to fade out when the level ends.
@export var end_fade_seconds: float = 2.0

@export_group("Danger Score")
## Points while an asteroid is on a collision course with the ship.
@export var collision_course_weight: float = 1.0
## Points per engine that is dry.
@export var engine_dry_weight: float = 1.0
## Points while the ship is off course.
@export var off_course_weight: float = 1.0
## Points while distance progress is behind elapsed time.
@export var behind_schedule_weight: float = 1.0
## Score at or above this plays level 2 (busy: L1 + L2).
@export var level_2_threshold: float = 1.0
## Score at or above this plays level 3 (chaos: L1 + L2 + L3).
@export var level_3_threshold: float = 3.0
## Seconds the score must stay below the current level's threshold before the level drops.
@export var drop_hold_seconds: float = 4.0

@export_group("Stingers")
## Seconds before the same stinger can play again. Different stingers may overlap.
@export var stinger_cooldown_seconds: float = 1.5
## Seconds between alarms during overtime.
@export var overtime_alarm_interval: float = 5.0
## Players in the stinger pool, so stingers overlap the music and each other without cutting off.
@export var stinger_pool_size: int = 4

var _music_player: AudioStreamPlayer
var _interactive: AudioStreamInteractive
var _main_layers: AudioStreamSynchronized
var _final_beat_seconds: float = 60.0 / 160.0
var _stinger_streams: Dictionary[StringName, AudioStream] = {}
var _stinger_pool: Array[AudioStreamPlayer] = []
## Time.get_ticks_msec() when each stinger last played.
var _stinger_last_played_msec: Dictionary[StringName, int] = {}

var _level_timer: LevelTimer = null
var _level_active: bool = false
## Active state of every reported problem.
var _problems: Dictionary[StringName, bool] = {}
## Current intensity level, 1 to 3.
var _intensity: int = 1
## Seconds the score has been below the current level's threshold.
var _drop_hold: float = 0.0
## 0 follows the danger score. 1 to 3 holds that level (debug only).
var _forced_intensity: int = 0
var _layer_tweens: Array[Tween] = [null, null, null]
var _fade_tween: Tween = null

## True once the switch to Final has been requested. Main never comes back during this level.
var _in_final: bool = false
## True once the Final clip is actually playing.
var _final_playing: bool = false
## Time.get_ticks_usec() at which players hear the first beat of Final.
var _final_heard_start_usec: int = 0
var _last_beat_index: int = -1

var _overtime_alarm_active: bool = false
var _overtime_alarm_elapsed: float = 0.0

func _ready() -> void:
	# keeps fading out and finishing stingers on the mission failed screen, which pauses the tree.
	# Everything that is game time (hold timers, overtime loop) skips while paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_music()
	_build_stingers()
	# --- DEBUG (strip with music_debug.gd) ---
	if OS.is_debug_build():
		var debug: Node = load(AUDIO_DIR + "music_debug.gd").new()
		debug.name = "MusicDebug"
		add_child(debug)
	# --- END DEBUG ---

func _process(delta: float) -> void:
	if _in_final:
		_update_final_beat()
	if not _level_active or get_tree().paused:
		return
	if not _in_final:
		_update_intensity(delta)
	if _overtime_alarm_active:
		_overtime_alarm_elapsed += delta
		if _overtime_alarm_elapsed >= overtime_alarm_interval:
			_overtime_alarm_elapsed -= overtime_alarm_interval
			play_stinger(STINGER_ALARM)

#region Public API

## Starts the level's music on Main at level 1 and resets the score, hold timers, cooldowns and overtime loop.
## Call at level start, after the LevelTimer has started. Starts on Final if the final stretch already applies.
func start_level_music() -> void:
	_kill_tween(_fade_tween)
	_connect_level_timer(get_tree().get_first_node_in_group(LevelTimer.GROUP) as LevelTimer)
	_level_active = true
	_problems.clear()
	_intensity = 1
	_drop_hold = 0.0
	_stinger_last_played_msec.clear()
	_overtime_alarm_active = false
	_overtime_alarm_elapsed = 0.0
	_in_final = false
	_final_playing = false
	_last_beat_index = -1
	for i: int in _layer_tweens.size():
		_kill_tween(_layer_tweens[i])
		_main_layers.set_sync_stream_volume(i, LAYER_ON_DB if i == 0 else LAYER_OFF_DB)

	var start_in_final: bool = is_instance_valid(_level_timer) and _level_timer.is_final_stretch
	_interactive.initial_clip = CLIP_NAMES.find(CLIP_FINAL if start_in_final else CLIP_MAIN)
	_music_player.volume_db = 0.0
	_music_player.play()
	_in_final = start_in_final
	if is_instance_valid(_level_timer) and _level_timer.is_overtime:
		_on_overtime_started()

## Reports whether a problem is active, for systems that can't be polled. Each active problem adds its weight
## to the danger score. Calling again with the same state does nothing. The alarm plays when a collision course,
## a dry engine or going off course begins.
func report_problem(problem_id: StringName, active: bool) -> void:
	var was_active: bool = _problems.get(problem_id, false)
	_problems[problem_id] = active
	if active == was_active or not _level_active:
		return
	if active and _is_alarm_problem(problem_id):
		play_stinger(STINGER_ALARM)
	# rises are immediate, so don't wait for the next frame
	if active and not _in_final and not get_tree().paused:
		_update_intensity(0.0)

## Plays a stinger by name (stinger_alarm, stinger_fuel_received, stinger_task_failed) on the SFX bus.
## The same stinger is ignored while it's on cooldown.
func play_stinger(stinger_name: StringName) -> void:
	var stream: AudioStream = _stinger_streams.get(stinger_name)
	if stream == null:
		push_warning("MusicManager: unknown stinger '%s'." % stinger_name)
		return
	var now: int = Time.get_ticks_msec()
	if _stinger_last_played_msec.has(stinger_name) and now - _stinger_last_played_msec[stinger_name] < stinger_cooldown_seconds * 1000.0:
		return
	_stinger_last_played_msec[stinger_name] = now
	var player: AudioStreamPlayer = _get_free_stinger_player()
	player.stream = stream
	player.play()

## Stops the overtime alarm loop and fades the music out, then stops it. Stingers already playing finish.
func end_level_music() -> void:
	_level_active = false
	_overtime_alarm_active = false
	_in_final = false
	_final_playing = false
	if not _music_player.playing:
		return
	_kill_tween(_fade_tween)
	_fade_tween = create_tween()
	_fade_tween.tween_property(_music_player, "volume_db", LAYER_OFF_DB, end_fade_seconds)
	_fade_tween.tween_callback(_music_player.stop)
	_fade_tween.tween_property(_music_player, "volume_db", 0.0, 0.0)

#endregion

#region Read-only state (for HUD and debug)

## Current intensity level, 1 to 3.
func get_intensity() -> int:
	return _intensity

## Sum of the weights of every active problem.
func get_danger_score() -> float:
	var score: float = 0.0
	for problem_id: StringName in _problems:
		if _problems[problem_id]:
			score += _get_weight(problem_id)
	return score

## Name of the clip players hear right now, or &"" when the music is stopped.
func get_current_clip_name() -> StringName:
	var playback: AudioStreamPlaybackInteractive = _get_playback()
	if playback == null:
		return &""
	var index: int = playback.get_current_clip_index()
	return CLIP_NAMES[index] if index >= 0 and index < CLIP_NAMES.size() else &""

func is_final_playing() -> bool:
	return _final_playing

func get_active_problems() -> Array[StringName]:
	var active: Array[StringName] = []
	for problem_id: StringName in _problems:
		if _problems[problem_id]:
			active.append(problem_id)
	return active

#endregion

#region Debug hooks (used by music_debug.gd only)

## Holds the intensity at level (1 to 3), or follows the danger score again with 0.
func debug_force_intensity(level: int) -> void:
	_forced_intensity = clampi(level, 0, 3)
	if not _in_final:
		_update_intensity(0.0)

func debug_get_forced_intensity() -> int:
	return _forced_intensity

#endregion

func _build_music() -> void:
	_main_layers = AudioStreamSynchronized.new()
	_main_layers.stream_count = 3
	for i: int in 3:
		_main_layers.set_sync_stream(i, load(AUDIO_DIR + "music_main_L%d.ogg" % (i + 1)))
		_main_layers.set_sync_stream_volume(i, LAYER_ON_DB if i == 0 else LAYER_OFF_DB)

	var final_stream: AudioStream = load(AUDIO_DIR + "music_final.ogg")
	if final_stream.get_bpm() > 0.0:
		_final_beat_seconds = 60.0 / final_stream.get_bpm()

	_interactive = AudioStreamInteractive.new()
	_interactive.clip_count = CLIP_NAMES.size()
	_set_clip(CLIP_MAIN, _main_layers)
	_set_clip(CLIP_TRANSITION, load(AUDIO_DIR + "music_transition.ogg"))
	_set_clip(CLIP_FINAL, final_stream)
	_interactive.initial_clip = CLIP_NAMES.find(CLIP_MAIN)
	# Main -> Final: wait for the next bar, play Transition as filler, then start Final from the top with no fade
	_interactive.add_transition(
		CLIP_NAMES.find(CLIP_MAIN), CLIP_NAMES.find(CLIP_FINAL),
		AudioStreamInteractive.TRANSITION_FROM_TIME_NEXT_BAR, AudioStreamInteractive.TRANSITION_TO_TIME_START,
		AudioStreamInteractive.FADE_DISABLED, 0.0,
		true, CLIP_NAMES.find(CLIP_TRANSITION))

	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.stream = _interactive
	_music_player.bus = _bus_or_master(MUSIC_BUS)
	add_child(_music_player)

func _set_clip(clip_name: StringName, stream: AudioStream) -> void:
	var index: int = CLIP_NAMES.find(clip_name)
	_interactive.set_clip_name(index, clip_name)
	_interactive.set_clip_stream(index, stream)

func _build_stingers() -> void:
	for stinger_name: StringName in [STINGER_ALARM, STINGER_FUEL_RECEIVED, STINGER_TASK_FAILED]:
		_stinger_streams[stinger_name] = load(AUDIO_DIR + stinger_name + ".wav")
	var bus: StringName = _bus_or_master(SFX_BUS)
	for i: int in maxi(stinger_pool_size, 1):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.name = "StingerPlayer%d" % i
		player.bus = bus
		add_child(player)
		_stinger_pool.append(player)

## A stinger player that isn't playing, or the one that started longest ago if all are busy.
func _get_free_stinger_player() -> AudioStreamPlayer:
	var oldest: AudioStreamPlayer = _stinger_pool[0]
	for player: AudioStreamPlayer in _stinger_pool:
		if not player.playing:
			return player
		if player.get_playback_position() > oldest.get_playback_position():
			oldest = player
	return oldest

func _bus_or_master(bus: StringName) -> StringName:
	if AudioServer.get_bus_index(bus) == -1:
		push_warning("MusicManager: audio bus '%s' is missing, using Master." % bus)
		return &"Master"
	return bus

func _connect_level_timer(timer: LevelTimer) -> void:
	if is_instance_valid(_level_timer) and _level_timer != timer:
		_level_timer.final_stretch_started.disconnect(_on_final_stretch_started)
		_level_timer.overtime_started.disconnect(_on_overtime_started)
		_level_timer.level_won.disconnect(_on_level_won)
		_level_timer.level_lost.disconnect(end_level_music)
	_level_timer = timer
	if timer == null:
		push_warning("MusicManager: no LevelTimer in the scene, so there is no final stretch or overtime.")
		return
	if not timer.final_stretch_started.is_connected(_on_final_stretch_started):
		timer.final_stretch_started.connect(_on_final_stretch_started)
		timer.overtime_started.connect(_on_overtime_started)
		timer.level_won.connect(_on_level_won)
		timer.level_lost.connect(end_level_music)

func _on_final_stretch_started() -> void:
	if not _level_active or _in_final:
		return
	_in_final = true
	var playback: AudioStreamPlaybackInteractive = _get_playback()
	if playback != null:
		playback.switch_to_clip_by_name(CLIP_FINAL)

func _on_overtime_started() -> void:
	if not _level_active:
		return
	_overtime_alarm_active = true
	_overtime_alarm_elapsed = 0.0
	play_stinger(STINGER_ALARM)

func _on_level_won(_late: bool) -> void:
	end_level_music()

func _get_playback() -> AudioStreamPlaybackInteractive:
	if not _music_player.playing:
		return null
	return _music_player.get_stream_playback() as AudioStreamPlaybackInteractive

## Finds when Final actually starts, then emits beat on each of its beats as players hear them.
## The start is anchored to the audio mix (time since the mix that started it, plus output latency),
## and every later beat is derived from that anchor, so beats don't drift with the frame rate.
func _update_final_beat() -> void:
	var now_usec: int = Time.get_ticks_usec()
	if not _final_playing:
		if get_current_clip_name() != CLIP_FINAL:
			return
		_final_playing = true
		_last_beat_index = -1
		var mixed_at_usec: int = now_usec - int(AudioServer.get_time_since_last_mix() * 1_000_000.0)
		_final_heard_start_usec = mixed_at_usec + int(AudioServer.get_output_latency() * 1_000_000.0)
	var heard_seconds: float = (now_usec - _final_heard_start_usec) / 1_000_000.0
	if heard_seconds < 0.0:
		return
	var beat_index: int = floori(heard_seconds / _final_beat_seconds)
	if beat_index > _last_beat_index:
		_last_beat_index = beat_index
		beat.emit()

func _update_intensity(delta: float) -> void:
	var target: int = _forced_intensity if _forced_intensity > 0 else _get_level_for_score(get_danger_score())
	if target > _intensity or (_forced_intensity > 0 and target != _intensity):
		_set_intensity(target)
	elif target < _intensity:
		_drop_hold += delta
		if _drop_hold >= drop_hold_seconds:
			_set_intensity(target)
	else:
		_drop_hold = 0.0

func _get_level_for_score(score: float) -> int:
	if score >= level_3_threshold:
		return 3
	if score >= level_2_threshold:
		return 2
	return 1

func _set_intensity(level: int) -> void:
	_intensity = level
	_drop_hold = 0.0
	for i: int in 3:
		# L1 always plays, L2 from level 2, L3 at level 3
		_fade_layer(i, LAYER_ON_DB if level >= i + 1 else LAYER_OFF_DB)

func _fade_layer(index: int, target_db: float) -> void:
	_kill_tween(_layer_tweens[index])
	var from_db: float = _main_layers.get_sync_stream_volume(index)
	if is_equal_approx(from_db, target_db):
		return
	var tween: Tween = create_tween()
	tween.tween_method(func(db: float) -> void: _main_layers.set_sync_stream_volume(index, db), from_db, target_db, layer_fade_seconds)
	_layer_tweens[index] = tween

func _kill_tween(tween: Tween) -> void:
	if tween != null and tween.is_valid():
		tween.kill()

func _is_alarm_problem(problem_id: StringName) -> bool:
	return problem_id == PROBLEM_COLLISION_COURSE or problem_id == PROBLEM_OFF_COURSE or _is_engine_problem(problem_id)

func _is_engine_problem(problem_id: StringName) -> bool:
	return String(problem_id).begins_with(PROBLEM_ENGINE_DRY)

func _get_weight(problem_id: StringName) -> float:
	if _is_engine_problem(problem_id):
		return engine_dry_weight
	match problem_id:
		PROBLEM_COLLISION_COURSE:
			return collision_course_weight
		PROBLEM_OFF_COURSE:
			return off_course_weight
		PROBLEM_BEHIND_SCHEDULE:
			return behind_schedule_weight
	return 1.0
