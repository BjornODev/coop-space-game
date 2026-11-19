## Shakes every player's camera together, since the whole ship shakes.
## Two kinds: a light rumble that lasts as long as set_rumble(true) is on (the engine burning fuel), and a heavy
## jolt from impact() that fades out on its own (hitting an asteroid). The stronger of the two wins.
## Strengths are in screen pixels, so the shake looks the same at any camera zoom, including zoomed in on a station.
## Moves Camera2D.offset only, so it never fights the code that moves the cameras.
class_name ScreenShake extends Node

@export_group("Rumble")
## How far the screen moves while rumbling, in screen pixels.
@export var rumble_strength: float = 2.5
## How quickly the rumble wobbles. Higher is buzzier.
@export var rumble_speed: float = 35.0
## Seconds for the rumble to fade in and out, so it doesn't snap on and off.
@export var rumble_fade_time: float = 0.15

@export_group("Impact")
## How far the screen moves at the start of an impact, in screen pixels.
@export var impact_strength: float = 24.0
## How quickly an impact wobbles. Lower than the rumble, so it reads as a heavy thud.
@export var impact_speed: float = 22.0
## Seconds for an impact to die out completely.
@export var impact_duration: float = 0.6

var _cameras: Array[Camera2D] = []
var _rumble_on: bool = false
## 0 to 1, eases toward 1 while rumbling and back to 0 after.
var _rumble_amount: float = 0.0
## 1 right after an impact, falling to 0 over impact_duration.
var _impact_amount: float = 0.0
var _time: float = 0.0
var _noise: FastNoiseLite = FastNoiseLite.new()

func _init() -> void:
	# keeps running while paused, only to put the cameras back to rest
	process_mode = Node.PROCESS_MODE_ALWAYS
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.frequency = 1.0

## Adds a camera to shake. The game calls this for each player's camera.
func add_camera(camera: Camera2D) -> void:
	if camera != null and not _cameras.has(camera):
		_cameras.append(camera)

## Turns the light rumble on or off. Safe to call every frame.
func set_rumble(on: bool) -> void:
	_rumble_on = on

## Starts a heavy jolt. strength_multiplier scales it, so a harder hit can shake more.
func impact(strength_multiplier: float = 1.0) -> void:
	_impact_amount = maxf(_impact_amount, clampf(strength_multiplier, 0.0, 2.0))

func _process(delta: float) -> void:
	if get_tree().paused:
		_set_offsets(Vector2.ZERO, Vector2.ZERO)
		return
	_time += delta
	var fade_speed: float = delta / rumble_fade_time if rumble_fade_time > 0.0 else 1.0
	_rumble_amount = move_toward(_rumble_amount, 1.0 if _rumble_on else 0.0, fade_speed)
	_impact_amount = move_toward(_impact_amount, 0.0, delta / impact_duration if impact_duration > 0.0 else 1.0)

	var rumble: Vector2 = _sample(rumble_speed, 0.0) * rumble_strength * _rumble_amount
	# squared, so an impact starts violent and settles quickly instead of fading evenly
	var impact_shake: Vector2 = _sample(impact_speed, 500.0) * impact_strength * _impact_amount * _impact_amount
	_set_offsets(rumble, impact_shake)

func _exit_tree() -> void:
	# the cameras belong to the splitscreen framework and outlive this run, so leave them at rest
	_set_offsets(Vector2.ZERO, Vector2.ZERO)

## Smooth random direction, roughly -1 to 1 on each axis. lane keeps the two kinds of shake from moving in step.
func _sample(speed: float, lane: float) -> Vector2:
	var t: float = _time * speed
	# raw simplex noise rarely reaches 1, so it's boosted to use the full strength
	return Vector2(_noise.get_noise_2d(t, lane), _noise.get_noise_2d(lane + 100.0, t)) * 1.6

## Applies the stronger of the two shakes to every camera, converted from screen pixels to world units.
func _set_offsets(rumble: Vector2, impact_shake: Vector2) -> void:
	var shake: Vector2 = impact_shake if impact_shake.length() > rumble.length() else rumble
	for camera: Camera2D in _cameras:
		if is_instance_valid(camera):
			camera.offset = shake / camera.zoom
