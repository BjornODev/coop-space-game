extends Game2D

var player = preload("res://Space Game/Player/player.tscn")

## Distance between players when they spawn.
const SPAWN_SPACING = 120

## Called by the framework once player select is done.
func start(player_count: int, joined_players: Array[bool], _zoom_matching) -> void:
	var stored_players = []

	# player number comes from joined_players index so each player keeps the controls they joined with
	for i in joined_players.size():
		if joined_players[i]:
			var new_player = player.instantiate()
			add_child(new_player)
			new_player.set_player_num(i + 1)
			stored_players.append(new_player)

	# camera number comes from join order so the visible screens are always filled first
	for i in stored_players.size():
		stored_players[i].position = Vector2((i - (stored_players.size() - 1) / 2.0) * SPAWN_SPACING, 0)
		var camera: Camera2D = Cameras.get_camera(i + 1)
		# screens get smaller with more players, so zoom out to compensate
		if player_count >= 3:
			camera.zoom = Vector2(0.5, 0.5)
		elif player_count == 2:
			camera.zoom = Vector2(0.75, 0.75)
		else:
			camera.zoom = Vector2.ONE
		stored_players[i].set_camera(camera)

	number_of_players = player_count
