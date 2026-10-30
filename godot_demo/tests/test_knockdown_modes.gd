extends SceneTree

const Reaction = preload("res://modules/damage_reaction.gd")
const Actions = preload("res://modules/monster_actions.gd")

func _initialize() -> void:
	call_deferred("run")

func target() -> Dictionary:
	return {"character_id": 101, "hp": 100, "hit": 0.0, "pos": Vector2(1000, 650), "damage_reaction": Reaction.new()}

func run() -> void:
	var reaction := Reaction.new()
	assert(reaction.receive(31, 100, 1.0))
	assert(reaction.knockdown_action() == "down")
	reaction.begin_knockback(1.0, 0.4)
	assert(reaction.knockdown_action() == "floated")
	reaction.advance_knockback(reaction.KNOCKBACK_DURATION)
	assert(reaction.knockdown_action() == "down_fly", "Landing preserves the launched knockdown type")
	reaction.finish_getup()
	assert(reaction.knockdown_action() == "down")
	var actions := Actions.new()
	assert(actions.load_config())
	actions.rows[101].down.animation = {"library": Actions.Resources.LIBRARY_PATH, "name": "die_SingleSword"}
	actions.rows[101].down_fly.animation = {"library": Actions.Resources.LIBRARY_PATH, "name": "fall_end"}
	# An airborne kill keeps moving and lands using the launched-fall action.
	var flying := target()
	flying.damage_reaction.begin_knockback(1.0, 0.5)
	actions.advance(flying, 0.01)
	assert(flying.action_state.key == "floated")
	flying.hp = 0
	actions.interrupt(flying)
	assert(flying.action_state.key == "floated")
	actions.retire(flying)
	actions.advance_corpses(0.2)
	assert(flying.action_state.key == "floated" and flying.character_height_px > 0.0)
	assert(flying.pos.x > 1000.0)
	actions.advance_corpses(0.35)
	assert(flying.action_state.key == "down_fly" and is_zero_approx(float(flying.character_height_px)))
	assert(actions.corpses.size() == 1)
	actions.advance_corpses(actions.duration(flying, "down_fly") - 0.001)
	assert(actions.corpses.size() == 1)
	actions.advance_corpses(0.002)
	assert(actions.corpses.is_empty(), "Dead targets disappear after their landing action and never get up")
	# Killing an already-landed target must not restart or replace its fall animation.
	var landed := target()
	landed.damage_reaction.begin_knockback(1.0, 1.0)
	landed.damage_reaction.advance_knockback(0.55)
	actions.advance(landed, 0.2)
	assert(landed.action_state.key == "down_fly")
	landed.hp = 0
	actions.interrupt(landed)
	assert(landed.action_state.key == "down_fly" and is_equal_approx(float(landed.action_state.elapsed), 0.2))
	actions.retire(landed)
	actions.clear()
	var grounded := target()
	grounded.hp = 0
	actions.interrupt(grounded)
	actions.retire(grounded)
	assert(grounded.action_state.key == "down", "Grounded deaths reuse standing knockdown")
	actions.advance_corpses(0.01)
	assert(grounded.action_state.key == "down")
	actions.clear()
	# The real player selects distinct actions, including an airborne death transition.
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	await process_frame
	game._enter_city(true)
	game._enter_dungeon()
	game.monsters.clear()
	game.dungeon_stage = "wave_delay"
	game.dungeon_next_wave_timer = 100.0
	game._damage_player(31)
	assert(game.character_actions.active_id == 1013)
	game.current_health = 0.0
	game.dungeon_stage = "dead"
	game.getup_pending = false
	game._process(0.55)
	assert(game.character_actions.active_id == 1014)
	game._process(2.0)
	game._process(0.01)
	assert(game.character_actions.active_id == 1015 and game.getup_remaining == 0.0 and game.getup_roll_remaining == 0.0)
	game._enter_city(true)
	game._enter_dungeon()
	game.monsters.clear()
	game._damage_player(101)
	assert(game.dungeon_stage == "dead" and game.character_actions.active_id == 1008)
	# A real monster can still take lethal damage after being launched.
	game._enter_city(true)
	game._enter_dungeon()
	game.monsters.clear()
	game.dungeon_stage = "wave_delay"
	game.dungeon_next_wave_timer = 100.0
	game.player = Vector2(1200, 650)
	game.facing = 1.0
	game.player_stats.attack = 400
	game.monster_actions.rows[101].down_fly.animation = {"library": Actions.Resources.LIBRARY_PATH, "name": "fall_end"}
	var monster: Dictionary = game._monster_definition(0, game.player + Vector2(20, 0), "击飞死亡测试", 0, 1)
	monster.active = true
	monster.hp = 1000
	monster.max_hp = 1000
	game.monsters.append(monster)
	game._apply_attack_damage(1000, 100, 200)
	assert(monster.hp > 0 and monster.damage_reaction.knockback_remaining > 0.0)
	monster.hp = 1
	game._apply_attack_damage(1000, 100, 200)
	assert(game.monsters.is_empty() and game.monster_actions.corpses.size() == 1)
	assert(monster.action_state.key == "floated")
	game._update_dungeon(0.55)
	assert(monster.action_state.key == "down_fly")
	game.queue_free()
	await process_frame
	print("KNOCKDOWN_MODES_TEST_OK")
	quit()
