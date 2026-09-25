extends Node2D

signal availability_changed(available: bool)
signal offers_changed(offers: Array[int])
signal purchased(component_type: int, item: JunkComponent, price: int)
signal feedback(message: String)

@export_range(1, 100) var component_price: int = 3
@export var interaction_range: float = 110.0
var available: bool = false
var active: bool = true
# Stable slots: -1 means sold, so buying slot 1 never renumbers the other keys.
var offers: Array[int] = []
var economy: Node
var jugaad_loop: JugaadLoop
var player: JugaadPlayer
var _near: bool = false

func setup(currency: Node, loop: JugaadLoop, player_node: JugaadPlayer) -> void:
	economy = currency
	jugaad_loop = loop
	player = player_node
	economy.scrap_changed.connect(_on_scrap_changed)
	visible = false
	$ShopPanel.hide()

func open_session() -> void:
	if not active or available:
		return
	var pool: Array[int] = [0, 1, 2, 3, 4, 5]
	pool.shuffle()
	offers.assign(pool.slice(0, 3))
	available = true
	visible = true
	_update_panel()
	availability_changed.emit(true)
	offers_changed.emit(offers.duplicate())
	feedback.emit("KABADIWALA open! Stall southeast of Workshop. DEBUG F6: close.")

func close_session() -> void:
	if not available:
		return
	available = false
	_near = false
	visible = false
	$ShopPanel.hide()
	availability_changed.emit(false)

func stop() -> void:
	active = false
	close_session()

func _process(_delta: float) -> void:
	_near = available and active and is_instance_valid(player) and player.global_position.distance_to(global_position) <= interaction_range
	$ShopPanel.visible = _near

func _input(event: InputEvent) -> void:
	if not available or not active or not is_instance_valid(player) or player.global_position.distance_to(global_position) > interaction_range:
		return
	if event is InputEventKey and event.pressed and event.physical_keycode in [KEY_1, KEY_2, KEY_3]:
		# Consume before JugaadLoop's drop actions; held-key echoes never purchase.
		get_viewport().set_input_as_handled()
		if not event.echo:
			buy(event.physical_keycode - KEY_1)

func buy(slot: int) -> bool:
	if not active or not available or not is_instance_valid(player) or player.global_position.distance_to(global_position) > interaction_range:
		return false
	if slot < 0 or slot >= offers.size() or offers[slot] < 0:
		feedback.emit("That offer is SOLD.")
		return false
	if economy.scrap < component_price:
		feedback.emit("SCRAP KAM HAI!")
		return false
	var drop_position: Vector2 = _pickup_point(slot)
	if not drop_position.is_finite():
		feedback.emit("Clear some space beside the stall first.")
		return false
	var item: JunkComponent = JugaadLoop.COMPONENT.instantiate()
	item.component_type = offers[slot]
	if not economy.try_spend(component_price):
		item.free()
		return false
	offers[slot] = -1
	jugaad_loop.components.add_child(item)
	item.global_position = drop_position
	_update_panel()
	offers_changed.emit(offers.duplicate())
	purchased.emit(item.component_type, item, component_price)
	feedback.emit("Bought %s! Pick it up beside the stall with E." % item.display_name())
	return true

func _pickup_point(slot: int) -> Vector2:
	var offsets: Array[Vector2] = [Vector2(-48, -56), Vector2(0, -56), Vector2(48, -56), Vector2(-48, 56), Vector2(0, 56), Vector2(48, 56)]
	for i in offsets.size():
		var at: Vector2 = global_position + offsets[(slot + i) % offsets.size()]
		if not JugaadLoop.ARENA.grow(-24).has_point(at) or at.distance_to(jugaad_loop.workshop.global_position) < 72:
			continue
		var blocked: bool = false
		for child in jugaad_loop.weapons.get_children():
			var weapon: JugaadWeapon = child as JugaadWeapon
			if weapon != null and at.distance_to(weapon.global_position) < 55:
				blocked = true
		for child in jugaad_loop.components.get_children():
			var component: JunkComponent = child as JunkComponent
			if component != null and at.distance_to(component.global_position) < 26:
				blocked = true
		if not blocked:
			return at
	return Vector2(INF, INF)

func _on_scrap_changed(_total: int) -> void:
	_update_panel()

func _update_panel() -> void:
	var text: String = "KABADIWALA  |  SCRAP: %d\n" % economy.scrap
	for i in offers.size():
		text += "[%d] %s\n" % [i + 1, "SOLD" if offers[i] < 0 else "%s - %d Scrap" % [JunkComponent.DISPLAY_NAMES[offers[i]], component_price]]
	text += "Buy: 1 / 2 / 3 (hand drops disabled here)\nE: pick up purchased junk | DEBUG F6: close"
	$ShopPanel/Panel/Offers.text = text
