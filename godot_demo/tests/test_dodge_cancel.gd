extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func reset_input_state(game) -> void:
	game.character_actions.clear_effects()
	game.monsters.clear()
	game.modal.hide()
	game.damage_reaction.reset()
	game.hurt_remaining = 0.0
	game.getup_remaining = 0.0
	game.getup_roll_remaining = 0.0
	game.is_jumping = false
	game.jump_elapsed = 0.0
	game.character_height_px = 0.0
	game.dodge_remaining = 0.0
	game.dodge_cooldown = 0.0
	game.attack_anim = 0.0
	game.attack_cooldown = 0.0
	game.player = Vector2(1600, 650)
	game.facing = 1.0
	game._update_traveler()

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	var account := "/private/tmp/dodge-cancel-%d.json" % OS.get_process_id()
	game.account_store = account
	root.add_child(game)
	game.set_process(false)
	await process_frame
	game._enter_city(false)
	var actions = game.character_actions
	for state in ["city", "dungeon"]:
		if state == "dungeon":
			game._enter_dungeon()
			game.dungeon_stage = "wave_delay"
			game.dungeon_next_wave_timer = 1000.0
		for id in [2001, 2002, 2003, 2004, 2005]:
			for elapsed in [0.0, 0.1, 0.45]:
				reset_input_state(game)
				actions.rows[id].upper = {"file": "skilleffect_jd_dg1.json", "animation": "attack2"}
				actions.rows[id].lower = {"file": "chuanson_fuben.spine-json", "animation": "2"}
				game._start_attack_action(id)
				if elapsed > 0.0:
					actions.advance(elapsed, game.traveler.position, game.facing)
				var cancelled_effects: Array = actions.effects.duplicate()
				# Also exercise the input while the attack is frozen and a combo is buffered.
				actions.queue_combo_attack()
				actions.start_hit_stop(200.0)
				game._dodge()
				assert(actions.active_id == 1006 and game.dodge_remaining == game.DODGE_DISTANCE)
				assert(game.attack_anim == 0.0 and game.attack_cooldown == 0.0 and game.combo_input_remaining == 0.0)
				assert(not actions.combo_attack_queued and actions.effects.is_empty() and actions.hit_stop_remaining == 0.0)
				var track = game.traveler.get_animation_state().get_track(0)
				assert(track.get_animation().get_name() == actions.rows[1006].animation and is_zero_approx(track.get_mix_duration()))
				for effect in cancelled_effects:
					assert(not effect.visible, "Cancelled VFX disappear on the input frame, before deferred deletion")
				var origin: Vector2 = game.player
				game._process(0.02)
				assert(game.player.x > origin.x and actions.active_id == 1006, "Hit stop must not delay the cancelling dodge")
				assert(actions.effects.all(func(effect): return int(effect.get_meta("hit_context").skill.id) == 1006), "Cancelled attacks cannot resume their hit windows")
		# Clicks in every part of the dodge cancel it at the current position.
		for fraction in [0.0, 0.25, 0.5, 0.9]:
			reset_input_state(game)
			game._dodge()
			game._process(game.DODGE_DURATION * fraction)
			var origin: Vector2 = game.player
			game.attack_cooldown = 10.0
			Input.action_press("ui_left")
			game._attack()
			Input.action_release("ui_left")
			assert(game.player == origin and game.dodge_remaining == 0.0 and game.dodge_elapsed == 0.0)
			assert(actions.active_id == 2005 and game.attack_action_id == 2005 and game.facing == -1.0)
			assert(is_equal_approx(game.attack_anim, actions.duration(2005)))
			var track = game.traveler.get_animation_state().get_track(0)
			assert(track.get_animation().get_name() == actions.rows[2005].animation and is_zero_approx(track.get_mix_duration()))
			actions.rows[2005].advanceDistancePx = 40.0
			actions.rows[2005].advanceDurationMs = 80.0
			game._process(0.04)
			assert(is_equal_approx(game.player.x, origin.x - 20.0), "Only dodge-attack advance applies after cancellation")
			game._process(0.04)
			assert(is_equal_approx(game.player.x, origin.x - 40.0))
			# The same dodge cooldown remains in force after cancelling into an attack.
			var serial: int = actions.playback_serial
			game._dodge()
			assert(actions.playback_serial == serial and game.dodge_remaining == 0.0)
		# Hurt/knockdown controls still take precedence over cancel requests.
		reset_input_state(game)
		game._start_attack_action(2001)
		game.hurt_remaining = 0.2
		game._dodge()
		assert(actions.active_id == 2001 and game.dodge_remaining == 0.0)
		game.hurt_remaining = 0.0
		game.damage_reaction.down_remaining = 0.2
		game._dodge()
		assert(actions.active_id == 2001 and game.dodge_remaining == 0.0)
	game.queue_free()
	await process_frame
	DirAccess.remove_absolute(account)
	print("DODGE_CANCEL_TEST_OK")
	quit()
