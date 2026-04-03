## Void Hunter - 虚空披风
## @description: 神秘的虚空披风，提供闪避和暗影抗性
## @version: 1.0.0

extends "res://src/items/item_base.gd"

func _ready() -> void:
	item_id = "armor_void_cloak"
	item_name = "虚空披风"
	description = "来自虚空的神秘披风，穿戴者如同融入黑暗"
	item_type = ItemType.EQUIPMENT
	rarity = ItemRarity.LEGENDARY
	equip_slot = EquipSlot.ARMOR

	stat_bonuses = {
		"dodge_chance": 0.15,  # 15%闪避
		"shadow_resistance": 0.4,
		"speed": 10.0,
	}
	sell_price = 280
	buy_price = 750

	super._ready()