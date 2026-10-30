extends RefCounted


static func packed_extent_for_region(unrotated_size: Vector2i, rotated: bool) -> Vector2i:
	return Vector2i(unrotated_size.y, unrotated_size.x) if rotated else unrotated_size


static func load_frame_textures(source_texture: Texture2D, atlas_path: String, region_prefix: String) -> Array[Texture2D]:
	var source_image := source_texture.get_image()
	var atlas_lines := FileAccess.get_file_as_string(atlas_path).split("\n")
	var frames: Array[Texture2D] = []
	for line_index in range(atlas_lines.size()):
		var name_line := atlas_lines[line_index].strip_edges()
		if not name_line.begins_with(region_prefix) or line_index + 6 >= atlas_lines.size():
			continue
		var rotated := atlas_lines[line_index + 1].get_slice(":", 1).strip_edges() == "true"
		var atlas_position := _atlas_pair(atlas_lines[line_index + 2])
		var unrotated_size := _atlas_pair(atlas_lines[line_index + 3])
		var original_size := _atlas_pair(atlas_lines[line_index + 4])
		var offset := _atlas_pair(atlas_lines[line_index + 5])
		var packed_extent := packed_extent_for_region(unrotated_size, rotated)
		if atlas_position.x < 0 or packed_extent.x <= 0 or packed_extent.y <= 0 or original_size.x <= 0 or original_size.y <= 0:
			continue
		var frame_image := source_image.get_region(Rect2i(atlas_position, packed_extent))
		if rotated:
			# Spine stores this atlas's rotated regions counter-clockwise.
			frame_image.rotate_90(ClockDirection.CLOCKWISE)
		var canvas := Image.create_empty(original_size.x, original_size.y, false, Image.FORMAT_RGBA8)
		var destination := Vector2i(offset.x, original_size.y - offset.y - frame_image.get_height())
		canvas.blit_rect(frame_image, Rect2i(Vector2i.ZERO, frame_image.get_size()), destination)
		frames.append(ImageTexture.create_from_image(canvas))
	return frames


static func _atlas_pair(line: String) -> Vector2i:
	var raw := line.get_slice(":", 1).strip_edges().split(",")
	if raw.size() < 2:
		return Vector2i(-1, -1)
	return Vector2i(int(raw[0].strip_edges()), int(raw[1].strip_edges()))
