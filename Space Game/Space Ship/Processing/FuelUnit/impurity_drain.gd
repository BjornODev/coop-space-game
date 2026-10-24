extends Interactable

signal drain_activated(drain_timer : Timer)
@onready var drain_timer: Timer = $DrainTimer

func _ready() -> void:
	drain_timer.timeout.connect(end_interaction)

func _on_interaction_started(_player: Player) -> void:
	drain_activated.emit(drain_timer)
