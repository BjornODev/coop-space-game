extends Node2D

@onready var refining_terminal: Interactable = $RefiningTerminal
@onready var process_progress: TextureProgressBar = $ProcessProgress
@onready var valve: Interactable = $Valve
@onready var fuel_input_unit: Node2D = $FuelInputUnit
@onready var on_off_rect: ColorRect = $OnOffRect

var count : float = 0.6
var refine_speed : float = 0.01
var items_in_unit : Array[Dictionary] = []
var item_ready : bool = false
var valve_status : int = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	refining_terminal.connect("item_added", process_item)
	valve.connect("valve_interacted", _on_valve_interaction)

func process_item(item : Dictionary) -> void:
	items_in_unit.append(item)
	get_tree().create_timer(1).timeout.connect(item_seperated)

func item_seperated() -> void:
	var item : Dictionary = items_in_unit.pop_front()
	
	if item["Amount"] < 5:
		return
	
	item["Amount"] -= 5 # still decreases if at low temp
	
	if count >= 1.0: # overheated means ore passes with less quality
		item["Purity"] *= 0.95 # 5% drop in overall ore quality
		fuel_input_unit.add_refined_material(
			5 * item["Purity"], 5 * (1-item["Purity"])) 
		
	elif count >= 0.45: # just right, quality unaffected
		fuel_input_unit.add_refined_material(
			5 * item["Purity"], 5 * (1-item["Purity"])) 
	
	process_item(item) # cycles item
	

func _on_valve_interaction() -> void:
	valve_status *= -1

func _process(delta: float) -> void:
	if items_in_unit:
		on_off_rect.color = Color("Green")
	else:
		on_off_rect.color = Color("Red")
	
	count += delta * refine_speed * valve_status
	count = clampf(count, 0,1)
	process_progress.value = count
	
