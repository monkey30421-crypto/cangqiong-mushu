extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	await process_frame
	game.state = "dungeon"
	game.dungeon_stage = "wave_delay"
	game.dungeon_next_wave_timer = 100.0
	game.modal.hide()
	game.player = Vector2(1200, 650)
	# Even fully finished effects cannot unlock a combo without actionEnd.
	var actions = game.character_actions
	var animation: String = actions.rows[2001].animation
	var original_clip: Dictionary = actions.library.character.animations[animation]
	var clip_without_end := original_clip.duplicate(true)
	clip_without_end.events = clip_without_end.events.filter(func(event): return event.name != "actionEnd")
	actions.library.character.animations[animation] = clip_without_end
	game._start_attack_action(2001)
	actions.advance(actions.duration(2001) - 0.001, game.player, 1.0)
	actions.clear_effects()
	assert(not actions.can_chain_attack(), "Finished effects must not unlock combos without actionEnd")
	game._attack()
	assert(game.attack_action_id == 2001)
	actions.library.character.animations[animation] = original_clip
	for id in [2001, 2002, 2003, 2005]:
		game.character_actions.clear_effects()
		game._start_attack_action(id)
		var clip: Dictionary = game.character_actions.library.character.animations[game.character_actions.rows[id].animation]
		var end_time := -1.0
		for event in clip.events:
			if event.name == "actionEnd":
				end_time = float(event.get("time", 0.0))
		assert(end_time > 0.0)
		game.character_actions.advance(end_time - 0.001, game.player, 1.0)
		assert(game.attack_anim > 0.0)
		game.character_actions.advance(0.0011, game.player, 1.0)
		assert(game.attack_anim == 0.0 and game.attack_cooldown == 0.0, "actionEnd unlocks immediately")
		var serial: int = actions.playback_serial
		game._update_traveler()
		assert(actions.active_id == id and actions.playback_serial == serial, "actionEnd must not cut the attack animation")
		game._process(0.01)
		assert(actions.active_id == id and actions.playback_serial == serial, "The remaining animation continues without restarting")
		game._process(actions.duration(id) - actions.action_elapsed + 0.001)
		assert(actions.active_id == 1001, "Idle starts only after the full attack animation finishes")
		# Restart to verify that deliberate movement can still use the released controls.
		game._start_attack_action(id)
		actions.advance(end_time, game.player, 1.0)
		var position: Vector2 = game.player
		Input.action_press("ui_right")
		game._move_player(0.01)
		game._update_traveler()
		assert(actions.active_id in [1002, 1003], "Movement after actionEnd can interrupt the remaining animation")
		Input.action_release("ui_right")
		assert(game.player.x > position.x)
		if id in [2001, 2002]:
			game._attack()
			assert(game.attack_action_id == id + 1, "Released attack can still chain")
	# Window is measured from the event, including time skipped within a frame.
	for wait in [0.299, 0.301]:
		game.is_jumping = false
		game.character_actions.clear_effects()
		game._start_attack_action(2001)
		game.character_actions.advance(0.2, game.player, 1.0)
		assert(is_equal_approx(game.combo_input_remaining, 0.3))
		game._process(wait)
		game._attack()
		assert(game.attack_action_id == (2002 if wait < 0.3 else 2001), "Only clicks within 300 ms continue the combo")
	game.character_actions.clear_effects()
	game._start_attack_action(2001)
	game.character_actions.advance(0.51, game.player, 1.0)
	assert(game.combo_input_remaining == 0.0, "A large frame must not extend the combo window")
	game._attack()
	assert(game.attack_action_id == 2001)
	# Before the 150 ms window clicks are discarded; the boundary is included.
	game.is_jumping = false
	game.character_actions.clear_effects()
	game._start_attack_action(2001)
	game.character_actions.advance(0.049, game.player, 1.0)
	game._attack()
	assert(not game.character_actions.combo_attack_queued)
	game.character_actions.advance(0.001, game.player, 1.0)
	game._attack()
	game._attack()
	assert(game.character_actions.combo_attack_queued and game.attack_action_id == 2001)
	game._process(0.151)
	assert(game.attack_action_id == 2002 and game.character_actions.active_id == 2002)
	assert(not game.character_actions.combo_attack_queued, "Repeated clicks only queue one segment")
	assert(is_equal_approx(game.attack_anim, game.character_actions.duration(2002)), "New segment cannot lose the previous segment frame duration")
	# The same rule chains the second attack to the third.
	game.character_actions.advance(0.12, game.player, 1.0)
	game._attack()
	assert(game.character_actions.combo_attack_queued)
	game.character_actions.advance(0.15, game.player, 1.0)
	assert(game.attack_action_id == 2003)
	game._attack()
	assert(not game.character_actions.combo_attack_queued, "Third attack cannot queue a fourth")
	# Hurt interruption must discard the saved input.
	game.character_actions.clear_effects()
	game._start_attack_action(2001)
	game.character_actions.advance(0.06, game.player, 1.0)
	game._attack()
	assert(game.character_actions.combo_attack_queued)
	game._damage_player(1)
	assert(not game.character_actions.combo_attack_queued and game.attack_anim == 0.0)
	game.hurt_remaining = 0.0
	game.character_actions.clear_effects()
	game._start_attack_action(2005)
	game.character_actions.advance(0.41, game.player, 1.0)
	game._jump()
	assert(game.is_jumping)
	game._update_traveler()
	assert(actions.active_id == 1004, "A requested jump can interrupt a released ground attack")
	# Air movement stays available while the jump-attack tail plays; landing cancels it.
	var jump_animation: String = actions.rows[2004].animation
	var original_jump_clip: Dictionary = actions.library.character.animations[jump_animation]
	var jump_clip := original_jump_clip.duplicate(true)
	jump_clip.events.append({"name": "actionEnd", "time": 0.1})
	actions.library.character.animations[jump_animation] = jump_clip
	game._start_attack_action(2004)
	actions.advance(0.11, game.player, 1.0)
	game.is_moving = true
	game._update_traveler()
	assert(actions.active_id == 2004 and game.attack_anim == 0.0)
	game._update_jump(game.JUMP_DURATION + game.JUMP_APEX_HOLD)
	assert(actions.active_id == 1001 and not game.is_jumping, "Landing still interrupts a released jump attack immediately")
	actions.library.character.animations[jump_animation] = original_jump_clip
	game.queue_free()
	await process_frame
	print("ACTION_END_TEST_OK")
	quit()
