## Void Hunter - 混沌宝珠
## @description: 随机增强效果
## @version: 1.0.0

extends "res://src/items/item_base.gd"

func _ready() -> void:
	item_id = "special_chaos_orb"
	item_name = "混沌宝珠"
	description = "蕴含混沌之力的宝珠，提供随机强力增益"
	item_type = ItemType.EQUIPMENT
	rarity = ItemRarity.LEGENDARY
	equip_slot = EquipSlot.ACCESSORY

	# 随机属性在拾取时确定
	sell_price = 350
	buy_price = 1000

	super._ready()

func _on_pickup(picker: Node) -> void:
	# 随机选择2-3个增益
	var possible_bonuses := [
		{"attack": randf_range(15.0, 30.0)},
		{"defense": randf_range(15.0, 30.0)},
		{"critical_chance": randf_range(0.1, 0.25)},
		{"critical_damage": randf_range(0.2, 0.5)},
		{"life_steal": randf_range(0.05, 0.15)},
		{"speed": randf_range(15.0, 30.0)},
		{"exp_bonus": randf_range(0.2, 0.4)},
	]

	var num_bonuses: int = randi_range(2, 3)
	for i in range(num_bonuses):
		if possible_bonuses.is_empty():
			break
		var idx: int = randi() % possible_bonuses.size()
		var bonus: Dictionary = possible_bonuses.pop_at(idx)
		for key in bonus.keys():
			stat_bonuses[key] = bonus[key]

	description = "混沌宝珠，提供了神秘的增益效果"