extends SceneTree

const AccountServiceScript = preload("res://modules/account_service.gd")
const DEFAULT_STATS := {"race": "人族", "level": 1, "experience": 0, "max_health": 100, "max_mana": 100, "mana_regen": 1.0, "mana_absorb": 2.0, "attack": 10, "defense": 10, "attack_speed": 2.0, "move_speed": 100.0, "crit_rate": 5.0, "crit_damage": 150.0, "skill_haste": 100.0, "healing_power": 100.0, "life_steal": 0.0}


func _initialize() -> void:
	var service = AccountServiceScript.new()
	assert(service.truncate_role_name("测试名字ABCDEFG", 18).to_utf8_buffer().size() <= 18)
	assert(service.is_role_name_legal("旅者-01"))
	assert(not service.is_role_name_legal("旅者 01"))
	assert(not service.is_role_name_legal("旅者😀"))
	var accounts := {"acct_a": {"account_name": "alpha", "role_name": "旧名字"}}
	assert(service.find_account_id(accounts, "alpha") == "acct_a")
	assert(service.is_role_name_used(accounts, "旧名字", "acct_b"))
	assert(not service.is_role_name_used(accounts, "旧名字", "acct_a"))
	var migrated: Dictionary = service.normalize_player_stats({"attack_speed": 1.0, "level": 0}, DEFAULT_STATS)
	assert(migrated.attack_speed == 2.0 and migrated.level == 1)
	var generated: String = service.generate_account_id(accounts)
	assert(generated.begins_with("acct_") and not accounts.has(generated))
	print("ACCOUNT_SERVICE_TEST_OK")
	quit()
