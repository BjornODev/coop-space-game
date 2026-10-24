extends Node2D

@onready var fuel_terminal: Interactable = $FuelTerminal
@onready var fuel_bar: TextureProgressBar = $FuelBar

func _ready() -> void:
	fuel_terminal.connect("item_added", add_refined_material)

func add_refined_material(item : Dictionary) -> void:
	fuel_bar.set_texture_progress_bars(item["Purity"],100 - item["Purity"])
