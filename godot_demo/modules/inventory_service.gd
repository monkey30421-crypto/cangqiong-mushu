class_name InventoryService
extends RefCounted

signal changed
signal rejected(message: String)
const CATEGORIES := ["general", "equipment", "quest", "skill"]
const QUALITY_NAMES := ["枯痕", "新芽", "生叶", "灵露", "灵枝", "冠辉", "母源"]
var capacity := 50
var catalog: Dictionary = {}
var slots: Array = []
var next_id := 1
var equipped: Dictionary = {}
var currencies: Dictionary = {}

func configure(path := "res://config/inventory.json") -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary:
		return
	capacity = maxi(int(data.get("capacity", 50)), 0)
	catalog = data.get("items", {}).duplicate(true)

func restore(data: Dictionary) -> void:
	slots.clear()
	currencies.clear()
	for item_id in data.get("currencies", {}):
		if catalog.has(item_id) and catalog[item_id].get("type", "") == "currency":
			currencies[item_id] = maxi(0, int(data.currencies[item_id]))
	equipped = data.get("equipped", {}).duplicate(true)
	next_id = maxi(int(data.get("next_id", 1)), 1)
	var seen: Dictionary = {}
	for value in data.get("slots", []):
		if not value is Dictionary or not catalog.has(str(value.get("item_id", ""))):
			continue
		var entry: Dictionary = value.duplicate(true)
		entry.count = int(entry.get("count", 0)) - int(entry.get("temporary_count", entry.get("count", 0) if entry.get("temporary", false) else 0))
		entry.temporary_count = 0
		entry.temporary = false
		if int(entry.count) <= 0:
			continue
		var uid := str(entry.get("uid", ""))
		if uid.is_empty() or seen.has(uid):
			continue
		seen[uid] = true
		entry.position = int(entry.get("position", slots.size()))
		entry.quality = int(catalog[entry.item_id].get("quality", 1))
		slots.append(entry)
	changed.emit()

func snapshot() -> Dictionary:
	return {"version": 2, "equipped": equipped.duplicate(true), "next_id": next_id, "slots": slots.duplicate(true), "currencies": currencies.duplicate(true)}

# Ground pickups share the normal bag rules; currencies have a separate balance.
func collect_item(item_id: String, count: int) -> bool:
	if not catalog.has(item_id) or count <= 0:
		return false
	if catalog[item_id].get("type", "") == "currency":
		currencies[item_id] = int(currencies.get(item_id, 0)) + count
		changed.emit()
		return true
	return add_item(item_id, count)

func find_slot(uid: String) -> Dictionary:
	for entry in slots:
		if str(entry.uid) == uid:
			return entry
	return {}

func stack_limit(entry: Dictionary) -> int:
	var definition: Dictionary = catalog.get(entry.item_id, {})
	return 1 if definition.get("category", "") in ["equipment", "skill"] else 999

func same_stack(a: Dictionary, b: Dictionary) -> bool:
	return a.item_id == b.item_id and stack_limit(a) > 1

func first_free(entries: Array) -> int:
	var used: Dictionary = {}
	for entry in entries:
		used[int(entry.position)] = true
	var index := 0
	while used.has(index):
		index += 1
	return index

# Atomic addition: insufficient capacity never consumes part of a reward.
func add_item(item_id: String, count: int, properties: Dictionary = {}) -> bool:
	if not catalog.has(item_id) or count <= 0:
		return false
	var definition: Dictionary = catalog[item_id]
	if not CATEGORIES.has(str(definition.get("category", ""))) or definition.get("type", "") == "currency":
		return false
	var template := {"item_id": item_id, "quality": clampi(int(definition.get("quality", 1)), 0, 6), "version": str(properties.get("version", "1")), "binding": str(properties.get("binding", "none")), "temporary": bool(properties.get("temporary", false)), "unique_id": str(properties.get("unique_id", "")), "attributes": properties.get("attributes", {}).duplicate(true), "acquired_at": Time.get_unix_time_from_system()}
	var pending := slots.duplicate(true)
	var remaining := count
	var limit := stack_limit(template)
	for entry in pending:
		if same_stack(entry, template):
			var amount := mini(remaining, maxi(0, limit - int(entry.count)))
			entry.count += amount
			entry.temporary_count = int(entry.get("temporary_count", 0)) + (amount if template.temporary else 0)
			remaining -= amount
	var required := ceili(float(remaining) / limit)
	if capacity > 0 and pending.size() + required > capacity:
		rejected.emit("背包空间不足")
		return false
	for index in range(required):
		var entry := template.duplicate(true)
		entry.uid = "slot_%d" % next_id
		while not find_slot(entry.uid).is_empty():
			next_id += 1
			entry.uid = "slot_%d" % next_id
		next_id += 1
		entry.count = mini(remaining, limit)
		remaining -= int(entry.count)
		entry.position = first_free(pending)
		entry.temporary_count = int(entry.count) if entry.temporary else 0
		if stack_limit(entry) == 1 and str(entry.unique_id).is_empty():
			entry.unique_id = entry.uid
		pending.append(entry)
	slots = pending
	changed.emit()
	return true

func remove_item(uid: String, count: int) -> bool:
	var entry := find_slot(uid)
	if entry.is_empty() or count <= 0 or int(entry.count) < count:
		return false
	entry.count -= count
	entry.temporary_count = maxi(0, int(entry.get("temporary_count", 0)) - count)
	if int(entry.count) == 0:
		slots.erase(entry)
	changed.emit()
	return true

# Effect callback validates target/caps and returns true only after applying an effect.
func use_consumable(uid: String, in_dungeon: bool, apply_effect: Callable) -> bool:
	var entry := find_slot(uid)
	if entry.is_empty():
		return false
	var definition: Dictionary = catalog.get(entry.item_id, {})
	if definition.get("type", "") != "consumable" or (in_dungeon and not bool(definition.get("dungeon_usable", false))) or not bool(definition.get("usable", false)):
		return false
	if not apply_effect.is_valid() or not bool(apply_effect.call(definition.duplicate(true))):
		return false
	return remove_item(uid, 1)

func settle_dungeon() -> void:
	var dirty := false
	for entry in slots.duplicate():
		var amount := int(entry.get("temporary_count", entry.count if entry.get("temporary", false) else 0))
		if amount > 0:
			dirty = true
			entry.count -= amount
			entry.temporary_count = 0
			entry.temporary = false
			if entry.count <= 0:
				slots.erase(entry)
	if dirty:
		changed.emit()

func sort_rank(entry: Dictionary) -> int:
	var definition: Dictionary = catalog[entry.item_id]
	return {"chest": 0, "consumable": 1, "equipment": 2, "skill": 3, "quest": 4}.get(str(definition.get("type", definition.get("category", ""))), 4 if definition.get("category") == "quest" else 5)

func organize(_mode := "default") -> void:
	var merged: Array = []
	for original in slots:
		var entry: Dictionary = original.duplicate(true)
		for previous in merged:
			if same_stack(previous, entry):
				var amount := mini(int(entry.count), 999 - int(previous.count))
				var temporary := mini(amount, int(entry.get("temporary_count", 0)))
				previous.count += amount
				previous.temporary_count = int(previous.get("temporary_count", 0)) + temporary
				entry.count -= amount
				entry.temporary_count = int(entry.get("temporary_count", 0)) - temporary
		if int(entry.count) > 0:
			merged.append(entry)
	merged.sort_custom(func(a, b):
		if sort_rank(a) != sort_rank(b): return sort_rank(a) < sort_rank(b)
		if int(a.quality) != int(b.quality): return int(a.quality) > int(b.quality)
		if a.item_id != b.item_id: return str(a.item_id).naturalnocasecmp_to(str(b.item_id)) < 0
		return str(a.get("unique_id", a.uid)).naturalnocasecmp_to(str(b.get("unique_id", b.uid))) < 0)
	for index in range(merged.size()):
		merged[index].position = index
	slots = merged
	changed.emit()

func equipment_key(entry: Dictionary) -> String:
	var definition: Dictionary = catalog.get(entry.get("item_id", ""), {})
	var key := str(definition.get("equipment_slot", ""))
	if not key.is_empty() and int(definition.get("slot_count", 1)) == 2:
		key += "_1"
	return key

func equip_item(uid: String, in_dungeon := false) -> bool:
	var entry := find_slot(uid)
	if entry.is_empty() or in_dungeon or catalog[entry.item_id].get("category") != "equipment":
		return false
	var key := equipment_key(entry)
	if key.is_empty(): return false
	var old: Dictionary = equipped.get(key, {})
	equipped[key] = entry.duplicate(true)
	slots.erase(entry)
	if not old.is_empty():
		old.position = entry.position
		slots.append(old)
	changed.emit()
	return true

func stats_for(entry: Dictionary) -> Dictionary:
	var result: Dictionary = catalog.get(entry.get("item_id", ""), {}).get("stats", {}).duplicate(true)
	for key in entry.get("attributes", {}):
		result[key] = float(result.get(key, 0)) + float(entry.attributes[key])
	return result

func stat_bonus(key: String) -> float:
	var total := 0.0
	for entry in equipped.values():
		total += float(stats_for(entry).get(key, 0))
	return total

func discard_item(uid: String, count: int) -> bool:
	var entry := find_slot(uid)
	if entry.is_empty(): return false
	var definition: Dictionary = catalog[entry.item_id]
	if definition.get("category") in ["quest", "skill"] or definition.get("type") in ["chest", "consumable"]: return false
	return remove_item(uid, count)

func list_items(category: String, filter := "all") -> Array:
	return slots.filter(func(entry):
		var definition: Dictionary = catalog.get(entry.item_id, {})
		if definition.get("type", "") == "currency" or definition.get("category", "") == "currency":
			return false
		if category != "all" and definition.get("category", "") != category:
			return false
		match filter:
			"usable": return bool(definition.get("usable", false))
			"equipped": return bool(entry.get("equipped", false))
			"temporary": return int(entry.get("temporary_count", 0)) > 0
			"quest": return definition.get("category", "") == "quest"
		return true)
