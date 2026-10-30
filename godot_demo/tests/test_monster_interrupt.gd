extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	await process_frame
	game.state = "dungeon"
	game.dungeon_stage = "combat"
	game.modal.hide()
	game.player = Vector2(1200, 650)
	game.facing = 1.0
	var monster: Dictionary = game._monster_definition(0, game.player + Vector2(20, 0), "打断测试", 0, 1)
	monster.active = true
	monster.engaged = true
	monster.hp = 10000
	monster.max_hp = 10000
	monster.attack_cooldown = 0.0
	game.monsters.clear()
	game.monsters.append(monster)
	game._apply_attack_damage(100, 100, 100)
	assert(monster.hit > 0.0 and monster.attack_cooldown > 0.0, "Hit must discard attack readiness immediately")
	var position: Vector2 = monster.pos
	var hp: float = game.current_health
	game._update_monster_ai(0.1)
	assert(monster.pos == position and game.current_health == hp, "Hurt monster cannot move or deal damage")
	monster.hit = 0.0
	game._update_monster_ai(0.01)
	assert(game.current_health == hp, "Interrupted attack cannot resume immediately after hurt")
	monster.attack_cooldown = 0.001
	game._apply_attack_damage(100, 100, 100)
	assert(monster.attack_cooldown > 0.1, "Repeated hits cancel attack preparation again")
	monster.damage_reaction.receive(4000, 10000, 1.0)
	monster.hit = 0.0
	game._update_monster_ai(1.0)
	assert(monster.pos == position and game.current_health == hp, "Knockdown blocks all monster actions")
	game.queue_free()
	await process_frame
	print("MONSTER_INTERRUPT_TEST_OK")
	quit()
