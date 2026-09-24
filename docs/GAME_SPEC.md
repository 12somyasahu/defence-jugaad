# DEFENCE JUGAAD — GAME SPEC

## 1. Game Overview

**Working Title:** Defence Jugaad  
**Theme:** Jugaad  
**Genre:** Top-down Arena Defence / Tower Defence / Light Roguelite  
**Engine:** Godot 4.7.x  
**Primary Language:** GDScript  
**Jam Duration:** 48 hours  
**Target:** Desktop first, Web if stable

### One-Line Pitch

Defend your neighbourhood workshop from a rival scrap gang by running around the battlefield, collecting everyday junk, combining two objects into ridiculous Jugaad weapons, placing them around the arena, and physically keeping your unreliable creations alive as the battlefield expands around you.

### Core Fantasy

You are not a soldier.

You are a Jugaadu.

You don't have the right tools or weapons.

You make something work with whatever you can find.

---

# 2. Design Pillars

The game is built around five pillars:

1. **Improvisation**
   - The player constantly works with whatever components are available.

2. **Experimentation**
   - Combining two objects reveals a handcrafted Jugaad weapon.

3. **Controlled Chaos**
   - Weapons jam, enemies attack from multiple directions, components drop around the arena, and unexpected events disrupt plans.

4. **Physical Involvement**
   - The player does not command everything from a menu.
   - They physically run around collecting, building, placing, moving and repairing defences.

5. **Escalation**
   - The battlefield starts simple and progressively expands until the player is defending from several directions.

---

# 3. Core Gameplay Loop

**COLLECT → COMBINE → BUILD → DEFEND → REPAIR → ADAPT → SURVIVE**

During a run:

1. Collect components.
2. Hold up to two components.
3. Combine them into a Jugaad weapon.
4. Carry the weapon to a location.
5. Place it.
6. Weapon automatically attacks enemies.
7. Run around maintaining the defence.
8. Repair jammed weapons.
9. Collect battlefield drops.
10. Survive the wave.
11. Buy/trade components between waves.
12. Choose an upgrade.
13. Arena periodically expands.
14. New attack routes appear.
15. Repeat until the final boss.

Target full-run duration:

**~12–15 minutes**

---

# 4. Player

## Perspective

Top-down 2D.

## Player Role

The player is a neighbourhood Jugaad engineer defending their workshop.

The player DOES NOT use conventional weapons.

Their weapons are the contraptions they build.

## Controls

Initial control proposal:

- **WASD** — Move
- **E** — Interact / Pick Up / Place / Repair
- **Q** — Combine held components
- **1** — Drop left-hand component
- **2** — Drop right-hand component

Controls may change during playtesting.

## Player Combat

The player does not directly attack enemies.

Optional emergency interaction:

- Player may shove nearby enemies.
- Shove deals negligible/no damage.
- Used only to create space.

## Player Damage

Enemies should not normally kill the player.

Enemy contact may:

- knock player backward
- briefly stun/slow player
- cause carried components to drop

The primary failure condition is destruction of the Workshop.

---

# 5. Two-Hand Inventory

The player has exactly two component slots:

- Left Hand
- Right Hand

Example:

LEFT HAND: Battery  
RIGHT HAND: Speaker

Press Combine:

Battery + Speaker → Dhamaal Box

The resulting Jugaad becomes one carried object.

The player must then physically place it.

No large traditional inventory for MVP.

This limitation is intentional and creates decisions about:

- what to pick up
- what to drop
- what to combine
- whether to wait for a better component

---

# 6. Jugaad Combination System

## Core Rule

Two different base components create one handcrafted Jugaad weapon.

Recipes are unordered:

Battery + Speaker = Speaker + Battery.

## Hybrid Design

The system is hybrid.

Each pair produces a specifically designed weapon with:

- unique behaviour
- role
- visuals
- sound
- special ability

Components also have identities that influence the resulting weapon's design and statistics.

Example component identities:

Battery:
- electrical
- powerful
- unstable

Cycle Wheel:
- mechanical
- fast
- reliable

Pressure Cooker:
- pressure/explosive
- heavy damage
- slower
- unstable

Speaker:
- sonic
- AoE
- knockback

Table Fan:
- air
- pushing
- control
- cooling

Rubber Band:
- elastic
- projectile/range
- fast
- reliable

---

# 7. Base Components

Initial six components:

1. Battery
2. Cycle Wheel
3. Pressure Cooker
4. Speaker
5. Table Fan
6. Rubber Band

Six components create:

**15 unique two-component combinations.**

All combinations should eventually produce a useful weapon.

Experimentation should never be punished with a completely useless result.

---

# 8. Jugaad Weapon List

## 1. Battery + Cycle Wheel
### BIJLI CHAKRI

Role:
Close-range DPS

Behaviour:
Electrified rotating wheel rapidly shocks nearby enemies.

Traits:
- fast
- electrical
- close range
- moderately unstable

---

## 2. Battery + Pressure Cooker
### BIJLI BOMB

Role:
Heavy AoE / Nuke

Behaviour:
Produces large electrical explosions and can chain electricity between nearby enemies.

Traits:
- extremely high damage
- slow
- very unreliable

---

## 3. Battery + Speaker
### DHAMAAL BOX

Role:
AoE

Behaviour:
Periodically emits an electrical bass shockwave damaging groups around it.

Traits:
- AoE
- electrical
- moderate knockback

---

## 4. Battery + Table Fan
### TURBO PANKHA

Role:
Crowd Control

Behaviour:
Produces electrified air blasts that damage and push enemies backwards.

Traits:
- push
- electrical
- lane control

---

## 5. Battery + Rubber Band
### JHATKA SLING

Role:
Long-range / Sniper

Behaviour:
Launches charged projectiles at distant enemies.

Traits:
- long range
- strong single-target damage
- moderate fire rate

---

## 6. Cycle Wheel + Pressure Cooker
### PRESSURE CHAKRA

Role:
Close Defence

Behaviour:
Pressure drives a spinning mechanical weapon that damages nearby enemies.

Traits:
- short range
- high sustained damage
- mechanical

---

## 7. Cycle Wheel + Speaker
### DJ CYCLE

Role:
360-degree Support/AoE

Behaviour:
Rotating speaker produces sonic pulses around the weapon.

Traits:
- circular coverage
- moderate damage
- knockback

---

## 8. Cycle Wheel + Table Fan
### DOUBLE GHOOMAR

Role:
Rapid DPS

Behaviour:
High-speed dual-rotor contraption attacks extremely quickly.

Traits:
- very high attack speed
- moderate damage
- mechanical

---

## 9. Cycle Wheel + Rubber Band
### CHAKRI GUN

Role:
Machine Gun

Behaviour:
Rapidly launches small scrap projectiles at individual enemies.

Traits:
- high attack speed
- reliable
- balanced range

---

## 10. Pressure Cooker + Speaker
### PRESSURE HORN

Role:
Heavy Crowd Control

Behaviour:
Builds pressure before releasing a powerful directional sonic blast.

Traits:
- huge knockback
- AoE
- slow attack

---

## 11. Pressure Cooker + Table Fan
### COOKER CANNON

Role:
Artillery

Behaviour:
Uses airflow and pressure to launch explosive projectiles.

Traits:
- long range
- splash damage
- slow attack

---

## 12. Pressure Cooker + Rubber Band
### PRESSURE PATTHAR

Role:
Heavy Sniper

Behaviour:
Large improvised slingshot fires extremely powerful projectiles.

Traits:
- huge single-hit damage
- very slow
- long range

---

## 13. Speaker + Table Fan
### AANDHI DJ

Role:
Area Control

Behaviour:
Combines wind and sound to continuously slow and push groups of enemies.

Traits:
- low/moderate damage
- strong control
- AoE

---

## 14. Speaker + Rubber Band
### BASS SLINGER

Role:
Crowd Control

Behaviour:
Launches sonic projectiles that can bounce between enemies.

Traits:
- chaining
- moderate damage
- crowd control

---

## 15. Table Fan + Rubber Band
### HAWA GULEL

Role:
Cheap Reliable DPS

Behaviour:
Fan-powered slingshot rapidly launches projectiles.

Traits:
- simple
- fast
- highly reliable
- moderate damage

---

# 9. Weapon Stats

Every weapon can expose four easy-to-understand characteristics:

- DAMAGE
- RANGE
- SPEED
- RELIABILITY

Prefer readable categories/stars over excessive numbers in player-facing UI.

Example:

PRESSURE PATTHAR

Damage: ★★★★★  
Range: ★★★★★  
Speed: ★  
Reliability: ★★★

---

# 10. Jugaad Reliability System

Weapons are intentionally imperfect.

Each deployed Jugaad has an instability/jam meter.

Using the weapon increases instability.

Different weapons accumulate instability at different rates.

Powerful experimental weapons generally accumulate instability faster.

At maximum instability:

**KHATAK!**

The weapon jams and stops functioning.

Visual feedback:

- smoke
- shaking
- sparks
- warning icon
- sound effect

Prompt:

**THOKO!**

The player runs to the weapon and presses E approximately three times.

Each press produces a physical hit:

THAK!  
THAK!  
THAK!

Weapon resumes operation and instability resets/reduces.

This should feel funny rather than frustrating.

Avoid invisible random failure.

---

# 11. Weapon Placement

After combining components:

1. Player carries the completed Jugaad.
2. Placement preview appears near player.
3. Valid position = clear feedback.
4. Invalid position = clear feedback.
5. Press E to place.

Placed Jugaads automatically attack.

---

# 12. Weapon Repositioning

Placed weapons can be picked up again.

Player approaches weapon and interacts.

While carrying:

- weapon cannot attack
- player must physically move it
- it can be placed somewhere else

This becomes important when new attack routes appear.

---

# 13. Workshop

The Workshop is the central objective.

Enemies attempt to reach and damage it.

## Workshop Health

Initial target:

100 HP

Visual damage states:

- 100% — normal
- 75% — minor damage
- 50% — cracks/smoke
- 25% — severe damage/alarm
- 0% — collapse

At 0 HP:

**GAME OVER**

Possible text:

# JUGAAD FAIL HO GAYA

---

# 14. Rival Gang

## Premise

The player runs a small neighbourhood Jugaad Workshop / scrap shop.

A rival scrap gang wants control of the workshop and its valuable junk.

They attack repeatedly.

The player uses whatever is available to defend it.

## Tone

Comedic and exaggerated.

Avoid realistic violence.

Enemies and weapons should feel cartoonish.

The rival gang should themselves use improvised equipment.

Examples:

- bucket helmets
- cooker-lid shields
- cardboard armour
- modified bicycles
- improvised vehicles

The world should visually communicate Jugaad on both sides.

---

# 15. Enemy Types

Keep enemy roster small and mechanically distinct.

## GUNDA

Basic enemy.

Behaviour:
- walks toward workshop
- attacks workshop

Stats:
Balanced.

---

## CHOTU

Fast enemy.

Behaviour:
- quickly rushes workshop
- low HP

Purpose:
Punishes slow-firing defences.

---

## PEHELWAN

Tank.

Behaviour:
- slow
- high HP
- difficult to knock back

Purpose:
Tests single-target damage.

---

## KABADI CHOR

Thief.

Behaviour:
- prioritizes loose battlefield components
- grabs one
- attempts to escape

Player can intercept him and recover the item.

Purpose:
Forces player movement and creates panic.

---

## MECHANIC

Saboteur/support enemy.

Behaviour:
- targets deployed Jugaads
- increases their instability
- attempts to jam/sabotage them

Purpose:
Forces player to protect infrastructure.

---

# 16. Boss

## THEKEDAAR

Final rival-gang boss.

Arrives using a gigantic improvised Jugaad vehicle.

The boss consists of multiple visible modules.

Possible modules:

- Speaker
- Battery
- Engine
- Armour
- Main chassis

Destroying modules changes boss behaviour.

Examples:

Destroy Speaker:
- disables shockwave

Destroy Battery:
- disables/reduces electrical attack

Destroy Engine:
- slows movement

Then destroy main chassis.

Theme:

The final enemy is also using Jugaad.

---

# 17. Components and Economy

Enemies primarily drop:

**SCRAP**

Scrap acts as currency.

Some enemies occasionally drop physical components.

Component drops create mid-wave opportunities.

Example:

Pressure Cooker drops across arena.

Player must decide whether it is worth leaving their current task to retrieve it.

---

# 18. Kabadiwala

Between waves, a Kabadiwala appears.

Purpose:

- provides predictable access to components
- reduces excessive RNG
- reinforces theme

Initial design:

Kabadiwala offers approximately three components.

Player spends Scrap to acquire them.

Optional later feature:

Trade unwanted components.

Do not overbuild shop UI.

---

# 19. Wave Structure

Each wave should last approximately:

**60–90 seconds**

Wave intensity:

1. manageable opening
2. pressure increases
3. final ~15 seconds become chaotic
4. remaining enemies are cleared
5. wave ends

Then:

- reward Scrap
- repair/reorganize
- Kabadiwala
- optional upgrade choice
- next wave

---

# 20. Arena Expansion

The arena begins small.

Only one direction is initially vulnerable.

After specific waves, the camera pulls outward and reveals additional attack routes.

Example progression:

Waves 1–2:
East

Waves 3–4:
East + North

Waves 5–6:
East + North + West

Waves 7–8:
Four-direction defence

Arena expansion should be a dramatic moment.

Example:

# NAYA RAASTA KHUL GAYA!

Old weapons remain where they were.

Player must physically redistribute defences.

Do not automatically reposition weapons.

---

# 21. Proposed Run

Target:

8 waves.

## Wave 1
Tutorial.

One direction.

Teach:
- movement
- pickup
- combining
- placement

## Wave 2
Normal defence.

Introduce jamming/repair.

### EXPANSION 1

Second attack route opens.

## Wave 3
Two directions.

Introduce first random event.

## Wave 4
Introduce additional enemy type.

### EXPANSION 2

Third route opens.

## Wave 5
Three-direction pressure.

## Wave 6
Heavy wave.

### FINAL EXPANSION

Fourth route opens.

## Wave 7
Full-arena defence.

High chaos.

## Wave 8
THEKEDAAR boss.

---

# 22. Random Events

Events exist to break established plans and force improvisation.

Events should be clearly telegraphed.

MVP target:

3 events.

## LIGHT GAYI

Electrical Jugaads temporarily stop functioning.

Mechanical Jugaads continue.

After short duration:

**LIGHT AA GAYI!**

---

## BAARISH

Rain begins.

Possible effects:

- electrical attacks chain farther
- electrical instability increases

Exact balance determined through playtesting.

---

## CHOR AA GAYE

Additional thieves enter and target loose components.

---

## Optional Later Events

BANDAR:
Monkey attempts to steal loose components.

GARAMI:
Weapons accumulate instability faster.

KABADIWALA EXPRESS:
Merchant briefly appears during combat.

SABOTAGE:
Mechanic enemies arrive.

---

# 23. Between-Wave Upgrades

After selected waves, present three random upgrades.

Player chooses one.

Examples:

## FEVI-TIGHT

All Jugaads accumulate instability more slowly.

## OVERVOLTAGE

Electrical weapons:
+ damage
+ instability

## MASTER JUGAADU

Repair requires fewer hits.

## BALL BEARING

Mechanical weapons attack faster.

## EXTRA SCRAP

Enemies drop more Scrap.

Keep upgrade effects simple and immediately understandable.

MVP does not require a large upgrade pool.

---

# 24. Recipe Discovery

Unknown combinations should not reveal their result beforehand.

Example:

Battery + Speaker → ???

Player chooses to experiment.

First discovery gets a short presentation:

# NAYA JUGAAD!

BATTERY + SPEAKER

## DHAMAAL BOX

Optional humorous description:

*"Volume kam karne ka option nahi hai."*

Then:

**Jugaad Book: 4 / 15**

Repeated crafting should NOT replay the full discovery animation.

---

# 25. Jugaad Book

Tracks discovered recipes.

Target:

15 / 15 combinations.

Purpose:

- rewards experimentation
- creates replay value
- communicates remaining discoveries

This can be a simple menu/panel.

Do not prioritize before core gameplay works.

---

# 26. Random Component Quality

STATUS: SHOULD HAVE / CUTTABLE

Later, components may have quality modifiers.

Example:

LOCAL BATTERY
+ Power
- Reliability

SUSPICIOUS BATTERY
++ Power
-- Reliability

Higher-quality component variants can alter resulting weapon stats.

Do NOT implement until the base combination system is fun.

---

# 27. Visual Direction

Style:

- colourful
- exaggerated
- readable
- playful
- Indian neighbourhood/workshop atmosphere
- slightly chaotic
- handmade/improvised

Possible environment details:

- corrugated metal
- bricks
- plastic chairs
- buckets
- old fans
- wires
- toolboxes
- tyres
- scrap piles
- chai glasses
- signs/posters
- scooters/bicycles

Avoid spending excessive time on detailed art before gameplay is proven.

Placeholder shapes are acceptable during development.

---

# 28. Audio Direction

Audio is important for game feel.

Important sounds:

- component pickup
- combining CLANK
- placement THUNK
- weapon firing
- electrical ZAP
- pressure POP
- weapon jam KHATAK
- repair THAK
- enemy hit
- workshop hit
- wave start
- wave complete
- arena expansion
- random event warning

Jugaad weapons should sound slightly unstable and homemade.

---

# 29. Tone / Writing

Short Hinglish/desi phrases are encouraged where readable.

Examples:

- NAYA JUGAAD!
- THOKO!
- LIGHT GAYI!
- LIGHT AA GAYI!
- NAYA RAASTA KHUL GAYA!
- GANG AA RAHI HAI!
- JUGAAD FAIL HO GAYA
- PHIR SE JUGAAD KARO

Do not overload the UI with text.

Humour should come primarily from gameplay and absurd contraptions.

---

# 30. End Screen

On defeat:

# JUGAAD FAIL HO GAYA

Possible statistics:

- Waves Survived
- Enemies Thoked
- Jugaads Built
- Jugaads Discovered
- Times Thoka
- Scrap Collected

Button:

**PHIR SE JUGAAD KARO**

---

# 31. Victory

After defeating THEKEDAAR:

Short ending.

Possible dialogue:

THEKEDAAR:
"Yeh sab engineering hai?"

Player:
"Nahi."

Pause.

"Jugaad hai."

Then:

# DEFENCE JUGAAD

YOU WIN

Credits.

Final dialogue is provisional and may be changed/cut.

---

# 32. MVP — FIRST PLAYABLE

THIS IS THE FIRST DEVELOPMENT TARGET.

Do not build the entire design immediately.

The MVP contains ONLY:

- top-down player movement
- workshop with HP
- one enemy spawn direction
- one basic enemy
- enemy pathing toward workshop
- component pickup
- two-hand inventory
- three base components
- three recipes
- combining
- carrying completed weapon
- placement
- automatic weapon targeting
- automatic attacks
- weapon instability/jamming
- player repair interaction
- one complete wave
- restart after failure

Initial MVP components:

- Cycle Wheel
- Rubber Band
- Battery
- Speaker / Pressure Cooker as needed for recipe tests

Initial weapon behaviours should test:

1. normal projectile targeting
2. AoE
3. crowd control/knockback

Suggested prototype weapons:

### Chakri Gun
Cycle Wheel + Rubber Band

Tests:
Projectile targeting and rapid attacks.

### Dhamaal Box
Battery + Speaker

Tests:
AoE.

### Pressure Horn
Pressure Cooker + Speaker

Tests:
Knockback.

If required, use 5 prototype components to support these three recipes.

All graphics may initially be primitive shapes.

---

# 33. MVP Success Criteria

Before adding major content, verify:

- movement feels responsive
- collecting components is understandable
- combining is fast
- placing weapons feels good
- automatic combat is readable
- running between defences is fun
- repair mechanic creates useful pressure
- one complete wave works
- game can restart
- no major runtime errors

Most importantly:

**Is the game fun with placeholder graphics?**

If NO:
Change the core loop before adding content.

If YES:
Proceed.

---

# 34. Development Order

## M0 — Foundation

- project structure
- input actions
- basic scene
- debug support

## M1 — Core Prototype

- player
- workshop
- enemy
- spawning
- movement
- health
- one attack direction

## M2 — Jugaad Loop

- component pickups
- two-hand inventory
- combination system
- weapon placement
- first three weapons

## M3 — Maintenance

- instability
- jamming
- repair interaction
- player knockback/drop behaviour

### PLAYTEST GATE

STOP.

Play the game.

Do not continue until the core loop has been evaluated.

## M4 — Content

- six components
- fifteen recipes
- enemy variety
- scrap economy
- Kabadiwala

## M5 — Escalation

- arena expansion
- multiple attack routes
- wave progression

## M6 — Chaos

- random events
- between-wave upgrades

## M7 — Finale

- boss
- victory
- game-over statistics

## M8 — Polish

- art
- animation
- VFX
- audio
- screenshake
- UI
- onboarding
- balancing

## M9 — Ship

- bug fixing
- complete playthroughs
- export testing
- submission build

---

# 35. 48-Hour Scope Rules

MUST HAVE:

- controllable player
- defence objective
- component collection
- two-item combining
- multiple Jugaad weapons
- placement
- automatic defence
- jamming
- repair
- waves
- clear win/lose condition

SHOULD HAVE:

- arena expansion
- 6 components
- 15 recipes
- multiple enemies
- random events
- Kabadiwala
- upgrade choices
- recipe discovery

NICE TO HAVE:

- component quality variants
- enemy copying player Jugaads
- detailed Jugaad Book
- elaborate boss
- extensive dialogue
- large upgrade pool

CUT FIRST IF BEHIND:

1. Component quality
2. Enemy copying
3. Extra random events
4. Extra upgrades
5. Jugaad Book presentation
6. Complex boss phases
7. Secondary animations
8. Any feature that threatens a stable build

Never cut the core combine → place → defend → repair loop.

---

# 36. Technical Principles

- Godot 4.7.x
- GDScript preferred
- 2D
- data-driven weapon/component definitions where practical
- avoid overengineering
- minimize dependencies
- use reusable systems only where they reduce implementation time
- prioritize deterministic/debuggable behaviour
- keep scenes reasonably isolated for multi-agent work

The combination system should make adding a recipe easy without rewriting core logic.

Weapon behaviour should use a shared base interface where practical.

Do not build a general-purpose crafting framework.

Build exactly what this game requires.

---

# 37. Multi-Agent Principle

Multiple humans/AI agents may work simultaneously.

Systems should be separated where practical.

Potential ownership:

**Core Gameplay**
- player
- game state
- waves
- combat
- combination architecture

**Content**
- recipes
- weapon behaviours
- enemy variants

**Presentation**
- UI
- VFX
- audio
- art
- menus

Agents must not independently expand scope.

GAME_SPEC.md is the design source of truth.

If a proposed implementation materially changes this document, ask the human team first.

---

# 38. Golden Rule

The game should make the player repeatedly experience:

**"This should absolutely not work..."**

followed by:

**"...but somehow it does."**

That feeling is Jugaad.

Everything in the game should serve that.