extends Node

var game
var failures: Array[String] = []
var simulated_steps := 0
var attack_attempts := 0
var rooms_completed: Array[int] = []

const DT := 1.0 / 30.0
const ROUTE := [1, 3, 1, 2, 4, 5, 6, 7, 8, 9]
const MAX_STEPS_PER_LEG := 18000

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	game.set_physics_process(false)
	game.profile.run = {}
	game.start_run()
	game.player.controlled_by_test = true
	# This is a traversal/combat connectivity smoke, not a balance benchmark.
	# Keep the driver alive so failures reflect routing, encounters, or attack flow.
	game.player.invulnerable = 99999.0
	print("CAMPAIGN seed=", game.run_seed, " start_room=", game.dungeon.room_at(game.player.position))

	for room_id in ROUTE:
		var ok := await _reach_and_clear(room_id)
		if not ok:
			failures.append("could not complete room %02d %s" % [room_id + 1, game.dungeon.rooms[room_id].name])
			break
		if room_id not in rooms_completed:
			rooms_completed.append(room_id)
		print("ROOM_OK %02d %s kills=%d level=%d" % [room_id + 1, game.dungeon.rooms[room_id].name, game.kills, game.player.level])
		if room_id == 9:
			break

	var all_visited := true
	var all_cleared := true
	for id in range(10):
		all_visited = all_visited and id in game.dungeon.visited
		all_cleared = all_cleared and id in game.dungeon.cleared

	if not all_visited:
		failures.append("not all ten rooms were visited: %s" % str(game.dungeon.visited))
	if not all_cleared:
		failures.append("not all ten rooms were cleared: %s" % str(game.dungeon.cleared))
	if game.mode != "victory":
		failures.append("campaign did not reach victory; mode=%s" % game.mode)
	if 3 not in game.dungeon.visited:
		failures.append("optional treasury was not visited")
	if attack_attempts <= 0:
		failures.append("driver never used the normal attack")

	print("CAMPAIGN_SUMMARY rooms=%d visited=%d cleared=%d kills=%d level=%d attacks=%d steps=%d failed=%d" % [
		10 if all_visited else game.dungeon.visited.size(),
		game.dungeon.visited.size(),
		game.dungeon.cleared.size(),
		game.kills,
		game.player.level,
		attack_attempts,
		simulated_steps,
		failures.size()
	])
	for failure in failures:
		printerr("CAMPAIGN_FAILURE ", failure)
	game.player.test_move = Vector2.ZERO
	game.shutdown(0 if failures.is_empty() else 1)

func _reach_and_clear(room_id: int) -> bool:
	var room: Dictionary = game.dungeon.rooms[room_id]
	var local_steps := 0
	while local_steps < MAX_STEPS_PER_LEG:
		local_steps += 1
		simulated_steps += 1

		if game.mode == "dead":
			return false
		if game.mode == "victory":
			return room_id == 9
		if game.mode == "upgrade":
			game.choose_upgrade(0)
			continue
		if game.mode != "play":
			return false

		game.player.invulnerable = maxf(game.player.invulnerable, 5.0)
		var desired := Vector2.ZERO

		if game.dungeon.active >= 0 and not game.enemies.is_empty():
			var enemy = game.nearest_enemy(game.player.position, 5000.0)
			if enemy != null:
				var delta: Vector2 = enemy.position - game.player.position
				if delta.length() > 1.0:
					game.player.facing = delta.normalized()
				if game.dungeon.line_clear(game.player.position, enemy.position):
					if delta.length() > 92.0:
						desired = delta.normalized()
					if delta.length() < 142.0 and game.player.attack_cd <= 0.0 and game.player.dash_time <= 0.0 and enemy.state != "spawn":
						attack_attempts += 1
						game.player.attack()
				else:
					var via_center: Vector2 = game.dungeon.rooms[game.dungeon.active].center - game.player.position
					if via_center.length() > 36.0:
						desired = via_center.normalized()
					else:
						desired = (delta.normalized() + delta.normalized().orthogonal() * 0.7).normalized()
		elif game.dungeon.active >= 0:
			desired = Vector2.ZERO
		else:
			var delta_to_room: Vector2 = room.center - game.player.position
			if delta_to_room.length() > 34.0:
				desired = delta_to_room.normalized()

		game.player.test_move = desired
		game.step(DT)

		if room_id != 9 and room_id in game.dungeon.cleared and game.dungeon.active < 0:
			if game.dungeon.room_at(game.player.position) == room_id:
				game.player.test_move = Vector2.ZERO
				return true
		if room_id == 9 and game.mode == "victory":
			game.player.test_move = Vector2.ZERO
			return true

		if local_steps % 120 == 0:
			await get_tree().process_frame

	return false
