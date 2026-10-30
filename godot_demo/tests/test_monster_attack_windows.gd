extends SceneTree

const MODEL := "res://assets/character/art/monsters/101-wind-slime/monster_101-data.tres"
const EFFECT := "skilleffect_jd_dg1.json"
var game
var actions
var original_source: Dictionary
var original_effect: Dictionary

func _initialize() -> void:
	call_deferred("run")

func attacker(offset: Vector2 = Vector2(-100, 0)) -> Dictionary:
	game.monsters.clear()
	game.current_health = 10000.0
	game.player_stats.max_health = 10000
	game.damage_reaction.reset()
	game.getup_remaining = 0.0
	game.getup_roll_remaining = 0.0
	game.hurt_remaining = 0.0
	game.character_height_px = 0.0
	game.player = Vector2(1200, 650)
	game.dungeon_stage = "combat"
	game.modal.hide()
	var monster: Dictionary = game._monster_definition(0, game.player + offset, "Attack windows", 0, 1)
	monster.model_resource = MODEL
	monster.active = true
	monster.engaged = true
	monster.hp = 10000
	monster.max_hp = 10000
	monster.attack = 10
	monster.attack_range_x = 100.0
	monster.attack_range_y = 50.0
	monster.attack_range_height = 0.0
	monster.facing = 1.0
	monster.attack_cooldown = 0.0
	monster.damage_reaction = game.DamageReactionScript.new()
	game.monsters.append(monster)
	actions.resources.spine_resources.sources[MODEL] = original_source.duplicate(true)
	actions.resources.spine_resources.clips.erase(MODEL)
	actions.rows[101].idle.animation = null
	actions.rows[101].idle.upper = null
	actions.rows[101].idle.lower = null
	for key in ["attack1", "attack2", "skill1", "skill2"]:
		actions.rows[101][key].animation = {"library": MODEL, "name": "attack_1"}
		actions.rows[101][key].upper = {"file": EFFECT, "animation": "attack1"}
		actions.rows[101][key].lower = null
	for file in actions.resources.library.effects:
		if file.file == EFFECT:
			file.animations.attack1 = original_effect.duplicate(true)
	return monster

func start(monster: Dictionary, key: String = "attack1", time: float = 0.0) -> void:
	actions.play(monster, key, true)
	actions.advance(monster, time)

func run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	await process_frame
	game._enter_city(true)
	game._enter_dungeon()
	actions = game.monster_actions
	original_source = actions._native_source(MODEL).duplicate(true)
	# The timing fixture uses the authored 1/30s window; the saved-attack test
	# separately checks the current source events for every actual selection.
	original_effect = actions.resources._effect_clip({"file": EFFECT, "animation": "attack2"}).duplicate(true)
	# All four attack actions wait for action (.7s) and then the effect window.
	for key in ["attack1", "attack2", "skill1", "skill2"]:
		var monster := attacker()
		start(monster, key)
		assert(game.current_health == 10000.0 and monster.action_state.effects.is_empty())
		actions.advance(monster, 0.699)
		assert(monster.action_state.effects.is_empty())
		actions.advance(monster, 0.002)
		assert(monster.action_state.effects.size() == 1 and game.current_health == 10000.0)
		actions.advance(monster, 0.03)
		assert(game.current_health == 10000.0)
		actions.advance(monster, 0.003)
		assert(game.current_health < 10000.0)
		var health: float = game.current_health
		actions.advance(monster, 0.02)
		actions.advance(monster, 0.02)
		assert(game.current_health == health, "A window hits each victim once")
	# A miss is not consumed: enter after hit_start while the window is open.
	var monster := attacker(Vector2(-200, 0))
	start(monster, "attack1", 0.74)
	assert(game.current_health == 10000.0)
	game.player = monster.pos + Vector2(120, 0) # Body edge overlaps range 100 + half-width 30.
	actions.advance(monster, 0.01)
	assert(game.current_health < 10000.0)
	var hit_health: float = game.current_health
	game.player.x += 200
	actions.advance(monster, 0.01)
	game.player.x -= 200
	actions.advance(monster, 0.01)
	assert(game.current_health == hit_health)
	monster = attacker(Vector2(-200, 0))
	start(monster, "attack1", 0.9)
	game.player = monster.pos + Vector2(50, 0)
	actions.advance(monster, 0.01)
	assert(game.current_health == 10000.0, "Entering after hit_end cannot be hit")
	# Every range axis and facing is sampled at hit time, not cast time.
	for mode in ["depth", "height", "behind"]:
		monster = attacker()
		if mode == "depth": game.player.y += 51.0
		if mode == "height": game.character_height_px = 1.0
		if mode == "behind": monster.facing = -1.0
		start(monster, "attack1", 0.74)
		assert(game.current_health == 10000.0)
		game.player.y = monster.pos.y
		game.character_height_px = 0.0
		monster.facing = 1.0
		actions.advance(monster, 0.01)
		assert(game.current_health < 10000.0)
	# No action event, no configured VFX, and old hit-only VFX never deal damage.
	for mode in ["no_action", "no_effect", "old_hit", "unpaired", "non_attack"]:
		monster = attacker()
		if mode == "no_action": actions.resources.spine_resources.sources[MODEL].animations.attack_1.events = []
		if mode == "no_effect": actions.rows[101].attack1.upper = null
		if mode in ["old_hit", "unpaired"]:
			var effect: Dictionary = actions.resources._effect_clip({"file": EFFECT, "animation": "attack1"})
			effect.events = [{"name": "hit" if mode == "old_hit" else "hit_start", "time": 0.05}]
		if mode == "non_attack":
			actions.rows[101].idle.animation = {"library": MODEL, "name": "attack_1"}
			actions.rows[101].idle.upper = {"file": EFFECT, "animation": "attack1"}
		start(monster, "idle" if mode == "non_attack" else "attack1", 1.0)
		assert(game.current_health == 10000.0, mode)
	# Matching upper/lower windows share one hit ledger; distinct windows can hit separately.
	monster = attacker()
	actions.rows[101].attack1.lower = {"file": EFFECT, "animation": "attack2"}
	start(monster, "attack1", 1.0)
	var single_damage: float = 10000.0 - game.current_health
	assert(single_damage > 0.0 and single_damage <= 10.0)
	monster = attacker()
	actions.rows[101].attack1.lower = {"file": EFFECT, "animation": "attack3"}
	start(monster, "attack1", 1.0)
	assert(is_equal_approx(10000.0 - game.current_health, single_damage * 2.0))
	# A large frame must resolve all action triggers and windows before deleting expired VFX.
	monster = attacker()
	actions.resources.spine_resources.sources[MODEL].animations.attack_1.events = [{"name": "action", "time": 0.2}, {"name": "action", "time": 0.6}]
	start(monster, "attack1", 1.0)
	assert(is_equal_approx(10000.0 - game.current_health, single_damage * 2.0))
	assert(monster.action_state.effects.is_empty())
	monster = attacker()
	var effect: Dictionary = actions.resources._effect_clip({"file": EFFECT, "animation": "attack1"})
	effect.events = [{"name": "hit_start", "time": 0.01}, {"name": "hit_end", "time": 0.02}, {"name": "hit_start", "time": 0.03}, {"name": "hit_end", "time": 0.04}]
	start(monster, "attack1", 1.0)
	assert(is_equal_approx(10000.0 - game.current_health, single_damage * 2.0))
	# Attack VFX outlive the body animation and retain their casting stats.
	monster = attacker()
	actions.resources.spine_resources.sources[MODEL].animations.attack_1 = {"events": [{"name": "action", "time": 0.01}], "bones": {"root": {"translate": [{"time": 0.02}]}}}
	start(monster, "attack1", 0.04)
	actions.advance(monster, 0.0)
	assert(monster.action_state.key == "idle" and not monster.action_state.effects.is_empty())
	monster.attack_range_x = 0.0
	monster.attack = 1000
	actions.advance(monster, 0.01)
	assert(is_equal_approx(10000.0 - game.current_health, single_damage))
	# Each new cast has its own ledger, even while its previous VFX are still alive.
	monster = attacker()
	actions.resources.spine_resources.sources[MODEL].animations.attack_1.events = [{"name": "action", "time": 0.0}]
	start(monster)
	start(monster, "attack2")
	actions.advance(monster, 0.04)
	assert(is_equal_approx(10000.0 - game.current_health, single_damage * 2.0))
	# Paused effects cannot advance into a hit; protected victims are not consumed.
	monster = attacker(Vector2(-200, 0))
	start(monster, "attack1", 0.74)
	var paused_time: float = monster.action_state.effects[0].elapsed
	monster.hit_stop_remaining = 1.0
	game.player = monster.pos + Vector2(50, 0)
	game._update_dungeon(0.1)
	assert(game.current_health == 10000.0 and monster.action_state.effects[0].elapsed == paused_time)
	monster.hit_stop_remaining = 0.0
	game._update_dungeon(0.01)
	assert(game.current_health < 10000.0)
	monster = attacker()
	game.damage_reaction.recovery_invulnerable_remaining = 1.0
	start(monster, "attack1", 0.74)
	assert(game.current_health == 10000.0)
	game.damage_reaction.recovery_invulnerable_remaining = 0.0
	actions.advance(monster, 0.01)
	assert(game.current_health < 10000.0)
	# Reactions cancel pending hit windows even when the victim subsequently enters range.
	for mode in ["hurt", "down", "dead"]:
		monster = attacker()
		start(monster, "attack1", 0.72)
		if mode == "hurt": monster.hit = 0.18
		if mode == "down": monster.damage_reaction.down_remaining = 2.0
		if mode == "dead": monster.hp = 0
		actions.interrupt(monster)
		actions.advance(monster, 1.0)
		assert(game.current_health == 10000.0, mode)
	# Real AI only starts a cast; the delayed effect callback applies damage later.
	monster = attacker()
	game._update_monster_ai(0.01)
	assert(monster.action_state.key in ["attack1", "attack2"] and game.current_health == 10000.0)
	actions.advance(monster, 0.75)
	assert(game.current_health < 10000.0)
	game.queue_free()
	await process_frame
	print("MONSTER_ATTACK_WINDOWS_TEST_OK")
	quit()
