class_name JugaadRecipes
extends RefCounted

# Sorted pair keys keep lookup unordered. Nine M4A recipes are enabled.
const RECIPES: Dictionary = {
	"1:5": 0, # Cycle Wheel + Rubber Band -> Chakri Gun
	"0:3": 1, # Battery + Speaker -> Dhamaal Box
	"2:3": 2, # Pressure Cooker + Speaker -> Pressure Horn
	"0:1": 3, # Battery + Cycle Wheel -> Bijli Chakri
	"0:4": 4, # Battery + Table Fan -> Turbo Pankha
	"0:5": 5, # Battery + Rubber Band -> Jhatka Sling
	"1:2": 6, # Cycle Wheel + Pressure Cooker -> Pressure Chakra
	"2:4": 7, # Pressure Cooker + Table Fan -> Cooker Cannon
	"3:4": 8, # Speaker + Table Fan -> Aandhi DJ
}

static func resolve(first: int, second: int) -> int:
	return RECIPES.get("%d:%d" % [mini(first, second), maxi(first, second)], -1)
