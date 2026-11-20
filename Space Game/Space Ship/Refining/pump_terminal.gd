extends Interactable

@onready var pump_animator : AnimationPlayer = $PumpAnimator
@onready var alarm_animator : AnimationPlayer = $AlarmAnimator

var pump_is_broken : bool = false
var pump_being_overclocked : bool = false
var pump_toggled : bool = false
var pump_already_broken : bool = false

## value of 0.1 ~ 10 seconds till pump breaks
@export var overclock_speed : float = 0.1
## time it takes to fix the pump in seconds (once broken)
@export var fix_time : float = 5 
## buffer when alarm is sounded
@export_range(0.5,0.9,0.05) var pump_alarm_ratio : float = 0.80
signal pump_overclock_toggled(status : bool)
signal pump_broken_toggled(status : bool)

var count : float = 0

# timeout time changeable, just make sure not too small (0.01>)
func _on_interaction_started(player: Player) -> void:
	if player.item_manager.item_being_held:
		get_tree().create_timer(0.1).timeout.connect(end_interaction)
		return
	
	if pump_is_broken:
		var timer = get_tree().create_timer(fix_time)
		timer.timeout.connect(end_interaction)
		timer.timeout.connect(pump_fixed)
		pump_animator.speed_scale = 5
	else:
		get_tree().create_timer(1.0).timeout.connect(end_interaction)
		pump_being_overclocked = not pump_being_overclocked
		
		if pump_being_overclocked:
			pump_animator.speed_scale = 10
		else:
			pump_animator.speed_scale = 5

func pump_fixed() -> void:
	pump_broken_toggled.emit(false)
	pump_is_broken = false
	pump_already_broken = false
	pump_being_overclocked = false
	pump_animator.play("Run_Pump")

func _process(delta: float) -> void:
	if not pump_animator:
		return
	
	if pump_is_broken and not pump_already_broken:
		return
	elif pump_is_broken:
		return
	
	if not pump_being_overclocked:
		count = move_toward(count,0,delta * overclock_speed)
		if count < 0.35 and pump_toggled:
			pump_overclock_toggled.emit(false)
			pump_toggled = false
		alarm_animator.play("RESET")
	else:
		count = move_toward(count,1,delta * overclock_speed)
		
		if count > 0.35 and not pump_toggled:
			pump_overclock_toggled.emit(true)
			pump_toggled = true
		
		if count >= 1:
			break_pump()
		elif count >= 0.7:
			alarm_animator.play("Alarm")
		else:
			alarm_animator.play("RESET")

## Breaks the pump once: drops its overclock bonus and applies the broken slowdown.
func break_pump() -> void:
	pump_is_broken = true
	pump_being_overclocked = false
	# a broken pump shouldn't keep its overclock bonus while it waits to be fixed
	if pump_toggled:
		pump_overclock_toggled.emit(false)
		pump_toggled = false
	pump_broken_toggled.emit(true)
	
	pump_animator.play("RESET")
	alarm_animator.play("RESET")
	
