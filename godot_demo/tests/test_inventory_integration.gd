extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var path := "/private/tmp/inventory-integration-%d.json" % OS.get_process_id()
	var game = load("res://main.tscn").instantiate()
	game.account_store = path
	root.add_child(game)
	await process_frame
	game.inventory.catalog = {
		"dew": {"name": "母树灵露（测试）", "category": "general", "type": "consumable", "type_name": "药物", "stack_limit": 20, "icon": "res://assets/items/mother_tree_dew.png", "description": "用于验证背包图标、堆叠与品质显示。仅存在于本次测试存档。", "source": "测试数据，不会发放到正式角色。"},
		"sword": {"name": "测试装备", "category": "equipment", "type": "equipment", "equipment_slot": "weapon", "stats": {"attack": 5}}}
	game.account_name.text = "inventory_a"
	game._login()
	game.role_name_input.text = "背包测试"
	game._confirm_role_name()
	assert(game.inventory.add_item("dew", 1038))
	assert(game.inventory.add_item("sword", 1))
	var accounts: Dictionary = game._load_accounts()
	assert(accounts[game.current_account_id].inventory.slots.size() == 3)
	game._show_backpack_panel()
	assert(game.inventory_panel.visible and game.inventory_panel.grid.columns == 6)
	assert(game.inventory_panel.category == "all" and game.inventory_panel.selected_uid == "")
	assert(game.inventory_panel.grid.get_child_count() == 50)
	game.inventory_panel.selected_uid = game.inventory.slots[0].uid
	game.inventory_panel.show_details()
	assert(game.inventory_panel.tips.visible)
	game.inventory_panel.dismiss_tips()
	assert(not game.inventory_panel.tips.visible)
	game._close_modal()
	assert(not game.inventory_panel.visible)
	game.account_name.text = "inventory_b"
	game._login()
	assert(game.inventory.slots.is_empty(), "Accounts must not share inventory")
	game.account_name.text = "inventory_a"
	game._login()
	assert(game.inventory.slots.size() == 3, "Inventory must survive login")
	game._enter_dungeon()
	assert(game.inventory.add_item("dew", 2, {"temporary": true}))
	game._finish_dungeon(false)
	assert(game.inventory.list_items("general", "temporary").is_empty())
	accounts = game._load_accounts()
	assert(accounts[game.current_account_id].inventory.slots.size() == 3)
	var sword_uid: String = game.inventory.list_items("equipment")[0].uid
	var attack_before := float(game._get_player_stat("attack"))
	assert(game.inventory.equip_item(sword_uid))
	assert(float(game._get_player_stat("attack")) == attack_before + 5)
	game.account_name.text = "inventory_a"
	game._login()
	assert(game.inventory.equipped.has("weapon"))
	assert(float(game._get_player_stat("attack")) == attack_before + 5)
	game._show_backpack_panel()
	game.inventory_panel.selected_uid = game.inventory.slots[0].uid
	game.inventory_panel.show_details()
	game.inventory_panel.scroll.get_v_scroll_bar().value_changed.emit(10)
	assert(game.inventory_panel.selected_uid.is_empty() and not game.inventory_panel.tips.visible)
	game.inventory_panel.category = "quest"
	game.inventory_panel.refresh()
	assert(game.inventory_panel.grid.get_child_count() == 0)
	game._close_modal()
	if "--capture" in OS.get_cmdline_user_args():
		root.mode = Window.MODE_WINDOWED
		root.size = Vector2i(1800, 750)
		for i in range(35):
			var key := "test_%d" % i
			game.inventory.catalog[key] = game.inventory.catalog.dew.duplicate(true)
			game.inventory.catalog[key].quality = i % 7
			assert(game.inventory.add_item(key, 1))
		game._show_backpack_panel()
		game.inventory_panel.selected_uid = game.inventory.slots[0].uid
		game.inventory_panel.show_details()
		for i in range(6):
			await process_frame
		await RenderingServer.frame_post_draw
		var output := ProjectSettings.globalize_path("res://../output/inventory/")
		DirAccess.make_dir_recursive_absolute(output)
		root.get_texture().get_image().save_png(output + "inventory.png")
	game.inventory.catalog["material"] = {"name": "测试材料", "category": "general", "type": "material", "type_name": "材料", "icon": "res://assets/items/mother_tree_dew.png", "description": "测试丢弃确认"}
	assert(game.inventory.add_item("material", 5))
	game._show_backpack_panel()
	var material_uid: String = game.inventory.list_items("general").filter(func(e): return e.item_id == "material")[0].uid
	game.inventory_panel.selected_uid = material_uid
	game.inventory_panel.show_details()
	for button in game.inventory_panel.details.get_children():
		if button is Button and button.text == "丢弃": button.pressed.emit()
	assert(game.inventory_panel.discard_dialog.visible)
	assert(game.inventory.find_slot(material_uid).count == 5)
	game.inventory_panel.quantity.value = 2
	if "--capture" in OS.get_cmdline_user_args():
		for i in range(3): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../output/inventory/discard.png"))
	game.inventory_panel.discard_dialog.confirmed.emit()
	assert(game.inventory.find_slot(material_uid).count == 3)
	assert(game.inventory_panel.selected_uid.is_empty())
	game.queue_free()
	await process_frame
	DirAccess.remove_absolute(path)
	print("INVENTORY_INTEGRATION_TEST_OK")
	quit()
