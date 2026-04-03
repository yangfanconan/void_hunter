## Void Hunter - 雷霆战锤武器
## @description: 闪电伤害武器，有几率触发连锁闪电
## @version: 1.0.0

extends "res://src/items/item_base.gd"

func _ready() -> void:
	item_id = "weapon_thunder_hammer"
	item_name = "雷霆战锤"
	description = "蕴含雷霆之力的战锤，攻击有几率触发连锁闪电"
	item_type = ItemType.EQUIPMENT
	rarity = ItemRarity.EPIC
	equip_slot = EquipSlot.WEAPON

	stat_bonuses = {
		"attack": 30.0,
		"attack_speed": -0.1,  # 攻击速度稍慢
	}
	sell_price = 160
	buy_price = 420

	super._ready()

func _on_equip(target: Node) -> void:
	# 添加连锁闪电效果
	if target.has_method("add_on_hit_effect"):
		target.add_on_hit_effect("chain_lightning", 0.25, 2)