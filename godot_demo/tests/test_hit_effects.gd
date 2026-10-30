extends SceneTree

const Effects = preload("res://modules/hit_effects.gd")

func _initialize() -> void:
	call_deferred("run")

func victim(game, offset: Vector2 = Vector2(100, 0)) -> Dictionary:
	var monster: Dictionary = game._monster_definition(0, game.player + offset, "Contact test", 0, 1)
	monster.active = true
	monster.hp = 10000
	monster.max_hp = 10000
	monster.attack = 10
	monster.hurtbox_x = 60.0
	monster.hurtbox_h = 130.0
	return monster

func run() -> void:
	var area := Effects.effect_area({"bounds": [100, 80]}, 1.0)
	assert(area == Rect2(-50, -60, 100, 80))
	assert(Effects.effect_area({"bounds": [100, 80]}, -1.0) == area)
	assert(Effects.contact_point(Vector2(0, 200), Vector2(100, 200), 60, 100, Rect2(0, -80, 120, 60)) == Vector2(95, 150), "Left-side attacks use the overlap's center")
	assert(Effects.contact_point(Vector2(200, 200), Vector2(100, 200), 60, 100, Rect2(-120, -80, 120, 60)) == Vector2(105, 150), "Right-side attacks also use the overlap's center")
	assert(Effects.contact_point(Vector2(0, 200), Vector2(100, 200), 60, 100, Rect2(0, -150, 120, 60)) == Vector2(95, 105), "Partial head contact uses the intersection's center")
	assert(Effects.contact_point(Vector2(0, 200), Vector2(100, 200), 60, 100, Rect2(0, -60, 120, 100)) == Vector2(95, 170), "Partial foot contact uses the intersection's center")
	assert(Effects.contact_point(Vector2(0, 200), Vector2(100, 200), 60, 100, Rect2(0, -150, 150, 200)) == Vector2(100, 150), "A fully covered body uses its center")
	assert(Effects.contact_point(Vector2(0, 200), Vector2(100, 200), 60, 100) == Vector2(70, 150))
	assert(Effects.contact_point(Vector2(0, 200), Vector2(100, 200), 60, 100, Rect2(0, -300, 30, 50)) == Vector2(70, 100), "Outlying artwork still places the burst on the victim")
	var fx := Effects.new()
	root.add_child(fx)
	var target := {"origin": Vector2(100, 200)}
	fx.play_at(Vector2(70, 150), target.origin, func(): return target.origin)
	assert(fx.effects.size() == 1)
	var sprite: SpineSprite = fx.effects[0].sprite
	var track = sprite.get_animation_state().get_track(0)
	assert(track.get_animation().get_name() == "hitEff_common" and not track.get_loop())
	assert(sprite.scale == Vector2.ONE, "The supplied Spine scale is preserved")
	var duration: float = fx.effects[0].duration
	assert(is_equal_approx(duration, 0.3666667))
	target.origin += Vector2(25, -40)
	fx.advance(0.1, Vector2(20, 30))
	assert(sprite.position == Vector2(95, 110) and sprite.global_position == Vector2(75, 80))
	fx.advance(duration - 0.101)
	assert(fx.effects.size() == 1)
	fx.advance(0.002)
	assert(fx.effects.is_empty() and sprite.is_queued_for_deletion() and not sprite.visible)
	fx.play_at(Vector2.ZERO, Vector2.ZERO)
	fx.play_at(Vector2.ONE, Vector2.ONE)
	assert(fx.effects.size() == 2)
	fx.clear()
	assert(fx.effects.is_empty())
	fx.queue_free()
	await process_frame
	# Actual hero hit windows carry attack geometry through the signal to the burst.
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
	game.character_height_px = 0.0
	var actions = game.character_actions
	var hero_contact_areas: Array[Rect2] = []
	actions.skill_effect_hit.connect(func(_id, _x, _y, _h, _stop, _targets, contact_area): hero_contact_areas.append(contact_area))
	actions.rows[2001].attackDistancePx = 250.0
	actions.rows[2001].longitudinalRangePx = 60.0
	actions.rows[2001].heightRangePx = 130.0
	actions.rows[2001].hitStopMs = 0.0
	actions.rows[2001].upper = {"file": "skilleffect_jd_dg1.json", "animation": "attack2"}
	actions.rows[2001].lower = {"file": "skilleffect_jd_dg1.json", "animation": "attack2"}
	actions.library.character.animations[actions.rows[2001].animation].events = [{"name": "action", "time": 0.0}]
	var monster := victim(game)
	game.monsters.append(monster)
	actions.play(2001, true)
	actions.advance(0.04, game.player, 1.0)
	assert(game.hit_effects.effects.size() == 1, "Matching upper/lower windows create only one impact")
	var impact: Dictionary = game.hit_effects.effects[0]
	var point: Vector2 = impact.position
	var hero_visual := Rect2(game.player + hero_contact_areas[0].position, hero_contact_areas[0].size)
	var hero_overlap := Rect2(monster.pos - Vector2(30, 130), Vector2(60, 130)).intersection(hero_visual)
	assert(hero_overlap.has_area())
	assert(point == hero_overlap.get_center(), "Hero impacts use the actual overlap's center")
	actions.advance(0.02, game.player, 1.0)
	assert(game.hit_effects.effects.size() == 1, "The same window never repeats the impact")
	monster.pos += Vector2(20, 12)
	monster.character_height_px = 25.0
	game.hit_effects.advance(0.0)
	assert(impact.position == point + Vector2(20, -13), "Contact offset follows target XY and combat height")
	game.hit_effects.clear()
	game.monsters.clear()
	game.monsters.append(victim(game, Vector2(1000, 0)))
	actions.clear_effects()
	actions.play(2001, true)
	actions.advance(0.04, game.player, 1.0)
	assert(game.hit_effects.effects.is_empty(), "Whiffs create no impact")
	game.monsters.clear()
	for offset in [Vector2(80, 0), Vector2(180, 0)]: game.monsters.append(victim(game, offset))
	actions.clear_effects()
	actions.play(2001, true)
	actions.advance(0.04, game.player, 1.0)
	assert(game.hit_effects.effects.size() == 2, "Each damaged victim gets its own contact burst")
	var first_point: Vector2 = game.hit_effects.effects[0].position
	var second_point: Vector2 = game.hit_effects.effects[1].position
	game.monsters[0].pos.x += 17.0
	game.hit_effects.advance(0.0)
	assert(game.hit_effects.effects[0].position == first_point + Vector2(17, 0))
	assert(game.hit_effects.effects[1].position == second_point, "Each impact follows its own victim")
	game.hit_effects.clear()
	# Real monster VFX hit windows also create a player-side contact burst.
	game.monsters.clear()
	monster = victim(game, Vector2(-100, 0))
	monster.model_resource = "res://assets/character/art/monsters/101-wind-slime/monster_101-data.tres"
	monster.facing = 1.0
	monster.attack_range_x = 100.0
	monster.attack_range_y = 50.0
	monster.attack_range_height = 0.0
	game.monsters.append(monster)
	game.dungeon_stage = "combat"
	game.modal.hide()
	game.current_health = 1000.0
	game.player_stats.max_health = 1000
	game.damage_reaction.reset()
	game.monster_actions.rows[101].attack1.animation = {"library": monster.model_resource, "name": "attack_1"}
	game.monster_actions.rows[101].attack1.upper = {"file": "skilleffect_jd_dg1.json", "animation": "attack2"}
	game.monster_actions.rows[101].attack1.lower = null
	var monster_contact_areas: Array[Rect2] = []
	game.monster_actions.attack_effect_hit.connect(func(_monster, _attack, _targets, contact_area): monster_contact_areas.append(contact_area))
	game.monster_actions.play(monster, "attack1", true)
	game.monster_actions.advance(monster, 0.75)
	assert(game.current_health < 1000.0 and game.hit_effects.effects.size() == 1)
	point = game.hit_effects.effects[0].position
	var profile: Dictionary = game.character_profiles.profile(1)
	var monster_visual := Rect2(monster.pos + monster_contact_areas[0].position, monster_contact_areas[0].size)
	var monster_overlap := Rect2(game.player - Vector2(float(profile.x) * 0.5, float(profile.h)), Vector2(float(profile.x), float(profile.h))).intersection(monster_visual)
	assert(monster_overlap.has_area())
	assert(point == monster_overlap.get_center(), "Monster impacts use the same overlap center rule")
	game.hit_effects.clear()
	game.damage_reaction.finish_getup()
	game._damage_player(10)
	assert(game.hit_effects.effects.is_empty(), "Invulnerability produces no false impact")
	game.hit_effects.play_at(Vector2.ZERO, Vector2.ZERO)
	game._enter_city(false)
	assert(game.hit_effects.effects.is_empty(), "Returning to the city clears old impacts")
	game.queue_free()
	await process_frame
	print("HIT_EFFECTS_TEST_OK")
	quit()
