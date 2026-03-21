## Void Hunter - 铁甲
## @description: 稀有稀有度防具，防御+10，生命+20
## @author: Void Hunter Team
## @version: 0.1.0

extends "res://src/items/item_base.gd"
class_name ArmorIron

# =============================================================================
# 配置
# =============================================================================

const ITEM_ID: String = "armor_iron"
const ITEM_NAME: String = "铁甲"
const ITEM_DESCRIPTION: String = "由铁板锻造的护甲，坚固耐用。\n防御力 +10\n最大生命值 +20"
const DEFENSE_BONUS: int = 10
const HEALTH_BONUS: int = 20

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
	equip_slot = EquipSlot.ARMOR
	
	max_stack = 1
	current_stack = 1
	can_drop = true
	sellable = true
	sell_price = 60
	buy_price = 180
	
	# 设置属性加成
	stat_bonuses = {
		"defense": DEFENSE_BONUS,
		"health": HEALTH_BONUS
	}
	
	is_temporary = false


func _apply_equipment_effects(target: Node) -> void:
	"""应用装备效果"""
	super._apply_equipment_effects(target)
	
	# 增加最大生命值
	if "stats" in target and target.stats is PlayerStats:
		target.stats.add_flat_bonus("health", HEALTH_BONUS)


func _remove_equipment_effects(target: Node) -> void:
	"""移除装备效果"""
	super._remove_equipment_effects(target)
	
	if "stats" in target and target.stats is PlayerStats:
		target.stats.remove_flat_bonus("health", HEALTH_BONUS)
