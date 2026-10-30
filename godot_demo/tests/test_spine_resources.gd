extends SceneTree

const SpineResources = preload("res://modules/spine_resources.gd")
const Profiles = preload("res://modules/character_profiles.gd")
const Actions = preload("res://modules/monster_actions.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var resources := SpineResources.new()
	var catalog := resources.catalog()
	assert(catalog.character.resource == Profiles.DEFAULT_MODEL)
	assert(catalog.character.animations.size() == 20)
	for animation_name in catalog.character.animations:
		var clip: Dictionary = catalog.character.animations[animation_name]
		assert(clip.nativeSpine and not clip.has("sheet") and not clip.has("frames"))
		assert(clip.duration == resources.timeline_end(resources.source(clip.resource).animations[animation_name]))
	for effect in catalog.effects:
		var data := load(str(effect.resource)) as SpineSkeletonDataResource
		assert(data != null and data.is_skeleton_data_loaded())
		for animation_name in effect.animations:
			assert(data.find_animation(StringName(animation_name)) != null)
			assert(not effect.animations[animation_name].has("sheet"))
	var profiles := Profiles.new()
	assert(profiles.load_config())
	assert(profiles.profile(1).modelResource == SpineResources.DEFAULT_MODEL)
	var actions := Actions.new()
	assert(actions.load_config())
	for id in actions.rows:
		for key in actions.rows[id]:
			var row: Dictionary = actions.rows[id][key]
			if row.animation != null:
				assert(str(row.animation.library).ends_with(".tres"))
				assert(not actions._body_clip(row).is_empty())
	# An explicitly selected native animation library must be the resource rendered,
	# including when the default model belongs to a different Spine skeleton.
	var monster := {"character_id": 101, "model_resource": profiles.profile(101).modelResource, "facing": 1.0}
	actions.rows[101].attack1.animation = {"library": SpineResources.DEFAULT_MODEL, "name": "attack1_SingleSword"}
	actions.play(monster, "attack1", true)
	var host := Node2D.new()
	root.add_child(host)
	actions.prepare_native_sprite(host, monster)
	assert(monster.native_spine_sprite.skeleton_data_res.resource_path == SpineResources.DEFAULT_MODEL)
	assert(actions._native_animation_name(monster, "attack1") == "attack1_SingleSword")
	assert(actions._native_clip(monster, "attack1").events == catalog.character.animations.attack1_SingleSword.events)
	actions.play(monster, "idle", true)
	actions.prepare_native_sprite(host, monster)
	assert(monster.native_spine_sprite.skeleton_data_res.resource_path == profiles.profile(101).modelResource)
	# A static model can have an explicitly selected native reaction, then return
	# to its still image without leaving the previous Spine body visible.
	var static_model := {"character_id": 104, "model_resource": profiles.profile(104).modelResource, "facing": 1.0}
	actions.play(static_model, "getup", true)
	assert(actions.draw_body(host, static_model, Vector2.ZERO, Color.WHITE))
	assert(static_model.native_spine_sprite.visible)
	actions.play(static_model, "idle", true)
	assert(not actions.draw_body(host, static_model, Vector2.ZERO, Color.WHITE))
	assert(not static_model.native_spine_sprite.visible)
	actions.clear()
	host.queue_free()
	await process_frame
	print("SPINE_RESOURCES_TEST_OK")
	quit()
