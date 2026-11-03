@tool extends TerminalPort

signal item_added(item: Dictionary)
@export var status : String = "unrefined"

# timeout time changeable, just make sure not too small (0.01>)
func _on_interaction_started(player: Player) -> void:
	var item : Dictionary = player.item_manager.remove_held_item(status)
	if item:
		item_added.emit(item)
	get_tree().create_timer(0.5).timeout.connect(end_interaction)
