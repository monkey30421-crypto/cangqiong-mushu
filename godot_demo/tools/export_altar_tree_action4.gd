extends SceneTree

# Rebuilds the map editor preview from the same packed frame used by the
# game's action 4.  Run with Godot headless from the project directory.
func _initialize() -> void:
	call_deferred("_export")


func _export() -> void:
	var source_texture := load("res://assets/scene/effects/altar_tree/jitanshu_m.png") as Texture2D
	var atlas_lines := FileAccess.get_file_as_string("res://assets/scene/effects/altar_tree/jitanshu_m.atlas").split("\n")
	var frame_index := 0
	var frame_image: Image
	for line_index in range(atlas_lines.size()):
		var name_line := atlas_lines[line_index].strip_edges()
		if not name_line.begins_with("jitanshu/") or line_index + 6 >= atlas_lines.size():
			continue
		frame_index += 1
		if frame_index != 52:
			continue
		var rotated := atlas_lines[line_index + 1].get_slice(":", 1).strip_edges() == "true"
		var atlas_position := _atlas_pair(atlas_lines[line_index + 2])
		var packed_size := _atlas_pair(atlas_lines[line_index + 3])
		var original_size := _atlas_pair(atlas_lines[line_index + 4])
		var offset := _atlas_pair(atlas_lines[line_index + 5])
		frame_image = source_texture.get_image().get_region(Rect2i(atlas_position, packed_size))
		if rotated:
			frame_image.rotate_90(ClockDirection.CLOCKWISE)
		var canvas := Image.create_empty(original_size.x, original_size.y, false, Image.FORMAT_RGBA8)
		var destination := Vector2i(offset.x, original_size.y - offset.y - frame_image.get_height())
		canvas.blit_rect(frame_image, Rect2i(Vector2i.ZERO, frame_image.get_size()), destination)
		frame_image = canvas
		break
	if frame_image == null:
		push_error("祭坛树图集没有动作 4 所需的第 52 帧。")
		quit(1)
		return
	var output_path := ProjectSettings.globalize_path("res://../map_editor/public/sprites/altar-tree-action4.png")
	DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	var result := frame_image.save_png(output_path)
	if result != OK:
		push_error("无法导出祭坛树动作 4 预览图。")
		quit(1)
		return
	print("ALTAR_TREE_ACTION4_EXPORTED")
	quit()


func _atlas_pair(line: String) -> Vector2i:
	var raw := line.get_slice(":", 1).strip_edges().split(",")
	if raw.size() < 2:
		return Vector2i(-1, -1)
	return Vector2i(int(raw[0].strip_edges()), int(raw[1].strip_edges()))
