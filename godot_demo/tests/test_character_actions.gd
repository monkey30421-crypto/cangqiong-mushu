extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func write_config(path: String, value: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(value))

func run() -> void:
	var path := "/private/tmp/character-actions-test-%d.json" % OS.get_process_id()
	var account := "/private/tmp/character-actions-account-%d.json" % OS.get_process_id()
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://config/character_actions.json"))
	config.revision = 10
	config.rows[0].animation = "idle_SingleWeapon"
	for row in config.rows:
		row.upper = null
		row.lower = null
		if int(row.id) >= 2000:
			row.hitStopMs = 0.0
			row.advanceDistancePx = 0.0
	write_config(path, config)
	var game = load("res://main.tscn").instantiate()
	game.character_action_store = path
	game.account_store = account
	root.add_child(game)
	game.set_process(false)
	await process_frame
	assert(game.attack_button.action_mode == BaseButton.ACTION_MODE_BUTTON_PRESS, "Attack input must fire on press, before release can miss the combo window")
	assert(game.traveler.global_scale.abs() == Vector2.ONE, "Character and parents retain native Spine scale")
	var actions = game.character_actions
	assert(actions.rows.size() == actions.NAMES.size() and actions.revision == 10)
	assert(game.traveler.get_animation_state().get_track(0).get_animation().get_name() == "idle_SingleWeapon")
	config.rows[0].animation = "walk1_SingleWeapon"
	config.revision = 11
	write_config(path, config)
	assert(not actions.poll(1.1, false), "An in-progress action must finish before reload")
	assert(actions.poll(0.1, true))
	assert(game.traveler.get_animation_state().get_track(0).get_animation().get_name() == "walk1_SingleWeapon")
	assert(game.status_preview_player.skeleton_data_res == game.traveler.skeleton_data_res)
	assert(game.status_preview_player.get_animation_state().get_track(0).get_animation().get_name() == "walk1_SingleWeapon")
	assert(is_equal_approx(actions.duration(1001), 1.0))
	config.rows[0].animation = "MISSING"
	config.revision = 12
	write_config(path, config)
	assert(not actions.reload_config() and actions.revision == 11, "Invalid reload must preserve last working mapping")
	config.rows[0].animation = "walk1_SingleWeapon"
	config.rows[0].upper = {"file": "chuanson_fuben.spine-json", "animation": "2"}
	config.rows[0].lower = {"file": "skilleffect_jd_dg1.json", "animation": "attack1"}
	write_config(path, config)
	assert(actions.reload_config())
	actions.advance(0.5, Vector2(100, 100), 1)
	assert(actions.effects.is_empty(), "Missing action event must never auto-trigger VFX")
	# Inject an event into test memory only to verify the event-to-two-layers contract.
	actions.library.character.animations.walk1_SingleWeapon.events = [{"name": "action", "time": 0.25}]
	actions.play(1001, true)
	actions.advance(0.3, Vector2(100, 100), -1)
	assert(actions.effects.size() == 2)
	assert(actions.effects[0].z_index == actions.SceneDepth.UPPER_EFFECT_Z and actions.effects[1].z_index == actions.SceneDepth.LOWER_EFFECT_Z)
	assert(actions.effects[0].position == Vector2(100, 100) and actions.effects[0].scale.x == -1)
	actions.advance(0.1, Vector2(120, 100), 1)
	assert(actions.effects.size() == 2, "Same event must not trigger twice")
	actions.clear_effects()
	game.account_name.text = "action_test"
	game._login()
	game.role_name_input.text = "动作测试"
	game._confirm_role_name()
	game._enter_dungeon()
	game._close_modal()
	game.monsters.clear()
	game.dungeon_stage = "wave_delay"
	game.dungeon_next_wave_timer = 1000.0
	game.attack_anim = 0
	game.attack_cooldown = 0
	game.facing = 1.0
	# VFX completion cannot unlock a combo; actionEnd releases controls.
	for id in [2001, 2002, 2003]:
		actions.rows[id].upper = {"file": "skilleffect_jd_dg1.json", "animation": "attack%d" % (id - 2000)}
		actions.rows[id].lower = null
		actions.library.character.animations[actions.rows[id].animation].events = [{"name": "action", "time": 0.0}, {"name": "actionEnd", "time": 0.5}]
		game._start_attack_action(id)
		assert(game.traveler.get_animation_state().get_track(0).get_animation().get_name() == actions.rows[id].animation)
		# The current source effects last up to 1/3s. Sample after they finish,
		# but before the 150ms actionEnd input buffer opens at 0.35s.
		actions.advance(0.34, game.player, 1)
		assert(actions.effects.is_empty() and not actions.can_chain_attack())
		game._attack()
		assert(game.attack_action_id == id and not actions.combo_attack_queued)
		actions.advance(0.1601, game.player, 1)
		assert(game.attack_anim == 0.0 and game.attack_cooldown == 0.0)
		assert(game.traveler.get_animation_state().get_track(0).get_animation().get_name() == actions.rows[id].animation, "actionEnd keeps playing the remaining native pose")
	# A long-running VFX remains alive when the next segment starts.
	actions.clear_effects()
	actions.rows[2001].lower = {"file": "chuanson_fuben.spine-json", "animation": "2"}
	game._start_attack_action(2001)
	actions.advance(0.51, game.player, 1)
	assert(not actions.effects.is_empty() and actions.can_chain_attack())
	game._attack()
	assert(game.attack_action_id == 2002 and actions.active_id == 2002)
	actions.rows[2001].lower = null
	actions.clear_effects()
	game._start_attack_action(2001)
	# Pixel distance / milliseconds drive normal attacks; input cannot add movement.
	actions.rows[2001].advanceDistancePx = 120.0
	actions.rows[2001].advanceDurationMs = 300.0
	actions.play(2001, true)
	actions.advance_facing = 1.0
	assert(is_equal_approx(actions.attack_advance(0.1), 40.0))
	assert(is_equal_approx(actions.attack_advance(0.3), 80.0))
	assert(is_zero_approx(actions.attack_advance(0.1)))
	actions.rows[2001].advanceDistancePx = 0.0
	var before: Vector2 = game.player
	Input.action_press("ui_right")
	game._move_player(0.1)
	assert(game.player == before)
	Input.action_release("ui_right")
	game.is_jumping = false
	game.dodge_remaining = 0.0
	game._jump()
	assert(not game.is_jumping, "Attacks still lock jumping")
	game.dodge_cooldown = 0.0
	game._dodge()
	assert(game.attack_anim == 0.0 and game.dodge_remaining > 0.0 and actions.active_id == 1006, "Dodge cancels the attack immediately")
	game.dodge_remaining = 0.0
	game._jump()
	assert(game.is_jumping)
	game._update_jump(game.JUMP_DURATION * 0.5)
	assert(is_equal_approx(game.character_height_px, game.JUMP_HEIGHT))
	game._update_jump(game.JUMP_APEX_HOLD)
	assert(is_equal_approx(game.character_height_px, game.JUMP_HEIGHT))
	game._update_jump(game.JUMP_DURATION)
	assert(not game.is_jumping and is_zero_approx(game.character_height_px))
	game.dodge_cooldown = 0.0
	game._dodge()
	game._update_traveler()
	assert(actions.active_id == 1006)
	game.dodge_remaining = 0
	game._damage_player(1)
	game._update_traveler()
	assert(actions.active_id == 1007)
	game.attack_anim = 0.0
	game.hurt_remaining = 0.0
	game.is_jumping = false
	game.dodge_remaining = 0.0
	game.dodge_cooldown = 0.0 # 新的输入场景不继承前一场景的闪避冷却。
	game._dodge()
	assert(game.dodge_remaining > 0.0)
	game.monsters.clear()
	game.player = Vector2(1600, 650) # Keep the movement checks away from map edges.
	game.attack_cooldown = 10.0
	Input.action_press("ui_left")
	game._attack()
	assert(game.dodge_remaining == 0.0 and game.dodge_elapsed == 0.0, "Even an immediate first-half click cancels dodge")
	assert(game.attack_action_id == 2005 and actions.active_id == 2005)
	assert(game.traveler.get_animation_state().get_track(0).get_animation().get_name() == actions.rows[2005].animation)
	assert(game.facing == -1.0)
	assert(is_equal_approx(game.attack_anim, game.current_attack_duration), "The new attack starts with its complete duration")
	var dodge_attack_left: float = game.attack_anim
	game._attack()
	assert(game.attack_anim == dodge_attack_left, "Dodge attack cannot chain or restart")
	Input.action_release("ui_left")
	Input.action_press("ui_right")
	Input.action_press("ui_up")
	actions.advance_elapsed = 0.0
	actions.rows[2005].advanceDistancePx = 200.0
	actions.rows[2005].advanceDurationMs = 100.0
	var locked_position: Vector2 = game.player
	game._move_player(0.05)
	game._jump()
	assert(is_equal_approx(game.player.x, locked_position.x - 100.0) and game.player.y == locked_position.y and not game.is_jumping and is_zero_approx(game.dodge_remaining), "Configured advance follows attack facing while directional input stays locked")
	game._process(game.current_attack_duration + 0.01)
	assert(actions.active_id == 1001, "Dodge attack must finish in idle")
	assert(is_equal_approx(game.player.x, locked_position.x - 200.0) and game.player.y == locked_position.y)
	game._move_player(0.01)
	assert(game.is_moving, "Held directions resume movement only after attack ends")
	Input.action_release("ui_right")
	Input.action_release("ui_up")
	# Reproduce the saved 40 px / 80 ms setting through the real process path.
	actions.rows[2005].advanceDistancePx = 40.0
	actions.rows[2005].advanceDurationMs = 80.0
	game.attack_anim = 0.0
	game.attack_cooldown = 0.0
	game.facing = 1.0
	game.dodge_cooldown = 0.0
	game._dodge()
	game._move_player(game.DODGE_DISTANCE * 0.6 / game.DODGE_SPEED)
	game._attack()
	var attack_origin: float = game.player.x
	assert(game.dodge_remaining == 0.0)
	game._process(0.04)
	assert(is_equal_approx(game.player.x, attack_origin + 20.0), "The first 40 ms applies only the new attack advance")
	game._process(0.04)
	assert(is_equal_approx(game.player.x, attack_origin + 40.0), "Saved 80 ms setting must advance exactly 40 px")
	game._process(0.1)
	assert(is_equal_approx(game.player.x, attack_origin + 40.0), "Advance stops at the configured distance")
	# With no held direction, cancelling dodge retains its facing.
	game.attack_anim = 0.0
	game.attack_cooldown = 0.0
	game.facing = 1.0
	game.dodge_cooldown = 0.0
	game._dodge()
	game._move_player(game.DODGE_DURATION * 0.6)
	game._attack()
	assert(game.attack_action_id == 2005 and game.facing == 1.0 and game.dodge_remaining == 0.0)
	# Airborne attacks select the dedicated animation and cannot chain into ground attacks.
	game.attack_anim = 0.0
	game.attack_cooldown = 0.0
	game.dodge_remaining = 0.0
	actions.clear_effects()
	game._jump()
	game._update_jump(0.1)
	game._attack()
	assert(game.attack_action_id == 2004 and actions.active_id == 2004)
	assert(game.traveler.get_animation_state().get_track(0).get_animation().get_name() == actions.rows[2004].animation)
	game._attack()
	assert(game.attack_action_id == 2004)
	# Jump attack keeps normal keyboard and joystick locomotion.
	var airborne_origin: Vector2 = game.player
	Input.action_press("ui_left")
	game._move_player(0.02)
	Input.action_release("ui_left")
	assert(game.player.x < airborne_origin.x and game.is_moving)
	game._update_traveler()
	assert(actions.active_id == 2004 and game.traveler.get_animation_state().get_track(0).get_animation().get_name() == actions.rows[2004].animation, "Moving must preserve jump attack playback")
	airborne_origin = game.player
	game.joystick_vector = Vector2(1.0, -1.0).normalized()
	game._move_player(0.02)
	game.joystick_vector = Vector2.ZERO
	assert(game.player.x > airborne_origin.x and game.player.y < airborne_origin.y, "Jump attack supports both movement axes")
	airborne_origin = game.player
	game._move_player(0.02)
	assert(game.player == airborne_origin and not game.is_moving, "Released input stops voluntary movement")
	game._update_jump(10.0)
	game._update_traveler()
	assert(actions.active_id == 1001 and game.attack_anim == 0.0, "Landing interrupts jump attack immediately")
	assert(actions.effects.is_empty(), "Landing cancels remaining attack hit windows")
	# Distance-only dodge settings still advance exactly the configured amount.
	actions.rows[2005].advanceDistancePx = 40.0
	actions.rows[2005].advanceDurationMs = 0.0
	actions.advance_facing = 1.0
	actions.play(2005, true)
	assert(is_equal_approx(actions.attack_advance(actions.duration(2005) * 0.5), 20.0))
	assert(is_equal_approx(actions.attack_advance(actions.duration(2005)), 20.0))
	assert(is_zero_approx(actions.attack_advance(1.0)))
	var down_target: Dictionary = game._monster_definition(0, game.player + Vector2(20, 0), "倒地测试", 0, 1)
	down_target.active = true
	down_target.hp = 10000
	down_target.max_hp = 10000
	down_target.damage_reaction = game.DamageReactionScript.new()
	down_target.damage_reaction.receive(3001, 10000, 1.0)
	game.monsters.append(down_target)
	game.facing = 1.0
	var target_before: int = down_target.hp
	game._apply_attack_damage(100, 100, 100)
	assert(down_target.hp < target_before, "Knocked down monsters still take damage")
	game.monsters.clear()
	game.damage_reaction.reset()
	game.current_health = 100.0
	game.player_stats.max_health = 100
	game._start_attack_action(2001)
	game._damage_player(10)
	assert(game.attack_anim == 0.0 and actions.active_id == 1007 and actions.effects.is_empty(), "Damage interrupts attack and effects")
	game._attack()
	assert(game.attack_anim == 0.0, "Hurt action cannot be cancelled by attack input")
	game._damage_player(20)
	assert(game.damage_reaction.down_remaining == 0.0)
	game._damage_player(1)
	assert(actions.active_id == 1013 and game.damage_reaction.down_remaining > 0.0)
	var down_health: float = game.current_health
	game._damage_player(100000)
	assert(game.current_health == down_health, "Player stays invulnerable until recovery")
	game._process(game.damage_reaction.KNOCKBACK_DURATION)
	assert(actions.active_id == 1014, "击飞后落地切换原生落地动作")
	game._enter_city(true)
	game._enter_dungeon()
	game._damage_player(100000)
	game._update_traveler()
	assert(actions.active_id == 1008 and game.dungeon_stage == "dead", "地面致死使用原地死亡动作")
	game.queue_free()
	await process_frame
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(account)
	print("CHARACTER_ACTIONS_TEST_OK")
	quit()
