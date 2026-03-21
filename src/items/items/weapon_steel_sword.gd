## Void Hunter - 精钢长剑
## @description: 稀有稀有度武器，攻击+15，暴击+5%
## @author: Void Hunter Team
## @version: 0.1.0

extends "res://src/items/item_base.gd"
class_name WeaponSteelSword

# =============================================================================
# 配置
# =============================================================================

const ITEM_ID: String = "weapon_steel_sword"
const ITEM_NAME: String = "精钢长剑"
const ITEM_DESCRIPTION: String = "由精钢锻造的长剑，锋利无比。\n攻击力 +15\n暴击率 +5%"
const ATTACK_BONUS: int = 15
const CRITICAL_CHANCE_BONUS: float = 0.05

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
	equip_slot = EquipSlot.WEAPON
	
	max_stack = 1
	current_stack = 1
	can_drop = true
	sellable = true
	sell_price = 50
	buy_price = 150
	
	# 设置属性加成
	stat_bonuses = {
		"attack": ATTACK_BONUS,
		"critical_chance": CRITICAL_CHANCE_BONUS
	}
	
	is_temporary = false


func _apply_equipment_effects(target: Node) -> void:
	"""应用装备效果"""
	super._apply_equipment_effects(target)
	
	# 特殊效果：暴击率需要单独处理
	if "stats" in target and target.stats is PlayerStats:
		target.stats.critical_chance += CRITICAL_CHANCE_BONUS


func _remove_equipment_effects(target: Node) -> void:
	"""移除装备效果"""
	super._remove_equipment_effects(target)
	
	if "stats" in target and target.stats is PlayerStats:
		target.stats.critical_chance -= CRITICAL_CHANCE_BONUS
