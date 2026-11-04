extends Interactable

signal drain_activated(drain_timer : Timer)
@onready var drain_timer: Timer = $DrainTimer

func _ready() -> void:
	drain_timer.timeout.connect(end_interaction)

func _on_interaction_started(player: Player) -> void:
	if not player.item_manager.item_being_held:
		drain_activated.emit(drain_timer)
	else:
		get_tree().create_timer(0.1).timeout.connect(end_interaction)
	
