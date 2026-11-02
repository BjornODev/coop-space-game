class_name Pump extends Interactable

signal pump_activated
var is_pump_overclocked : bool = false

@onready var pump_timer: Timer = $PumpTimer

# timeout time changeable, just make sure not too small (0.01>)
func _on_interaction_started(player: Player) -> void:
	if not player.item_manager.item_being_held:
		is_pump_overclocked = not is_pump_overclocked
	get_tree().create_timer(0.1).timeout.connect(end_interaction)

func _on_pump_timer_timeout() -> void:
	pump_activated.emit()
	if is_pump_overclocked:
		pump_timer.start(1.5)
	
