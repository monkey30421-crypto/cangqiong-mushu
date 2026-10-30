extends SceneTree

const Depth = preload("res://modules/scene_depth.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var layers := Depth.new()
	root.add_child(layers)
	var a := Node2D.new()
	var b := Node2D.new()
	root.add_child(a)
	root.add_child(b)
	layers.sort_entities([{"node": a, "y": 650.1}, {"node": b, "y": 650.2}])
	assert(a.z_index < b.z_index, "Fractional Y differences cannot share a coarse depth band")
	layers.sort_entities([{"node": a, "y": 5000.0}, {"node": b, "y": -100.0}])
	assert(a.z_index > b.z_index, "Depth does not depend on camera or hardcoded world-height bands")
	assert(layers.lower_effects.z_index < b.z_index and layers.upper_effects.z_index > a.z_index)
	assert(not a.z_as_relative and not layers.upper_effects.z_as_relative)
	a.queue_free()
	b.queue_free()
	layers.queue_free()
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	await process_frame
	game._enter_city(true)
	game._enter_dungeon()
	game.traveler.show()
	game.monsters.clear()
	game.dungeon_stage = "wave_delay"
	game.dungeon_next_wave_timer = 100.0
	game.player = Vector2(1200, 650)
	var rear: Dictionary = game._monster_definition(0, Vector2(1200, 640), "Rear native", 0, 1)
	var front: Dictionary = game._monster_definition(3, Vector2(1200, 660), "Front PNG", 0, 1)
	front.model_resource = "res://assets/character/art/monsters/gray-shell-branch-beast.png"
	game.monsters.assign([front, rear]) # Array order deliberately disagrees with depth.
	game._update_traveler()
	assert(rear.render_canvas.z_index < game.traveler.z_index and game.traveler.z_index < front.render_canvas.z_index)
	assert(rear.native_spine_sprite.get_parent() == rear.render_canvas)
	assert(rear.native_spine_sprite.z_index == 0 and rear.native_spine_sprite.z_as_relative)
	var ground_rank: int = game.traveler.z_index
	game.character_height_px = 200.0
	rear.character_height_px = 300.0
	game._update_traveler()
	assert(game.traveler.z_index == ground_rank and rear.render_canvas.z_index < game.traveler.z_index, "Jump height never changes ground-depth ordering")
	front.pos.y = 630.0
	rear.pos.y = 670.0
	game.camera_y += 1000.0
	game._update_traveler()
	assert(front.render_canvas.z_index < game.traveler.z_index and game.traveler.z_index < rear.render_canvas.z_index)
	var tree_y: float = game._current_dungeon_altar_tree_position().y
	game.player.y = tree_y - 10.0
	game._update_traveler()
	assert(game.traveler.z_index < game.altar_tree.z_index and not game.altar_tree.z_as_relative)
	game.player.y = tree_y + 10.0
	game._update_traveler()
	assert(game.traveler.z_index > game.altar_tree.z_index, "Altar depth uses its ground anchor, not its offset Spine origin")
	# Hero VFX join the same global planes as every monster's VFX.
	var actions = game.character_actions
	actions.rows[2001].upper = {"file": "skilleffect_jd_dg1.json", "animation": "attack1"}
	actions.rows[2001].lower = {"file": "skilleffect_jd_dg1.json", "animation": "attack2"}
	actions.library.character.animations[actions.rows[2001].animation].events = [{"name": "action", "time": 0.0}]
	actions.play(2001, true)
	actions.advance(0.01, game.traveler.position, 1.0)
	assert(actions.effects.size() == 2)
	var upper: CanvasItem = actions.effects[0]
	var lower: CanvasItem = actions.effects[1]
	assert(upper.z_index == game.scene_depth.upper_effects.z_index and lower.z_index == game.scene_depth.lower_effects.z_index)
	assert(not upper.z_as_relative and not lower.z_as_relative)
	for actor in [game.traveler, game.altar_tree, rear.render_canvas, front.render_canvas]:
		assert(lower.z_index < actor.z_index and upper.z_index > actor.z_index)
	assert(game.hit_effects.z_index > rear.render_canvas.z_index)
	# Death visuals still sort, and removal cannot leave an orphan render canvas.
	rear.hp = 0
	game.monsters.erase(rear)
	game.monster_actions.retire(rear)
	game._update_scene_depth()
	var corpse_canvas: Node2D = rear.render_canvas
	assert(corpse_canvas.z_index > front.render_canvas.z_index)
	game.monster_actions.advance_corpses(10.0)
	assert(corpse_canvas.is_queued_for_deletion() and not corpse_canvas.visible)
	game._enter_city(false)
	assert(game.monster_actions.actor_canvases.is_empty())
	game.queue_free()
	await process_frame
	print("SCENE_DEPTH_TEST_OK")
	quit()
