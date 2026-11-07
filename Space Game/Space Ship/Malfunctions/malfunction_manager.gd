## Owns the four failure meters: Fire, Oxygen, Comms and Hull.
## Every frame it asks each system how many instances of its malfunction are active. A meter fills by its
## fill rate for each active instance, and drains back at its drain rate while none are active.
## When any meter is full, the mission fails. The HUD reads meters, colors and alert targets from here,
## and the countdown shown on each malfunction in the world is pushed out from here too.
class_name MalfunctionManager extends Node

## Emitted every frame for each meter with its value from 0 to 1.
signal meter_changed(type: Malfunction.Type, value: float)
## Emitted once, when the first meter fills completely.
signal mission_failed(type: Malfunction.Type)

## Burning tiles are Fire instances.
@export var fire_system: FireSystem
## A clogged or missing filter is one Oxygen instance.
@export var life_support: LifeSupportUnit
## Each pending check-in is a Comms instance.
@export var comms_panel: CommsPanel
## Each open breach is a Hull instance.
@export var hull_breaches: HullBreachSystem

@export_group("Fill Per Instance")
## Fire meter fill per second for each burning tile. A full meter is 1.
@export var fire_fill_per_instance: float = 0.004
## Oxygen meter fill per second while the filter is clogged or missing.
@export var oxygen_fill_per_instance: float = 0.012
## Comms meter fill per second for each pending check-in.
@export var comms_fill_per_instance: float = 0.01
## Hull meter fill per second for each open breach.
@export var hull_fill_per_instance: float = 0.008

@export_group("Drain")
## Fire meter drain per second while nothing is burning.
@export var fire_drain_rate: float = 0.02
## Oxygen meter drain per second while the air is clean.
@export var oxygen_drain_rate: float = 0.02
## Comms meter drain per second while no check-in is pending.
@export var comms_drain_rate: float = 0.02
## Hull meter drain per second while no breach is open.
@export var hull_drain_rate: float = 0.02

@export_group("Colors")
@export var fire_color: Color = Color(1.0, 0.45, 0.1)
@export var oxygen_color: Color = Color(0.3, 0.8, 1.0)
@export var comms_color: Color = Color(0.75, 0.45, 1.0)
@export var hull_color: Color = Color(0.95, 0.85, 0.2)

@export_group("Names")
@export var fire_name: String = "Fire"
@export var oxygen_name: String = "Oxygen"
@export var comms_name: String = "Comms"
@export var hull_name: String = "Hull"

var _meters: Dictionary[Malfunction.Type, float] = {}
var _failed: bool = false

func _ready() -> void:
	for type: Malfunction.Type in Malfunction.ALL_TYPES:
		_meters[type] = 0.0

func _process(delta: float) -> void:
	if _failed:
		return
	for type: Malfunction.Type in Malfunction.ALL_TYPES:
		var count: int = get_active_count(type)
		var value: float = _meters[type]
		if count > 0:
			value += get_fill_per_instance(type) * count * delta
		else:
			value = move_toward(value, 0.0, get_drain_rate(type) * delta)
		_meters[type] = clampf(value, 0.0, 1.0)
		meter_changed.emit(type, _meters[type])
	_push_countdowns()
	for type: Malfunction.Type in Malfunction.ALL_TYPES:
		if _meters[type] >= 1.0:
			_failed = true
			mission_failed.emit(type)
			return

#region Meters

## How full the meter is, from 0 to 1.
func get_meter(type: Malfunction.Type) -> float:
	return _meters.get(type, 0.0)

func has_failed() -> bool:
	return _failed

## Active instances of type right now.
func get_active_count(type: Malfunction.Type) -> int:
	match type:
		Malfunction.Type.FIRE:
			return fire_system.get_burning_tile_count() if fire_system != null else 0
		Malfunction.Type.OXYGEN:
			return 1 if life_support != null and life_support.is_oxygen_failing() else 0
		Malfunction.Type.COMMS:
			return comms_panel.get_pending_count() if comms_panel != null else 0
		Malfunction.Type.HULL:
			return hull_breaches.get_open_breach_count() if hull_breaches != null else 0
	return 0

func is_active(type: Malfunction.Type) -> bool:
	return get_active_count(type) > 0

## Seconds until the meter is full at its current rate, or INF while it isn't filling.
func get_time_until_full(type: Malfunction.Type) -> float:
	var rate: float = get_fill_per_instance(type) * get_active_count(type)
	if rate <= 0.0:
		return INF
	return (1.0 - get_meter(type)) / rate

## get_time_until_full() as whole seconds, like "42s", or an empty string while the meter isn't filling.
func get_countdown_text(type: Malfunction.Type) -> String:
	var seconds: float = get_time_until_full(type)
	if is_inf(seconds):
		return ""
	return "%ds" % ceili(seconds)

func get_fill_per_instance(type: Malfunction.Type) -> float:
	match type:
		Malfunction.Type.FIRE: return fire_fill_per_instance
		Malfunction.Type.OXYGEN: return oxygen_fill_per_instance
		Malfunction.Type.COMMS: return comms_fill_per_instance
	return hull_fill_per_instance

func get_drain_rate(type: Malfunction.Type) -> float:
	match type:
		Malfunction.Type.FIRE: return fire_drain_rate
		Malfunction.Type.OXYGEN: return oxygen_drain_rate
		Malfunction.Type.COMMS: return comms_drain_rate
	return hull_drain_rate

func get_color(type: Malfunction.Type) -> Color:
	match type:
		Malfunction.Type.FIRE: return fire_color
		Malfunction.Type.OXYGEN: return oxygen_color
		Malfunction.Type.COMMS: return comms_color
	return hull_color

func get_display_name(type: Malfunction.Type) -> String:
	match type:
		Malfunction.Type.FIRE: return fire_name
		Malfunction.Type.OXYGEN: return oxygen_name
		Malfunction.Type.COMMS: return comms_name
	return hull_name

#endregion

## Everything alert arrows should point at for a player at viewer_position:
## the nearest burning tile in each room on fire, each open breach, the life support unit while oxygen is failing,
## and the comms panel while a check-in is pending.
func get_alert_targets(viewer_position: Vector2) -> Array[AlertTarget]:
	var targets: Array[AlertTarget] = []
	if fire_system != null:
		for point: Vector2 in fire_system.get_alert_positions(viewer_position):
			targets.append(AlertTarget.new(Malfunction.Type.FIRE, point))
	if hull_breaches != null:
		for breach: HullBreach in hull_breaches.get_breaches():
			targets.append(AlertTarget.new(Malfunction.Type.HULL, breach.global_position))
	if life_support != null and life_support.is_oxygen_failing():
		targets.append(AlertTarget.new(Malfunction.Type.OXYGEN, life_support.get_alert_position()))
	if comms_panel != null and comms_panel.get_pending_count() > 0:
		targets.append(AlertTarget.new(Malfunction.Type.COMMS, comms_panel.get_alert_position()))
	return targets

## Shows each meter's countdown on its malfunctions in the world.
func _push_countdowns() -> void:
	if fire_system != null:
		fire_system.set_countdown_text(get_countdown_text(Malfunction.Type.FIRE))
	if life_support != null:
		life_support.set_countdown_text(get_countdown_text(Malfunction.Type.OXYGEN))
	if comms_panel != null:
		comms_panel.set_countdown_text(get_countdown_text(Malfunction.Type.COMMS))
	if hull_breaches != null:
		hull_breaches.set_countdown_text(get_countdown_text(Malfunction.Type.HULL))
