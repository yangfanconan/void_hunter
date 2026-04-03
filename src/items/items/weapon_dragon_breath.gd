## Void Hunter - 龙息巨剑
## @description: 传说稀有度武器，攻击+50，攻击附带火焰伤害
## @author: Void Hunter Team
## @version: 0.1.0

extends "res://src/items/item_base.gd"
class_name WeaponDragonBreath

# =============================================================================
# 配置
# =============================================================================

const ITEM_ID: String = "weapon_dragon_breath"
const ITEM_NAME: String = "龙息巨剑"
const ITEM_DESCRIPTION: String = "传说中由龙鳞锻造的巨剑，挥舞时喷射火焰。\n攻击力 +50\n攻击附带火焰伤害（额外20%）"
const ATTACK_BONUS: int = 50
const FIRE_DAMAGE_BONUS: float = 0.20

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
	sell_price = 1000
	buy_price = 3000
	
	# 设置属性加成
	stat_bonuses = {
		"attack": ATTACK_BONUS,
		"fire_damage_percent": FIRE_DAMAGE_BONUS
	}
	
	is_temporary = false


func _apply_equipment_effects(target: Node) -> void:
	"""应用装备效果"""
	super._apply_equipment_effects(target)
	
	# 火焰光环效果
	_play_fire_aura(target)


func _remove_equipment_effects(target: Node) -> void:
	"""移除装备效果"""
	super._remove_equipment_effects(target)


func _play_fire_aura(target: Node) -> void:
	"""播放火焰光环效果"""
	if VFXManager:
		# 创建持续火焰光环
		var aura := VFXManager.create_aura_effect(target, "fire_aura")
		if aura:
			aura.name = "FireAura"
			target.add_child(aura)


func get_item_info() -> Dictionary:
	"""获取道具信息，添加特殊属性说明"""
	var info = super.get_item_info()
	info["special_effect"] = "火焰伤害: 攻击时额外造成20%的火焰伤害"
	return info
