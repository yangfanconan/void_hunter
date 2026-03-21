## Void Hunter - 幸运护符
## @description: 史诗稀有度饰品，暴击+10%，掉落率+20%
## @author: Void Hunter Team
## @version: 0.1.0

extends "res://src/items/item_base.gd"
class_name AccessoryLuckyCharm

# =============================================================================
# 配置
# =============================================================================

const ITEM_ID: String = "accessory_lucky_charm"
const ITEM_NAME: String = "幸运护符"
const ITEM_DESCRIPTION: String = "带来好运的护符，增加暴击和掉落概率。\n暴击率 +10%\n道具掉落率 +20%"
const CRITICAL_CHANCE_BONUS: float = 0.10
const DROP_RATE_BONUS: float = 0.20

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
	sell_price = 350
	buy_price = 1000
	
	# 设置属性加成
	stat_bonuses = {
		"critical_chance": CRITICAL_CHANCE_BONUS,
		"drop_rate": DROP_RATE_BONUS
	}
	
	is_temporary = false


func _apply_equipment_effects(target: Node) -> void:
	"""应用装备效果"""
	super._apply_equipment_effects(target)
	
	if "stats" in target and target.stats is PlayerStats:
		# 增加暴击率
		target.stats.critical_chance += CRITICAL_CHANCE_BONUS
	
	# 增加掉落率（需要在掉落系统中处理）
	# DropSystem.modify_drop_rate(DROP_RATE_BONUS)


func _remove_equipment_effects(target: Node) -> void:
	"""移除装备效果"""
	super._remove_equipment_effects(target)
	
	if "stats" in target and target.stats is PlayerStats:
		target.stats.critical_chance -= CRITICAL_CHANCE_BONUS


func get_item_info() -> Dictionary:
	"""获取道具信息，添加特殊属性说明"""
	var info = super.get_item_info()
	info["special_effect"] = "幸运光环: 增加20%的道具掉落概率"
	return info
