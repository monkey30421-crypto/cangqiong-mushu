extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func check_follow(game, background: Node2D) -> void:
	game.monsters.clear()
	# Freeze locomotion to inspect camera tracking independently of walkable polygons.
	game.modal.show()
	for sample in [[400.0, 0.0], [500.0, 0.0], [650.0, 100.0], [1000.0, 450.0], [1100.0, 450.0], [900.0, 350.0], [650.0, 100.0], [400.0, 0.0]]:
		game.player = Vector2(1200, sample[0])
		game._process(0.0)
		assert(is_equal_approx(game.camera_y, sample[1]), "Camera stops at both edges and resumes following toward the interior")
		assert(background.position.y == -game.camera_y)
		assert(game.traveler.position.y == game.player.y - game.camera_y, "Player rendering stays aligned when the camera stops")
		assert(game.hit_effects.position.y == -game.camera_y, "Impact effects use the same bounded camera")
	# Airborne artwork must not move the camera away from its ground position.
	game.player.y = 650.0
	game.character_height_px = 200.0
	game._process(0.0)
	assert(game.camera_y == 100.0)
	assert(game.traveler.position.y == 350.0)
	game.character_height_px = 0.0

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	game.account_store = "/private/tmp/camera-bounds-%d.json" % OS.get_process_id()
	root.add_child(game)
	game.set_process(false)
	await process_frame
	game.city_walkable_polygon = PackedVector2Array([Vector2.ZERO, Vector2(5400, 0), Vector2(5400, 1200), Vector2(0, 1200)])
	for spawn_y in [100.0, 1100.0]:
		game.city_spawn_rect = Rect2(200, spawn_y, 1, 1)
		game._enter_city(false)
		assert(game.camera_y == (0.0 if spawn_y == 100.0 else 450.0), "City entry must already respect both edges")
	check_follow(game, game.city_background)
	game._enter_dungeon()
	assert(game.camera_y >= 0.0 and game.camera_y <= 450.0, "Dungeon entry must be bounded before its first frame")
	check_follow(game, game.dungeon_background)
	game.queue_free()
	await process_frame
	DirAccess.remove_absolute("/private/tmp/camera-bounds-%d.json" % OS.get_process_id())
	print("CAMERA_BOUNDS_TEST_OK")
	quit()
