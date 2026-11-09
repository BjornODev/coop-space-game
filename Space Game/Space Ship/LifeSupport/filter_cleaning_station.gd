## Cleans life support filters. A filter put in comes back out fully clean after process_time seconds.
class_name FilterCleaningStation extends TimedItemStation

## Dirtiness where a filter starts to look dirty. Keep this matching the life support unit's value.
@export var dirty_threshold: float = 0.5

func _make_output(input_item: Dictionary) -> Dictionary:
	ShipItems.set_filter_dirtiness(input_item, 0.0, dirty_threshold)
	return input_item

func _get_working_text() -> String:
	return "Cleaning"
