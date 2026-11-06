extends Node2D

@onready var capsule_container: HBoxContainer = $CapsuleContainer
const CAPSULE_PLACEHOLDER = preload("res://Space Game/Space Ship/Engine/capsule_placeholder.tscn")
@onready var fuel_label: Label = $EngineRect/FuelLabel

var capsules : Array = []
var fuel_available : int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in range(4):
		var placeholder : Control = CAPSULE_PLACEHOLDER.instantiate()
		capsule_container.add_child(placeholder)
		capsules.append(placeholder)
		placeholder.connect("update_fuel_available",update_fuel_available)
		
		if i <= 1:
			placeholder.add_new_capsule({
			"Texture": preload("res://Framework/Assets/icon.png"),
			"Status": "unrefined",
			"Purity": 50,
			"is_scanned" : false
			})

func update_fuel_available(amount : int) -> void:
	fuel_available += amount
	var text = "Fuel\nAvailable\n-> "
	fuel_label.text = text + str(fuel_available)

## Call this function to get how much fuel is available.
## Specify amount to take out that amount of available fuel.
func drain_fuel(amount : int = 0) -> int:
	for capsule in capsules:
		if not capsule.capsule["Activated"]:
			continue
		if capsule.drain_fuel_left(amount):
			update_fuel_available(-amount)
			break
	
	return fuel_available
