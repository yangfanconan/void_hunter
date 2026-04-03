## Void Hunter - 护盾药剂
## @description: 使用后获得护盾
## @version: 1.0.0

extends "res://src/items/item_base.gd"

func _ready() -> void:
	item_id = "consumable_shield_potion"
	item_name = "护盾药剂"
	description = "使用后获得100点护盾，持续30秒"
	item_type = ItemType.CONSUMABLE
	rarity = ItemRarity.RARE
	max_stack = 5
	current_stack = 1
	effect_duration = 30.0

	heal_amount = 0.0
	sell_price = 40
	buy_price = 120

	super._ready()

func _apply_immediate_effects(target: Node) -> void:
	# 添加护盾
	var status_mgr = target.get_tree().current_scene.get_node_or_null("StatusEffectManager")
	if status_mgr and status_mgr.has_method("apply_shield"):
		status_mgr.apply_shield(target, 100.0, null)
	elif target.has_method("add_shield"):
		target.add_shield(100.0)