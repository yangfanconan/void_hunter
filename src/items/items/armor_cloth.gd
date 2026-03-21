## Void Hunter - 布甲
## @description: 普通稀有度防具，防御+3
## @author: Void Hunter Team
## @version: 0.1.0

extends "res://src/items/item_base.gd"
class_name ArmorCloth

# =============================================================================
# 配置
# =============================================================================

const ITEM_ID: String = "armor_cloth"
const ITEM_NAME: String = "布甲"
const ITEM_DESCRIPTION: String = "简单的布制护甲，提供基础防护。\n防御力 +3"
const DEFENSE_BONUS: int = 3

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
	rarity = ItemRarity.COMMON
	equip_slot = EquipSlot.ARMOR
	
	max_stack = 1
	current_stack = 1
	can_drop = true
	sellable = true
	sell_price = 8
	buy_price = 25
	
	# 设置属性加成
	stat_bonuses = {
		"defense": DEFENSE_BONUS
	}
	
	is_temporary = false
