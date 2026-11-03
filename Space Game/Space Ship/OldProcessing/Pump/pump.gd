class_name Pump extends Interactable

signal pump_activated
var is_pump_overclocked : bool = false

@onready var pump_timer: Timer = $PumpTimer
@onready var texture_progress_bar: TextureProgressBar = $TextureProgressBar

var count : float = 0
@export var overclock_speed : int = 10
@export var cooldown_speed : float = 7.5

func _process(delta: float) -> void:
	if is_pump_overclocked:
		count += delta * overclock_speed
	else:
		count -= delta * cooldown_speed
	
	count = clampf(count,0,100)
	texture_progress_bar.value = count

# timeout time changeable, just make sure not too small (0.01>)
func _on_interaction_started(player: Player) -> void:
	if not player.item_manager.item_being_held:
		is_pump_overclocked = not is_pump_overclocked
	get_tree().create_timer(0.1).timeout.connect(end_interaction)

func _on_pump_timer_timeout() -> void:
	if texture_progress_bar.value < 75:
		pump_activated.emit()
	if is_pump_overclocked:
		pump_timer.start(1.5)
	
