extends Game2D

var player = preload("res://Space Game/Player/player.tscn")
const PLAYER_HUD = preload("res://Space Game/Space Ship/Malfunctions/HUD/player_hud.tscn")
const GUIDE_HUD = preload("res://Space Game/Space Ship/Guidance/guide_hud.tscn")
const PAUSE_MENU = preload("res://Space Game/Pause/pause_menu.tscn")

## On: the full ship with every room, plus fire, oxygen, comms and hull malfunctions, the director and the HUD meters.
## Off: a smaller ship with just the bridge, sorting, refinery and engine, and no malfunctions.
## The unused layout is removed when the game starts. In the editor, the small layout sits to the right of the full one.
@export var full_ship_with_malfunctions: bool = true

## Every room, station, and supply that only exists on the full ship.
@onready var full_layout: Node2D = $FullLayout
## The small ship's tilemap, plus markers for where the shared stations go on it.
@onready var simple_layout: Node2D = $SimpleLayout
@onready var malfunctions: Node2D = $Malfunctions
@onready var sorting_unit: Node2D = $SortingUnit
@onready var refining_unit: Node2D = $RefiningUnit
@onready var bridge: Node2D = $Bridge
@onready var engine_unit: Node2D = $EngineUnit
## Players spawn in a row centered here.
@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var fire_system: FireSystem = $Malfunctions/FireSystem
@onready var malfunction_manager: MalfunctionManager = $Malfunctions/MalfunctionManager
@onready var malfunction_director: MalfunctionDirector = $Malfunctions/MalfunctionDirector
## Counts down to the destination. Its time limit is set in start().
@onready var level_timer: LevelTimer = $LevelTimer

## Size of each player's HUD (meters, alert arrows, interact hints, mission failed screen) with 1, 2, 3 and 4 players,
## in pixels of the 1920x1080 render. Smaller splitscreen views get bigger text so it stays readable.
@export var hud_scale_by_player_count: Array[float] = [1.25, 1.5, 1.75, 1.75]

## Distance between players when they spawn.
const SPAWN_SPACING = 120

@onready var fuel_ticker: Timer = $FuelTicker
## Light rumble while the engine burns fuel, heavy jolt when the ship hits an asteroid.
@onready var screen_shake: ScreenShake = $ScreenShake
@export var fuel_ticker_speed : float = 0.05

## Kept from start() so a restart brings back the same players with the same controls.
var _joined_players: Array[bool] = []
var _zoom_matching: bool = true
var _huds: Array[PlayerHud] = []
var _guide_huds: Array[GuideHud] = []
var _restarting: bool = false
var _pause_menu: PauseMenu = null

func _ready() -> void:
	_apply_layout()
	var suction_to_refining : TerminalPort = sorting_unit.sorting_minigame.suction_to_refining
	suction_to_refining.connect("suction_tube_entered",refining_unit.item_spawn_area.spawn_ore,CONNECT_DEFERRED)
	bridge.space_simulation.connect("asteroid_harvested",sorting_unit.send_item_to_spawn_area,CONNECT_DEFERRED)

	bridge.navigation_screen.connect("requesting_boost",toggle_boosting)
	bridge.space_simulation.asteroid_hit.connect(_on_asteroid_hit)
	fuel_ticker.wait_time = fuel_ticker_speed
	fuel_ticker.connect("timeout",toggle_boosting)
	if malfunction_manager != null:
		malfunction_manager.mission_failed.connect(_on_mission_failed)
		level_timer.level_lost.connect(_on_time_ran_out)

## Called by the framework once player select is done.
func start(player_count: int, joined_players: Array[bool], zoom_matching) -> void:
	_joined_players = joined_players.duplicate()
	_zoom_matching = zoom_matching
	# set first, since the HUDs made below size themselves by it
	number_of_players = player_count
	var stored_players = []

	# player number comes from joined_players index so each player keeps the controls they joined with
	for i in joined_players.size():
		if joined_players[i]:
			var new_player = player.instantiate()
			add_child(new_player)
			new_player.set_player_num(i + 1)
			new_player.fire_system = fire_system
			stored_players.append(new_player)

	# camera number comes from join order so the visible screens are always filled first
	for i in stored_players.size():
		stored_players[i].position = player_spawn.position + Vector2((i - (stored_players.size() - 1) / 2.0) * SPAWN_SPACING, 0)
		var camera: Camera2D = Cameras.get_camera(i + 1)
		# screens get smaller with more players, so zoom out to compensate. These zooms were tuned at the old
		# render resolution, so they're scaled up to show the same amount of the ship at the current one.
		var zoom: float = 1.0
		if player_count >= 3:
			zoom = 0.5
		elif player_count == 2:
			zoom = 0.75
		camera.zoom = Vector2.ONE * zoom * UiScale.get_resolution_scale()
		stored_players[i].set_camera(camera)
		screen_shake.add_camera(camera)
		_add_guide_hud(stored_players[i], camera)
		if malfunction_manager != null:
			_add_hud(stored_players[i], camera)

	_add_pause_menu(joined_players)
	if malfunction_director != null:
		malfunction_director.player_count = player_count
	level_timer.start_level(player_count)
	MusicManager.start_level_music()

func toggle_boosting(attempting_boost : bool = true) -> void:
	if not attempting_boost:
		fuel_ticker.stop()
	elif not engine_unit.drain_fuel(1):
		disable_boosting()
	else:
		fuel_ticker.start()

func _process(_delta: float) -> void:
	# the fuel ticker only runs while boosting is actually burning fuel
	screen_shake.set_rumble(not fuel_ticker.is_stopped())
	if engine_unit and bridge.fuel_label:
		var fuel_amt : int = engine_unit.drain_fuel(0)
		bridge.fuel_label.text = "Fuel Available: " + str(fuel_amt)

func _on_asteroid_hit(_asteroid: BridgeAsteroid) -> void:
	screen_shake.impact()

func disable_boosting() -> void:
	fuel_ticker.stop()
	bridge.navigation_screen._boost_armed = false

## Starts the whole run over with the same players: a fresh copy of this scene replaces this one,
## so the space simulation, stations, items, meters, malfunctions and director all start from scratch.
func restart_run() -> void:
	if _restarting:
		return
	_restarting = true
	get_tree().paused = false
	var framework: FrameworkControl = _find_framework_control()
	if framework == null:
		get_tree().reload_current_scene()
		return
	framework.start_game(number_of_players, _joined_players, _zoom_matching)

## Leaves the run and goes back to player select, so players can join, leave, or change controls.
func quit_to_player_select() -> void:
	if _restarting:
		return
	_restarting = true
	get_tree().paused = false
	MusicManager.end_level_music()
	var framework: FrameworkControl = _find_framework_control()
	if framework == null:
		get_tree().reload_current_scene()
		return
	framework.start_player_select()

## Keeps the layout picked by full_ship_with_malfunctions and removes the other one.
## For the small ship, also removes the malfunction systems and moves the shared stations onto its markers.
func _apply_layout() -> void:
	if full_ship_with_malfunctions:
		_remove_node(simple_layout)
		return
	_remove_node(full_layout)
	_remove_node(malfunctions)
	fire_system = null
	malfunction_manager = null
	malfunction_director = null
	var markers: Node = simple_layout.get_node("StationMarkers")
	bridge.global_position = (markers.get_node("Bridge") as Node2D).global_position
	sorting_unit.global_position = (markers.get_node("SortingUnit") as Node2D).global_position
	refining_unit.global_position = (markers.get_node("RefiningUnit") as Node2D).global_position
	refining_unit.output_terminal.global_position = (markers.get_node("OutputTerminal") as Node2D).global_position
	engine_unit.global_position = (markers.get_node("EngineUnit") as Node2D).global_position
	player_spawn.global_position = (markers.get_node("PlayerSpawn") as Node2D).global_position

## Takes node out of the game right away, so its walls and items never touch the players, then frees it.
func _remove_node(node: Node) -> void:
	node.get_parent().remove_child(node)
	node.queue_free()

## Lets any joined player pause with Start. joined_players is indexed by player number - 1.
func _add_pause_menu(joined_players: Array[bool]) -> void:
	var player_numbers: Array[int] = []
	for i: int in joined_players.size():
		if joined_players[i]:
			player_numbers.append(i + 1)
	_pause_menu = PAUSE_MENU.instantiate() as PauseMenu
	add_child(_pause_menu)
	_pause_menu.setup(player_numbers)
	_pause_menu.restart_requested.connect(restart_run)
	_pause_menu.quit_requested.connect(quit_to_player_select)

## Gives player a HUD drawn into the splitscreen viewport their camera renders.
func _add_hud(hud_player: Player, camera: Camera2D) -> void:
	var hud: PlayerHud = PLAYER_HUD.instantiate() as PlayerHud
	add_child(hud)
	hud.setup(malfunction_manager, hud_player, camera.get_viewport(), _get_hud_scale())
	hud.restart_requested.connect(restart_run)
	_huds.append(hud)

## Gives player an arrow that shows where to take the ore or canister they carry.
func _add_guide_hud(hud_player: Player, camera: Camera2D) -> void:
	var guide: GuideHud = GUIDE_HUD.instantiate() as GuideHud
	add_child(guide)
	guide.setup(hud_player, camera.get_viewport(), refining_unit.input_terminal, refining_unit.output_terminal, engine_unit, _get_hud_scale())
	_guide_huds.append(guide)

## Scale for each player's HUD at the current player count.
func _get_hud_scale() -> float:
	if hud_scale_by_player_count.is_empty():
		return 1.0
	var index: int = clampi(number_of_players - 1, 0, hud_scale_by_player_count.size() - 1)
	return hud_scale_by_player_count[index]

## Freezes the ship and shows every player which meter filled.
func _on_mission_failed(type: Malfunction.Type) -> void:
	_disable_pause_menu()
	level_timer.stop()
	MusicManager.end_level_music()
	get_tree().paused = true
	for guide: GuideHud in _guide_huds:
		guide.visible = false
	for hud: PlayerHud in _huds:
		hud.show_mission_failed(type)

## Freezes the ship and tells every player that time ran out, the same way a filled meter does.
func _on_time_ran_out() -> void:
	_disable_pause_menu()
	get_tree().paused = true
	for guide: GuideHud in _guide_huds:
		guide.visible = false
	for hud: PlayerHud in _huds:
		hud.show_time_ran_out()

## The run is over, so Start no longer opens the pause menu over the end screen.
func _disable_pause_menu() -> void:
	if _pause_menu != null:
		_pause_menu.set_enabled(false)

func _find_framework_control() -> FrameworkControl:
	var node: Node = get_parent()
	while node != null:
		if node is FrameworkControl:
			return node
		node = node.get_parent()
	return null
