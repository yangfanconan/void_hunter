## Void Hunter - 智慧宝石
## @description: 史诗稀有度饰品，法力+50%，法力恢复+2
## @author: Void Hunter Team
## @version: 0.1.0

extends "res://src/items/item_base.gd"
class_name AccessoryGemOfWisdom

# =============================================================================
# 配置
# =============================================================================

const ITEM_ID: String = "accessory_gem_of_wisdom"
const ITEM_NAME: String = "智慧宝石"
const ITEM_DESCRIPTION: String = "蕴含古老智慧的宝石，增强魔力。\n最大法力值 +50%\n法力恢复 +2/秒"
const MANA_PERCENT_BONUS: float = 0.50
const MANA_REGEN_BONUS: float = 2.0

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
	rarity = ItemRarity.EPIC
	equip_slot = EquipSlot.ACCESSORY
	
	max_stack = 1
	current_stack = 1
	can_drop = true
	sellable = true
	sell_price = 300
	buy_price = 900
	
	# 设置属性加成
	stat_bonuses = {
		"mana_percent": MANA_PERCENT_BONUS,
		"mana_regen": MANA_REGEN_BONUS
	}
	
	is_temporary = false


func _apply_equipment_effects(target: Node) -> void:
	"""应用装备效果"""
	super._apply_equipment_effects(target)
	
	if "stats" in target and target.stats is PlayerStats:
		# 应用法力百分比加成
		target.stats.add_percent_bonus("mana", MANA_PERCENT_BONUS)
		# 增加法力恢复
		target.stats.mana_regen += MANA_REGEN_BONUS


func _remove_equipment_effects(target: Node) -> void:
	"""移除装备效果"""
	super._remove_equipment_effects(target)
	
	if "stats" in target and target.stats is PlayerStats:
		target.stats.remove_percent_bonus("mana", MANA_PERCENT_BONUS)
		target.stats.mana_regen -= MANA_REGEN_BONUS
