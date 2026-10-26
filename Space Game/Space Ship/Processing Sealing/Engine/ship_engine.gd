## One of the ship's two engines. A canister in its slot dispenses fuel into the tank until the tank is full or the
## canister is grabbed out. The tank burns fuel all the time, and faster while boosting.
## While the tank is empty the ship should drift toward this engine's side. Steering is not part of processing,
## so this is only reported through dry_changed and is_dry().
class_name ShipEngine extends Node2D

## Emitted when the tank runs empty or gets fuel again. The ship should drift toward side while is_dry is true.
signal dry_changed(side: ShipSide.Side, is_dry: bool)

## Which side of the ship this engine is on.
@export var side: ShipSide.Side = ShipSide.Side.LEFT
## Most fuel the tank holds, in canisters' worth.
@export var tank_capacity: float = 3.0
## Fuel in the tank. The exported value is the starting amount.
@export var fuel: float = 3.0
## Fuel moved from the canister in the slot to the tank per second.
@export var dispense_rate: float = 0.33
## Fuel burned per second, all the time. Both engines should use the same value.
@export var base_burn_rate: float = 0.02
## Extra fuel burned per second while boosting, on top of the base burn.
@export var boost_burn_rate: float = 0.08

## Set by ShipProcessing.set_boost(). While true, the tank also burns boost_burn_rate.
var is_boosting: bool = false

## Dry state as of the last check, so dry_changed only fires on changes.
var _was_dry: bool = false

@onready var _slot: CanisterSlot = $Slot
@onready var _fuel_bar: ProgressBar = $FuelBar
@onready var _fuel_label: Label = $FuelBar/Label

func _ready() -> void:
	fuel = clampf(fuel, 0.0, tank_capacity)
	_was_dry = is_dry()
	_fuel_bar.max_value = tank_capacity
	_update_readouts()

func _physics_process(delta: float) -> void:
	var burn: float = base_burn_rate + (boost_burn_rate if is_boosting else 0.0)
	fuel = maxf(fuel - burn * delta, 0.0)

	var canister := _slot.canister
	if canister != null:
		var wanted: float = minf(dispense_rate * delta, maxf(tank_capacity - fuel, 0.0))
		fuel += canister.remove_fuel(wanted)

	if is_dry() != _was_dry:
		_was_dry = is_dry()
		dry_changed.emit(side, _was_dry)

	_update_readouts()

func is_dry() -> bool:
	return fuel <= 0.0

## The slot canisters are inserted into.
func get_slot() -> CanisterSlot:
	return _slot

func _update_readouts() -> void:
	_fuel_bar.value = fuel
	_fuel_label.text = "%s engine %.2f / %.2f%s" % [
		"Left" if side == ShipSide.Side.LEFT else "Right",
		fuel, tank_capacity,
		"  DRY" if is_dry() else ("  BOOST" if is_boosting else ""),
	]
