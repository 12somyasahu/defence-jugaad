class_name WaveTable
extends RefCounted

# M5 tuning data. Add a wave by appending an entry; WaveDirector reads nothing else.
# routes: how many of WaveDirector's route order (EAST, NORTH, WEST, SOUTH) are active.
# arena_stage: index into PrototypeArena.STAGES. spawn_interval: seconds between spawns.
const WAVES: Array[Dictionary] = [
	{"gunda": 6, "chotu": 2, "pehelwan": 0, "routes": 1, "arena_stage": 0, "spawn_interval": 2.6},
	{"gunda": 8, "chotu": 4, "pehelwan": 1, "routes": 2, "arena_stage": 0, "spawn_interval": 2.2},
	{"gunda": 10, "chotu": 6, "pehelwan": 2, "routes": 3, "arena_stage": 1, "spawn_interval": 1.9},
	{"gunda": 12, "chotu": 8, "pehelwan": 3, "routes": 4, "arena_stage": 2, "spawn_interval": 1.6},
	{"gunda": 15, "chotu": 10, "pehelwan": 5, "routes": 4, "arena_stage": 2, "spawn_interval": 1.35},
]
