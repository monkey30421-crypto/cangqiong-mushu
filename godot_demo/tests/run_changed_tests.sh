#!/bin/zsh
set -euo pipefail

project_root="${0:A:h:h}"
godot_bin="/Applications/Godot.app/Contents/MacOS/Godot"
typeset -A selected

run_test() {
	local test_name="${1:t:r}"
	local log_file="/private/tmp/cangqiong-mushu-${test_name}.log"
	local success_marker="$2"
	local output
	local checked_output
	local exit_code
	set +e
	output="$("$godot_bin" --headless --log-file "$log_file" --path "$project_root" --script "$1" --quit-after 300 2>&1)"
	exit_code=$?
	set -e
	print -r -- "$output"
	# Resource-loader and scene-tree errors must fail too, even when GDScript
	# continues to the success marker. Ignore only the known macOS CA lookup error.
	checked_output="$(print -r -- "$output" | sed '/^ERROR: Condition "ret != noErr" is true\. Returning: ""$/d')"
	if [[ "$output" != *"$success_marker"* || "$checked_output" == *"ERROR:"* || "$output" == *"SCRIPT ERROR"* || "$output" == *"Parse Error"* || "$output" == *"Assertion failed"* ]]; then
		return 1
	fi
	if (( exit_code != 0 )); then
		# Sandboxed macOS runs can report a non-fatal system CA lookup error.
		# Only accept that exit when the test reached its explicit success marker.
		if [[ "$output" == *"$success_marker"* \
			&& "$output" != *"SCRIPT ERROR"* \
			&& "$output" != *"Parse Error"* \
			&& "$output" != *"Assertion failed"* ]]; then
			return 0
		fi
		return $exit_code
	fi
	return 0
}

for changed_path in "$@"; do
	case "$changed_path" in
		*modules/city_training.gd|*tests/test_city_training.gd) selected[full]=1 ;;
		*modules/spine_resources.gd|*config/spine_effects.json|*tests/test_spine_resources.gd) selected[full]=1 ;;
		*tests/test_native_skill_effects.gd) selected[native_effects]=1 ;;
		*tests/test_monster_hit_reaction.gd) selected[monster_hit_reaction]=1 ;;
		*tests/test_dodge_cancel.gd) selected[dodge_cancel]=1 ;;
		*tests/test_action_end.gd) selected[action_end]=1 ;;
		*tests/test_hit_stop_timing.gd) selected[hit_stop_timing]=1 ;;
		*tests/test_camera_bounds.gd) selected[camera_bounds]=1 ;;
		*modules/scene_depth.gd|*tests/test_scene_depth.gd) selected[scene_depth]=1 ;;
		*modules/hit_effects.gd|*tests/test_hit_effects.gd|*assets/scene/effects/hit_common/*) selected[hit_effects]=1 ;;
		*tests/test_down_phase_loops.gd) selected[down_phases]=1 ;;
		*tests/test_knockdown_modes.gd) selected[knockdown_modes]=1 ;;
		*tests/test_monster_rendering.gd) selected[monster_rendering]=1 ;;
		*tests/test_monster_movement.gd) selected[monster_movement]=1 ;;
		*tests/test_monster_death_cleanup.gd) selected[monster_death]=1 ;;
		*tests/test_monster_attack_windows.gd) selected[monster_attack]=1 ;;
		*modules/monster_actions.gd|*config/monster_actions.json|*tests/test_monster_actions.gd) selected[monster_actions]=1; selected[down_phases]=1; selected[knockdown_modes]=1; selected[monster_rendering]=1; selected[monster_movement]=1; selected[monster_death]=1; selected[monster_attack]=1 ;;
		*modules/character_shadows.gd|*tests/test_character_shadows.gd|*assets/character/art/common_shadow.png) selected[shadows]=1 ;;
		*tests/test_dungeon_reentry.gd) selected[reentry]=1 ;;
		*modules/ground_loot.gd|*tests/test_ground_loot*.gd) selected[ground_loot]=1; selected[inventory]=1 ;;
		*modules/character_profiles.gd|*config/characters.json|*tests/test_character_profiles.gd) selected[full]=1 ;;
		*modules/character_actions.gd|*config/character_actions.json|*assets/character/art/player_animations/*|*assets/skill_effects/*|*tests/test_skill_hit.gd|*tests/test_character_actions.gd) selected[native_effects]=1; selected[hit_stop_timing]=1; selected[character_actions]=1; selected[action_end]=1; selected[dodge_cancel]=1; selected[down_phases]=1 ;;
		*modules/account_service.gd|*tests/test_account_service.gd) selected[account]=1; selected[inventory]=1 ;;
		*modules/inventory_service.gd|*ui/inventory_panel.gd|*config/inventory.json|*tests/test_inventory*.gd) selected[inventory]=1 ;;
		*modules/damage_reaction.gd|*tests/test_damage_reaction.gd) selected[full]=1 ;;
		*modules/combat_rules.gd|*tests/test_combat_rules.gd) selected[combat]=1 ;;
		*modules/dungeon_route_generator.gd|*tests/test_dungeon_route_generator.gd) selected[route]=1 ;;
		*modules/map_geometry.gd|*tests/test_map_geometry.gd) selected[geometry]=1 ;;
		*modules/spine_atlas_frames.gd|*tests/test_spine_atlas_frames.gd) selected[spine_atlas]=1 ;;
		*assets/scene/effects/altar_tree/*) selected[spine_atlas]=1; selected[altar_animation]=1 ;;
		*tests/test_altar_tree_anchor.gd) selected[altar_anchor]=1 ;;
		*build_altar_tree_animations.py|*tests/test_altar_tree_animations.gd) selected[altar_animation]=1 ;;
		*main.gd|*main.tscn|*project.godot|*test_demo.gd) selected[full]=1 ;;
		*.gd|*.tscn|*.tres) selected[full]=1 ;;
	esac
done

if (( ${#selected} == 0 )); then
	print "没有匹配到需要运行的 Godot 测试。"
	exit 0
fi


if [[ -n "${selected[full]-}" ]]; then
	run_test res://tests/test_city_training.gd CITY_TRAINING_TEST_OK
	run_test res://tests/test_spine_resources.gd SPINE_RESOURCES_TEST_OK
	run_test res://tests/test_native_skill_effects.gd NATIVE_SKILL_EFFECTS_TEST_OK
	run_test res://tests/test_monster_hit_reaction.gd MONSTER_HIT_REACTION_TEST_OK
	run_test res://tests/test_character_profiles.gd CHARACTER_PROFILES_TEST_OK
	run_test res://tests/test_hit_stop_timing.gd HIT_STOP_TIMING_TEST_OK
	run_test res://tests/test_camera_bounds.gd CAMERA_BOUNDS_TEST_OK
	run_test res://tests/test_scene_depth.gd SCENE_DEPTH_TEST_OK
	run_test res://tests/test_hit_effects.gd HIT_EFFECTS_TEST_OK
	run_test res://tests/test_monster_attack_windows.gd MONSTER_ATTACK_WINDOWS_TEST_OK
	run_test res://tests/test_monster_death_cleanup.gd MONSTER_DEATH_CLEANUP_TEST_OK
	run_test res://tests/test_monster_movement.gd MONSTER_MOVEMENT_TEST_OK
	run_test res://tests/test_monster_rendering.gd MONSTER_RENDERING_TEST_OK
	run_test res://tests/test_down_phase_loops.gd DOWN_PHASE_LOOPS_TEST_OK
	run_test res://tests/test_knockdown_modes.gd KNOCKDOWN_MODES_TEST_OK
	run_test res://tests/test_monster_actions.gd MONSTER_ACTIONS_TEST_OK
	run_test res://tests/test_character_shadows.gd CHARACTER_SHADOWS_TEST_OK
	run_test res://tests/test_dungeon_reentry.gd DUNGEON_REENTRY_TEST_OK
	run_test res://tests/test_getup_roll.gd GETUP_ROLL_TEST_OK
	run_test res://tests/test_ground_loot.gd GROUND_LOOT_TEST_OK
	run_test res://tests/test_ground_loot_integration.gd GROUND_LOOT_INTEGRATION_TEST_OK
	run_test res://tests/test_dodge_cancel.gd DODGE_CANCEL_TEST_OK
	run_test res://tests/test_action_end.gd ACTION_END_TEST_OK
	run_test res://tests/test_longitudinal_config.gd LONGITUDINAL_CONFIG_TEST_OK
	run_test res://tests/test_recovery_invulnerability.gd RECOVERY_INVULNERABILITY_TEST_OK
	run_test res://tests/test_monster_interrupt.gd MONSTER_INTERRUPT_TEST_OK
	run_test res://tests/test_damage_reaction.gd DAMAGE_REACTION_TEST_OK
	run_test res://tests/test_altar_tree_anchor.gd ALTAR_TREE_ANCHOR_TEST_OK
	run_test res://test_demo.gd DEMO_SELF_TEST_OK
	run_test res://tests/test_character_actions.gd CHARACTER_ACTIONS_TEST_OK
	run_test res://tests/test_skill_hit.gd SKILL_HIT_TEST_OK
	run_test res://tests/test_combat_rules.gd COMBAT_RULES_TEST_OK
	run_test res://tests/test_inventory.gd INVENTORY_TEST_OK
	run_test res://tests/test_inventory_integration.gd INVENTORY_INTEGRATION_TEST_OK
	exit 0
fi
[[ -n "${selected[native_effects]-}" ]] && run_test res://tests/test_native_skill_effects.gd NATIVE_SKILL_EFFECTS_TEST_OK
[[ -n "${selected[monster_hit_reaction]-}" ]] && run_test res://tests/test_monster_hit_reaction.gd MONSTER_HIT_REACTION_TEST_OK
[[ -n "${selected[hit_stop_timing]-}" ]] && run_test res://tests/test_hit_stop_timing.gd HIT_STOP_TIMING_TEST_OK
[[ -n "${selected[camera_bounds]-}" ]] && run_test res://tests/test_camera_bounds.gd CAMERA_BOUNDS_TEST_OK
[[ -n "${selected[scene_depth]-}" ]] && run_test res://tests/test_scene_depth.gd SCENE_DEPTH_TEST_OK
[[ -n "${selected[hit_effects]-}" ]] && run_test res://tests/test_hit_effects.gd HIT_EFFECTS_TEST_OK
[[ -n "${selected[monster_attack]-}" ]] && run_test res://tests/test_monster_attack_windows.gd MONSTER_ATTACK_WINDOWS_TEST_OK
[[ -n "${selected[monster_death]-}" ]] && run_test res://tests/test_monster_death_cleanup.gd MONSTER_DEATH_CLEANUP_TEST_OK
[[ -n "${selected[monster_movement]-}" ]] && run_test res://tests/test_monster_movement.gd MONSTER_MOVEMENT_TEST_OK
[[ -n "${selected[monster_rendering]-}" ]] && run_test res://tests/test_monster_rendering.gd MONSTER_RENDERING_TEST_OK
[[ -n "${selected[down_phases]-}" ]] && run_test res://tests/test_down_phase_loops.gd DOWN_PHASE_LOOPS_TEST_OK
[[ -n "${selected[knockdown_modes]-}" ]] && run_test res://tests/test_knockdown_modes.gd KNOCKDOWN_MODES_TEST_OK
[[ -n "${selected[monster_actions]-}" ]] && run_test res://tests/test_monster_actions.gd MONSTER_ACTIONS_TEST_OK
[[ -n "${selected[shadows]-}" ]] && run_test res://tests/test_character_shadows.gd CHARACTER_SHADOWS_TEST_OK
[[ -n "${selected[reentry]-}" ]] && run_test res://tests/test_dungeon_reentry.gd DUNGEON_REENTRY_TEST_OK
[[ -n "${selected[ground_loot]-}" ]] && run_test res://tests/test_ground_loot.gd GROUND_LOOT_TEST_OK
[[ -n "${selected[ground_loot]-}" ]] && run_test res://tests/test_ground_loot_integration.gd GROUND_LOOT_INTEGRATION_TEST_OK
[[ -n "${selected[dodge_cancel]-}" ]] && run_test res://tests/test_dodge_cancel.gd DODGE_CANCEL_TEST_OK
[[ -n "${selected[action_end]-}" ]] && run_test res://tests/test_action_end.gd ACTION_END_TEST_OK
[[ -n "${selected[character_actions]-}" ]] && run_test res://tests/test_character_actions.gd CHARACTER_ACTIONS_TEST_OK
[[ -n "${selected[character_actions]-}" ]] && run_test res://tests/test_skill_hit.gd SKILL_HIT_TEST_OK
[[ -n "${selected[inventory]-}" ]] && run_test res://tests/test_inventory.gd INVENTORY_TEST_OK
[[ -n "${selected[inventory]-}" ]] && run_test res://tests/test_inventory_integration.gd INVENTORY_INTEGRATION_TEST_OK
[[ -n "${selected[account]-}" ]] && run_test res://tests/test_account_service.gd ACCOUNT_SERVICE_TEST_OK
[[ -n "${selected[combat]-}" ]] && run_test res://tests/test_combat_rules.gd COMBAT_RULES_TEST_OK
[[ -n "${selected[route]-}" ]] && run_test res://tests/test_dungeon_route_generator.gd DUNGEON_ROUTE_GENERATOR_TEST_OK
[[ -n "${selected[geometry]-}" ]] && run_test res://tests/test_map_geometry.gd MAP_GEOMETRY_TEST_OK
[[ -n "${selected[spine_atlas]-}" ]] && run_test res://tests/test_spine_atlas_frames.gd SPINE_ATLAS_FRAMES_TEST_OK
[[ -n "${selected[altar_anchor]-}" ]] && run_test res://tests/test_altar_tree_anchor.gd ALTAR_TREE_ANCHOR_TEST_OK
[[ -n "${selected[altar_animation]-}" ]] && run_test res://tests/test_altar_tree_animations.gd ALTAR_TREE_ANIMATIONS_TEST_OK
exit 0
