## Void Hunter - 冰霜精华
## @description: 冰霜属性的强化材料
## @version: 1.0.0

extends "res://src/items/item_base.gd"

func _ready() -> void:
	item_id = "material_essence_ice"
	item_name = "冰霜精华"
	description = "蕴含冰霜之力的精华，可用于强化冰属性装备"
	item_type = ItemType.MATERIAL
	rarity = ItemRarity.RARE
	max_stack = 20
	current_stack = 1

	sell_price = 25
	buy_price = 0  # 无法购买

	super._ready()