extends SceneTree

const Shadows = preload("res://modules/character_shadows.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for body_height in [98.4375, 130.0, 220.0]:
		assert(is_equal_approx(Shadows.height_scale(-10, body_height), 1.0))
		assert(is_equal_approx(Shadows.height_scale(0, body_height), 1.0))
		assert(is_equal_approx(Shadows.height_scale(body_height * 0.5, body_height), 0.7))
		assert(is_equal_approx(Shadows.height_scale(body_height, body_height), 0.4))
		assert(is_equal_approx(Shadows.height_scale(body_height * 1.5, body_height), 0.2))
		assert(Shadows.height_scale(body_height * 2, body_height) == 0.0)
		assert(Shadows.height_scale(body_height * 3, body_height) == 0.0)
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	await process_frame
	game._enter_city(false)
	game.traveler.show()
	game.player = Vector2(1000, 650)
	game.camera_x = 300.0
	game.camera_y = 100.0
	game.character_height_px = 0.0
	game._update_traveler()
	var shadows = game.character_shadows
	assert(shadows.get_parent() == game and shadows.z_index < game.traveler.z_index)
	assert(shadows.characters.size() == 2 and shadows.visible, "The city training monster has its own grounded shadow")
	var grounded: Rect2 = shadows.shadow_rect(shadows.characters[0])
	assert(grounded.get_center().is_equal_approx(Vector2(700, 550)))
	assert(grounded.size.is_equal_approx(Shadows.SHADOW_TEXTURE.get_size()))
	# Configured size is multiplied by the height factor, never replaced by it.
	game.character_profiles.rows[1].shadowScalePercent = 200.0
	game._update_traveler()
	var configured: Rect2 = shadows.shadow_rect(shadows.characters[0])
	assert(configured.size.is_equal_approx(grounded.size * 2.0))
	# Jumping changes only size; mirroring/rotation never move or flip the ground shadow.
	game.character_height_px = float(game.character_profiles.profile(1).h)
	game.facing = -1.0
	game.traveler.rotation = PI * 0.5
	game._update_traveler()
	var raised: Rect2 = shadows.shadow_rect(shadows.characters[0])
	assert(raised.get_center().is_equal_approx(grounded.get_center()))
	assert(raised.size.is_equal_approx(configured.size * 0.4))
	assert(game.traveler.position.y < raised.get_center().y)
	game.character_height_px *= 2.0
	game._update_traveler()
	assert(shadows.shadow_rect(shadows.characters[0]).size == Vector2.ZERO)
	game._enter_dungeon()
	game.monsters.clear()
	game.player = Vector2(1100, 650)
	game.camera_x = 200.0
	game.camera_y = 50.0
	var monster: Dictionary = game._monster_definition(0, Vector2(1300, 700), "阴影测试", 0, 1)
	monster.character_height_px = float(monster.hurtbox_h)
	monster.shadow_scale_percent = 50.0
	monster.spawn_alpha = 0.5
	game.monsters.append(monster)
	game._update_traveler()
	assert(shadows.characters.size() == 2)
	var monster_rect: Rect2 = shadows.shadow_rect(shadows.characters[1])
	assert(monster_rect.get_center().is_equal_approx(Vector2(1100, 650)))
	assert(monster_rect.size.is_equal_approx(Shadows.SHADOW_TEXTURE.get_size() * 0.5 * 0.4))
	assert(shadows.characters[1].alpha == 0.5)
	# Monster visual bob and knockdown do not alter its ground anchor.
	monster.visual_elapsed = 100.0
	monster.pos += Vector2(20, -15)
	game._update_traveler()
	assert(shadows.shadow_rect(shadows.characters[1]).get_center().is_equal_approx(monster_rect.get_center() + Vector2(20, -15)))
	game.monsters.clear()
	game._update_traveler()
	assert(shadows.characters.size() == 1)
	game.character_profiles.rows[1].shadowScalePercent = 0.0
	game._update_traveler()
	assert(shadows.shadow_rect(shadows.characters[0]).size == Vector2.ZERO, "A zero configured scale hides the shadow")
	game.state = "login"
	game._process(0.01)
	assert(not shadows.visible)
	game.queue_free()
	await process_frame
	print("CHARACTER_SHADOWS_TEST_OK")
	quit()
