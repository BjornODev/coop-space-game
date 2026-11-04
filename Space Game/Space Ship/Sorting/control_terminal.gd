@tool extends TerminalPort

var current_player_num : int = 0

# timeout time changeable, just make sure not too small (0.01>)
func _on_interaction_started(player: Player) -> void:
	current_player_num = player.player_number

func _input(event: InputEvent) -> void:
	if not current_player_num:
		return
	
	var player_action = CoopInput.get_player(current_player_num)
	if event.is_action_pressed(player_action.A):
		print("ah")
	elif event.is_action_pressed(player_action.B):
		current_player_num = 0
		end_interaction()
