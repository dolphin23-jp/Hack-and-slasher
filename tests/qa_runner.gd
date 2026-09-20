extends Node

var game
var passed := 0
var failures: Array[String] = []

func _ready() -> void:
	call_deferred("_run")

func _check(label: String, condition: bool) -> void:
	if condition:
		passed += 1
		print("PASS %02d %s" % [passed, label])
	else:
		failures.append(label)
		printerr("FAIL ", label)

func _run() -> void:
	game.set_physics_process(false)
	game.profile.run = {}
	game.profile.records = {"runs":0,"wins":0,"best_level":1,"total_kills":0}

	_check("enemy roster loaded", game.enemy_data.size() >= 6)
	_check("test profile path selected", game.profile.path.ends_with("ashen_vow_test.json"))

	var initial := ItemDB.initial_items()
	_check("three starter slots exist", initial.size() == 3 and initial.has("weapon") and initial.has("armor") and initial.has("accessory"))
	var starters_valid := true
	for slot in ItemDB.SLOTS:
		starters_valid = starters_valid and ItemDB.valid(initial[slot])
	_check("starter items validate", starters_valid)

	var sample_rng := RandomNumberGenerator.new()
	sample_rng.seed = 101
	var rare := ItemDB.generate(sample_rng, 3, 2)
	_check("generated rare validates", ItemDB.valid(rare) and int(rare.rarity) == 2)
	var legendary := ItemDB.generate(sample_rng, 3, 3, 0)
	_check("legendary carries effect", ItemDB.valid(legendary) and int(legendary.rarity) == 3 and not legendary.effect.is_empty())

	game.start_run()
	_check("run enters play mode", game.mode == "play")
	_check("dungeon has ten rooms", game.dungeon.rooms.size() == 10)
	_check("dungeon has nine links", game.dungeon.connections.size() == 9)
	_check("threshold starts cleared", game.dungeon.cleared == [0])
	_check("player starts in threshold", game.dungeon.room_at(game.player.position) == 0)
	_check("player starts at full health", is_equal_approx(game.player.hp, game.player.stats.hp))
	var has_item_drop := false
	var has_chest := false
	for d in game.drops:
		has_item_drop = has_item_drop or d.kind == "item"
		has_chest = has_chest or d.kind == "chest"
	_check("starter gift and chest spawn", has_item_drop and has_chest)

	game.player.attack_cd = 0.0
	game.player.dash_time = 0.0
	var first_attack := game.player.attack()
	_check("basic attack starts", first_attack)
	_check("attack cooldown blocks spam", not game.player.attack())
	game.player.attack_cd = 0.0
	var combo_before: int = game.player.combo
	game.player.attack()
	_check("combo advances", game.player.combo != combo_before)

	game.player.dash_cd = 0.0
	game.player.dash_time = 0.0
	game.player.last_move = Vector2.RIGHT
	_check("dash starts", game.player.dash())
	_check("dash grants invulnerability", game.player.invulnerable > 0.0)

	game.player.dash_time = 0.0
	game.player.cooldowns[0] = 0.0
	_check("judgement starts cooldown", game.player.cast(0) and game.player.cooldowns[0] > 0.0)
	game.player.cooldowns[1] = 0.0
	_check("nova starts cooldown", game.player.cast(1) and game.player.cooldowns[1] > 0.0)
	game.player.cooldowns[2] = 0.0
	var projectile_before: int = game.projectiles.size()
	_check("spirit lance creates projectile", game.player.cast(2) and game.projectiles.size() > projectile_before)

	game.player.invulnerable = 0.0
	game.player.hp = game.player.stats.hp
	var hp_before: float = game.player.hp
	_check("damage applies", game.player.take_damage(20.0) and game.player.hp < hp_before)
	var hp_after_hit: float = game.player.hp
	_check("hit invulnerability blocks repeat", not game.player.take_damage(20.0) and is_equal_approx(game.player.hp, hp_after_hit))

	game.player.invulnerable = 0.0
	game.player.hp = game.player.stats.hp * 0.35
	game.player.potions = 3
	var heal_before: float = game.player.hp
	_check("mend heals", game.player.drink() and game.player.hp > heal_before)
	_check("mend consumes flask", game.player.potions == 2)

	game.player.level = 1
	game.player.xp = 0
	game.player.pending_upgrades = 0 if "pending_upgrades" in game.player else 0
	game.pending_upgrades = 0
	var xp_needed := game.player.xp_required()
	game.player.gain_xp(xp_needed)
	_check("experience raises level", game.player.level == 2)
	_check("level queues upgrade", game.pending_upgrades == 1)

	game.prepare_upgrade()
	_check("upgrade offers three choices", game.mode == "upgrade" and game.upgrade_choices.size() == 3)
	var upgrade_key: String = game.upgrade_choices[0].key
	game.choose_upgrade(0)
	_check("upgrade selection returns to play", game.mode == "play" and game.pending_upgrades == 0)
	_check("upgrade persists on player", game.player.upgrades.has(upgrade_key))

	var test_item := ItemDB.generate(game.rng, 3, 3, 1)
	game.player.inventory.append(test_item)
	var equip_index := game.player.inventory.size() - 1
	var equip_slot: String = test_item.slot
	var old_equipped_id: String = game.player.equipment[equip_slot].id
	_check("equip swaps selected item in", game.player.equip(equip_index) and game.player.equipment[equip_slot].id == test_item.id)
	_check("old gear returns to inventory", game.player.inventory[equip_index].id == old_equipped_id)

	game.player.hp = game.player.stats.hp * 0.5
	var salvage_hp_before: float = game.player.hp
	var inventory_before: int = game.player.inventory.size()
	game.salvage(equip_index)
	_check("salvage removes inventory item", game.player.inventory.size() == inventory_before - 1)
	_check("salvage restores some life", game.player.hp > salvage_hp_before)

	var drop_before: int = game.drops.size()
	game.spawn_chest(game.player.position, 2, false)
	game.interact()
	var item_drops_after := 0
	for d in game.drops:
		if d.kind == "item":
			item_drops_after += 1
	_check("nearby chest opens into loot", game.drops.size() >= drop_before + 3 and item_drops_after >= 3)

	game.mode = "play"
	game.save_run()
	_check("save run is created", not game.profile.run.is_empty())
	_check("saved run validates", game.profile.valid_run(game.profile.run))
	var saved_level: int = game.player.level
	var saved_weapon_id: String = game.player.equipment.weapon.id
	game.start_run(true)
	_check("resume restores level", game.player.level == saved_level)
	_check("resume restores equipment", game.player.equipment.weapon.id == saved_weapon_id)

	game.player.position = game.dungeon.rooms[9].center
	game.camera.position = game.player.position
	game.dungeon.active = 9
	var boss = game.spawn_enemy("boss", game.player.position + Vector2(160, 0), 7, 9)
	boss.state = "approach"
	boss.take_damage(boss.hp + 1.0, Vector2.ZERO)
	var boss_rewards := 0
	for d in game.drops:
		if d.kind == "item" and d.item.get("boss_reward", false):
			boss_rewards += 1
	_check("boss creates four legendary rewards", boss_rewards == 4)
	_check("boss marks victory pending", game.victory_pending)
	game.step(0.016)
	_check("boss completion enters victory", game.mode == "victory" and game.profile.records.wins >= 1)
	_check("completed run clears resumable save", game.profile.run.is_empty())

	if passed + failures.size() != 43:
		failures.append("expected 43 checks, executed %d" % (passed + failures.size()))
		printerr("FAIL check count mismatch: ", passed + failures.size())

	var summary := "QA_SUMMARY passed=%d failed=%d total=%d" % [passed, failures.size(), passed + failures.size()]
	print(summary)
	for failure in failures:
		printerr("QA_FAILURE ", failure)
	game.shutdown(0 if failures.is_empty() else 1)
