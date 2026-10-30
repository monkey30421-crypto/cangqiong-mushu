extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	await process_frame
	game.camera_x = 100.0
	game.camera_y = 50.0
	var monster: Dictionary = game._monster_definition(0, Vector2(500, 650), "显示测试", 1.0, 1)
	monster.active = false # Native body can be placed without drawing the HP/name canvas.
	monster.spawn_alpha = 1.0
	game.monster_actions.play(monster, "idle")
	for elapsed in [0.0, 0.4, 1.0, 2.0]:
		monster.visual_elapsed = elapsed
		game._draw_monster(monster)
		assert(monster.native_spine_sprite.position == Vector2(400, 600), "Idle visual time never offsets the model from its ground position")
		assert(monster.native_spine_sprite.scale == Vector2.ONE)
	monster.hurtbox_h = 500.0
	monster.hurtbox_x = 700.0
	monster.facing = -1.0
	monster.character_height_px = 42.0
	game._draw_monster(monster)
	assert(monster.native_spine_sprite.position == Vector2(400, 558), "Actual combat height remains visible")
	assert(monster.native_spine_sprite.scale == Vector2(-1, 1))
	var texture: Texture2D = game.LARGE_MONSTER
	var png := {"character_id": 104, "model_resource": "res://assets/character/art/monsters/gray-shell-branch-beast.png", "facing": 1.0}
	var rect: Rect2 = game.monster_actions.visual_rect(png, Vector2(500, 650), texture)
	assert(rect.size == texture.get_size(), "PNG models also retain their actual pixel dimensions")
	assert(rect.get_center().x == 500.0 and rect.end.y == 650.0)
	var source: Dictionary = game.monster_actions._native_source(monster.model_resource)
	var native_rect: Rect2 = game.monster_actions.visual_rect(monster, Vector2(500, 650), texture)
	assert(native_rect.size.is_equal_approx(Vector2(source.skeleton.width, source.skeleton.height)))
	game._spawn_damage_floater(monster, 10, false)
	assert(is_equal_approx(game.damage_floaters.back().position.y, native_rect.position.y - 42.0 - 32.0), "Damage labels follow the original model size and combat height")
	game.monster_actions.clear()
	game.queue_free()
	await process_frame
	print("MONSTER_RENDERING_TEST_OK")
	quit()
