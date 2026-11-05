extends Label



var parent_body : PhysicsItem
@onready var progress_bar: TextureProgressBar = $ProgressBar
@export var scanning_speed : float = 50
	
func _process(delta: float) -> void:
	if not progress_bar.visible:
		return 
		
	progress_bar.value += delta * scanning_speed
	if progress_bar.value == 100:
		max_lines_visible = -1
		progress_bar.visible = false

func scanning_area_exited(body : Node2D) -> void:
	if body == parent_body and not max_lines_visible:
		queue_free()
