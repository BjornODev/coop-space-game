extends Node2D

@onready var engine: Interactable = $Engine
@onready var capsule_container: HBoxContainer = $CapsuleContainer
const CAPSULE_PLACEHOLDER = preload("res://Space Game/Space Ship/Engine/capsule_placeholder.tscn")

var capsule_slots : Array = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	engine.connect("item_added",_add_capsule)
	
	for i in range(5):
		var placeholder :Control= CAPSULE_PLACEHOLDER.instantiate()
		capsule_container.add_child(placeholder)
		capsule_slots.append(placeholder)

func _add_capsule(item : Dictionary) -> void:
	for slot in capsule_slots:
		if not slot.capsule["Activated"]:
			slot.capsule["fuel_left"] = item["Status"]
			slot.capsule["Activated"] = true
			return
	
	printerr("no available slots!")
	
