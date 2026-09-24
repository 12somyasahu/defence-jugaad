class_name JugaadRecipes
extends RefCounted

# Sorted pair keys keep lookup unordered; only the three M2 recipes are enabled.
const RECIPES: Dictionary = {
	"1:5": 0, # Cycle Wheel + Rubber Band -> Chakri Gun
	"0:3": 1, # Battery + Speaker -> Dhamaal Box
	"2:3": 2, # Pressure Cooker + Speaker -> Pressure Horn
}

static func resolve(first: int, second: int) -> int:
	return RECIPES.get("%d:%d" % [mini(first, second), maxi(first, second)], -1)
