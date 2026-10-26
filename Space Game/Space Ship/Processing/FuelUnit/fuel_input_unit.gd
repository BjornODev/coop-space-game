extends Node2D

@onready var fuel_terminal: Interactable = $FuelTerminal
@onready var fuel_bar: TextureProgressBar = $FuelBar
@onready var impurity_drain: Interactable = $ImpurityDrain

@export var drain_modifier : float = 1.5

func _ready() -> void:
	fuel_terminal.connect("item_added", add_refined_material)
	impurity_drain.connect("drain_activated", set_drain_timer)

func add_refined_material(item : Dictionary) -> void:
	fuel_bar.set_texture_progress_bars(item["Purity"],100 - item["Purity"])

func set_drain_timer(drain_timer : Timer) -> void:
	drain_timer.start(fuel_bar.move_to_impurity/(
		fuel_bar.animation_fill_speed * drain_modifier))
	fuel_bar.move_to_impurity = 0
