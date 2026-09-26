# M7B audio asset handoff

All files are optional. Add Ogg Vorbis files at these exact paths, let Godot import them, then restart the run. No gameplay or audio-script edits are needed. Runtime config sets loop flags. Missing assets remain silent; deterministic subtitles and gameplay continue.

Master, Music, SFX and Dialogue buses are created if absent. Music targets -12 dB, dialogue ducks it another 5 dB. Combat SFX use -12 dB and a bounded pool; telegraphs have reserved slots at -3 dB. Engine loop uses -20 dB. These are initial mix values, requiring an audible review when assets arrive.

Engine charge/shove was cut, so boss/ram.ogg is not required; parked Workshop impacts use workshop_hit.ogg.

| PATH | STATUS | TRIGGER / SUBTITLE | LOOP |
|---|---|---|---|
| `res://audio/music/preparation_theme.ogg` | MISSING | Normal/final preparation; after warning sting | YES |
| `res://audio/music/combat_theme.ogg` | MISSING | Normal-wave combat | YES |
| `res://audio/music/wave_clear.ogg` | MISSING | Normal wave clear | NO |
| `res://audio/music/thekedaar_warning.ogg` | MISSING | Final preparation warning | NO |
| `res://audio/music/thekedaar_theme.ogg` | MISSING | Boss combat | YES |
| `res://audio/music/victory.ogg` | MISSING | Chassis destruction | NO |
| `res://audio/music/defeat.ogg` | MISSING | Workshop destruction | NO |
| `res://audio/sfx/pickup.ogg` | MISSING | Component or working weapon pickup | NO |
| `res://audio/sfx/drop.ogg` | MISSING | Manual component drop | NO |
| `res://audio/sfx/combine_success.ogg` | MISSING | Successful craft | NO |
| `res://audio/sfx/combine_fail.ogg` | MISSING | Unsupported recipe | NO |
| `res://audio/sfx/place_jugaad.ogg` | MISSING | Valid placement | NO |
| `res://audio/sfx/player_hit.ogg` | MISSING | Enemy contact or Speaker disruption | NO |
| `res://audio/sfx/repair_thak.ogg` | MISSING | Valid repair hit | NO |
| `res://audio/sfx/repair_complete.ogg` | MISSING | Repair restored | NO |
| `res://audio/sfx/jam_warning.ogg` | MISSING | Entering 80% instability | NO |
| `res://audio/sfx/jammed.ogg` | MISSING | Weapon jam | NO |
| `res://audio/sfx/shop_open.ogg` | MISSING | Shop available | NO |
| `res://audio/sfx/purchase.ogg` | MISSING | Component/mod bought | NO |
| `res://audio/sfx/purchase_fail.ogg` | MISSING | Rejected shop purchase | NO |
| `res://audio/sfx/workshop_patch.ogg` | MISSING | Patch bought | NO |
| `res://audio/sfx/countdown_tick.ogg` | MISSING | Countdown digit | NO |
| `res://audio/sfx/countdown_go.ogg` | MISSING | Combat starts | NO |
| `res://audio/sfx/route_open.ogg` | MISSING | Arena route announcement | NO |
| `res://audio/sfx/wave_clear.ogg` | MISSING | Normal wave clear | NO |
| `res://audio/sfx/workshop_hit.ogg` | MISSING | Workshop HP decreases | NO |
| `res://audio/sfx/workshop_critical.ogg` | MISSING | Entering 25% HP or lower | NO |
| `res://audio/sfx/workshop_destroyed.ogg` | MISSING | Workshop reaches zero | NO |
| `res://audio/sfx/weapons/mechanical_shot.ogg` | MISSING | Chakri Gun firing | NO |
| `res://audio/sfx/weapons/electric_zap.ogg` | MISSING | Bijli Chakri firing | NO |
| `res://audio/sfx/weapons/speaker_boom.ogg` | MISSING | Dhamaal Box / Pressure Horn firing | NO |
| `res://audio/sfx/weapons/wind_blast.ogg` | MISSING | Turbo Pankha / Aandhi DJ firing | NO |
| `res://audio/sfx/weapons/cooker_boom.ogg` | MISSING | Cooker Cannon firing | NO |
| `res://audio/sfx/weapons/slingshot.ogg` | MISSING | Jhatka Sling firing | NO |
| `res://audio/sfx/weapons/spinner.ogg` | MISSING | Pressure Chakra firing | NO |
| `res://audio/sfx/enemies/enemy_hit.ogg` | MISSING | Normal enemy damaged | NO |
| `res://audio/sfx/enemies/enemy_death.ogg` | MISSING | Normal enemy dies | NO |
| `res://audio/sfx/enemies/chotu_attack.ogg` | MISSING | Chotu attacks Workshop | NO |
| `res://audio/sfx/enemies/pehelwan_attack.ogg` | MISSING | Pehelwan attacks Workshop | NO |
| `res://audio/sfx/boss/arrival.ogg` | MISSING | Tempo enters | NO |
| `res://audio/sfx/boss/engine_loop.ogg` | MISSING | Tempo moving with living Engine | YES |
| `res://audio/sfx/boss/stop.ogg` | MISSING | Tempo stops | NO |
| `res://audio/sfx/boss/speaker_charge.ogg` | MISSING | Speaker warning starts | NO |
| `res://audio/sfx/boss/speaker_blast.ogg` | MISSING | Speaker fires | NO |
| `res://audio/sfx/boss/battery_charge.ogg` | MISSING | Battery target lines start | NO |
| `res://audio/sfx/boss/battery_zap.ogg` | MISSING | Battery outage applied | NO |
| `res://audio/sfx/boss/module_destroyed.ogg` | MISSING | Any non-chassis module destroyed | NO |
| `res://audio/sfx/boss/hafta_horn.ogg` | MISSING | HAFTA threshold announcement | NO |
| `res://audio/sfx/boss/chassis_destroyed.ogg` | MISSING | Chassis reaches zero | NO |
| `res://audio/dialogue/start_workshop_bachao.ogg` | MISSING | Workshop bachao! Jo mile, jod do! | NO |
| `res://audio/dialogue/first_jugaad.ogg` | MISSING | Arre wah! Chal bhi raha hai! | NO |
| `res://audio/dialogue/jugaad_jammed.ogg` | MISSING | Arre! Jugaad atak gaya! | NO |
| `res://audio/dialogue/workshop_critical.ogg` | MISSING | Workshop gaya toh sab gaya! | NO |
| `res://audio/dialogue/kabadiwala_arrival.ogg` | MISSING | Kabadiwala aa gaya! | NO |
| `res://audio/dialogue/scrap_kam_hai.ogg` | MISSING | Scrap kam hai! | NO |
| `res://audio/dialogue/wave_clear.ogg` | MISSING | Ek aur nipat gaya! | NO |
| `res://audio/dialogue/thekedaar_warning.ogg` | MISSING | Thekedaar aa raha hai! | NO |
| `res://audio/dialogue/thekedaar_arrival.ogg` | MISSING | Bahut jugaad kar liya. Ab hisaab hoga! | NO |
| `res://audio/dialogue/thekedaar_speaker.ogg` | MISSING | Awaaz badhao! | NO |
| `res://audio/dialogue/thekedaar_bijli.ogg` | MISSING | Bijli band! | NO |
| `res://audio/dialogue/thekedaar_hafta.ogg` | MISSING | HAFTA VASOOLI! | NO |
| `res://audio/dialogue/engine_destroyed.ogg` | MISSING | Engine gaya! | NO |
| `res://audio/dialogue/speaker_destroyed.ogg` | MISSING | Speaker chup! | NO |
| `res://audio/dialogue/battery_destroyed.ogg` | MISSING | Battery gayi! | NO |
| `res://audio/dialogue/thekedaar_defeated.ogg` | MISSING | THEKEDAAR HAAR GAYA! | NO |
| `res://audio/dialogue/ending_engineering.ogg` | MISSING | Yeh sab engineering hai? | NO |
| `res://audio/dialogue/ending_nahi.ogg` | MISSING | Nahi. | NO |
| `res://audio/dialogue/ending_jugaad_hai.ogg` | MISSING | JUGAAD HAI. | NO |
