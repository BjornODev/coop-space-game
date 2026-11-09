## One thing an alert arrow can point at. MalfunctionManager builds a fresh list of these for each player every frame.
class_name AlertTarget extends RefCounted

var type: Malfunction.Type
## Where the malfunction is, in global coordinates.
var position: Vector2

func _init(target_type: Malfunction.Type, target_position: Vector2) -> void:
	type = target_type
	position = target_position
