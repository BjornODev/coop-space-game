## One asteroid on a radar, drawn as a square. RadarDisplay creates and positions these,
## and frees them when the asteroid leaves range. The blip's origin is the asteroid's center.
class_name RadarBlip extends Control

## Pixels between the blip's edge and its fuel label or scan bar.
@export var label_gap: float = 3.0
## Size in pixels of the scan progress bar under the blip.
@export var scan_bar_size: Vector2 = Vector2(30.0, 4.0)

@onready var _body: ColorRect = $Body
@onready var _fuel_label: Label = $FuelLabel
@onready var _scan_bar: ColorRect = $ScanBar
@onready var _scan_bar_fill: ColorRect = $ScanBar/Fill

## Shows asteroid at radius_px pixels in color. show_details adds scan progress and the fuel number (scanner radar only).
func show_asteroid(asteroid: BridgeAsteroid, radius_px: float, color: Color, show_details: bool) -> void:
	_body.position = Vector2(-radius_px, -radius_px)
	_body.size = Vector2.ONE * radius_px * 2.0
	_body.color = color

	var ratio: float = asteroid.get_scan_ratio()
	_scan_bar.visible = show_details and not asteroid.is_scanned and ratio > 0.0
	if _scan_bar.visible:
		_scan_bar.size = scan_bar_size
		_scan_bar.position = Vector2(-scan_bar_size.x * 0.5, radius_px + label_gap)
		_scan_bar_fill.size = Vector2(scan_bar_size.x * ratio, scan_bar_size.y)

	_fuel_label.visible = show_details and asteroid.is_scanned
	if _fuel_label.visible:
		_fuel_label.text = str(asteroid.fuel)
		_fuel_label.position = Vector2(radius_px + label_gap, -_fuel_label.size.y * 0.5)
