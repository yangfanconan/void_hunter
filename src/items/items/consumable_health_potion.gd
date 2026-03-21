## Void Hunter - 生命药水
## @description: 恢复30%生命值的消耗品
## @author: Void Hunter Team
## @version: 0.1.0

extends "res://src/items/item_base.gd"
class_name ConsumableHealthPotion

# =============================================================================
# 配置
# =============================================================================

const ITEM_ID: String = "consumable_health_potion"
const ITEM_NAME: String = "生命药水"
const ITEM_DESCRIPTION: String = "红色的药水，散发着生命气息。\n恢复30%最大生命值"
const HEAL_PERCENT: float = 0.30
const MAX_STACK: int = 99

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
	
	item_type = ItemType.CONSUMABLE
	rarity = ItemRarity.COMMON
	equip_slot = EquipSlot.NONE
	
	max_stack = MAX_STACK
	current_stack = 1
	can_drop = true
	sellable = true
	sell_price = 15
	buy_price = 50
	
	# 治疗效果
	heal_amount = 0  # 动态计算
	
	is_temporary = false


func _on_use(user: Node) -> void:
	"""使用道具"""
	super._on_use(user)
	
	# 计算并应用治疗
	if "stats" in user and user.stats is PlayerStats:
		var heal_amount_actual: float = user.stats.max_health * HEAL_PERCENT
		user.stats.heal(heal_amount_actual)
		
		# 播放治疗效果
		_play_heal_effect(user)


func _play_heal_effect(target: Node) -> void:
	"""播放治疗效果"""
	# 绿色闪烁效果
	var tween: Tween = target.create_tween()
	tween.tween_property(target, "modulate", Color.GREEN, 0.15)
	tween.tween_property(target, "modulate", Color.WHITE, 0.15)
	
	# 播放音效
	AudioManager.play_sfx("heal", 0.8)


func get_item_info() -> Dictionary:
	"""获取道具信息"""
	var info = super.get_item_info()
	info["heal_percent"] = HEAL_PERCENT * 100
	return info
