## Void Hunter - 经验宝石
## @description: 使用获得100经验的特殊道具
## @author: Void Hunter Team
## @version: 0.1.0

extends "res://src/items/item_base.gd"
class_name SpecialExpGem

# =============================================================================
# 配置
# =============================================================================

const ITEM_ID: String = "special_exp_gem"
const ITEM_NAME: String = "经验宝石"
const ITEM_DESCRIPTION: String = "蕴含纯净经验能量的宝石。\n使用后获得100点经验值"
const EXP_AMOUNT: int = 100
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
	rarity = ItemRarity.UNCOMMON
	equip_slot = EquipSlot.NONE
	
	max_stack = MAX_STACK
	current_stack = 1
	can_drop = true
	sellable = true
	sell_price = 50
	buy_price = 150
	
	is_temporary = false


func _on_use(user: Node) -> void:
	"""使用道具"""
	super._on_use(user)
	
	# 给予经验值
	if "stats" in user and user.stats is PlayerStats:
		user.stats.add_experience(EXP_AMOUNT)
		
		# 播放经验获取效果
		_play_exp_effect(user)


func _play_exp_effect(target: Node) -> void:
	"""播放经验获取效果"""
	# 黄色闪烁效果
	var tween: Tween = target.create_tween()
	tween.tween_property(target, "modulate", Color.YELLOW, 0.15)
	tween.tween_property(target, "modulate", Color.WHITE, 0.15)
	
	# 播放音效
	AudioManager.play_sfx("exp_gain", 0.8)


func get_item_info() -> Dictionary:
	"""获取道具信息"""
	var info = super.get_item_info()
	info["exp_amount"] = EXP_AMOUNT
	return info
