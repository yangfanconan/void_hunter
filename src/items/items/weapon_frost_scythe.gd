## Void Hunter - 霜镰武器
## @description: 冰霜伤害武器，有几率冻结敌人
## @version: 1.0.0

extends "res://src/items/item_base.gd"

func _ready() -> void:
	item_id = "weapon_frost_scythe"
	item_name = "霜镰"
	description = "散发寒气的镰刀，攻击时有几率冻结敌人"
	item_type = ItemType.EQUIPMENT
	rarity = ItemRarity.EPIC
	equip_slot = EquipSlot.WEAPON

	stat_bonuses = {
		"attack": 22.0,
		"attack_range": 20.0,
	}
	sell_price = 140
	buy_price = 380

	super._ready()

func _on_equip(target: Node) -> void:
	# 添加冰冻效果
	if target.has_method("add_on_hit_effect"):
		target.add_on_hit_effect("freeze", 0.15, 1.5)