class_name PhysicsItem extends RigidBody2D

@onready var grab_area: Interactable = $GrabArea
@onready var sprite_2d: Sprite2D = $Sprite2D

## Longest side, in pixels, that item textures cut from a sprite sheet (AtlasTexture) are shown at.
## The default icon textures keep the sprite's own region and scale.
@export var atlas_item_size: float = 44.0

@export var item : Dictionary = {
	"Texture": preload("res://Framework/Assets/icon.svg"),
	"Status": "unrefined",
	"Purity": 50,
	"is_scanned" : false
}:
	set(value):
		item = value
		# spawners often set the item after adding it to the tree, so refresh the sprite when that happens
		if is_node_ready():
			_update_sprite()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# items placed in a scene can share one dictionary between instances, so each item keeps its own copy
	item = item.duplicate()
	grab_area.connect("item_grabbed", _on_interaction_started)
	_update_sprite()

# timeout time changeable, just make sure not too small (0.01>)
func _on_interaction_started(player: Player) -> void:
	if player.item_manager.add_item(item):
		remove_item()


func remove_item() -> void:
	queue_free()

## Shows the item's texture. Sprite sheet textures are fitted to atlas_item_size instead of using the icon's region.
func _update_sprite() -> void:
	var texture: Texture2D = item.get("Texture")
	sprite_2d.texture = texture
	if texture is AtlasTexture:
		sprite_2d.region_enabled = false
		var longest_side: float = maxf(texture.get_width(), texture.get_height())
		sprite_2d.scale = Vector2.ONE * atlas_item_size / longest_side
