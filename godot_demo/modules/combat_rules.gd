class_name CombatRules
extends RefCounted

var deterministic_attack_roll := 0

static func within_attack_ranges(offset: Vector2, target_height: float, attacker_height: float, horizontal: float, longitudinal: float, height_range: float) -> bool:
	return absf(offset.x) <= horizontal and absf(offset.y) <= longitudinal and target_height - attacker_height <= height_range


static func overlaps_hurtbox(offset: Vector2, target_height: float, attacker_height: float, horizontal: float, longitudinal: float, height_range: float, width: float, body_height: float) -> bool:
	# X is full width centered on the feet; H extends upwards from target feet.
	return absf(offset.x) <= horizontal + width * 0.5 and absf(offset.y) <= longitudinal \
		and target_height <= attacker_height + height_range and target_height + body_height >= attacker_height



func roll_crit(crit_rate: float) -> bool:
	deterministic_attack_roll += 1
	return fposmod(float(deterministic_attack_roll * 17), 100.0) < crit_rate


func compute_damage(attack_value: float, target_defense: float, allow_crit: bool, crit_rate: float, crit_damage: float) -> Dictionary:
	var crit_multiplier := 1.0
	var crit := false
	if allow_crit and roll_crit(crit_rate):
		crit = true
		crit_multiplier = crit_damage / 100.0
	var dealt := roundf(attack_value * crit_multiplier * 100.0 / (target_defense + 100.0))
	return {"damage": maxi(int(dealt), 1), "crit": crit}


func monster_definition(kind: int, position: Vector2, display_name: String, phase: float, experience_reward: int, view_width: float) -> Dictionary:
	var max_hp: int = [9, 18, 27, 120][kind]
	var attack_value: int = [4, 6, 8, 12][kind]
	var defense_value: int = [0, 5, 10, 18][kind]
	var attack_speed_value: float = [0.7, 0.8, 0.9, 1.0][kind]
	var move_speed_value: float = [80.0, 86.0, 92.0, 105.0][kind]
	return {
		"pos": position, "hp": max_hp, "max_hp": max_hp, "name": display_name,
		"kind": kind, "phase": phase, "hit": 0.0, "spawn_alpha": 0.0,
		"active": false, "engaged": false, "attack_cooldown": 0.0,
		"attack": attack_value, "defense": defense_value,
		"attack_speed": attack_speed_value, "move_speed": move_speed_value,
		"alert_range": view_width if kind == 3 else 360.0,
		"chase_distance": INF if kind == 3 else 520.0,
		"leash_distance": INF if kind == 3 else 760.0,
		"attack_range_x": 105.0 if kind == 3 else 82.0,
		"attack_range_y": 82.0 if kind == 3 else 62.0,
		"attack_range_height": 0.0, "character_height_px": 0.0,
		"target_rule": "最近单位", "experience_reward": experience_reward,
	}


static func interrupt_monster(monster: Dictionary) -> void:
	# Discard the current attack opportunity; recovery starts a fresh preparation.
	monster.hit = 0.18
	monster.attack_cooldown = 1.0 / maxf(float(monster.get("attack_speed", 1.0)), 0.01)
