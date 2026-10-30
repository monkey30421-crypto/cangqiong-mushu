extends SceneTree

const SpineAtlasFramesScript = preload("res://modules/spine_atlas_frames.gd")
const SourceAtlas: Texture2D = preload("res://assets/scene/effects/altar_tree/jitanshu_m.png")
const LockedSheet: Texture2D = preload("res://assets/scene/effects/altar_tree/altar-tree-locked.png")
const ActivateSheet: Texture2D = preload("res://assets/scene/effects/altar_tree/altar-tree-activate.png")
const ReadySheet: Texture2D = preload("res://assets/scene/effects/altar_tree/altar-tree-ready.png")
const TalkedSheet: Texture2D = preload("res://assets/scene/effects/altar_tree/altar-tree-talked.png")
const Cell := Vector2i(384, 307)


func _sheet_frame(sheet: Texture2D, index: int, columns: int) -> Image:
	return sheet.get_image().get_region(Rect2i(Vector2i(index % columns * Cell.x, index / columns * Cell.y), Cell))


func _initialize() -> void:
	var metadata: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/scene/effects/altar_tree/animations.json"))
	assert(metadata is Dictionary, "祭坛树动画元数据必须可读取")
	assert(metadata.supplementary_attachments == ["2", "qp"], "祭坛树必须合成光效 2 与气泡 qp 两组附加图")
	assert(metadata.animations.activate.frames == 52 and metadata.animations.ready.frames == 41, "动画 2 和动画 3 必须使用完整源时间轴")
	assert(LockedSheet.get_size() == Vector2(Cell) and TalkedSheet.get_size() == Vector2(Cell), "静态动作必须使用单帧原始画布")
	assert(ActivateSheet.get_size() == Vector2(3072, 2149), "动画 2 图集必须包含完整 52 帧")
	assert(ReadySheet.get_size() == Vector2(3072, 1842), "动画 3 图集必须包含完整 41 帧")
	var source_frames := SpineAtlasFramesScript.load_frame_textures(SourceAtlas, "res://assets/scene/effects/altar_tree/jitanshu_m.atlas", "jitanshu/")
	assert(_sheet_frame(ActivateSheet, 40, 8).get_data() != source_frames[40].get_image().get_data(), "动画 2 后段必须合成附加图，而非只播放树主体")
	assert(_sheet_frame(ReadySheet, 0, 8).get_data() != source_frames[51].get_image().get_data(), "动画 3 必须合成附加图，而非只显示第 52 帧树主体")
	assert(_sheet_frame(ReadySheet, 0, 8).get_data() != _sheet_frame(ReadySheet, 20, 8).get_data(), "动画 3 的附加图必须按骨骼时间轴持续运动")
	print("ALTAR_TREE_ANIMATIONS_TEST_OK")
	quit()
