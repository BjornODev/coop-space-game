extends Node2D

var unrefined_ore_queue : Array = []
@onready var pump_terminals: Node2D = $PumpTerminals

@onready var processing_rect: ColorRect = $ProcessingRect
@onready var tick_label: Label = $TickLabel

signal ore_refined(amount : int)
var refinement_percentage : float = 0

var count : float = 0
var cook_time : float = 0

@export_category("Pump Modifiers")
@export var overclock_boost : float = 10.0
@export_range(1.0,20.0,1.0) var pump_boost : float = 10.0
@export_range(1.0,5.0,0.1) var broken_slowdown : float = 2.0

func _ready() -> void:
	if pump_terminals.get_child_count() == 0:
		return
	
	for pump_terminal in pump_terminals.get_children():
		pump_terminal.connect("pump_overclock_toggled",pump_overclock_toggled)
		pump_terminal.connect("pump_broken_toggled",pump_broken_toggled)

func pump_overclock_toggled(pump_overclocked : bool) -> void:
	if pump_overclocked:
		overclock_boost += pump_boost
	else:
		overclock_boost -= pump_boost

# too many broken pumps could theoretically stop pumping
func pump_broken_toggled(pump_broken : bool) -> void:
	if pump_broken:
		overclock_boost -= broken_slowdown
	else:
		overclock_boost += broken_slowdown

func add_ore_to_queue(new_ore : Dictionary) -> void:
	unrefined_ore_queue.append(new_ore)
	start_pump_timer()

func remove_ore_from_queue() -> void:
	if not unrefined_ore_queue:
		return
	
	var refined_ore = unrefined_ore_queue.pop_front()
	ore_refined.emit(refined_ore["Purity"])
	

func _on_pump_timer_timeout() -> void:
	if overclock_boost > 0 and unrefined_ore_queue:
		refinement_percentage += overclock_boost
		tick_label.text = "Refinement: " + str(refinement_percentage) + "%"
	
	
	start_pump_timer()
	count = 0

func start_pump_timer() -> void:
	if refinement_percentage >= 100:
		refinement_percentage = 0
		tick_label.text = "Refinement: " + str(refinement_percentage) + "%"
		processing_rect.color = Color("red")
		remove_ore_from_queue()
	
	if not unrefined_ore_queue:
		return
	
	processing_rect.color = Color("green")
	var purity : float = unrefined_ore_queue.front()["Purity"]
	cook_time = 2*exp(-purity/21.7)

func _process(delta: float) -> void:
	if processing_rect.color != Color("green"):
		return 
	elif not cook_time:
		return printerr("this should never happen")
		
	count += delta
	if count >= cook_time:
		_on_pump_timer_timeout()
