## Builds and reads the item dictionaries for ship supplies. They use the same format as every other carryable item,
## {"Texture", "Status", "Purity", "is_scanned"}, plus a few extra keys:
## filters keep "Dirtiness" (0 clean to 1 fully clogged), and extinguishers keep "Charge" (negative means unlimited).
class_name ShipItems extends RefCounted

const STATUS_FILTER: String = "filter"
const STATUS_EXTINGUISHER: String = "extinguisher"
const STATUS_HULL_PLATE: String = "hull_plate"
const STATUS_UNREFINED: String = "unrefined"

const FILTER_CLEAN_TEXTURE: Texture2D = preload("res://Space Game/Space Ship/Items/filter_clean_texture.tres")
const FILTER_DIRTY_TEXTURE: Texture2D = preload("res://Space Game/Space Ship/Items/filter_dirty_texture.tres")
const EXTINGUISHER_TEXTURE: Texture2D = preload("res://Space Game/Space Ship/Items/extinguisher_texture.tres")
const HULL_PLATE_TEXTURE: Texture2D = preload("res://Space Game/Space Ship/Items/hull_plate_texture.tres")

## True if item is a real item with the given status. Safe to call with an empty dictionary.
static func has_status(item: Dictionary, status: String) -> bool:
	return not item.is_empty() and item.get("Status", "") == status

#region Filters

## A life support filter. dirty_threshold is the dirtiness where it starts to look dirty.
static func create_filter(dirtiness: float, dirty_threshold: float) -> Dictionary:
	var item: Dictionary = {
		"Texture": FILTER_CLEAN_TEXTURE,
		"Status": STATUS_FILTER,
		"Purity": 0,
		"is_scanned": false,
		"Dirtiness": 0.0,
	}
	set_filter_dirtiness(item, dirtiness, dirty_threshold)
	return item

static func get_filter_dirtiness(item: Dictionary) -> float:
	return item.get("Dirtiness", 0.0)

## Sets how clogged a filter is, from 0 to 1, and swaps its texture once it passes dirty_threshold.
static func set_filter_dirtiness(item: Dictionary, dirtiness: float, dirty_threshold: float) -> void:
	item["Dirtiness"] = clampf(dirtiness, 0.0, 1.0)
	item["Texture"] = FILTER_DIRTY_TEXTURE if item["Dirtiness"] >= dirty_threshold else FILTER_CLEAN_TEXTURE

#endregion

#region Extinguishers

## An extinguisher. A negative charge never runs out.
static func create_extinguisher(charge: float) -> Dictionary:
	return {
		"Texture": EXTINGUISHER_TEXTURE,
		"Status": STATUS_EXTINGUISHER,
		"Purity": 0,
		"is_scanned": false,
		"Charge": charge,
	}

## True if the extinguisher still has something to spray.
static func extinguisher_has_charge(item: Dictionary) -> bool:
	var charge: float = item.get("Charge", -1.0)
	return charge < 0.0 or charge > 0.0

## Uses up amount of charge. Returns false if the extinguisher was already empty.
## Unlimited extinguishers (negative charge) never change.
static func use_extinguisher_charge(item: Dictionary, amount: float) -> bool:
	if not extinguisher_has_charge(item):
		return false
	var charge: float = item.get("Charge", -1.0)
	if charge >= 0.0:
		item["Charge"] = maxf(charge - amount, 0.0)
	return true

#endregion

## A hull plate, used up when patching a hull breach.
static func create_hull_plate() -> Dictionary:
	return {
		"Texture": HULL_PLATE_TEXTURE,
		"Status": STATUS_HULL_PLATE,
		"Purity": 0,
		"is_scanned": false,
	}
