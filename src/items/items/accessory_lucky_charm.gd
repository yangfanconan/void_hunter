## Void Hunter - 幸运护符
## @description: 史诗稀有度饰品，暴击+10%，掉落率+20%
## @author: Void Hunter Team
## @version: 0.2.0

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


func _on_equip(target: Node) -> void:
	"""装备时触发"""
	# 增加暴击率
	if "stats" in target and target.stats is PlayerStats:
		target.stats.critical_chance += CRITICAL_CHANCE_BONUS

	# 增加掉落率 - 查找场景中的掉落系统
	_apply_drop_rate_bonus(DROP_RATE_BONUS)


func _on_unequip(target: Node) -> void:
	"""卸下时触发"""
	# 移除暴击率加成
	if "stats" in target and target.stats is PlayerStats:
		target.stats.critical_chance -= CRITICAL_CHANCE_BONUS

	# 移除掉落率加成
	_apply_drop_rate_bonus(-DROP_RATE_BONUS)


func _apply_drop_rate_bonus(bonus: float) -> void:
	"""应用/移除掉落率加成到掉落系统"""
	var drop_systems: Array[Node] = get_tree().get_nodes_in_group("drop_system")
	for ds in drop_systems:
		if ds.has_method("add_drop_rate_bonus"):
			ds.add_drop_rate_bonus(bonus)
		break


func get_item_info() -> Dictionary:
	"""获取道具信息，添加特殊属性说明"""
	var info = super.get_item_info()
	info["special_effect"] = "幸运光环: 增加20%的道具掉落概率"
	return info
