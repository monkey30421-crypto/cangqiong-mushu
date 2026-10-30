extends RefCounted

signal attack_action_ended(skill_id: int, elapsed_after_event: float)

signal skill_effect_hit(skill_id: int, attack_distance_px: float, longitudinal_range_px: float, height_range_px: float, hit_stop_ms: float, hit_targets: Array, contact_area: Rect2)
const HitEffects = preload("res://modules/hit_effects.gd")
const SceneDepth = preload("res://modules/scene_depth.gd")
const SpineResources = preload("res://modules/spine_resources.gd")
const PIXELS_PER_METER := 100.0
const DEFAULT_ATTACK_DISTANCE_PX := 246.09375
static func pixels_to_meters(pixels: float) -> float:
	return pixels / PIXELS_PER_METER


# Owns resource mapping, hot reload and action-event VFX; combat values stay in main/rules.
const CONFIG_PATH := "res://config/character_actions.json"
const LIBRARY_PATH := SpineResources.DEFAULT_MODEL
const NAMES := {1001: &"stand1", 1002: &"walk1", 1003: &"run1", 1004: &"jump_up", 1005: &"jump_down", 1006: &"dodge", 1007: &"hurt", 1008: &"down_standing", 1010: &"getup_roll_forward", 1011: &"getup_roll_backward", 1012: &"getup", 1013: &"floated", 1014: &"down_launched", 1015: &"lying_loop", 1016: &"kneel_loop", 2004: &"jump_attack", 2005: &"dodge_attack", 2001: &"attack1", 2002: &"attack2", 2003: &"attack3"}
const HOLD_POSE_ANIMATION := "__hold_last_frame__"
const HOLD_POSE_IDS := [1015, 1016]
const LOOP_IDS := [1001, 1002, 1003, 1013, 1015, 1016]
var library_path := LIBRARY_PATH
var config_path := CONFIG_PATH
var rows: Dictionary = {}
var library: Dictionary = {}
var spine_resources := SpineResources.new()
var effect_data: Dictionary = {}
var revision := -1
var active_id := 0
var playback_serial := 0
var active_skill_hit := false
var playback_hit_windows: Dictionary = {}
var hit_stop_remaining := 0.0
var advance_elapsed := 0.0
var advance_facing := 1.0
var action_elapsed := 0.0
var action_first_tick := true
var action_end_emitted := false
var combo_attack_queued := false
var poll_elapsed := 0.0
var actor: SpineSprite
var preview: SpineSprite
var host: Node2D
var effects: Array[SpineSprite] = []
var effect_position := Vector2.ZERO
var facing := 1.0

func setup(owner_node: Node2D, player_sprite: SpineSprite, preview_sprite: SpineSprite) -> void:
	host = owner_node
	actor = player_sprite
	preview = preview_sprite
	# Gameplay and the native pose share one clock, including partial hit-stop frames.
	actor.set_update_mode(SpineConstant.UpdateMode_Manual)
	var data := load(library_path) as SpineSkeletonDataResource
	if data == null or not data.is_skeleton_data_loaded():
		return
	actor.skeleton_data_res = data
	preview.skeleton_data_res = data
	library = spine_resources.catalog(library_path)
	reload_config()

func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var value = JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}

func poll(delta: float, safe_to_reload: bool) -> bool:
	poll_elapsed += delta
	if poll_elapsed < 1.0 or not safe_to_reload or not effects.is_empty():
		return false
	poll_elapsed = 0.0
	return reload_config()

func reload_config() -> bool:
	var config := _read_json(config_path)
	if config.is_empty() or int(config.get("revision", -1)) == revision or library.is_empty():
		return false
	var next: Dictionary = {}
	for row in config.get("rows", []):
		if not row is Dictionary:
			return false
		var id := int(row.get("id", 0))
		if not NAMES.has(id) or next.has(id) or (not library.character.animations.has(row.get("animation", "")) and not (id in HOLD_POSE_IDS and row.get("animation") == HOLD_POSE_ANIMATION)):
			return false
		for layer in ["upper", "lower"]:
			if row.get(layer) != null and (not row[layer] is Dictionary or _effect_clip(row[layer]).is_empty()):
				return false
		if id >= 2000:
			var raw = row.get("attackDistancePx", DEFAULT_ATTACK_DISTANCE_PX)
			if not (raw is float or raw is int) or not is_finite(float(raw)) or float(raw) < 0.0:
				return false
			row.attackDistancePx = float(raw)
			for key in ["advanceDistancePx", "advanceDurationMs", "longitudinalRangePx", "heightRangePx", "hitStopMs"]:
				var value = row.get(key, float(raw) if key == "longitudinalRangePx" else 0.0)
				if not (value is float or value is int) or not is_finite(float(value)) or float(value) < 0.0:
					return false
				row[key] = float(value)
		next[id] = row
	if next.size() != NAMES.size():
		return false
	rows = next
	revision = int(config.revision)
	active_id = 0
	clear_effects()
	play(1001)
	return true

func _effect_resource(effect: Dictionary) -> String:
	for file in library.get("effects", []):
		if file.file == effect.get("file", ""):
			return str(file.get("resource", ""))
	return ""

func create_spine_effect(parent: Node2D, effect: Dictionary, position: Vector2, direction: float) -> SpineSprite:
	var path := _effect_resource(effect)
	if path.is_empty() or not path.begins_with("res://assets/") or ".." in path:
		return null
	var data: SpineSkeletonDataResource = effect_data.get(path)
	if data == null:
		data = load(path) as SpineSkeletonDataResource
		if data == null:
			return null
		effect_data[path] = data
	if not data.is_skeleton_data_loaded() or data.find_animation(StringName(str(effect.get("animation", "")))) == null:
		return null
	var sprite := SpineSprite.new()
	sprite.skeleton_data_res = data
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.set_update_mode(SpineConstant.UpdateMode_Manual)
	sprite.position = position
	sprite.scale = Vector2(signf(direction), 1.0)
	parent.add_child(sprite)
	sprite.get_animation_state().set_animation(StringName(str(effect.animation)), false, 0.0)
	sprite.update_skeleton(0.0)
	return sprite

func _clip(id: int) -> Dictionary:
	if rows[id].animation == HOLD_POSE_ANIMATION:
		return {"duration": 1.0, "events": [{"name": "action", "time": 0.0}]}
	return library.character.animations[rows[id].animation]

func duration(id: int) -> float:
	if not rows.has(id):
		return 0.0
	var clip: Dictionary = _clip(id)
	return maxf(float(clip.duration), 1.0 / 30.0)

func start_hit_stop(milliseconds: float) -> void:
	hit_stop_remaining = maxf(hit_stop_remaining, milliseconds / 1000.0)
	if hit_stop_remaining > 0.0:
		actor.get_animation_state().set_time_scale(0.0)

func consume_hit_stop(delta: float) -> float:
	var blocked := minf(delta, hit_stop_remaining)
	hit_stop_remaining = maxf(0.0, hit_stop_remaining - delta)
	actor.get_animation_state().set_time_scale(0.0 if hit_stop_remaining > 0.0 else 1.0)
	return delta - blocked

func attack_advance(delta: float) -> float:
	if active_id < 2000 or not rows.has(active_id):
		return 0.0
	var distance := float(rows[active_id].get("advanceDistancePx", 0.0))
	var seconds := float(rows[active_id].get("advanceDurationMs", 0.0)) / 1000.0
	# A dodge attack with distance only spreads its advance across the animation.
	if active_id == 2005 and seconds <= 0.0:
		seconds = duration(active_id)
	if distance <= 0.0 or seconds <= 0.0:
		return 0.0
	var before := advance_elapsed
	advance_elapsed = minf(seconds, before + maxf(delta, 0.0))
	return advance_facing * distance * (advance_elapsed - before) / seconds

func queue_combo_attack() -> bool:
	if active_id not in [2001, 2002] or not rows.has(active_id) or action_end_emitted:
		return false
	var clip: Dictionary = _clip(active_id)
	for event in clip.get("events", []):
		if event.get("name", "") == "actionEnd":
			var remaining := float(event.get("time", 0.0)) - action_elapsed
			if remaining > 0.0 and remaining <= 0.15 + 0.000001:
				combo_attack_queued = true
				return true
	return false

func consume_combo_attack() -> bool:
	var queued := combo_attack_queued
	combo_attack_queued = false
	return queued

func has_attack_tail() -> bool:
	return active_id >= 2000 and rows.has(active_id) and action_end_emitted and action_elapsed < duration(active_id)

func can_chain_attack() -> bool:
	if not rows.has(active_id) or active_id not in [2001, 2002]:
		return false
	if action_elapsed >= duration(active_id):
		return false
	var skill: Dictionary = rows[active_id]
	var clip: Dictionary = _clip(active_id)
	for event in clip.get("events", []):
		if event.get("name", "") == "actionEnd":
			return action_end_emitted
	# Effects never unlock combos; an explicit actionEnd event is required.
	return false

func play(id: int, restart := false) -> void:
	if not rows.has(id):
		return
	if active_id == id and not restart:
		return
	var cuts_action := (active_id >= 2000 and id >= 2000) or (active_id >= 2000 and id == 1006) or (active_id == 1006 and id == 2005)
	combo_attack_queued = false
	active_id = id
	playback_serial += 1
	playback_hit_windows = {}
	advance_elapsed = 0.0
	active_skill_hit = false
	action_elapsed = 0.0
	action_first_tick = true
	action_end_emitted = false
	var clip: Dictionary = _clip(id)
	if rows[id].animation == HOLD_POSE_ANIMATION:
		# Pin the previous transition to its final pose, including low-FPS frames.
		for sprite in [actor, preview]:
			var track = sprite.get_animation_state().get_track(0)
			if track != null:
				track.set_loop(false)
				track.set_track_time(maxf(track.get_track_time(), track.get_animation_end()))
		return
	var animation_name := StringName(str(clip.get("source_animation", rows[id].animation)))
	var loop := id in LOOP_IDS
	var actor_track = actor.get_animation_state().set_animation(animation_name, loop, 0)
	# Attacks, dodge cancels and dodge attacks replace the interrupted pose
	# immediately so the new animation and its action-event VFX stay together.
	if cuts_action:
		actor_track.set_mix_duration(0.0)
	actor.update_skeleton(0.0)
	var preview_track = preview.get_animation_state().set_animation(animation_name, loop, 0)
	if cuts_action:
		preview_track.set_mix_duration(0.0)

func _effect_clip(effect: Dictionary) -> Dictionary:
	for file in library.get("effects", []):
		if file.file == effect.get("file", ""):
			if not file.animations.has(effect.get("animation", "")):
				return {}
			var clip: Dictionary = file.animations[effect.animation]
			clip.resource = file.get("resource", "")
			return clip
	return {}

func _spawn_effect(effect: Dictionary, upper: bool, skill: Dictionary, remaining_delta: float) -> void:
	var clip := _effect_clip(effect).duplicate(true)
	if clip.is_empty():
		return
	var node := create_spine_effect(host, effect, effect_position, facing)
	if node == null:
		return
	SceneDepth.set_layer(node, SceneDepth.UPPER_EFFECT_Z if upper else SceneDepth.LOWER_EFFECT_Z)
	# The effect owns the casting skill's snapshot, even after another combo starts.
	node.set_meta("hit_context", {"serial": playback_serial, "clip": clip, "skill": skill.duplicate(true), "elapsed": 0.0, "first": true, "windows": _hit_windows(clip, action_elapsed - remaining_delta)})
	effects.append(node)
	# Advance from the actual action-event offset, including hit at time zero/end.
	_advance_effect(node, remaining_delta)

func _hit_windows(clip: Dictionary, trigger: float) -> Array:
	var windows: Array = []
	var start := -1.0
	for event in clip.get("events", []):
		var time := float(event.get("time", 0.0))
		if event.get("name", "") == "hit_start":
			start = time
		elif event.get("name", "") == "hit_end" and start >= 0.0:
			if time > start:
				# Upper/lower visuals of the same cast and interval share the hit ledger.
				var key := Vector2(trigger + start, trigger + time)
				if not playback_hit_windows.has(key):
					playback_hit_windows[key] = []
				windows.append({"start": start, "end": time, "targets": playback_hit_windows[key]})
			start = -1.0
	return windows

func _advance_effect(node: SpineSprite, delta: float) -> void:
	if not is_instance_valid(node) or not effects.has(node):
		return
	var context: Dictionary = node.get_meta("hit_context")
	var clip: Dictionary = context.clip
	var before := float(context.elapsed)
	var first := bool(context.first)
	var length := maxf(float(clip.duration), 1.0 / 30.0)
	var after := minf(before + maxf(delta, 0.0), length)
	# Apply this frame before a hit callback can freeze it. Source event times are
	# rounded decimals, e.g. 0.03333333 must resolve to frame 1 at 30 FPS.
	context.elapsed = after
	context.first = false
	node.update_skeleton(maxf(delta, 0.0))
	for window in context.windows:
		# Sample every frame overlapping [hit_start, hit_end), including skipped windows.
		# Each window retains references to victims already hit, never to missed targets.
		if before >= float(window.end) or after < float(window.start):
			continue
		if after <= before and not first:
			continue
		if context.skill.get("kind", "") == "skill":
			if int(context.serial) == playback_serial and int(context.skill.id) == active_id:
				active_skill_hit = true
			skill_effect_hit.emit(int(context.skill.id), float(context.skill.get("attackDistancePx", 0.0)), float(context.skill.get("longitudinalRangePx", DEFAULT_ATTACK_DISTANCE_PX)), float(context.skill.get("heightRangePx", 0.0)), float(context.skill.get("hitStopMs", 0.0)), window.targets, HitEffects.effect_area(clip, facing))
			if not effects.has(node):
				return
			if hit_stop_remaining > 0.0:
				break
	if after >= length and hit_stop_remaining <= 0.0:
		effects.erase(node)
		node.queue_free()

func advance(delta: float, position: Vector2, direction: float) -> void:
	effect_position = position
	facing = direction
	# Hit stop freezes animation time, not the shared screen origin. The camera
	# can still move, and the hit frame may have advanced the attack's position.
	for node in effects:
		if is_instance_valid(node):
			node.position = position
			node.scale = Vector2(signf(direction), 1.0)
	if hit_stop_remaining > 0.0:
		return
	if not rows.has(active_id):
		return
	var before := action_elapsed
	action_elapsed += maxf(delta, 0.0)
	actor.update_skeleton(maxf(delta, 0.0))
	for node in effects.duplicate():
		if not is_instance_valid(node):
			continue
		_advance_effect(node, delta)
	var skill: Dictionary = rows[active_id]
	var clip: Dictionary = _clip(active_id)
	var length := duration(active_id)
	for event in clip.get("events", []):
		if event.get("name", "") != "action":
			continue
		var time := float(event.get("time", 0.0))
		var first_cycle := floori(before / length) if active_id in LOOP_IDS else 0
		var last_cycle := floori(action_elapsed / length) if active_id in LOOP_IDS else 0
		for cycle in range(first_cycle, last_cycle + 1):
			var trigger := time + cycle * length
			if trigger <= action_elapsed and (trigger > before or (action_first_tick and is_zero_approx(trigger))):
				for layer in ["upper", "lower"]:
					if skill.get(layer) != null:
						_spawn_effect(skill[layer], layer == "upper", skill, action_elapsed - trigger)
	action_first_tick = false
	# Release controls independently of the remaining animation and VFX.
	# A hit callback above may freeze this very frame after crossing actionEnd.
	# Keep the queued attack on the same clock as the frozen native pose.
	if active_id >= 2000 and not action_end_emitted and hit_stop_remaining <= 0.0:
		for event in clip.get("events", []):
			if event.get("name", "") == "actionEnd" and action_elapsed >= float(event.get("time", 0.0)):
				action_end_emitted = true
				attack_action_ended.emit(active_id, maxf(0.0, action_elapsed - float(event.get("time", 0.0))))
				break

func clear_effects() -> void:
	combo_attack_queued = false
	playback_hit_windows = {}
	hit_stop_remaining = 0.0
	if is_instance_valid(actor):
		actor.get_animation_state().set_time_scale(1.0)
	for node in effects:
		node.hide()
		node.queue_free()
	effects.clear()
