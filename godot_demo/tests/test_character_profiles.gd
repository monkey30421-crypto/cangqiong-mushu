extends SceneTree

const Profiles = preload("res://modules/character_profiles.gd")
const Rules = preload("res://modules/combat_rules.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var profiles := Profiles.new()
	assert(profiles.load_config())
	assert(profiles.profile(1).id == 1)
	var monster := {}
	profiles.configure_monster(monster, 101)
	assert(monster.character_id == 101 and monster.hurtbox_x > 0 and monster.hurtbox_h > 0)
	assert(monster.name == profiles.profile(101).name)
	if str(monster.model_resource).ends_with(".png"):
		assert(profiles.texture(monster.model_resource, null) != null)
	elif str(monster.model_resource).ends_with("-data.tres"):
		assert(load(monster.model_resource) is SpineSkeletonDataResource)
	# Only X and H add body extent; Y stays a point in depth.
	assert(Rules.overlaps_hurtbox(Vector2(140, 20), 0, 0, 100, 20, 0, 80, 100))
	assert(not Rules.overlaps_hurtbox(Vector2(140.01, 20), 0, 0, 100, 20, 0, 80, 100))
	assert(not Rules.overlaps_hurtbox(Vector2(140, 20.01), 0, 0, 100, 20, 0, 80, 100))
	assert(Rules.overlaps_hurtbox(Vector2.ZERO, 0, 100, 100, 20, 0, 80, 100))
	assert(not Rules.overlaps_hurtbox(Vector2.ZERO, 0, 100.01, 100, 20, 0, 80, 100))
	assert(Rules.overlaps_hurtbox(Vector2.ZERO, 120, 100, 100, 20, 20, 80, 100))
	assert(not Rules.overlaps_hurtbox(Vector2.ZERO, 120.01, 100, 100, 20, 20, 80, 100))
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	await process_frame
	game.player = Vector2(1000, 650)
	game.facing = 1.0
	game.character_height_px = 0.0
	game.state = "dungeon"
	for kind in range(4):
		var configured_name := "配置名称_%d" % kind
		var character_id: int = game.character_profiles.character_id_for_type(["normal", "elite", "mutation", "boss"][kind])
		game.character_profiles.rows[character_id].name = configured_name
		var named: Dictionary = game._monster_definition(kind, game.player, "旧的固定名称", 0, 1)
		assert(named.name == configured_name, "Every monster type displays its configured name instead of the spawn fallback")
	var target: Dictionary = game._monster_definition(0, game.player + Vector2(125, 0), "测试", 0, 1)
	target.active = true
	target.hurtbox_x = 60.0
	target.hurtbox_h = 100.0
	assert(game._is_monster_in_attack_range(target, 100, 20, 0), "Body edge can be hit before feet enter range")
	target.hurtbox_x = 40.0
	assert(not game._is_monster_in_attack_range(target, 100, 20, 0))
	target.pos = game.player
	game.character_height_px = 101.0
	assert(not game._is_monster_in_attack_range(target, 100, 20, 0))
	target.hurtbox_h = 110.0
	assert(game._is_monster_in_attack_range(target, 100, 20, 0))
	# Monster attacks also include the configured player's body width.
	game.character_height_px = 0.0
	game.dungeon_stage = "combat"
	game.modal.hide()
	game.current_health = 100.0
	target.pos = game.player + Vector2(100, 0)
	target.engaged = true
	target.attack_cooldown = 0.0
	target.attack = 10
	target.model_resource = "res://assets/character/art/monsters/101-wind-slime/monster_101-data.tres"
	for key in ["attack1", "attack2"]:
		game.monster_actions.rows[target.character_id][key].animation = {"library": target.model_resource, "name": "attack_1"}
		game.monster_actions.rows[target.character_id][key].upper = {"file": "skilleffect_jd_dg1.json", "animation": "attack2"}
		game.monster_actions.rows[target.character_id][key].lower = null
	game.monsters.assign([target])
	game._update_monster_ai(0.01)
	assert(game.current_health == 100.0, "Starting an attack cannot deal immediate damage")
	game.monster_actions.advance(target, 0.75)
	assert(game.current_health < 100.0, "Player body width must affect incoming attacks")
	assert(game.character_actions.library_path == str(profiles.profile(1).modelResource))
	game.queue_free()
	await process_frame
	print("CHARACTER_PROFILES_TEST_OK")
	quit()
