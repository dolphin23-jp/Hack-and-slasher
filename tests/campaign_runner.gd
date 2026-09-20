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
var locked_target = null

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	game.profile.run = {}
	game.start_run()
	game.set_physics_process(false)
	game.set_process(false)
	game.player.controlled_by_test = true
	game.player.test_move = Vector2.ZERO
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
	var survivors := []
	for enemy in game.enemies:
		if is_instance_valid(enemy) and not enemy.dead:
			survivors.append("%s@%s hp=%.1f state=%s" % [enemy.kind, str(enemy.position.round()), enemy.hp, enemy.state])
	var summary = "CAMPAIGN mode=%s simulated=%.1fs attacks=%d blessings=%d kills=%d visited=%s active=%d pos=%s survivors=%s failures=%d\n" % [
		game.mode, simulated, attacks, blessings, game.kills, str(unique_visited), game.dungeon.active, str(game.player.position.round()), str(survivors), failures.size()
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

	var target = _combat_target()
	if target != null:
		var to_enemy: Vector2 = target.position - player.position
		var distance = to_enemy.length()
		if distance > 0.001:
			player.facing = to_enemy / distance
		var evade := _danger_move(target)
		if evade.length() > 0.05:
			player.test_move = evade
		elif not game.dungeon.line_clear(player.position, target.position):
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
	if origin.distance_to(target_position) < 0.001:
		return Vector2.ZERO
	var goal := target_position
	if not game.dungeon.line_clear(origin, target_position):
		var waypoint = _one_bend_waypoint(origin, target_position)
		if waypoint != null:
			goal = waypoint
		elif game.dungeon.active >= 0:
			goal = game.dungeon.rooms[game.dungeon.active].center
	var delta: Vector2 = goal - origin
	if delta.length() < 0.001:
		return Vector2.ZERO
	var direct := delta.normalized()
	if game.dungeon.line_clear(origin, goal):
		return direct
	var best: Vector2 = direct
	var best_score: float = INF
	var phase_sign: float = 1.0 if int(simulated / 2.0) % 2 == 0 else -1.0
	for angle in [0.0, 0.35 * phase_sign, -0.35 * phase_sign, 0.7 * phase_sign, -0.7 * phase_sign, 1.1 * phase_sign, -1.1 * phase_sign, 1.55 * phase_sign, -1.55 * phase_sign, 2.1 * phase_sign, -2.1 * phase_sign]:
		var candidate: Vector2 = direct.rotated(float(angle))
		var next: Vector2 = game.dungeon.move_body(origin, candidate * 96.0, 18.0)
		var progress: float = next.distance_to(origin)
		if progress < 6.0:
			continue
		var score: float = next.distance_to(goal) + absf(float(angle)) * 5.0
		if game.dungeon.line_clear(next, goal):
			score -= 320.0
		if score < best_score:
			best_score = score
			best = candidate
	return best

func _one_bend_waypoint(origin: Vector2, target_position: Vector2):
	var best = null
	var best_cost := INF
	for obstacle in game.dungeon.obstacles:
		if game.dungeon.active >= 0 and not game.dungeon.rooms[game.dungeon.active].rect.grow(90.0).intersects(obstacle):
			continue
		var grown: Rect2 = obstacle.grow(58.0)
		var points = [
			grown.position,
			Vector2(grown.end.x, grown.position.y),
			grown.end,
			Vector2(grown.position.x, grown.end.y)
		]
		for point in points:
			if not game.dungeon.walkable(point, 18.0, false):
				continue
			if not game.dungeon.line_clear(origin, point):
				continue
			if not game.dungeon.line_clear(point, target_position):
				continue
			var cost := origin.distance_to(point) + point.distance_to(target_position)
			if cost < best_cost:
				best_cost = cost
				best = point
	return best

func _combat_target():
	if is_instance_valid(locked_target) and not locked_target.dead and locked_target.state != "spawn":
		return locked_target
	locked_target = _nearest_live_enemy()
	return locked_target

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

func _danger_move(primary) -> Vector2:
	var player = game.player
	var immediate := false
	for hazard in game.hazards:
		if hazard.delay <= 0.65 and player.position.distance_to(hazard.p) < float(hazard.radius) + 135.0:
			immediate = true
			break
	if not immediate:
		for projectile in game.projectiles:
			if is_instance_valid(projectile) and not projectile.dead and not projectile.friendly and projectile.position.distance_to(player.position) < 190.0:
				immediate = true
				break
	if not immediate:
		for enemy in game.enemies:
			if not is_instance_valid(enemy) or enemy.dead or enemy.state == "spawn":
				continue
			if enemy.state == "windup":
				var reach := float(enemy.spec.get("reach", 100.0))
				if enemy.kind == "boss":
					reach = 700.0 if enemy.pattern % 4 in [1, 2, 3] else 260.0
				if enemy.position.distance_to(player.position) < reach + 150.0:
					immediate = true
					break
			elif enemy.state == "charge" and enemy.position.distance_to(player.position) < 300.0:
				immediate = true
				break
	if not immediate:
		return Vector2.ZERO

	var best_dir := Vector2.ZERO
	var best_score := -INF
	var preferred := Vector2.RIGHT
	if primary != null:
		preferred = (player.position - primary.position).normalized()
	var candidates := [preferred, preferred.orthogonal(), -preferred.orthogonal()]
	for i in range(16):
		candidates.append(Vector2.from_angle(i * TAU / 16.0))
	for candidate in candidates:
		if candidate.length() < 0.1:
			continue
		var dir: Vector2 = candidate.normalized()
		var projected: Vector2 = game.dungeon.move_body(player.position, dir * 105.0, 18.0)
		if projected.distance_to(player.position) < 18.0:
			continue
		var score := _safety_score(projected)
		if primary != null:
			score += minf(projected.distance_to(primary.position), 320.0) * 0.015
		if score > best_score:
			best_score = score
			best_dir = dir
	return best_dir

func _safety_score(point: Vector2) -> float:
	var score := 0.0
	for hazard in game.hazards:
		var margin := point.distance_to(hazard.p) - float(hazard.radius)
		if hazard.delay <= 0.8:
			if margin < 28.0:
				score -= 1600.0
			else:
				score += minf(margin, 220.0) * 0.025
	for projectile in game.projectiles:
		if not is_instance_valid(projectile) or projectile.dead or projectile.friendly:
			continue
		var future: Vector2 = projectile.position + projectile.velocity * 0.32
		var miss := Geometry2D.get_closest_point_to_segment(point, projectile.position, future).distance_to(point)
		if miss < 54.0:
			score -= 1100.0
		else:
			score += minf(miss, 180.0) * 0.012
	for enemy in game.enemies:
		if not is_instance_valid(enemy) or enemy.dead or enemy.state == "spawn":
			continue
		var delta: Vector2 = point - enemy.position
		var distance := delta.length()
		if enemy.state == "charge":
			var charge_end: Vector2 = enemy.position + enemy.aim * 340.0
			var miss := Geometry2D.get_closest_point_to_segment(point, enemy.position, charge_end).distance_to(point)
			if miss < enemy.radius + 42.0:
				score -= 1800.0
			continue
		if enemy.state != "windup":
			continue
		match enemy.kind:
			"cantor":
				var beam_end: Vector2 = enemy.position + enemy.aim * 470.0
				var miss := Geometry2D.get_closest_point_to_segment(point, enemy.position, beam_end).distance_to(point)
				if miss < 62.0:
					score -= 1500.0
			"hound":
				var charge_end: Vector2 = enemy.position + enemy.aim * 330.0
				var miss := Geometry2D.get_closest_point_to_segment(point, enemy.position, charge_end).distance_to(point)
				if miss < enemy.radius + 46.0:
					score -= 1700.0
			"warden":
				if distance < 145.0:
					score -= 1600.0
			"boss":
				match enemy.pattern % 4:
					0:
						if distance < 255.0 and absf(enemy.aim.angle_to(delta)) < 1.62:
							score -= 2000.0
					1:
						score += minf(distance, 420.0) * 0.01
					2:
						if distance < 270.0:
							score -= 1400.0
					3:
						var charge_end: Vector2 = enemy.position + enemy.aim * 520.0
						var miss := Geometry2D.get_closest_point_to_segment(point, enemy.position, charge_end).distance_to(point)
						if miss < enemy.radius + 55.0:
							score -= 1900.0
			_:
				var reach := float(enemy.spec.get("reach", 90.0)) + 35.0
				if distance < reach and absf(enemy.aim.angle_to(delta)) < 1.25:
					score -= 1450.0
	return score

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
