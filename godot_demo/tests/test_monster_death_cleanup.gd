extends SceneTree

const Actions = preload("res://modules/monster_actions.gd")
const Reaction = preload("res://modules/damage_reaction.gd")
const MODEL := "res://assets/character/art/monsters/101-wind-slime/monster_101-data.tres"

func _initialize() -> void:
	call_deferred("run")

func target() -> Dictionary:
	return {"character_id": 101, "hp": 0, "hit": 0.0, "pos": Vector2(1000, 650), "model_resource": MODEL, "damage_reaction": Reaction.new()}

func run() -> void:
	var actions := Actions.new()
	assert(actions.load_config())
	# This branch checks an explicitly configured landing, independently of editor changes.
	actions.rows[101].down_fly.animation = {"library": MODEL, "name": "die_floated"}
	var host := Node2D.new()
	root.add_child(host)
	var dead := target()
	actions.interrupt(dead)
	actions.retire(dead)
	actions.retire(dead)
	assert(actions.corpses.size() == 1, "Retiring twice cannot duplicate the death visual")
	assert(actions.draw_body(host, dead, Vector2.ZERO, Color.WHITE))
	var sprite: SpineSprite = dead.native_spine_sprite
	var length := actions.duration(dead, "down")
	dead.action_state.effects.append({"layer": "upper", "elapsed": 0.0, "clip": {"duration": 100.0, "frames": 1, "fps": 30.0}})
	actions.advance_corpses(length - 0.001)
	assert(actions.corpses.size() == 1 and sprite.visible)
	actions.advance_corpses(0.002)
	assert(actions.corpses.is_empty())
	assert(sprite.is_queued_for_deletion() and not sprite.visible)
	assert(not actions.native_sprites.has(sprite) and not dead.has("native_spine_sprite"))
	assert(dead.action_state.effects.is_empty())
	await process_frame
	assert(not is_instance_valid(sprite))
	# Flight is never counted against the landing/death action duration.
	var flying := target()
	flying.damage_reaction.begin_knockback(1.0, 1.0)
	actions.interrupt(flying)
	actions.retire(flying)
	actions.advance_corpses(0.2)
	assert(flying.action_state.key == "floated" and actions.corpses.size() == 1)
	actions.advance_corpses(0.35)
	assert(flying.action_state.key == "down_fly")
	assert(is_zero_approx(float(flying.action_state.elapsed)))
	length = actions.duration(flying, "down_fly")
	actions.advance_corpses(length - 0.001)
	assert(actions.corpses.size() == 1)
	actions.advance_corpses(0.002)
	assert(actions.corpses.is_empty() and flying.action_state.key == "down_fly")
	# An oversized frame can complete both flight and death in one update.
	var fast := target()
	fast.damage_reaction.begin_knockback(-1.0)
	actions.interrupt(fast)
	actions.retire(fast)
	actions.advance_corpses(10.0)
	assert(actions.corpses.is_empty())
	# Static PNG death fallback is finite too.
	var png := {"character_id": 104, "hp": 0, "hit": 0.0}
	actions.interrupt(png)
	actions.retire(png)
	actions.advance_corpses(actions.duration(png, "down") + 0.001)
	assert(actions.corpses.is_empty())
	# Real game: death cleanup removes shadows without affecting loot or experience.
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	await process_frame
	game._enter_city(true)
	game._enter_dungeon()
	game.monsters.clear()
	game.dungeon_stage = "wave_delay"
	game.dungeon_next_wave_timer = 100.0
	game.player = Vector2(1200, 650)
	game.facing = 1.0
	var monster: Dictionary = game._monster_definition(0, game.player + Vector2(20, 0), "Death cleanup", 0, 1)
	monster.active = true
	monster.spawn_alpha = 1.0
	monster.hp = 1
	monster.max_hp = 1000
	game.monsters.append(monster)
	game._apply_attack_damage(100, 100, 100)
	assert(game.monsters.is_empty() and game.monster_actions.corpses.size() == 1)
	game.monster_actions.prepare_native_sprite(game, monster)
	var native: SpineSprite = monster.native_spine_sprite
	game._update_character_shadows()
	var shadows: int = game.character_shadows.characters.size()
	var drops: int = game.ground_loot.entries.size()
	var experience: int = game.pending_dungeon_experience
	assert(drops > 0 and experience == 1)
	game._update_dungeon(game.monster_actions.duration(monster, "down") + 0.001)
	game._update_character_shadows()
	assert(game.monster_actions.corpses.is_empty())
	assert(native.is_queued_for_deletion())
	assert(game.character_shadows.characters.size() == shadows - 1)
	assert(game.ground_loot.entries.size() == drops and game.pending_dungeon_experience == experience)
	game.queue_free()
	host.queue_free()
	await process_frame
	print("MONSTER_DEATH_CLEANUP_TEST_OK")
	quit()
