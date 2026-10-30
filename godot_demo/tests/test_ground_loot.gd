extends SceneTree

const Loot = preload("res://modules/ground_loot.gd")
const Geometry = preload("res://modules/map_geometry.gd")
const Inventory = preload("res://modules/inventory_service.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var loot := Loot.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	var polygon := PackedVector2Array([Vector2(0, 0), Vector2(200, 0), Vector2(200, 60), Vector2(60, 60), Vector2(60, 200), Vector2(0, 200)])
	for origin in [Vector2(1, 1), Vector2(59, 59), Vector2(20, 180), Vector2(65, 65)]:
		for i in range(200):
			var point: Vector2 = loot.scatter_point(origin, polygon, rng)
			assert(point.distance_to(origin) <= 100.001)
			assert(Geometry.is_point_in_polygon_or_edge(point, polygon), "Concave polygon drop must remain walkable")
	assert(loot.scatter_point(Vector2(500, 500), polygon, rng) == null)
	var bag := Inventory.new()
	bag.configure()
	bag.capacity = 1
	var monster := {"pos": Vector2(30, 30), "drops": [{"itemId": "2001", "probability": 1.0}, {"itemId": "2002", "probability": 0.0}, {"itemId": "missing", "probability": 1.0}]}
	loot.spawn_monster(monster, bag.catalog, polygon, rng)
	assert(loot.entries.size() == 1 and bag.slots.is_empty(), "Kills create ground loot, not immediate bag rewards")
	loot.spawn_monster(monster, bag.catalog, polygon, rng)
	assert(loot.entries.size() == 1, "A monster drops only once")
	var point: Vector2 = loot.entries[0].pos
	loot.advance(1.0, point + Vector2(50.01, 0), bag.collect_item)
	assert(not loot.entries[0].attracting and bag.slots.is_empty())
	loot.advance(0.01, point + Vector2(50, 0), bag.collect_item)
	assert(loot.entries[0].attracting and bag.slots.is_empty(), "50 px boundary begins visible attraction")
	loot.advance(1.0, point + Vector2(50, 0), bag.collect_item)
	assert(loot.entries.is_empty() and bag.slots.size() == 1)
	var full_bag_monster := {"pos": point, "drops": [{"itemId": "2002", "probability": 1.0}]}
	loot.spawn_monster(full_bag_monster, bag.catalog, polygon, rng)
	point = loot.entries[0].pos
	loot.advance(1.0, point, bag.collect_item)
	assert(loot.entries.size() == 1 and not loot.entries[0].attracting, "Full bags retain the drop")
	assert(bag.remove_item(str(bag.slots[0].uid), 1))
	loot.advance(1.0, point, bag.collect_item)
	assert(loot.entries.is_empty() and bag.slots[0].item_id == "2002")
	assert(loot.icon(bag.catalog["2002"].icon).get_size() * loot.ICON_SCALE == Vector2(50, 50))
	loot.spawn_monster({"pos": Vector2(30, 30), "drops": [{"itemId": "2001", "probability": 1.0, "minCount": 3, "maxCount": 7}, {"itemId": "1001", "probability": 1.0, "minCount": 8, "maxCount": 8}, {"itemId": "2002", "probability": 0.0}]}, bag.catalog, polygon, rng)
	assert(loot.entries.size() == 2, "Independent rolls permit multiple item types on the same kill")
	assert(loot.entries[0].count >= 3 and loot.entries[0].count <= 7 and loot.entries[1].count == 8)
	point = loot.entries[1].pos
	loot.advance(1.0, point, bag.collect_item)
	assert(bag.currencies["1001"] == 8, "Currency stack pickups grant the configured count")
	# Seeded frequency checks protect independent per-entry probabilities.
	loot.clear()
	for i in range(2000):
		loot.spawn_monster({"pos": Vector2(30, 30), "drops": [{"itemId": "2001", "probability": 0.25}]}, bag.catalog, polygon, rng)
	assert(loot.entries.size() > 400 and loot.entries.size() < 600)
	loot.clear()
	assert(loot.entries.is_empty())
	print("GROUND_LOOT_TEST_OK")
	quit()
