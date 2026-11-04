extends Node2D

@onready var input_terminal: Interactable = $InputTerminal
@onready var output_terminal: Interactable = $OutputTerminal
@onready var process_box: Node2D = $ProcessBox
@onready var ore_label: Label = $OreLabel

var refined_ore : int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	input_terminal.connect("item_added",unrefined_ore_added)
	output_terminal.connect("add_capsule",add_filled_capsule)
	process_box.connect("ore_refined",ore_refined)

func unrefined_ore_added(item : Dictionary) -> void:
	process_box.add_ore_to_queue(item)

func add_filled_capsule(player : Player) -> void:
	var leftover : int = player.item_manager.item_being_held["Purity"]
	
	if refined_ore >= 100:
		player.item_manager.item_being_held["Purity"] = 100
		refined_ore -= 100 - leftover
	elif refined_ore + leftover >= 100:
		player.item_manager.item_being_held["Purity"] = 100
		refined_ore -= 100 - leftover
	else:
		player.item_manager.item_being_held["Purity"] = refined_ore + leftover
		refined_ore = 0

func ore_refined(amount: int) -> void:
	refined_ore += amount
	ore_label.text = "Ore Refined: " + str(refined_ore)
