extends Node

var item_being_held : Dictionary = {}
const PHYSICS_ITEM = preload("res://Space Game/Space Ship/Processing/PhysicsItem/physics_item.tscn")

signal set_item_texture(texture : Texture2D)

func add_item(item : Dictionary) -> bool:
	if item["Texture"]:
		set_item_texture.emit(item["Texture"])
	else:
		set_item_texture.emit(null)
	
	if not item_being_held:
		item_being_held = item
		return true # item was grabbed
	else:
		return false # player is already holding item

func remove_held_item(status : String) -> Dictionary:
	var item : Dictionary = item_being_held
	if not item:
		return {} # no item held returns empty set
	elif item["Status"] == status:
		reset_item_held()
		return item
	return {} 

func drop_held_item(global_pos : Vector2) -> void:
	if not item_being_held:
		return
	
	var new_item = PHYSICS_ITEM.instantiate()
	new_item.item = item_being_held
	reset_item_held()
	add_child(new_item)
	new_item.set_global_position(global_pos)

func reset_item_held() -> void:
	item_being_held = {}
	set_item_texture.emit(null)
