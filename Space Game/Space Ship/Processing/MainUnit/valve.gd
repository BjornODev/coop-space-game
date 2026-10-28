extends Interactable

signal valve_interacted(player : Player)

# timeout time changeable, just make sure not too small (0.01>)
func _on_interaction_started(player: Player) -> void:
	if not player.item_manager.item_being_held:
		valve_interacted.emit()
	get_tree().create_timer(0.1).timeout.connect(end_interaction)
