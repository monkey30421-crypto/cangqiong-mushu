extends SceneTree

const CombatRulesScript = preload("res://modules/combat_rules.gd")


func _initialize() -> void:
	var rules = CombatRulesScript.new()
	var normal: Dictionary = rules.compute_damage(10.0, 0.0, false, 100.0, 150.0)
	assert(normal.damage == 10 and not normal.crit)
	var critical: Dictionary = rules.compute_damage(10.0, 0.0, true, 100.0, 150.0)
	assert(critical.damage == 15 and critical.crit)
	var monster: Dictionary = rules.monster_definition(3, Vector2(100, 200), "首领", 0.0, 80, 1800.0)
	assert(monster.max_hp == 120 and monster.alert_range == 1800.0 and monster.experience_reward == 80)
	assert(rules.within_attack_ranges(Vector2(-20, 30), 110, 100, 20, 30, 10))
	assert(not rules.within_attack_ranges(Vector2(21, 30), 110, 100, 20, 30, 10))
	assert(not rules.within_attack_ranges(Vector2(20, -31), 110, 100, 20, 30, 10))
	assert(not rules.within_attack_ranges(Vector2(20, 30), 111, 100, 20, 30, 10))
	assert(rules.within_attack_ranges(Vector2(20, 30), 0, 100, 20, 30, 0))
	assert(monster.attack_range_height == 0 and monster.character_height_px == 0)
	print("COMBAT_RULES_TEST_OK")
	quit()
