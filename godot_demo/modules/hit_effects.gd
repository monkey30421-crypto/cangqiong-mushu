extends Node2D

const DATA = preload("res://assets/scene/effects/hit_common/hitEff_common-data.tres")
const ANIMATION := &"hitEff_common"
const SceneDepth = preload("res://modules/scene_depth.gd")
var effects: Array[Dictionary] = []

func _init() -> void:
	name = "HitEffects"
	SceneDepth.set_layer(self, SceneDepth.HIT_EFFECT_Z)

# Attack clips use the same native pixel geometry for rendering and contact placement.
static func effect_area(clip: Dictionary, direction: float) -> Rect2:
	var bounds: Array = clip.get("bounds", [])
	if bounds.size() != 2:
		return Rect2()
	var size := Vector2(float(bounds[0]), float(bounds[1]))
	var center := Vector2(0.0, -size.y * 0.25)
	return Rect2(center - size * 0.5, size)

static func contact_point(attacker_origin: Vector2, target_origin: Vector2, body_x: float, body_h: float, attack_area: Rect2 = Rect2()) -> Vector2:
	var body := Rect2(target_origin - Vector2(body_x * 0.5, body_h), Vector2(body_x, body_h))
	var incoming_left := attacker_origin.x <= target_origin.x
	var fallback_x := body.position.x if incoming_left else body.end.x
	if not attack_area.has_area():
		return Vector2(fallback_x, body.get_center().y)
	var visual := Rect2(attacker_origin + attack_area.position, attack_area.size)
	var overlap := body.intersection(visual)
	if overlap.has_area():
		return overlap.get_center()
	# Damage uses configured ranges, which may extend past the visual. Keep the burst
	# on the target's incoming surface, nearest the attack artwork's height.
	return Vector2(fallback_x, clampf(visual.get_center().y, body.position.y, body.end.y))

func play_at(point: Vector2, target_origin: Vector2, follow: Callable = Callable()) -> void:
	var animation = DATA.find_animation(ANIMATION)
	if animation == null:
		return
	var sprite := SpineSprite.new()
	sprite.skeleton_data_res = DATA
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.position = point
	add_child(sprite)
	sprite.get_animation_state().set_animation(ANIMATION, false, 0)
	effects.append({"sprite": sprite, "position": point, "offset": point - target_origin, "follow": follow, "elapsed": 0.0, "duration": maxf(float(animation.get_duration()), 1.0 / 30.0)})

func advance(delta: float, camera: Vector2 = Vector2.ZERO) -> void:
	position = -camera
	for effect in effects.duplicate():
		effect.elapsed += maxf(0.0, delta)
		if float(effect.elapsed) >= float(effect.duration):
			effect.sprite.hide()
			effect.sprite.queue_free()
			effects.erase(effect)
			continue
		if effect.follow.is_valid():
			var origin = effect.follow.call()
			if origin is Vector2:
				effect.position = origin + Vector2(effect.offset)
		effect.sprite.position = effect.position

func clear() -> void:
	for effect in effects:
		effect.sprite.hide()
		effect.sprite.queue_free()
	effects.clear()
