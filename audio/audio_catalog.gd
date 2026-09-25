class_name AudioCatalog
extends RefCounted

const MUSIC: Array[String] = ["preparation_theme", "combat_theme", "wave_clear", "thekedaar_warning", "thekedaar_theme", "victory", "defeat"]
const MUSIC_LOOPS: Array[String] = ["preparation_theme", "combat_theme", "thekedaar_theme"]
const SFX: Array[String] = [
	"pickup", "drop", "combine_success", "combine_fail", "place_jugaad", "player_hit",
	"repair_thak", "repair_complete", "jam_warning", "jammed", "shop_open", "purchase", "purchase_fail", "workshop_patch",
	"countdown_tick", "countdown_go", "route_open", "wave_clear", "workshop_hit", "workshop_critical", "workshop_destroyed",
	"weapons/mechanical_shot", "weapons/electric_zap", "weapons/speaker_boom", "weapons/wind_blast", "weapons/cooker_boom", "weapons/slingshot", "weapons/spinner",
	"enemies/enemy_hit", "enemies/enemy_death", "enemies/chotu_attack", "enemies/pehelwan_attack",
	"boss/arrival", "boss/engine_loop", "boss/stop", "boss/speaker_charge", "boss/speaker_blast", "boss/battery_charge", "boss/battery_zap", "boss/module_destroyed", "boss/hafta_horn", "boss/chassis_destroyed",
]
const DIALOGUE: Dictionary = {
	"start_workshop_bachao": "Workshop bachao! Jo mile, jod do!",
	"first_jugaad": "Arre wah! Chal bhi raha hai!",
	"jugaad_jammed": "Arre! Jugaad atak gaya!",
	"workshop_critical": "Workshop gaya toh sab gaya!",
	"kabadiwala_arrival": "Kabadiwala aa gaya!",
	"scrap_kam_hai": "Scrap kam hai!",
	"wave_clear": "Ek aur nipat gaya!",
	"thekedaar_warning": "Thekedaar aa raha hai!",
	"thekedaar_arrival": "Bahut jugaad kar liya. Ab hisaab hoga!",
	"thekedaar_speaker": "Awaaz badhao!",
	"thekedaar_bijli": "Bijli band!",
	"thekedaar_hafta": "HAFTA VASOOLI!",
	"engine_destroyed": "Engine gaya!",
	"speaker_destroyed": "Speaker chup!",
	"battery_destroyed": "Battery gayi!",
	"thekedaar_defeated": "THEKEDAAR HAAR GAYA!",
	"ending_engineering": "Yeh sab engineering hai?",
	"ending_nahi": "Nahi.",
	"ending_jugaad_hai": "JUGAAD HAI.",
}
const WEAPON_SOUNDS: Array[String] = ["mechanical_shot", "speaker_boom", "speaker_boom", "electric_zap", "wind_blast", "slingshot", "spinner", "cooker_boom", "wind_blast"]

static func expected_paths() -> Array[String]:
	var paths: Array[String] = []
	for id in MUSIC:
		paths.append("res://audio/music/%s.ogg" % id)
	for id in SFX:
		paths.append("res://audio/sfx/%s.ogg" % id)
	for id in DIALOGUE:
		paths.append("res://audio/dialogue/%s.ogg" % id)
	return paths
