extends RigidBody2D

@onready var grab_area: Interactable = $GrabArea

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	grab_area.connect("item_grabbed", remove_item)

func remove_item() -> void:
	queue_free()
