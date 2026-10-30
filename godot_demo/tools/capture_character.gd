extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	var store := "/private/tmp/new-character-visual-%d.json" % OS.get_process_id()
	game.account_store = store
	root.add_child(game)
	await process_frame
	game.account_name.text = "character_preview"
	game._login()
	game.role_name_input.text = "初枝行者"
	game._confirm_role_name()
	var output := ProjectSettings.globalize_path("res://../output/character_current/")
	DirAccess.make_dir_recursive_absolute(output)
	for i in range(12):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output + "city.png")
	game._show_status_panel()
	for i in range(4):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output + "status.png")
	game.queue_free()
	await process_frame
	DirAccess.remove_absolute(store)
	print("CHARACTER_CAPTURE_OK")
	quit()
