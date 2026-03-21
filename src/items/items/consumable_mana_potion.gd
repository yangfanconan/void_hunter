## Void Hunter - 法力药水
## @description: 恢复50%法力值的消耗品
## @author: Void Hunter Team
## @version: 0.1.0

extends "res://src/items/item_base.gd"
class_name ConsumableManaPotion

# =============================================================================
# 配置
# =============================================================================

const ITEM_ID: String = "consumable_mana_potion"
const ITEM_NAME: String = "法力药水"
const ITEM_DESCRIPTION: String = "蓝色的药水，蕴含魔力。\n恢复50%最大法力值"
const MANA_PERCENT: float = 0.50
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
	sell_price = 20
	buy_price = 60
	
	# 法力恢复效果
	mana_restore = 0  # 动态计算
	
	is_temporary = false


func _on_use(user: Node) -> void:
	"""使用道具"""
	super._on_use(user)
	
	# 计算并应用法力恢复
	if "stats" in user and user.stats is PlayerStats:
		var mana_amount: float = user.stats.max_mana * MANA_PERCENT
		user.stats.restore_mana(mana_amount)
		
		# 播放法力恢复效果
		_play_mana_effect(user)


func _play_mana_effect(target: Node) -> void:
	"""播放法力恢复效果"""
	# 蓝色闪烁效果
	var tween: Tween = target.create_tween()
	tween.tween_property(target, "modulate", Color.CYAN, 0.15)
	tween.tween_property(target, "modulate", Color.WHITE, 0.15)
	
	# 播放音效
	AudioManager.play_sfx("mana_restore", 0.8)


func get_item_info() -> Dictionary:
	"""获取道具信息"""
	var info = super.get_item_info()
	info["mana_percent"] = MANA_PERCENT * 100
	return info
