# Defence Jugaad — Asset, UI & HUD Presentation Guide

This document defines the visual and presentation language for Defence Jugaad.

It is the authoritative guide for CONTENT & PRESENTATION work.

It does not define gameplay behaviour.

If this document conflicts with the gameplay architecture defined by
`docs/GAME_SPEC.md`, gameplay architecture takes precedence.

==================================================
0. CORE PRINCIPLE
==================================================

Defence Jugaad is a 48-hour game-jam game.

Presentation must maximize:

READABILITY
→ PERSONALITY
→ GAME FEEL
→ DETAIL

Never reverse this priority.

A beautiful asset that cannot be recognized during gameplay is a failed asset.

A simple asset with an immediately readable silhouette is successful.

The game should feel handmade, improvised, colourful, funny, and mechanically
absurd.

Guiding phrase:

"This should absolutely not work… but somehow it does."

==================================================
1. VISUAL IDENTITY
==================================================

Defence Jugaad is NOT:

- generic sci-fi
- cyberpunk
- military realism
- realistic engineering simulation
- grimdark survival
- futuristic tower defence
- photorealistic
- polished corporate vector art

Defence Jugaad IS:

- Indian workshop energy
- roadside repair-shop energy
- scrap-yard engineering
- household objects repurposed into weapons
- mismatched materials
- exposed wiring
- tape
- bolts
- bent metal
- reused plastic
- old electrical components
- ridiculous mechanical assemblies
- colourful cartoon presentation

The player should look at a machine and think:

"Who the hell built this?"

followed immediately by:

"...but I can see how it works."

==================================================
2. CAMERA AND VIEW
==================================================

Gameplay is presented from a top-down / slightly elevated 2D perspective.

Assets must be designed for this camera.

Do not create assets using a dramatic cinematic side view.

Do not create assets using a realistic three-quarter product-render perspective.

The viewer should be able to identify the object from above.

Important visual surfaces should remain visible from the gameplay camera.

Prefer:

- top-facing surfaces
- readable circular shapes
- chunky silhouettes
- limited perspective distortion

Avoid:

- thin side profiles
- objects whose identity depends on a frontal photograph-like view
- excessive foreshortening

==================================================
3. SILHOUETTE FIRST
==================================================

Every gameplay asset must pass a silhouette test.

Before details are added, the object must be recognizable using only:

- outer silhouette
- major internal shape
- one or two characteristic features

Examples:

BATTERY
→ rectangular body + two terminals

CYCLE WHEEL
→ circular tyre + spokes

PRESSURE COOKER
→ round body + lid + handle

SPEAKER
→ box + large circular speaker cone

TABLE FAN
→ circular fan cage + stand

RUBBER BAND
→ thick visible loop / wrapped band

If an asset cannot be identified at small size without colour or texture,
redesign the silhouette.

==================================================
4. GAMEPLAY SCALE
==================================================

Assets are game sprites, not illustrations.

They must remain readable when displayed at approximately:

64 × 64 px

and preferably still recognizable around:

48 × 48 px

Do not add detail merely because there is empty space.

At gameplay scale:

large shapes > small details

silhouette > texture

colour blocks > gradients

recognizable parts > decorative parts

==================================================
5. SHAPE LANGUAGE
==================================================

Use:

- chunky geometry
- rounded corners
- slightly exaggerated proportions
- simple mechanical forms
- large readable components
- deliberate asymmetry where appropriate

Avoid:

- razor-thin geometry
- microscopic bolts
- excessive mechanical complexity
- realistic CAD-like construction
- hundreds of decorative components

Jugaad machines should look assembled from objects humans could plausibly
find in a workshop.

==================================================
6. IMPERFECTION IS INTENTIONAL
==================================================

The game should not look factory-perfect.

Controlled imperfection is encouraged:

- slightly crooked panels
- mismatched screws
- uneven tape
- exposed wires
- bent brackets
- repaired surfaces
- patched metal
- reused parts

However:

IMPERFECTION MUST NEVER REDUCE READABILITY.

Do not randomly distort the entire object.

The main silhouette must remain clean.

==================================================
7. MATERIAL LANGUAGE
==================================================

Prefer materials that communicate everyday Indian workshop objects:

METAL
- painted steel
- worn aluminium
- old iron
- patched sheet metal

PLASTIC
- faded coloured plastic
- old appliance plastic
- slightly scratched surfaces

ELECTRICAL
- insulated wires
- terminals
- switches
- LEDs
- connectors

REPAIR MATERIALS
- electrical tape
- cloth tape
- zip ties
- bolts
- brackets
- crude welds

Do not introduce futuristic materials such as:

- holographic panels
- glowing sci-fi alloys
- advanced energy cores
- sleek carbon composites

unless specifically requested for a gameplay reason.

==================================================
8. OUTLINES
==================================================

Use a strong dark outline around major forms.

The outline should:

- separate the object from the environment
- survive gameplay scale
- reinforce the cartoon style
- create visual consistency across assets

Avoid extremely thin outlines.

Avoid photorealistic edge treatment.

Do not use multiple competing outline colours within one asset.

The outline should generally be a dark neutral / dark warm colour rather
than pure black where practical.

==================================================
9. COLOUR
==================================================

The palette should feel:

- warm
- colourful
- slightly worn
- playful

Prefer a controlled palette rather than unlimited colours.

Recommended colour families:

- warm cream / off-white
- dirty grey
- dark charcoal
- workshop brown
- muted orange
- yellow
- red
- teal
- green
- occasional blue

Bright colours should communicate important gameplay information.

Do not make every object maximally saturated.

Colour should support hierarchy.

==================================================
10. SHADING
==================================================

Use simple stylized shading.

Preferred:

BASE COLOUR
+
ONE PRIMARY SHADOW
+
OPTIONAL SMALL HIGHLIGHT

Avoid:

- photorealistic rendering
- complex gradients
- dramatic cinematic lighting
- glossy 3D rendering
- excessive ambient occlusion

The asset must still work when viewed without its shading.

==================================================
11. TEXTURE
==================================================

Texture is secondary.

Allowed:

- small scratches
- dents
- paint wear
- tiny rust marks
- tape edges

Do not cover assets in noise.

Texture must never obscure:

- component identity
- silhouette
- source-component identity
- gameplay state

==================================================
12. COMPONENT ASSET SPECIFICATION
==================================================

The six base components are gameplay objects.

Each must have an unmistakable identity.

--------------------------------------------------
12.1 BATTERY
--------------------------------------------------

Primary silhouette:

Chunky rectangular battery.

Required visual cues:

- two terminals
- battery casing
- readable positive/negative terminal distinction
- simple label or marking
- optional exposed wire / tape

The battery should look like an everyday electrical battery,
not a futuristic power cell.

Avoid:

- glowing energy cores
- sci-fi batteries
- floating holographic indicators

--------------------------------------------------
12.2 CYCLE WHEEL
--------------------------------------------------

Primary silhouette:

Large circular bicycle wheel.

Required visual cues:

- tyre
- rim
- spokes
- central hub

The circular silhouette must dominate.

The wheel should look slightly used rather than pristine.

--------------------------------------------------
12.3 PRESSURE COOKER
--------------------------------------------------

Primary silhouette:

Round pressure cooker viewed from slightly above.

Required visual cues:

- cooker body
- lid
- pressure valve
- handle

The cooker must immediately read as a household pressure cooker.

Do not redesign it into a generic metal container.

--------------------------------------------------
12.4 SPEAKER
--------------------------------------------------

Primary silhouette:

Box containing a large circular speaker cone.

Required visual cues:

- speaker cone
- casing
- grille or rim
- cable

The circular speaker cone should remain visually obvious.

--------------------------------------------------
12.5 TABLE FAN
--------------------------------------------------

Primary silhouette:

Large circular fan cage with supporting body.

Required visual cues:

- circular cage
- visible blades
- central hub
- motor housing
- stand

The circular cage should dominate the silhouette.

--------------------------------------------------
12.6 RUBBER BAND
--------------------------------------------------

Rubber bands are naturally difficult to read at small scale.

Therefore exaggerate thickness.

The band must remain visually obvious.

Prefer:

- thick loop
- stretched band
- wrapped band
- strongly contrasting colour

Do not represent it as a hair-thin line.

==================================================
13. JUGAAD WEAPONS
==================================================

Jugaad weapons are combinations of existing components.

The source components must remain visually identifiable.

This is a HARD RULE.

A weapon made from:

A + B

must visibly communicate:

A + B

It must not become a generic new machine that merely has
A and B hidden somewhere inside.

--------------------------------------------------
13.1 CHAKRI GUN
--------------------------------------------------

Source components:

Cycle Wheel
+
Rubber Band

The cycle wheel must remain obvious.

The rubber band must remain obvious.

The weapon should visually imply that the wheel and rubber band
are part of the firing mechanism.

Possible visual language:

- wheel mounted as a rotating mechanism
- stretched rubber band
- crude barrel / launch guide
- improvised frame
- tape / bolts

Do not turn it into a conventional military gun with a bicycle wheel
decorating the side.

--------------------------------------------------
13.2 DHAMAAL BOX
--------------------------------------------------

Source components:

Battery
+
Speaker

Both must be obvious.

The speaker cone should be prominent.

The battery should remain visibly attached or integrated.

Wires should help communicate the relationship.

The result should resemble:

"someone connected a battery to a speaker and weaponized it."

Not:

"futuristic sonic turret."

--------------------------------------------------
13.3 PRESSURE HORN
--------------------------------------------------

Source components:

Pressure Cooker
+
Speaker

Both must remain immediately identifiable.

The pressure cooker should form the main body.

The speaker should form the directional horn / output mechanism.

The resulting silhouette should be funny and mechanically absurd.

==================================================
14. CHARACTER STYLE
==================================================

Characters use the same visual language as objects:

- chunky
- readable
- colourful
- thick outline
- limited shading
- exaggerated silhouette

Characters should be readable primarily from:

- body shape
- clothing silhouette
- major accessories
- colour blocks

Do not depend on facial detail.

--------------------------------------------------
14.1 ENGINEER
--------------------------------------------------

The Engineer represents the player.

Visual impression:

resourceful workshop mechanic.

Useful visual cues:

- practical clothing
- rolled sleeves
- tool-related accessory
- slightly messy appearance
- workshop equipment
- confident / busy posture

The character should communicate:

"I can probably fix this."

Avoid making the Engineer look like:

- a futuristic scientist
- military soldier
- superhero
- generic businessman
- realistic technician

--------------------------------------------------
14.2 GUNDA
--------------------------------------------------

The Gunda is an enemy.

Visual impression:

scrap-yard / rival gang member.

Use a silhouette clearly different from the Engineer.

Useful cues:

- broader silhouette
- rough clothing
- improvised equipment
- aggressive posture
- exaggerated proportions

The Gunda should be funny and threatening without becoming grotesque.

Avoid:

- realistic violence
- military uniforms
- generic fantasy or sci-fi enemies

==================================================
15. WORKSHOP
==================================================

The Workshop is a major visual anchor.

It must immediately communicate:

"THIS IS THE THING WE ARE DEFENDING."

It should feel like:

- improvised garage
- electronics bench
- repair shop
- scrap workshop
- chaotic engineering station

Potential visual elements:

- workbench
- wires
- batteries
- tools
- fans
- speakers
- scrap metal
- electrical equipment
- tape
- homemade machinery

Avoid generic:

- sci-fi reactor
- military command centre
- futuristic power generator

--------------------------------------------------
WORKSHOP DAMAGE STATES
--------------------------------------------------

The Workshop should support:

100%
75%
50%
25%

Damage states should progressively communicate deterioration.

Possible progression:

100%
→ functional, cluttered, energetic

75%
→ minor damage / sparks / displaced parts

50%
→ visibly damaged / broken components

25%
→ heavily damaged / unstable / desperate

The silhouette and identity of the Workshop must remain recognizable
at every state.

==================================================
16. UI DESIGN
==================================================

UI must belong to the same world as the game.

Do not use generic futuristic HUD styling.

Avoid:

- neon sci-fi panels
- glassmorphism
- holographic UI
- military tactical HUDs
- excessive gradients
- thin technical typography

Preferred:

- chunky panels
- workshop-inspired shapes
- slightly irregular geometry
- warm neutral backgrounds
- strong dark outlines
- accent colours
- simple icons

UI should feel like:

"someone made a game HUD out of workshop labels and painted metal."

==================================================
17. HUD PRIORITY
==================================================

The HUD should communicate gameplay state immediately.

Priority:

1. Workshop danger / HP
2. Held items
3. Wave
4. Scrap
5. Contextual prompts

Do not make decorative UI larger or louder than gameplay information.

==================================================
18. TWO-HAND DISPLAY
==================================================

The player has:

LEFT HAND
RIGHT HAND

These must be visually distinct.

Each hand slot should display:

- item icon
- selected/active state
- empty state

The icon must use the actual component/weapon visual language.

Do not use generic inventory icons.

==================================================
19. WORKSHOP HP
==================================================

Workshop health should be immediately readable.

Preferred representation:

- chunky health bar
- workshop icon
- clear colour/state transition

The exact numerical presentation is secondary to immediate danger
recognition.

Health should become visually urgent as the Workshop approaches
destruction.

Do not rely on tiny text alone.

==================================================
20. WAVE INDICATOR
==================================================

Wave information should be compact.

Example:

WAVE 04

It should not dominate the screen.

A wave start event may use larger temporary presentation,
but the persistent HUD should remain compact.

==================================================
21. SCRAP
==================================================

Scrap is the game's resource.

The HUD representation should look physical / workshop-related.

Prefer an icon resembling:

- scrap metal
- bolt
- nut
- metal piece

Avoid generic fantasy coins.

==================================================
22. TYPOGRAPHY
==================================================

Typography should be:

- bold
- highly readable
- playful
- slightly handmade where appropriate

Never sacrifice readability for personality.

Important messages such as:

NAYA JUGAAD!

NAYA RAASTA KHUL GAYA!

JAM!

REPAIR!

must be readable immediately.

==================================================
23. FEEDBACK LANGUAGE
==================================================

Feedback should feel physical and energetic.

PICKUP
→ quick pop / snap

COMBINE
→ mechanical assembly moment

NAYA JUGAAD!
→ strong celebratory presentation

PLACEMENT
→ satisfying confirmation

WEAPON FIRE
→ physical motion corresponding to the weapon

HIT
→ brief readable impact

JAM
→ obvious mechanical failure

REPAIR
→ satisfying restoration

WORKSHOP DAMAGE
→ stronger screen/world feedback as danger increases

WAVE START
→ clear but brief announcement

ARENA EXPANSION
→ communicate discovery

NAYA RAASTA KHUL GAYA!
→ major discovery moment

Do not use generic particle spam for every event.

Different events should have different visual signatures.

==================================================
24. VFX STYLE
==================================================

VFX should use the same stylized language.

Prefer:

- chunky particles
- simple shapes
- short bursts
- readable motion
- sparks
- dust
- impact rings
- small debris

Avoid:

- photorealistic explosions
- excessive bloom
- giant particle clouds
- effects that obscure gameplay

Effects should reinforce the action, not hide it.

==================================================
25. ANIMATION
==================================================

Animation should exaggerate mechanical personality.

Prefer:

- squash/stretch
- quick recoil
- small shakes
- wheel rotation
- rubber-band tension
- fan rotation
- cooker vibration
- speaker pulse
- sparks

The animation should communicate mechanism.

Example:

CHAKRI GUN

wheel rotates
→ rubber band tensions
→ release
→ projectile
→ tiny recoil

This is preferable to simply playing a generic muzzle flash.

==================================================
26. SVG PRODUCTION RULES
==================================================

SVG is the preferred format for reusable 2D assets.

SVGs must be:

- self-contained
- relative/path-safe
- free of machine-specific paths
- reasonably lightweight
- editable
- compatible with Godot import

Avoid unnecessarily complex SVGs.

Do not auto-trace highly detailed raster images into thousands of paths.

Prefer manually structured vector geometry.

Major visual parts should correspond to understandable SVG elements.

Examples:

- body
- wheel
- spokes
- handle
- speaker cone
- wire
- tape

==================================================
27. SVG COMPLEXITY
==================================================

The target is not the smallest possible SVG.

The target is:

minimum complexity required for the intended visual result.

Avoid:

- thousands of tiny paths
- embedded raster images
- unnecessary filters
- excessive clipping paths
- unnecessary masks
- complex gradients
- unsupported SVG features

A simple SVG with 30 meaningful shapes is preferable to
an auto-traced SVG with 3000 meaningless paths.

==================================================
28. LAYERING
==================================================

When an asset will likely require animation, keep meaningful parts
separable where practical.

Examples:

CHAKRI GUN

- frame
- wheel
- rubber band
- barrel

TABLE FAN

- body
- cage
- blades
- stand

ENGINEER

- body
- head
- arms
- tool

Do not create unnecessary fragmentation.

48-hour jam scope takes priority.

==================================================
29. ASSET NAMING
==================================================

Use lowercase snake_case.

Examples:

battery.svg
cycle_wheel.svg
pressure_cooker.svg
speaker.svg
table_fan.svg
rubber_band.svg

chakri_gun.svg
dhamaal_box.svg
pressure_horn.svg

gunda.svg
engineer.svg

Avoid:

Battery.svg
batteryFinal.svg
battery_final2.svg
Battery_NEW.svg

Never rely on case-only filename differences.

==================================================
30. DIRECTORY STRUCTURE
==================================================

Presentation assets should follow a predictable structure.

Preferred:

assets/
    components/
    characters/
    weapons/
    workshop/
    ui/
    vfx/

ui/
    hud/
    menus/
    feedback/

Keep presentation assets separate from gameplay code.

==================================================
31. GENERATION WORKFLOW
==================================================

Do NOT generate the final production SVG immediately.

Preferred workflow:

STEP 1
Create / review visual concept.

STEP 2
Validate silhouette.

STEP 3
Validate consistency against existing assets.

STEP 4
Validate gameplay-scale readability.

STEP 5
Create production SVG.

STEP 6
Import into Godot.

STEP 7
Test at gameplay scale.

STEP 8
Inspect SVG complexity.

STEP 9
Commit only the finished asset.

Do not generate large batches of mediocre assets.

==================================================
32. MASTER STYLE REFERENCE
==================================================

A master visual reference should be maintained for consistency.

Before creating a new asset, compare it against:

- existing component assets
- Engineer
- Gunda
- Workshop
- Jugaad weapons

A new asset must look like it belongs to the same game.

If it does not:

STOP.

Do not compensate with additional detail.

Adjust the design.

==================================================
33. QUALITY CHECKLIST
==================================================

Before considering an asset complete:

[ ] recognizable silhouette
[ ] recognizable at gameplay scale
[ ] consistent outline
[ ] consistent shading
[ ] consistent palette
[ ] appropriate top-down view
[ ] visually belongs to Defence Jugaad
[ ] does not look futuristic without reason
[ ] does not resemble generic tower defence
[ ] source components remain recognizable
[ ] no unnecessary detail
[ ] SVG is reasonably lightweight
[ ] no embedded raster image
[ ] no machine-specific path
[ ] filename follows convention
[ ] Godot imports successfully

==================================================
34. IMPORTANT FAILURE CONDITIONS
==================================================

An asset should be rejected if:

- it looks like a different art style
- it is difficult to identify
- it only looks good when zoomed in
- it resembles generic sci-fi
- source components disappear inside a Jugaad weapon
- excessive detail makes it visually noisy
- the silhouette is weak
- the SVG is unnecessarily complex
- UI becomes more visually dominant than gameplay

==================================================
35. CONTENT & PRESENTATION BOUNDARY
==================================================

Presentation engineers may:

- create assets
- create presentation scenes
- create UI
- create HUD visuals
- create VFX
- create animations
- integrate stable presentation hooks
- request signals from core systems

Presentation engineers must NOT independently create:

- gameplay state
- inventory state
- weapon logic
- enemy AI
- health logic
- wave logic
- targeting
- projectile logic
- recipe logic
- combine logic

If presentation requires missing gameplay information:

REPORT:

NEEDED CORE HOOK:
<exact signal/state/data required>

Do not create a competing implementation.

==================================================
36. GOLDEN RULE
==================================================

When choosing between:

MORE DETAIL

and

MORE READABILITY

choose readability.

When choosing between:

REALISM

and

JUGAAD PERSONALITY

choose Jugaad personality.

When choosing between:

GENERIC POLISH

and

DISTINCTIVE IDENTITY

choose distinctive identity.

When choosing between:

A COMPLEX ASSET

and

A SIMPLE ASSET THAT READS PERFECTLY

choose the simple asset.

Defence Jugaad should look like something that could only have been
made by people who decided:

"Why buy a proper machine when we have a pressure cooker, a bicycle
wheel and some wire?"