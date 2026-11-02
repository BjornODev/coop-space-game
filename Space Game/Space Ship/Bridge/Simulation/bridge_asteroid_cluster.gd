## A group of asteroids scattered around one random center. The route view shows each one as a single cloud.
class_name BridgeAsteroidCluster extends RefCounted

## The asteroids placed in this cluster.
var asteroids: Array[BridgeAsteroid] = []

## Average position of this cluster's asteroids. Moves as drifting asteroids drift.
func get_center() -> Vector2:
	if asteroids.is_empty():
		return Vector2.ZERO
	var total: Vector2 = Vector2.ZERO
	for asteroid: BridgeAsteroid in asteroids:
		total += asteroid.position
	return total / asteroids.size()

## Distance from get_center() to the outer edge of the furthest asteroid.
func get_extent() -> float:
	var center: Vector2 = get_center()
	var extent: float = 0.0
	for asteroid: BridgeAsteroid in asteroids:
		extent = maxf(extent, center.distance_to(asteroid.position) + asteroid.radius)
	return extent
