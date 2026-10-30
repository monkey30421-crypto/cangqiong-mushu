extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	await process_frame
	game.state = "dungeon"
	game.dungeon_current_node_id = "anchor_test"
	game.dungeon_route_nodes = {"anchor_test": {"map": 1}}
	game.dungeon_altar_tree_positions[0] = Vector2(1200, 650)
	game.camera_x = 300.0
	game.camera_y = 100.0
	game.dungeon_background.position = Vector2(0, -game.camera_y)
	game._update_dungeon_altar_tree()
	var source = JSON.parse_string(FileAccess.get_file_as_string("res://assets/scene/effects/altar_tree/jitanshu_m.spine-json"))
	var bone: Dictionary
	for entry in source.bones:
		if entry.name == "a":
			bone = entry
	var attachment: Dictionary = source.skins[0].attachments.a["jitanshu/052"]
	var bottom_center := Vector2(float(bone.x), -(float(bone.y) + float(attachment.y)) + float(attachment.height) * 0.5)
	assert((game.altar_tree.global_position + bottom_center).is_equal_approx(Vector2(900, 550)), "Spine canvas bottom-centre must match editor anchor after camera transform")
	game.camera_x = 500.0
	game._update_dungeon_altar_tree()
	assert((game.altar_tree.global_position + bottom_center).is_equal_approx(Vector2(700, 550)), "Camera movement must preserve the same map anchor")
	game.queue_free()
	await process_frame
	print("ALTAR_TREE_ANCHOR_TEST_OK")
	quit()
