## Void Hunter - 时间回溯饰品
## @description: 死亡时有几率复活
## @version: 1.0.0

extends "res://src/items/item_base.gd"

func _ready() -> void:
	item_id = "accessory_time_loop"
	item_name = "时间回溯"
	description = "死亡时有30%几率以25%生命值复活"
	item_type = ItemType.EQUIPMENT
	rarity = ItemRarity.LEGENDARY
	equip_slot = EquipSlot.ACCESSORY

	stat_bonuses = {
		"cooldown_reduction": 0.15,
	}
	sell_price = 400
	buy_price = 1200

	super._ready()

func _on_equip(target: Node) -> void:
	if target.has_method("add_revive_chance"):
		target.add_revive_chance(0.3, 0.25)