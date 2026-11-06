extends Game2D

var player = preload("res://Space Game/Player/player.tscn")
@onready var sorting_unit: Node2D = $SortingUnit
@onready var refining_unit: Node2D = $RefiningUnit
@onready var bridge: Node2D = $Bridge
@onready var engine_unit: Node2D = $EngineUnit

## Distance between players when they spawn.
const SPAWN_SPACING = 120

@onready var fuel_ticker: Timer = $FuelTicker
@export var fuel_ticker_speed : float = 0.05

func _ready() -> void:
	var suction_to_refining : TerminalPort = sorting_unit.sorting_minigame.suction_to_refining
	suction_to_refining.connect("suction_tube_entered",refining_unit.item_spawn_area.spawn_ore,CONNECT_DEFERRED)
	bridge.space_simulation.connect("asteroid_harvested",sorting_unit.send_item_to_spawn_area,CONNECT_DEFERRED)
	
	bridge.navigation_screen.connect("requesting_boost",toggle_boosting)
	fuel_ticker.wait_time = fuel_ticker_speed
	fuel_ticker.connect("timeout",toggle_boosting)

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

func toggle_boosting(attempting_boost : bool = true) -> void:
	if not attempting_boost:
		fuel_ticker.stop()
	elif not engine_unit.drain_fuel(1):
		disable_boosting()
	else:
		fuel_ticker.start()

func _process(_delta: float) -> void:
	if engine_unit and bridge.fuel_label:
		var fuel_amt : int = engine_unit.drain_fuel(0)
		bridge.fuel_label.text = "Fuel Available: " + str(fuel_amt)

func disable_boosting() -> void:
	fuel_ticker.stop()
	bridge.navigation_screen._boost_armed = false
