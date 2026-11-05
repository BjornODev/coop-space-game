class_name PhysicsItem extends RigidBody2D

@onready var grab_area: Interactable = $GrabArea
@onready var sprite_2d: Sprite2D = $Sprite2D

@export var item : Dictionary = {
	"Texture": preload("res://Framework/Assets/icon.svg"),
	"Status": "unrefined",
	"Purity": 50,
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	grab_area.connect("item_grabbed", _on_interaction_started)
	sprite_2d.texture = item["Texture"]

# timeout time changeable, just make sure not too small (0.01>)
func _on_interaction_started(player: Player) -> void:
	if player.item_manager.add_item(item):
		remove_item()
		

func remove_item() -> void:
	queue_free()
