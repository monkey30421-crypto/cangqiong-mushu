extends SceneTree
const InventoryScript = preload("res://modules/inventory_service.gd")

func _initialize() -> void:
	var bag = InventoryScript.new()
	bag.configure()
	assert(bag.capacity == 50)
	bag.capacity = 3
	bag.catalog = {
		"potion": {"name": "药物", "category": "general", "type": "consumable", "usable": true},
		"quest": {"category": "quest", "type": "quest"},
		"sword": {"category": "equipment", "type": "equipment", "equipment_slot": "hand", "slot_count": 2, "stats": {"attack": 5}},
		"chest": {"category": "general", "type": "chest"},
		"skill": {"category": "skill", "type": "skill"}}
	assert(bag.add_item("potion", 1000))
	assert(bag.slots[0].count == 999 and bag.slots[1].count == 1)
	assert(bag.add_item("potion", 1, {"binding": "role", "quality": 6}))
	assert(bag.slots.size() == 2 and bag.slots[1].count == 2 and bag.slots[1].quality == 1)
	assert(bag.add_item("sword", 1))
	var uid: String = bag.slots[2].uid
	var before: Dictionary = bag.snapshot()
	assert(not bag.add_item("quest", 1) and before == bag.snapshot())
	assert(bag.equip_item(uid))
	assert(bag.equipped.has("hand_1") and bag.stat_bonus("attack") == 5)
	assert(bag.add_item("sword", 1))
	assert(bag.slots[2].position == 2)
	assert(bag.equip_item(bag.slots[2].uid))
	assert(bag.find_slot(uid).position == 2)
	assert(not bag.equip_item(uid, true))
	assert(bag.discard_item(uid, 1))
	assert(bag.remove_item(bag.slots[0].uid, 999))
	assert(bag.slots[0].position == 1)
	assert(bag.add_item("quest", 999))
	assert(bag.slots[1].position == 0)
	assert(not bag.discard_item(bag.slots[1].uid, 1))
	assert(bag.add_item("potion", 3, {"temporary": true}))
	var saved: Dictionary = bag.snapshot()
	bag.settle_dungeon()
	assert(bag.slots[0].count == 2)
	bag.restore(saved)
	assert(bag.slots[0].count == 2 and bag.slots[0].position == 1)
	assert(bag.stat_bonus("attack") == 5)
	assert(not bag.use_consumable(bag.slots[0].uid, true, func(_d): return true))
	assert(not bag.use_consumable(bag.slots[0].uid, false, func(_d): return false))
	assert(bag.use_consumable(bag.slots[0].uid, false, func(_d): return true))
	assert(bag.slots[0].count == 1)
	bag.capacity = 50
	assert(bag.add_item("chest", 1))
	assert(bag.add_item("skill", 2))
	assert(bag.list_items("skill").size() == 2)
	bag.organize()
	assert(bag.slots[0].item_id == "chest")
	assert(bag.slots[1].item_id == "potion")
	assert(bag.slots[-1].item_id == "quest")
	for i in range(bag.slots.size()): assert(bag.slots[i].position == i)
	var accounts = preload("res://modules/account_service.gd").new()
	assert(accounts.normalize_account_record({"inventory": bag.snapshot()}, "test", {}).inventory == bag.snapshot())
	bag.catalog["amber"] = {"name": "树珀", "type": "currency", "category": "currency"}
	var previous: int = bag.slots.size()
	assert(not bag.add_item("amber", 100) and bag.slots.size() == previous, "Currency cannot enter bag slots")
	# Existing save entries or definitions changed to currency must remain hidden.
	bag.slots.append({"item_id": "amber", "count": 10})
	assert(bag.list_items("all").size() == previous)
	assert(bag.list_items("currency").is_empty())
	bag.slots.pop_back()
	assert(bag.collect_item("amber", 100))
	assert(bag.currencies.amber == 100 and bag.slots.size() == previous)
	var with_currency: Dictionary = bag.snapshot()
	bag.restore({})
	assert(bag.currencies.is_empty(), "Account switches clear currency balances")
	bag.restore(with_currency)
	assert(bag.currencies.amber == 100, "Currency pickups survive save/load")
	print("INVENTORY_TEST_OK")
	quit()
