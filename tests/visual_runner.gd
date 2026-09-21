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
	game.profile.oaths = OathBoard.empty()
	game.profile.oaths.points = 20
	game.profile.build_presets = []
	game.profile.settings.touch = false
	game.profile.write_save()
	await _frames(5)

	# Every UI run starts from a deterministic profile. Previous test processes
	# share user:// on the runner and may otherwise leave CONTINUE or touch mode on.
	game.profile.run = {}
	game.profile.settings = {"music": .65, "sfx": .8, "shake": .7, "auto_aim": false, "touch": false, "touch_size": .5, "touch_inset": .5, "hitstop": true}
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
	_expect("begin descent opens build confirmation", game.mode == "build_confirm")
	await _shot("03b_build_confirm")
	await _click(Vector2(390, 678))
	_expect("build confirmation opens editable oath board", game.mode == "oaths" and game.ui.reliquary.back == "build_confirm")
	await _click(Vector2(745, 235))
	_expect("pre-run oath node can be purchased", "dance_tempo" in game.profile.oaths.nodes)
	await _click(Vector2(1095, 51))
	_expect("build manager tab opens before departure", game.ui.reliquary.oath_section == "build")
	await _shot("03c_build_manager")
	await _click(Vector2(205, 488))
	_expect("current build can be saved as a preset", game.profile.build_presets.size() == 1)
	await _shot("03d_build_preset_saved")
	await _click(Vector2(1280, 51))
	_expect("oath board returns to build confirmation", game.mode == "build_confirm")
	await _click(Vector2(720, 678))
	_expect("confirmed build begins descent", game.mode == "play")
	await _frames(4)
	await _shot("04_gameplay")

	await _joy_axis(JOY_AXIS_LEFT_X, 0.8)
	_expect("gamepad stick switches HUD prompt mode", game.ui.pad_active)
	await _shot("04c_gamepad_hud")
	await _joy_axis(JOY_AXIS_LEFT_X, 0.0)

	var full_hp: float = game.player.hp
	game.player.hp = game.player.stats.hp * 0.22
	await _frames(3)
	_expect("critical-health state is below the HUD warning threshold", game.player.hp / game.player.stats.hp < 0.30)
	await _shot("04a_critical_health")
	game.player.hp = full_hp
	await _frames(2)

	# Nearby loot should communicate whether it is likely to improve the current build.
	var preview_item: Dictionary = game.player.equipment.weapon.duplicate(true)
	preview_item.id = "visual-upgrade"
	preview_item.name = "Hallowed Trial Edge"
	preview_item.rarity = 2
	preview_item.tier = 4
	preview_item.base = {"attack": 90.0}
	preview_item.affixes = {}
	var preview_drop = game.spawn_drop(game.player.position + Vector2(155, 35), preview_item)
	await _frames(3)
	_expect("nearby loot exposes a positive upgrade score", game.player.item_upgrade_ratio(preview_item) > 0.10)
	await _shot("04b_loot_upgrade_hint")
	preview_drop.take()
	await _frames(2)

	await _click(Vector2(1294, 88))
	_expect("minimap opens large map", game.ui.big_map)
	await _shot("05_map")
	await _click(Vector2(1294, 88))
	_expect("minimap closes large map", not game.ui.big_map)

	var sample_common := ItemDB.generate(game.rng, 7, 0)
	var sample_rare := ItemDB.generate(game.rng, 4, 2)
	var sample := ItemDB.generate(game.rng, 3, 3, 0)
	game.player.inventory.append_array([sample_common, sample_rare, sample])
	game.save_run()
	await _click(Vector2(1094, 847))
	_expect("reliquary click", game.mode == "inventory")
	await _frames(3)
	await _shot("06_inventory")
	await _click(Vector2(280, 294))
	_expect("Sort Pack puts legendary before rare and common", int(game.player.inventory[0].rarity) == 3 and int(game.player.inventory[1].rarity) == 2 and int(game.player.inventory[2].rarity) == 0)
	await _shot("06b_inventory_sorted")
	await _click(Vector2(71, 356))
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
	_expect("elite affix metadata is exposed to HUD", elite.affix_name() == "爆裂" and not elite.affix_hint().is_empty())
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
	var visual_boss = game.spawn_enemy("boss", game.player.position + Vector2(260, 0), 7, 9)
	await _frames(3)
	await _shot("11_boss_hud")

	game.metrics.damage_dealt = 12345.0
	game.metrics.hits_taken = 7
	game.metrics.pickups = 12
	game.metrics.equips = 4
	game.metrics.level_ups = 3
	visual_boss.dead = true
	game.enemy_died(visual_boss)
	game.finish_run()
	await _frames(3)
	await _shot("12_victory")
	await _click(Vector2(720, 568))
	_expect("victory relic button click", game.mode == "victory_inventory")
	await _shot("13_victory_inventory")
	await _click(Vector2(1305, 61))
	_expect("victory inventory return click", game.mode == "victory")
	await _click(Vector2(720, 744))
	_expect("victory can return to title with checkpoint intact", game.mode == "title" and bool(game.profile.run.get("victory_ready", false)))
	await _shot("13a_victory_title")
	await _click(Vector2(281, 577))
	_expect("title victory checkpoint resumes the victory screen", game.mode == "victory")
	await _shot("13b_victory_resume")
	await _click(Vector2(720, 637))
	_expect("restored victory Ascend starts the next vow", game.mode == "play" and game.ascension == 1 and String(game.ascension_vow().id) == "ember_tide")
	await _frames(4)
	await _shot("13c_ascension_vow")

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

	# Expansion screens and multi-touch input at iPad aspect ratio.
	game.ui.settings_return = "play"
	game.mode = "journal"
	await _shot("15_journal_legends_ipad")
	await _click(Vector2(495, 135))
	_expect("bestiary tab opens by click", game.ui.journal_tab == "enemies")
	await _shot("16_bestiary_ipad")
	await _click(Vector2(785, 135))
	await _shot("17_unlocks_ipad")
	await _click(Vector2(1200, 60))
	_expect("journal returns to combat", game.mode == "play")
	game.event_room = 10
	game.mode = "event"
	await _shot("18_blood_contract_ipad")
	await _click(Vector2(1070, 570))
	_expect("contract decline still opens alternate route combat", game.mode == "play" and game.event_choices.get("10") == "leave")
	game.dungeon.active = -1
	game.event_room = 11
	game.mode = "event"
	await _shot("19_wager_ipad")
	game.mode = "settings"
	await _click(Vector2(1190, 250))
	await _shot("20_touch_settings_ipad")
	game.mode = "play"
	game.player.dash_time = 0
	game.player.attack_cd = 0
	await _frames(3)
	var down_attack := InputEventScreenTouch.new()
	down_attack.index = 2
	down_attack.pressed = true
	down_attack.position = _touch_position(Vector2(1290, 626))
	Input.parse_input_event(down_attack)
	await _frames(2)
	_expect("touch attack holds across frames", game.player.touch_attack)
	var down_stick := InputEventScreenTouch.new()
	down_stick.index = 3
	down_stick.pressed = true
	down_stick.position = _touch_position(Vector2(160, 640))
	Input.parse_input_event(down_stick)
	var drag := InputEventScreenDrag.new()
	drag.index = 3
	drag.position = _touch_position(Vector2(220, 640))
	Input.parse_input_event(drag)
	await _frames(2)
	_expect("stick and held attack coexist", game.player.touch_move.x > .5 and game.player.touch_attack)
	game.player.cooldowns[0]=0;game.player.dash_time=0;game.player.dash_cd=0
	var down_skill:=InputEventScreenTouch.new();down_skill.index=4;down_skill.pressed=true;down_skill.position=_touch_position(Vector2(406,809))
	Input.parse_input_event(down_skill);await _frames(1)
	_expect("third touch casts skill while movement and attack stay held",game.player.cooldowns[0]>0 and game.player.touch_attack and game.player.touch_move.x>.5)
	var down_dash:=InputEventScreenTouch.new();down_dash.index=5;down_dash.pressed=true;down_dash.position=_touch_position(Vector2(1128,698))
	Input.parse_input_event(down_dash);await _frames(1)
	_expect("fourth touch dodges without releasing held movement or attack",game.player.dash_cd>0 and game.player.touch_attack and game.player.touch_move.x>.5)
	await _shot("21_multitouch_ipad")
	game.mode = "pause"
	await _frames(2)
	_expect("opening a modal clears all held touch input", not game.player.touch_attack and game.player.touch_move == Vector2.ZERO)
	game.mode = "play"
	game.player.position = game.dungeon.rooms[9].center
	game.camera.position = game.player.position
	game.dungeon.active = 9
	var awakened = game.spawn_enemy("boss", game.player.position + Vector2(260, 0), 7, 9)
	awakened.phase = 2
	awakened.state = "windup"
	awakened.pattern = 2
	awakened.start_windup()
	await _shot("22_awakened_boss_ipad")
	awakened.state = "recover"
	awakened.timer = 2
	await _shot("23_boss_opening_ipad")
	game.dungeon.active = -1
	game.mode = "inventory"
	game.player.inventory.append(ItemDB.generate(game.rng, 5, 3, 4))
	game.ui.selected = game.player.inventory.size()-1
	await _shot("24_synergy_comparison_ipad")

	game.player.materials=9999
	game.player.equipment.weapon.tier=5
	game.player.equipment.weapon.enhance=10
	game.player.equipment.weapon.affixes={"crit":.08,"haste":.1}
	await _click(Vector2(1160,48))
	await _shot("25_forge_ipad")
	game.ui.reliquary.inheritance="crit"
	await _click(Vector2(1080,574))
	_expect("forge evolve click changes real grade",game.player.equipment.weapon.grade==2)
	await _shot("26_evolution_ipad")
	game.player.equipment.weapon.tier=2
	game.player.equipment.weapon.fusion=10
	await _click(Vector2(1100,508))
	_expect("forge Tier button consumes material and unlocks",game.player.equipment.weapon.tier==3)
	await _shot("27_tier_ipad")
	await _click(Vector2(1010,48))
	var order_before=game.player.equipment.weapon.id
	await _click(Vector2(410,130))
	_expect("reorder button changes actual chain",game.player.equipment.weapon2.id==order_before)
	await _shot("28_chain_reordered_ipad")
	await _click(Vector2(140,723))
	_expect("oath board opens from inventory",game.mode=="oaths")
	await _shot("29_oath_board_ipad")
	await _click(Vector2(1095,51))
	_expect("run build summary opens on iPad",game.ui.reliquary.oath_section=="build")
	await _shot("29a_build_summary_ipad")
	await _click(Vector2(950,51))
	_expect("oath tree returns from build summary",game.ui.reliquary.oath_section=="tree")
	await _click(Vector2(1260,60))
	game.mode="play"
	var myth=ItemDB.generate(game.rng,8,4,0)
	game.spawn_drop(game.player.position+Vector2(110,70),myth)
	await _shot("30_mythic_drop_ipad")
	game.mode="inventory";game.player.inventory.append(myth);game.ui.selected=game.player.inventory.size()-1
	await _shot("31_mythic_detail_ipad")
	await _click(Vector2(115,294))
	_expect("inventory filter cycles on iPad",game.ui.reliquary.filter_mode=="weapon")
	await _shot("32_inventory_filter_ipad")
	await _click(Vector2(1270,311))
	_expect("large item detail opens on iPad",game.ui.reliquary.focus_detail)
	await _shot("33_inventory_detail_focus_ipad")
	var vault_before=game.profile.vault.size()
	await _click(Vector2(1035,794))
	_expect("focused detail can move an item to the vault",game.profile.vault.size()==vault_before+1)
	await _click(Vector2(860,48))
	_expect("vault tab opens after storing an item",game.ui.reliquary.tab=="vault")
	await _shot("34_vault_ipad")

	# Skill 2.0 controls on the same iPad touch layout used above.
	game.mode = "play"
	game.set_physics_process(false)
	game.player.skill_actions.clear()
	game.player.cooldowns = [0.0, 0.0, 0.0]
	game.player.finisher_charge = WeaponActionResolver.FINISHER_COST
	game.player.dash_time = 0
	game.player.dead = false
	for j in range(3):game.player.equipment[Loadout.WEAPONS[j]].weapon_type = ["scythe", "staff", "spear"][j]
	game.player.combo = 1
	await _shot("35_skill_ready_ipad")
	await _click(Vector2(523, 809))
	_expect("E button starts loadout chain", game.player.cooldowns[1]>0 and game.player.skill_actions.size()==2)
	WeaponActionResolver.tick(game.player, .4)
	await _shot("36_chain_cast_ipad")
	await _click(Vector2(640, 809))
	_expect("R button consumes ready finisher", game.player.finisher_charge==0 and game.player.cooldowns[2]>0)
	await _shot("37_finisher_ipad")
	game.mode = "inventory"
	game.ui.reliquary.tab = "equipment"
	game.ui.reliquary.focus_detail = false
	await _shot("38_skill_recipes_ipad")

	# Explicit fusion donor review and rule editor on iPad-sized controls.
	var donor = game.player.equipment.weapon.duplicate(true)
	donor.id = "visual-fusion-donor"
	donor.locked = false
	donor.favorite = false
	var valuable = donor.duplicate(true)
	valuable.id = "visual-keep-donor"
	valuable.name = "保持する装備"
	game.player.inventory = [donor, valuable]
	game.ui.reliquary.forge_slot = "weapon"
	var fusion_before = game.player.equipment.weapon.fusion
	await _click(Vector2(1180, 48))
	await _click(Vector2(1100, 442))
	_expect("fusion opens donor selector without consuming", game.ui.reliquary.forge_screen.opened and game.player.inventory.size()==2)
	await _shot("39_fusion_candidates_ipad")
	await _click(Vector2(330, 188))
	await _click(Vector2(1050, 780))
	_expect("fusion preview preserves inventory", not game.ui.reliquary.forge_screen.pending.is_empty() and game.player.inventory.size()==2)
	await _shot("40_fusion_confirm_ipad")
	await _click(Vector2(930, 815))
	_expect("fusion consumes only reviewed donor", game.player.inventory.size()==1 and game.player.inventory[0].id==valuable.id and game.player.equipment.weapon.fusion>fusion_before)
	await _click(Vector2(1020, 48))
	await _click(Vector2(140, 678))
	_expect("auto salvage opens rule editor", game.ui.reliquary.salvage_screen.opened)
	await _shot("41_salvage_rules_ipad")
	var enabled_before = game.profile.settings.get("auto_salvage_rare", false)
	await _click(Vector2(340, 195))
	_expect("rule editor toggle changes enabled state", game.profile.settings.auto_salvage_rare!=enabled_before)
	await _click(Vector2(1260, 55))
	game.player.inventory[0].junk = true
	await _click(Vector2(485, 295))
	_expect("bulk junk opens confirmation without consuming", game.ui.reliquary.salvage_screen.bulk and game.player.inventory.size()==1)
	await _shot("42_junk_confirm_ipad")
	await _click(Vector2(1000, 810))
	_expect("bulk confirm removes reviewed junk", game.player.inventory.is_empty())

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


func _joy_axis(axis: int, value: float) -> void:
	var motion := InputEventJoypadMotion.new()
	motion.device = 0
	motion.axis = axis
	motion.axis_value = value
	Input.parse_input_event(motion)
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
		if label in ["04_gameplay", "04a_critical_health", "04c_gamepad_hud", "09b_touch_gameplay", "10b_elite_affix", "11_boss_hud", "13c_ascension_vow", "14_ipad_4x3_touch"]:
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

func _touch_position(p:Vector2)->Vector2:
	var window_size=Vector2(root.size)
	var scale=minf(window_size.x/BASE.x,window_size.y/BASE.y)
	return (window_size-BASE*scale)*.5+p*scale
