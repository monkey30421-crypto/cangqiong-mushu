extends RefCounted

const MAX_HEALTH := 20

func create(factory: Callable, position: Vector2) -> Dictionary:
	var monster: Dictionary = factory.call(0, position, "测试怪物", 0.0, 0)
	monster.city_training = true
	monster.training_origin = position
	monster.hp = MAX_HEALTH
	monster.max_hp = MAX_HEALTH
	monster.active = true
	monster.spawn_alpha = 1.0
	monster.engaged = false
	monster.moving = false
	monster.move_speed = 0.0
	monster.attack = 0
	monster.drops = []
	return monster

static func is_target(monster: Dictionary) -> bool:
	return bool(monster.get("city_training", false))

static func restore_health(monster: Dictionary) -> bool:
	if not is_target(monster):
		return false
	monster.hp = MAX_HEALTH
	monster.max_hp = MAX_HEALTH
	return true

func advance(delta: float, monsters: Array, actions: RefCounted, clamp_position: Callable) -> void:
	for monster in monsters:
		if not is_target(monster):
			continue
		restore_health(monster)
		monster.moving = false
		monster.engaged = false
		actions.advance_reaction(monster, delta, clamp_position)
