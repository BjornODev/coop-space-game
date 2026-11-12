class_name PhysicsItem extends RigidBody2D

@onready var grab_area: Interactable = $GrabArea
@onready var sprite_2d: Sprite2D = $Sprite2D

## Longest side, in pixels, that item textures cut from a sprite sheet (AtlasTexture) are shown at.
## The default icon textures keep the sprite's own region and scale.
@export var atlas_item_size: float = 44.0

## for texture, [preload, h_frames, current frame]
@export var item : Dictionary = {
	"Texture": preload("res://Framework/Assets/icon.png"),
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

## Shows the item's texture. Textures no longer use the icon's region.
func _update_sprite() -> void:
	var texture: Texture2D = item.get("Texture")
	
	sprite_2d.texture = texture
	sprite_2d.region_enabled = false
	if not item.has("frame"):
		var longest_side: float = maxf(texture.get_width(), texture.get_height())
		sprite_2d.scale = Vector2.ONE * atlas_item_size / longest_side
	else:
		var shortest_side: float = minf(texture.get_width(), texture.get_height())
		sprite_2d.scale = Vector2.ONE * atlas_item_size / shortest_side
	
	if item.has("frame") and item.has("h_frames"):
		var frame : int = item.get("frame")
		var h_frames : int = item.get("h_frames")
		sprite_2d.hframes = h_frames
		sprite_2d.frame = frame
	else:
		sprite_2d.hframes = 1
		sprite_2d.frame = 0
