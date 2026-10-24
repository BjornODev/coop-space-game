class_name PlayerView extends SubViewportContainer

@onready var subviewport: SubViewport = %SubViewport as SubViewport
@onready var camera_2d: Camera2D = %Camera2D as Camera2D
@onready var camera_3d: Camera3D = %Camera3D as Camera3D

func set_viewport_world_2d(new_world_2d: World2D) -> void:
	subviewport.world_2d = new_world_2d

func set_viewport_world_3d(new_world_3d: World3D) -> void:
	subviewport.world_3d = new_world_3d

func get_viewport_world_2d() -> World2D:
	return subviewport.world_2d

func get_viewport_world_3d() -> World3D:
	return subviewport.world_3d

func add_game(game: Node) -> void:
	subviewport.add_child(game)

## Returns relevant camera and makes the camera valid.
func get_camera(in_3d: bool) -> Node:
	if in_3d:
		camera_3d.process_mode = Node.PROCESS_MODE_INHERIT
		camera_2d.process_mode = Node.PROCESS_MODE_DISABLED
		return camera_3d
	else:
		camera_2d.process_mode = Node.PROCESS_MODE_INHERIT
		camera_3d.process_mode = Node.PROCESS_MODE_DISABLED
		return camera_2d
