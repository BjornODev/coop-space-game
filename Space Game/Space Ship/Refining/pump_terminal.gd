@tool extends TerminalPort

@onready var indicator: ColorRect = $Indicator

var pump_is_broken : bool = false
var pump_being_overclocked : bool = false
var pump_toggled : bool = false

## value of 0.1 ~ 10 seconds till pump breaks
@export var overclock_speed : float = 0.1
## time it takes to fix the pump in seconds (once broken)
@export var fix_time : float = 5 

signal pump_overclock_toggled(status : bool)
signal pump_broken_toggled(status : bool)

# timeout time changeable, just make sure not too small (0.01>)
func _on_interaction_started(player: Player) -> void:
	if player.item_manager.item_being_held:
		get_tree().create_timer(0.1).timeout.connect(end_interaction)
		return
	
	if pump_is_broken:
		var timer = get_tree().create_timer(fix_time)
		timer.timeout.connect(end_interaction)
		timer.timeout.connect(pump_fixed)
	else:
		get_tree().create_timer(1.0).timeout.connect(end_interaction)
		pump_being_overclocked = not pump_being_overclocked

func pump_fixed() -> void:
	pump_broken_toggled.emit(false)
	pump_is_broken = false
	indicator.color = Color("7b7b00")
	pump_being_overclocked = false
	

func _process(delta: float) -> void:
	if not indicator:
		return
	
	if pump_is_broken:
		indicator.color = Color("black")
		return
		
	if not pump_being_overclocked:
		indicator.color.r = move_toward(indicator.color.r,0,delta * overclock_speed)
		indicator.color.g = move_toward(indicator.color.g,1,delta * overclock_speed)
		if indicator.color.r < 0.35 and pump_toggled:
			pump_overclock_toggled.emit(false)
			pump_toggled = false
	else:
		indicator.color.r = move_toward(indicator.color.r,1,delta * overclock_speed)
		indicator.color.g = move_toward(indicator.color.g,0,delta * overclock_speed)
		
		if indicator.color.r > 0.35 and not pump_toggled:
			pump_overclock_toggled.emit(true)
			pump_toggled = true
		
		if indicator.color == Color("red"):
			break_pump()

## Breaks the pump once: drops its overclock bonus and applies the broken slowdown.
func break_pump() -> void:
	pump_is_broken = true
	pump_being_overclocked = false
	# a broken pump shouldn't keep its overclock bonus while it waits to be fixed
	if pump_toggled:
		pump_overclock_toggled.emit(false)
		pump_toggled = false
	pump_broken_toggled.emit(true)
		
	
