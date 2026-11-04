extends Node2D

var unrefined_ore_queue : Array = []
@onready var pump_timer: Timer = $PumpTimer
@onready var pump_terminals: Node2D = $PumpTerminals

signal ore_refined(amount : int)

## 50% purity -> 20 seconds, 95% purity -> 5 seconds (at 5 boost, 150 modifier)
## 50% purity -> 10 seconds, 95% purity -> 2.5 seconds (at 10 boost, 150 modifier)
@export var overclock_boost : float = 5.0
@export_range(1.0,10.0,1.0) var pump_boost : float = 5.0
@export_range(101.0,200.0,1.0) var boost_modifier : float = 150.0
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
	remove_ore_from_queue()
	start_pump_timer()

func start_pump_timer() -> void:
	if not unrefined_ore_queue or not overclock_boost:
		return
	
	var cook_time = (boost_modifier - unrefined_ore_queue.front()["Purity"])/overclock_boost
	if cook_time > 0.1:
		pump_timer.start(cook_time)
	elif cook_time > 0:
		pump_timer.start(0.1)
