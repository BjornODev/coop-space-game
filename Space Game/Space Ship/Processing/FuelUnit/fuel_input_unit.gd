extends Node2D

@onready var fuel_bar: TextureProgressBar = $FuelBar
@onready var impurity_drain: Interactable = $ImpurityDrain
@onready var sealing_unit: Node2D = $SealingUnit

@export var pumps : Array[Pump]

func _ready() -> void:
	impurity_drain.connect("drain_activated", set_drain_timer)
	if not pumps:
		return
	
	for pump in pumps:
		pump.connect("pump_activated",send_pure_fuel)

func add_refined_material(fuel : float,impurities : float) -> void:
	fuel_bar.set_texture_progress_bars(fuel,impurities)

func set_drain_timer(drain_timer : Timer) -> void:
	drain_timer.start(2)
	fuel_bar.move_to_impurity = 0

func send_pure_fuel() -> void:
	if fuel_bar.move_to_fuel >= 10:
		fuel_bar.move_to_fuel -= 10
		sealing_unit.add_pressurized_fuel(10)
