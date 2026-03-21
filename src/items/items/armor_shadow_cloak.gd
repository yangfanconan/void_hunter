## Void Hunter - 暗影披风
## @description: 传说稀有度防具，防御+15，闪避+20%
## @author: Void Hunter Team
## @version: 0.1.0

extends "res://src/items/item_base.gd"
class_name ArmorShadowCloak

# =============================================================================
# 配置
# =============================================================================

const ITEM_ID: String = "armor_shadow_cloak"
const ITEM_NAME: String = "暗影披风"
const ITEM_DESCRIPTION: String = "由暗影编织的披风，穿戴者如幽灵般难以捕捉。\n防御力 +15\n闪避率 +20%"
const DEFENSE_BONUS: int = 15
const DODGE_CHANCE: float = 0.20

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
	equip_slot = EquipSlot.ARMOR
	
	max_stack = 1
	current_stack = 1
	can_drop = true
	sellable = true
	sell_price = 800
	buy_price = 2400
	
	# 设置属性加成
	stat_bonuses = {
		"defense": DEFENSE_BONUS,
		"dodge_chance": DODGE_CHANCE
	}
	
	is_temporary = false


func _apply_equipment_effects(target: Node) -> void:
	"""应用装备效果"""
	super._apply_equipment_effects(target)
	
	# 添加闪避效果
	# TODO: 在玩家属性中添加闪避机制


func _remove_equipment_effects(target: Node) -> void:
	"""移除装备效果"""
	super._remove_equipment_effects(target)


func get_item_info() -> Dictionary:
	"""获取道具信息，添加特殊属性说明"""
	var info = super.get_item_info()
	info["special_effect"] = "暗影闪避: 20%概率闪避敌人的攻击"
	return info
