extends Node2D

@onready var fuel_bar: TextureProgressBar = $FuelBar
@onready var impurity_drain: Interactable = $ImpurityDrain

func _ready() -> void:
	impurity_drain.connect("drain_activated", set_drain_timer)

func add_refined_material(fuel : float,impurities : float) -> void:
	fuel_bar.set_texture_progress_bars(fuel,impurities)

func set_drain_timer(drain_timer : Timer) -> void:
	drain_timer.start(2)
	fuel_bar.move_to_impurity = 0
