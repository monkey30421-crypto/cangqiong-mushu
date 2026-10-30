extends RefCounted

signal attack_effect_hit(monster: Dictionary, attack: Dictionary, hit_targets: Array, contact_area: Rect2)

const Resources = preload("res://modules/character_actions.gd")
const CONFIG_PATH := "res://config/monster_actions.json"
const KEYS := ["idle", "move_front", "move_back", "attack1", "attack2", "skill1", "skill2", "hurt", "floated", "down", "down_fly", "lying_loop", "getup"]
const LOOP_KEYS := ["idle", "move_front", "move_back", "floated", "lying_loop"]
const GROUND_LOOP_KEYS := ["lying_loop"]
const ATTACK_KEYS := ["attack1", "attack2"]
const BOSS_ATTACK_KEYS := ["attack1", "attack2", "skill1", "skill2"]
var rows: Dictionary = {}
var native_sprites: Array[SpineSprite] = []
var actor_canvases: Array[Node2D] = []
var resources := Resources.new()
var corpses: Array[Dictionary] = []

func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var value = JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}

func load_config(path: String = CONFIG_PATH) -> bool:
	var config := _read_json(path)
	if config.get("version") != 1 or not config.get("monsters") is Array:
		return false
	var next: Dictionary = {}
	for entry in config.monsters:
		if not entry is Dictionary or int(entry.get("characterId", 0)) < 101 or next.has(int(entry.characterId)) or not entry.get("actions") is Array:
			return false
		var actions: Dictionary = {}
		var legacy_death: Dictionary = {}
		for action in entry.actions:
			if not action is Dictionary:
				return false
			var action_key := "attack1" if str(action.get("key", "")) == "attack" else str(action.get("key", ""))
			if action_key == "move":
				action_key = "move_front"
			if action_key == "death":
				legacy_death = action
				continue
			if not KEYS.has(action_key) or actions.has(action_key):
				return false
			actions[action_key] = action.duplicate(true)
			actions[action_key].key = action_key
		if not legacy_death.is_empty() and (not actions.has("down") or (actions.down.get("animation") == null and actions.down.get("upper") == null and actions.down.get("lower") == null)):
			actions.down = legacy_death.duplicate(true)
			actions.down.key = "down"
		for key in KEYS:
			if not actions.has(key):
				actions[key] = {"key": key, "animation": null, "upper": null, "lower": null}
		next[int(entry.characterId)] = actions
	rows = next
	resources.spine_resources = Resources.SpineResources.new()
	resources.library = resources.spine_resources.catalog()
	return true

func clear() -> void:
	corpses.clear()
	for sprite in native_sprites:
		if is_instance_valid(sprite):
			sprite.queue_free()
	native_sprites.clear()
	for canvas in actor_canvases:
		if is_instance_valid(canvas):
			canvas.hide()
			canvas.queue_free()
	actor_canvases.clear()

func action(monster: Dictionary, key: String) -> Dictionary:
	var row: Dictionary = rows.get(int(monster.get("character_id", 0)), {}).get(key, {"key": key, "animation": null, "upper": null, "lower": null})
	# Landing is optional: an empty editor selection must not infer a model animation.
	if key == "down_fly":
		return row
	if row.get("animation") == null:
		var model_library := str(monster.get("model_resource", ""))
		if model_library.ends_with(".tres"):
			var model_animation := _default_model_animation(model_library, key)
			if not model_animation.is_empty():
				var model_row := row.duplicate(true)
				model_row.animation = {"library": model_library, "name": model_animation}
				return model_row
	if not str(monster.get("model_resource", "")).ends_with(".tres") and key == "floated" and row.get("animation") == null:
		var floated := row.duplicate(true)
		floated.animation = {"library": Resources.LIBRARY_PATH, "name": "floated"}
		return floated
	if not str(monster.get("model_resource", "")).ends_with(".tres") and key == "getup" and row.get("animation") == null:
		var getup := row.duplicate(true)
		getup.animation = {"library": Resources.LIBRARY_PATH, "name": "die_Up"}
		return getup
	return row

func _native_source(model_resource: String) -> Dictionary:
	return resources.spine_resources.source(model_resource)

func _body_resource(monster: Dictionary, key: String) -> String:
	var mapping: Variant = action(monster, key).get("animation")
	if mapping is Dictionary:
		return str(mapping.get("library", ""))
	if key in GROUND_LOOP_KEYS:
		var held: Dictionary = monster.get("action_state", {}).get("held_clip", {})
		if not held.is_empty():
			return str(held.get("resource", ""))
	var model := str(monster.get("model_resource", ""))
	return model if model.ends_with(".tres") else ""

func _native_animation_name(monster: Dictionary, key: String) -> String:
	var source := _native_source(_body_resource(monster, key))
	var animations: Dictionary = source.get("animations", {})
	var configured: Variant = action(monster, key).get("animation")
	if configured is Dictionary and animations.has(str(configured.get("name", ""))):
		return str(configured.name)
	if key == "down_fly":
		return ""
	var defaults := {
		"idle": ["idle", "idle_SingleWeapon"], "move_front": ["move_front", "run_SingleWeapon", "move"],
		"move_back": ["move_back", "move_front", "run_SingleWeapon", "move"],
		"attack1": ["attack_1", "attack1_SingleSword", "attack1"], "attack2": ["attack_2", "attack2_SingleSword", "attack2"],
		"skill1": ["casting", "attack3_SingleSword", "skill1"], "skill2": ["skill_emit", "jumpAttack_SingleWeapon", "skill2"],
		"hurt": ["hit", "hit_SingleWeapon2", "hurt"], "floated": ["floated"],
		"down_fly": ["die_floated", "down_fly"], "down": ["die", "die_SingleSword", "down"],
		"getup": ["die_up", "die_Up", "getup"]
	}
	for candidate in defaults.get(key, []):
		if animations.has(candidate):
			return candidate
	return ""

func _native_clip(monster: Dictionary, key: String) -> Dictionary:
	var path := _body_resource(monster, key)
	return resources.spine_resources.animations(path).get(_native_animation_name(monster, key), {})

func _ensure_native_sprite(canvas: CanvasItem, monster: Dictionary) -> SpineSprite:
	var key := str(monster.get("action_state", {}).get("key", "idle"))
	var resource_path := _body_resource(monster, key)
	if _native_source(resource_path).is_empty():
		return null
	var actor_canvas: Node2D = monster.get("render_canvas")
	if is_instance_valid(actor_canvas) and not actor_canvas.is_queued_for_deletion():
		canvas = actor_canvas
	var sprite: SpineSprite = monster.get("native_spine_sprite")
	if is_instance_valid(sprite) and not sprite.is_queued_for_deletion():
		if sprite.get_parent() != canvas:
			sprite.reparent(canvas, false)
		if sprite.skeleton_data_res.resource_path != resource_path:
			sprite.skeleton_data_res = load(resource_path) as SpineSkeletonDataResource
			sprite.set_meta("animation_key", "")
			sprite.set_meta("animation_name", "")
		return sprite
	if not canvas is Node2D:
		return null
	var data := load(resource_path) as SpineSkeletonDataResource
	if data == null:
		return null
	sprite = SpineSprite.new()
	sprite.name = "MonsterSpine_%d" % int(monster.get("character_id", 0))
	sprite.skeleton_data_res = data
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	(canvas as Node2D).add_child(sprite)
	monster.native_spine_sprite = sprite
	native_sprites.append(sprite)
	return sprite

func prepare_actor_canvas(host: Node2D, monster: Dictionary, draw_callback: Callable) -> Node2D:
	var canvas: Node2D = monster.get("render_canvas")
	if not is_instance_valid(canvas) or canvas.is_queued_for_deletion():
		canvas = Node2D.new()
		canvas.name = "MonsterBody_%d" % int(monster.get("character_id", 0))
		host.add_child(canvas)
		canvas.draw.connect(draw_callback.bind(monster, canvas))
		monster.render_canvas = canvas
		actor_canvases.append(canvas)
	prepare_native_sprite(canvas, monster)
	canvas.queue_redraw()
	return canvas

func prepare_native_sprite(host: Node2D, monster: Dictionary) -> void:
	if not _body_resource(monster, str(monster.get("action_state", {}).get("key", "idle"))).is_empty():
		_ensure_native_sprite(host, monster)

func _draw_native_spine(canvas: CanvasItem, monster: Dictionary, position: Vector2, tint: Color) -> bool:
	var sprite := _ensure_native_sprite(canvas, monster)
	if not is_instance_valid(sprite):
		return false
	var key := str(monster.get("action_state", {}).get("key", "idle"))
	var animation_name := _native_animation_name(monster, key)
	var source := _native_source(_body_resource(monster, key))
	var hold_ground_pose: bool = key in GROUND_LOOP_KEYS and animation_name.is_empty()
	if (animation_name.is_empty() and not hold_ground_pose) or not source:
		sprite.hide()
		return false
	sprite.show()
	sprite.position = position
	# X/H configure the hurtbox, never the size of the artwork.
	sprite.scale = Vector2(float(monster.get("facing", 1.0)), 1.0)
	sprite.modulate = tint
	# The whole individual (native Spine and labels) inherits
	# its ground-Y rank from its render canvas. Jump height only offsets artwork.
	sprite.z_as_relative = true
	sprite.z_index = 0
	var state: Dictionary = monster.get("action_state", {})
	if hold_ground_pose:
		var track = sprite.get_animation_state().get_track(0)
		if track == null:
			sprite.hide()
			return false
		# Native Spine assets often have no dedicated ground-loop animation. Keep the
		# preceding fall/death animation's terminal pose visible instead of hiding the sprite.
		track.set_loop(false)
		track.set_track_time(maxf(track.get_track_time(), track.get_animation_end()))
		sprite.get_animation_state().set_time_scale(0.0)
		sprite.set_meta("animation_key", key)
		sprite.set_meta("animation_name", str(track.get_animation().get_name()))
		return true
	if str(sprite.get_meta("animation_key", "")) != key or str(sprite.get_meta("animation_name", "")) != animation_name:
		sprite.get_animation_state().set_animation(StringName(animation_name), key in LOOP_KEYS, 0)
		sprite.set_meta("animation_key", key)
		sprite.set_meta("animation_name", animation_name)
	sprite.get_animation_state().set_time_scale(0.0 if float(monster.get("hit_stop_remaining", 0.0)) > 0.0 else 1.0)
	return true

func _default_model_animation(library: String, key: String) -> String:
	var defaults := {
		"idle": ["idle_SingleWeapon", "idle"],
		"move_front": ["move_front", "run_SingleWeapon", "move"],
		"move_back": ["move_back", "move_front", "run_SingleWeapon", "move"],
		"attack1": ["attack1_SingleSword", "attack_1", "attack1"],
		"attack2": ["attack2_SingleSword", "attack_2", "attack2"],
		"skill1": ["attack3_SingleSword", "casting", "skill1"],
		"skill2": ["jumpAttack_SingleWeapon", "skill_emit", "skill2"],
		"hurt": ["hit_SingleWeapon2", "hit", "hurt"],
		"floated": ["floated"],
		"down_fly": ["die_floated", "down_fly"],
		"down": ["die_SingleSword", "die", "down"],
		"getup": ["die_Up", "getup", "die_up"]
	}
	for candidate in defaults.get(key, []):
		if not _body_clip({"animation": {"library": library, "name": candidate}}).is_empty():
			return candidate
	return ""

func _body_clip(row: Dictionary) -> Dictionary:
	var mapping = row.get("animation")
	if not mapping is Dictionary:
		return {}
	return resources.spine_resources.animations(str(mapping.get("library", ""))).get(str(mapping.get("name", "")), {})

func _clip_duration(clip: Dictionary) -> float:
	return maxf(float(clip.get("duration", 0.0)), 1.0 / 30.0)

func duration(monster: Dictionary, key: String) -> float:
	var native_clip := _native_clip(monster, key)
	if not native_clip.is_empty():
		return maxf(float(native_clip.duration), 1.0 if key == "floated" and is_zero_approx(float(native_clip.duration)) else 1.0 / 30.0)
	if key == "down_fly":
		return 0.0
	var row := action(monster, key)
	var clip := _body_clip(row)
	if not clip.is_empty():
		if key == "floated" and is_zero_approx(float(clip.get("duration", 0.0))):
			return maxf(1.0, _clip_duration(clip))
		return _clip_duration(clip)
	var result := float({"idle": 1.0, "move_front": 1.0, "move_back": 1.0, "attack1": 0.35, "attack2": 0.35, "skill1": 0.8, "skill2": 0.8, "hurt": 0.18, "down": 0.6, "down_fly": 0.4333333, "lying_loop": 1.0}.get(key, 0.0))
	for layer in ["upper", "lower"]:
		if row.get(layer) is Dictionary:
			var effect := resources._effect_clip(row[layer])
			if not effect.is_empty():
				result = maxf(result, _clip_duration(effect))
	return result

func play(monster: Dictionary, key: String, restart: bool = false) -> void:
	if key == "down_fly" and duration(monster, key) <= 0.0:
		key = "lying_loop"
	if monster.get("action_state", {}).get("key") == key and not restart:
		return
	var held_clip: Dictionary = {}
	if key in GROUND_LOOP_KEYS and action(monster, key).get("animation") == null:
		var previous: Dictionary = monster.get("action_state", {})
		held_clip = previous.get("held_clip", {})
		if held_clip.is_empty():
			held_clip = _body_clip(action(monster, str(previous.get("key", "idle"))))
	var effects: Array = []
	if key in BOSS_ATTACK_KEYS or key in ["idle", "move_front", "move_back"]:
		# Completed body animations may leave their attack effects playing. A new cast
		# gets a separate hit ledger; reactions still cancel all previous attack effects.
		for effect in monster.get("action_state", {}).get("effects", []):
			if effect.get("attack", {}) is Dictionary and not effect.get("attack", {}).is_empty():
				effects.append(effect)
	for old_effect in monster.get("action_state", {}).get("effects", []):
		if not effects.has(old_effect):
			var old_sprite: SpineSprite = old_effect.get("sprite")
			if is_instance_valid(old_sprite):
				old_sprite.queue_free()
	var attack := {}
	if key in BOSS_ATTACK_KEYS:
		attack = {"attack": float(monster.get("attack", 0.0)), "range_x": float(monster.get("attack_range_x", 0.0)), "range_y": float(monster.get("attack_range_y", 0.0)), "range_h": float(monster.get("attack_range_height", 0.0))}
	monster.action_state = {"key": key, "elapsed": 0.0, "first_tick": true, "effects": effects, "held_clip": held_clip, "attack": attack, "hit_windows": {}}

func busy(monster: Dictionary) -> bool:
	var state: Dictionary = monster.get("action_state", {})
	return str(state.get("key", "")) in ["attack", "attack1", "attack2", "skill1", "skill2", "hurt", "getup"] and float(state.get("elapsed", 0.0)) < duration(monster, str(state.key))

func choose_attack(monster: Dictionary) -> String:
	var choices: Array = BOSS_ATTACK_KEYS if str(monster.get("monster_type", "normal")) == "boss" else ATTACK_KEYS
	return str(choices[randi_range(0, choices.size() - 1)])

func interrupt(monster: Dictionary) -> void:
	var knocked_down: bool = monster.has("damage_reaction") and monster.damage_reaction.down_remaining > 0.0
	var key := down_action(monster) if int(monster.hp) <= 0 or knocked_down else "hurt"
	# Losing health while already down changes life state, not the ongoing pose.
	var same_dead_pose: bool = int(monster.hp) <= 0 and monster.get("action_state", {}).get("key") == key
	play(monster, key, not same_dead_pose)
	_tick(monster, 0.0)

func down_action(monster: Dictionary) -> String:
	var phase: String = monster.damage_reaction.knockdown_action() if monster.has("damage_reaction") else "down"
	if not bool(monster.get("can_be_launched", str(monster.get("monster_type", "normal")) != "boss")):
		phase = "down"
	if phase == "floated":
		return phase
	if phase == "down_fly" and duration(monster, phase) <= 0.0:
		return "lying_loop"
	var state: Dictionary = monster.get("action_state", {})
	if phase == "down_fly" and state.get("key") == "lying_loop":
		return "lying_loop"
	if phase == "down_fly" and state.get("key") == phase and float(state.get("elapsed", 0.0)) >= duration(monster, phase):
		return "lying_loop"
	return phase

func update_movement(monster: Dictionary, target_position: Vector2, displacement: Vector2) -> void:
	# Facing follows the target, never the movement vector. Use resolved terrain motion.
	var target_x := target_position.x - Vector2(monster.pos).x
	if absf(target_x) > 0.1:
		monster.facing = signf(target_x)
	monster.moving = displacement.length_squared() > 0.000001
	monster.movement_action = "move_back" if displacement.x * float(monster.get("facing", 1.0)) < -0.000001 else "move_front"

func advance_reaction(monster: Dictionary, delta: float, clamp_position: Callable) -> void:
	var blocked := minf(delta, float(monster.get("hit_stop_remaining", 0.0)))
	var motion_delta := delta - blocked
	monster.hit_stop_remaining = maxf(0.0, float(monster.get("hit_stop_remaining", 0.0)) - delta)
	if monster.has("damage_reaction"):
		monster.damage_reaction.advance(motion_delta)
		if monster.damage_reaction.knockback_remaining > 0.0:
			var knockback: Dictionary = monster.damage_reaction.advance_knockback(motion_delta)
			var position := Vector2(monster.get("pos", Vector2.ZERO))
			position.x += float(knockback.offset_x)
			monster.pos = clamp_position.call(position)
			monster.character_height_px = float(knockback.height)
		elif monster.has("character_height_px"):
			monster.character_height_px = 0.0
		var push_offset: float = monster.damage_reaction.advance_pushback(motion_delta)
		if not is_zero_approx(push_offset):
			monster.pos = clamp_position.call(Vector2(monster.pos) + Vector2(push_offset, 0.0))
	monster.hit = maxf(0.0, float(monster.get("hit", 0.0)) - motion_delta)
	advance(monster, motion_delta)

func advance(monster: Dictionary, delta: float) -> void:
	var state: Dictionary = monster.get("action_state", {})
	var key: String = str(state.get("key", "idle"))
	if int(monster.hp) <= 0:
		play(monster, down_action(monster))
	elif monster.has("damage_reaction") and monster.damage_reaction.down_remaining > 0.0:
		play(monster, down_action(monster))
	elif float(monster.get("hit", 0.0)) > 0.0:
		play(monster, "hurt")
	elif key in ["down", "down_fly", "lying_loop"] and duration(monster, "getup") > 0.0:
		if monster.has("damage_reaction"):
			monster.damage_reaction.down_kind = "standing"
		play(monster, "getup")
	elif not busy(monster):
		play(monster, str(monster.get("movement_action", "move_front")) if bool(monster.get("moving", false)) else "idle")
	_tick(monster, maxf(delta, 0.0))

func _tick(monster: Dictionary, delta: float) -> void:
	var state: Dictionary = monster.action_state
	for effect in state.effects.duplicate():
		_advance_effect(monster, effect, delta)
		if not is_same(monster.action_state, state):
			return
	var before := float(state.elapsed)
	state.elapsed = before + delta
	var row := action(monster, str(state.key))
	# Use the same source that is actually rendered, including native Spine models.
	var clip := _native_clip(monster, str(state.key))
	var events: Array = clip.get("events", []).filter(func(event): return event.get("name", "") == "action")
	var length := maxf(duration(monster, str(state.key)), 0.001)
	var first_cycle := floori(before / length) if state.key in LOOP_KEYS else 0
	var last_cycle := floori(float(state.elapsed) / length) if state.key in LOOP_KEYS else 0
	for cycle in range(first_cycle, last_cycle + 1):
		for event in events:
			var time := float(event.get("time", 0.0)) + cycle * length
			if time > float(state.elapsed) or not (time > before or (bool(state.first_tick) and is_zero_approx(time))):
				continue
			for layer in ["upper", "lower"]:
				if row.get(layer) is Dictionary:
					var effect := resources._effect_clip(row[layer]).duplicate(true)
					if not effect.is_empty():
						var visual := {"layer": layer, "clip": effect, "selected": row[layer].duplicate(true), "elapsed": 0.0, "first_tick": true, "attack": state.get("attack", {}).duplicate(true), "windows": _hit_windows(effect, time, state)}
						state.effects.append(visual)
						# A long frame may cross the entire hit window. Resolve it before
						# discarding an effect that has already finished visually.
						_advance_effect(monster, visual, float(state.elapsed) - time)
						if not is_same(monster.action_state, state):
							return
	state.first_tick = false

func _hit_windows(clip: Dictionary, trigger: float, state: Dictionary) -> Array:
	var windows: Array = []
	var start := -1.0
	for event in clip.get("events", []):
		var time := float(event.get("time", 0.0))
		if event.get("name", "") == "hit_start":
			start = time
		elif event.get("name", "") == "hit_end" and start >= 0.0:
			if time > start:
				var key := Vector2(trigger + start, trigger + time)
				if not state.hit_windows.has(key):
					state.hit_windows[key] = []
				windows.append({"start": start, "end": time, "targets": state.hit_windows[key]})
			start = -1.0
	return windows

func _advance_effect(monster: Dictionary, effect: Dictionary, delta: float) -> void:
	var effects: Array = monster.action_state.effects
	if not effects.has(effect):
		return
	var before := float(effect.elapsed)
	var after := minf(before + maxf(0.0, delta), _clip_duration(effect.clip))
	var visual_sprite: SpineSprite = effect.get("sprite")
	if is_instance_valid(visual_sprite):
		visual_sprite.update_skeleton(maxf(delta, 0.0))
	for window in effect.get("windows", []):
		if before >= float(window.end) or after < float(window.start):
			continue
		if after <= before and not bool(effect.get("first_tick", true)):
			continue
		if not effect.get("attack", {}).is_empty() and not window.targets.has(1):
			attack_effect_hit.emit(monster, effect.attack, window.targets, Resources.HitEffects.effect_area(effect.clip, float(monster.get("facing", 1.0))))
			if not monster.action_state.effects.has(effect):
				return
	effect.elapsed = after
	effect.first_tick = false
	if after >= _clip_duration(effect.clip):
		monster.action_state.effects.erase(effect)
		if is_instance_valid(visual_sprite):
			visual_sprite.queue_free()

func retire(monster: Dictionary) -> void:
	if bool(monster.get("death_visual_started", false)):
		return
	monster.death_visual_started = true
	var key := down_action(monster)
	play(monster, key)
	_tick(monster, 0.0)
	corpses.append(monster)

func _remove_corpse(monster: Dictionary) -> void:
	corpses.erase(monster)
	var sprite: SpineSprite = monster.get("native_spine_sprite")
	if is_instance_valid(sprite):
		sprite.hide()
		native_sprites.erase(sprite)
		sprite.queue_free()
	monster.erase("native_spine_sprite")
	var canvas: Node2D = monster.get("render_canvas")
	if is_instance_valid(canvas):
		canvas.hide()
		actor_canvases.erase(canvas)
		canvas.queue_free()
	monster.erase("render_canvas")
	monster.action_state.effects.clear()

func advance_corpses(delta: float, clamp_position: Callable = Callable()) -> void:
	for monster in corpses.duplicate():
		if monster.has("damage_reaction"):
			var push_offset: float = monster.damage_reaction.advance_pushback(delta)
			if not is_zero_approx(push_offset):
				monster.pos = Vector2(monster.pos) + Vector2(push_offset, 0.0)
				if clamp_position.is_valid():
					monster.pos = clamp_position.call(monster.pos)
		var pose_delta := delta
		var was_flying: bool = monster.has("damage_reaction") and monster.damage_reaction.knockback_remaining > 0.0
		if was_flying:
			var remaining: float = monster.damage_reaction.knockback_remaining
			_tick(monster, minf(delta, remaining))
			var motion: Dictionary = monster.damage_reaction.advance_knockback(delta)
			monster.pos = Vector2(monster.pos) + Vector2(float(motion.offset_x), 0.0)
			if clamp_position.is_valid():
				monster.pos = clamp_position.call(monster.pos)
			monster.character_height_px = float(motion.height)
			pose_delta = maxf(0.0, delta - remaining) if monster.damage_reaction.knockback_remaining <= 0.0 else 0.0
			if monster.damage_reaction.knockback_remaining <= 0.0:
				play(monster, down_action(monster))
			else:
				continue
		_tick(monster, pose_delta)
		var key := str(monster.action_state.key)
		# Ground loops belong to living knockdowns. Death finishes after one fall.
		if key in GROUND_LOOP_KEYS or (key in ["down", "down_fly"] and float(monster.action_state.elapsed) >= duration(monster, key)):
			_remove_corpse(monster)

func draw_body(canvas: CanvasItem, monster: Dictionary, position: Vector2, tint: Color) -> bool:
	var key := str(monster.get("action_state", {}).get("key", "idle"))
	if not _body_resource(monster, key).is_empty():
		if _draw_native_spine(canvas, monster, position, tint):
			return true
	var sprite: SpineSprite = monster.get("native_spine_sprite")
	if is_instance_valid(sprite):
		sprite.hide()
	return false

func visual_rect(monster: Dictionary, position: Vector2, fallback: Texture2D) -> Rect2:
	var key := str(monster.get("action_state", {}).get("key", "idle"))
	var source := _native_source(_body_resource(monster, key))
	if not source.is_empty():
		var bounds: Dictionary = source.skeleton
		var size := Vector2(float(bounds.get("width", 0.0)), float(bounds.get("height", 0.0)))
		var left := float(bounds.get("x", -size.x * 0.5))
		if float(monster.get("facing", 1.0)) < 0.0:
			left = -left - size.x
		return Rect2(position + Vector2(left, -float(bounds.get("y", 0.0)) - size.y), size)

	var size := fallback.get_size()
	return Rect2(position - Vector2(size.x * 0.5, size.y), size)

func draw_effects(canvas: CanvasItem, monster: Dictionary, position: Vector2, layer: String, alpha: float) -> void:
	if not canvas is Node2D:
		return
	for effect in monster.get("action_state", {}).get("effects", []):
		if effect.layer != layer:
			continue
		var sprite: SpineSprite = effect.get("sprite")
		if not is_instance_valid(sprite):
			var selected: Dictionary = effect.get("selected", {})
			sprite = resources.create_spine_effect(canvas, selected, position, float(monster.get("facing", 1.0)))
			if sprite == null:
				continue
			effect.sprite = sprite
		sprite.position = position
		sprite.scale = Vector2(signf(float(monster.get("facing", 1.0))), 1.0)
		sprite.modulate = Color(1, 1, 1, alpha)
		sprite.show()
