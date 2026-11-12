extends Control

@onready var indicator: ColorRect = $Indicator
@onready var capsule_grabber: Interactable = $CapsuleGrabber

signal update_fuel_available(amount : int)

var capsule : Dictionary = {
	"Activated": false,
	"fuel_left" : 0,
	"Item":{}}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	capsule_grabber.connect("capsule_added",add_new_capsule)
	capsule_grabber.connect("capsule_grabbed",give_player_capsule)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if not capsule["Activated"]:
		indicator.color = Color("gray")
		return
	
	if capsule["fuel_left"]:
		indicator.color = Color("red")
	else:
		indicator.color = Color("green")

func give_player_capsule(player : Player) -> void:
	capsule["Item"]["Purity"] = capsule["fuel_left"]
	capsule["Item"]["frame"] = ceili(capsule["Item"]["Purity"]/100.0*14.0)
	capsule["Activated"] = false
	player.item_manager.add_item(capsule["Item"])
	
	if capsule["Item"]["Purity"]: # if there is fuel left
		update_fuel_available.emit(-capsule["Item"]["Purity"])

func add_new_capsule(item : Dictionary) -> void:
	capsule["Activated"] = true
	capsule["fuel_left"] = item["Purity"]
	capsule["Item"] = item
	
	update_fuel_available.emit(capsule["fuel_left"])

func drain_fuel_left(amount : int) -> bool:
	if capsule["fuel_left"] >= amount:
		capsule["fuel_left"] -= amount
		return true
	else:
		return false
