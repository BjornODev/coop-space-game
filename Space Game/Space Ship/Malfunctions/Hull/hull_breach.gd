## A hole in the hull. Pulls loose items and players toward it until someone patches it.
## To patch: carry a hull plate here and hold A for repair_time. The plate is used up and the breach closes.
## HullBreachSystem creates these on hull wall tiles; don't place them by hand.
class_name HullBreach extends Interactable

## Emitted once the breach is patched, right before it is freed.
signal repaired(breach: HullBreach)

## Things within this many pixels are pulled toward the breach.
@export var pull_radius: float = 420.0
## Pull on loose items at the breach itself, in pixels per second squared. Fades to 0 at pull_radius.
@export var item_pull_strength: float = 500.0
## Speed players are dragged at, at the breach itself, in pixels per second. Fades to 0 at pull_radius.
## Players walk at 250, so values near that make walking away from a breach hard.
@export var player_pull_strength: float = 170.0
## Seconds of holding A with a hull plate to patch the breach.
@export var repair_time: float = 3.0
## Status of the item needed to patch the breach.
@export var plate_status: String = ShipItems.STATUS_HULL_PLATE

@onready var _visuals: Node2D = $Visuals
@onready var _pull_shape: CollisionShape2D = $PullArea/CollisionShape2D
@onready var _pull_area: Area2D = $PullArea
@onready var _repair_bar: ProgressBar = $RepairBar
@onready var _countdown_label: Label = $CountdownLabel
@onready var _repair_prompt: ButtonPrompt = $RepairPrompt

## The hull wall cell this breach is on.
var cell: Vector2i = Vector2i.ZERO
## Points from the ship's inside to the outside, through this breach.
var outward_direction: Vector2 = Vector2.UP

var _repair_progress: float = 0.0

func _ready() -> void:
	var shape: CircleShape2D = _pull_shape.shape as CircleShape2D
	if shape != null:
		shape.radius = pull_radius
	# the visuals are drawn with the outside of the ship pointing up
	_visuals.rotation = outward_direction.angle() + PI * 0.5
	_repair_bar.visible = false

func _physics_process(_delta: float) -> void:
	for body: Node2D in _pull_area.get_overlapping_bodies():
		var offset: Vector2 = global_position - body.global_position
		var falloff: float = clampf(1.0 - offset.length() / pull_radius, 0.0, 1.0)
		var direction: Vector2 = offset.normalized()
		if body is Player:
			body.apply_pull(direction * player_pull_strength * falloff)
		elif body is PhysicsItem:
			var physics_item: PhysicsItem = body
			physics_item.apply_central_force(direction * item_pull_strength * falloff * physics_item.mass)

## Sets the breach up before it is added to the tree.
func setup(breach_cell: Vector2i, outward: Vector2) -> void:
	cell = breach_cell
	outward_direction = outward

## Shows text (the time until the hull meter fills) on the breach.
func set_countdown_text(text: String) -> void:
	_countdown_label.text = text

#region Interactable hooks

## Only a player carrying a hull plate can start patching.
func can_interact(player: Player) -> bool:
	return current_player == null and ShipItems.has_status(player.item_manager.item_being_held, plate_status)

func _on_interaction_started(player: Player) -> void:
	_repair_progress = 0.0
	_repair_bar.value = 0.0
	_repair_bar.visible = true
	_repair_prompt.show_for_actions([CoopInput.get_player(player.player_number).A])
	_repair_prompt.set_active(true)

func _on_interaction_ended(_player: Player) -> void:
	_repair_progress = 0.0
	_repair_bar.visible = false
	_repair_prompt.set_active(false)
	_repair_prompt.show_default()

## Letting go of A before the time is up cancels the repair.
func _interaction_process(player: Player, delta: float) -> void:
	if not Input.is_action_pressed(get_player_input().A):
		end_interaction()
		return
	_repair_progress += delta
	_repair_bar.value = clampf(_repair_progress / repair_time, 0.0, 1.0) * _repair_bar.max_value
	if _repair_progress >= repair_time:
		player.item_manager.remove_held_item(plate_status)
		end_interaction()
		repaired.emit(self)
		queue_free()

#endregion
