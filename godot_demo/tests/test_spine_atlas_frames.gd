extends SceneTree

const SpineAtlasFramesScript = preload("res://modules/spine_atlas_frames.gd")
const AltarTreeAtlas: Texture2D = preload("res://assets/scene/effects/altar_tree/jitanshu_m.png")
const AltarTreeAtlasPath := "res://assets/scene/effects/altar_tree/jitanshu_m.atlas"


func _initialize() -> void:
	assert(SpineAtlasFramesScript.packed_extent_for_region(Vector2i(83, 139), true) == Vector2i(139, 83), "旋转打包区域必须交换裁剪宽高")
	assert(SpineAtlasFramesScript.packed_extent_for_region(Vector2i(83, 139), false) == Vector2i(83, 139), "未旋转区域必须保持原裁剪尺寸")
	var frames: Array[Texture2D] = SpineAtlasFramesScript.load_frame_textures(AltarTreeAtlas, AltarTreeAtlasPath, "jitanshu/")
	assert(frames.size() == 52, "祭坛树必须按图集顺序读取完整的 52 帧")
	for frame in frames:
		assert(frame.get_size() == Vector2(384, 307), "祭坛树每帧必须恢复为 Spine 原始画布尺寸")
	print("SPINE_ATLAS_FRAMES_TEST_OK")
	quit()
