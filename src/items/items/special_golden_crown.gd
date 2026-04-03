## Void Hunter - 黄金皇冠
## @description: 大幅提升金币获取
## @version: 1.0.0

extends "res://src/items/item_base.gd"

func _ready() -> void:
	item_id = "special_golden_crown"
	item_name = "黄金皇冠"
	description = "王者之冠，大幅提升金币获取"
	item_type = ItemType.EQUIPMENT
	rarity = ItemRarity.RARE
	equip_slot = EquipSlot.ACCESSORY

	stat_bonuses = {
		"gold_bonus": 0.5,  # +50%金币
		"max_health": 20.0,
	}
	sell_price = 200
	buy_price = 500

	super._ready()