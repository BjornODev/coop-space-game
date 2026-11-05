@tool extends TerminalPort

var current_player_num : int = 0
signal player_playing(player_num : int)

# timeout time changeable, just make sure not too small (0.01>)
func _on_interaction_started(player: Player) -> void:
	current_player_num = player.player_number
	player_playing.emit(current_player_num)

func _input(event: InputEvent) -> void:
	if not current_player_num:
		return
	
	var player_action = CoopInput.get_player(current_player_num)
	if event.is_action_pressed(player_action.B):
		current_player_num = 0
		player_playing.emit(false)
		end_interaction()
