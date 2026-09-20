extends SceneTree

const BASE := Vector2(1440, 900)
var game
var failures: Array[String] = []
var shots := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1440, 900))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-artifacts/ui"))
	# Start the visual regression from a clean title state. Earlier QA/campaign
	# jobs intentionally share the test profile and may leave a resumable run.
	var test_save := ProjectSettings.globalize_path("user://ashen_vow_test.json")
	if FileAccess.file_exists("user://ashen_vow_test.json"):
		DirAccess.remove_absolute(test_save)
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	# Each harness must start from a clean profile state even when prior CI steps saved a run.
	game.profile.run = {}
	game.profile.settings.touch = false
	game.profile.write_save()
	await _frames(5)

	# Every UI run starts from a deterministic profile. Previous test processes
	# share user:// on the runner and may otherwise leave CONTINUE or touch mode on.
	game.profile.run = {}
	game.profile.settings = {"music": .65, "sfx": .8, "shake": .7, "auto_aim": false, "touch": false}
	game.sound.settings = game.profile.settings
	game.sound.update_volume()
	game.profile.write_save()
	game.mode = "title"
	game.ui.queue_redraw()
	await _frames(3)

	_expect("starts on title", game.mode == "title")
	await _shot("01_title")

	# Gamepad-only menu flow: spatial D-pad focus, activation and B/back.
	await _joy(JOY_BUTTON_DPAD_DOWN)
	_expect("gamepad down moves title focus spatially to settings", game.ui.pad_focus == 1)
	await _joy(JOY_BUTTON_A)
	_expect("gamepad A opens focused title settings", game.mode == "settings")
	await _frames(2)
	var pad_sfx_before: float = game.profile.settings.sfx
	await _joy(JOY_BUTTON_DPAD_DOWN)
	_expect("gamepad down advances settings focus", game.ui.pad_focus == 1)
	await _joy(JOY_BUTTON_A)
	_expect("gamepad A changes focused setting", not is_equal_approx(pad_sfx_before, float(game.profile.settings.sfx)))
	await _joy(JOY_BUTTON_B)
	_expect("gamepad B returns from settings", game.mode == "title")
	await _frames(2)

	await _click(Vector2(190, 638))
	_expect("title settings click", game.mode == "settings")
	await _shot("02_settings")
	var music_before: float = game.profile.settings.music
	await _click(Vector2(720, 252))
	_expect("settings value changes by click", not is_equal_approx(music_before, float(game.profile.settings.music)))
	await _click(Vector2(720, 737))
	_expect("settings back returns to title", game.mode == "title")

	await _click(Vector2(373, 638))
	_expect("help click", game.mode == "help")
	await _shot("03_help")
	await _click(Vector2(720, 788))
	_expect("help back returns to title", game.mode == "title")

	await _click(Vector2(281, 577))
	_expect("begin descent click", game.mode == "play")
	await _frames(4)
	await _shot("04_gameplay")

	await _click(Vector2(1294, 88))
	_expect("minimap opens large map", game.ui.big_map)
	await _shot("05_map")
	await _click(Vector2(1294, 88))
	_expect("minimap closes large map", not game.ui.big_map)

	var sample := ItemDB.generate(game.rng, 3, 3, 0)
	game.player.inventory.append(sample)
	game.save_run()
	await _click(Vector2(1094, 847))
	_expect("reliquary click", game.mode == "inventory")
	await _frames(3)
	await _shot("06_inventory")
	await _click(Vector2(380, 226))
	_expect("inventory item click selects first item", game.ui.selected == 0)
	var slot: String = game.player.inventory[0].slot
	var old_id: String = game.player.equipment[slot].id
	await _click(Vector2(901, 788))
	_expect("equip click swaps equipment", game.player.equipment[slot].id != old_id)
	await _shot("07_inventory_equipped")
	var pad_equipped_id: String = game.player.equipment[slot].id
	await _joy(JOY_BUTTON_X)
	_expect("gamepad X equips selected inventory item directly", game.player.equipment[slot].id != pad_equipped_id)
	await _click(Vector2(1305, 61))
	_expect("inventory return click", game.mode == "play")

	await _click(Vector2(1294, 847))
	_expect("pause click", game.mode == "pause")
	await _shot("08_pause")
	await _click(Vector2(720, 426))
	_expect("pause settings click", game.mode == "settings")
	await _shot("09_pause_settings")
	await _click(Vector2(720, 737))
	_expect("nested settings back returns to pause", game.mode == "pause")
	await _click(Vector2(720, 359))
	_expect("resume click", game.mode == "play")

	# Exercise the touch HUD through the same settings path a player uses.
	await _click(Vector2(1294, 847))
	await _click(Vector2(720, 426))
	_expect("settings opens before enabling touch controls", game.mode == "settings")
	var touch_before: bool = game.profile.settings.touch
	await _click(Vector2(720, 564))
	_expect("touch controls toggle by click", bool(game.profile.settings.touch) != touch_before)
	await _click(Vector2(720, 737))
	await _click(Vector2(720, 359))
	_expect("returns to play with touch controls enabled", game.mode == "play" and game.profile.settings.touch)
	await _shot("09b_touch_gameplay")
	game.player.dash_cd = 0.0
	await _touch(Vector2(1128, 698))
	_expect("touch DASH button invokes dash", game.player.dash_cd > 0.0)
	game.player.dash_time = 0.0

	game.pending_upgrades = 1
	game.prepare_upgrade()
	await _frames(3)
	_expect("upgrade overlay opens", game.mode == "upgrade" and game.upgrade_choices.size() == 3)
	await _shot("10_upgrade")
	await _joy(JOY_BUTTON_DPAD_RIGHT)
	_expect("gamepad right moves between blessing cards", game.ui.pad_focus == 1)
	await _joy(JOY_BUTTON_A)
	_expect("gamepad A chooses focused blessing", game.mode == "play" and game.pending_upgrades == 0)

	# Elite affixes must be readable both on the enemy and in the combat HUD.
	game.player.position = game.dungeon.rooms[4].center
	game.camera.position = game.player.position
	game.dungeon.active = 4
	game.wave = 2
	var elite = game.spawn_enemy("elite", game.player.position + Vector2(230, 0), 4, 4, "volatile")
	elite.state = "approach"
	elite.timer = 1.0
	game.toast_time = 0.0
	game.banner_time = 0.0
	await _frames(3)
	_expect("elite affix metadata is exposed to HUD", elite.affix_name() == "VOLATILE" and not elite.affix_hint().is_empty())
	await _shot("10b_elite_affix")
	for enemy in game.enemies.duplicate():
		if is_instance_valid(enemy):
			enemy.queue_free()
	game.enemies.clear()
	game.hazards.clear()

	game.player.position = game.dungeon.rooms[9].center
	game.camera.position = game.player.position
	game.dungeon.active = 9
	game.wave = 1
	game.toast_time = 0.0
	game.banner_time = 0.0
	game.spawn_enemy("boss", game.player.position + Vector2(260, 0), 7, 9)
	await _frames(3)
	await _shot("11_boss_hud")

	game.metrics.damage_dealt = 12345.0
	game.metrics.hits_taken = 7
	game.metrics.pickups = 12
	game.metrics.equips = 4
	game.metrics.level_ups = 3
	game.mode = "victory"
	game.dungeon.active = -1
	await _frames(3)
	await _shot("12_victory")
	await _click(Vector2(720, 568))
	_expect("victory relic button click", game.mode == "victory_inventory")
	await _shot("13_victory_inventory")
	await _click(Vector2(1305, 61))
	_expect("victory inventory return click", game.mode == "victory")
	await _click(Vector2(720, 637))
	_expect("victory Ascend starts the next vow", game.mode == "play" and game.ascension == 1 and String(game.ascension_vow().id) == "ember_tide")
	await _frames(4)
	await _shot("13b_ascension_vow")

	# iPad-class 4:3 window: keep click mapping and legibility under a different aspect ratio.
	DisplayServer.window_set_size(Vector2i(1024, 768))
	root.size = Vector2i(1024, 768)
	await _frames(8)
	_expect("4:3 viewport resize takes effect", root.size == Vector2i(1024, 768))
	game.mode = "play"
	game.ui.big_map = false
	game.player.position = game.dungeon.rooms[0].center
	game.camera.position = game.player.position
	await _shot("14_ipad_4x3_touch")
	await _click(Vector2(1294, 88))
	_expect("4:3 scaled minimap remains clickable", game.ui.big_map)
	game.ui.big_map = false

	var summary := "VISUAL_SMOKE shots=%d failures=%d\n" % [shots, failures.size()]
	for failure in failures:
		summary += "FAIL: " + failure + "\n"
	var file := FileAccess.open("res://test-artifacts/visual_summary.txt", FileAccess.WRITE)
	if file:
		file.store_string(summary)
		file.close()
	print(summary.strip_edges())
	game.shutdown(0 if failures.is_empty() else 1)

func _frames(count: int = 2) -> void:
	for _i in range(count):
		await process_frame

func _click(base_position: Vector2) -> void:
	var window_size := Vector2(root.size)
	var scale := minf(window_size.x / BASE.x, window_size.y / BASE.y)
	var offset := (window_size - BASE * scale) * 0.5
	var screen_position := offset + base_position * scale
	var motion := InputEventMouseMotion.new()
	motion.position = screen_position
	motion.global_position = screen_position
	Input.parse_input_event(motion)
	await process_frame
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = screen_position
	down.global_position = screen_position
	Input.parse_input_event(down)
	await process_frame
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = screen_position
	up.global_position = screen_position
	Input.parse_input_event(up)
	await _frames(2)


func _joy(button_index: int) -> void:
	var down := InputEventJoypadButton.new()
	down.device = 0
	down.button_index = button_index
	down.pressed = true
	Input.parse_input_event(down)
	await _frames(2)
	var up := InputEventJoypadButton.new()
	up.device = 0
	up.button_index = button_index
	up.pressed = false
	Input.parse_input_event(up)
	await _frames(2)


func _touch(base_position: Vector2) -> void:
	var window_size := Vector2(root.size)
	var scale := minf(window_size.x / BASE.x, window_size.y / BASE.y)
	var offset := (window_size - BASE * scale) * 0.5
	var screen_position := offset + base_position * scale
	var down := InputEventScreenTouch.new()
	down.index = 0
	down.pressed = true
	down.position = screen_position
	Input.parse_input_event(down)
	await _frames(2)
	var up := InputEventScreenTouch.new()
	up.index = 0
	up.pressed = false
	up.position = screen_position
	Input.parse_input_event(up)
	await _frames(2)

func _shot(label: String) -> void:
	game.ui.queue_redraw()
	await _frames(3)
	var image := root.get_texture().get_image()
	var path := ProjectSettings.globalize_path("res://test-artifacts/ui/%s.png" % label)
	var err := image.save_png(path)
	if err != OK:
		failures.append("screenshot %s could not be saved: %s" % [label, error_string(err)])
	else:
		shots += 1
		print("SHOT ", label, " ", image.get_width(), "x", image.get_height())
		if label in ["04_gameplay", "09b_touch_gameplay", "10b_elite_affix", "11_boss_hud", "13b_ascension_vow", "14_ipad_4x3_touch"]:
			_expect("world visible in " + label, _world_visible(image))

func _world_visible(image: Image) -> bool:
	var ink := Color("0d1722")
	var changed := 0
	var total := 0
	var x0 := int(image.get_width() * 0.24)
	var x1 := int(image.get_width() * 0.76)
	var y0 := int(image.get_height() * 0.28)
	var y1 := int(image.get_height() * 0.68)
	var step_x := maxi(1, int((x1 - x0) / 18.0))
	var step_y := maxi(1, int((y1 - y0) / 12.0))
	for y in range(y0, y1, step_y):
		for x in range(x0, x1, step_x):
			var pixel := image.get_pixel(x, y)
			var diff := absf(pixel.r - ink.r) + absf(pixel.g - ink.g) + absf(pixel.b - ink.b)
			if diff > 0.08:
				changed += 1
			total += 1
	return total > 0 and float(changed) / float(total) > 0.35

func _expect(label: String, condition: bool) -> void:
	if condition:
		print("PASS ", label)
	else:
		failures.append(label)
		printerr("FAIL ", label)
