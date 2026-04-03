## Void Hunter - 狂暴药剂
## @description: 使用后大幅提升攻击和速度
## @version: 1.0.0

extends "res://src/items/item_base.gd"

func _ready() -> void:
	item_id = "consumable_berserk_potion"
	item_name = "狂暴药剂"
	description = "使用后攻击+50%，速度+30%，持续10秒"
	item_type = ItemType.CONSUMABLE
	rarity = ItemRarity.RARE
	max_stack = 5
	current_stack = 1
	effect_duration = 10.0
	is_temporary = true

	stat_bonuses = {
		"attack": 0.5,  # +50%
		"speed": 0.3,   # +30%
	}
	sell_price = 50
	buy_price = 150

	super._ready()