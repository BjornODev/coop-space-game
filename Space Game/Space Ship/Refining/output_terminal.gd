@tool extends TerminalPort

signal add_capsule(player : Player)
@export var status : String = "capsule"

# timeout time changeable, just make sure not too small (0.01>)
func _on_interaction_started(player: Player) -> void:
	get_tree().create_timer(2).timeout.connect(end_interaction)
	
	if not player.item_manager.item_being_held:
		return
	
	if player.item_manager.item_being_held["Status"] == status:
		add_capsule.emit(player)
