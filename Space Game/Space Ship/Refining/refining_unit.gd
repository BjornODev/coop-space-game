extends Node2D

@onready var input_terminal: Interactable = $InputTerminal
@onready var output_terminal: Interactable = $OutputTerminal

var unrefined_ore_queue : Array[Dictionary]
var refined_ore : int = 100000

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	input_terminal.connect("item_added",unrefined_ore_added)
	output_terminal.connect("add_capsule",add_filled_capsule)

func unrefined_ore_added(item : Dictionary) -> void:
	unrefined_ore_queue.append(item)

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
