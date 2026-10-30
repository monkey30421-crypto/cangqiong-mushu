class_name MapGeometry
extends RefCounted


static func closest_point_on_segment(point: Vector2, edge_start: Vector2, edge_end: Vector2) -> Vector2:
	var edge := edge_end - edge_start
	if edge.length_squared() <= 0.0001:
		return edge_start
	return edge_start + edge * clampf((point - edge_start).dot(edge) / edge.length_squared(), 0.0, 1.0)


static func polygon_area(polygon: PackedVector2Array) -> float:
	var twice_area := 0.0
	for vertex_index in range(polygon.size()):
		var current := polygon[vertex_index]
		var following := polygon[(vertex_index + 1) % polygon.size()]
		twice_area += current.x * following.y - following.x * current.y
	return absf(twice_area) * 0.5


static func is_point_in_polygon_or_edge(point: Vector2, polygon: PackedVector2Array) -> bool:
	if Geometry2D.is_point_in_polygon(point, polygon):
		return true
	for vertex_index in range(polygon.size()):
		var edge_start := polygon[vertex_index]
		var edge_end := polygon[(vertex_index + 1) % polygon.size()]
		if point.distance_squared_to(closest_point_on_segment(point, edge_start, edge_end)) <= 0.01:
			return true
	return false
