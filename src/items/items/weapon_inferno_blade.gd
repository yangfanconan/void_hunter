## Void Hunter - 炎刃武器
## @description: 火焰伤害武器，有几率点燃敌人
## @version: 1.0.0

extends "res://src/items/item_base.gd"

func _ready() -> void:
	item_id = "weapon_inferno_blade"
	item_name = "炎刃"
	description = "注入火焰之力的刀刃，攻击时有几率点燃敌人"
	item_type = ItemType.EQUIPMENT
	rarity = ItemRarity.EPIC
	equip_slot = EquipSlot.WEAPON

	stat_bonuses = {
		"attack": 25.0,
		"critical_chance": 0.08,
	}
	sell_price = 150
	buy_price = 400

	super._ready()

func _on_equip(target: Node) -> void:
	# 添加火焰伤害效果
	if target.has_method("add_on_hit_effect"):
		target.add_on_hit_effect("burn", 0.2, 3.0)  # 20%几率点燃3秒