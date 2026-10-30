extends RefCounted

const Geometry = preload("res://modules/map_geometry.gd")
const SCATTER_RADIUS := 100.0
const PICKUP_RADIUS := 50.0
const ICON_SCALE := 0.5
const ATTRACT_SPEED := 500.0
var entries: Array[Dictionary] = []
var textures: Dictionary = {}

func clear() -> void:
	entries.clear()

func scatter_point(origin: Vector2, polygon: PackedVector2Array, rng: RandomNumberGenerator) -> Variant:
	if polygon.size() < 3:
		return null
	for attempt in range(128):
		var point := origin + Vector2.from_angle(rng.randf_range(0.0, TAU)) * sqrt(rng.randf()) * SCATTER_RADIUS
		if Geometry.is_point_in_polygon_or_edge(point, polygon):
			return point
	# Narrow corners still get a valid drop; never project beyond the 100 px radius.
	if Geometry.is_point_in_polygon_or_edge(origin, polygon):
		return origin
	var closest := Vector2.INF
	var distance := INF
	for i in range(polygon.size()):
		var point := Geometry.closest_point_on_segment(origin, polygon[i], polygon[(i + 1) % polygon.size()])
		if origin.distance_squared_to(point) < distance:
			distance = origin.distance_squared_to(point)
			closest = point
	return closest if distance <= SCATTER_RADIUS * SCATTER_RADIUS else null

func spawn_monster(monster: Dictionary, catalog: Dictionary, polygon: PackedVector2Array, rng: RandomNumberGenerator) -> void:
	if bool(monster.get("drops_spawned", false)):
		return
	monster.drops_spawned = true
	for drop in monster.get("drops", []):
		if not drop is Dictionary:
			continue
		var item_id := str(drop.get("itemId", ""))
		if not catalog.has(item_id):
			continue
		var probability := clampf(float(drop.get("probability", 0.0)), 0.0, 1.0)
		if probability <= 0.0 or rng.randf() >= probability:
			continue
		var legacy_count := int(drop.get("count", 1))
		var min_count := clampi(int(drop.get("minCount", legacy_count)), 1, 9999)
		var max_count := clampi(int(drop.get("maxCount", legacy_count)), min_count, 9999)
		var count := rng.randi_range(min_count, max_count)
		var point = scatter_point(Vector2(monster.pos), polygon, rng)
		if point == null:
			continue
		entries.append({"item_id": item_id, "count": count, "pos": point, "ground_pos": point, "attracting": false, "retry_remaining": 0.0})

func advance(delta: float, player: Vector2, receive: Callable) -> void:
	for entry in entries.duplicate():
		entry.retry_remaining = maxf(0.0, float(entry.retry_remaining) - delta)
		if float(entry.retry_remaining) > 0.0:
			continue
		if not entry.attracting and Vector2(entry.ground_pos).distance_squared_to(player) <= PICKUP_RADIUS * PICKUP_RADIUS:
			entry.attracting = true
		if not entry.attracting:
			continue
		var target := player + Vector2(0.0, -45.0)
		entry.pos = Vector2(entry.pos).move_toward(target, ATTRACT_SPEED * maxf(delta, 0.0))
		if Vector2(entry.pos).distance_squared_to(target) > 0.01:
			continue
		if receive.call(str(entry.item_id), int(entry.count)):
			entries.erase(entry)
		else:
			# A full bag cannot delete loot. Retry after space is freed.
			entry.pos = entry.ground_pos
			entry.attracting = false
			entry.retry_remaining = 0.5

func icon(path: String) -> Texture2D:
	if not textures.has(path):
		var texture: Texture2D
		if path.begins_with("res://assets/") and not ".." in path and ResourceLoader.exists(path):
			texture = load(path) as Texture2D
		textures[path] = texture
	return textures[path]

func draw(canvas: CanvasItem, camera: Vector2, catalog: Dictionary) -> void:
	for entry in entries:
		var definition: Dictionary = catalog.get(entry.item_id, {})
		var texture := icon(str(definition.get("icon", "")))
		if texture == null:
			continue
		var size := texture.get_size() * ICON_SCALE
		canvas.draw_texture_rect(texture, Rect2(Vector2(entry.pos) - camera - size * 0.5, size), false)
		if int(entry.count) > 1:
			var label_position := Vector2(entry.pos) - camera + size * 0.5
			canvas.draw_string(ThemeDB.fallback_font, label_position + Vector2(1, 1), str(entry.count), HORIZONTAL_ALIGNMENT_RIGHT, -1, 16, Color.BLACK)
			canvas.draw_string(ThemeDB.fallback_font, label_position, str(entry.count), HORIZONTAL_ALIGNMENT_RIGHT, -1, 16, Color.WHITE)
