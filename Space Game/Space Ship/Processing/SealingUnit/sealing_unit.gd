extends Node2D

@onready var pressurized_fuel_label: Label = $PressurizedFuelLabel
@onready var output_terminal: Interactable = $OutputTerminal
var pressurized_fuel : int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	output_terminal.connect("empty_capsule",fill_empty_capsule)

func fill_empty_capsule(player: Player) -> void:
	if pressurized_fuel >= 100:
		player.item_manager.item_being_held["Status"] = 100
		add_pressurized_fuel(-100)
	else:
		player.item_manager.item_being_held["Status"] = pressurized_fuel
		add_pressurized_fuel(-pressurized_fuel)

func add_pressurized_fuel(amount : int) -> void:
	pressurized_fuel += amount
	pressurized_fuel_label.text = "Pressurized Fuel: " +str(pressurized_fuel)
