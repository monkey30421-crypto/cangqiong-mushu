extends Panel

signal closed
const InventoryScript = preload("res://modules/inventory_service.gd")
var inventory: InventoryScript
var in_dungeon := false
var category := "all"
var categories: OptionButton
var tips: Panel
var discard_dialog: ConfirmationDialog
var quantity: SpinBox
var pending_discard := ""
var filter_key := "all"
var selected_uid := ""
var grid: GridContainer
var details: VBoxContainer
var capacity_label: Label
var empty_label: Label
var scroll: ScrollContainer
const QUALITY_COLORS := [Color("777777"), Color("dddddd"), Color("77bd70"), Color("6bb3da"), Color("b183d4"), Color("d5b663"), Color("df6d62")]

func setup(service: InventoryScript) -> void:
	inventory = service
	position = Vector2(0, -35)
	size = Vector2(726, 700)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("202b29")
	style.border_color = Color("988463")
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	add_theme_stylebox_override("panel", style)
	var heading := Label.new()
	heading.text = "行者背包"
	heading.position = Vector2(24, 14)
	heading.add_theme_font_size_override("font_size", 24)
	add_child(heading)
	categories = OptionButton.new()
	categories.position = Vector2(200, 16)
	for title in ["全部", "通用", "装备", "任务", "技能"]:
		categories.add_item(title)
	categories.item_selected.connect(func(index): category = ["all", "general", "equipment", "quest", "skill"][index]; dismiss_tips(); scroll.scroll_vertical = 0; refresh())
	add_child(categories)
	var close_button := Button.new()
	close_button.text = "关闭 ×"
	close_button.position = Vector2(600, 12)
	close_button.size = Vector2(100, 38)
	close_button.pressed.connect(func(): closed.emit())
	add_child(close_button)
	var organize_button := Button.new()
	organize_button.text = "整理"
	organize_button.position = Vector2(337, 54)
	organize_button.pressed.connect(func(): dismiss_tips(); inventory.organize())
	add_child(organize_button)
	capacity_label = Label.new()
	capacity_label.position = Vector2(420, 59)
	add_child(capacity_label)
	scroll = ScrollContainer.new()
	scroll.position = Vector2(24, 94)
	scroll.size = Vector2(678, 590)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	grid = GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(grid)
	details = VBoxContainer.new()
	details.custom_minimum_size.x = 390
	tips = Panel.new()
	tips.position = Vector2(726, 0)
	tips.size = Vector2(430, 100)
	tips.clip_contents = true
	tips.add_theme_stylebox_override("panel", style.duplicate())
	add_child(tips)
	details.position = Vector2(20, 16)
	details.add_theme_constant_override("separation", 12)
	tips.add_child(details)
	details.minimum_size_changed.connect(func(): tips.size.y = minf(details.get_combined_minimum_size().y + 32, 700))
	scroll.get_v_scroll_bar().value_changed.connect(func(_value): dismiss_tips())
	discard_dialog = ConfirmationDialog.new()
	discard_dialog.title = "确认丢弃"
	discard_dialog.dialog_text = ""
	discard_dialog.get_ok_button().text = "确认丢弃"
	discard_dialog.get_cancel_button().text = "取消"
	var discard_content := VBoxContainer.new()
	discard_content.add_theme_constant_override("separation", 14)
	var warning := Label.new()
	warning.text = "丢弃后无法恢复，请选择数量并确认。"
	discard_content.add_child(warning)
	discard_dialog.add_child(discard_content)
	quantity = SpinBox.new()
	quantity.min_value = 1
	quantity.step = 1
	quantity.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	discard_content.add_child(quantity)
	discard_dialog.confirmed.connect(func(): inventory.discard_item(pending_discard, int(quantity.value)); dismiss_tips(); refresh())
	add_child(discard_dialog)
	empty_label = Label.new()
	empty_label.position = Vector2(24, 58)
	empty_label.add_theme_font_size_override("font_size", 15)
	add_child(empty_label)
	inventory.rejected.connect(func(message): empty_label.text = message)
	inventory.changed.connect(refresh)
	refresh()

func clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

func icon_for(definition: Dictionary) -> Texture2D:
	var path := str(definition.get("icon", ""))
	return load(path) as Texture2D if not path.is_empty() and ResourceLoader.exists(path) else null

func refresh() -> void:
	if grid == null:
		return
	clear_children(grid)
	var entries := inventory.list_items(category, filter_key)
	capacity_label.text = "%d / %s 格" % [inventory.slots.size(), str(inventory.capacity) if inventory.capacity > 0 else "不限"]
	empty_label.text = "副本中 · 临时物品结算后清除" if in_dungeon else "主城 · 物品随角色保存"
	var cells: Dictionary = {}
	for index in range(entries.size()):
		cells[int(entries[index].position) if category == "all" else index] = entries[index]
	var cell_count := inventory.capacity if category == "all" else entries.size()
	for index in range(cell_count):
		var button := Button.new()
		button.custom_minimum_size = Vector2(100, 100)
		button.clip_contents = true
		grid.add_child(button)
		if not cells.has(index):
			button.pressed.connect(dismiss_tips)
			continue
		var entry: Dictionary = cells[index]
		var definition: Dictionary = inventory.catalog[entry.item_id]
		var tile := StyleBoxFlat.new()
		tile.bg_color = Color("293632")
		tile.border_color = quality_color(definition)
		tile.set_border_width_all(2)
		button.add_theme_stylebox_override("normal", tile)
		button.tooltip_text = str(definition.get("name", "未命名道具"))
		var texture := icon_for(definition)
		if texture:
			var art := TextureRect.new()
			art.texture = texture
			art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			art.size = Vector2(100, 100)
			art.mouse_filter = Control.MOUSE_FILTER_IGNORE
			button.add_child(art)
		else:
			button.text = str(definition.get("name", "未命名道具")).left(5)
		var count_label := Label.new()
		count_label.text = str(int(entry.count)) if int(entry.count) > 1 else ""
		count_label.position = Vector2(60, 72)
		count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(count_label)
		button.pressed.connect(func(): selected_uid = str(entry.uid); show_details())
	show_details()

func text_line(value: String, color := Color("d9e0d7")) -> void:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 390
	label.add_theme_color_override("font_color", color)
	details.add_child(label)

func show_details() -> void:
	clear_children(details)
	var entry := inventory.find_slot(selected_uid)
	if entry.is_empty():
		tips.hide()
		return
	tips.show()
	var definition: Dictionary = inventory.catalog[entry.item_id]
	text_line(str(definition.get("name", "未命名道具")), quality_color(definition))
	var texture := icon_for(definition)
	if texture:
		var icon := TextureRect.new()
		icon.texture = texture
		icon.custom_minimum_size = Vector2(100, 100)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var frame := PanelContainer.new()
		frame.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		var border := StyleBoxFlat.new()
		border.bg_color = quality_color(definition).darkened(0.7)
		border.border_color = quality_color(definition)
		border.set_border_width_all(2)
		frame.add_theme_stylebox_override("panel", border)
		details.add_child(frame)
		frame.add_child(icon)
		if int(entry.count) > 1:
			var amount := Label.new()
			amount.text = str(int(entry.count))
			amount.position = Vector2(60, 72)
			icon.add_child(amount)
	text_line("%s · %s" % [str(definition.get("quality_name", inventory.QUALITY_NAMES[int(entry.quality)])), str(definition.get("type_name", definition.get("type", "道具")))])
	text_line(str(definition.get("description", "暂无说明")))
	text_line("绑定：%s%s" % [{"none": "未绑定", "role": "角色绑定", "account": "账号绑定"}.get(str(entry.binding), str(entry.binding)), " · 含副本临时物品" if int(entry.get("temporary_count", 0)) > 0 else ""])
	match str(definition.get("type", "")):
		"equipment": show_comparison(entry)
		"chest": text_line("宝箱内容：" + str(definition.get("contents_description", "未配置")))
		"skill": text_line("技能效果：" + str(definition.get("skill_description", "未配置")))
	if not entry.get("attributes", {}).is_empty():
		text_line("词缀：" + str(entry.attributes))
	var kind := str(definition.get("type", ""))
	if kind == "equipment":
		var equip := Button.new()
		equip.text = "装备"
		equip.disabled = in_dungeon or inventory.equipment_key(entry).is_empty()
		equip.tooltip_text = "副本中不可更换装备" if in_dungeon else ""
		equip.pressed.connect(func(): inventory.equip_item(selected_uid, in_dungeon); dismiss_tips(); refresh())
		details.add_child(equip)
	elif kind == "chest":
		var use := Button.new()
		use.text = "使用"
		use.disabled = true
		use.tooltip_text = "宝箱奖励系统尚未开放"
		details.add_child(use)
	if kind != "chest":
		var source := Button.new()
		source.text = "来源"
		details.add_child(source)
	if definition.get("category") not in ["quest", "skill"] and kind not in ["chest", "consumable"]:
		var discard := Button.new()
		discard.text = "丢弃"
		discard.pressed.connect(func():
			pending_discard = selected_uid
			quantity.max_value = int(entry.count)
			quantity.value = 1
			discard_dialog.popup_centered(Vector2i(400, 170)))
		details.add_child(discard)

func quality_color(definition: Dictionary) -> Color:
	return Color(str(definition.get("quality_color", QUALITY_COLORS[clampi(int(definition.get("quality", 1)), 0, 6)].to_html())))

func show_comparison(entry: Dictionary) -> void:
	var current: Dictionary = inventory.equipped.get(inventory.equipment_key(entry), {})
	var previous := inventory.stats_for(current)
	var incoming := inventory.stats_for(entry)
	var keys := incoming.keys()
	for key in previous:
		if not keys.has(key): keys.append(key)
	for key in keys:
		var value := float(incoming.get(key, 0))
		var difference := value - float(previous.get(key, 0))
		var color := Color("d9e0d7")
		var suffix := ""
		if not current.is_empty():
			if not previous.has(key):
				color = Color("6bb3da")
				suffix = "（新增）"
			elif difference != 0:
				color = Color("77bd70") if difference > 0 else Color("df6d62")
				suffix = "（%+g）" % difference
		text_line("%s：%g%s" % [key, value, suffix], color)

func dismiss_tips() -> void:
	selected_uid = ""
	if tips: tips.hide()

func open_inventory() -> void:
	category = "all"
	filter_key = "all"
	categories.select(0)
	dismiss_tips()
	scroll.scroll_vertical = 0
	refresh()

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not tips.visible or discard_dialog.visible:
		return
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
		if not tips.get_global_rect().has_point(get_global_mouse_position()):
			dismiss_tips()
