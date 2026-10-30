extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	game.account_store = "/private/tmp/hit-stop-timing-%d.json" % OS.get_process_id()
	root.add_child(game)
	game.set_process(false)
	await process_frame
	game._enter_city(false)
	game._enter_dungeon()
	game.monsters.clear()
	game.player = Vector2(1200, 650)
	var target: Dictionary = game._monster_definition(0, game.player + Vector2(100, 0), "Hit stop timing", 0, 1)
	target.active = true
	target.hp = 10000
	target.max_hp = 10000
	target.hurtbox_x = 60.0
	target.hurtbox_h = 130.0
	game.monsters.append(target)
	var actions = game.character_actions
	actions.rows[2001].attackDistancePx = 250.0
	actions.rows[2001].longitudinalRangePx = 60.0
	actions.rows[2001].heightRangePx = 130.0
	actions.rows[2001].hitStopMs = 100.0
	actions.rows[2001].upper = {"file": "skilleffect_jd_dg1.json", "animation": "attack2"}
	actions.rows[2001].lower = {"file": "skilleffect_jd_dg1.json", "animation": "attack2"}
	actions.library.character.animations[actions.rows[2001].animation].events = [{"name": "action", "time": 0.0}]
	var clip: Dictionary = actions._effect_clip(actions.rows[2001].upper)
	var start: float = clip.events[0].time
	assert(start == 0.03333333, "Exercise the source's rounded 30 FPS event time")
	actions.play(2001, true)
	actions.advance(start - 0.001, game.player, 1.0)
	assert(target.hp == 10000 and actions.hit_stop_remaining == 0.0)
	assert(is_equal_approx(actions.effects[0].get_animation_state().get_track(0).get_track_time(), start - 0.001))
	actions.advance(0.001, game.player, 1.0)
	assert(target.hp < 10000 and is_equal_approx(actions.hit_stop_remaining, 0.1))
	var hp: int = target.hp
	var track = game.traveler.get_animation_state().get_track(0)
	assert(is_equal_approx(track.get_track_time(), start), "Native attacker pose reaches hit_start before freezing")
	for effect in actions.effects:
		assert(is_equal_approx(effect.get_animation_state().get_track(0).get_track_time(), start), "Neither native effect may freeze before hit_start")
		assert(is_equal_approx(float(effect.get_meta("hit_context").elapsed), start))
	# Native rendering must not independently advance or consume another engine delta.
	await process_frame
	await process_frame
	assert(is_equal_approx(track.get_track_time(), start))
	actions.advance(actions.consume_hit_stop(0.04), game.player, 1.0)
	assert(is_equal_approx(track.get_track_time(), start) and target.hp == hp)
	var remainder: float = actions.consume_hit_stop(0.08)
	assert(is_equal_approx(remainder, 0.02))
	actions.advance(remainder, game.player, 1.0)
	assert(is_equal_approx(track.get_track_time(), start + 0.02), "Only the unfrozen remainder advances the native pose")
	assert(is_equal_approx(track.get_track_time(), actions.action_elapsed))
	assert(target.hp == hp, "Hit stop cannot reset a window's hit ledger")
	# A target entering an already-open window must freeze at the actual hit sample,
	# never rewind to hit_start or the preceding sample.
	actions.clear_effects()
	target.pos = game.player + Vector2(1000, 0)
	actions.play(2001, true)
	actions.advance(0.09, game.player, 1.0)
	assert(actions.hit_stop_remaining == 0.0 and target.hp == hp)
	target.pos = game.player + Vector2(100, 0)
	actions.advance(0.02, game.player, 1.0)
	assert(target.hp < hp and actions.hit_stop_remaining > 0.0)
	track = game.traveler.get_animation_state().get_track(0)
	assert(is_equal_approx(track.get_track_time(), 0.11))
	for effect in actions.effects:
		assert(is_equal_approx(effect.get_animation_state().get_track(0).get_track_time(), 0.11))
		assert(is_equal_approx(float(effect.get_meta("hit_context").elapsed), 0.11))
	# During hit stop, buffered input must leave the current pose and VFX frozen.
	actions.clear_effects()
	game.dungeon_stage = "wave_delay"
	game.dungeon_next_wave_timer = 1000.0
	game.modal.hide()
	target.pos = game.player + Vector2(100, 0)
	actions.library.character.animations[actions.rows[2001].animation].events = [{"name": "action", "time": 0.0}, {"name": "actionEnd", "time": 0.2}]
	game._start_attack_action(2001)
	actions.advance(0.1, game.player, 1.0)
	assert(actions.hit_stop_remaining > 0.0)
	var serial: int = actions.playback_serial
	var effect_count: int = actions.effects.size()
	game._attack()
	game._attack()
	assert(actions.combo_attack_queued and actions.playback_serial == serial)
	actions.advance(actions.consume_hit_stop(0.04), game.player, 1.0)
	assert(actions.active_id == 2001 and actions.effects.size() == effect_count)
	actions.advance(actions.consume_hit_stop(0.061), game.player, 1.0)
	actions.advance(0.101, game.player, 1.0)
	assert(actions.active_id == 2002 and not actions.combo_attack_queued)
	track = game.traveler.get_animation_state().get_track(0)
	assert(is_zero_approx(track.get_mix_duration()), "The next segment must not retain the frozen previous pose while its VFX starts")
	actions.advance(0.0, game.player, 1.0)
	assert(track.get_animation().get_name() == actions.rows[2002].animation)
	var next_effects := 0
	for effect in actions.effects:
		if int(effect.get_meta("hit_context").serial) == actions.playback_serial:
			next_effects += 1
			assert(is_equal_approx(effect.get_animation_state().get_track(0).get_track_time(), track.get_track_time()))
	assert(next_effects > 0, "The next action event must play VFX with its own native pose")
	# A frame can cross actionEnd at the same time a late hit begins hit stop.
	# Keep the queued segment pending until that freeze has finished.
	actions.clear_effects()
	target.pos = game.player + Vector2(1000, 0)
	game._start_attack_action(2001)
	actions.advance(0.08, game.player, 1.0)
	game._attack()
	assert(actions.combo_attack_queued)
	target.pos = game.player + Vector2(100, 0)
	actions.advance(0.13, game.player, 1.0)
	assert(actions.hit_stop_remaining > 0.0)
	assert(actions.active_id == 2001 and not actions.action_end_emitted, "A hit-stop frame cannot release the next action before its frozen pose")
	game._attack()
	actions.advance(actions.consume_hit_stop(0.04), game.player, 1.0)
	assert(actions.active_id == 2001)
	actions.advance(actions.consume_hit_stop(0.061), game.player, 1.0)
	assert(actions.active_id == 2002 and is_zero_approx(actions.hit_stop_remaining))
	# Exercise the real frame order: attack advance, hit stop, then camera follow.
	for direction in [1.0, -1.0]:
		actions.clear_effects()
		game.monsters.clear()
		game.player = Vector2(1200, 650)
		game.camera_x = 0.0
		game.camera_y = 0.0
		game.facing = direction
		game._update_traveler()
		target = game._monster_definition(0, game.player + Vector2(direction * 100, 0), "Frozen alignment", 0, 1)
		target.active = true
		target.hp = 10000
		target.max_hp = 10000
		target.hurtbox_x = 60.0
		target.hurtbox_h = 130.0
		game.monsters.append(target)
		actions.rows[2001].advanceDistancePx = 40.0
		actions.rows[2001].advanceDurationMs = 100.0
		game._start_attack_action(2001)
		game._process(0.04)
		assert(actions.hit_stop_remaining > 0.0 and actions.effects.size() == 2)
		var frozen_position: Vector2 = game.player
		var frozen_elapsed: float = actions.action_elapsed
		var frozen_hp: int = target.hp
		var camera_before: float = game.camera_x
		for frame in range(3):
			if frame > 0:
				game._process(0.02)
			assert(game.player.is_equal_approx(frozen_position))
			assert(is_equal_approx(actions.action_elapsed, frozen_elapsed) and target.hp == frozen_hp)
			for effect in actions.effects:
				assert(effect.position.is_equal_approx(game.traveler.position), "Frozen upper/lower effects must follow the same screen origin as the player")
				assert((effect.position + Vector2(game.camera_x, game.camera_y)).is_equal_approx(game.player - Vector2(0, game.character_height_px)), "Camera smoothing cannot move frozen effects in world space")
				assert(effect.scale == Vector2(direction, 1.0))
				assert(is_equal_approx(effect.get_animation_state().get_track(0).get_track_time(), frozen_elapsed), "Alignment must not advance the frozen animation")
		assert(not is_equal_approx(game.camera_x, camera_before), "The regression must exercise a camera that continues moving during hit stop")
	game.queue_free()
	await process_frame
	DirAccess.remove_absolute("/private/tmp/hit-stop-timing-%d.json" % OS.get_process_id())
	print("HIT_STOP_TIMING_TEST_OK")
	quit()
