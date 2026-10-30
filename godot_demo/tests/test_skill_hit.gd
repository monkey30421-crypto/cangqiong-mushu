extends SceneTree

var hits: Array = []

func _initialize() -> void:
	call_deferred("run")

func enemy(game, offset: Vector2, active := true) -> Dictionary:
	var monster: Dictionary = game._monster_definition(0, game.player + offset, "打击测试", 0, 1)
	monster.active = active
	monster.spawn_alpha = 1.0
	monster.hp = 10000
	monster.max_hp = 10000
	monster.defense = 0
	# Point-width fixture isolates skill window/range tests; profile volume is tested separately.
	monster.hurtbox_x = 0.0
	monster.hurtbox_h = 10000.0
	monster.attack = 0
	return monster

func run() -> void:
	var path := "/private/tmp/skill-hit-%d.json" % OS.get_process_id()
	var account := "/private/tmp/skill-hit-account-%d.json" % OS.get_process_id()
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://config/character_actions.json"))
	config.revision = 900
	for row in config.rows:
		row.upper = null
		row.lower = null
		if int(row.id) in [2001, 2002, 2003]:
			row.attackDistancePx = 250.0
			row.longitudinalRangePx = 250.0
			row.heightRangePx = 0.0
			row.hitStopMs = 0.0
			row.animation = "attack%d_SingleSword" % (int(row.id) - 2000)
			row.upper = {"file": "skilleffect_jd_dg1.json", "animation": "attack%d" % (int(row.id) - 2000)}
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(config))
	file.close()
	var game = load("res://main.tscn").instantiate()
	game.character_action_store = path
	game.account_store = account
	root.add_child(game)
	game.set_process(false)
	await process_frame
	game.account_name.text = "skill_hit_test"
	game._login()
	game.role_name_input.text = "打击测试"
	game._confirm_role_name()
	game._enter_dungeon()
	game._close_modal()
	game.player = Vector2(500, 650)
	game.facing = 1.0
	var actions = game.character_actions
	actions.skill_effect_hit.connect(func(id, distance, _longitudinal, _height, _stop, _targets, _area): hits.append([id, distance]))
	assert(is_equal_approx(actions.pixels_to_meters(250), 2.5))
	var near_enemy := enemy(game, Vector2(300, 0))
	var hp := 0
	# All five attacks use the source effect's hit_start/hit_end, not a midpoint.
	var animations := ["attack1", "attack2", "attack3", "jump_attack1", "step_attack1"]
	for index in range(5):
		var id := 2001 + index
		actions.rows[id].upper = {"file": "skilleffect_jd_dg1.json", "animation": animations[index]}
		actions.rows[id].lower = null
		actions.rows[id].attackDistancePx = 250.0
		actions.rows[id].longitudinalRangePx = 250.0
		actions.rows[id].heightRangePx = 0.0
		actions.rows[id].hitStopMs = 0.0
		actions.library.character.animations[actions.rows[id].animation].events = [{"name": "action", "time": 0.0}]
		var clip: Dictionary = actions._effect_clip(actions.rows[id].upper)
		var start: float = clip.events[0].time
		var end: float = clip.events[1].time
		near_enemy = enemy(game, Vector2(300, 0))
		var late := enemy(game, Vector2(300, 0))
		game.monsters.assign([near_enemy, late])
		actions.play(id, true)
		actions.advance(start - 0.001, game.player, 1)
		assert(hits.is_empty() and near_enemy.hp == 10000)
		actions.advance(0.002, game.player, 1)
		assert(hits.size() == 1 and near_enemy.hp == 10000, "Opening miss must leave the window active")
		near_enemy.pos = game.player + Vector2(100, 0)
		actions.advance(0.01, game.player, 1)
		assert(near_enemy.hp < 10000, "Targets entering after hit_start must be hit")
		hp = near_enemy.hp
		actions.advance(0.01, game.player, 1)
		assert(near_enemy.hp == hp, "Each target takes damage only once per window")
		near_enemy.pos = game.player + Vector2(300, 0)
		actions.advance(0.01, game.player, 1)
		near_enemy.pos = game.player + Vector2(100, 0)
		late.pos = game.player + Vector2(100, 0)
		actions.advance(0.01, game.player, 1)
		assert(near_enemy.hp == hp and late.hp < 10000, "Reentry cannot hit again, but a different target can")
		actions.advance(end - start, game.player, 1)
		var expired := enemy(game, Vector2(100, 0))
		game.monsters.append(expired)
		actions.advance(0.01, game.player, 1)
		assert(expired.hp == 10000, "No hit after hit_end")
		actions.clear_effects()
		hits.clear()
	# Facing, active state and both planar range boundaries are still applied.
	near_enemy = enemy(game, Vector2(100, 0))
	var boundary := enemy(game, Vector2(250, 250))
	var outside := enemy(game, Vector2(251, 0))
	var inactive := enemy(game, Vector2(80, 0), false)
	var behind := enemy(game, Vector2(-100, 0))
	game.monsters.assign([near_enemy, boundary, outside, inactive, behind])
	actions.play(2001, true)
	actions.advance(0.5, game.player, 1)
	assert(near_enemy.hp < 10000 and boundary.hp < 10000, "A frame skipping the entire window still evaluates it")
	assert(outside.hp == 10000 and inactive.hp == 10000 and behind.hp == 10000)
	assert(hits.size() == 1)
	actions.clear_effects()
	hits.clear()
	# Same-cast upper/lower copies share their target ledger; next cast starts fresh.
	actions.rows[2001].lower = actions.rows[2001].upper.duplicate()
	var first_hit := float(actions._effect_clip(actions.rows[2001].upper).events[0].time) + 0.001
	actions.play(2001, true)
	actions.advance(first_hit, game.player, 1)
	var first_context: Dictionary = actions.effects[0].get_meta("hit_context")
	var second_context: Dictionary = actions.effects[1].get_meta("hit_context")
	assert(is_same(first_context.windows[0].targets, second_context.windows[0].targets))
	hp = near_enemy.hp
	actions.advance(0.01, game.player, 1)
	assert(near_enemy.hp == hp)
	actions.clear_effects()
	actions.play(2001, true)
	actions.advance(first_hit, game.player, 1)
	assert(near_enemy.hp < hp, "Next attack can hit the same victim again")
	actions.clear_effects()
	actions.rows[2001].lower = null
	hits.clear()
	# Explicit paired windows: zero-time start, multiple windows and legacy hit ignored.
	var fx: Dictionary = actions._effect_clip(actions.rows[2001].upper)
	fx.events = [{"name": "hit_start", "time": 0.0}, {"name": "hit_end", "time": 0.05}, {"name": "hit_start", "time": 0.1}, {"name": "hit_end", "time": 0.15}]
	actions.play(2001, true)
	actions.advance(0.0, game.player, 1)
	hp = near_enemy.hp
	assert(hits.size() == 1)
	actions.advance(0.02, game.player, 1)
	assert(near_enemy.hp == hp)
	actions.advance(0.09, game.player, 1)
	assert(near_enemy.hp < hp, "A separate hit window may hit again")
	actions.clear_effects()
	hits.clear()
	fx.events = [{"name": "hit", "time": 0.1}, {"name": "hit_start", "time": 0.2}]
	actions.play(2001, true)
	actions.advance(0.5, game.player, 1)
	assert(hits.is_empty(), "Legacy hit or an unclosed window cannot cause accidental damage")
	# Death/room transitions cancel open windows and reset frozen animation.
	fx.events = [{"name": "hit_start", "time": 0.0}, {"name": "hit_end", "time": 0.15}]
	actions.play(2001, true)
	actions.advance(0.01, game.player, 1)
	actions.clear_effects()
	hits.clear()
	actions.advance(0.05, game.player, 1)
	assert(hits.is_empty())
	# Independent depth and airborne height filters, evaluated at hit time.
	near_enemy.pos = game.player + Vector2(100, 40)
	assert(not game._is_monster_in_attack_range(near_enemy, 99, 40, 60), "Horizontal overflow must miss")
	game.character_height_px = 60.0
	assert(game._is_monster_in_attack_range(near_enemy, 250, 40, 60))
	assert(not game._is_monster_in_attack_range(near_enemy, 250, 39, 60))
	assert(game._is_monster_in_attack_range(near_enemy, 250, 40, 0), "Lower enemies pass the one-sided height check")
	near_enemy.character_height_px = 120.0
	assert(game._is_monster_in_attack_range(near_enemy, 250, 40, 60), "Upper height boundary is included")
	assert(not game._is_monster_in_attack_range(near_enemy, 250, 40, 59))
	near_enemy.character_height_px = 60.0
	assert(game._is_monster_in_attack_range(near_enemy, 250, 40, 0))
	game.character_height_px = 0.0
	# Actual monster AI must not damage an airborne target above its height range.
	game.dungeon_stage = "combat"
	game.monsters.clear()
	var attacker := enemy(game, Vector2(10, 0))
	attacker.engaged = true
	attacker.attack = 10
	attacker.attack_cooldown = 0.0
	attacker.attack_range_height = 20.0
	game.monsters.append(attacker)
	game.character_height_px = 21.0
	var health_before: float = game.current_health
	game._update_monster_ai(0.01)
	assert(game.current_health == health_before)
	game.character_height_px = 20.0
	attacker.model_resource = "res://assets/character/art/monsters/101-wind-slime/monster_101-data.tres"
	for key in ["attack1", "attack2"]:
		game.monster_actions.rows[attacker.character_id][key].animation = {"library": attacker.model_resource, "name": "attack_1"}
		game.monster_actions.rows[attacker.character_id][key].upper = {"file": "skilleffect_jd_dg1.json", "animation": "attack2"}
		game.monster_actions.rows[attacker.character_id][key].lower = null
	game._update_monster_ai(0.01)
	assert(game.current_health == health_before, "起手不立即结算伤害")
	game.monster_actions.advance(attacker, 0.75)
	assert(game.current_health < health_before)
	# Hit stop freezes attacker/effects and the actual victim, not a miss.
	game.character_height_px = 0.0
	attacker.hp = 10000
	game._on_skill_effect_hit(2001, 1.0, 250, 0, 100)
	assert(is_zero_approx(actions.hit_stop_remaining))
	game._on_skill_effect_hit(2001, 250, 250, 0, 100)
	assert(is_equal_approx(actions.hit_stop_remaining, 0.1))
	assert(is_equal_approx(attacker.hit_stop_remaining, 0.1))
	assert(game.traveler.get_animation_state().get_time_scale() == 0.0)
	var elapsed_before: float = actions.action_elapsed
	actions.advance(0.05, game.player, 1)
	assert(actions.action_elapsed == elapsed_before)
	assert(is_zero_approx(actions.consume_hit_stop(0.04)))
	assert(is_equal_approx(actions.consume_hit_stop(0.08), 0.02))
	assert(game.traveler.get_animation_state().get_time_scale() == 1.0)
	game.queue_free()
	await process_frame
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(account)
	print("SKILL_HIT_TEST_OK")
	quit()
