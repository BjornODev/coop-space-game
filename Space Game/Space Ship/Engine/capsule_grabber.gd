extends Interactable

signal add_capsule(player : Player)

# timeout time changeable, just make sure not too small (0.01>)
func _on_interaction_started(player: Player) -> void:
	get_tree().create_timer(2).timeout.connect(end_interaction)
	
	if not player.item_manager.item_being_held:
		return
	
	add_capsule.emit(player)
