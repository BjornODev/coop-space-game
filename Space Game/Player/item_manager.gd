extends Node

var item_being_held : Dictionary = {}
const PHYSICS_ITEM = preload("res://Space Game/Space Ship/Processing/PhysicsItem/physics_item.tscn")

func add_item(item : Dictionary) -> bool:
	if item["Texture"]:
		pass #TODO set item texture
	
	if not item_being_held:
		item_being_held = item
		return true # item was grabbed
	else:
		return false # player is already holding item

func remove_held_item() -> Dictionary:
	var item : Dictionary = item_being_held
	if item:
		item_being_held = {}
		return item
	return {} # no item held returns empty set

func drop_held_item(global_pos : Vector2) -> void:
	if not item_being_held:
		return
	
	var new_item = PHYSICS_ITEM.instantiate()
	new_item.item_type = item_being_held
	item_being_held = {}
	add_child(new_item)
	new_item.set_global_position(global_pos)
