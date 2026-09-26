class_name UpgradeTable
extends RefCounted

# M7A Jugaad Mods. Pure data; UpgradeSystem reads it, nothing else hardcodes mod effects.
# component: JunkComponent.Type a Jugaad's recipe must contain, or ANY for every Jugaad.
# modifiers: multiplicative per-stat factors (damage, cooldown, range, instability,
# knockback, blast_radius). repair_hits: replaces the THAK count. aura: placement effect.
const ANY: int = -1
const MODS: Dictionary = {
	&"fevi_tight": {
		"name": "FEVI-TIGHT", "cost": 20, "component": ANY,
		"flavour": "Kam hilta, der se jam hota.", "effect": "ALL: jam x0.7",
		"modifiers": {"instability": 0.7},
	},
	&"master_jugaadu": {
		"name": "MASTER JUGAADU", "cost": 12, "component": ANY,
		"flavour": "Do thappad kaafi hai.", "effect": "ALL: repair 2 THAK",
		"repair_hits": 2,
	},
	&"overvoltage": {
		"name": "OVERVOLTAGE", "cost": 15, "component": JunkComponent.Type.BATTERY,
		"flavour": "Zyada bijli. Zyada dikkat.", "effect": "BATTERY: dmg x1.5, jam x1.5",
		"modifiers": {"damage": 1.5, "instability": 1.5},
	},
	&"ball_bearing": {
		"name": "BALL BEARING", "cost": 18, "component": JunkComponent.Type.CYCLE_WHEEL,
		"flavour": "Ghoomta hi rehta hai.", "effect": "WHEEL: attack x1.33 faster",
		"modifiers": {"cooldown": 0.75},
	},
	&"do_rubber": {
		"name": "DO RUBBER", "cost": 12, "component": JunkComponent.Type.RUBBER_BAND,
		"flavour": "Double gulel, double door.", "effect": "RUBBER: range x1.3",
		"modifiers": {"range": 1.3},
	},
	&"nayi_seeti": {
		"name": "NAYI SEETI", "cost": 15, "component": JunkComponent.Type.PRESSURE_COOKER,
		"flavour": "Seeti bajegi, gunde udenge.", "effect": "COOKER: push x1.5, blast 100",
		"modifiers": {"knockback": 1.5, "blast_radius": 100.0 / 75.0},
	},
	&"thanda_thanda": {
		"name": "THANDA THANDA", "cost": 15, "component": JunkComponent.Type.TABLE_FAN,
		"flavour": "Pankhe ke paas sab cool.", "effect": "Near FAN Jugaad: jam x0.7",
		"aura": {"radius": 120.0, "instability": 0.7},
	},
	&"dj_wale_babu": {
		"name": "DJ WALE BABU", "cost": 15, "component": JunkComponent.Type.SPEAKER,
		"flavour": "Volume badhao!", "effect": "SPEAKER: range x1.3",
		"modifiers": {"range": 1.3},
	},
}
# Offer/display order; also the debug grant cycle.
const ORDER: Array[StringName] = [&"fevi_tight", &"master_jugaadu", &"overvoltage", &"ball_bearing", &"do_rubber", &"nayi_seeti", &"thanda_thanda", &"dj_wale_babu"]
# Balance hook for range mods (DO RUBBER / DJ WALE BABU): modified range never exceeds this.
# 500 keeps Jhatka Sling (380 x 1.3 = 494) uncapped for the first playtest.
const MAX_MODIFIED_RANGE: float = 500.0
const OFFERS_PER_PREPARATION: int = 3

# Repeatable Workshop repair; not an owned mod and never discounted.
const PATCH_NAME: String = "TIRPAL-EENT PATCH"
const PATCH_COST: int = 10
const PATCH_HEAL: int = 75
