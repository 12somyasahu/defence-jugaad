class_name JugaadLoop
extends Node2D

signal hands_changed(left: JunkComponent, right: JunkComponent)
signal carried_weapon_changed(weapon: JugaadWeapon)
signal feedback(message: String)
signal weapon_placed(weapon: JugaadWeapon)
signal weapon_picked_up(weapon: JugaadWeapon)
signal components_scattered(items: Array[JunkComponent])

const COMPONENT: PackedScene = preload("res://components/junk_component.tscn")
const WEAPON: PackedScene = preload("res://weapons/jugaad_weapon.tscn")
const PICKUP_DISTANCE: float = 52.0
const ARENA: Rect2 = Rect2(-540, -290, 1080, 580)
# Current playable bounds; starts at ARENA and grows with PrototypeArena stages (M5).
var arena: Rect2 = ARENA
var left_hand: JunkComponent
var right_hand: JunkComponent
var carried_weapon: JugaadWeapon
var player: JugaadPlayer
var workshop: Workshop
var enemies: Node2D
# M7A: handed to every crafted Jugaad so mods apply to existing and future weapons.
var upgrades: UpgradeSystem
var active: bool = true
var _message_remaining: float = 0.0
@onready var components: Node2D = $Components
@onready var weapons: Node2D = $Weapons
@onready var projectiles: Node2D = $Projectiles

func setup(player_node: JugaadPlayer, workshop_node: Workshop, enemy_container: Node2D) -> void:
	player = player_node
	workshop = workshop_node
	enemies = enemy_container
	player.enemies = enemies
	player.hit.connect(_on_player_hit)
	# Fixed prototype supply: two of each recipe pair, plus two Table Fans.
	var supply: Array[int] = [1, 5, 0, 3, 2, 3, 4, 1, 5, 0, 3, 2, 3, 4]
	for i in supply.size():
		var item: JunkComponent = COMPONENT.instantiate()
		item.component_type = supply[i]
		components.add_child(item)
		item.position = Vector2(-450 + (i % 3) * 125, -170 + (i / 3) * 90)
	_update_hands()
	_show_feedback("Find a labeled component, approach, and press E. Q combines two items.")

func _unhandled_input(event: InputEvent) -> void:
	if not active or event.is_echo():
		return
	if event.is_action_pressed("interact"):
		interact()
	elif event.is_action_pressed("combine"):
		combine()
	elif event.is_action_pressed("drop_left"):
		drop_hand(true)
	elif event.is_action_pressed("drop_right"):
		drop_hand(false)

func _process(delta: float) -> void:
	_message_remaining = maxf(0, _message_remaining - delta)
	if _message_remaining == 0:
		$Feedback/Message.text = ""
	queue_redraw()

func interact() -> void:
	if not active:
		return
	if is_instance_valid(carried_weapon):
		_place_weapon()
		return
	var jammed_weapon: JugaadWeapon = _nearest_weapon(true)
	if jammed_weapon != null:
		if jammed_weapon.repair():
			_show_feedback("THAK! %d/%d" % [jammed_weapon.repair_progress, jammed_weapon.repair_hits_required] if jammed_weapon.jammed else "THOKO! %s working again." % JugaadWeapon.NAMES[jammed_weapon.kind])
		return
	var working_weapon: JugaadWeapon = _nearest_weapon(false)
	if working_weapon != null:
		if is_instance_valid(left_hand) or is_instance_valid(right_hand):
			_show_feedback("Drop hand components with 1 / 2 before carrying a Jugaad.")
			return
		working_weapon.pick_up()
		working_weapon.reparent(player)
		working_weapon.position = Vector2(0, -52)
		carried_weapon = working_weapon
		carried_weapon_changed.emit(carried_weapon)
		weapon_picked_up.emit(carried_weapon)
		_update_hands()
		_show_feedback("Picked up %s. E: place again." % JugaadWeapon.NAMES[carried_weapon.kind])
		return
	var nearest: JunkComponent
	var distance: float = PICKUP_DISTANCE * PICKUP_DISTANCE
	for child in components.get_children():
		var item: JunkComponent = child as JunkComponent
		if item == null:
			continue
		var candidate: float = player.global_position.distance_squared_to(item.global_position)
		if candidate <= distance:
			nearest = item
			distance = candidate
	if nearest == null:
		_show_feedback("Move closer to a loose component, then press E.")
		return
	if is_instance_valid(left_hand) and is_instance_valid(right_hand):
		_show_feedback("Both hands full. Q: combine, or 1 / 2: drop.")
		return
	var use_left: bool = not is_instance_valid(left_hand)
	if use_left:
		left_hand = nearest
	else:
		right_hand = nearest
	nearest.reparent(player)
	nearest.position = Vector2(-24 if use_left else 24, -24)
	nearest.set_held(true)
	_show_feedback("Picked up " + nearest.display_name())
	_update_hands()

func _nearest_weapon(want_jammed: bool) -> JugaadWeapon:
	var nearest: JugaadWeapon
	var distance: float = PICKUP_DISTANCE * PICKUP_DISTANCE
	for child in weapons.get_children():
		var weapon: JugaadWeapon = child as JugaadWeapon
		if weapon == null or not weapon.active or not weapon.is_placed or weapon.jammed != want_jammed:
			continue
		var candidate: float = player.global_position.distance_squared_to(weapon.global_position)
		if candidate <= distance:
			nearest = weapon
			distance = candidate
	return nearest

func _on_player_hit(direction: Vector2) -> void:
	if not active:
		return
	var dropped: Array[JunkComponent] = []
	var hands: Array[JunkComponent] = [left_hand, right_hand]
	for i in hands.size():
		var item: JunkComponent = hands[i]
		if not is_instance_valid(item):
			continue
		var at: Vector2 = player.global_position + direction.rotated(-0.8 if i == 0 else 0.8) * 40.0
		# Keep loose junk away from the Workshop and within reachable arena space.
		var from_workshop: Vector2 = at - workshop.global_position
		if from_workshop.length() < 72.0:
			at = workshop.global_position + (from_workshop.normalized() if not from_workshop.is_zero_approx() else direction) * 72.0
		at = at.clamp(arena.position + Vector2(20, 20), arena.end - Vector2(20, 20))
		item.reparent(components)
		item.global_position = at
		item.set_held(false)
		dropped.append(item)
	left_hand = null
	right_hand = null
	_update_hands()
	if not dropped.is_empty():
		components_scattered.emit(dropped)
	_show_feedback("OOF! Junk scattered!" if not dropped.is_empty() else "OOF!")

func drop_hand(left: bool) -> void:
	if not active:
		return
	if is_instance_valid(carried_weapon):
		_show_feedback("Carrying a Jugaad. Use E to place it.")
		return
	var item: JunkComponent = left_hand if left else right_hand
	if not is_instance_valid(item):
		return
	# At the player's feet: always reachable and inside the player's valid arena position.
	item.reparent(components)
	item.global_position = player.global_position
	item.set_held(false)
	if left:
		left_hand = null
	else:
		right_hand = null
	_show_feedback("Dropped " + item.display_name())
	_update_hands()

func combine() -> void:
	if not active:
		return
	if is_instance_valid(carried_weapon) or not is_instance_valid(left_hand) or not is_instance_valid(right_hand):
		_show_feedback("Combine needs one component in each hand.")
		return
	var recipe: int = JugaadRecipes.resolve(left_hand.component_type, right_hand.component_type)
	if recipe < 0:
		_show_feedback("Recipe not implemented yet. Both components kept.")
		return
	left_hand.queue_free()
	right_hand.queue_free()
	left_hand = null
	right_hand = null
	carried_weapon = WEAPON.instantiate()
	carried_weapon.kind = recipe
	carried_weapon.enemies = enemies
	carried_weapon.projectiles = projectiles
	carried_weapon.upgrades = upgrades
	player.add_child(carried_weapon)
	carried_weapon.position = Vector2(0, -52)
	carried_weapon_changed.emit(carried_weapon)
	_update_hands()
	_show_feedback("Created " + JugaadWeapon.NAMES[recipe] + ". Move to aim placement; E places.")

func placement_position() -> Vector2:
	return player.global_position + player.facing * 64.0

func can_place(at: Vector2) -> bool:
	if not arena.grow(-28).has_point(at):
		return false
	if at.distance_to(workshop.global_position) < 78.0:
		return false
	for child in weapons.get_children():
		var weapon: JugaadWeapon = child as JugaadWeapon
		if weapon != null and at.distance_to(weapon.global_position) < 60.0:
			return false
	return true

func _place_weapon() -> void:
	var at: Vector2 = placement_position()
	if not can_place(at):
		_show_feedback("Cannot place: keep clear of Workshop, arena edges, and other Jugaads.")
		return
	var weapon: JugaadWeapon = carried_weapon
	weapon.reparent(weapons)
	weapon.place_at(at, player.facing)
	carried_weapon = null
	carried_weapon_changed.emit(null)
	weapon_placed.emit(weapon)
	_update_hands()
	_show_feedback("Placed " + JugaadWeapon.NAMES[weapon.kind])

func stop() -> void:
	active = false
	for child in weapons.get_children():
		var weapon: JugaadWeapon = child as JugaadWeapon
		if weapon != null:
			weapon.active = false
	weapons.process_mode = Node.PROCESS_MODE_DISABLED
	projectiles.process_mode = Node.PROCESS_MODE_DISABLED
	if is_instance_valid(carried_weapon):
		carried_weapon.active = false
		carried_weapon.process_mode = Node.PROCESS_MODE_DISABLED
	queue_redraw()

func _update_hands() -> void:
	var left: String = left_hand.display_name() if is_instance_valid(left_hand) else "empty"
	var right: String = right_hand.display_name() if is_instance_valid(right_hand) else "empty"
	$Feedback/Hands.text = "Left [1]: %s   |   Right [2]: %s" % [left, right]
	if is_instance_valid(carried_weapon):
		$Feedback/Hands.text = "Carrying: %s   |   E: place at preview (direction = last movement)" % JugaadWeapon.NAMES[carried_weapon.kind]
	hands_changed.emit(left_hand, right_hand)

func _show_feedback(message: String) -> void:
	$Feedback/Message.text = message
	_message_remaining = 4.0
	feedback.emit(message)

func _draw() -> void:
	if not active or not is_instance_valid(carried_weapon):
		return
	var at: Vector2 = placement_position()
	var color: Color = Color.LIME_GREEN if can_place(at) else Color.RED
	draw_arc(to_local(at), 28, 0, TAU, 24, color, 2)
	draw_line(to_local(at), to_local(at + player.facing * 45), color, 3)
