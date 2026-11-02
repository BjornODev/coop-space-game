extends Interactable

signal empty_capsule(player : Player)
@export var type : String = "Capsule"

# timeout time changeable, just make sure not too small (0.01>)
func _on_interaction_started(player: Player) -> void:
	if player.item_manager.item_being_held["Type"] != type:
		pass
	elif player.item_manager.item_being_held["Status"] >= 100:
		pass
	else:
		empty_capsule.emit(player)
	
	print(player.item_manager.item_being_held["Status"])
	get_tree().create_timer(2).timeout.connect(end_interaction)
