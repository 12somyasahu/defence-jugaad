extends Node2D

signal availability_changed(available: bool)
signal offers_changed(offers: Array[int])
signal purchased(component_type: int, item: JunkComponent, price: int)
signal feedback(message: String)
signal price_changed(price: int)

@export_range(1, 100) var component_price: int = 3
@export var interaction_range: float = 110.0
# Temporary event price (KABADIWALA SALE); -1 = none. component_price is never mutated.
var sale_price: int = -1
var available: bool = false
var active: bool = true
# Stable slots: -1 means sold, so buying slot 1 never renumbers the other keys.
var offers: Array[int] = []
var economy: Node
var jugaad_loop: JugaadLoop
var player: JugaadPlayer
# M7A: optional; adds mod slots [4][5][6] and the Workshop patch [7].
var upgrades: UpgradeSystem
var _near: bool = false

func setup(currency: Node, loop: JugaadLoop, player_node: JugaadPlayer, upgrade_system: UpgradeSystem = null) -> void:
	economy = currency
	jugaad_loop = loop
	player = player_node
	upgrades = upgrade_system
	economy.scrap_changed.connect(_on_scrap_changed)
	if upgrades != null:
		upgrades.shop_state_changed.connect(_update_panel)
	visible = false
	$ShopPanel.hide()

# Fresh three unique offers. WaveDirector calls this once per legitimate shop phase.
func restock() -> void:
	var pool: Array[int] = [0, 1, 2, 3, 4, 5]
	pool.shuffle()
	offers.assign(pool.slice(0, 3))

func current_price() -> int:
	return sale_price if sale_price > 0 else component_price

func set_sale_price(price: int) -> void:
	sale_price = price
	_update_panel()
	price_changed.emit(current_price())

func clear_sale_price() -> void:
	set_sale_price(-1)

func open_session() -> void:
	if not active or available:
		return
	# Opening/reopening never rerolls; only restock() does.
	if offers.is_empty():
		restock()
	available = true
	visible = true
	_update_panel()
	availability_changed.emit(true)
	offers_changed.emit(offers.duplicate())
	feedback.emit("KABADIWALA open! Stall southeast of Workshop.")

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
	elif upgrades != null and event is InputEventKey and event.pressed and event.physical_keycode in [KEY_4, KEY_5, KEY_6, KEY_7]:
		get_viewport().set_input_as_handled()
		if not event.echo:
			if event.physical_keycode == KEY_7:
				upgrades.buy_patch()
			else:
				upgrades.buy_mod(event.physical_keycode - KEY_4)

func buy(slot: int) -> bool:
	if not active or not available or not is_instance_valid(player) or player.global_position.distance_to(global_position) > interaction_range:
		return false
	if slot < 0 or slot >= offers.size() or offers[slot] < 0:
		feedback.emit("That offer is SOLD.")
		return false
	var price: int = current_price()
	if economy.scrap < price:
		feedback.emit("SCRAP KAM HAI!")
		return false
	var drop_position: Vector2 = _pickup_point(slot)
	if not drop_position.is_finite():
		feedback.emit("Clear some space beside the stall first.")
		return false
	var item: JunkComponent = JugaadLoop.COMPONENT.instantiate()
	item.component_type = offers[slot]
	if not economy.try_spend(price):
		item.free()
		return false
	offers[slot] = -1
	jugaad_loop.components.add_child(item)
	item.global_position = drop_position
	_update_panel()
	offers_changed.emit(offers.duplicate())
	purchased.emit(item.component_type, item, price)
	feedback.emit("Bought %s! Pick it up beside the stall with E." % item.display_name())
	return true

func _pickup_point(slot: int) -> Vector2:
	var offsets: Array[Vector2] = [Vector2(-48, -56), Vector2(0, -56), Vector2(48, -56), Vector2(-48, 56), Vector2(0, 56), Vector2(48, 56)]
	for i in offsets.size():
		var at: Vector2 = global_position + offsets[(slot + i) % offsets.size()]
		if not jugaad_loop.arena.grow(-24).has_point(at) or at.distance_to(jugaad_loop.workshop.global_position) < 72:
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
	var text: String = "KABADIWALA%s  |  SCRAP: %d\n" % [" SALE!" if sale_price > 0 else "", economy.scrap]
	if upgrades != null and upgrades.can_shop():
		text += "COMPONENTS\n"
	for i in offers.size():
		text += "[%d] %s\n" % [i + 1, "SOLD" if offers[i] < 0 else "%s - %d Scrap" % [JunkComponent.DISPLAY_NAMES[offers[i]], current_price()]]
	text += _mods_text()
	text += "Buy: 1-3 junk, 4-6 mod, 7 patch (no hand drops here)\nE: pick up purchased junk | Closes when the wave starts"
	$ShopPanel/Panel/Offers.text = text

func _mods_text() -> String:
	if upgrades == null or not upgrades.can_shop():
		return ""
	var text: String = "JUGAAD MODS (one per visit, never on sale)\n"
	if upgrades.offers.is_empty():
		text += "  Saare mods le liye!\n"
	for i in upgrades.offers.size():
		var mod: Dictionary = UpgradeTable.MODS[upgrades.offers[i]]
		if upgrades.mod_bought == upgrades.offers[i]:
			text += "[%d] %s - BOUGHT\n" % [i + 4, mod.name]
		elif upgrades.mod_bought != &"":
			text += "[%d] %s - closed\n" % [i + 4, mod.name]
		else:
			text += "[%d] %s - %d Scrap\n     %s %s\n" % [i + 4, mod.name, mod.cost, mod.flavour, mod.effect]
	var patch: String = "used" if upgrades.patch_used else ("Workshop full" if upgrades.workshop.current_hp >= upgrades.workshop.maximum_hp else "%d Scrap: +%d HP" % [UpgradeTable.PATCH_COST, UpgradeTable.PATCH_HEAL])
	text += "[7] %s - %s\n" % [UpgradeTable.PATCH_NAME, patch]
	return text
