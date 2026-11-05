extends Node2D

const PHYSICS_ITEM = preload("res://Space Game/Space Ship/PhysicsItem/physics_item.tscn")
@export var sorted_ore_speed : float = 150

func spawn_ore(item : Dictionary) -> void:
	var sorted_ore : PhysicsItem = PHYSICS_ITEM.instantiate()
	add_child(sorted_ore)
	sorted_ore.item = item
	var rand_dir : Vector2 = Vector2(1,randf_range(-PI/2,PI/2)).normalized()
	sorted_ore.apply_central_impulse(rand_dir * sorted_ore_speed)
