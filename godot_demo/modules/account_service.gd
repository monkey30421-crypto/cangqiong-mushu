class_name AccountService
extends RefCounted

var _role_name_pattern := RegEx.create_from_string("^[\\p{Han}A-Za-z0-9\\p{P}\\p{S}]+$")


func truncate_role_name(value: String, maximum_bytes: int) -> String:
	var result := ""
	var used_bytes := 0
	for character_index in range(value.length()):
		var character := value.substr(character_index, 1)
		var character_bytes := character.to_utf8_buffer().size()
		if used_bytes + character_bytes > maximum_bytes:
			break
		result += character
		used_bytes += character_bytes
	return result


func contains_emoji(value: String) -> bool:
	for character_index in range(value.length()):
		var codepoint := value.unicode_at(character_index)
		if (codepoint >= 0x1F000 and codepoint <= 0x1FAFF) \
				or (codepoint >= 0x2600 and codepoint <= 0x27FF) \
				or (codepoint >= 0x2300 and codepoint <= 0x23FF) \
				or (codepoint >= 0x2B00 and codepoint <= 0x2BFF) \
				or codepoint == 0x200D or codepoint == 0xFE0F \
				or codepoint in [0x00A9, 0x00AE, 0x203C, 0x2049, 0x2122, 0x2139, 0x3030, 0x303D, 0x3297, 0x3299]:
			return true
	return false


func is_role_name_legal(value: String) -> bool:
	return not value.is_empty() and not contains_emoji(value) and _role_name_pattern.search(value) != null


func is_role_name_used(accounts: Dictionary, candidate: String, current_account_id: String) -> bool:
	for id in accounts:
		if str(id) != current_account_id and str(accounts[id].get("role_name", "")) == candidate:
			return true
	return false


func load_accounts(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


func save_accounts(path: String, accounts: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(accounts))


func normalize_account_record(record: Dictionary, account_name_value: String, default_stats: Dictionary) -> Dictionary:
	var normalized_role_name := str(record.get("role_name", ""))
	return {
		"inventory": record.get("inventory", {}).duplicate(true) if record.get("inventory", {}) is Dictionary else {},
		"account_name": account_name_value if not account_name_value.is_empty() else str(record.get("account_name", "")),
		"role_name": normalized_role_name,
		"character_creation_completed": bool(record.get("character_creation_completed", not normalized_role_name.is_empty())),
		"player_stats": normalize_player_stats(record.get("player_stats", record.get("stats", {})), default_stats),
	}


func normalize_player_stats(raw_stats: Variant, default_stats: Dictionary) -> Dictionary:
	var stats := default_stats.duplicate(true)
	if typeof(raw_stats) != TYPE_DICTIONARY:
		return stats
	var dictionary_stats := raw_stats as Dictionary
	for key in stats.keys():
		if not dictionary_stats.has(key):
			continue
		match key:
			"race":
				stats[key] = str(dictionary_stats[key]) if not str(dictionary_stats[key]).is_empty() else "人族"
			"level":
				stats[key] = maxi(int(dictionary_stats[key]), 1)
			"experience":
				stats[key] = maxi(int(dictionary_stats[key]), 0)
			"max_health", "max_mana", "attack", "defense":
				stats[key] = maxi(int(roundf(float(dictionary_stats[key]))), 1)
			"mana_regen", "attack_speed":
				stats[key] = maxf(float(dictionary_stats[key]), 0.01)
			"mana_absorb", "move_speed", "crit_rate", "crit_damage", "skill_haste", "healing_power", "life_steal":
				stats[key] = maxf(float(dictionary_stats[key]), 0.0)
	if dictionary_stats.has("attack_speed") and is_equal_approx(float(dictionary_stats["attack_speed"]), 1.0):
		stats["attack_speed"] = default_stats["attack_speed"]
	return stats


func find_account_id(accounts: Dictionary, account: String) -> String:
	for id in accounts:
		var record: Dictionary = accounts[id]
		if str(record.get("account_name", "")) == account:
			return str(id)
	return ""


func generate_account_id(accounts: Dictionary) -> String:
	var generated := ""
	while generated.is_empty() or accounts.has(generated):
		generated = "acct_" + Crypto.new().generate_random_bytes(16).hex_encode()
	return generated
