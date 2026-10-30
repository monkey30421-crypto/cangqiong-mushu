extends SceneTree

const MapGeometryScript = preload("res://modules/map_geometry.gd")


func _initialize() -> void:
	var polygon := PackedVector2Array([Vector2(0, 0), Vector2(100, 0), Vector2(100, 100), Vector2(0, 100)])
	assert(is_equal_approx(MapGeometryScript.polygon_area(polygon), 10000.0))
	assert(MapGeometryScript.is_point_in_polygon_or_edge(Vector2(50, 50), polygon))
	assert(MapGeometryScript.is_point_in_polygon_or_edge(Vector2(0, 50), polygon))
	assert(not MapGeometryScript.is_point_in_polygon_or_edge(Vector2(150, 50), polygon))
	assert(MapGeometryScript.closest_point_on_segment(Vector2(50, 30), Vector2(0, 0), Vector2(100, 0)) == Vector2(50, 0))
	print("MAP_GEOMETRY_TEST_OK")
	quit()
