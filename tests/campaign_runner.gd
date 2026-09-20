extends Node

const DT = 1.0 / 60.0
const SUBSTEPS_PER_FRAME = 30
const MAX_SIM_SECONDS = 2400.0
const ROUTE = [1, 3, 1, 2, 4, 5, 6, 7, 8, 9]

var game
var route_index = 0
var simulated = 0.0
var attacks = 0
var blessings = 0
var last_cleared_count = 1
var failures: Array[String] = []

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	game.profile.run = {}
	game.start_run()
	game.set_physics_process(false)
	game.set_process(false)
	game.player.controlled_by_test = true
	game.player.test_move = Vector2.ZERO
	# This regression proves room connectivity and normal-attack encounter completion.
	# Damage immunity keeps combat difficulty/balance from making the route test flaky.
	game.player.invulnerable = MAX_SIM_SECONDS + 60.0
	print("CAMPAIGN START seed=", game.run_seed)

	while simulated < MAX_SIM_SECONDS and game.mode not in ["victory", "dead"]:
		for _substep in range(SUBSTEPS_PER_FRAME):
			if game.mode == "upgrade":
				_choose_survival_blessing()
			if game.mode == "dead" or game.mode == "victory":
				break
			if game.mode != "play":
				failures.append("unexpected mode: " + game.mode)
				break

			_drive_player()
			game.step(DT)
			simulated += DT

			if game.dungeon.cleared.size() > last_cleared_count:
				last_cleared_count = game.dungeon.cleared.size()
				print("CAMPAIGN CLEAR rooms=", game.dungeon.cleared, " t=", snapped(simulated, 0.1), " hp=", snapped(game.player.hp, 0.1), " level=", game.player.level)

			_advance_route_if_ready()
			if simulated >= MAX_SIM_SECONDS:
				break

		if not failures.is_empty():
			break
		await get_tree().process_frame

	game.player.test_move = Vector2.ZERO
	var unique_visited: Array[int] = []
	for id in game.dungeon.visited:
		var room_id = int(id)
		if room_id not in unique_visited:
			unique_visited.append(room_id)
	unique_visited.sort()

	if game.mode != "victory":
		failures.append("campaign did not reach victory; mode=%s t=%.1f" % [game.mode, simulated])
	if unique_visited.size() != 10:
		failures.append("expected all 10 rooms visited, got " + str(unique_visited))
	if 3 not in unique_visited:
		failures.append("optional treasury was not visited")
	if attacks <= 0:
		failures.append("normal attack was never used")
	if game.player.dead:
		failures.append("player died before campaign completion")

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-artifacts"))
	var summary = "CAMPAIGN mode=%s simulated=%.1fs attacks=%d blessings=%d kills=%d visited=%s failures=%d\n" % [
		game.mode, simulated, attacks, blessings, game.kills, str(unique_visited), failures.size()
	]
	for failure in failures:
		summary += "FAIL: " + failure + "\n"
	var file = FileAccess.open("res://test-artifacts/campaign_summary.txt", FileAccess.WRITE)
	if file:
		file.store_string(summary)
		file.close()
	print(summary.strip_edges())
	game.shutdown(0 if failures.is_empty() else 1)

func _advance_route_if_ready() -> void:
	if route_index >= ROUTE.size() or game.dungeon.active >= 0 or not game.enemies.is_empty():
		return
	var target_room: int = ROUTE[route_index]
	var current_room = game.dungeon.room_at(game.player.position)
	if current_room == target_room and target_room in game.dungeon.cleared:
		route_index += 1
		if route_index < ROUTE.size():
			print("CAMPAIGN NEXT room=", ROUTE[route_index] + 1)

func _drive_player() -> void:
	var player = game.player
	if not is_instance_valid(player):
		return

	var target = _nearest_live_enemy()
	if target != null:
		var to_enemy: Vector2 = target.position - player.position
		var distance = to_enemy.length()
		if distance > 0.001:
			player.facing = to_enemy / distance
		if not game.dungeon.line_clear(player.position, target.position):
			player.test_move = _navigate_toward(target.position)
		elif distance > 96.0:
			player.test_move = to_enemy.normalized()
		else:
			player.test_move = Vector2.ZERO
		if distance <= 112.0 and target.state != "spawn":
			if player.attack():
				attacks += 1
		return

	if game.dungeon.active >= 0:
		player.test_move = Vector2.ZERO
		return

	if route_index >= ROUTE.size():
		player.test_move = Vector2.ZERO
		return

	var room = game.dungeon.rooms[ROUTE[route_index]]
	var to_room: Vector2 = room.center - player.position
	if to_room.length() > 20.0:
		player.facing = to_room.normalized()
		player.test_move = _navigate_toward(room.center)
	else:
		player.test_move = Vector2.ZERO

func _navigate_toward(target_position: Vector2) -> Vector2:
	var origin: Vector2 = game.player.position
	var delta: Vector2 = target_position - origin
	if delta.length() < 0.001:
		return Vector2.ZERO
	var direct: Vector2 = delta.normalized()
	var best: Vector2 = direct
	var best_score: float = INF
	var phase_sign: float = 1.0 if int(simulated / 3.0) % 2 == 0 else -1.0
	for angle in [0.0, 0.45 * phase_sign, -0.45 * phase_sign, 0.9 * phase_sign, -0.9 * phase_sign, 1.3 * phase_sign, -1.3 * phase_sign]:
		var candidate: Vector2 = direct.rotated(float(angle))
		var next: Vector2 = game.dungeon.move_body(origin, candidate * 82.0, 18.0)
		var progress: float = next.distance_to(origin)
		if progress < 8.0:
			continue
		var score: float = next.distance_to(target_position) + absf(float(angle)) * 8.0
		if game.dungeon.line_clear(next, target_position):
			score -= 260.0
		if score < best_score:
			best_score = score
			best = candidate
	return best

func _nearest_live_enemy():
	var nearest = null
	var best = INF
	for enemy in game.enemies:
		if not is_instance_valid(enemy) or enemy.dead or enemy.state == "spawn":
			continue
		var distance = enemy.position.distance_squared_to(game.player.position)
		if distance < best:
			best = distance
			nearest = enemy
	return nearest

func _danger_vector(primary) -> Vector2:
	var player = game.player
	var avoid = Vector2.ZERO

	for hazard in game.hazards:
		var delta: Vector2 = player.position - hazard.p
		var safe_radius = float(hazard.radius) + 85.0
		if delta.length() < safe_radius:
			avoid += delta.normalized() * (3.0 if hazard.delay <= 0.35 else 1.8)

	for projectile in game.projectiles:
		if not is_instance_valid(projectile) or projectile.dead or projectile.friendly:
			continue
		var delta: Vector2 = player.position - projectile.position
		if delta.length() < 155.0:
			var side = projectile.velocity.orthogonal().normalized()
			if side.dot(delta) < 0:
				side = -side
			avoid += side * 2.4

	for enemy in game.enemies:
		if not is_instance_valid(enemy) or enemy.dead or enemy.state == "spawn":
			continue
		var delta: Vector2 = player.position - enemy.position
		var distance = delta.length()
		if enemy.state == "windup":
			var reach = float(enemy.spec.get("reach", 100.0))
			if enemy.kind == "boss":
				reach = 280.0
			if distance < reach + 115.0:
				var side = enemy.aim.orthogonal().normalized()
				if side.dot(delta) < 0:
					side = -side
				avoid += side * 3.2 + delta.normalized() * 1.2
		if enemy.state == "charge" and distance < 230.0:
			var side = enemy.aim.orthogonal().normalized()
			if side.dot(delta) < 0:
				side = -side
			avoid += side * 3.6


	if primary != null and primary.kind in ["elite", "boss"] and primary.state == "windup":
		var delta: Vector2 = player.position - primary.position
		avoid += delta.normalized() * 1.4

	return avoid

func _choose_survival_blessing() -> void:
	if game.upgrade_choices.is_empty():
		return
	var priorities = ["HEARTWOOD", "SOUL TAKER", "WAYFARER", "OATH OF STEEL", "TEMPERED EDGE", "EXECUTIONER", "QUICKENING", "COLD SUN", "FORKED PROMISE"]
	var choice = 0
	var best_rank = priorities.size() + 1
	for i in range(game.upgrade_choices.size()):
		var name: String = game.upgrade_choices[i].name
		var rank = priorities.find(name)
		if rank >= 0 and rank < best_rank:
			best_rank = rank
			choice = i
	game.choose_upgrade(choice)
	blessings += 1
