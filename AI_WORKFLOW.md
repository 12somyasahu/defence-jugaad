# DEFENCE JUGAAD — SHARED AI WORKFLOW

This document defines the shared working rules for every AI agent contributing to Defence Jugaad.

Agents currently involved:

- Codex — Primary Core Gameplay Engineer
- Claude Code — Specialist Engineer / Debugger / Reviewer
- Antigravity — Content & Presentation Engineer

Humans remain responsible for task assignment, priorities, creative decisions, playtesting, and final approval.

This is a 48-hour game jam.

The objective is not perfect software architecture.

The objective is:

**Build the smallest polished version of Defence Jugaad that is genuinely fun, clearly expresses the JUGAAD theme, and can be submitted reliably within the jam.**

---

# 1. SOURCE OF TRUTH

Before substantial work, agents must read the documents relevant to their role.

Game design source of truth:

`docs/GAME_SPEC.md`

Shared workflow source of truth:

`AI_WORKFLOW.md`

Agent-specific roles:

Codex:

`AGENTS.md`

Claude Code:

`CLAUDE.md`

Antigravity:

`ANTIGRAVITY.md`

If implementation and documentation disagree, do not silently invent a new design.

Determine whether the implementation is intentionally newer.

If uncertain, report the conflict to the human.

---

# 2. HUMAN AUTHORITY

Humans control:

- milestone progression
- scope changes
- major design decisions
- feature cuts
- creative direction
- agent assignments
- final integration decisions
- final submission

Agents must not assign tasks to other agents.

Agents may recommend a task for another lane, but the human decides whether to assign it.

---

# 3. AGENT OWNERSHIP

## Codex

Primary Core Gameplay Engineer.

Main ownership includes:

- player systems
- Workshop gameplay
- component system
- two-hand inventory
- recipe/combine system
- weapon base architecture
- enemy base architecture
- combat foundations
- targeting
- projectiles
- placement
- wave systems
- game state
- arena expansion
- main gameplay integration

Codex is the primary implementation agent.

---

## Claude Code

Specialist Engineer / Debugger / Reviewer.

Main uses include:

- difficult debugging
- architecture review
- performance investigation
- integration diagnosis
- subtle Godot problems
- isolated technically difficult systems
- reviewing important implementations
- identifying regressions

Claude should not independently rebuild systems already owned by Codex.

---

## Antigravity

Content & Presentation Engineer.

Main ownership includes:

- UI
- HUD
- menus
- visual assets
- VFX
- audio integration
- animations
- combat feedback
- component presentation
- weapon presentation
- enemy presentation
- Workshop visual deterioration
- arena expansion presentation
- discovery presentation
- event warnings
- onboarding presentation

Antigravity should integrate with core gameplay rather than replacing core architecture.

---

# 4. MULTI-AGENT RULE

Multiple agents may modify the repository during the jam.

Therefore, before substantial modifications:

1. Inspect the relevant files.
2. Inspect current Git status.
3. Understand what already exists.
4. Identify the smallest set of files required for the assigned task.
5. Avoid touching files owned by another active task unless integration requires it.

Never assume the repository is unchanged since the previous session.

---

# 5. HUMAN ACTION HANDOFF

Agents should perform normal development operations themselves.

Examples:

- reading files
- editing files
- running quick commands
- inspecting Git
- inspecting Godot
- running short tests
- debugging
- checking logs
- running quick builds
- verifying scenes
- verifying scripts

Do not make the human manually execute routine commands merely to conserve agent effort.

However, if an operation is substantially passive, expensive, or long-running, prepare everything first and hand the final operation to the human.

Examples:

- very large downloads
- SDK installations
- long dependency installations
- long builds
- long asset conversions
- large imports
- simulations
- substantial model training
- other operations where the agent would mostly wait

Use this exact handoff format:

```text
## HUMAN ACTION REQUIRED

Reason:
<why human execution is preferable>

Run:
<exact command or exact UI action>

Expected:
<what should happen>

Approx duration:
<reasonable estimate>

When finished:
<what the human should report back>
```

Before handing off, verify paths, arguments, and dependencies; prepare the workflow and run a small smoke test where useful. Stop before the substantial passive stage. Humans also own playtesting and final approval.

# 6. CREDIT CONSERVATION

Use reasoning and API credits for implementation, difficult debugging, review, integration, and testing analysis. Perform routine work yourself. Do not duplicate another agent's completed work, repeatedly poll passive operations, or waste tokens narrating obvious commands. Use Claude's specialist time for problems that benefit from deeper investigation rather than repetitive content entry.

# 7. TARGETED CONTEXT

Read the assigned system and its direct dependencies. Do not repeatedly scan the whole repository or reread unchanged documents. Recheck relevant instructions when they change and retain concise findings for the current task.

# 8. INSPECT BEFORE EDITING

Before substantial edits, inspect Git status, relevant files, existing implementation, and ownership. Check whether the requested behaviour already exists. Identify active work and the smallest set of files needed before making changes.

# 9. SMALL CHANGES

Make the smallest robust change that solves the assigned problem. Preserve working behaviour and public interfaces. Avoid unrelated cleanup, broad refactors, and rewriting another agent's system because of stylistic preference.

# 10. JAM ENGINEERING

Prioritize, in order:

1. Working
2. Fun
3. Understandable
4. Stable
5. Polished
6. Architecturally elegant

Prefer working > elegant and simple > generic. Do not build enterprise abstractions, speculative frameworks, or unnecessary dependencies. Measure confirmed performance problems before optimizing.

# 11. FINISHED OVER AMBITIOUS

A complete, stable smaller game is better than an ambitious unfinished one. Identify scope risks early and recommend cuts to the humans. Humans decide feature cuts; agents must not silently remove required behaviour.

# 12. FUN OVER ARCHITECTURE

Choose architecture that supports fast iteration, clear ownership, and reliable debugging. Playtesting determines whether the loop is enjoyable. Do not replace a functioning simple system with a generic framework without a concrete task need.

# 13. CORE FANTASY

Protect the experience: **"This should absolutely not work… but somehow it does."** The player is a Jugaad engineer improvising defences from everyday junk, not primarily a conventional fighter.

# 14. CORE LOOP PROTECTION

Protect this loop:

collect → carry two components → combine → create Jugaad → place → defend → repair/reposition → adapt → survive

The Workshop is the defence objective. Do not replace the loop with menu-only crafting, direct player combat, or unattended automation that removes the player's maintenance role.

# 15. TWO-HAND RULE

The player has exactly two hands/items for carrying components, one component per hand. Combining the pair produces one carried Jugaad that must be placed. Do not add a large inventory or extra carrying slots without an explicit human-approved design change.

The six base components are:

- Battery
- Cycle Wheel
- Pressure Cooker
- Speaker
- Table Fan
- Rubber Band

Two different components form an unordered recipe: A + B equals B + A. The six components support 15 handcrafted combinations; avoid useless experiment results.

# 16. PHYSICAL JUGAAD RULE

Collect, carry, place, repair, and reposition objects physically in the arena. Carried weapons do not attack. A Jugaad should visibly look constructed from its two source components, with a readable improvised connection between them.

# 17. RELIABILITY RULE

Instability builds through weapon use and is communicated clearly. At maximum instability, the weapon jams and stops until the player repairs it. Use readable meters, effects, prompts, and sounds rather than arbitrary hidden RNG. The intended repair interaction is approximately three physical hits; tune through authorized playtesting.

# 18. PLACEHOLDERS ARE ACCEPTABLE

Primitive shapes, temporary sounds, and simple labels are acceptable while proving the loop. Do not block core development on final art. Keep placeholders readable and compatible with later presentation work.

# 19. GODOT VERSION

Use Godot 4.7.x and GDScript for this 2D project; the current team editor is Godot 4.7.2. Do not upgrade the engine or dependencies without assignment. Use consistent filename casing and `res://` resource paths, and avoid hardcoded machine paths in game resources. Support Windows and macOS development.

# 20. GODOT MCP

Use Godot MCP where useful for scene inspection, runtime investigation, and validation. Preserve the working Toolkit, addon, autoload, and configuration. Do not reinstall or reconfigure MCP without a concrete need and authorization. Do not repeatedly retest connectivity unless there is an actual connection problem. Respect read-only task restrictions.

# 21. RUN THE GAME

Meaningful gameplay changes must be run in the relevant scene or game. Static inspection or a successful parse alone does not establish correct behaviour. Inspect editor/runtime output and report any environment blocker honestly. Documentation-only tasks need document checks, not unnecessary game runs.

# 22. TEST THE CHANGED BEHAVIOUR

Reproduce the original issue when applicable, then exercise the changed behaviour and its important edge cases. Verify the observable result, not merely that the project launches. Report exactly what was tested and distinguish automated checks from human playtesting.

# 23. REGRESSION CHECK

Check reasonable adjacent behaviour and integration contracts affected by the change. Keep testing proportional to risk. Once relevant checks pass, do not repeat them without a new change, failure, or unresolved concern.

# 24. PLAYTEST GATE

After M3, STOP for a mandatory HUMAN PLAYTEST GATE. Humans must evaluate collecting, combining, placing, defending, and repairing before content expansion. Do not automatically advance beyond M3 before human feedback and authorization. If the loop is weak, address it rather than concealing it with more content.

# 25. MILESTONE DISCIPLINE

The sequence is:

- M0 — Foundation
- M1 — Core Prototype
- M2 — Jugaad Loop
- M3 — Maintenance
- Mandatory HUMAN PLAYTEST GATE
- M4 — Content
- M5 — Expansion / Waves
- M6 — Events / Upgrades
- M7 — Finale
- M8 — Polish
- M9 — Ship

Work only on the task or milestone assigned by a human. A feature's presence in the design does not authorize implementation. Stop after the assigned work is tested; do not start the next milestone automatically.

# 26. MVP PRIORITY

Prove a small playable loop: movement, Workshop health, one attack direction, one basic enemy, pickups, two-hand combining, carrying and placement, three weapon behaviours, automatic combat, jamming and repair, one complete wave, and restart after failure. Use only the prototype components needed. Defer expanded content, economy, events, upgrades, and finale work until assigned.

# 27. FIRST WEAPON PRIORITY

The first three prototype weapons test distinct behaviours:

- **Chakri Gun:** Cycle Wheel + Rubber Band; reliable projectile DPS.
- **Dhamaal Box:** Battery + Speaker; AoE sonic/electrical attack.
- **Pressure Horn:** Pressure Cooker + Speaker; directional knockback/control.

These recipes require five prototype components. Validate their different combat roles before scaling the catalogue; this does not authorize implementing them ahead of the assigned milestone.

# 28. CONTENT EXPANSION RULE

Expand toward six components and 15 recipes only after the core loop is evaluated and humans authorize the work. Add content through existing interfaces. Use small explicit definitions where helpful, not a general-purpose crafting framework. Coordinate content tasks with the core owner.

# 29. VISUAL READABILITY

Prioritize recognizing enemies, pickups, placed weapons, jam states, attack areas, and Workshop danger at gameplay scale. Effects must support decisions and avoid obscuring combat. Readability comes before decorative detail.

# 30. COMPONENT SILHOUETTES

Battery, Cycle Wheel, Pressure Cooker, Speaker, Table Fan, and Rubber Band must be distinguishable by silhouette and form, not colour alone. Keep pickup, carried, and UI representations consistent and readable.

# 31. JUGAAD VISUAL IDENTITY

Retain recognizable parts of both recipe components in each weapon. Use improvised supports, wires, straps, or other simple connections to communicate assembly. Weapon presentation should communicate its range, attack role, and reliability without disguising its source objects.

# 32. INDIAN WORKSHOP TONE

Use a colourful, playful Indian neighbourhood/workshop atmosphere and exaggerated improvised equipment. Short readable Hinglish phrases can support the tone. Keep violence cartoonish; let absurd contraptions and gameplay carry the humour. Humans retain creative decisions.

# 33. AUDIO PRIORITY

Prioritize clear feedback for pickup, combining, placement, firing, hits, jamming, repair, Workshop damage, wave transitions, and warnings. Make jam and repair sounds distinguishable in combat. Integrate audio without delaying the playable loop or overwhelming important cues.

# 34. UI PRIORITY

Communicate Workshop health, held components, placement validity, jam/repair state, and wave state first. Add economy, discovery, menus, and onboarding presentation when the corresponding systems are assigned. Keep text concise and avoid elaborate screens before core behaviour works.

# 35. EVENT RULE

Events should be clearly telegraphed, understandable disruptions that encourage adaptation. Use the defined events and existing contracts when assigned. Do not add hidden arbitrary penalties or expand the event roster without human approval.

# 36. ARENA EXPANSION RULE

Begin with one vulnerable direction and reveal additional routes at the authorized wave milestones. Expansion presentation should make the new threat obvious. Existing weapons remain where placed; the player physically redistributes them. Coordinate core progression with presentation rather than duplicating either system.

# 37. ENEMY RULE

Keep enemies mechanically distinct: Gunda is basic, Chotu is fast, Pehelwan is durable, Kabadi Chor steals components, and Mechanic sabotages Jugaads. Start with the basic enemy for the prototype. Core owns common behaviour/contracts; assigned content and presentation work integrates with them. Do not introduce extra enemy systems without assignment.

# 38. BOSS RULE

The specified boss is **THEKEDAAR**, using an improvised vehicle. Implement the finale only when assigned. Visible modules may alter attacks or movement when destroyed, but complex phases are cuttable by humans. Do not let boss ambition threaten a stable submission.

# 39. GIT DISCIPLINE

Inspect status before substantial changes and keep changes focused. Do not delete or reset unrelated work, discard another person's changes, rewrite history, force push, or delete others' branches. Do not push unless explicitly requested. Never commit secrets or credentials. Keep the shared main branch playable and follow human integration decisions.

# 40. CONCURRENT EDIT SAFETY

Never overwrite another agent's active work. Recheck affected files before writing when concurrent edits are possible. If conflicting concurrent work is detected, STOP and report the files, overlap, and proposed coordination need. Do not resolve ownership conflicts by replacing the other implementation. Humans assign tasks between lanes.

# 41. ERROR HANDLING

Investigate root causes and make narrow fixes. Do not hide failures, disable warnings globally, remove validation to fake success, or claim tests that were not run. Distinguish historical errors from new ones. Report unresolved problems and their impact; stop if resolving them would exceed the assigned scope.

# 42. NO SILENT SCOPE EXPANSION

Do not add features, dependencies, architecture, or design changes outside the task. Present material conflicts and proposed changes to humans before proceeding. Do not autonomously advance milestones, execute suggested next steps, or turn a review into an unrequested rewrite.

# 43. COMPLETION REPORT

Every implementation, debugging, or review task ends with this structure. State actual evidence; for a review-only task, report findings and explicitly identify checks not run.

```text
## DONE
- What was completed or reviewed.

## TESTED
- What was actually run, exercised, or inspected.

## KNOWN ISSUES
- Remaining issues and uncertainty, or None known.

## INTEGRATION / HUMAN ACTION
- Changed contracts, integration needs, or required human action; otherwise None.

## NEXT
- One recommended next action.
```

Do not automatically execute NEXT. Use the Section 5 handoff format when a substantial passive operation requires human execution.

# 44. FINAL SHARED RULE

Before substantial work, determine:

- What am I responsible for?
- What exact task was I assigned?
- Which files/systems belong to someone else?
- What is the smallest implementation that solves the task?
- How will I test it?
- When should I stop?

Then:

implement → test → report → stop.
