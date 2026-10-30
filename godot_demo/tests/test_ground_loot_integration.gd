extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	game.account_store = "/private/tmp/ground-loot-integration-%d.json" % OS.get_process_id()
	root.add_child(game)
	game.set_process(false)
	await process_frame
	game._enter_dungeon()
	game.monsters.clear()
	game.dungeon_stage = "wave_delay"
	game.dungeon_next_wave_timer = 100.0
	game.current_health = 100.0
	game.modal.hide()
	game.player = game._clamp_point_to_dungeon_walkable_area(Vector2(1200, 650))
	game.character_profiles.rows[101].drops = [{"itemId": "2001", "probability": 1.0, "minCount": 3, "maxCount": 3}, {"itemId": "1001", "probability": 1.0, "minCount": 10, "maxCount": 10}]
	var monster: Dictionary = game._monster_definition(0, game.player, "掉落测试", 0, 1)
	monster.hp = 0
	monster.hit_stop_remaining = 0.02
	game.monsters.assign([monster])
	game._update_dungeon(0.01)
	assert(game.ground_loot.entries.is_empty(), "Hit-stop delays death processing")
	game._update_dungeon(0.02)
	assert(game.monsters.is_empty() and game.ground_loot.entries.size() == 2)
	assert(game.inventory.slots.is_empty())
	game._update_dungeon(0.01)
	assert(game.ground_loot.entries.size() == 2, "Death processing must not duplicate drops")
	for entry in game.ground_loot.entries.duplicate():
		game.player = entry.ground_pos
		game._process(0.01)
		game._process(0.3)
	assert(game.ground_loot.entries.is_empty() and game.inventory.slots.size() == 3)
	assert(game.inventory.currencies["1001"] == 10)
	game._grant_monster_drops({"pos": game.player, "drops": [{"itemId": "2002", "probability": 1.0}]})
	game._enter_city(false)
	assert(game.ground_loot.entries.is_empty(), "Leaving a room clears its ground loot")
	game.queue_free()
	await process_frame
	DirAccess.remove_absolute("/private/tmp/ground-loot-integration-%d.json" % OS.get_process_id())
	print("GROUND_LOOT_INTEGRATION_TEST_OK")
	quit()
