## Void Hunter - 虚空之刃
## @description: 传说稀有度武器，攻击+40，穿透敌人
## @author: Void Hunter Team
## @version: 0.1.0

extends "res://src/items/item_base.gd"
class_name WeaponVoidBlade

# =============================================================================
# 配置
# =============================================================================

const ITEM_ID: String = "weapon_void_blade"
const ITEM_NAME: String = "虚空之刃"
const ITEM_DESCRIPTION: String = "由虚空能量凝聚而成的利刃，可以穿透一切防御。\n攻击力 +40\n攻击穿透敌人（无视50%防御）"
const ATTACK_BONUS: int = 40
const ARMOR_PENETRATION: float = 0.50

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
	equip_slot = EquipSlot.WEAPON
	
	max_stack = 1
	current_stack = 1
	can_drop = true
	sellable = true
	sell_price = 1200
	buy_price = 3500
	
	# 设置属性加成
	stat_bonuses = {
		"attack": ATTACK_BONUS,
		"armor_penetration": ARMOR_PENETRATION
	}
	
	is_temporary = false


func _apply_equipment_effects(target: Node) -> void:
	"""应用装备效果"""
	super._apply_equipment_effects(target)
	
	# 虚空光环效果
	_play_void_aura(target)


func _remove_equipment_effects(target: Node) -> void:
	"""移除装备效果"""
	super._remove_equipment_effects(target)


func _play_void_aura(target: Node) -> void:
	"""播放虚空光环效果"""
	# TODO: 添加虚空粒子效果
	pass


func get_item_info() -> Dictionary:
	"""获取道具信息，添加特殊属性说明"""
	var info = super.get_item_info()
	info["special_effect"] = "护甲穿透: 无视敌人50%的防御力"
	return info
