## Void Hunter - 新手短剑
## @description: 普通稀有度武器，攻击+5
## @author: Void Hunter Team
## @version: 0.1.0

extends "res://src/items/item_base.gd"
class_name WeaponNoviceSword

# =============================================================================
# 配置
# =============================================================================

const ITEM_ID: String = "weapon_novice_sword"
const ITEM_NAME: String = "新手短剑"
const ITEM_DESCRIPTION: String = "一把简单的短剑，适合初学者使用。\n攻击力 +5"
const ATTACK_BONUS: int = 5

# =============================================================================
# 生命周期
# =============================================================================

func _ready() -> void:
	_setup_item()


func _setup_item() -> void:
	"""配置道具属性"""
	item_id = ITEM_ID
	item_name = ITEM_NAME
	description = ITEM_DESCRIPTION
	
	item_type = ItemType.EQUIPMENT
	rarity = ItemRarity.COMMON
	equip_slot = EquipSlot.WEAPON
	
	max_stack = 1
	current_stack = 1
	can_drop = true
	sellable = true
	sell_price = 10
	buy_price = 30
	
	# 设置属性加成
	stat_bonuses = {
		"attack": ATTACK_BONUS
	}
	
	# 装备效果说明
	is_temporary = false


func _on_equip(target: Node) -> void:
	"""装备时触发"""
	# 新手短剑没有特殊效果，基类已处理属性加成


func _on_unequip(target: Node) -> void:
	"""卸下时触发"""
	# 新手短剑没有特殊效果，基类已处理属性移除
