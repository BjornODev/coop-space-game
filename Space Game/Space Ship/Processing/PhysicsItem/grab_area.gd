extends Interactable

signal item_grabbed
@export var item : Dictionary = {
	"Texture":"", 
	"Amount":100,
	"Purity" : 0.5
}

# timeout time changeable, just make sure not too small (0.01>)
func _on_interaction_started(player: Player) -> void:
	if player.item_manager.add_item(item):
		item_grabbed.emit()
		
	get_tree().create_timer(0.1).timeout.connect(end_interaction)
