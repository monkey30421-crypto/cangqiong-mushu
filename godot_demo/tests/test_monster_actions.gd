extends SceneTree

const Actions = preload("res://modules/monster_actions.gd")
const Reaction = preload("res://modules/damage_reaction.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var actions := Actions.new()
	assert(actions.load_config())
	# Use a blank fixture so editor changes do not alter this mapping test.
	for id in actions.rows:
		for key in actions.rows[id]:
			actions.rows[id][key].animation = null
			actions.rows[id][key].upper = null
			actions.rows[id][key].lower = null
	actions.rows[101].attack1.animation = {"library": Actions.Resources.LIBRARY_PATH, "name": "attack1_SingleSword"}
	actions._body_clip(actions.rows[101].attack1).events = [{"name": "action", "time": 0.0}]
	actions.rows[101].hurt.animation = {"library": Actions.Resources.LIBRARY_PATH, "name": "idle_SingleWeapon"}
	actions._body_clip(actions.rows[101].hurt).events = [{"name": "action", "time": 0.0}]
	var monster := {"character_id": 101, "hp": 100, "hit": 0.0, "damage_reaction": Reaction.new()}
	var other := {"character_id": 102, "hp": 100, "hit": 0.0}
	var spine_monster := {"character_id": 101, "hp": 100, "hit": 0.0, "model_resource": "res://assets/character/art/monsters/101-wind-slime/monster_101-data.tres", "hurtbox_h": 98.4375, "facing": 1.0}
	assert(actions.action(spine_monster, "idle").animation == {"library": spine_monster.model_resource, "name": "idle"})
	assert(actions._native_animation_name(spine_monster, "idle") == "idle")
	assert(actions._native_animation_name(spine_monster, "attack1") == "attack1_SingleSword", "An explicitly selected native library overrides the default model")
	assert(is_equal_approx(actions.duration(spine_monster, "attack1"), 0.6666667))
	spine_monster.action_state = {"key": "idle", "elapsed": 0.0}
	var spine_host := Node2D.new()
	root.add_child(spine_host)
	actions.prepare_native_sprite(spine_host, spine_monster)
	assert(actions.draw_body(spine_host, spine_monster, Vector2(300, 200), Color.WHITE))
	assert(spine_monster.native_spine_sprite.skeleton_data_res != null)
	assert(spine_monster.native_spine_sprite.get_animation_state().get_track(0).get_animation().get_name() == "idle")
	assert(spine_monster.native_spine_sprite.scale == Vector2.ONE, "Native Spine artwork keeps its original size")
	spine_monster.hurtbox_h = 500.0
	spine_monster.facing = -1.0
	assert(actions.draw_body(spine_host, spine_monster, Vector2(300, 200), Color.WHITE))
	assert(spine_monster.native_spine_sprite.scale == Vector2(-1, 1), "Changing hurtbox height cannot resize the model; facing only mirrors it")
	spine_monster.action_state = {"key": "down", "elapsed": 0.0, "effects": [], "held_clip": {}}
	assert(actions.draw_body(spine_host, spine_monster, Vector2(300, 200), Color.WHITE))
	var native_track = spine_monster.native_spine_sprite.get_animation_state().get_track(0)
	assert(native_track.get_animation().get_name() == "die")
	spine_monster.action_state = {"key": "down", "elapsed": 10.0, "effects": [], "held_clip": {}}
	native_track.set_loop(false)
	native_track.set_track_time(native_track.get_animation_end())
	assert(actions.draw_body(spine_host, spine_monster, Vector2(300, 200), Color.WHITE), "A Spine monster keeps its death pose without a kneel-loop action")
	assert(spine_monster.native_spine_sprite.visible)
	assert(not native_track.get_loop() and native_track.get_track_time() >= native_track.get_animation_end(), "Ground death remains on the final frame")
	spine_host.queue_free()
	monster.model_resource = Actions.Resources.LIBRARY_PATH
	assert(actions.action(monster, "idle").animation.name == "idle_SingleWeapon", "An unconfigured monster can use the selected hero Spine")
	assert(actions.action(monster, "attack1").animation.name == "attack1_SingleSword")
	actions.rows[101].idle.animation = {"library": Actions.Resources.LIBRARY_PATH, "name": "run_SingleWeapon"}
	assert(actions.action(monster, "idle").animation.name == "run_SingleWeapon", "Explicit monster mappings override model defaults")
	actions.rows[101].idle.animation = null
	monster.erase("model_resource")
	actions.rows[101].attack1.upper = {"file": "skilleffect_jd_dg1.json", "animation": "attack1"}
	actions.rows[101].attack1.lower = {"file": "skilleffect_jd_dg1.json", "animation": "attack2"}
	actions.rows[101].hurt.upper = {"file": "skilleffect_jd_dg1.json", "animation": "attack3"}
	actions.play(monster, "attack1", true)
	actions.advance(monster, 0.01)
	assert(monster.action_state.key == "attack1" and monster.action_state.effects.size() == 2)
	assert(monster.action_state.effects[0].layer == "upper" and monster.action_state.effects[1].layer == "lower")
	actions.advance(monster, 0.0)
	assert(monster.action_state.effects.size() == 2, "An action event cannot trigger twice")
	actions.play(other, "attack1", true)
	actions.advance(other, 0.01)
	assert(other.action_state.effects.is_empty(), "Each monster uses its own action mapping")
	monster.hit = 0.18
	actions.interrupt(monster)
	assert(monster.action_state.key == "hurt" and monster.action_state.effects.size() == 1)
	assert(monster.action_state.effects[0].clip == actions.resources._effect_clip(actions.rows[101].hurt.upper), "Hurt clears the old attack's two effects")
	monster.hit = 0.0
	monster.damage_reaction.down_remaining = 0.5
	actions.rows[101].getup.animation = {"library": Actions.Resources.LIBRARY_PATH, "name": "die_Up"}
	actions.advance(monster, 0.01)
	assert(monster.action_state.key == "down")
	monster.damage_reaction.advance(0.5)
	actions.advance(monster, 0.0)
	assert(monster.action_state.key == "getup" and actions.busy(monster))
	actions.advance(monster, actions.duration(monster, "getup"))
	actions.advance(monster, 0.0)
	assert(monster.action_state.key == "idle")
	monster.moving = true
	actions.advance(monster, 0.01)
	assert(monster.action_state.key == "move_front")
	# Selected body animations trigger VFX at their own action events.
	actions.rows[101].attack1.animation = {"library": Actions.Resources.LIBRARY_PATH, "name": "attack1_SingleSword"}
	var clip: Dictionary = actions._body_clip(actions.rows[101].attack1)
	clip.events = [{"name": "action", "time": 0.1}]
	actions.play(monster, "attack1", true)
	actions.advance(monster, 0.099)
	assert(monster.action_state.effects.is_empty())
	actions.advance(monster, 0.002)
	assert(monster.action_state.effects.size() == 2)
	var mapped_data := load(str(clip.resource)) as SpineSkeletonDataResource
	assert(mapped_data != null and mapped_data.is_skeleton_data_loaded())
	assert(mapped_data.find_animation(&"attack1_SingleSword") != null)
	assert(not clip.has("sheet"), "Configured monster actions use native Spine, never sampled sheets")
	actions.rows[101].down.animation = {"library": Actions.Resources.LIBRARY_PATH, "name": "die_SingleSword"}
	monster.hp = 0
	actions.interrupt(monster)
	assert(monster.action_state.key == "down" and monster.action_state.effects.is_empty())
	actions.retire(monster)
	actions.retire(monster)
	assert(actions.corpses.size() == 1)
	actions.advance_corpses(actions.duration(monster, "down") * 0.5)
	assert(actions.corpses.size() == 1)
	actions.advance_corpses(actions.duration(monster, "down"))
	assert(actions.corpses.is_empty(), "Death visuals disappear when the configured action finishes")
	actions.clear()
	# Integration: actual AI plays attack; receiving a hit interrupts the mapping immediately.
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	await process_frame
	game._enter_dungeon()
	game.dungeon_stage = "combat"
	game.modal.hide()
	game.player = Vector2(1200, 650)
	game.current_health = 100.0
	game.monsters.clear()
	game.monster_actions.rows = actions.rows.duplicate(true)
	var target: Dictionary = game._monster_definition(0, game.player + Vector2(20, 0), "动作测试", 0, 1)
	target.active = true
	target.spawn_alpha = 1.0
	target.engaged = true
	target.hp = 1000
	target.max_hp = 1000
	target.attack_cooldown = 0.0
	game.monsters.append(target)
	game._update_monster_ai(0.01)
	assert(target.action_state.key in ["attack1", "attack2"])
	game._apply_attack_damage(100, 100, 100)
	assert(target.action_state.key == "hurt")
	target.hp = 1
	game._apply_attack_damage(100, 100, 100)
	assert(game.monsters.is_empty() and game.monster_actions.corpses.size() == 1)
	assert(target.action_state.key == "down")
	assert(game.pending_dungeon_experience == 1)
	game._update_character_shadows()
	assert(game.character_shadows.characters.size() >= 1, "Death visuals keep their grounded shadows")
	game._enter_city(false)
	assert(game.monster_actions.corpses.is_empty())
	game.queue_free()
	await process_frame
	print("MONSTER_ACTIONS_TEST_OK")
	quit()
