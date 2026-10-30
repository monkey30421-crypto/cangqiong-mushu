extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _spawn_demo(store: String, walkable_store: String, spawn_store: String, dungeon_store := "", project_store := "") -> Node:
	var scene := load("res://main.tscn") as PackedScene
	var demo: Node = scene.instantiate()
	demo.city_editor_project_store = project_store if not project_store.is_empty() else "/private/tmp/godot_demo_missing_main_city_editor.json"
	demo.dungeon_area_project_store = "/private/tmp/godot_demo_missing_dungeon_area_editor.json"
	demo.account_store = store
	demo.walkable_area_store = walkable_store
	demo.spawn_area_store = spawn_store
	if not dungeon_store.is_empty():
		demo.dungeon_area_store = dungeon_store
	root.add_child(demo)
	demo.set_process(false)
	return demo


func _login(demo: Node, account: String, entered_password: String) -> void:
	demo.account_name.text = account
	demo.password.text = entered_password
	demo._login()


func _set_role_name(demo: Node, value: String) -> void:
	demo.role_name_input.text = value
	demo._on_role_name_changed(value)


func _assert_display_rules(demo: Node) -> void:
	assert(ProjectSettings.get_setting("display/window/size/viewport_width") == 1800, "内部宽度必须固定为 1800")
	assert(ProjectSettings.get_setting("display/window/size/viewport_height") == 750, "内部高度必须固定为 750")
	assert(ProjectSettings.get_setting("display/window/size/window_width_override") == 1800, "全屏窗口宽度必须统一为 1800")
	assert(ProjectSettings.get_setting("display/window/size/window_height_override") == 750, "全屏窗口高度必须统一为 750")
	assert(ProjectSettings.get_setting("display/window/size/mode") == 3, "游戏必须保持全屏")
	assert(ProjectSettings.get_setting("display/window/size/resizable") == false, "窗口尺寸规则不能由玩家改变")
	assert(ProjectSettings.get_setting("display/window/stretch/mode") == "viewport", "必须先渲染固定 1800×750 视口")
	assert(ProjectSettings.get_setting("display/window/stretch/aspect") == "keep", "显示必须保持宽高比并允许黑边")
	assert(demo.scale == Vector2.ONE, "游戏根节点必须直接使用 1800×750 坐标，不能整体放大")
	assert(demo.VIEW_WIDTH == 1800.0 and demo.VIEW_HEIGHT == 750.0, "摄像机逻辑尺寸必须直接为 1800×750")
	assert(demo.CITY_WIDTH == demo.VIEW_WIDTH * 3.0, "新主城必须精确容纳三个 1800 像素宽的屏幕")
	assert(demo.DUNGEON_WIDTH == demo.VIEW_WIDTH * 3.0 and demo.DUNGEON_HEIGHT == 1200.0, "副本最大世界尺寸必须保留 5400×1200 的普通前景范围")
	assert(demo.login_screen.size == Vector2(1800, 750) and demo.login_screen.scale == Vector2.ONE, "登录 UI 必须直接使用 1800×750，不能放大")
	var login_background := demo.get_node("UI/LoginScreen/Background") as TextureRect
	assert(login_background.texture.get_size() == Vector2(1800, 750), "登录界面必须使用最新的 1800×750 完整设计图")
	assert(login_background.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "登录界面设计图必须按 1:1 像素显示")
	assert(demo.naming_screen.size == Vector2(1800, 750) and demo.naming_screen.scale == Vector2.ONE, "创角命名 UI 必须直接使用 1800×750")
	assert(demo.get_node("UI/NamingScreen/Frame/Prompt").text == "请告诉我你的名字", "命名界面必须显示指定提示文字")
	assert(demo.role_name_input is LineEdit and demo.naming_confirm_button.text == "确定", "命名界面必须包含输入框和确定按钮")
	var naming_frame_style := demo.get_node("UI/NamingScreen/Frame").get_theme_stylebox("panel") as StyleBoxFlat
	var naming_input_style := demo.role_name_input.get_theme_stylebox("normal") as StyleBoxFlat
	assert(naming_frame_style != null and naming_frame_style.border_width_left > 0, "临时命名面板必须使用线条框")
	assert(naming_input_style != null and naming_input_style.border_width_left > 0, "临时名字输入框必须显示线条边框")
	assert(demo.game_hud.size == Vector2(1800, 750) and demo.game_hud.scale == Vector2.ONE, "游戏 HUD 必须直接使用 1800×750，不能放大")
	assert(not demo.has_node("UI/GameHUD/TopBar") and not demo.has_node("UI/GameHUD/HintBack") and not demo.has_node("UI/GameHUD/Banner"), "游戏场景不能保留上下暗色遮罩或文字提示")
	var player_status := demo.get_node("UI/GameHUD/PlayerStatus") as Control
	var status_frame := demo.get_node("UI/GameHUD/PlayerStatus/StatusFrame") as TextureRect
	var portrait := demo.get_node("UI/GameHUD/PlayerStatus/Portrait") as TextureRect
	var health_bar := demo.get_node("UI/GameHUD/PlayerStatus/HealthBar") as ProgressBar
	var health_value_label := demo.get_node("UI/GameHUD/PlayerStatus/HealthValue") as Label
	var mana_bar := demo.get_node("UI/GameHUD/PlayerStatus/ManaBar") as ProgressBar
	assert(player_status.scale == Vector2(0.8, 0.8), "左上角角色状态栏必须恢复上一版本的 80% 显示比例")
	assert(status_frame.texture.get_size() == Vector2(600, 168) and status_frame.size == Vector2(600, 168), "状态栏必须保留 600×168 原始资源尺寸后统一缩放")
	assert(status_frame.get_global_transform().get_scale() == Vector2(0.8, 0.8), "状态栏必须使用上一版本的最终显示比例")
	assert(status_frame.global_position.is_equal_approx(Vector2(18, 12)), "状态栏必须恢复上一版本的左上角位置")
	assert(portrait.texture is AtlasTexture, "左上角必须显示当前角色的头像裁切")
	assert(health_bar.value == 100.0 and mana_bar.value == 100.0, "左上角必须显示绿色血条和蓝条")
	assert(health_value_label.text == "100 / 100", "左上角血条必须显示当前血量与最大血量")
	assert(health_bar.position == Vector2(226, 54) and health_bar.size == Vector2(364, 29), "血条必须精确对齐新外框开孔")
	assert(mana_bar.position == Vector2(227, 100) and mana_bar.size == Vector2(310, 25), "蓝条必须精确对齐新外框开孔")
	var resource_bar := demo.get_node("UI/GameHUD/ResourceBar") as TextureRect
	assert(resource_bar.position == Vector2(1475, 50) and resource_bar.size == Vector2(235, 53), "两种货币必须使用示意图中的原始位置与尺寸")
	assert(resource_bar.texture.get_size() == Vector2(235, 53), "右上货币栏必须直接显示从示意图提取的完整彩色贴图")
	assert(not demo.get_node("UI/GameHUD/ResourceBar/AmberAmount").visible and not demo.get_node("UI/GameHUD/ResourceBar/LeafAmount").visible, "货币文字不能再用独立线框控件重复绘制")
	var joystick := demo.get_node("UI/GameHUD/Joystick") as Control
	var joystick_art := demo.get_node("UI/GameHUD/Joystick/Art") as TextureRect
	var status_button := demo.get_node("UI/GameHUD/StatusButton") as Button
	var backpack_button := demo.get_node("UI/GameHUD/BackpackButton") as Button
	assert(joystick.position == Vector2(55, 587) and joystick.size == Vector2(146, 144), "移动摇杆必须恢复示意图中的位置与尺寸")
	assert(joystick_art.texture.get_size() == Vector2(146, 144), "摇杆必须直接使用示意图中的完整彩色贴图")
	assert(not demo.get_node("UI/GameHUD/Joystick/Base").visible, "摇杆不能显示临时底座线框")
	assert(demo.get_node("UI/GameHUD/Joystick/CenterMask").visible and demo.get_node("UI/GameHUD/Joystick/Knob").visible, "摇杆中间圆盘必须作为独立可移动层显示")
	assert(status_button.position == Vector2(197, 619) and backpack_button.position == Vector2(278, 619), "状态和背包按钮必须使用示意图中的紧凑位置")
	assert(status_button.size == Vector2(83, 94) and backpack_button.size == Vector2(85, 94), "左下功能按钮必须使用示意图贴图的原始尺寸")
	assert(status_button.icon.get_size() == Vector2(83, 94) and backpack_button.icon.get_size() == Vector2(85, 94), "状态与背包按钮必须直接使用示意图图标")
	var action_cluster := demo.get_node("UI/GameHUD/ActionCluster") as Control
	var attack_button := demo.get_node("UI/GameHUD/ActionCluster/AttackButton") as Button
	assert(action_cluster.position == Vector2(1320, 400) and action_cluster.size == Vector2(480, 350), "右下动作区必须占用紧凑的边缘区域")
	assert(attack_button.global_position == Vector2(1471, 568) and attack_button.size == Vector2(150, 168), "攻击按钮必须恢复示意图中的完整贴图位置与尺寸")
	assert(attack_button.icon.get_size() == Vector2(150, 168), "攻击按钮必须直接使用示意图中的剑形彩色图标")
	assert(not attack_button.expand_icon, "攻击按钮必须关闭图标扩展，禁止拉伸贴图")
	var expected_action_positions := {
		"Skill1Button": Vector2(1383, 635),
		"Skill2Button": Vector2(1380, 563),
		"Skill3Button": Vector2(1435, 500),
		"Skill4Button": Vector2(1506, 492),
		"JumpButton": Vector2(1582, 498),
		"DodgeButton": Vector2(1628, 565),
	}
	var expected_action_sizes := {
		"Skill1Button": Vector2(79, 94),
		"Skill2Button": Vector2(81, 98),
		"Skill3Button": Vector2(73, 93),
		"Skill4Button": Vector2(78, 100),
		"JumpButton": Vector2(78, 95),
		"DodgeButton": Vector2(85, 96),
	}
	var expected_content_aspects := {
		"Skill1Button": 95.0 / 85.0,
		"Skill2Button": 95.0 / 90.0,
		"Skill3Button": 92.0 / 89.0,
		"Skill4Button": 99.0 / 96.0,
		"JumpButton": 91.0 / 89.0,
		"DodgeButton": 93.0 / 88.0,
	}
	for button_name in expected_action_positions:
		var action_button := demo.get_node("UI/GameHUD/ActionCluster/" + button_name) as Button
		assert(action_button.global_position == expected_action_positions[button_name], "%s 必须使用示意图中的准确位置" % button_name)
		assert(action_button.size == expected_action_sizes[button_name], "%s 必须保留示意图贴图的原始尺寸" % button_name)
		assert(action_button.icon != null and action_button.icon.get_size() == expected_action_sizes[button_name], "%s 必须直接显示示意图彩色图标" % button_name)
		assert(not action_button.expand_icon, "%s 必须关闭图标扩展，禁止拉伸贴图" % button_name)
		var used_size := action_button.icon.get_image().get_used_rect().size
		var content_aspect := float(used_size.x) / float(used_size.y)
		assert(absf(content_aspect - expected_content_aspects[button_name]) < 0.04, "%s 的有效图像区域必须保持提取源宽高比" % button_name)
	var attack_used_size := attack_button.icon.get_image().get_used_rect().size
	var attack_content_aspect := float(attack_used_size.x) / float(attack_used_size.y)
	assert(absf(attack_content_aspect - 174.0 / 164.0) < 0.04, "攻击按钮的有效图像区域必须保持提取源宽高比")
	assert(demo.has_node("UI/GameHUD/Modal") and demo.has_node("UI/GameHUD/ModalDim"), "状态与背包必须使用游戏内信息面板")
	var status_content := demo.get_node("UI/GameHUD/Modal/StatusContent") as Control
	var status_preview := demo.get_node("UI/GameHUD/Modal/StatusContent/PreviewFrame/PreviewPlayer") as SpineSprite
	assert(status_content != null and status_preview != null, "状态面板必须包含属性展示区和主角待机模型")
	assert(status_preview.position == Vector2(150, 238), "状态面板中的主角模型必须固定在预览框中央区域")
	var city_layers := [
		{"node": demo.get_node("CityBackground/ForegroundLayer") as Node2D, "speed": 1.0, "path": "maincity-foreground.png"},
		{"node": demo.get_node("CityBackground/MidgroundLayer") as Node2D, "speed": 0.5, "path": "maincity-midground.png"},
		{"node": demo.get_node("CityBackground/BackgroundLayer") as Node2D, "speed": 0.1, "path": "maincity-background.jpg"},
	]
	for layer_spec in city_layers:
		var city_layer := layer_spec.node as Node2D
		var source := city_layer.get_node("Source") as Sprite2D
		assert(source.texture.get_size() == Vector2(5400, 1600), "三张主城分层图必须按原始 5400×1600 尺寸接入")
		assert(source.texture.resource_path.ends_with(layer_spec.path), "主城图层必须对应用户提供的前/中/背景文件")
		assert(source.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "主城分层图必须按原始像素显示")
		assert(source.global_transform.get_scale() == Vector2.ONE, "主城分层图不能缩放或拉伸")
		assert(source.region_enabled and source.region_rect == Rect2(0, 400, 5400, 1200), "主城必须在 5400×1200 世界范围内显示原图合法取景")
		assert(source.position == Vector2(2700, 600), "每个视差层必须与 5400×1200 主城世界居中对齐")
	assert(demo.CITY_FOREGROUND_PARALLAX == 1.0 and demo.CITY_MIDGROUND_PARALLAX == 0.5 and demo.CITY_BACKGROUND_PARALLAX == 0.1, "主城近景/中景/背景横向视差速度必须为 100%/50%/10%")
	assert(not demo.has_node("CityBackground/Teleport"), "传送阵必须烘焙在屏 2，不得再使用独立图层")
	var portal_effect := demo.get_node("CityBackground/ForegroundLayer/PortalEffect") as AnimatedSprite2D
	assert(portal_effect.position == Vector2(5107, 544), "主城传送特效必须对准屏 2 地面传送阵")
	assert(portal_effect.scale == Vector2(1.5, 1.5), "主城传送特效必须与 2.5–4.0H 传送阵尺度相容")
	assert(portal_effect.sprite_frames.get_frame_count(&"loop") == demo.PORTAL_EFFECT_FRAME_COUNT, "主城传送特效必须使用 20 帧以内的完整循环")
	assert(portal_effect.sprite_frames.get_animation_loop(&"loop"), "主城传送特效必须循环播放")
	assert(is_equal_approx(portal_effect.sprite_frames.get_animation_speed(&"loop"), demo.PORTAL_EFFECT_FPS), "主城传送特效必须保持原动图节奏")
	var portal_material := portal_effect.material as CanvasItemMaterial
	assert(portal_material != null and portal_material.blend_mode == CanvasItemMaterial.BLEND_MODE_ADD, "主城传送特效必须使用加法发光混合")
	var dungeon_scene := demo.get_node("DungeonBackground/Scene") as Sprite2D
	var dungeon_midground := demo.get_node("DungeonBackground/Midground") as Sprite2D
	var dungeon_foreground := demo.get_node("DungeonBackground/Foreground") as Sprite2D
	assert(dungeon_scene.texture == demo.DUNGEON_SHARED_BACKGROUND and dungeon_scene.texture.get_size() == Vector2(5400, 1600), "副本所有房间必须共用树海背景图")
	assert(dungeon_scene.region_enabled and dungeon_scene.region_rect == Rect2(0, 400, 5400, 1200), "副本背景必须按原生尺寸裁取 1200 高的世界区域")
	assert(demo.DUNGEON_NORMAL_FOREGROUNDS.size() == 2 and demo.DUNGEON_NORMAL_MIDGROUNDS.size() == 3, "普通房必须使用两张前景和三张中景组合")
	assert(demo.DUNGEON_START_FOREGROUND.get_size() == Vector2(2400, 1600) and demo.DUNGEON_START_MIDGROUND.get_size() == Vector2(2400, 1600), "起点房必须接入固定的 start 前中景")
	assert(demo.DUNGEON_BOSS_FOREGROUND.get_size() == Vector2(3600, 1600) and demo.DUNGEON_BOSS_MIDGROUND.get_size() == Vector2(3600, 1600), "首领房必须接入固定的 boss 前中景")
	for dungeon_layer in [dungeon_scene, dungeon_midground, dungeon_foreground]:
		assert(dungeon_layer.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST and dungeon_layer.global_transform.get_scale() == Vector2.ONE, "副本分层必须继续按 1:1 像素显示")
	assert(demo.has_node("UI/GameHUD/DungeonMenuButton") and demo.has_node("UI/GameHUD/InteractButton"), "副本必须提供菜单与祭坛树/传送阵交互按钮")
	assert(demo.has_node("UI/GameHUD/Modal/PrimaryButton") and demo.has_node("UI/GameHUD/Modal/SecondaryButton"), "副本选择、对话与结算必须提供明确操作按钮")
	var traveler := demo.get_node("Traveler") as SpineSprite
	var traveler_scale := traveler.global_transform.get_scale()
	assert(is_equal_approx(absf(traveler_scale.x), absf(traveler_scale.y)), "角色只能等比缩放")
	assert(is_equal_approx(absf(traveler_scale.x), 1.0) and is_equal_approx(absf(traveler_scale.y), 1.0), "角色必须以源文件原始尺寸显示，不能缩放")
	assert(traveler.skeleton_data_res != null and traveler.get_skeleton() != null, "主角必须接入有效的原生 Spine 骨骼")
	assert(status_preview.skeleton_data_res == traveler.skeleton_data_res, "状态预览与场景主角必须使用同一骨骼资源")
	for id in [1001, 1003, 2001]:
		var clip: Dictionary = demo.character_actions._clip(id)
		var animation_name := str(clip.get("source_animation", demo.character_actions.rows[id].animation))
		assert(traveler.skeleton_data_res.find_animation(animation_name) != null, "已配置的待机、跑步、攻击必须存在于 Spine 中")
		demo.character_actions.play(id, true)
		var track = traveler.get_animation_state().get_track(0)
		assert(track != null and track.get_animation().get_name() == animation_name)
		assert(track.get_loop() == (id != 2001), "待机与跑步循环，攻击单次播放")
	demo.character_actions.play(1001, true)


func _run() -> void:
	# /private/tmp keeps the self-test isolated when user:// is unavailable in CI/sandbox runs.
	var store := "/private/tmp/godot_demo_accounts_codex_test.json"
	var walkable_store := "/private/tmp/godot_demo_walkable_area_codex_test.json"
	var spawn_store := "/private/tmp/godot_demo_spawn_area_codex_test.json"
	var dungeon_store := "/private/tmp/godot_demo_dungeon_area_editor_codex_test.json"
	var empty_effects_project_store := "/private/tmp/godot_demo_empty_effects_project_config.json"
	var test_files := [store, walkable_store, spawn_store, dungeon_store, empty_effects_project_store]
	for path in test_files:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

	var demo := _spawn_demo(store, walkable_store, spawn_store, dungeon_store)
	await process_frame
	_assert_display_rules(demo)
	var empty_effects_file := FileAccess.open(empty_effects_project_store, FileAccess.WRITE)
	empty_effects_file.store_string(JSON.stringify({"effects": []}))
	empty_effects_file.close()
	var no_effect_demo := _spawn_demo(store, walkable_store, spawn_store, "", empty_effects_project_store)
	await process_frame
	var no_effect_portal := no_effect_demo.get_node("CityBackground/ForegroundLayer/PortalEffect") as AnimatedSprite2D
	assert(not no_effect_portal.visible, "主城配置显式删除全部特效后，传送阵金光必须停止并隐藏")
	no_effect_demo.queue_free()
	assert(not demo.has_node("UI/LoginScreen/Card/Form/AccountID"), "登录界面不能显示或要求输入内部账号 ID")
	assert(demo.account_name.visible and demo.account_name.editable, "登录界面必须提供账号输入框")
	assert(demo.password.visible and demo.password.editable and demo.password.secret, "密码输入框保留且输入内容仍需隐藏")
	_login(demo, "", "test_password")
	assert(demo.state == "login", "账号为空时必须拒绝登录")
	_login(demo, "测试账号", "")
	assert(demo.state == "naming" and demo.naming_screen.visible, "新账号密码为空时也必须先进入命名界面")
	assert(not demo.login_screen.visible and not demo.game_hud.visible and not demo.traveler.visible, "命名期间不能显示登录界面或游戏 HUD")
	assert(demo.current_account_id.begins_with("acct_"), "新账号在待命名阶段也必须获得自动生成的内部 ID")
	demo._confirm_role_name()
	assert(demo.naming_warning.text == "名字不能为空" and demo.state == "naming", "空名字必须阻止进入主城")
	_set_role_name(demo, "一二三四五六七")
	assert(demo.role_name_input.text == "一二三四五六" and demo.role_name_input.text.to_utf8_buffer().size() == 18, "汉字输入超过 18 UTF-8 字节时必须保留最长完整前缀")
	_set_role_name(demo, "abcdefghijklmnopqrs")
	assert(demo.role_name_input.text == "abcdefghijklmnopqr" and demo.role_name_input.text.to_utf8_buffer().size() == 18, "ASCII 输入超过 18 字节时必须被截断")
	_set_role_name(demo, "勇 者")
	demo._confirm_role_name()
	assert(demo.naming_warning.text == "使用非法字符" and demo.state == "naming", "名字中包含空格时必须拒绝提交")
	_set_role_name(demo, "勇者😀")
	demo._confirm_role_name()
	assert(demo.naming_warning.text == "使用非法字符" and demo.state == "naming", "Emoji 必须被判定为非法字符")
	var first_role := "苍穹行者01"
	_set_role_name(demo, first_role)
	assert(demo.naming_warning.text.is_empty(), "输入新的合法文字后必须清除之前的警告")
	demo._confirm_role_name()
	assert(demo.state == "city", "合法名字确认后必须进入主城")
	assert(demo.role_name == first_role and demo.player_name_label.text == first_role, "左上角状态栏必须显示已确认的角色名")
	assert(demo.dungeon_menu_button.visible and demo.dungeon_menu_button.text == "选项", "主城右上角必须显示选项按钮")
	demo.dungeon_menu_button.emit_signal("pressed")
	assert(demo.modal_mode == "city_options" and demo.modal_title.text == "选项", "主城选项按钮必须打开选项列表")
	assert(demo.modal_primary_button.visible and demo.modal_primary_button.text == "退出游戏" and not demo.modal_secondary_button.visible, "主城选项列表只能提供退出游戏按钮")
	demo._close_modal()
	assert(demo.player_stats == {
		"race": "人族",
		"level": 1,
		"experience": 0,
		"max_health": 100,
		"max_mana": 100,
		"mana_regen": 1.0,
		"mana_absorb": 2.0,
		"attack": 10,
		"defense": 10,
		"attack_speed": 2.0,
		"move_speed": 100.0,
		"crit_rate": 5.0,
		"crit_damage": 150.0,
		"skill_haste": 100.0,
		"healing_power": 100.0,
		"life_steal": 0.0,
	}, "新角色必须自动拥有属性文档中约定的全部初始属性")
	assert(demo.current_health == 100.0 and demo.current_mana == 100.0, "进入游戏时当前生命与灵蕴必须与属性上限同步")
	assert(is_equal_approx(demo._attack_interval(), 0.5), "主角基础攻击速度为 2 次/秒时，普通攻击间隔必须为 0.5 秒")
	assert(demo._normalize_player_stats({"attack_speed": 1.0})["attack_speed"] == 2.0, "旧账号的 1 次/秒基础攻击速度必须迁移为 2 次/秒")
	assert(demo.city_background.position.y == -demo.camera_y, "主城必须以原始像素跟随纵向摄像机，不得缩放场景")
	var saved_city_camera_x: float = demo.camera_x
	demo.camera_x = 1800.0
	demo._update_city_parallax()
	assert(demo.city_foreground_layer.position.x == -1800.0, "近景必须按 100% 速度横向移动")
	assert(demo.city_midground_layer.position.x == -900.0, "中景必须按 50% 速度横向移动")
	assert(demo.city_background_layer.position.x == -180.0, "背景必须按 10% 速度横向移动")
	demo.camera_x = saved_city_camera_x
	demo._update_city_parallax()
	assert(demo.PORTAL == Vector2(5107, 800), "传送交互点必须位于新的主城可行走区域内")
	assert(demo._is_in_city_portal_trigger(demo.city_portal_trigger_position), "主城传送阵中心必须位于可编辑触发椭圆内")
	assert(not demo._is_in_city_portal_trigger(demo.city_portal_trigger_position + Vector2(demo.city_portal_trigger_radius.x * 1.1, 0.0)), "主城传送阵触发椭圆外不得触发")
	assert(demo.city_walkable_polygon == PackedVector2Array([
		Vector2(demo.PLAYER_HORIZONTAL_MARGIN, demo.CITY_WALKABLE_TOP),
		Vector2(demo.CITY_WIDTH - demo.PLAYER_HORIZONTAL_MARGIN, demo.CITY_WALKABLE_TOP),
		Vector2(demo.CITY_WIDTH - demo.PLAYER_HORIZONTAL_MARGIN, demo.CITY_WALKABLE_BOTTOM),
		Vector2(demo.PLAYER_HORIZONTAL_MARGIN, demo.CITY_WALKABLE_BOTTOM),
	]), "主城可行走区域必须从默认四边形开始")
	assert(not demo.CITY_WALKABLE_EDITOR_ENABLED, "主城可行走区域的显示与编辑必须关闭")
	assert(demo.city_spawn_rect == demo.CITY_SPAWN_DEFAULT_RECT, "主城必须建立默认的矩形随机出生范围")
	var first_spawn: Vector2 = demo.player
	assert(demo.city_spawn_rect.grow(0.001).has_point(first_spawn), "登录进入主城时必须在出生矩形内随机出生")
	assert(demo._is_point_in_city_walkable_area(first_spawn), "随机出生点必须位于固定可行走区内")
	demo.player.y = 0.0
	demo._clamp_player_position()
	assert(is_equal_approx(demo.player.y, demo.CITY_WALKABLE_TOP), "主城可行走区域默认上缘必须为源图 y=400")
	demo.player.y = 2000.0
	demo._clamp_player_position()
	assert(is_equal_approx(demo.player.y, demo.CITY_WALKABLE_BOTTOM), "主城可行走区域默认下缘必须为源图 y=800")
	assert(demo.PLAYER_SCREEN_BASELINE_Y == 550.0, "非边缘区域的角色脚底跟随基准必须为屏幕 y=550")
	for city_y in [demo.CITY_WALKABLE_TOP, demo.CITY_WALKABLE_BOTTOM]:
		demo.player = Vector2(260.625, city_y)
		demo._process(0.0)
		assert(demo.camera_y >= 0.0 and demo.camera_y + demo.VIEW_HEIGHT <= demo.CITY_HEIGHT, "纵向镜头不能超出场景上下边缘")
		assert(is_equal_approx(demo.traveler.position.y, demo.player.y - demo.camera_y), "边缘处角色位置必须正确跟随受限镜头")
	demo.player = Vector2(260.625, 600.0)
	demo._process(0.0)
	var spawn_screen_rect: Rect2 = demo._city_spawn_screen_rect()
	assert(spawn_screen_rect.position == demo.city_spawn_rect.position - Vector2(demo.camera_x, demo.camera_y), "出生范围颜色框必须与主城世界坐标一致")
	assert(not demo.CITY_SPAWN_EDITOR_ENABLED, "主城出生点编辑器必须关闭")
	var spawn_before_input: Rect2 = demo.city_spawn_rect
	var mouse_press := InputEventMouseButton.new()
	mouse_press.button_index = MOUSE_BUTTON_LEFT
	mouse_press.pressed = true
	mouse_press.position = spawn_screen_rect.get_center()
	demo._input(mouse_press)
	assert(demo.spawn_drag_corner == -1 and demo.spawn_drag_pointer == demo.NO_POINTER and demo.city_spawn_rect == spawn_before_input, "出生区域编辑关闭后鼠标输入不得改变出生范围")
	var city_walkable_edge_screen := Vector2(2700.0, demo.CITY_WALKABLE_TOP) - Vector2(demo.camera_x, demo.camera_y)
	var add_city_walkable_vertex := InputEventMouseButton.new()
	add_city_walkable_vertex.button_index = MOUSE_BUTTON_LEFT
	add_city_walkable_vertex.pressed = true
	add_city_walkable_vertex.position = city_walkable_edge_screen
	demo._input(add_city_walkable_vertex)
	assert(demo.city_walkable_polygon.size() == 4 and demo.city_walkable_drag_pointer == demo.NO_POINTER, "可行走区域编辑关闭后鼠标输入不得新增顶点")
	assert(demo._is_city_spawn_rect_valid(demo.city_spawn_rect), "出生矩形必须保留合法尺寸和画布位置")
	assert(not demo._is_city_spawn_rect_valid(Rect2(0.0, 0.0, 100.0, 200.0)), "出生矩形不能小于最小尺寸")
	var varied_spawn := false
	for spawn_sample_index in range(16):
		var spawn_sample: Vector2 = demo._random_city_spawn_point()
		assert(demo.city_spawn_rect.grow(0.001).has_point(spawn_sample), "每个随机出生点都必须在矩形范围内")
		assert(demo._is_point_in_city_walkable_area(spawn_sample), "每个随机出生点都必须可行走")
		varied_spawn = varied_spawn or not spawn_sample.is_equal_approx(first_spawn)
	assert(varied_spawn, "主城出生位置不能始终是同一个固定点")
	demo._enter_city(false)
	assert(demo.city_spawn_rect.grow(0.001).has_point(demo.player), "再次进入主城时必须重新在矩形内随机出生")
	demo.player = Vector2(260.625, 600.0)
	demo.camera_x = 0.0
	demo._process(0.0)
	assert(demo.current_account_id.begins_with("acct_"), "账号 ID 应由系统自动生成")
	assert(demo.role_name == first_role, "角色名必须使用玩家自定义的名字")
	assert(demo.player_name_label.text == demo.role_name, "绿色血条上方必须显示当前玩家名称")
	var joystick_start_x: float = demo.player.x
	demo._set_joystick_from_position(demo.JOYSTICK_CENTER + Vector2(demo.JOYSTICK_RADIUS, 0))
	assert(demo.joystick_vector.is_equal_approx(Vector2.RIGHT), "摇杆拖到最右侧时必须产生完整右移输入")
	assert(demo.joystick_knob.position == demo.JOYSTICK_CENTER - demo.joystick_knob.size * 0.5 + Vector2(demo.JOYSTICK_RADIUS, 0), "摇杆中间圆盘必须跟随操控位置移动")
	demo._process(0.1)
	assert(demo.player.x > joystick_start_x, "游戏内摇杆必须能实际驱动角色移动")
	demo._reset_joystick()
	assert(demo.joystick_vector == Vector2.ZERO and demo.joystick_knob.position == demo.JOYSTICK_CENTER - demo.joystick_knob.size * 0.5, "松开摇杆后必须回中并停止移动")
	demo.status_button.emit_signal("pressed")
	assert(demo.modal.visible and demo.modal_dim.visible, "状态按钮必须打开玩家信息面板")
	assert(demo.modal_title.text == "玩家状态" and demo.status_content.visible and not demo.modal_body.visible, "状态按钮必须切换到属性面板布局")
	assert(demo.status_name_label.text == demo.role_name, "属性面板必须显示当前玩家名称")
	assert(demo.status_preview_player.get_animation_state().get_track(0).get_animation().get_name() == "idle_SingleWeapon" and demo.status_preview_player.get_animation_state().get_track(0).get_loop(), "属性面板内必须播放主角待机动作")
	assert("种族：人族" in demo.status_left_attributes.text and "攻击力：10" in demo.status_left_attributes.text, "属性面板左侧必须显示前半组主角属性")
	assert("技能急速：100.00%" in demo.status_right_attributes.text and "吸血：0.00%" in demo.status_right_attributes.text, "属性面板右侧必须显示后半组主角属性")
	var modal_pause_x: float = demo.player.x
	demo._set_joystick_from_position(demo.JOYSTICK_CENTER + Vector2(demo.JOYSTICK_RADIUS, 0))
	demo._process(0.1)
	assert(is_equal_approx(demo.player.x, modal_pause_x), "打开信息面板时不能继续移动角色")
	demo.modal_close_button.emit_signal("pressed")
	assert(not demo.modal.visible and not demo.modal_dim.visible, "信息面板关闭按钮必须恢复游戏界面")
	demo.backpack_button.emit_signal("pressed")
	assert(demo.modal.visible and demo.modal_title.text == "行者背包" and demo.inventory_panel.visible and not demo.modal_body.visible and not demo.status_content.visible, "背包按钮必须打开分类格子背包面板")
	demo._close_modal()
	demo.skill_buttons[2].emit_signal("pressed")
	assert(demo.last_skill_index == 3, "四个技能槽必须分别提供独立交互入口")
	var first_id: String = demo.current_account_id
	var stored_accounts: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(store))
	assert(stored_accounts.has(first_id), "自动生成的账号 ID 必须保存")
	assert(stored_accounts[first_id].get("role_name", "") == first_role and stored_accounts[first_id].get("character_creation_completed", false), "已确认的角色名和创角状态必须保存")
	assert(stored_accounts[first_id].get("player_stats", {}).get("attack", 0) == 10 and stored_accounts[first_id].get("player_stats", {}).get("max_mana", 0) == 100, "账号存档中必须写入主角属性")
	assert(not stored_accounts[first_id].has("password"), "密码功能停用期间不能保存明文密码")
	assert(not stored_accounts[first_id].has("password_hash") and not stored_accounts[first_id].has("password_salt"), "密码功能停用期间不保存密码摘要或盐值")

	demo.player = demo.PORTAL
	demo.attack_button.emit_signal("pressed")
	assert(demo.state == "city" and demo.modal_mode == "dungeon_select", "主城传送阵必须先打开副本选择列表")
	var dungeon_list := demo.get_node("UI/GameHUD/Modal/DungeonSelectionList") as Control
	var floor_one_button := demo.get_node("UI/GameHUD/Modal/DungeonSelectionList/FloorOneButton") as Button
	assert(dungeon_list.visible and floor_one_button.visible and "第一层" in floor_one_button.text and "年轮树海" in floor_one_button.text, "副本选择必须提供可选的大框列表条目，并显示层数与副本名")
	assert(demo.modal_close_button.visible and not demo.modal_secondary_button.visible, "副本选择只保留关闭按钮，不显示重复的取消按钮")
	assert(not demo.modal_close_button.get_global_rect().intersects(demo.modal_primary_button.get_global_rect()), "关闭与确认进入按钮的点击区域不得重叠")
	assert(demo.modal_primary_button.visible and demo.modal_primary_button.disabled, "未选中副本时不能直接确认进入")
	floor_one_button.emit_signal("pressed")
	assert(not demo.modal_primary_button.disabled, "选中副本后必须启用确认进入入口")
	demo.modal_primary_button.emit_signal("pressed")
	assert(demo.state == "dungeon" and demo.dungeon_current_node_id == "2A", "确认后必须进入固定起点 2A")
	assert(demo.dungeon_route_nodes.size() == 9 and demo.dungeon_columns.size() == 6, "第一层每次必须生成 9 个区域并按 A-F 六列组织")
	assert(demo.dungeon_columns[0] == ["2A"] and demo.dungeon_columns[5] == ["2F"], "起点必须固定为 2A，首领区域必须固定为 2F")
	var middle_node_count := 0
	for column_index in range(1, 5):
		assert(demo.dungeon_columns[column_index].size() >= 1 and demo.dungeon_columns[column_index].size() <= 3, "B-E 每列必须生成 1 至 3 个区域")
		middle_node_count += demo.dungeon_columns[column_index].size()
	assert(middle_node_count == 7, "B-E 四列必须总共生成 7 个区域")
	assert(demo.dungeon_elite_weight >= 0.0 and demo.dungeon_elite_weight <= 20.0, "本局精英区域权重必须位于 0%-20%")
	assert(demo.dungeon_mutation_weight >= 0.0 and demo.dungeon_mutation_weight <= 10.0, "本局变异区域权重必须位于 0%-10%")
	var reachable := {"2A": true}
	for column_index in range(demo.dungeon_columns.size() - 1):
		for source_id in demo.dungeon_columns[column_index]:
			if not reachable.has(source_id):
				continue
			for target_id in demo.dungeon_route_nodes[source_id]["connections"]:
				reachable[target_id] = true
	assert(reachable.size() == 9 and reachable.has("2F"), "所有生成节点都必须从 2A 可达并最终通往 2F")
	for column_index in range(demo.dungeon_columns.size() - 1):
		var edges: Array = []
		for source_id in demo.dungeon_columns[column_index]:
			assert(not demo.dungeon_route_nodes[source_id]["connections"].is_empty(), "每个非首领节点必须至少连接一个下一列节点")
			for target_id in demo.dungeon_route_nodes[source_id]["connections"]:
				assert(absi(int(demo.dungeon_route_nodes[source_id]["row"]) - int(demo.dungeon_route_nodes[target_id]["row"])) <= 1, "路线只能连接相邻编号位置")
				if column_index >= 1 and column_index <= 3:
					assert(demo.dungeon_route_nodes[source_id]["map"] != demo.dungeon_route_nodes[target_id]["map"], "相邻可移动节点不能使用同一张中间地图")
				edges.append([int(demo.dungeon_route_nodes[source_id]["row"]), int(demo.dungeon_route_nodes[target_id]["row"])])
		for first_edge in edges:
			for second_edge in edges:
				assert(not (first_edge[0] < second_edge[0] and first_edge[1] > second_edge[1]), "同一列之间的路线连接不能交叉")
	assert(demo._portal_index_from_rows(2, 2) == 1, "同一行前进必须使用中间传送阵")
	assert(demo._portal_index_from_rows(3, 2) == 0, "从 3B 前往 2C 必须使用上方传送阵")
	assert(demo._portal_index_from_rows(1, 2) == 2, "从 1B 前往 2C 必须使用下方传送阵")
	assert(demo.dungeon_route_nodes["2A"]["map"] == 1 and demo.dungeon_route_nodes["2F"]["map"] == 6, "起点必须使用地图1，首领必须使用地图6")
	for column_index in range(1, 5):
		for node_id in demo.dungeon_columns[column_index]:
			assert(int(demo.dungeon_route_nodes[node_id]["map"]) >= 2 and int(demo.dungeon_route_nodes[node_id]["map"]) <= 5, "中间区域只能使用地图2至地图5")
	assert(demo.dungeon_scene.texture == demo.DUNGEON_SHARED_BACKGROUND and demo.dungeon_foreground.texture == demo.DUNGEON_START_FOREGROUND and demo.dungeon_midground.texture == demo.DUNGEON_START_MIDGROUND, "进入副本必须固定使用 start 前景和中景")
	assert(demo.dungeon_world_width == 2400.0, "起点房世界宽度必须由 2400 像素前景决定")
	assert(demo.dungeon_portal_spine_effects.size() == demo.DUNGEON_PORTAL_POSITIONS.size(), "每个副本传送阵必须创建一个官方 Spine 特效实例")
	for portal_effect in demo.dungeon_portal_spine_effects:
		assert(portal_effect is SpineSprite and portal_effect.skeleton_data_res != null, "副本传送阵必须直接使用官方 SpineSprite 和 skeleton data 资源")
		assert(not portal_effect.visible, "挑战完成前副本传送阵 Spine 特效必须保持隐藏")
	assert(demo._dungeon_portal_spine_animation_for_type("normal") == "1" and demo._dungeon_portal_spine_animation_for_type("elite") == "2" and demo._dungeon_portal_spine_animation_for_type("mutation") == "3" and demo._dungeon_portal_spine_animation_for_type("boss") == "4", "传送阵必须按普通、精英、变异、首领依次映射 Spine 动作 1 至 4")
	demo.camera_x = 100.0
	demo._update_dungeon_parallax()
	assert(is_equal_approx(demo.dungeon_foreground.position.x, 1100.0) and is_equal_approx(demo.dungeon_midground.position.x, 1150.0) and is_equal_approx(demo.dungeon_scene.position.x, 2690.0), "副本前中背景必须分别按 100%、50%、10% 的速度移动")
	demo.camera_x = 0.0
	demo._update_dungeon_parallax()
	assert(demo.monsters.is_empty() and demo.dungeon_stage == "await_altar", "起始区域 2A 不得生成怪物，必须先完成祭坛树对话")
	assert(demo.dungeon_menu_button.visible, "进入副本后右上角菜单按钮必须显示")
	assert(demo.dungeon_walkable_by_foreground.size() == 4 and demo.dungeon_walkable_polygons.size() == 6 and demo.dungeon_altar_trigger_polygons.size() == 6 and demo.dungeon_portal_trigger_positions.size() == 6 and demo.dungeon_portal_trigger_radii.size() == 6 and demo.dungeon_portal_effect_positions.size() == 6 and demo.dungeon_spawn_rects.size() == 6, "副本可行走区必须按四张前景图保存，祭坛、传送阵、传送特效和出生区域按六张地图保存")
	var active_spawn_rect: Rect2 = demo._current_dungeon_spawn_rect()
	assert(active_spawn_rect.has_point(demo.player), "进入副本地图时必须在当前地图配置的出生区域内随机出生")
	var dungeon_walkable: PackedVector2Array = demo._current_dungeon_polygon("walkable")
	var altar_trigger: PackedVector2Array = demo._current_dungeon_polygon("altar")
	assert(dungeon_walkable.size() == 4 and altar_trigger.size() == 8, "副本编辑器必须提供可修改的默认区域多边形")
	demo.player = Vector2(-100.0, -100.0)
	demo._clamp_player_position()
	assert(demo._is_point_in_polygon_or_edge(demo.player, dungeon_walkable), "副本玩家位置必须被限制在当前地图的可行走多边形内")
	var walkable_edge_screen := Vector2(demo.dungeon_world_width * 0.5, demo.DUNGEON_WALKABLE_TOP) - Vector2(demo.camera_x, demo.camera_y)
	var add_walkable_vertex := InputEventMouseButton.new()
	add_walkable_vertex.button_index = MOUSE_BUTTON_LEFT
	add_walkable_vertex.pressed = true
	add_walkable_vertex.position = walkable_edge_screen
	assert(not demo.dungeon_area_editor_enabled, "游戏默认必须关闭副本区域可视化与编辑")
	demo._input(add_walkable_vertex)
	assert(demo._current_dungeon_polygon("walkable").size() == 4, "关闭编辑后点击区域边缘不得修改配置")
	demo.dungeon_area_editor_enabled = true
	demo._input(add_walkable_vertex)
	assert(demo._current_dungeon_polygon("walkable").size() == 5, "左键点击副本可行走区边缘必须新增一个顶点")
	var release_walkable_vertex := InputEventMouseButton.new()
	release_walkable_vertex.button_index = MOUSE_BUTTON_LEFT
	release_walkable_vertex.pressed = false
	release_walkable_vertex.position = walkable_edge_screen
	demo._input(release_walkable_vertex)
	var delete_walkable_vertex := InputEventMouseButton.new()
	delete_walkable_vertex.button_index = MOUSE_BUTTON_RIGHT
	delete_walkable_vertex.pressed = true
	delete_walkable_vertex.position = walkable_edge_screen
	demo._input(delete_walkable_vertex)
	assert(demo._current_dungeon_polygon("walkable").size() == 4, "右键点击副本可行走区顶点必须删除该顶点")
	var altar_edge_screen := (altar_trigger[0] + altar_trigger[1]) * 0.5 - Vector2(demo.camera_x, demo.camera_y)
	var add_altar_vertex := InputEventMouseButton.new()
	add_altar_vertex.button_index = MOUSE_BUTTON_LEFT
	add_altar_vertex.pressed = true
	add_altar_vertex.position = altar_edge_screen
	demo._input(add_altar_vertex)
	assert(demo._current_dungeon_polygon("altar").size() == 9, "左键点击祭坛树触发区边缘必须新增一个顶点")
	var release_altar_vertex := InputEventMouseButton.new()
	release_altar_vertex.button_index = MOUSE_BUTTON_LEFT
	release_altar_vertex.pressed = false
	release_altar_vertex.position = altar_edge_screen
	demo._input(release_altar_vertex)
	var delete_altar_vertex := InputEventMouseButton.new()
	delete_altar_vertex.button_index = MOUSE_BUTTON_RIGHT
	delete_altar_vertex.pressed = true
	delete_altar_vertex.position = altar_edge_screen
	demo._input(delete_altar_vertex)
	assert(demo._current_dungeon_polygon("altar").size() == 8, "右键点击祭坛树触发区顶点必须删除该顶点")
	var saved_dungeon_areas: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(dungeon_store))
	assert(saved_dungeon_areas.get("walkable_polygons_by_foreground", {}).size() == 4 and saved_dungeon_areas.get("altar_trigger_polygons", []).size() == 6 and saved_dungeon_areas.get("altar_trigger_polygons_by_foreground", {}).size() == 4, "副本可行走区与祭坛触发区必须按四套前景资源保存")
	var initial_portal_position: Vector2 = demo._current_dungeon_portal_trigger_position(0)
	demo.camera_x = demo.DUNGEON_WIDTH - demo.VIEW_WIDTH
	var portal_screen_position: Vector2 = initial_portal_position - Vector2(demo.camera_x, demo.camera_y)
	var portal_press := InputEventMouseButton.new()
	portal_press.button_index = MOUSE_BUTTON_LEFT
	portal_press.pressed = true
	portal_press.position = portal_screen_position
	demo._input(portal_press)
	var portal_drag := InputEventMouseMotion.new()
	portal_drag.button_mask = MOUSE_BUTTON_MASK_LEFT
	portal_drag.position = portal_screen_position + Vector2(36.0, 24.0)
	demo._input(portal_drag)
	var portal_release := InputEventMouseButton.new()
	portal_release.button_index = MOUSE_BUTTON_LEFT
	portal_release.pressed = false
	portal_release.position = portal_drag.position
	demo._input(portal_release)
	assert(demo._current_dungeon_portal_trigger_position(0).is_equal_approx(initial_portal_position + Vector2(36.0, 24.0)), "拖动传送阵触发点必须立即更新当前地图的触发位置")
	var initial_portal_radius: Vector2 = demo._current_dungeon_portal_trigger_radius(0)
	assert(not is_equal_approx(initial_portal_radius.x, initial_portal_radius.y), "传送阵默认触发范围必须是椭圆而非圆形")
	var portal_horizontal_handle: Vector2 = demo._current_dungeon_portal_trigger_position(0) + Vector2(initial_portal_radius.x, 0.0) - Vector2(demo.camera_x, demo.camera_y)
	var portal_horizontal_press := InputEventMouseButton.new()
	portal_horizontal_press.button_index = MOUSE_BUTTON_LEFT
	portal_horizontal_press.pressed = true
	portal_horizontal_press.position = portal_horizontal_handle
	demo._input(portal_horizontal_press)
	var portal_horizontal_drag := InputEventMouseMotion.new()
	portal_horizontal_drag.button_mask = MOUSE_BUTTON_MASK_LEFT
	portal_horizontal_drag.position = portal_horizontal_handle + Vector2(60.0, 0.0)
	demo._input(portal_horizontal_drag)
	var portal_horizontal_release := InputEventMouseButton.new()
	portal_horizontal_release.button_index = MOUSE_BUTTON_LEFT
	portal_horizontal_release.pressed = false
	portal_horizontal_release.position = portal_horizontal_drag.position
	demo._input(portal_horizontal_release)
	assert(is_equal_approx(demo._current_dungeon_portal_trigger_radius(0).x, initial_portal_radius.x + 60.0), "拖动传送阵右侧手柄必须调整椭圆横向半径")
	var portal_vertical_handle: Vector2 = demo._current_dungeon_portal_trigger_position(0) + Vector2(0.0, initial_portal_radius.y) - Vector2(demo.camera_x, demo.camera_y)
	var portal_vertical_press := InputEventMouseButton.new()
	portal_vertical_press.button_index = MOUSE_BUTTON_LEFT
	portal_vertical_press.pressed = true
	portal_vertical_press.position = portal_vertical_handle
	demo._input(portal_vertical_press)
	var portal_vertical_drag := InputEventMouseMotion.new()
	portal_vertical_drag.button_mask = MOUSE_BUTTON_MASK_LEFT
	portal_vertical_drag.position = portal_vertical_handle + Vector2(0.0, 45.0)
	demo._input(portal_vertical_drag)
	var portal_vertical_release := InputEventMouseButton.new()
	portal_vertical_release.button_index = MOUSE_BUTTON_LEFT
	portal_vertical_release.pressed = false
	portal_vertical_release.position = portal_vertical_drag.position
	demo._input(portal_vertical_release)
	assert(is_equal_approx(demo._current_dungeon_portal_trigger_radius(0).y, initial_portal_radius.y + 45.0), "拖动传送阵下侧手柄必须调整椭圆纵向半径")
	var adjusted_portal_radius: Vector2 = demo._current_dungeon_portal_trigger_radius(0)
	var adjusted_portal_center: Vector2 = demo._current_dungeon_portal_trigger_position(0)
	assert(demo._is_in_current_dungeon_portal_trigger(adjusted_portal_center + Vector2(adjusted_portal_radius.x * 0.9, 0.0), 0), "椭圆范围内的位置必须能触发传送阵")
	assert(not demo._is_in_current_dungeon_portal_trigger(adjusted_portal_center + Vector2(0.0, adjusted_portal_radius.y * 1.1), 0), "椭圆范围外的位置不能触发传送阵")
	var saved_portal_triggers: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(dungeon_store))
	demo.dungeon_area_editor_enabled = false
	assert(saved_portal_triggers.get("portal_trigger_positions", []).size() == 6 and saved_portal_triggers.get("portal_trigger_radii", []).size() == 6 and saved_portal_triggers.get("portal_effect_positions", []).size() == 6 and saved_portal_triggers.get("spawn_rects", []).size() == 6 and saved_portal_triggers.get("altar_tree_positions", []).size() == 6 and saved_portal_triggers.get("portal_trigger_positions_by_foreground", {}).size() == 4 and saved_portal_triggers.get("portal_effect_positions_by_foreground", {}).size() == 4 and saved_portal_triggers.get("altar_tree_positions_by_foreground", {}).size() == 4 and saved_portal_triggers.get("spawn_rects_by_foreground", {}).size() == 4, "传送阵、传送特效、祭坛树位置与出生区域必须同时按四套前景资源保存")
	demo.camera_x = 0.0
	assert(demo._is_in_current_dungeon_altar_trigger(demo._current_dungeon_altar_position()), "祭坛树中心必须位于当前可编辑触发区中")
	for animation_name in ["1", "2", "3", "4"]:
		assert(demo.altar_tree.skeleton_data_res.find_animation(animation_name) != null, "祭坛树必须接入四个原生 Spine 动作")
	assert(is_equal_approx(demo.altar_tree.skeleton_data_res.find_animation("2").get_duration(), demo.ALTAR_TREE_ACTIVATE_DURATION), "激活动作必须使用 Spine 原始时长")
	demo._process(0.01)
	assert(demo.dungeon_altar_tree_state == "activating" and demo.altar_tree.get_animation_state().get_track(0).get_animation().get_name() == "2", "祭坛树进入视野后必须先开始一次激活动作")
	demo._on_altar_tree_animation_finished()
	assert(demo.dungeon_altar_tree_state == "ready" and demo.altar_tree.get_animation_state().get_track(0).get_animation().get_name() == "3", "祭坛树激活动作完成后才能进入可对话循环")
	demo.player = demo._current_dungeon_altar_position()
	demo._interact()
	assert(demo.modal_mode == "altar", "靠近起始区域祭坛树时必须进入一次对话")
	assert(demo.dungeon_altar_tree_state == "ready" and demo.altar_tree.get_animation_state().get_track(0).get_animation().get_name() == "3", "未完成对话时祭坛树必须持续保持动作 3")
	demo.modal_primary_button.emit_signal("pressed")
	assert(demo.dungeon_stage == "portals" and demo.dungeon_altar_tree_state == "talked" and demo.altar_tree.get_animation_state().get_track(0).get_animation().get_name() == "4" and not demo.dungeon_available_targets.is_empty(), "祭坛树对话完成后必须进入动作 4 并开启所有可行路线的传送阵")
	demo._process(0.016)
	for target_id in demo.dungeon_available_targets:
		var portal_index: int = demo._portal_index_for_target(target_id)
		var portal_effect: SpineSprite = demo.dungeon_portal_spine_effects[portal_index]
		var expected_animation: String = demo._dungeon_portal_spine_animation_for_type(str(demo.dungeon_route_nodes[target_id]["type"]))
		assert(portal_effect.visible and portal_effect.get_meta("animation_name", "") == expected_animation, "挑战完成后对应传送阵必须播放目标房间类型的 Spine 动作")
		assert(portal_effect.position.is_equal_approx(demo._current_dungeon_portal_effect_position(portal_index) - Vector2(demo.camera_x, 0.0)), "传送阵 Spine 特效必须以 100% 速度跟随副本前景摄像机")
	var first_target: String = demo.dungeon_available_targets[0]
	demo.player = demo._current_dungeon_portal_trigger_position(demo._portal_index_for_target(first_target))
	demo._interact()
	assert(demo.dungeon_current_node_id == first_target and demo.dungeon_stage == "spawning", "进入有效传送阵后必须立即加载 B 区战斗")
	var first_area_type := str(demo.dungeon_route_nodes[first_target]["type"])
	if first_area_type == "normal":
		assert(demo.monsters.size() >= 10 and demo.monsters.size() <= 20, "普通区域每波必须生成 10 至 20 只普通怪")
	elif first_area_type == "elite":
		assert(demo.monsters.size() >= 15 and demo.monsters.size() <= 20, "精英区域每波必须生成 15 至 20 只怪物")
	else:
		assert(demo.monsters.size() >= 5 and demo.monsters.size() <= 10, "变异区域每波必须生成 5 至 10 只变异怪")
	var protected_hp: int = demo.monsters[0]["hp"]
	demo.player = demo.monsters[0]["pos"] - Vector2(100.0, 0.0)
	demo.facing = 1.0
	demo._on_skill_effect_hit(2001, 246.09375)
	assert(demo.monsters[0]["hp"] == protected_hp, "怪物一秒渐变完成前不能被攻击")
	demo._process(demo.WAVE_FADE_DURATION + 0.01)
	assert(demo.dungeon_stage == "combat" and demo.monsters[0]["active"], "一秒渐变完成后怪物才能移动、攻击和受到伤害")
	demo.monsters[0]["hp"] = 100
	demo.monsters[0]["max_hp"] = 100
	demo.player = Vector2(demo.monsters[0]["pos"]) - Vector2(24.0, 0.0)
	demo.facing = 1.0
	demo.damage_floaters.clear()
	demo._on_skill_effect_hit(2001, 246.09375)
	assert(not demo.damage_floaters.is_empty(), "攻击命中怪物时必须生成伤害飘字")
	assert(int(demo.damage_floaters[0]["damage"]) > 0 and Vector2(demo.damage_floaters[0]["position"]).y < Vector2(demo.monsters[0]["pos"]).y, "伤害飘字必须显示实际伤害并从怪物头顶起飞")
	demo._update_damage_floaters(demo.DAMAGE_FLOATER_DURATION + 0.01)
	assert(demo.damage_floaters.is_empty(), "伤害飘字完成上浮淡出后必须自动清除")
	for target in demo.monsters:
		target.hit = 0.0
		if target.has("damage_reaction"):
			target.damage_reaction.advance(10.0)
			target.damage_reaction.advance_pushback(10.0)
	demo.current_health = 100.0
	demo.monsters[0]["pos"] = demo.player + Vector2(20.0, 0.0)
	demo.monsters[0]["engaged"] = true
	demo.monsters[0]["attack_cooldown"] = 0.0
	var attacker: Dictionary = demo.monsters[0]
	attacker.model_resource = "res://assets/character/art/monsters/101-wind-slime/monster_101-data.tres"
	for key in ["attack1", "attack2"]:
		demo.monster_actions.rows[attacker.character_id][key].animation = {"library": attacker.model_resource, "name": "attack_1"}
		demo.monster_actions.rows[attacker.character_id][key].upper = {"file": "skilleffect_jd_dg1.json", "animation": "attack2"}
		demo.monster_actions.rows[attacker.character_id][key].lower = null
	demo.monster_actions.play(attacker, "idle", true)
	demo._update_monster_ai(0.01)
	assert(demo.current_health == 100.0, "起手不立即扣血，伤害必须等待攻击特效窗口")
	demo.monster_actions.advance(attacker, 0.75)
	assert(demo.current_health < 100.0, "怪物原生动作触发特效窗口后必须造成伤害")
	for monster in demo.monsters:
		monster.attack = 0 # 后续移动测试隔离战斗干扰。
	demo.current_health = 72.0
	demo._refresh_resource_bars()
	assert((demo.get_node("UI/GameHUD/PlayerStatus/HealthValue") as Label).text == "72 / 100", "血量变化后左上角数值必须同步更新")
	demo.current_mana = 43.0
	demo._refresh_resource_bars()

	demo.hurt_remaining = 0.0
	demo.damage_reaction.reset()
	demo._jump()
	assert(demo.is_jumping, "落地状态必须允许开始跳跃")
	assert(is_equal_approx(demo.JUMP_DURATION, 0.6))
	demo._process(demo.JUMP_DURATION * 0.5)
	assert(is_equal_approx(demo.character_height_px, 140.0), "跳跃最高点必须约为 140 像素")
	var jump_elapsed_before_retry: float = demo.jump_elapsed
	demo._jump()
	assert(is_equal_approx(demo.jump_elapsed, jump_elapsed_before_retry), "落地前不能连续起跳或重置跳跃时间")
	demo._process(0.1)
	assert(is_equal_approx(demo.character_height_px, 140.0) and demo.is_jumping, "最高点停留前半段保持高度")
	demo._process(0.1)
	assert(is_equal_approx(demo.character_height_px, 140.0) and demo.is_jumping, "最高点完整停留 0.2 秒")
	demo._process(demo.JUMP_DURATION * 0.5)
	assert(not demo.is_jumping and demo.character_height_px == 0.0, "跳跃结束后必须准确回到地面")

	demo.player = Vector2(500, 610)
	demo.facing = 1.0
	demo._dodge()
	assert(is_equal_approx(demo.DODGE_SPEED, demo.MOVE_SPEED * 1.5), "闪避速度必须是移动速度的 150%")
	demo._jump()
	assert(not demo.is_jumping, "闪避过程中不能跳跃")
	Input.action_press("ui_left")
	Input.action_press("ui_down")
	demo._process(demo.DODGE_DURATION * 0.5)
	var dodge_remaining_before_retry: float = demo.dodge_remaining
	demo._dodge()
	assert(is_equal_approx(demo.dodge_remaining, dodge_remaining_before_retry), "闪避尚未结束时不能连续触发")
	demo._process(demo.DODGE_DURATION * 0.5)
	Input.action_release("ui_left")
	Input.action_release("ui_down")
	assert(is_zero_approx(demo.attack_anim), "闪避结束不得自动执行此前攻击输入")
	assert(is_equal_approx(demo.player.x, 700.0), "闪避必须沿触发时方向移动整整 200 像素")
	assert(demo.facing == 1.0, "闪避过程中必须忽略反方向输入并锁定左右朝向")
	assert(is_equal_approx(demo.DODGE_VERTICAL_SPEED, demo.MOVE_SPEED * 0.2), "闪避期间的纵向速度必须为正常移动速度的 20%")
	assert(is_equal_approx(demo.player.y, 610.0 + demo.DODGE_VERTICAL_SPEED * demo.DODGE_DURATION), "闪避期间必须按 20% 速度纵向移动")

	demo.player = Vector2(914.0625, 645)
	demo.attack_cooldown = 0.0
	demo._attack()
	demo.character_actions.rows[demo.attack_action_id].advanceDistancePx = 0.0
	var x_before_attack_move: float = demo.player.x
	Input.action_press("ui_right")
	demo._process(0.1)
	Input.action_release("ui_right")
	assert(is_equal_approx(demo.player.x, x_before_attack_move), "前移参数为零时攻击期间方向输入不能移动角色")
	demo.player = Vector2(600.0, 645)
	demo.facing = 1.0
	demo.attack_cooldown = 0.0
	demo.hurt_remaining = 0.0
	demo.damage_reaction.reset()
	var remote_attack_hp: int = demo.monsters[0]["hp"]
	demo._attack()
	assert(demo.character_actions.active_id in [2001, 2002, 2003] and demo.traveler.get_animation_state().get_track(0).get_animation().get_name() == demo.character_actions.rows[demo.character_actions.active_id].animation, "远离怪物时也必须可以随时触发攻击动作")
	demo._process(demo.ATTACK_DURATION * 0.55)
	assert(demo.monsters[0]["hp"] == remote_attack_hp, "攻击动作触发后只有范围内怪物才会受到伤害")
	demo.monsters.clear()
	demo._process(0.01)
	assert(demo.dungeon_stage == "wave_delay" and is_equal_approx(demo.dungeon_next_wave_timer, demo.NEXT_WAVE_DELAY), "第一波全灭后必须等待三秒")
	demo._process(demo.NEXT_WAVE_DELAY + 0.01)
	assert(demo.dungeon_wave == 2 and demo.dungeon_stage == "spawning", "等待三秒后必须生成独立随机的第二波")
	demo._process(demo.WAVE_FADE_DURATION + 0.01)
	demo.monsters.clear()
	demo._process(0.01)
	assert(demo.dungeon_stage == "await_altar", "第二波全灭后区域战斗必须立即完成并等待祭坛树对话")
	while demo.dungeon_current_node_id != "2F":
		demo._activate_dungeon_portals()
		var next_target: String = demo.dungeon_available_targets[0]
		demo._enter_dungeon_target(next_target)
		if next_target == "2F":
			assert(demo.dungeon_scene.texture == demo.DUNGEON_SHARED_BACKGROUND and demo.dungeon_foreground.texture == demo.DUNGEON_BOSS_FOREGROUND and demo.dungeon_midground.texture == demo.DUNGEON_BOSS_MIDGROUND and demo.monsters.size() == 1, "2F 必须加载固定首领分层并生成首领")
			assert(demo.dungeon_world_width == 3600.0, "首领房世界宽度必须由 3600 像素前景决定")
		else:
			assert(int(demo.dungeon_route_nodes[next_target]["map"]) >= 2 and int(demo.dungeon_route_nodes[next_target]["map"]) <= 5, "B-E 每个区域必须加载已生成的中间地图")
		demo.monsters.clear()
		demo.dungeon_stage = "await_altar"
	assert(demo.dungeon_chosen_path.size() == 6, "一次完整路线必须依次经过 A、B、C、D、E、F 六列且不能返回或跨列")
	demo.pending_dungeon_experience = 30
	demo.player = demo._current_dungeon_altar_position()
	demo.camera_x = 900.0
	demo._process(0.01)
	assert(demo.dungeon_altar_tree_state == "activating", "首领房祭坛树进入视野时也必须先播放激活动作")
	demo._on_altar_tree_animation_finished()
	demo._interact()
	assert(demo.modal_mode == "boss_altar", "击败首领后必须与首领区域祭坛树对话")
	demo.modal_primary_button.emit_signal("pressed")
	assert(demo.modal_mode == "victory" and demo.modal_title.text == "恭喜通关", "首领祭坛树对话后必须弹出恭喜通关界面")
	demo.modal_primary_button.emit_signal("pressed")
	assert(demo.modal_mode == "settlement" and "击杀经验结算：30" in demo.modal_body.text, "点击通关确定后必须进入统一结算并显示击杀经验")
	demo.modal_primary_button.emit_signal("pressed")
	assert(demo.state == "city", "结算确认后必须返回主城")
	assert(demo.current_health == 100.0 and demo.current_mana == 100.0, "离开副本回到主城时必须自动回满生命与灵蕴")
	assert(demo.player_stats["experience"] == 30, "副本经验必须在结算返回主城时统一发放")

	demo._enter_dungeon()
	demo.dungeon_menu_button.emit_signal("pressed")
	assert(demo.modal_mode == "dungeon_menu" and "退出副本" == demo.modal_primary_button.text, "副本右上菜单必须提供退出副本入口")
	demo.modal_primary_button.emit_signal("pressed")
	assert(demo.modal_mode == "exit_confirm", "退出副本前必须弹出二次确认")
	demo.modal_primary_button.emit_signal("pressed")
	assert(demo.modal_mode == "settlement" and "挑战失败" in demo.modal_body.text, "主动退出必须按照挑战失败进入结算")
	demo.modal_primary_button.emit_signal("pressed")
	assert(demo.state == "city" and demo.player_stats["experience"] == 30, "失败结算不得增加经验，确认后必须回到主城")
	demo._enter_dungeon()
	demo.current_health = 1.0
	demo._damage_player(999)
	assert(demo.dungeon_stage == "dead" and demo.modal_mode == "settlement", "主角生命归零后必须立即进入失败结算且不能继续副本")
	demo.modal_primary_button.emit_signal("pressed")
	assert(demo.state == "city" and demo.current_health == 100.0, "死亡结算确认后必须返回主城并恢复生命")

	var ignored_password := _spawn_demo(store, walkable_store, spawn_store)
	await process_frame
	_login(ignored_password, "测试账号", "任意内容")
	assert(ignored_password.state == "city", "当前阶段密码内容不能影响已有账号登录")
	assert(ignored_password.current_account_id == first_id, "忽略密码后仍必须读取原账号 ID")

	var relog := _spawn_demo(store, walkable_store, spawn_store)
	await process_frame
	_login(relog, "测试账号", "")
	assert(relog.current_account_id == first_id, "同一账号再次登录必须读取原账号 ID")
	assert(relog.role_name == first_role, "已有账号再次登录必须读取原角色名")
	assert(relog.player_stats["experience"] == 30, "重新登录时必须读取副本结算后保存的经验值")

	var second := _spawn_demo(store, walkable_store, spawn_store)
	await process_frame
	_login(second, "第二个账号", "")
	assert(second.current_account_id != first_id and second.state == "naming", "新账号必须使用不同内部 ID 并先进入命名界面")
	_set_role_name(second, first_role)
	second._confirm_role_name()
	assert(second.naming_warning.text == "已有相同名字" and second.state == "naming", "不同账号不能使用已存在的角色名")
	_set_role_name(second, "第二勇者")
	second._confirm_role_name()
	assert(second.state == "city" and second.role_name == "第二勇者", "非重复名字必须可以完成创角")

	var pending := _spawn_demo(store, walkable_store, spawn_store)
	await process_frame
	_login(pending, "待命名账号", "")
	var pending_id: String = pending.current_account_id
	assert(pending.state == "naming" and pending.role_name.is_empty(), "新账号在未确认名字时必须保持待命名状态")
	var resumed_pending := _spawn_demo(store, walkable_store, spawn_store)
	await process_frame
	_login(resumed_pending, "待命名账号", "")
	assert(resumed_pending.state == "naming" and resumed_pending.current_account_id == pending_id, "未完成命名的账号下次登录时必须继续命名")

	for path in test_files:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("DEMO_SELF_TEST_OK")
	quit()
