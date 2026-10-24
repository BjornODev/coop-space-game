extends TextureProgressBar

@onready var impurity_bar: TextureProgressBar = $ImpurityBar

var move_to_fuel : int = 0
var move_to_impurity : int = 0

var impurity_counter : float = 0
var fuel_counter : float = 0
@export var animation_fill_speed : int = 10

func set_texture_progress_bars(fuel : int, impurities : int) -> void:
	move_to_fuel += fuel
	move_to_impurity += impurities

func _process(delta: float) -> void:
	if value != move_to_fuel + move_to_impurity:
		fuel_counter = move_toward(
		fuel_counter,move_to_fuel + move_to_impurity,delta * animation_fill_speed * 2)
		set_value(fuel_counter)
	if impurity_bar.value != move_to_impurity:
		impurity_counter = move_toward(
		impurity_counter,move_to_impurity,delta * animation_fill_speed)
		impurity_bar.set_value(impurity_counter)
