extends RigidBody2D

@onready var grab_area: Interactable = $GrabArea
@onready var item_type : Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	grab_area.connect("item_grabbed", remove_item)
	if item_type:
		grab_area.item = item_type

func remove_item() -> void:
	queue_free()
