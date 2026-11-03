extends Interactable

signal capsule_added(item : Dictionary)
signal capsule_grabbed(player : Player)
var activated : bool = false
@export var status : String = "capsule"
@export var buffer_time : float = 1.0

# timeout time changeable, just make sure not too small (0.01>)
func _on_interaction_started(player: Player) -> void:
	get_tree().create_timer(buffer_time).timeout.connect(end_interaction)
	
	if not activated:
		if not player.item_manager.item_being_held:
			return # no item, no canister to fill
		
		var item : Dictionary = player.item_manager.remove_held_item(status)
		if item:
			capsule_added.emit(item)
			activated = true
	else:
		if player.item_manager.item_being_held:
			return
		
		capsule_grabbed.emit(player)
		activated = false
