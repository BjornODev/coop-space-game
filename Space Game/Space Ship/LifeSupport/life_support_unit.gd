## Keeps the air clean with one filter. The installed filter clogs up at clog_rate whatever else is going on.
## Once it is fully clogged, or no filter is installed, the Oxygen malfunction is active until a filter
## that isn't fully clogged goes in. Use the slot empty-handed to take the filter out, or holding a filter to put one in.
class_name LifeSupportUnit extends Node2D

## Emitted when oxygen starts or stops failing.
signal oxygen_failure_changed(failing: bool)

## Dirtiness added to the installed filter per second. 1 is fully clogged, so 1 / clog_rate is how long a clean filter lasts.
@export var clog_rate: float = 0.011
## Dirtiness of the filter installed at the start of a run.
@export var starting_dirtiness: float = 0.0
## Dirtiness where a filter starts to look dirty.
@export var dirty_threshold: float = 0.5
@export_group("Colors")
## Status light color while the filter is clean.
@export var clean_color: Color = Color(0.2, 0.9, 0.3)
## Status light color while the filter is dirty but still working.
@export var dirty_color: Color = Color(0.95, 0.75, 0.1)
## Status light color while oxygen is failing.
@export var failing_color: Color = Color(1.0, 0.15, 0.1)

@onready var _filter_slot: FilterSlot = $FilterSlot
@onready var _dirtiness_bar: ProgressBar = $DirtinessBar
@onready var _status_label: Label = $StatusLabel
@onready var _status_light: ColorRect = $StatusLight
@onready var _countdown_label: Label = $CountdownLabel

## The installed filter item, or an empty dictionary when the slot is empty.
var installed_filter: Dictionary = {}

var _was_failing: bool = false

func _ready() -> void:
	_filter_slot.filter_inserted.connect(_on_filter_inserted)
	_filter_slot.filter_removal_requested.connect(_on_filter_removal_requested)
	_install(ShipItems.create_filter(starting_dirtiness, dirty_threshold))

func _process(delta: float) -> void:
	if installed_filter:
		var dirtiness: float = ShipItems.get_filter_dirtiness(installed_filter)
		ShipItems.set_filter_dirtiness(installed_filter, dirtiness + clog_rate * delta, dirty_threshold)
	_update_display()
	var failing: bool = is_oxygen_failing()
	if failing != _was_failing:
		_was_failing = failing
		oxygen_failure_changed.emit(failing)

## True while the slot is empty or the installed filter is fully clogged.
func is_oxygen_failing() -> bool:
	return installed_filter.is_empty() or ShipItems.get_filter_dirtiness(installed_filter) >= 1.0

## Where alert arrows point while oxygen is failing.
func get_alert_position() -> Vector2:
	return global_position

## Shows text (the time until the oxygen meter fills) on the unit while oxygen is failing.
func set_countdown_text(text: String) -> void:
	_countdown_label.text = text

func _on_filter_inserted(item: Dictionary) -> void:
	_install(item)

func _on_filter_removal_requested(player: Player) -> void:
	if installed_filter.is_empty():
		return
	if player.item_manager.add_item(installed_filter):
		installed_filter = {}
		_filter_slot.has_filter = false

func _install(item: Dictionary) -> void:
	installed_filter = item
	_filter_slot.has_filter = true

func _update_display() -> void:
	_countdown_label.visible = is_oxygen_failing()
	if installed_filter.is_empty():
		_dirtiness_bar.value = 0.0
		_status_label.text = "NO FILTER"
		_status_light.color = failing_color
		return
	var dirtiness: float = ShipItems.get_filter_dirtiness(installed_filter)
	_dirtiness_bar.value = dirtiness * _dirtiness_bar.max_value
	if dirtiness >= 1.0:
		_status_label.text = "FILTER CLOGGED"
		_status_light.color = failing_color
	elif dirtiness >= dirty_threshold:
		_status_label.text = "Filter dirty"
		_status_light.color = dirty_color
	else:
		_status_label.text = "Filter clean"
		_status_light.color = clean_color
