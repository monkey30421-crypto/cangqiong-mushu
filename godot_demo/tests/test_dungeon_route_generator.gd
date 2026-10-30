extends SceneTree

const DungeonRouteGeneratorScript = preload("res://modules/dungeon_route_generator.gd")


func _initialize() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260829
	var generated: Dictionary = DungeonRouteGeneratorScript.new().generate(rng)
	var nodes: Dictionary = generated.nodes
	var columns: Array = generated.columns
	assert(nodes.size() == 9 and columns.size() == 6)
	assert(columns[0] == ["2A"] and columns[5] == ["2F"])
	assert(float(generated.elite_weight) >= 0.0 and float(generated.elite_weight) <= 20.0)
	assert(float(generated.mutation_weight) >= 0.0 and float(generated.mutation_weight) <= 10.0)
	for column_index in range(columns.size() - 1):
		for source_id in columns[column_index]:
			assert(not nodes[source_id].connections.is_empty())
			for target_id in nodes[source_id].connections:
				assert(absi(int(nodes[source_id].row) - int(nodes[target_id].row)) <= 1)
	for column_index in range(1, 5):
		for node_id in columns[column_index]:
			assert(int(nodes[node_id].map) >= 2 and int(nodes[node_id].map) <= 5)
	print("DUNGEON_ROUTE_GENERATOR_TEST_OK")
	quit()
