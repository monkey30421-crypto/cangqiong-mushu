extends RefCounted

const CONFIG_PATH := "res://config/characters.json"
const DEFAULT_MODEL := "res://assets/character/art/player_animations/Character-data.tres"
var rows: Dictionary = {}
var textures: Dictionary = {}

func load_config(path: String = CONFIG_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary or parsed.get("version") != 1 or not parsed.get("rows") is Array:
		return false
	var next: Dictionary = {}
	for row in parsed.rows:
		if not row is Dictionary:
			return false
		var id := int(row.get("id", 0))
		if (id != 1 and id < 101) or next.has(id):
			return false
		if id >= 101:
			var monster_type := str(row.get("monsterType", "normal"))
			if not ["normal", "elite", "mutation", "boss"].has(monster_type):
				return false
			row["monsterType"] = monster_type
			var push_distance = row.get("hitPushbackDistancePx", 40.0)
			if not (push_distance is int or push_distance is float) or not is_finite(float(push_distance)) or push_distance < 0.0 or push_distance > 10000.0:
				return false
			var can_launch = row.get("canBeLaunched", monster_type != "boss")
			if not can_launch is bool:
				return false
			row.hitPushbackDistancePx = float(push_distance)
			row.canBeLaunched = can_launch
		for key in ["x", "h"]:
			var value = row.get(key)
			if not (value is int or value is float) or not is_finite(float(value)) or value <= 0:
				return false
		var shadow_scale = row.get("shadowScalePercent", 100.0)
		if not (shadow_scale is int or shadow_scale is float) or not is_finite(float(shadow_scale)) or shadow_scale < 0.0 or shadow_scale > 1000.0:
			return false
		var resource := str(row.get("modelResource", ""))
		if not resource.begins_with("res://assets/") or ".." in resource or not FileAccess.file_exists(resource):
			return false
		if id == 1 or resource.ends_with(".tres"):
			if not ResourceLoader.exists(resource):
				return false
			var data := load(resource) as SpineSkeletonDataResource
			if data == null or not data.is_skeleton_data_loaded():
				return false
		elif not resource.ends_with(".png"):
			return false
		next[id] = row
	for id in [1, 101, 102, 103, 104]:
		if not next.has(id):
			return false
	rows = next
	textures.clear()
	return true

func profile(id: int) -> Dictionary:
	return rows.get(id, {"id": id, "x": 60.0, "h": 130.0, "modelResource": DEFAULT_MODEL if id == 1 else ""})

func configure_monster(monster: Dictionary, id: int) -> void:
	var row := profile(id)
	monster.character_id = id
	monster.name = str(row.get("name", monster.get("name", "")))
	monster.monster_type = str(row.get("monsterType", "normal"))
	monster.hit_pushback_distance_px = float(row.get("hitPushbackDistancePx", 40.0))
	monster.can_be_launched = bool(row.get("canBeLaunched", monster.monster_type != "boss"))
	monster.hurtbox_x = float(row.x)
	monster.hurtbox_h = float(row.h)
	monster.shadow_scale_percent = float(row.get("shadowScalePercent", 100.0))
	monster.model_resource = str(row.modelResource)
	monster.drops = row.get("drops", []).duplicate(true) if row.get("drops", []) is Array else []


func character_id_for_type(monster_type: String) -> int:
	var ids: Array = rows.keys()
	ids.sort()
	for id in ids:
		if int(id) >= 101 and str(rows[id].get("monsterType", "normal")) == monster_type:
			return int(id)
	for id in ids:
		if int(id) >= 101:
			return int(id)
	return 0

func texture(path: String, fallback: Texture2D) -> Texture2D:
	if textures.has(path):
		return textures[path]
	if path.begins_with("res://assets/") and ".." not in path and path.ends_with(".png"):
		if ResourceLoader.exists(path):
			var imported := load(path) as Texture2D
			if imported != null:
				textures[path] = imported
				return imported
		var image := Image.load_from_file(path)
		if image != null and not image.is_empty():
			textures[path] = ImageTexture.create_from_image(image)
			return textures[path]
	return fallback
