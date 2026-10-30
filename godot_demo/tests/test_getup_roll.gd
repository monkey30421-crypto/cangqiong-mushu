extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	await process_frame
	game._enter_dungeon()
	game.monsters.clear()
	game.dungeon_stage = "wave_delay"
	game.dungeon_next_wave_timer = 100.0
	game.modal.hide()
	for direction_facing in [1.0, -1.0]:
		for input_direction in [1.0, -1.0]:
			game.damage_reaction.reset()
			game.hurt_remaining = 0.0
			game.getup_roll_remaining = 0.0
			game.getup_roll_direction = 0.0
			game.attack_anim = 0.0
			game.current_health = 100.0
			game.facing = direction_facing
			game.player = game._clamp_point_to_dungeon_walkable_area(Vector2(2400, 650))
			game._damage_player(31)
			assert(game.damage_reaction.down_remaining > 0.0)
			assert(game.getup_roll_facing == direction_facing)
			var key := "ui_right" if input_direction > 0.0 else "ui_left"
			Input.action_press(key)
			game._process(game.damage_reaction.down_remaining - 0.01)
			game._process(0.011)
			var expected_action := 1010 if input_direction == direction_facing else 1011
			assert(game.getup_roll_remaining > 0.0, "Held input starts recovery automatically when knockdown ends")
			assert(game.character_actions.active_id == expected_action)
			assert(game.facing == direction_facing, "Backward rolling preserves the knockdown facing")
			var before: Vector2 = game.player
			game._move_player(0.05)
			assert((game.player.x - before.x) * input_direction > 0.0)
			game._update_traveler()
			assert(game.character_actions.active_id == expected_action)
			assert(signf(game.traveler.scale.x) == direction_facing)
			game._attack()
			game._jump()
			game._dodge()
			assert(game.attack_anim == 0.0 and not game.is_jumping and game.dodge_remaining == 0.0)
			Input.action_release(key)
			game._move_player(game.GETUP_ROLL_DURATION)
			assert(game.getup_roll_remaining == 0.0 and game.facing == direction_facing)
			assert(game.damage_reaction.is_invulnerable(), "Two seconds of protection follow recovery")
	# No held input still recovers in place, without repeating the last roll.
	game.damage_reaction.reset()
	game.current_health = 100.0
	game._damage_player(31)
	game._process(game.damage_reaction.down_remaining + 0.01)
	assert(game.getup_roll_remaining == 0.0 and game.damage_reaction.is_invulnerable())
	assert(game.character_actions.rows[1010].action == "倒地起身前滚")
	assert(game.character_actions.rows[1011].action == "倒地起身后滚")
	game.queue_free()
	await process_frame
	print("GETUP_ROLL_TEST_OK")
	quit()
