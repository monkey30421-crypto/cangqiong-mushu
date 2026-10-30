class_name DungeonRouteGenerator
extends RefCounted

var _rng: RandomNumberGenerator
var _nodes: Dictionary = {}
var _columns: Array[Array] = []
var _elite_weight := 0.0
var _mutation_weight := 0.0


func generate(rng: RandomNumberGenerator) -> Dictionary:
	_rng = rng
	_nodes.clear()
	_columns.clear()
	_elite_weight = snappedf(_rng.randf_range(0.0, 20.0), 0.01)
	_mutation_weight = snappedf(_rng.randf_range(0.0, 10.0), 0.01)
	var count_combinations: Array[Array] = []
	for b_count in range(1, 4):
		for c_count in range(1, 4):
			for d_count in range(1, 4):
				for e_count in range(1, 4):
					if b_count + c_count + d_count + e_count == 7:
						count_combinations.append([b_count, c_count, d_count, e_count])
	var middle_counts: Array = count_combinations[_rng.randi_range(0, count_combinations.size() - 1)]
	var middle_rows: Array = []
	for _attempt in range(64):
		middle_rows.clear()
		for count in middle_counts:
			middle_rows.append(_random_route_rows(int(count)))
		var all_rows: Array = [[2]]
		all_rows.append_array(middle_rows)
		all_rows.append([2])
		var compatible := true
		for column_index in range(all_rows.size() - 1):
			if not _route_rows_compatible(all_rows[column_index], all_rows[column_index + 1]):
				compatible = false
				break
		if compatible:
			break

	var column_letters := ["A", "B", "C", "D", "E", "F"]
	var all_column_rows: Array = [[2]]
	all_column_rows.append_array(middle_rows)
	all_column_rows.append([2])
	for column_index in range(all_column_rows.size()):
		var column_ids: Array[String] = []
		for row_value in all_column_rows[column_index]:
			var node_id := "%d%s" % [int(row_value), column_letters[column_index]]
			var node_type := "start" if column_index == 0 else ("boss" if column_index == 5 else _roll_area_type())
			_nodes[node_id] = {
				"id": node_id, "column": column_index, "row": int(row_value), "type": node_type,
				"map": 1 if column_index == 0 else (6 if column_index == 5 else 0),
				"connections": [], "completed": false,
				"revealed": column_index == 0 or column_index == 5, "dimmed": false,
			}
			column_ids.append(node_id)
		_columns.append(column_ids)
	for column_index in range(_columns.size() - 1):
		_connect_columns(_columns[column_index], _columns[column_index + 1])
	_assign_maps()
	return {
		"nodes": _nodes.duplicate(true),
		"columns": _columns.duplicate(true),
		"elite_weight": _elite_weight,
		"mutation_weight": _mutation_weight,
	}


func _random_route_rows(count: int) -> Array[int]:
	var options: Array = []
	match count:
		1: options = [[1], [2], [3]]
		2: options = [[1, 2], [1, 3], [2, 3]]
		_: options = [[1, 2, 3]]
	return (options[_rng.randi_range(0, options.size() - 1)] as Array).duplicate()


func _route_rows_compatible(left_rows: Array, right_rows: Array) -> bool:
	for left_row in left_rows:
		if not right_rows.any(func(right_row: int) -> bool: return absi(int(left_row) - right_row) <= 1):
			return false
	for right_row in right_rows:
		if not left_rows.any(func(left_row: int) -> bool: return absi(left_row - int(right_row)) <= 1):
			return false
	return true


func _connect_columns(left_ids: Array, right_ids: Array) -> void:
	for left_id in left_ids:
		_add_connection(str(left_id), _closest_node(str(left_id), right_ids))
	for right_id in right_ids:
		_add_connection(_closest_node(str(right_id), left_ids), str(right_id))


func _closest_node(source_id: String, candidates: Array) -> String:
	var source_row := int(_nodes[source_id]["row"])
	var best_id := str(candidates[0])
	var best_distance := 99
	for candidate_value in candidates:
		var candidate_id := str(candidate_value)
		var distance := absi(source_row - int(_nodes[candidate_id]["row"]))
		if distance < best_distance:
			best_distance = distance
			best_id = candidate_id
	return best_id


func _add_connection(left_id: String, right_id: String) -> void:
	var node: Dictionary = _nodes[left_id]
	var connections: Array = node["connections"]
	if right_id not in connections:
		connections.append(right_id)
	node["connections"] = connections
	_nodes[left_id] = node


func _roll_area_type() -> String:
	var roll := _rng.randf_range(0.0, 100.0)
	if roll < _elite_weight:
		return "elite"
	if roll < _elite_weight + _mutation_weight:
		return "mutation"
	return "normal"


func _assign_maps() -> void:
	for column_index in range(1, 5):
		for node_id_value in _columns[column_index]:
			var node_id := str(node_id_value)
			var forbidden_maps: Array[int] = []
			for previous_id_value in _columns[column_index - 1]:
				var previous_id := str(previous_id_value)
				if node_id in _nodes[previous_id]["connections"]:
					forbidden_maps.append(int(_nodes[previous_id]["map"]))
			var candidates: Array[int] = [2, 3, 4, 5]
			_shuffle(candidates)
			for map_number in candidates:
				if map_number not in forbidden_maps:
					_nodes[node_id]["map"] = map_number
					break


func _shuffle(values: Array) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index := _rng.randi_range(0, index)
		var held = values[index]
		values[index] = values[swap_index]
		values[swap_index] = held
