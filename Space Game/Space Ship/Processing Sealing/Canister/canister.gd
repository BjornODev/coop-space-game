## A fuel canister players carry between the sealer and the engines. 1.0 fuel is one full canister.
class_name Canister extends Grabbable

## Emitted whenever the amount of fuel inside changes.
signal fuel_changed(fuel: float)

## Most fuel this canister can hold.
@export var capacity: float = 1.5
## Fuel currently inside. The exported value is the starting amount.
@export var fuel: float = 0.0

@onready var _fuel_bar: ProgressBar = $FuelBar

func _ready() -> void:
	fuel = clampf(fuel, 0.0, capacity)
	_fuel_bar.max_value = capacity
	_update_readout()

## Adds up to amount fuel, limited by the space left. Returns how much was actually added.
func add_fuel(amount: float) -> float:
	var added := clampf(amount, 0.0, get_space())
	if added > 0.0:
		fuel += added
		_on_fuel_changed()
	return added

## Removes up to amount fuel, limited by what is inside. Returns how much was actually removed.
func remove_fuel(amount: float) -> float:
	var removed := clampf(amount, 0.0, fuel)
	if removed > 0.0:
		fuel -= removed
		_on_fuel_changed()
	return removed

## How much more fuel fits inside.
func get_space() -> float:
	return maxf(capacity - fuel, 0.0)

func is_full() -> bool:
	return fuel >= capacity

func is_empty() -> bool:
	return fuel <= 0.0

func _on_fuel_changed() -> void:
	_update_readout()
	fuel_changed.emit(fuel)

func _update_readout() -> void:
	_fuel_bar.value = fuel
