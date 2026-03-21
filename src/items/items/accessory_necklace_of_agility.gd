## Void Hunter - 敏捷项链
## @description: 稀有稀有度饰品，移动速度+15%
## @author: Void Hunter Team
## @version: 0.1.0

extends "res://src/items/item_base.gd"
class_name AccessoryNecklaceOfAgility

# =============================================================================
# 配置
# =============================================================================

const ITEM_ID: String = "accessory_necklace_of_agility"
const ITEM_NAME: String = "敏捷项链"
const ITEM_DESCRIPTION: String = "轻巧的项链，让穿戴者身手矫健。\n移动速度 +15%"
const SPEED_PERCENT_BONUS: float = 0.15

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
	rarity = ItemRarity.UNCOMMON
	equip_slot = EquipSlot.ACCESSORY
	
	max_stack = 1
	current_stack = 1
	can_drop = true
	sellable = true
	sell_price = 80
	buy_price = 240
	
	# 设置属性加成（百分比）
	stat_bonuses = {
		"speed_percent": SPEED_PERCENT_BONUS
	}
	
	is_temporary = false


func _apply_equipment_effects(target: Node) -> void:
	"""应用装备效果"""
	super._apply_equipment_effects(target)
	
	# 应用速度加成
	if "stats" in target and target.stats is PlayerStats:
		target.stats.add_percent_bonus("speed", SPEED_PERCENT_BONUS)


func _remove_equipment_effects(target: Node) -> void:
	"""移除装备效果"""
	super._remove_equipment_effects(target)
	
	if "stats" in target and target.stats is PlayerStats:
		target.stats.remove_percent_bonus("speed", SPEED_PERCENT_BONUS)
