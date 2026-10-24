extends Node2D

@onready var input_terminal: Interactable = $InputTerminal
@onready var process_progress: TextureProgressBar = $ProcessProgress
@onready var valve: Interactable = $Valve

var count : float = 0
var refine_speed : float = 0.1
var item_in_unit : Dictionary = {}
var item_ready : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	input_terminal.connect("item_added", process_new_item)
	valve.connect("valve_interacted", _on_valve_interaction)

func process_new_item(item : Dictionary) -> void:
	item_in_unit = item

func _on_valve_interaction(player : Player) -> void:
	if not item_in_unit:
		return
	
	var item : Dictionary = item_in_unit
	
	item_in_unit = {}
	
	if count >= 1.0: # "over-processed"
		return 
	elif count >= 0.59: # just right
		player.item_manager.add_item(item)
	
	# "under-processed"
	


func _process(delta: float) -> void:
	if item_in_unit:
		count += delta * refine_speed
		process_progress.value = count
	elif count:
		count = 0
		process_progress.value = 0
