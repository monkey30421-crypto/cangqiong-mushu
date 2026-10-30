extends RefCounted

# Native skeletons own animation duration and event tracks; no sampled frame catalog.
const DEFAULT_MODEL := "res://assets/character/art/player_animations/Character-data.tres"
const EFFECTS_PATH := "res://config/spine_effects.json"
var sources: Dictionary = {}
var clips: Dictionary = {}

func source(path: String) -> Dictionary:
	if sources.has(path):
		return sources[path]
	if not path.begins_with("res://assets/") or not path.ends_with(".tres") or ".." in path or not ResourceLoader.exists(path):
		return {}
	var data := load(path) as SpineSkeletonDataResource
	if data == null or data.skeleton_file_res == null or not data.is_skeleton_data_loaded():
		return {}
	var source_path: String = data.skeleton_file_res.resource_path
	if not FileAccess.file_exists(source_path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(source_path))
	if not parsed is Dictionary or not parsed.get("animations") is Dictionary:
		return {}
	sources[path] = parsed
	return parsed

static func timeline_end(value: Variant) -> float:
	var result := 0.0
	if value is Array:
		for item in value:
			result = maxf(result, timeline_end(item))
	elif value is Dictionary:
		if value.get("time") is float or value.get("time") is int:
			result = maxf(result, float(value.time))
		for item in value.values():
			result = maxf(result, timeline_end(item))
	return result

func animations(path: String) -> Dictionary:
	if clips.has(path):
		return clips[path]
	var result := {}
	for animation_name in source(path).get("animations", {}):
		var raw: Dictionary = sources[path].animations[animation_name]
		result[animation_name] = {"duration": timeline_end(raw), "events": raw.get("events", []).duplicate(true), "nativeSpine": true, "resource": path, "bounds": [512, 414]}
	clips[path] = result
	return result

func catalog(model: String = DEFAULT_MODEL) -> Dictionary:
	var result := {"character": {"resource": model, "animations": animations(model)}, "effects": []}
	if not FileAccess.file_exists(EFFECTS_PATH):
		return result
	var registry = JSON.parse_string(FileAccess.get_file_as_string(EFFECTS_PATH))
	if not registry is Dictionary or not registry.get("effects") is Array:
		return result
	for entry in registry.effects:
		var effect: Dictionary = entry.duplicate(true)
		effect.animations = animations(str(effect.get("resource", "")))
		result.effects.append(effect)
	return result
