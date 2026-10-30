extends SceneTree

const Profiles = preload("res://modules/character_profiles.gd")

func _initialize() -> void:
	call_deferred("run")

func victim(game, direction: float, distance: float, can_launch: bool, kind: int = 0) -> Dictionary:
	var monster: Dictionary = game._monster_definition(kind, game.player + Vector2(direction * 100, 0), "Pushback test", 0, 1)
	monster.active = true
	monster.hp = 10000
	monster.max_hp = 10000
	monster.defense = 0
	monster.hit_pushback_distance_px = distance
	monster.can_be_launched = can_launch
	game.monsters.assign([monster])
	return monster

func run() -> void:
	var profiles := Profiles.new()
	assert(profiles.load_config())
	var configured := {}
	profiles.configure_monster(configured, 101)
	assert(configured.hit_pushback_distance_px == profiles.profile(101).hitPushbackDistancePx)
	assert(configured.can_be_launched == profiles.profile(101).canBeLaunched)
	var game = load("res://main.tscn").instantiate()
	game.account_store = "/private/tmp/monster-hit-reaction-%d.json" % OS.get_process_id()
	root.add_child(game)
	game.set_process(false)
	await process_frame
	game._enter_city(false)
	game._enter_dungeon()
	game.dungeon_stage = "wave_delay"
	game.dungeon_next_wave_timer = 1000.0
	game.player = Vector2(1200, 650)
	game.player_stats.attack = 10
	for direction in [1.0, -1.0]:
		game.facing = direction
		var monster := victim(game, direction, 60.0, false)
		var origin: Vector2 = monster.pos
		game._apply_attack_damage(300, 100, 200, 100)
		assert(monster.action_state.key == "hurt")
		game._update_dungeon(0.05)
		assert(monster.pos == origin, "Hit stop freezes the shove")
		game._update_dungeon(0.05)
		assert(monster.pos == origin)
		game._update_dungeon(0.06)
		assert(is_equal_approx(monster.pos.x, origin.x + direction * 30.0))
		game._update_dungeon(0.06)
		assert(is_equal_approx(monster.pos.x, origin.x + direction * 60.0))
		assert(monster.pos.y == origin.y and monster.character_height_px == 0.0)
		game._update_dungeon(0.2)
		assert(is_equal_approx(monster.pos.x, origin.x + direction * 60.0), "A shove stops after the configured distance")
	game.facing = 1.0
	var stationary := victim(game, 1.0, 0.0, false)
	var origin: Vector2 = stationary.pos
	game._apply_attack_damage(300, 100, 200)
	game._update_dungeon(0.2)
	assert(stationary.pos == origin, "Zero disables horizontal shove")
	# Existing knockdown threshold chooses a standing fall when launching is disabled.
	game.player_stats.attack = 4000
	var grounded := victim(game, 1.0, 40.0, false)
	game._apply_attack_damage(300, 100, 200)
	assert(grounded.hp > 0 and grounded.damage_reaction.down_remaining > 0.0)
	assert(grounded.damage_reaction.knockback_remaining == 0.0 and grounded.action_state.key == "down")
	game._update_dungeon(0.12)
	assert(grounded.character_height_px == 0.0)
	# The flag, including a boss override, governs both motion and selected animation.
	for kind in [0, 3]:
		var launched := victim(game, 1.0, 40.0, true, kind)
		game._apply_attack_damage(300, 100, 200)
		assert(launched.damage_reaction.knockback_remaining > 0.0 and launched.action_state.key == "floated")
		game._update_dungeon(0.1)
		assert(launched.character_height_px > 0.0)
	# Death on the ground can finish its shove without reviving or using an air fall.
	game.player_stats.attack = 100000
	var dead := victim(game, 1.0, 25.0, false)
	origin = dead.pos
	game._apply_attack_damage(300, 100, 200)
	assert(game.monster_actions.corpses.has(dead) and dead.action_state.key == "down")
	game._update_dungeon(0.12)
	assert(is_equal_approx(dead.pos.x, origin.x + 25.0) and dead.character_height_px == 0.0)
	# A very large shove is clamped to a walkable point instead of passing the edge.
	game.monster_actions.clear()
	game.player_stats.attack = 10
	var edge := victim(game, 1.0, 10000.0, false)
	game._apply_attack_damage(300, 100, 200)
	game._update_dungeon(0.12)
	assert(Vector2(edge.pos).distance_to(game._clamp_point_to_dungeon_walkable_area(edge.pos)) < 0.001)
	assert(edge.pos.x <= game.dungeon_world_width)
	game.queue_free()
	await process_frame
	DirAccess.remove_absolute("/private/tmp/monster-hit-reaction-%d.json" % OS.get_process_id())
	print("MONSTER_HIT_REACTION_TEST_OK")
	quit()
