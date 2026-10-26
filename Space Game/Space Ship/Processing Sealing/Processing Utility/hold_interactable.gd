## An Interactable that counts as held for as long as a player stays in the interaction, such as a lever or a valve.
## The player lets go with the cancel button (B). Can't be started while holding an item.
## Used as is for the seal levers. Extend it and override _on_held_changed() for anything that needs more.
class_name HoldInteractable extends Interactable

## Emitted when a player starts or stops holding this.
signal held_changed(is_held: bool)

@onready var _state_label: Label = $StateLabel

func _ready() -> void:
	_update_readout()

#region Overridable hooks

## Override to react to this being grabbed or let go of.
func _on_held_changed(_is_held: bool) -> void:
	pass

#endregion

#region Interactable hooks

func can_interact(player: Player) -> bool:
	return super.can_interact(player) and Grabbable.get_held_by(player) == null

func _on_interaction_started(_player: Player) -> void:
	_set_held(true)

func _on_interaction_ended(_player: Player) -> void:
	_set_held(false)

func _interaction_process(_player: Player, _delta: float) -> void:
	if Input.is_action_just_pressed(get_player_input().B):
		end_interaction()

#endregion

func is_held() -> bool:
	return is_interacting()

func _set_held(held: bool) -> void:
	_update_readout()
	_on_held_changed(held)
	held_changed.emit(held)

func _update_readout() -> void:
	_state_label.text = "HELD" if is_held() else "-"
