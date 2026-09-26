extends "res://tests/test_m7a.gd"

# Game shell regression: main menu, pause, end-screen buttons and run transitions.
# Run: <Godot 4.7 exe> --headless --path . -s res://tests/test_shell.gd

const MENU: PackedScene = preload("res://ui/shell/main_menu.tscn")

func _run() -> void:
	await _menu()
	await _pause()
	await _end_buttons()
	await _transitions()
	print("Shell tests: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)

func _frames(count: int) -> void:
	for i in count:
		await physics_frame
	await process_frame

func _wait_scene(previous: Node) -> void:
	for i in 60:
		if current_scene != null and current_scene != previous:
			return
		await _frames(1)

func _menu() -> void:
	check(ProjectSettings.get_setting("application/run/main_scene") == "res://ui/shell/main_menu.tscn", "boots into main menu")
	var menu: MainMenu = MENU.instantiate()
	root.add_child(menu)
	await _frames(2)
	check(menu.play_button.text == "PLAY" and menu.how_button.text == "HOW TO PLAY" and menu.quit_button.text == "QUIT", "menu buttons")
	check(menu.play_button.has_focus(), "PLAY focused for keyboard")
	check(not menu.how_to_play.visible, "how to play hidden at start")
	menu.how_button.pressed.emit()
	check(menu.how_to_play.visible and menu.how_to_play.back_button.has_focus(), "how to play opens")
	menu.how_to_play.back_button.pressed.emit()
	check(not menu.how_to_play.visible and menu.how_button.has_focus(), "how to play back")
	menu.queue_free()
	await _frames(1)

func _pause() -> void:
	await _fresh()
	var shell: GameShell = main.get_node("GameShell")
	check(shell.process_mode == Node.PROCESS_MODE_ALWAYS and not shell.is_paused(), "shell ready, not paused")
	var player: Node2D = main.get_node("Player")
	shell.pause()
	check(paused and shell.is_paused() and shell.resume_button.has_focus(), "pause freezes tree")
	check(not player.can_process() and not main.get_node("Enemies").can_process() and not main.get_node("BossDirector").can_process(), "gameplay stops while paused")
	check(shell.can_process() and shell.how_to_play.can_process(), "pause UI keeps processing")
	shell.pause_how_button.pressed.emit()
	check(shell.how_to_play.visible and paused, "how to play keeps game paused")
	shell.how_to_play.back_button.pressed.emit()
	check(not shell.how_to_play.visible and shell.is_paused() and paused, "back returns to pause menu")
	shell.resume_button.pressed.emit()
	check(not paused and not shell.is_paused() and player.can_process(), "resume")

func _end_buttons() -> void:
	await _fresh()
	var shell: GameShell = main.get_node("GameShell")
	var hud: HUD = main.get_node("HUD")
	for panel in [hud.victory_panel, hud.defeat_panel]:
		check(shell.end_buttons.has(panel), "end buttons on " + panel.name)
	workshop.receive_damage(99999)
	await _frames(2)
	check(hud.defeat_panel.visible and shell.end_buttons[hud.defeat_panel].is_visible_in_tree(), "defeat shows TRY AGAIN")
	check(shell.end_buttons[hud.defeat_panel].text == "TRY AGAIN" and shell.end_buttons[hud.victory_panel].text == "PLAY AGAIN", "end button labels")
	check(shell.end_buttons[hud.defeat_panel].has_focus(), "end button focused for keyboard")
	shell.pause()
	check(not paused and not shell.is_paused(), "no pause on end screen")

func _transitions() -> void:
	# TRY AGAIN from defeat -> a clean new run via the existing reload path.
	current_scene = main
	var shell: GameShell = main.get_node("GameShell")
	var old: Node = main
	shell.end_buttons[main.get_node("HUD").defeat_panel].pressed.emit()
	await _wait_scene(old)
	var fresh: Node = current_scene
	check(fresh != old and fresh.name == "Main", "try again reloads the run")
	check(fresh.get_node("Workshop").current_hp == fresh.get_node("Workshop").maximum_hp and not fresh.is_defeated, "workshop reset")
	check(fresh.get_node("ScrapEconomy").scrap == 0 and fresh.get_node("RunStats").snapshot().kills == 0, "economy and stats reset")
	check(fresh.get_node("WaveDirector").current_wave() <= 1 and fresh.get_node("BossDirector").stage == &"idle", "waves and boss reset")
	check(not paused, "fresh run unpaused")
	# Pause -> MAIN MENU -> PLAY again.
	await _frames(2)
	var shell2: GameShell = fresh.get_node("GameShell")
	shell2.pause()
	shell2.to_main_menu()
	await _wait_scene(fresh)
	check(current_scene is MainMenu and not paused, "pause menu returns to title")
	var menu: MainMenu = current_scene
	await _frames(2)
	menu.play_button.pressed.emit()
	await _wait_scene(menu)
	check(current_scene != null and current_scene.name == "Main" and current_scene.get_node("Workshop").current_hp == 500, "PLAY starts a fresh run")
	check(current_scene.get_node("AudioManager").music_id == "preparation_theme", "run audio starts in preparation")
