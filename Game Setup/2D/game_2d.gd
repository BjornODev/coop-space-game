## Extend this class to set up a 2D coop game!
class_name Game2D extends Game

func start(player_count: int, joined_players: Array[bool], zoom_matching: bool) -> void:
	var stored_players = []
	
	# adds players to scene by player_num so they match their control scheme
	for i in joined_players.size():
		if joined_players[i]:
			var new_player : Player2D = (load(PLAYER_SCENE) as PackedScene).instantiate() as Player2D
			if new_player ==  null:
				printerr("%s: Player scene in PLAYER_SCENE export does not inherit from Player2D. If you have set up your own player, replace the Player2D typecasting in this game_2d.gd with your custom class!" % self)
				return
			add_child(new_player)
			new_player.set_player_num(i + 1)
			stored_players.append(new_player)
	
	# then iterates through player list to assign cameras by order so they match splitscreen set-up
	for i in stored_players.size():
		if zoom_matching:
			if player_count >= 3:
				# zooms out cameras for when there's more players?
				Cameras.get_camera(i + 1).zoom = Vector2(0.5, 0.5)
			elif player_count == 2:
				# zooms out cameras for when there's more players?
				Cameras.get_camera(i + 1).zoom = Vector2(0.75, 0.75)
		stored_players[i].set_camera(Cameras.get_camera(i + 1))
	
	number_of_players = player_count
