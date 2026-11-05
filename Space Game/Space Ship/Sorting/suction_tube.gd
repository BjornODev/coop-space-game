@tool extends TerminalPort

signal suction_tube_entered(item : Dictionary)

func _init() -> void:
	set_collision_mask_value(3,true)
	set_collision_mask_value(2,false)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is PhysicsItem:
		suction_tube_entered.emit(body.item)
		body.remove_item()
