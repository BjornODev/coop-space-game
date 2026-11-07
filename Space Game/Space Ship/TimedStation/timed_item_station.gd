## A station that takes items at its input terminal, works on each one for process_time seconds,
## and drops the result out of its ItemSpawnArea, like the refinery. Items wait in a queue if several go in.
## Extend this and override _make_output() to decide what comes out.
## Needs children named InputTerminal (a terminal port with input_terminal.gd), ItemSpawnArea, ProgressBar, StatusLabel and Indicator.
@abstract
class_name TimedItemStation extends Node2D

## Emitted when an item finishes and is dropped out of the output.
signal item_finished(item: Dictionary)

## Seconds to work on one item.
@export var process_time: float = 8.0
## Indicator color while waiting for an item.
@export var idle_color: Color = Color(1.0, 0.0, 0.0)
## Indicator color while working.
@export var working_color: Color = Color(0.0, 1.0, 0.0)

@onready var input_terminal: Interactable = $InputTerminal
@onready var item_spawn_area: Node2D = $ItemSpawnArea
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var status_label: Label = $StatusLabel
@onready var indicator: ColorRect = $Indicator

var _queue: Array[Dictionary] = []
var _progress: float = 0.0

func _ready() -> void:
	input_terminal.connect("item_added", _on_item_added)
	_update_display()

func _process(delta: float) -> void:
	if not _queue.is_empty():
		_progress += delta
		if _progress >= process_time:
			_progress = 0.0
			var output: Dictionary = _make_output(_queue.pop_front())
			item_spawn_area.spawn_ore(output)
			item_finished.emit(output)
	_update_display()

## Number of items waiting, including the one being worked on.
func get_queue_size() -> int:
	return _queue.size()

## Builds the item that comes out once input_item is done.
@abstract func _make_output(input_item: Dictionary) -> Dictionary

## Text shown while working, like "Forging".
func _get_working_text() -> String:
	return "Working"

func _on_item_added(item: Dictionary) -> void:
	_queue.append(item)

func _update_display() -> void:
	var working: bool = not _queue.is_empty()
	indicator.color = working_color if working else idle_color
	progress_bar.value = (_progress / process_time if working and process_time > 0.0 else 0.0) * progress_bar.max_value
	if working:
		status_label.text = "%s... (%d queued)" % [_get_working_text(), _queue.size()]
	else:
		status_label.text = "Idle"
