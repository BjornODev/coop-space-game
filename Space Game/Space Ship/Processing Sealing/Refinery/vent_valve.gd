## A refinery vent valve on one side of the ship. Held open by staying in the interaction.
## While open, the refinery loses vent_rate pressure per second, and the ship should drift toward this valve's side.
## Steering is not part of processing, so the drift is only reported through venting_changed and is_venting().
class_name VentValve extends HoldInteractable

## Emitted when this valve opens or closes. The ship should drift toward side while is_venting is true.
signal venting_changed(side: ShipSide.Side, is_venting: bool)

## Which side of the ship this valve is on, and so which way venting pushes the ship.
@export var side: ShipSide.Side = ShipSide.Side.LEFT
## Pressure removed from the refinery per second while this valve is open.
@export var vent_rate: float = 12.0

#region HoldInteractable hooks

func _on_held_changed(held: bool) -> void:
	venting_changed.emit(side, held)

#endregion

func is_venting() -> bool:
	return is_held()
