extends Game2D

var player = preload("res://Space Game/Player/player.tscn")
const PLAYER_HUD = preload("res://Space Game/Space Ship/Malfunctions/HUD/player_hud.tscn")
const GUIDE_HUD = preload("res://Space Game/Space Ship/Guidance/guide_hud.tscn")

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

## Distance between players when they spawn.
const SPAWN_SPACING = 120

@onready var fuel_ticker: Timer = $FuelTicker
@export var fuel_ticker_speed : float = 0.05

## Kept from start() so a restart brings back the same players with the same controls.
var _joined_players: Array[bool] = []
var _zoom_matching: bool = true
var _huds: Array[PlayerHud] = []
var _guide_huds: Array[GuideHud] = []
var _restarting: bool = false

func _ready() -> void:
	_apply_layout()
	var suction_to_refining : TerminalPort = sorting_unit.sorting_minigame.suction_to_refining
	suction_to_refining.connect("suction_tube_entered",refining_unit.item_spawn_area.spawn_ore,CONNECT_DEFERRED)
	bridge.space_simulation.connect("asteroid_harvested",sorting_unit.send_item_to_spawn_area,CONNECT_DEFERRED)

	bridge.navigation_screen.connect("requesting_boost",toggle_boosting)
	fuel_ticker.wait_time = fuel_ticker_speed
	fuel_ticker.connect("timeout",toggle_boosting)
	if malfunction_manager != null:
		malfunction_manager.mission_failed.connect(_on_mission_failed)

## Called by the framework once player select is done.
func start(player_count: int, joined_players: Array[bool], zoom_matching) -> void:
	_joined_players = joined_players.duplicate()
	_zoom_matching = zoom_matching
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
		# screens get smaller with more players, so zoom out to compensate
		if player_count >= 3:
			camera.zoom = Vector2(0.5, 0.5)
		elif player_count == 2:
			camera.zoom = Vector2(0.75, 0.75)
		else:
			camera.zoom = Vector2.ONE
		stored_players[i].set_camera(camera)
		_add_guide_hud(stored_players[i], camera)
		if malfunction_manager != null:
			_add_hud(stored_players[i], camera)

	number_of_players = player_count
	if malfunction_director != null:
		malfunction_director.player_count = player_count

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

## Gives player a HUD drawn into the splitscreen viewport their camera renders.
func _add_hud(hud_player: Player, camera: Camera2D) -> void:
	var hud: PlayerHud = PLAYER_HUD.instantiate() as PlayerHud
	add_child(hud)
	hud.setup(malfunction_manager, hud_player, camera.get_viewport())
	hud.restart_requested.connect(restart_run)
	_huds.append(hud)

## Gives player an arrow that shows where to take the ore or canister they carry.
func _add_guide_hud(hud_player: Player, camera: Camera2D) -> void:
	var guide: GuideHud = GUIDE_HUD.instantiate() as GuideHud
	add_child(guide)
	guide.setup(hud_player, camera.get_viewport(), refining_unit.input_terminal, refining_unit.output_terminal, engine_unit)
	_guide_huds.append(guide)

## Freezes the ship and shows every player which meter filled.
func _on_mission_failed(type: Malfunction.Type) -> void:
	get_tree().paused = true
	for guide: GuideHud in _guide_huds:
		guide.visible = false
	for hud: PlayerHud in _huds:
		hud.show_mission_failed(type)

func _find_framework_control() -> FrameworkControl:
	var node: Node = get_parent()
	while node != null:
		if node is FrameworkControl:
			return node
		node = node.get_parent()
	return null
