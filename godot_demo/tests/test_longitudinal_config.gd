extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var path := "/private/tmp/longitudinal-%d.json" % OS.get_process_id()
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://config/character_actions.json"))
	for row in config.rows:
		if row.id == 2001:
			row.longitudinalRangePx = 10.0
			row.hitStopMs = 0.0
	config.revision += 1000
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(config))
	file.close()
	var game = load("res://main.tscn").instantiate()
	game.character_action_store = path
	root.add_child(game)
	game.set_process(false)
	await process_frame
	game.state = "dungeon"
	game.dungeon_stage = "combat"
	game.modal.hide()
	game.player = Vector2(1200, 650)
	game.facing = 1.0
	var monster: Dictionary = game._monster_definition(0, game.player + Vector2(20, 30), "纵向测试", 0, 1)
	monster.active = true
	monster.hp = 10000
	monster.max_hp = 10000
	game.monsters.clear()
	game.monsters.append(monster)
	assert(game.character_actions.rows[2001].longitudinalRangePx == 10.0)
	game._start_attack_action(2001)
	game.character_actions.advance(0.15, game.player, 1.0)
	assert(monster.hp == 10000, "30 px ground separation must miss with 10 px longitudinal range")
	for row in config.rows:
		if row.id == 2001:
			row.longitudinalRangePx = 60.0
	config.revision += 1
	file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(config))
	file.close()
	game.character_actions.clear_effects()
	assert(game.character_actions.reload_config())
	assert(game.character_actions.rows[2001].longitudinalRangePx == 60.0)
	game._start_attack_action(2001)
	game.character_actions.advance(0.15, game.player, 1.0)
	assert(monster.hp < 10000, "Hot-reloaded 60 px range must hit the same monster at 30 px")
	game.queue_free()
	await process_frame
	DirAccess.remove_absolute(path)
	print("LONGITUDINAL_CONFIG_TEST_OK")
	quit()
