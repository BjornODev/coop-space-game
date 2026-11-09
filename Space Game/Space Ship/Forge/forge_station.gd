## Turns one unrefined ore item, of any purity, into one hull plate after process_time seconds.
class_name ForgeStation extends TimedItemStation

func _make_output(_input_item: Dictionary) -> Dictionary:
	return ShipItems.create_hull_plate()

func _get_working_text() -> String:
	return "Forging"
