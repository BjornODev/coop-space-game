## Routes interact presses for grabbing, dropping, and inserting held items, on top of the framework's Player routing.
## Put one in the scene. It runs before every other node each physics frame.
##
## Rules it enforces when a player presses interact (and isn't already interacting):
## - Holding an item: start the nearest CanisterSlot that accepts it, otherwise drop the item at the player's position.
## - Empty-handed: whichever is nearer wins, the nearest grabbable item or the nearest Interactable that accepts the player.
##   If the Interactable wins, the press is left to the Player, which starts it as usual.
##
## The Player reacts to interact presses on its own, so when this node uses a press, it hides that player's nearby
## Interactables (through Player.exit_interaction_range) for that one frame so the Player doesn't also act on it.
## They are handed back on the next frame.
class_name GrabRouter extends Node

## Emitted after this node uses a player's interact press for a grab, a drop, or starting a slot.
signal press_used(player: Player)

## Every Player in the tree.
var _players: Array[Player] = []
## Every Interactable in the tree.
var _interactables: Array[Interactable] = []
## Players whose nearby Interactables were hidden this frame, and need them handed back next frame.
var _hidden_from: Array[Player] = []

func _ready() -> void:
	# runs before Players and Interactables (priority 0), so it sees each press first
	process_physics_priority = -100
	for node in get_tree().root.find_children("*", "", true, false):
		_track(node)
	get_tree().node_added.connect(_track)

func _physics_process(_delta: float) -> void:
	_restore_hidden()
	for player in _players:
		# while interacting, the Interactable owns the buttons
		if player.current_interaction != null:
			continue
		var input: PlayerInput = CoopInput.get_player(player.player_number)
		if not Input.is_action_just_pressed(input.A):
			continue
		if _route_press(player):
			_hide_interactables_from(player)
			press_used.emit(player)

## Decides what an interact press does. Returns true if this node used it, false to leave it to the Player.
func _route_press(player: Player) -> bool:
	var held := Grabbable.get_held_by(player)
	if held != null:
		var slots: Array[Node2D] = []
		for interactable in _interactables:
			if interactable is CanisterSlot and interactable.overlaps_body(player) and interactable.can_interact(player):
				slots.append(interactable)
		var slot := _nearest(player, slots) as CanisterSlot
		if slot != null:
			slot.interact(player)
		else:
			held.drop()
		return true

	var grabbables: Array[Node2D] = []
	for node in get_tree().get_nodes_in_group(Grabbable.GROUP):
		var grabbable := node as Grabbable
		if grabbable != null and grabbable.overlaps_body(player) and grabbable.can_grab(player):
			grabbables.append(grabbable)
	var nearest_grabbable := _nearest(player, grabbables) as Grabbable
	if nearest_grabbable == null:
		return false

	var interactables: Array[Node2D] = []
	for interactable in _interactables:
		if interactable.overlaps_body(player) and interactable.can_interact(player):
			interactables.append(interactable)
	var nearest_interactable := _nearest(player, interactables)
	if nearest_interactable != null and _distance_squared(player, nearest_interactable) < _distance_squared(player, nearest_grabbable):
		return false

	nearest_grabbable.grab(player)
	return true

## Removes every Interactable from the player's range so the Player ignores this frame's press.
func _hide_interactables_from(player: Player) -> void:
	for interactable in _interactables:
		player.exit_interaction_range(interactable)
	if not _hidden_from.has(player):
		_hidden_from.append(player)

## Gives players back the Interactables they are still standing in.
func _restore_hidden() -> void:
	for player in _hidden_from:
		if not is_instance_valid(player):
			continue
		for interactable in _interactables:
			if interactable.overlaps_body(player):
				player.enter_interaction_range(interactable)
	_hidden_from.clear()

func _nearest(player: Player, nodes: Array[Node2D]) -> Node2D:
	var nearest: Node2D = null
	for node in nodes:
		if nearest == null or _distance_squared(player, node) < _distance_squared(player, nearest):
			nearest = node
	return nearest

func _distance_squared(player: Player, node: Node2D) -> float:
	return player.global_position.distance_squared_to(node.global_position)

func _track(node: Node) -> void:
	if node is Player and not _players.has(node):
		_players.append(node)
		node.tree_exited.connect(_untrack.bind(node), CONNECT_ONE_SHOT)
	elif node is Interactable and not _interactables.has(node):
		_interactables.append(node)
		node.tree_exited.connect(_untrack.bind(node), CONNECT_ONE_SHOT)

func _untrack(node: Node) -> void:
	# typed arrays refuse values of the wrong type, so only erase from the matching ones
	if node is Player:
		_players.erase(node)
		_hidden_from.erase(node)
	elif node is Interactable:
		_interactables.erase(node)
