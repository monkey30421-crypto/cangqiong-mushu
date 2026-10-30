extends SceneTree

const Actions = preload("res://modules/monster_actions.gd")
const Reaction = preload("res://modules/damage_reaction.gd")
const MODEL := "res://assets/character/art/monsters/101-wind-slime/monster_101-data.tres"

func _initialize() -> void:
	call_deferred("run")

func target(id: int = 101) -> Dictionary:
	return {"character_id": id, "hp": 0, "hit": 0.0, "pos": Vector2(1000, 650), "damage_reaction": Reaction.new()}

func run() -> void:
	var actions := Actions.new()
	assert(actions.load_config())
	actions.rows[101].down.animation = {"library": Actions.Resources.LIBRARY_PATH, "name": "die_SingleSword"}
	actions.rows[101].down_fly.animation = {"library": Actions.Resources.LIBRARY_PATH, "name": "fall_end"}
	actions.rows[101].getup.animation = {"library": Actions.Resources.LIBRARY_PATH, "name": "die_Up"}
	# Ground deaths finish once, then disappear; living knockdowns can still loop.
	var grounded := target()
	actions.interrupt(grounded)
	actions.retire(grounded)
	assert(grounded.action_state.key == "down")
	actions.advance_corpses(actions.duration(grounded, "down") + 0.02)
	assert(actions.corpses.is_empty())
	actions.advance_corpses(10.0)
	assert(actions.corpses.is_empty())
	# An airborne death keeps its flight and disappears after landing finishes.
	var airborne := target()
	airborne.damage_reaction.begin_knockback(1.0, 1.0)
	actions.interrupt(airborne)
	actions.retire(airborne)
	actions.advance_corpses(0.2)
	assert(airborne.action_state.key == "floated" and airborne.character_height_px > 0.0)
	actions.advance_corpses(0.35)
	assert(airborne.action_state.key == "down_fly" and is_zero_approx(airborne.character_height_px))
	actions.advance_corpses(actions.duration(airborne, "down_fly") + 0.02)
	assert(actions.corpses.is_empty())
	# An omitted landing selection skips even when the model has a matching native
	# fall animation. It must not play that animation or wait for fallback VFX time.
	actions.rows[102].down_fly.animation = null
	actions.rows[102].down_fly.upper = {"file": "skilleffect_jd_dg1.json", "animation": "attack1"}
	actions.rows[102].lying_loop.animation = {"library": MODEL, "name": "die_floated"}
	actions.rows[102].lying_loop.upper = null
	actions.rows[102].lying_loop.lower = null
	var skipped := target(102)
	skipped.hp = 50
	skipped.model_resource = MODEL
	skipped.facing = 1.0
	skipped.damage_reaction.begin_knockback(1.0, 2.0)
	actions.interrupt(skipped)
	assert(skipped.action_state.key == "floated")
	assert(actions.action(skipped, "down_fly").animation == null)
	assert(actions._native_animation_name(skipped, "down_fly").is_empty())
	assert(is_zero_approx(actions.duration(skipped, "down_fly")))
	var host := Node2D.new()
	root.add_child(host)
	assert(actions.draw_body(host, skipped, Vector2.ZERO, Color.WHITE))
	skipped.damage_reaction.advance_knockback(0.55)
	actions.advance(skipped, 0.0)
	assert(skipped.action_state.key == "lying_loop", "Enter the ground loop on the landing frame, without a blank landing stage")
	assert(skipped.action_state.effects.is_empty(), "Skipped landing effects cannot delay the transition")
	assert(actions.draw_body(host, skipped, Vector2.ZERO, Color.WHITE))
	var ground_track = skipped.native_spine_sprite.get_animation_state().get_track(0)
	assert(ground_track.get_animation().get_name() == "die_floated" and ground_track.get_loop())
	actions.advance(skipped, 0.05)
	actions.advance(skipped, 0.0)
	assert(skipped.action_state.key == "lying_loop" and is_equal_approx(float(skipped.action_state.elapsed), 0.05), "The ground loop does not restart every frame")
	# Death still finishes after landing instead of retaining an infinite corpse loop.
	var skipped_death := target(102)
	skipped_death.model_resource = MODEL
	skipped_death.damage_reaction.begin_knockback(1.0, 2.0)
	actions.interrupt(skipped_death)
	actions.retire(skipped_death)
	actions.advance_corpses(0.55)
	assert(skipped_death.action_state.key == "lying_loop" and actions.corpses.is_empty())
	host.queue_free()
	actions.rows[102].down_fly.upper = null
	# Only the airborne landing loop is independently configurable for monsters.
	actions.rows[102].lying_loop.animation = {"library": Actions.Resources.LIBRARY_PATH, "name": "idle_SingleWeapon"}
	actions._body_clip(actions.rows[102].lying_loop).events = [{"name": "action", "time": 0.0}]
	actions.rows[102].lying_loop.upper = {"file": "skilleffect_jd_dg1.json", "animation": "attack1"}
	actions.rows[102].lying_loop.lower = {"file": "skilleffect_jd_dg1.json", "animation": "attack2"}
	var custom := target(102)
	custom.hp = 50
	custom.damage_reaction.down_remaining = 10.0
	custom.damage_reaction.begin_knockback(1.0, 1.0)
	custom.damage_reaction.advance_knockback(0.55)
	actions.interrupt(custom)
	actions.advance(custom, actions.duration(custom, "down_fly") + 0.01)
	actions.advance(custom, 0.0)
	assert(custom.action_state.key == "lying_loop" and custom.action_state.held_clip.is_empty())
	assert(custom.action_state.effects.size() == 2)
	assert(grounded.action_state.effects.is_empty())
	var serial_time := float(custom.action_state.elapsed)
	actions.advance(custom, actions.duration(custom, "lying_loop"))
	assert(custom.action_state.key == "lying_loop" and custom.action_state.elapsed > serial_time)
	assert(custom.action_state.effects.size() == 2, "Loop VFX retrigger each cycle")
	# Living targets retain their recovery path after the ground loop.
	var living := target()
	living.hp = 50
	living.damage_reaction.down_remaining = 2.0
	actions.interrupt(living)
	actions.advance(living, actions.duration(living, "down") + 0.01)
	actions.advance(living, 0.0)
	assert(living.action_state.key == "down")
	living.damage_reaction.advance(2.0)
	actions.advance(living, 0.0)
	assert(living.action_state.key == "getup")
	actions.clear()
	assert(actions.corpses.is_empty())
	# Hero ground deaths stay on their death action; launched ground poses can loop.
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	await process_frame
	game._enter_city(true)
	game._enter_dungeon()
	game.monsters.clear()
	game.dungeon_stage = "dead"
	game.current_health = 0.0
	game.getup_pending = false
	var hero = game.character_actions
	# Test the launched held pose independently of the editor-selected loop.
	hero.rows[1015].animation = hero.HOLD_POSE_ANIMATION
	var ground_animation: String = hero.rows[1008].animation
	hero.play(1008, true)
	game._process(hero.duration(1008) + 0.01)
	assert(hero.active_id == 1008)
	var track = game.traveler.get_animation_state().get_track(0)
	assert(track.get_animation().get_name() == ground_animation and not track.get_loop())
	var serial: int = hero.playback_serial
	game._process(5.0)
	assert(hero.active_id == 1008 and hero.playback_serial == serial)
	assert(game.getup_remaining == 0.0)
	game.damage_reaction.begin_knockback(1.0, 1.0)
	game._update_traveler()
	assert(hero.active_id == 1013 and game.traveler.get_animation_state().get_track(0).get_loop())
	game._process(0.55)
	assert(hero.active_id == 1014)
	game._process(hero.duration(1014) + 0.01)
	assert(hero.active_id == 1015)
	assert(game.traveler.get_animation_state().get_track(0).get_animation().get_name() == "fall_end")
	hero.rows[1015].animation = "idle_SingleWeapon"
	hero.play(1014, true)
	game._process(hero.duration(1014) + 0.01)
	assert(hero.active_id == 1015)
	track = game.traveler.get_animation_state().get_track(0)
	assert(track.get_animation().get_name() == "idle_SingleWeapon" and track.get_loop())
	assert(game.getup_remaining == 0.0 and game.getup_roll_remaining == 0.0)
	game.queue_free()
	await process_frame
	print("DOWN_PHASE_LOOPS_TEST_OK")
	quit()
