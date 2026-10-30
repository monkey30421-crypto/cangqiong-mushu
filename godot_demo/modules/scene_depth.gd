extends Node2D

# Background artwork remains below these world layers. HUD uses its own CanvasLayer.
const LOWER_EFFECT_Z := -1
const UPPER_EFFECT_Z := 4000
const HIT_EFFECT_Z := 4001
const FLOATING_TEXT_Z := 4002
var lower_effects := Node2D.new()
var upper_effects := Node2D.new()
var floating_text := Node2D.new()

func _init() -> void:
	name = "SceneDepth"
	lower_effects.name = "LowerEffects"
	upper_effects.name = "UpperEffects"
	floating_text.name = "FloatingText"
	set_layer(lower_effects, LOWER_EFFECT_Z)
	set_layer(upper_effects, UPPER_EFFECT_Z)
	set_layer(floating_text, FLOATING_TEXT_Z)
	add_child(lower_effects)
	add_child(upper_effects)
	add_child(floating_text)

static func set_layer(item: CanvasItem, layer: int) -> void:
	item.z_as_relative = false
	item.z_index = layer

func sort_entities(entries: Array[Dictionary]) -> void:
	# Rank actual ground coordinates instead of rounding Y into coarse Z bands.
	entries.sort_custom(func(a, b):
		if float(a.y) == float(b.y):
			return a.node.get_instance_id() < b.node.get_instance_id()
		return float(a.y) < float(b.y))
	assert(entries.size() <= UPPER_EFFECT_Z, "Too many individual render layers")
	for index in range(entries.size()):
		set_layer(entries[index].node, index)
	lower_effects.queue_redraw()
	upper_effects.queue_redraw()
	floating_text.queue_redraw()
