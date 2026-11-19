## The game renders at the project's base resolution (display/window/size/viewport_height), but camera zooms, HUD
## layouts and font sizes were tuned when it rendered at REFERENCE_HEIGHT. Multiplying by get_resolution_scale()
## keeps things the same size on screen while drawing them with more pixels, so text and maps stay sharp.
class_name UiScale extends RefCounted

## Window height in pixels that the game's sizes were tuned at (Godot's default 1152x648).
const REFERENCE_HEIGHT: float = 648.0

## How many pixels the game renders now for each pixel it was tuned at. 1080p gives about 1.67.
static func get_resolution_scale() -> float:
	var height: float = float(ProjectSettings.get_setting("display/window/size/viewport_height", REFERENCE_HEIGHT))
	return maxf(height / REFERENCE_HEIGHT, 0.1)
