## Void Hunter - 力量戒指
## @description: 稀有稀有度饰品，攻击+10%
## @author: Void Hunter Team
## @version: 0.1.0

extends "res://src/items/item_base.gd"
class_name AccessoryRingOfPower

# =============================================================================
# 配置
# =============================================================================

const ITEM_ID: String = "accessory_ring_of_power"
const ITEM_NAME: String = "力量戒指"
const ITEM_DESCRIPTION: String = "蕴含力量的神秘戒指，提升攻击能力。\n攻击力 +10%"
const ATTACK_PERCENT_BONUS: float = 0.10

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
		"attack_percent": ATTACK_PERCENT_BONUS
	}
	
	is_temporary = false


func _apply_equipment_effects(target: Node) -> void:
	"""应用装备效果"""
	super._apply_equipment_effects(target)
	
	# 应用百分比攻击加成
	if "stats" in target and target.stats is PlayerStats:
		target.stats.add_percent_bonus("attack", ATTACK_PERCENT_BONUS)


func _remove_equipment_effects(target: Node) -> void:
	"""移除装备效果"""
	super._remove_equipment_effects(target)
	
	if "stats" in target and target.stats is PlayerStats:
		target.stats.remove_percent_bonus("attack", ATTACK_PERCENT_BONUS)
