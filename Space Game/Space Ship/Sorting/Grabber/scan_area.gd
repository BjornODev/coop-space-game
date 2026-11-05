extends Area2D

const PURITY_LABEL = preload("res://Space Game/Space Ship/Sorting/Grabber/purity_label.tscn")

func _on_body_entered(body: Node2D) -> void:
	if body is PhysicsItem:
		for child in body.get_children():
			if child is Label:
				return
		
		var purity_label = PURITY_LABEL.instantiate()
		body.add_child(purity_label)
		
		var purity : float = body.item["Purity"]
		purity_label.self_modulate = Color(1,0.5 + purity/200,0)
		purity_label.text = str(int(purity))
		purity_label.parent_body = body
		
		body_exited.connect(purity_label.scanning_area_exited)
		
