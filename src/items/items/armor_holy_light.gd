## Void Hunter - 圣光铠甲
## @description: 史诗稀有度防具，防御+20，受伤恢复
## @author: Void Hunter Team
## @version: 0.1.0

extends "res://src/items/item_base.gd"
class_name ArmorHolyLight

# =============================================================================
# 配置
# =============================================================================

const ITEM_ID: String = "armor_holy_light"
const ITEM_NAME: String = "圣光铠甲"
const ITEM_DESCRIPTION: String = "蕴含圣洁之力的铠甲，受到伤害时恢复少量生命。\n防御力 +20\n受伤恢复（回复伤害的10%）"
const DEFENSE_BONUS: int = 20
const HEAL_ON_DAMAGE_PERCENT: float = 0.10

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
	equip_slot = EquipSlot.ARMOR
	
	max_stack = 1
	current_stack = 1
	can_drop = true
	sellable = true
	sell_price = 250
	buy_price = 750
	
	# 设置属性加成
	stat_bonuses = {
		"defense": DEFENSE_BONUS,
		"heal_on_damage": HEAL_ON_DAMAGE_PERCENT
	}
	
	is_temporary = false


func get_item_info() -> Dictionary:
	"""获取道具信息，添加特殊属性说明"""
	var info = super.get_item_info()
	info["special_effect"] = "圣光庇护: 受到伤害时恢复伤害值10%的生命"
	return info
