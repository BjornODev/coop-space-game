## Asteroid colors shared by every bridge display, so an asteroid looks the same on every radar.
class_name AsteroidPalette extends Resource

## Color of every asteroid that hasn't been scanned yet.
@export var unscanned_color: Color = Color(0.255, 0.412, 0.882)
## Color of scanned asteroids by value. Offset 0 is the least valuable (red), offset 1 the most valuable (light green).
@export var value_gradient: Gradient

## The color asteroid should be drawn in right now.
func get_color(asteroid: BridgeAsteroid) -> Color:
	if not asteroid.is_scanned or value_gradient == null:
		return unscanned_color
	return value_gradient.sample(asteroid.value_ratio)
