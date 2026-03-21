## Void Hunter - 时间沙漏
## @description: 传说稀有度饰品，冷却-20%，持续时间+30%
## @author: Void Hunter Team
## @version: 0.1.0

extends "res://src/items/item_base.gd"
class_name AccessoryHourglassOfTime

# =============================================================================
# 配置
# =============================================================================

const ITEM_ID: String = "accessory_hourglass_of_time"
const ITEM_NAME: String = "时间沙漏"
const ITEM_DESCRIPTION: String = "操控时间流动的神秘沙漏。\n技能冷却时间 -20%\n技能持续时间 +30%"
const COOLDOWN_REDUCTION: float = 0.20
const DURATION_BONUS: float = 0.30

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
	rarity = ItemRarity.LEGENDARY
	equip_slot = EquipSlot.ACCESSORY
	
	max_stack = 1
	current_stack = 1
	can_drop = true
	sellable = true
	sell_price = 1000
	buy_price = 3000
	
	# 设置属性加成
	stat_bonuses = {
		"cooldown_reduction": COOLDOWN_REDUCTION,
		"duration_bonus": DURATION_BONUS
	}
	
	is_temporary = false


func _apply_equipment_effects(target: Node) -> void:
	"""应用装备效果"""
	super._apply_equipment_effects(target)
	
	# TODO: 在技能系统中应用冷却和持续时间加成
	# SkillManager.apply_cooldown_reduction(COOLDOWN_REDUCTION)
	# SkillManager.apply_duration_bonus(DURATION_BONUS)


func _remove_equipment_effects(target: Node) -> void:
	"""移除装备效果"""
	super._remove_equipment_effects(target)


func get_item_info() -> Dictionary:
	"""获取道具信息，添加特殊属性说明"""
	var info = super.get_item_info()
	info["special_effect"] = "时间操控: 技能冷却减少20%，技能持续时间增加30%"
	return info
