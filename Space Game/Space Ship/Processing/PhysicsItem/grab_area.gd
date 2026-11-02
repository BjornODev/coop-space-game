extends Interactable

signal item_grabbed(player : Player)


# timeout time changeable, just make sure not too small (0.01>)
func _on_interaction_started(player: Player) -> void:
	item_grabbed.emit(player)
		
	get_tree().create_timer(0.1).timeout.connect(end_interaction)
