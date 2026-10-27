extends Interactable

func _on_interaction_started(_player: Player) -> void:
	get_tree().create_timer(2.0).timeout.connect(end_interaction)
