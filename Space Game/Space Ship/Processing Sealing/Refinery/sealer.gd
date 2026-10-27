## The refinery's sealer. Fills the canister in its slot with refined material after both seal levers are held at once
## for seal_time seconds. Progress drains back while either lever is let go. There is no solo fallback.
## A completed seal moves as much refined material as fits (partial fills allowed), then progress resets for the next one.
class_name Sealer extends Node2D

## Emitted when a seal completes, with how much refined material went into the canister.
signal seal_completed(canister: Canister, amount: float)

## The refinery that supplies refined material.
@export var refinery: Refinery
## The slot holding the canister to fill.
@export var slot: CanisterSlot
## One of the two levers that must both be held.
@export var lever_a: HoldInteractable
## The other lever that must be held.
@export var lever_b: HoldInteractable
## Seconds both levers must be held to complete a seal.
@export var seal_time: float = 2.0
## Seal progress lost per second while not sealing, as a fraction of a full seal (1.0 drains a full bar in a second).
@export var progress_drain_rate: float = 0.5

## Seal progress from 0.0 to 1.0.
var progress: float = 0.0

@onready var _progress_bar: ProgressBar = $SealBar

func _physics_process(delta: float) -> void:
	if can_seal():
		progress += delta / seal_time if seal_time > 0.0 else 1.0
		if progress >= 1.0:
			_complete_seal()
	else:
		progress = maxf(progress - progress_drain_rate * delta, 0.0)
	_progress_bar.value = progress

## True while seal progress is filling: both levers held, a canister that isn't full in the slot, and refined material available.
func can_seal() -> bool:
	return (lever_a.is_held() and lever_b.is_held()
		and slot.canister != null and not slot.canister.is_full()
		and refinery.refined > 0.0)

func _complete_seal() -> void:
	var canister := slot.canister
	var amount := canister.add_fuel(refinery.take_refined(canister.get_space()))
	progress = 0.0
	seal_completed.emit(canister, amount)
