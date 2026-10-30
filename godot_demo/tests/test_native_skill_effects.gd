extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	game.account_store = "/private/tmp/native-skill-effects-%d.json" % OS.get_process_id()
	root.add_child(game)
	game.set_process(false)
	await process_frame
	game._enter_city(false)
	game._enter_dungeon()
	game.monsters.clear()
	game.dungeon_stage = "wave_delay"
	game.dungeon_next_wave_timer = 1000.0
	game.player = Vector2(1200,650)
	game.facing = 1.0
	game.traveler.show()
	game._update_traveler()
	var actions = game.character_actions
	# Check every catalog resource through Godot's loader, rather than merely
	# validating that the JSON text is readable by the web editor.
	for file in actions.library.effects:
		var data = load(str(file.resource)) as SpineSkeletonDataResource
		assert(data != null and data.is_skeleton_data_loaded(), "An editor-selectable effect must load in the game")
		for animation in file.animations:
			assert(data.find_animation(animation) != null)
	# Reproduce saved attacks using the real main-scene process and actual source
	# action events. No event injection or replacement config can hide loader bugs.
	for id in [2001,2002,2003,2004,2005]:
		for repeat in range(3):
			actions.clear_effects()
			game._start_attack_action(id)
			game._process(0.05)
			var expected := 0
			for layer in ["upper","lower"]:
				if actions.rows[id].get(layer) != null:
					expected += 1
			assert(actions.effects.size() == expected, "Saved attacks must spawn their effects on every cast")
			for effect in actions.effects:
				assert(effect.get_parent() == game and effect.is_visible_in_tree())
				assert(effect.scale.abs() == Vector2.ONE)
				assert(effect.position.is_equal_approx(game.traveler.position))
				var track = effect.get_animation_state().get_track(0)
				assert(track != null and is_equal_approx(track.get_track_time(), 0.05))
			game._process(1.0)
			assert(actions.effects.is_empty(), "Completed native effects are released")
	# Both planes use native Spine, at authored scale and the same feet origin.
	actions.rows[2001].upper = {"file":"skilleffect_jd_dg1.json","animation":"attack1"}
	actions.rows[2001].lower = {"file":"skilleffect_jd_dg1.json","animation":"attack2"}
	game._start_attack_action(2001)
	game._process(0.05)
	assert(actions.effects.size() == 2)
	assert(actions.effects[0].z_index == actions.SceneDepth.UPPER_EFFECT_Z)
	assert(actions.effects[1].z_index == actions.SceneDepth.LOWER_EFFECT_Z)
	game.queue_free()
	await process_frame
	DirAccess.remove_absolute("/private/tmp/native-skill-effects-%d.json" % OS.get_process_id())
	print("NATIVE_SKILL_EFFECTS_TEST_OK")
	quit()
