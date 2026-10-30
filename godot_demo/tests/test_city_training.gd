extends SceneTree

var game

func _initialize() -> void:
	call_deferred("run")

func reset_target(target: Dictionary) -> void:
	if not target.has("damage_reaction"):
		target.damage_reaction = game.DamageReactionScript.new()
	target.damage_reaction.reset()
	target.character_height_px = 0.0
	target.hit = 0.0
	target.hit_stop_remaining = 0.0
	game.monster_actions.play(target, "idle", true)
	game.character_actions.hit_stop_remaining = 0.0
	game.player = Vector2(target.pos) - Vector2(40, 0)
	game.facing = 1.0
	game.character_height_px = 0.0
	game.current_health = 100.0
	game._update_traveler()

func run() -> void:
	game = load("res://main.tscn").instantiate()
	var account := "/private/tmp/city-training-%d.json" % OS.get_process_id()
	game.account_store = account
	root.add_child(game)
	game.set_process(false)
	await process_frame
	game._enter_city(false)
	game.traveler.show()
	assert(game.monsters.size() == 1)
	var target: Dictionary = game.monsters[0]
	assert(target.hp == 20 and target.max_hp == 20)
	assert(is_equal_approx(float(target.pos.x), game.CITY_WIDTH * 0.5))
	assert(game._is_point_in_city_walkable_area(target.pos))
	var profile: Dictionary = game.character_profiles.profile(target.character_id)
	assert(target.hit_pushback_distance_px == float(profile.get("hitPushbackDistancePx", 40.0)))
	assert(target.can_be_launched == bool(profile.get("canBeLaunched", true)))
	game.player_stats.crit_rate = 0.0
	game.player_stats.attack = 1
	reset_target(target)
	var origin: Vector2 = target.pos
	game._process(1.0)
	assert(target.pos == origin and not target.engaged and not target.moving)
	assert(game.current_health == 100.0 and target.action_state.key == "idle")
	game._update_traveler()
	assert(target.render_canvas != null and target.native_spine_sprite != null)
	assert(game.character_shadows.characters.size() == 2)
	# Shared real hit logic: width/depth boundaries and one hit per window still apply.
	game.player = origin - Vector2(80.0 + float(target.hurtbox_x) * 0.5 + 0.1, 0)
	var ledger: Array = []
	game._on_skill_effect_hit(2001, 80, 30, 100, 0, ledger)
	assert(ledger.is_empty() and game.damage_floaters.is_empty())
	game.player.x += 0.1
	game._on_skill_effect_hit(2001, 80, 30, 100, 0, ledger)
	assert(ledger.size() == 1 and game.damage_floaters.size() == 1)
	assert(target.hp == 20, "Health is already full before the damage callback returns")
	game._on_skill_effect_hit(2001, 80, 30, 100, 0, ledger)
	assert(game.damage_floaters.size() == 1, "Instant refill must not bypass the hit-window ledger")
	game.player.y = origin.y + 30.1
	ledger = []
	game._on_skill_effect_hit(2001, 80, 30, 100, 0, ledger)
	assert(ledger.is_empty())
	# Small hits push normally; only autonomous locomotion and AI attacks are disabled.
	reset_target(target)
	game.player_stats.attack = 5
	game._apply_attack_damage(100, 30, 100)
	assert(target.hp == 20 and target.damage_reaction.is_pushed())
	game.city_training.advance(0.06, game.monsters, game.monster_actions, game._clamp_point_to_city_walkable_area)
	assert(target.pos.x > origin.x)
	game.city_training.advance(2.0, game.monsters, game.monster_actions, game._clamp_point_to_city_walkable_area)
	game.city_training.advance(0.0, game.monsters, game.monster_actions, game._clamp_point_to_city_walkable_area)
	var resting: Vector2 = target.pos
	game.city_training.advance(1.0, game.monsters, game.monster_actions, game._clamp_point_to_city_walkable_area)
	assert(target.pos == resting, "It must neither chase the player nor snap back after pushback")
	# Lethal-sized hits are nonlethal but still produce the normal launched reaction.
	reset_target(target)
	game.player_stats.attack = 100000
	game._apply_attack_damage(100, 30, 100)
	assert(target.hp == 20 and game.monsters.size() == 1 and game.monster_actions.corpses.is_empty())
	assert(target.damage_reaction.knockback_remaining > 0.0)
	assert(target.action_state.key == "floated")
	game.city_training.advance(0.1, game.monsters, game.monster_actions, game._clamp_point_to_city_walkable_area)
	assert(float(target.character_height_px) > 0.0 and target.pos.x > resting.x)
	assert(game.ground_loot.entries.is_empty() and game.pending_dungeon_experience == 0)
	# Button and keyboard both start native attacks in the city, with real VFX hits.
	game._enter_city(false)
	target = game.monsters[0]
	reset_target(target)
	game.attack_cooldown = 0.0
	game.character_actions.rows[2001].upper = {"file": "skilleffect_jd_dg1.json", "animation": "attack1"}
	game.character_actions.rows[2001].lower = null
	game.character_actions.rows[2001].advanceDistancePx = 0.0
	game.character_actions.rows[2001].hitStopMs = 0.0
	game.player_stats.attack = 1
	game._primary_action()
	assert(game.character_actions.active_id == 2001)
	game._process(0.12)
	assert(target.hp == 20 and not game.damage_floaters.is_empty())
	game._enter_city(false)
	game.attack_cooldown = 0.0
	var key := InputEventKey.new()
	key.keycode = KEY_J
	key.pressed = true
	game._unhandled_key_input(key)
	assert(game.character_actions.active_id == 2001)
	game._enter_city(false)
	game.attack_cooldown = 0.0
	game._jump()
	game._attack()
	assert(game.attack_action_id == 2004)
	game._enter_city(false)
	game.attack_cooldown = 0.0
	game.dodge_cooldown = 0.0
	game._dodge()
	game._move_player(game.DODGE_DURATION * 0.6)
	game._attack()
	game._move_player(game.DODGE_DURATION * 0.4 + 0.001)
	assert(game.attack_action_id == 2005)
	game._enter_dungeon()
	assert(game.monsters.all(func(monster): return not game.CityTrainingScript.is_target(monster)))
	game._enter_city(false)
	assert(game.monsters.size() == 1 and game.monsters[0].hp == 20)
	game.player = game.city_portal_trigger_position
	game._primary_action()
	assert(game.modal_mode == "dungeon_select", "Portal interaction remains available")
	game.queue_free()
	await process_frame
	DirAccess.remove_absolute(account)
	print("CITY_TRAINING_TEST_OK")
	quit()
