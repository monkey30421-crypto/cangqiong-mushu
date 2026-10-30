extends SceneTree

const Actions = preload("res://modules/monster_actions.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var actions := Actions.new()
	assert(actions.load_config())
	var monster := {"character_id": 101, "model_resource": "res://assets/character/art/monsters/101-wind-slime/monster_101-data.tres", "pos": Vector2(1000, 650), "hp": 100, "hit": 0.0, "facing": 1.0}
	for direction in [-1.0, 1.0]:
		var target := Vector2(1000 + direction * 200, 650)
		for forward in [true, false]:
			var motion := Vector2(direction * (10.0 if forward else -10.0), 3.0)
			actions.update_movement(monster, target, motion)
			actions.advance(monster, 0.0)
			var key := "move_front" if forward else "move_back"
			assert(monster.facing == direction, "Retreating never turns away from the target")
			assert(monster.action_state.key == key)
			assert(actions._native_animation_name(monster, key) == key)
			assert(key in actions.LOOP_KEYS)
	actions.update_movement(monster, Vector2(1200, 650), Vector2.ZERO)
	actions.advance(monster, 0.0)
	assert(monster.action_state.key == "idle" and monster.facing == 1.0, "Blocked movement does not play a movement loop")
	actions.update_movement(monster, Vector2(1000, 700), Vector2(0, 10))
	actions.advance(monster, 0.0)
	assert(monster.action_state.key == "move_front" and monster.facing == 1.0, "Depth-only movement preserves facing")
	# Legacy move mappings keep all data when converted to forward; backward is independent.
	var old: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Actions.CONFIG_PATH))
	for entry in old.monsters:
		entry.actions = entry.actions.filter(func(row): return row.key != "move_back")
		for row in entry.actions:
			if row.key in ["move", "move_front"]:
				row.key = "move"
				row.upper = {"file": "skilleffect_jd_dg1.json", "animation": "attack1"}
	var path := "/private/tmp/monster-movement-%d.json" % OS.get_process_id()
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(old))
	file.close()
	assert(actions.load_config(path))
	assert(actions.rows[101].move_front.upper.animation == "attack1")
	assert(actions.rows[101].move_back.upper == null and not actions.rows[101].has("move"))
	DirAccess.remove_absolute(path)
	# Real AI follows a target on either side and uses the resolved movement direction.
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	await process_frame
	game._enter_dungeon()
	game.dungeon_stage = "combat"
	game.modal.hide()
	game.monsters.clear()
	game.player = Vector2(1200, 650)
	for direction in [-1.0, 1.0]:
		var target: Dictionary = game._monster_definition(0, game.player - Vector2(direction * 220, 0), "移动测试", 0, 1)
		target.active = true
		target.engaged = true
		game.monsters.assign([target])
		var before: Vector2 = target.pos
		game._update_monster_ai(0.1)
		game.monster_actions.advance(target, 0.0)
		assert(target.facing == direction and (target.pos.x - before.x) * direction > 0.0)
		assert(target.action_state.key == "move_front")
		# A target crossing behind the monster must update facing even in the move frame.
		game.player = Vector2(target.pos) - Vector2(direction * 250, 0)
		game._update_monster_ai(0.1)
		assert(target.facing == -direction)
		game.player = Vector2(1200, 650)
	game.queue_free()
	await process_frame
	print("MONSTER_MOVEMENT_TEST_OK")
	quit()
