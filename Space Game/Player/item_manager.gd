extends Node

var item_being_held : Dictionary = {}

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
	item_being_held = {}
	return item # if there was no item held, returns empty set
	#TODO: add dropping item into world
