## Root of the ship's fuel processing: the refinery with its sealer and vent valves, the two engines, the canisters,
## and the GrabRouter that handles grabbing. Spawns the canisters on ready.
## This is the connection point for the future steering system:
## - venting_changed / is_venting() / get_vent_drift(): the ship drifts toward a side while that side's valve is open.
## - dry_changed / is_engine_dry() / get_dry_drift(): the ship drifts toward a side while that side's engine is empty.
## - set_boost(): call every time boost or turn input changes, to drain the right engines.
class_name ShipProcessing extends Node2D

## Relayed from both vent valves. The ship should drift toward side while is_venting is true.
signal venting_changed(side: ShipSide.Side, is_venting: bool)
## Relayed from both engines. The ship should drift toward side while is_dry is true.
signal dry_changed(side: ShipSide.Side, is_dry: bool)

## The canister scene to spawn.
@export var canister_scene: PackedScene
## How many canisters exist. They are all spawned on ready and never destroyed.
@export var canister_count: int = 5
## Distance between spawned canisters, in pixels. They are spread in a row centered on the CanisterSpawn marker.
@export var canister_spacing: float = 100.0

## The refinery, which owns the sealer and both vent valves.
@export var refinery: Refinery
## The engine on the left side of the ship.
@export var left_engine: ShipEngine
## The engine on the right side of the ship.
@export var right_engine: ShipEngine

@onready var _canister_spawn: Marker2D = $CanisterSpawn

func _ready() -> void:
	for valve: VentValve in [refinery.left_valve, refinery.right_valve]:
		valve.venting_changed.connect(venting_changed.emit)
	for engine: ShipEngine in [left_engine, right_engine]:
		engine.dry_changed.connect(dry_changed.emit)
	_spawn_canisters()

## Sets which engines burn extra fuel. turn is -1 (left), 0 (straight), or 1 (right).
## Straight drains both engines. Turning drains the engine on the side the ship turns away from:
## turning right drains the left engine, turning left drains the right engine.
func set_boost(active: bool, turn: float) -> void:
	left_engine.is_boosting = active and turn >= 0.0
	right_engine.is_boosting = active and turn <= 0.0

func get_engine(side: ShipSide.Side) -> ShipEngine:
	return left_engine if side == ShipSide.Side.LEFT else right_engine

func get_vent_valve(side: ShipSide.Side) -> VentValve:
	return refinery.left_valve if side == ShipSide.Side.LEFT else refinery.right_valve

func is_venting(side: ShipSide.Side) -> bool:
	return get_vent_valve(side).is_venting()

func is_engine_dry(side: ShipSide.Side) -> bool:
	return get_engine(side).is_dry()

## Drift from venting along the x axis: -1 toward the left, 1 toward the right, 0 for none or both open.
func get_vent_drift() -> float:
	return _get_drift(is_venting(ShipSide.Side.LEFT), is_venting(ShipSide.Side.RIGHT))

## Drift from dry engines along the x axis: -1 toward the left, 1 toward the right, 0 for none or both dry.
func get_dry_drift() -> float:
	return _get_drift(is_engine_dry(ShipSide.Side.LEFT), is_engine_dry(ShipSide.Side.RIGHT))

## Combines a pull toward each side into one direction on the x axis.
func _get_drift(left: bool, right: bool) -> float:
	return (1.0 if right else 0.0) - (1.0 if left else 0.0)

func _spawn_canisters() -> void:
	for i in canister_count:
		var canister := canister_scene.instantiate() as Canister
		canister.position = _canister_spawn.position + Vector2((i - (canister_count - 1) / 2.0) * canister_spacing, 0.0)
		add_child(canister)
