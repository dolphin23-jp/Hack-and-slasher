extends Node

var game
var checks := 0
var failures: Array[String] = []

func _ready() -> void:
	call_deferred("_run")

func _expect(label: String, condition: bool) -> void:
	checks += 1
	if condition:
		print("QA PASS %02d  %s" % [checks, label])
	else:
		failures.append(label)
		printerr("QA FAIL %02d  %s" % [checks, label])

func _run() -> void:
	game.set_physics_process(false)
	game.profile.run = {}
	_expect("game boots to title", game.mode == "title")
	_expect("enemy database contains the boss", game.enemy_data.has("boss"))
	_expect("Japanese rarity labels are active", ItemDB.RARITIES[3] == "レジェンダリー")
	_expect("Japanese slot labels are active", ItemDB.slot_text("weapon") == "武器" and ItemDB.slot_text("armor") == "防具" and ItemDB.slot_text("accessory") == "装飾品")
	_expect("Japanese fallback font is loaded", game.ui.body.fallbacks.size() > 0 and game.ui.heading.fallbacks.size() > 0)

	game.start_run()
	await get_tree().process_frame
	_expect("begin descent enters play mode", game.mode == "play")
	_expect("dungeon contains ten original and two contract rooms", game.dungeon.rooms.size() == 12)
	_expect("dungeon graph contains a southern alternate route", game.dungeon.connections.size() == 12)
	_expect("threshold starts reclaimed", game.dungeon.cleared == [0])
	_expect("player is instantiated", is_instance_valid(game.player))
	_expect("starter gift and chest are present", game.drops.size() >= 2)

	game.player.controlled_by_test = true
	var before_move: Vector2 = game.player.position
	game.player.test_move = Vector2.RIGHT
	game.player.tick(0.20)
	game.player.test_move = Vector2.ZERO
	_expect("test-controlled normal movement advances the player", game.player.position.x > before_move.x)

	var enemy_count: int = game.enemies.size()
	var enemy = game.spawn_enemy("hollow", game.player.position + Vector2(88, 0), 1, 0)
	enemy.state = "approach"
	enemy.timer = 1.0
	game.player.facing = Vector2.RIGHT
	var enemy_hp: float = float(enemy.hp)
	_expect("enemy spawn enters the encounter list", game.enemies.size() == enemy_count + 1)
	_expect("normal attack can start", game.player.attack())
	_expect("attack cooldown rejects immediate repeat", not game.player.attack())
	_expect("normal attack damages a nearby enemy", enemy.hp < enemy_hp)
	_expect("damage metric records combat", game.metrics.damage_dealt > 0.0)

	var frenzied = game.spawn_enemy("elite", game.player.position + Vector2(150, 40), 2, 3, "frenzied")
	_expect("forced elite affix selects Frenzied", frenzied.affix == "frenzied" and frenzied.speed > float(frenzied.spec.speed))
	frenzied.start_windup()
	_expect("Frenzied elite shortens its attack windup", frenzied.windup < float(frenzied.spec.windup))

	var bulwark = game.spawn_enemy("elite", game.player.position + Vector2(170, -40), 2, 4, "bulwark")
	var normal_elite_hp: float = float(bulwark.spec.hp) * 1.25
	_expect("Bulwark elite gains extra maximum life", bulwark.affix == "bulwark" and bulwark.max_hp > normal_elite_hp)

	var volatile = game.spawn_enemy("elite", game.player.position + Vector2(190, 0), 2, 6, "volatile")
	volatile.state = "approach"
	var hazards_before: int = game.hazards.size()
	volatile.take_damage(volatile.max_hp + 1.0, Vector2.ZERO)
	_expect("Volatile elite leaves a telegraphed death blast", game.hazards.size() == hazards_before + 1)

	for elite in [frenzied, bulwark]:
		game.enemies.erase(elite)
		if is_instance_valid(elite):
			elite.queue_free()
	game.hazards.clear()

	game.ascension = 1
	_expect("Ascension I activates Ember Tide", String(game.ascension_vow().id) == "ember_tide")
	_expect("Ember Tide shortens sanctuary hazard intervals", game.room_modifier_interval(10.0) < 8.0)

	game.ascension = 2
	var veil_elite = game.spawn_enemy("elite", game.player.position + Vector2(210, 0), 2, 4, "frenzied")
	var veil_base_hp: float = float(veil_elite.spec.hp) * (1.0 + 0.25 + game.ascension * 0.45)
	_expect("Thickened Veil strengthens Oathless Knights", String(game.ascension_vow().id) == "thickened_veil" and veil_elite.max_hp > veil_base_hp * 1.27)
	game.enemies.erase(veil_elite)
	if is_instance_valid(veil_elite):
		veil_elite.queue_free()

	game.ascension = 3
	_expect("Hollow Choir adds one foe to non-boss waves", String(game.ascension_vow().id) == "hollow_choir" and game.ascension_wave_bonus() == 1)
	game.ascension = 4
	_expect("Ascension Vows rotate every three tiers", String(game.ascension_vow().id) == "ember_tide")
	game.save_run()
	_expect("Chronicle records the highest saved Ascension", int(game.profile.records.best_ascension) >= 4)
	game.ascension = 0

	game.player.attack_cd = 0.0
	game.player.dash_cd = 0.0
	game.player.dash_time = 0.0
	_expect("dash can start", game.player.dash())
	_expect("dash cooldown rejects immediate repeat", not game.player.dash())
	game.player.dash_time = 0.0
	game.player.dash_cd = 0.0

	game.player.cooldowns = [0.0, 0.0, 0.0]
	_expect("Judgement can cast", game.player.cast(0))
	_expect("skill cooldown is applied", game.player.cooldowns[0] > 0.0)
	_expect("skill cooldown rejects immediate recast", not game.player.cast(0))
	game.player.dash_time = 0.0
	var projectiles_before: int = game.projectiles.size()
	_expect("Spirit Lance can cast", game.player.cast(2))
	_expect("Spirit Lance creates a projectile", game.projectiles.size() > projectiles_before)

	game.player.hp = game.player.stats.hp * 0.35
	game.player.potions = 3
	var hp_before: float = float(game.player.hp)
	_expect("Mend consumes a flask when injured", game.player.drink())
	_expect("Mend restores life", game.player.hp > hp_before)
	_expect("Mend decrements flask count", game.player.potions == 2)

	var baseline_gear_score: float = game.player.build_score()
	_expect("equipment build score is positive", baseline_gear_score > 0.0)
	var obvious_upgrade: Dictionary = game.player.equipment.weapon.duplicate(true)
	obvious_upgrade.id = "qa-upgrade"
	obvious_upgrade.name = "QA Superior Oathblade"
	obvious_upgrade.base = {"attack": 120.0}
	obvious_upgrade.affixes = {}
	_expect("loot comparison identifies a clear upgrade", game.player.item_upgrade_ratio(obvious_upgrade) > 0.25)
	var obvious_weaker: Dictionary = game.player.equipment.weapon.duplicate(true)
	obvious_weaker.id = "qa-weaker"
	obvious_weaker.name = "QA Blunted Oathblade"
	obvious_weaker.base = {"attack": 0.0}
	obvious_weaker.affixes = {}
	_expect("loot comparison identifies a weaker replacement", game.player.item_upgrade_ratio(obvious_weaker) < -0.02)

	var saved_inventory: Array = game.player.inventory.duplicate(true)
	var sort_common := ItemDB.generate(game.rng, 8, 0)
	var sort_rare_low := ItemDB.generate(game.rng, 2, 2)
	var sort_rare_high := ItemDB.generate(game.rng, 6, 2)
	var sort_legend := ItemDB.generate(game.rng, 1, 3, 0)
	game.player.inventory = [sort_common, sort_rare_low, sort_legend, sort_rare_high]
	game.sort_inventory()
	_expect("pack sort puts higher rarity first", int(game.player.inventory[0].rarity) == 3 and int(game.player.inventory[-1].rarity) == 0)
	_expect("pack sort orders equal rarity by tier", int(game.player.inventory[1].rarity) == 2 and int(game.player.inventory[1].tier) >= int(game.player.inventory[2].tier))
	game.player.inventory = saved_inventory

	var item := ItemDB.generate(game.rng, 2, 2)
	var drop_metric := int(game.metrics.drops)
	var drop = game.spawn_drop(game.player.position + Vector2(30, 0), item)
	_expect("spawning equipment records a drop", int(game.metrics.drops) == drop_metric + 1)
	var inventory_before: int = game.player.inventory.size()
	var pickup_metric := int(game.metrics.pickups)
	_expect("equipment drop can be collected", game.collect(drop))
	_expect("collecting adds the item to the pack", game.player.inventory.size() == inventory_before + 1)
	_expect("pickup metric records collection", int(game.metrics.pickups) == pickup_metric + 1)

	while game.player.inventory.size() < 40:
		game.player.inventory.append(ItemDB.generate(game.rng, 2, 1))
	var overflow = game.spawn_drop(game.player.position, ItemDB.generate(game.rng, 2, 1))
	_expect("full pack rejects overflow loot", not game.collect(overflow))

	var equip_index := 0
	var equip_item: Dictionary = game.player.inventory[equip_index]
	var equip_slot: String = equip_item.slot
	var old_equipped_id: String = game.player.equipment[equip_slot].id
	var equip_metric := int(game.metrics.equips)
	_expect("inventory item can be equipped", game.player.equip(equip_index))
	_expect("equipment swap changes the active slot", game.player.equipment[equip_slot].id != old_equipped_id)
	_expect("equip metric records the swap", int(game.metrics.equips) == equip_metric + 1)

	var pack_before_salvage: int = game.player.inventory.size()
	game.salvage(0)
	_expect("salvage removes one packed item", game.player.inventory.size() == pack_before_salvage - 1)

	var level_before: int = int(game.player.level)
	game.player.gain_xp(game.player.xp_required() + 5)
	_expect("enough XP raises the player level", game.player.level > level_before)
	_expect("level-up queues a blessing choice", game.pending_upgrades > 0)
	var pending_before: int = int(game.pending_upgrades)
	game.prepare_upgrade()
	_expect("growth screen presents three blessings", game.mode == "upgrade" and game.upgrade_choices.size() == 3)
	game.choose_upgrade(0)
	_expect("choosing a blessing returns to play and consumes one choice", game.mode == "play" and game.pending_upgrades == pending_before - 1)

	var saved_damage: float = float(game.metrics.damage_dealt)
	game.save_run()
	if game.profile.run.is_empty() or not game.profile.valid_run(game.profile.run):
		_print_save_diagnostics()
	var saved_level: int = int(game.player.level)
	var saved_weapon_id: String = game.player.equipment.weapon.id
	_expect("current run serializes as a valid save", not game.profile.run.is_empty() and game.profile.valid_run(game.profile.run))
	_expect("current run save includes summary metrics", game.profile.run.has("metrics") and is_equal_approx(float(game.profile.run.metrics.damage_dealt), saved_damage))

	var reloaded := ProfileStore.new()
	reloaded.path = game.profile.path
	reloaded.read_save()
	_expect("save file reloads and validates from disk", reloaded.valid_run(reloaded.run))

	game.start_run(true)
	_expect("resume restores level and equipment", game.player.level == saved_level and game.player.equipment.weapon.id == saved_weapon_id)
	_expect("resume restores run summary metrics", is_equal_approx(float(game.metrics.damage_dealt), saved_damage))

	for e in game.enemies.duplicate():
		if is_instance_valid(e):
			e.queue_free()
	game.enemies.clear()
	game.mode = "play"
	game.player.position = game.dungeon.rooms[9].center
	game.camera.position = game.player.position
	game.dungeon.active = 9
	var wins_before := int(game.profile.records.wins)
	var boss = game.spawn_enemy("boss", game.player.position + Vector2(220, 0), 7, 9)
	boss.dead = true
	game.enemy_died(boss)
	var boss_rewards := 0
	for d in game.drops:
		if d.kind == "item" and d.item.get("boss_reward", false):
			boss_rewards += 1
	_expect("boss defeat schedules victory and creates four legendary rewards", game.victory_pending and boss_rewards == 4)
	game.finish_run()
	_expect("finishing the boss encounter enters victory mode", game.mode == "victory")
	var victory_pack_size: int = game.player.inventory.size()
	var victory_weapon_id: String = game.player.equipment.weapon.id
	_expect("victory persists a resumable checkpoint and increments wins", game.profile.valid_run(game.profile.run) and bool(game.profile.run.get("victory_ready", false)) and int(game.profile.records.wins) == wins_before + 1)

	var victory_reload := ProfileStore.new()
	victory_reload.path = game.profile.path
	victory_reload.read_save()
	_expect("victory checkpoint reloads from disk", victory_reload.valid_run(victory_reload.run) and bool(victory_reload.run.get("victory_ready", false)))

	# Victory inventory edits used to bypass save_run because victory modes were
	# excluded from normal checkpoints. Exercise both mutation paths so the
	# post-boss build remains restart-safe after inspection.
	game.mode = "victory_inventory"
	var victory_edit_item: Dictionary = game.player.inventory[0].duplicate(true)
	var victory_edit_slot: String = String(victory_edit_item.slot)
	game.player.equip(0)
	var victory_equip_reload := ProfileStore.new()
	victory_equip_reload.path = game.profile.path
	victory_equip_reload.read_save()
	_expect("victory inventory equipment edits persist immediately", victory_equip_reload.valid_run(victory_equip_reload.run) and bool(victory_equip_reload.run.get("victory_ready", false)) and String(victory_equip_reload.run.equipment[victory_edit_slot].id) == String(victory_edit_item.id))
	var victory_pack_before_salvage: int = game.player.inventory.size()
	game.salvage(0)
	var victory_salvage_reload := ProfileStore.new()
	victory_salvage_reload.path = game.profile.path
	victory_salvage_reload.read_save()
	_expect("victory inventory salvage persists immediately", victory_salvage_reload.valid_run(victory_salvage_reload.run) and bool(victory_salvage_reload.run.get("victory_ready", false)) and victory_salvage_reload.run.inventory.size() == victory_pack_before_salvage - 1)
	game.mode = "victory"
	victory_pack_size = game.player.inventory.size()
	victory_weapon_id = game.player.equipment.weapon.id

	game.return_to_title()
	game.start_run(true)
	_expect("continue restores the victory screen with rewards intact", game.mode == "victory" and game.player.inventory.size() == victory_pack_size and game.player.equipment.weapon.id == victory_weapon_id)

	if checks != 67:
		failures.append("expected 67 checks, executed %d" % checks)
		printerr("QA FAIL check count: ", checks)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-artifacts"))
	var summary := "QA checks=%d failures=%d\n" % [checks, failures.size()]
	for failure in failures:
		summary += "FAIL: " + failure + "\n"
	var file := FileAccess.open("res://test-artifacts/qa_summary.txt", FileAccess.WRITE)
	if file:
		file.store_string(summary)
		file.close()
	print(summary.strip_edges())
	game.shutdown(0 if failures.is_empty() else 1)


func _print_save_diagnostics() -> void:
	print("QA SAVE DEBUG mode=", game.mode, " dead=", game.player.dead, " pack=", game.player.inventory.size(), " hp=", game.player.hp, " level=", game.player.level, " xp=", game.player.xp)
	if game.profile.run.is_empty():
		print("QA SAVE DEBUG run is empty")
		return
	var run: Dictionary = game.profile.run
	print("QA SAVE DEBUG cleared=", run.get("cleared"), " visited=", run.get("visited"), " drops=", run.get("drops", []).size(), " position=", run.get("position"))
	for slot in ItemDB.SLOTS:
		var equipped = run.equipment.get(slot)
		if not ItemDB.valid(equipped):
			print("QA SAVE DEBUG invalid equipment ", slot, ": ", equipped)
	for i in range(run.inventory.size()):
		if not ItemDB.valid(run.inventory[i]):
			print("QA SAVE DEBUG invalid inventory ", i, ": ", run.inventory[i])
	for i in range(run.get("drops", []).size()):
		var drop = run.drops[i]
		if drop.get("kind") == "item" and not ItemDB.valid(drop.get("item")):
			print("QA SAVE DEBUG invalid item drop ", i, ": ", drop)
		elif drop.get("kind") == "chest":
			var payload = drop.get("item")
			if not payload is Dictionary or not (payload.get("tier") is int or payload.get("tier") is float) or not payload.get("gilded") is bool:
				print("QA SAVE DEBUG invalid chest ", i, ": ", drop)
