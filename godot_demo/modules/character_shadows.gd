extends Node2D

const SHADOW_TEXTURE: Texture2D = preload("res://assets/character/art/common_shadow.png")
var characters: Array[Dictionary] = []
var camera_offset := Vector2.ZERO

func _init() -> void:
	name = "CharacterShadows"
	# Above scene art (-8), below actors (0) and their lower VFX (-1).
	z_index = -2
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	visible = false

static func height_scale(height_px: float, body_height: float) -> float:
	var relative_height := clampf(height_px / maxf(body_height, 0.001), 0.0, 2.0)
	if relative_height <= 1.0:
		return lerpf(1.0, 0.4, relative_height)
	return lerpf(0.4, 0.0, relative_height - 1.0)

func update_characters(values: Array[Dictionary], camera: Vector2) -> void:
	characters = values
	camera_offset = camera
	visible = not characters.is_empty()
	queue_redraw()

func shadow_rect(character: Dictionary) -> Rect2:
	var factor := height_scale(float(character.get("height", 0.0)), float(character.body_h))
	var configured_scale := maxf(0.0, float(character.get("shadow_scale_percent", 100.0))) / 100.0
	var size := SHADOW_TEXTURE.get_size() * configured_scale * factor
	# Ground position never contains jump height, visual bob, rotation or facing.
	return Rect2(Vector2(character.ground_position) - camera_offset - size * 0.5, size)

func _draw() -> void:
	for character in characters:
		var rect := shadow_rect(character)
		if rect.size.x <= 0.0:
			continue
		draw_texture_rect(SHADOW_TEXTURE, rect, false, Color(1.0, 1.0, 1.0, clampf(float(character.get("alpha", 1.0)), 0.0, 1.0)))
