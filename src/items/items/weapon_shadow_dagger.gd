## Void Hunter - 暗影匕首
## @description: 史诗稀有度武器，攻击+25，暴击伤害+30%
## @author: Void Hunter Team
## @version: 0.1.0

extends "res://src/items/item_base.gd"
class_name WeaponShadowDagger

# =============================================================================
# 配置
# =============================================================================

const ITEM_ID: String = "weapon_shadow_dagger"
const ITEM_NAME: String = "暗影匕首"
const ITEM_DESCRIPTION: String = "蕴含暗影之力的匕首，攻击时带有黑暗气息。\n攻击力 +25\n暴击伤害 +30%"
const ATTACK_BONUS: int = 25
const CRITICAL_DAMAGE_BONUS: float = 0.30

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
	equip_slot = EquipSlot.WEAPON
	
	max_stack = 1
	current_stack = 1
	can_drop = true
	sellable = true
	sell_price = 200
	buy_price = 600
	
	# 设置属性加成
	stat_bonuses = {
		"attack": ATTACK_BONUS
	}
	
	is_temporary = false


func _apply_equipment_effects(target: Node) -> void:
	"""应用装备效果"""
	super._apply_equipment_effects(target)
	
	# 特殊效果：暴击伤害加成
	if "stats" in target and target.stats is PlayerStats:
		target.stats.critical_damage += CRITICAL_DAMAGE_BONUS


func _remove_equipment_effects(target: Node) -> void:
	"""移除装备效果"""
	super._remove_equipment_effects(target)
	
	if "stats" in target and target.stats is PlayerStats:
		target.stats.critical_damage -= CRITICAL_DAMAGE_BONUS
