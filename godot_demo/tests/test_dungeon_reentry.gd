extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func open_start_altar(game) -> void:
	var tree_position: Vector2 = game._current_dungeon_altar_tree_position()
	game.camera_x = tree_position.x - game.VIEW_WIDTH * 0.5
	game.camera_y = tree_position.y - game.VIEW_HEIGHT * 0.5
	game._update_dungeon_altar_tree()
	assert(game.dungeon_altar_tree_state == "activating", "A fresh challenge must activate its own starting altar")
	game._on_altar_tree_animation_finished()
	game.player = game._current_dungeon_polygon("altar")[0]
	game._update_interact_button()
	assert(game.interact_button.visible)
	game._interact()
	assert(game.modal.visible and game.modal_mode == "altar")
	game._on_modal_primary()
	assert(game.dungeon_stage == "portals" and game.dungeon_altar_tree_state == "talked")
	assert(not game.dungeon_available_targets.is_empty())

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	game.account_store = "/private/tmp/dungeon-reentry-%d.json" % OS.get_process_id()
	root.add_child(game)
	game.set_process(false)
	await process_frame
	for attempt in range(3):
		game._enter_dungeon()
		assert(game.dungeon_altar_tree_talked_nodes.is_empty(), "A new challenge cannot inherit last run's completed conversations")
		assert(game.dungeon_altar_tree_activated_nodes.is_empty())
		assert(game.dungeon_altar_tree_state == "locked" and game.dungeon_stage == "await_altar")
		open_start_altar(game)
		# Flags remain valid within this challenge.
		game._reset_dungeon_altar_tree_for_current_node()
		assert(game.dungeon_altar_tree_state == "talked")
		game._enter_dungeon_target(game.dungeon_available_targets[0])
		game._damage_player(int(game.current_health) + 1)
		assert(game.dungeon_stage == "dead" and game.modal_mode == "settlement")
		game._on_modal_primary()
		assert(game.state == "city" and not game.modal.visible)
		assert(game.current_health == game._get_player_stat("max_health"))
	# A run abandoned mid-activation must also start fresh next time.
	game._enter_dungeon()
	var tree_position: Vector2 = game._current_dungeon_altar_tree_position()
	game.camera_x = tree_position.x - game.VIEW_WIDTH * 0.5
	game.camera_y = tree_position.y - game.VIEW_HEIGHT * 0.5
	game._update_dungeon_altar_tree()
	game.altar_tree_activation_elapsed = game.ALTAR_TREE_ACTIVATE_DURATION * 0.5
	game._finish_dungeon(false)
	game._enter_dungeon()
	assert(game.altar_tree_activation_elapsed == 0.0)
	open_start_altar(game)
	game.queue_free()
	await process_frame
	DirAccess.remove_absolute("/private/tmp/dungeon-reentry-%d.json" % OS.get_process_id())
	print("DUNGEON_REENTRY_TEST_OK")
	quit()
