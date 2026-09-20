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

	game.start_run()
	await get_tree().process_frame
	_expect("begin descent enters play mode", game.mode == "play")
	_expect("dungeon contains ten rooms", game.dungeon.rooms.size() == 10)
	_expect("dungeon graph contains nine passages", game.dungeon.connections.size() == 9)
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

	game.save_run()
	var saved_level: int = int(game.player.level)
	var saved_weapon_id: String = game.player.equipment.weapon.id
	_expect("current run serializes as a valid save", not game.profile.run.is_empty() and game.profile.valid_run(game.profile.run))

	var reloaded := ProfileStore.new()
	reloaded.path = game.profile.path
	reloaded.read_save()
	_expect("save file reloads and validates from disk", reloaded.valid_run(reloaded.run))

	game.start_run(true)
	_expect("resume restores level and equipment", game.player.level == saved_level and game.player.equipment.weapon.id == saved_weapon_id)

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
	_expect("victory clears the resumable run and increments wins", game.profile.run.is_empty() and int(game.profile.records.wins) == wins_before + 1)

	if checks != 43:
		failures.append("expected 43 checks, executed %d" % checks)
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
