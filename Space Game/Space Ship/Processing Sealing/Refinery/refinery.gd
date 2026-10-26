## The ship's refinery. Raw material arrives through the chute on a timer and refines over time into refined material,
## which the sealer puts into canisters. Pressure rises over time and with each delivery, and higher pressure refines
## faster. Vent valves lower pressure while held open. Reaching max_pressure has no consequence yet.
class_name Refinery extends Node2D

## Emitted on every chute delivery. wasted is the part that didn't fit (all of it while the refinery is full).
signal material_delivered(added: float, wasted: float)

@export_group("Chute")
## Seconds between chute deliveries.
@export var delivery_interval: float = 5.0
## Raw material in each delivery.
@export var delivery_amount: float = 0.3
## Pressure added by each delivery that adds material.
@export var delivery_pressure_bump: float = 8.0
## Most raw material waiting to be refined. Anything past this is wasted.
@export var raw_capacity: float = 1.0

@export_group("Refining")
## Most refined material stored, in canisters' worth. While full, refining stops and deliveries are wasted.
@export var refined_capacity: float = 3.0
## Raw material refined per second at zero pressure.
@export var base_refine_rate: float = 0.04
## Extra refining speed at max pressure, as a multiple of the base rate. Scales linearly with pressure.
@export var pressure_refine_multiplier: float = 3.0

@export_group("Pressure")
## Pressure can't go above this.
@export var max_pressure: float = 100.0
## Pressure gained per second, all the time.
@export var pressure_rise_rate: float = 1.5

@export_group("State")
## Current pressure. The exported value is the starting pressure.
@export var pressure: float = 0.0
## Raw material waiting to be refined. The exported value is the starting amount.
@export var raw: float = 0.0
## Refined material ready for sealing. The exported value is the starting amount.
@export var refined: float = 0.0

@export_group("Valves")
## The left vent valve.
@export var left_valve: VentValve
## The right vent valve.
@export var right_valve: VentValve

@onready var _delivery_timer: Timer = $Chute/DeliveryTimer
@onready var _pressure_bar: ProgressBar = $PressureBar
@onready var _pressure_label: Label = $PressureBar/Label
@onready var _raw_bar: ProgressBar = $RawBar
@onready var _raw_label: Label = $RawBar/Label
@onready var _refined_bar: ProgressBar = $RefinedBar
@onready var _refined_label: Label = $RefinedBar/Label

func _ready() -> void:
	_pressure_bar.max_value = max_pressure
	_raw_bar.max_value = raw_capacity
	_refined_bar.max_value = refined_capacity
	_delivery_timer.wait_time = delivery_interval
	_delivery_timer.timeout.connect(_on_delivery)
	_delivery_timer.start()
	_update_readouts()

func _physics_process(delta: float) -> void:
	var vent_total: float = 0.0
	for valve: VentValve in [left_valve, right_valve]:
		if valve != null and valve.is_venting():
			vent_total += valve.vent_rate
	pressure = clampf(pressure + (pressure_rise_rate - vent_total) * delta, 0.0, max_pressure)

	var refined_amount: float = minf(get_refine_rate() * delta, minf(raw, get_refined_space()))
	if refined_amount > 0.0:
		raw -= refined_amount
		refined += refined_amount

	_update_readouts()

## Raw material refined per second at the current pressure.
func get_refine_rate() -> float:
	var pressure_ratio: float = pressure / max_pressure if max_pressure > 0.0 else 0.0
	return base_refine_rate * (1.0 + pressure_refine_multiplier * pressure_ratio)

## How much more refined material fits in storage.
func get_refined_space() -> float:
	return maxf(refined_capacity - refined, 0.0)

func is_full() -> bool:
	return refined >= refined_capacity

func is_at_max_pressure() -> bool:
	return pressure >= max_pressure

## Removes up to amount refined material. Returns how much was actually taken.
func take_refined(amount: float) -> float:
	var taken := clampf(amount, 0.0, refined)
	refined -= taken
	return taken

func _on_delivery() -> void:
	var added: float = 0.0
	if not is_full():
		added = clampf(delivery_amount, 0.0, maxf(raw_capacity - raw, 0.0))
	if added > 0.0:
		raw += added
		pressure = minf(pressure + delivery_pressure_bump, max_pressure)
	material_delivered.emit(added, delivery_amount - added)

func _update_readouts() -> void:
	_pressure_bar.value = pressure
	_pressure_label.text = "Pressure %.0f / %.0f" % [pressure, max_pressure]
	_raw_bar.value = raw
	_raw_label.text = "Raw %.2f / %.2f" % [raw, raw_capacity]
	_refined_bar.value = refined
	_refined_label.text = "Refined %.2f / %.2f" % [refined, refined_capacity]
