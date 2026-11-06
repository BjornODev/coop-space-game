extends Node2D

const PURITY_LABEL = preload("res://Space Game/Space Ship/Sorting/Grabber/purity_label.tscn")
const PHYSICS_ITEM = preload("res://Space Game/Space Ship/PhysicsItem/physics_item.tscn")
@export var sorted_ore_speed : float = 150
@export var show_scanned_enabled : bool = false

func spawn_ore(item : Dictionary) -> void:
	var sorted_ore : PhysicsItem = PHYSICS_ITEM.instantiate()
	add_child(sorted_ore)
	sorted_ore.item = item
	var rand_dir : Vector2 = Vector2(1,randf_range(-PI/2,PI/2)).normalized()
	sorted_ore.apply_central_impulse(rand_dir * sorted_ore_speed)
	
	if show_scanned_enabled and item["is_scanned"]:
		var purity_label = PURITY_LABEL.instantiate()
		sorted_ore.add_child(purity_label)
		
		var purity : float = item["Purity"]
		purity_label.self_modulate = Color(1,0.5 + purity/200,0)
		purity_label.text = str(int(purity))
		purity_label.parent_body = sorted_ore
