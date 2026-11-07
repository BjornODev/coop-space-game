## The life support unit's filter slot. Works like the engine's capsule slots.
@tool
class_name FilterSlot extends TerminalPort

## Emitted when a player puts a filter into the empty slot.
signal filter_inserted(item: Dictionary)
## Emitted when an empty-handed player takes the installed filter out.
signal filter_removal_requested(player: Player)

## Status of items the slot accepts.
@export var status: String = ShipItems.STATUS_FILTER
## Seconds the player is held at the slot after using it.
@export var buffer_time: float = 0.5

## True while a filter is installed. Set by the life support unit.
var has_filter: bool = false

# works like the engine's capsule slots: empty-handed takes the filter out, holding a filter puts it in
func _on_interaction_started(player: Player) -> void:
	get_tree().create_timer(buffer_time).timeout.connect(end_interaction)

	if not has_filter:
		var item: Dictionary = player.item_manager.remove_held_item(status)
		if item:
			filter_inserted.emit(item)
	elif not player.item_manager.item_being_held:
		filter_removal_requested.emit(player)
