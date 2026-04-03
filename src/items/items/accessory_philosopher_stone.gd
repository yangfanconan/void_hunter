## Void Hunter - 贤者之石
## @description: 传说中的炼金术至宝
## @version": 1.0.0

extends "res://src/items/item_base.gd"

func _ready() -> void:
	item_id = "accessory_philosopher_stone"
	item_name = "贤者之石"
	description = "传说中的炼金术至宝，大幅提升所有属性"
	item_type = ItemType.EQUIPMENT
	rarity = ItemRarity.LEGENDARY
	equip_slot = EquipSlot.ACCESSORY

	stat_bonuses = {
		"attack": 15.0,
		"defense": 15.0,
		"max_health": 30.0,
		"max_mana": 30.0,
		"critical_chance": 0.1,
		"exp_bonus": 0.25,
		"gold_bonus": 0.25,
	}
	sell_price = 500
	buy_price = 1500

	super._ready()