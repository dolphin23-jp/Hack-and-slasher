extends Node
# Deterministic full-run regression: combat input remains movement + normal attack.

const DT = 1.0 / 60.0
const SUBSTEPS_PER_FRAME = 120
const MAX_SIM_SECONDS = 2400.0
const ROUTE = [1, 3, 1, 2, 4, 5, 6, 7, 8, 9]

var game
var route_index = 0
var simulated = 0.0
var attacks = 0
var blessings = 0
var last_cleared_count = 1
var next_report = 120.0
var retreat_until = 0.0
var last_hp = 0.0
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
	last_hp = game.player.hp
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
			if game.player.hp < last_hp - 0.5:
				var boss = _boss_enemy()
				var boss_note: String = "none" if boss == null else "%s p=%d phase=%d d=%.0f" % [boss.state, boss.pattern, boss.phase, boss.position.distance_to(game.player.position)]
				var hostile_projectiles: int = 0
				for projectile in game.projectiles:
					if is_instance_valid(projectile) and not projectile.dead and not projectile.friendly:
						hostile_projectiles += 1
				print("CAMPAIGN HIT t=", snapped(simulated, 0.1), " hp=", snapped(game.player.hp, 0.1), " boss=", boss_note, " hostile_projectiles=", hostile_projectiles, " hazards=", game.hazards.size())
			last_hp = game.player.hp

			if game.dungeon.cleared.size() > last_cleared_count:
				last_cleared_count = game.dungeon.cleared.size()
				print("CAMPAIGN CLEAR rooms=", game.dungeon.cleared, " t=", snapped(simulated, 0.1), " hp=", snapped(game.player.hp, 0.1), " level=", game.player.level)

			_advance_route_if_ready()
			if simulated >= next_report:
				var boss = _boss_enemy()
				var boss_status: String = "" if boss == null else " boss_hp=%d/%d boss_state=%s pattern=%d phase=%d" % [ceili(boss.hp), ceili(boss.max_hp), boss.state, boss.pattern, boss.phase]
				print("CAMPAIGN STATUS t=", snapped(simulated, 0.1), " room=", game.dungeon.room_at(game.player.position), " active=", game.dungeon.active, " enemies=", game.enemies.size(), " kills=", game.kills, " hp=", snapped(game.player.hp, 0.1), boss_status)
				next_report += 120.0
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
		if target.kind == "boss":
			var boss_move: Vector2 = _boss_move(target, to_enemy, distance)
			if boss_move.length() > 0.05:
				player.test_move = boss_move
				return
		var evade: Vector2 = _danger_move(target)
		if evade.length() > 0.05:
			player.test_move = evade
		else:
			var healing = _nearest_health_drop()
			var heal_threshold: float = 0.62 if game.dungeon.active == 9 else 0.42
			var heal_reach: float = 620.0 if game.dungeon.active == 9 else 420.0
			if player.hp < player.stats.hp * heal_threshold and healing != null and player.position.distance_to(healing.position) < heal_reach:
				player.test_move = _navigate_toward(healing.position)
				return
			if simulated < retreat_until and target.kind in ["hound", "warden", "elite"]:
				var away: Vector2 = -to_enemy.normalized()
				var flank: Vector2 = to_enemy.orthogonal().normalized()
				if flank.dot(player.last_move) < 0.0:
					flank = -flank
				player.test_move = (away * 1.35 + flank * 0.35).normalized()
				return
		if not game.dungeon.line_clear(player.position, target.position):
			player.test_move = _navigate_toward(target.position)
		elif distance > (108.0 if target.kind == "boss" else 102.0):
			player.test_move = to_enemy.normalized()
		else:
			var orbit: Vector2 = to_enemy.orthogonal().normalized()
			if orbit.dot(player.last_move) < 0.0:
				orbit = -orbit
			var away_weight: float = 0.52 if distance < 82.0 else (0.28 if target.kind == "boss" else 0.18)
			player.test_move = (orbit - to_enemy.normalized() * away_weight).normalized()
		if distance <= 112.0 and target.state != "spawn":
			if player.attack():
				attacks += 1
				match target.kind:
					"hound": retreat_until = simulated + 0.35
					"warden": retreat_until = simulated + 0.75
					"elite": retreat_until = simulated + 1.15
					"boss": retreat_until = simulated
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

func _boss_move(boss, to_enemy: Vector2, distance: float) -> Vector2:
	var player = game.player
	var room: Dictionary = game.dungeon.rooms[9]
	var safe_rect: Rect2 = room.rect.grow(-145.0)
	var away: Vector2 = -to_enemy.normalized()
	var side: Vector2 = to_enemy.orthogonal().normalized()
	if side.dot(player.last_move) < 0.0:
		side = -side
	var hostile_count: int = _hostile_projectile_count()

	# Never re-enter while delayed floor effects are still threatening us.
	if not game.hazards.is_empty():
		var hazard_dodge: Vector2 = _danger_move(boss)
		if hazard_dodge.length() > 0.05:
			return _boss_safe_direction(hazard_dodge, room)

	# Radial volleys outlive the animation. Keep translating around the arena
	# until every hostile projectile has cleared instead of cutting back inward.
	if hostile_count > 0:
		var projectile_dodge: Vector2 = _incoming_projectile_dodge()
		if projectile_dodge.length() > 0.05:
			return projectile_dodge
		var volley_move: Vector2 = side
		if distance < 500.0:
			volley_move = (side + away * 0.55).normalized()
		return _boss_safe_direction(volley_move, room)

	if boss.state == "windup":
		match boss.pattern % 4:
			0:
				return _boss_safe_direction(away if distance < 285.0 else side, room)
			1:
				return _boss_safe_direction((side + away * 0.8).normalized(), room)
			2:
				return _boss_safe_direction(away if distance < 480.0 else side, room)
			3:
				return _boss_charge_dodge(boss, room)

	if boss.state == "charge":
		return _boss_charge_dodge(boss, room)

	# Recovery is the deliberate damage window. Stay in sword range, attack,
	# and orbit without drifting toward the arena boundary.
	if boss.state == "recover":
		if not safe_rect.has_point(player.position):
			return _boss_safe_direction((room.center - player.position).normalized(), room)
		if distance > 118.0:
			return _boss_safe_direction(to_enemy.normalized(), room)
		if player.attack():
			attacks += 1
		var orbit: Vector2 = side
		if distance < 76.0:
			orbit = (side + away * 0.4).normalized()
		elif distance > 106.0:
			orbit = (side + to_enemy.normalized() * 0.18).normalized()
		return _boss_safe_direction(orbit, room)

	# Between patterns, recover arena position first. Pattern 0 must be
	# deliberately triggered inside 175 px; the other patterns can start afar.
	if not safe_rect.has_point(player.position):
		return _boss_safe_direction((room.center - player.position).normalized(), room)
	if boss.pattern % 4 == 0:
		if distance > 155.0:
			return _boss_safe_direction(to_enemy.normalized(), room)
		return _boss_safe_direction(side, room)
	if distance > 280.0:
		return _boss_safe_direction(to_enemy.normalized(), room)
	return _boss_safe_direction(side, room)

func _boss_charge_dodge(boss, room: Dictionary) -> Vector2:
	var player = game.player
	var aim: Vector2 = boss.aim.normalized()
	var base_side: Vector2 = aim.orthogonal().normalized()
	var safe_rect: Rect2 = room.rect.grow(-145.0)
	var best: Vector2 = base_side
	var best_score: float = -INF
	for candidate in [base_side, -base_side, (base_side + (room.center-player.position).normalized()*0.45).normalized(), (-base_side + (room.center-player.position).normalized()*0.45).normalized()]:
		var next: Vector2 = game.dungeon.move_body(player.position, candidate * 285.0, 18.0)
		var progress: float = next.distance_to(player.position)
		var rel: Vector2 = next - boss.position
		var line_clearance: float = absf(rel.cross(aim))
		var score: float = progress * 3.0 + minf(line_clearance, 360.0) * 1.8 - next.distance_to(room.center) * 0.18
		if safe_rect.has_point(next):
			score += 450.0
		if score > best_score:
			best_score = score
			best = candidate
	return best

func _boss_safe_direction(desired: Vector2, room: Dictionary) -> Vector2:
	var player = game.player
	if desired.length() < 0.05:
		return Vector2.ZERO
	var safe_rect: Rect2 = room.rect.grow(-130.0)
	var best: Vector2 = desired.normalized()
	var best_score: float = -INF
	for angle in [0.0, 0.35, -0.35, 0.7, -0.7, 1.05, -1.05]:
		var candidate: Vector2 = desired.normalized().rotated(float(angle))
		var next: Vector2 = game.dungeon.move_body(player.position, candidate * 150.0, 18.0)
		var progress: float = next.distance_to(player.position)
		if progress < 8.0:
			continue
		var score: float = progress * 2.0 - next.distance_to(room.center) * 0.08 - absf(float(angle)) * 8.0
		if safe_rect.has_point(next):
			score += 180.0
		if score > best_score:
			best_score = score
			best = candidate
	return best

func _hostile_projectile_count() -> int:
	var count: int = 0
	for projectile in game.projectiles:
		if is_instance_valid(projectile) and not projectile.dead and not projectile.friendly:
			count += 1
	return count

func _boss_enemy():
	for enemy in game.enemies:
		if is_instance_valid(enemy) and not enemy.dead and enemy.kind == "boss":
			return enemy
	return null

func _nearest_health_drop():
	var nearest = null
	var best: float = INF
	for drop in game.drops:
		if not is_instance_valid(drop) or drop.taken or drop.kind != "health":
			continue
		var distance: float = drop.position.distance_squared_to(game.player.position)
		if distance < best:
			best = distance
			nearest = drop
	return nearest

func _nearest_live_enemy():
	var boss = _boss_enemy()
	var prioritize_adds: bool = boss != null and int(boss.phase) == 2
	var nearest = null
	var best = INF
	for enemy in game.enemies:
		if not is_instance_valid(enemy) or enemy.dead or enemy.state == "spawn":
			continue
		if prioritize_adds and enemy.kind == "boss":
			continue
		var distance = enemy.position.distance_squared_to(game.player.position)
		if distance < best:
			best = distance
			nearest = enemy
	if nearest == null and boss != null and not boss.dead and boss.state != "spawn":
		return boss
	return nearest

func _incoming_projectile_dodge() -> Vector2:
	var player = game.player
	var hostile = []
	for projectile in game.projectiles:
		if is_instance_valid(projectile) and not projectile.dead and not projectile.friendly:
			hostile.append(projectile)
	if hostile.is_empty():
		return Vector2.ZERO
	var room: Dictionary = game.dungeon.rooms[9]
	var safe_rect: Rect2 = room.rect.grow(-125.0)
	var move_speed: float = 235.0 * (1.0 + float(player.stats.speed))
	var best: Vector2 = Vector2.ZERO
	var best_score: float = -INF
	for i in range(16):
		var candidate: Vector2 = Vector2.from_angle(float(i) * TAU / 16.0)
		var projected: Vector2 = game.dungeon.move_body(player.position, candidate * 190.0, 18.0)
		var progress: float = projected.distance_to(player.position)
		if progress < 20.0:
			continue
		var min_clearance: float = INF
		for projectile in hostile:
			var rel: Vector2 = projectile.position - player.position
			var relative_velocity: Vector2 = projectile.velocity - candidate * move_speed
			var rv_sq: float = relative_velocity.length_squared()
			var t: float = 0.0
			if rv_sq > 1.0:
				t = clampf(-rel.dot(relative_velocity) / rv_sq, 0.0, 2.4)
			var clearance: float = (rel + relative_velocity * t).length() - float(projectile.radius) - 22.0
			min_clearance = minf(min_clearance, clearance)
		var score: float = min_clearance * 5.0 + progress * 0.7 - projected.distance_to(room.center) * 0.08
		if safe_rect.has_point(projected):
			score += 260.0
		if score > best_score:
			best_score = score
			best = candidate
	return best


func _danger_move(primary) -> Vector2:
	var player = game.player
	var threat_dir: Vector2 = Vector2.ZERO
	var threat_weight: float = 0.0
	for hazard in game.hazards:
		if hazard.delay > 0.7:
			continue
		var delta: Vector2 = player.position - hazard.p
		var limit: float = float(hazard.radius) + 115.0
		if delta.length() < limit:
			threat_dir += delta.normalized() * (limit - delta.length() + 40.0)
			threat_weight += 1.0
	for projectile in game.projectiles:
		if not is_instance_valid(projectile) or projectile.dead or projectile.friendly:
			continue
		var delta: Vector2 = player.position - projectile.position
		if delta.length() < 230.0:
			var side: Vector2 = projectile.velocity.orthogonal().normalized()
			if side.dot(delta) < 0.0:
				side = -side
			threat_dir += side * 165.0
			threat_weight += 1.0
	for enemy in game.enemies:
		if not is_instance_valid(enemy) or enemy.dead or enemy.state == "spawn":
			continue
		var delta: Vector2 = player.position - enemy.position
		var distance: float = delta.length()
		if enemy.state == "charge" and distance < 270.0:
			var side: Vector2 = enemy.aim.orthogonal().normalized()
			if side.dot(delta) < 0.0:
				side = -side
			threat_dir += side * 170.0
			threat_weight += 1.0
		elif enemy.state == "windup":
			var dodge: Vector2 = _windup_dodge(enemy, delta, distance)
			if dodge.length() > 0.05:
				threat_dir += dodge * 150.0
				threat_weight += 1.0
	if threat_weight <= 0.0 or threat_dir.length() < 0.05:
		return Vector2.ZERO
	var desired: Vector2 = threat_dir.normalized()
	var best: Vector2 = Vector2.ZERO
	var best_progress: float = -1.0
	for angle in [0.0, 0.35, -0.35, 0.7, -0.7, 1.05, -1.05]:
		var candidate: Vector2 = desired.rotated(float(angle))
		var next: Vector2 = game.dungeon.move_body(player.position, candidate * 72.0, 18.0)
		var progress: float = next.distance_to(player.position)
		if progress > best_progress:
			best_progress = progress
			best = candidate
	return best.normalized() if best_progress >= 8.0 else Vector2.ZERO

func _windup_dodge(enemy, delta: Vector2, distance: float) -> Vector2:
	var side: Vector2 = enemy.aim.orthogonal().normalized()
	if side.dot(delta) < 0.0:
		side = -side
	match enemy.kind:
		"cantor":
			return side if distance < 430.0 else Vector2.ZERO
		"hound":
			return side if distance < 320.0 else Vector2.ZERO
		"warden":
			return delta.normalized() if distance < 205.0 else Vector2.ZERO
		"elite":
			if distance < 225.0 and absf(enemy.aim.angle_to(delta)) < 1.6:
				return (side * 1.2 + delta.normalized() * 0.35).normalized()
		"boss":
			match enemy.pattern % 4:
				0:
					if distance < 285.0 and absf(enemy.aim.angle_to(delta)) < 1.7:
						return (side * 1.3 + delta.normalized() * 0.45).normalized()
				1:
					return side
				2:
					return (side * 1.45 + delta.normalized() * 0.12).normalized()
				3:
					return side
		_:
			var reach: float = float(enemy.spec.get("reach", 80.0)) + 55.0
			if distance < reach and absf(enemy.aim.angle_to(delta)) < 1.35:
				return (side + delta.normalized() * 0.25).normalized()
	return Vector2.ZERO

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
