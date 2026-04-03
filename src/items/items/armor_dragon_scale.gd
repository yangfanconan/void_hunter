## Void Hunter - 龙鳞甲
## @description: 高防御护甲，提供火焰抗性
## @version: 1.0.0

extends "res://src/items/item_base.gd"

func _ready() -> void:
	item_id = "armor_dragon_scale"
	item_name = "龙鳞甲"
	description = "由龙鳞锻造的护甲，提供极高的防御和火焰抗性"
	item_type = ItemType.EQUIPMENT
	rarity = ItemRarity.LEGENDARY
	equip_slot = EquipSlot.ARMOR

	stat_bonuses = {
		"defense": 40.0,
		"max_health": 50.0,
		"fire_resistance": 0.5,  # 50%火焰抗性
	}
	sell_price = 300
	buy_price = 800

	super._ready()