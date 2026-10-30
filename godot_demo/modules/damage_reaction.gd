extends RefCounted

const KNOCKBACK_DISTANCE := 200.0
const KNOCKBACK_DURATION := 0.55
const KNOCKBACK_HEIGHT := 80.0
const PUSHBACK_DURATION := 0.12
var pushback_elapsed := 0.0
var pushback_distance := 0.0
var pushback_direction := 0.0
var clock := 0.0
var hits: Array = []
var down_remaining := 0.0
var recovery_invulnerable_remaining := 0.0
var knockback_elapsed := 0.0
var knockback_remaining := 0.0
var knockback_direction := 0.0
var down_kind := "standing"

func advance(delta: float) -> void:
	clock += maxf(delta, 0.0)
	recovery_invulnerable_remaining = maxf(0.0, recovery_invulnerable_remaining - maxf(delta, 0.0))
	down_remaining = maxf(0.0, down_remaining - delta)
	_prune()

func _prune() -> void:
	while not hits.is_empty() and clock - float(hits[0].time) >= 5.0:
		hits.pop_front()

func begin_knockback(direction: float, landing_duration: float = 0.0) -> void:
	pushback_distance = 0.0
	down_kind = "launched"
	knockback_direction = signf(direction)
	knockback_elapsed = 0.0
	knockback_remaining = KNOCKBACK_DURATION
	down_remaining = maxf(down_remaining, KNOCKBACK_DURATION + maxf(landing_duration, 0.0))

func begin_pushback(direction: float, distance: float) -> void:
	# Repeated hits start a fresh shove; airborne motion keeps its own trajectory.
	if knockback_remaining > 0.0:
		return
	pushback_elapsed = 0.0
	pushback_distance = maxf(distance, 0.0)
	pushback_direction = signf(direction)

func advance_pushback(delta: float) -> float:
	var before := pushback_elapsed
	pushback_elapsed = minf(PUSHBACK_DURATION, before + maxf(delta, 0.0))
	return pushback_direction * pushback_distance * (pushback_elapsed - before) / PUSHBACK_DURATION

func is_pushed() -> bool:
	return pushback_distance > 0.0 and pushback_elapsed < PUSHBACK_DURATION

func knockdown_action() -> String:
	if knockback_remaining > 0.0:
		return "floated"
	return "down_fly" if down_kind == "launched" else "down"

func advance_knockback(delta: float) -> Dictionary:
	if knockback_remaining <= 0.0:
		return {"offset_x": 0.0, "height": 0.0}
	var before := clampf(knockback_elapsed / KNOCKBACK_DURATION, 0.0, 1.0)
	knockback_elapsed = minf(KNOCKBACK_DURATION, knockback_elapsed + maxf(delta, 0.0))
	var after := clampf(knockback_elapsed / KNOCKBACK_DURATION, 0.0, 1.0)
	var distance_before := KNOCKBACK_DISTANCE * (1.0 - pow(1.0 - before, 1.5))
	var distance_after := KNOCKBACK_DISTANCE * (1.0 - pow(1.0 - after, 1.5))
	knockback_remaining = maxf(0.0, KNOCKBACK_DURATION - knockback_elapsed)
	var height := KNOCKBACK_HEIGHT * 4.0 * after * (1.0 - after)
	return {"offset_x": knockback_direction * (distance_after - distance_before), "height": height}

func receive(damage: float, max_health: float, down_duration: float) -> bool:
	_prune()
	if damage <= 0.0 or is_invulnerable():
		return false
	hits.append({"time": clock, "damage": damage})
	var total := 0.0
	for hit in hits:
		total += float(hit.damage)
	if total > max_health * 0.3:
		down_kind = "standing"
		down_remaining = maxf(down_duration, 0.01)
		hits.clear()
		return true
	return false

func reset() -> void:
	pushback_elapsed = 0.0
	pushback_distance = 0.0
	pushback_direction = 0.0
	hits.clear()
	down_remaining = 0.0
	recovery_invulnerable_remaining = 0.0
	knockback_elapsed = 0.0
	knockback_remaining = 0.0
	knockback_direction = 0.0
	down_kind = "standing"
	clock = 0.0

func is_invulnerable() -> bool:
	return down_remaining > 0.0 or recovery_invulnerable_remaining > 0.0

func finish_getup() -> void:
	down_kind = "standing"
	recovery_invulnerable_remaining = 2.0
