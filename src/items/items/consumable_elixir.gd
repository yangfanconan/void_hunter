## Void Hunter - 全能药剂
## @description: 恢复全部生命和法力，并提供临时增益
## @author: Void Hunter Team
## @version: 0.1.0

extends "res://src/items/item_base.gd"
class_name ConsumableElixir

# =============================================================================
# 配置
# =============================================================================

const ITEM_ID: String = "consumable_elixir"
const ITEM_NAME: String = "全能药剂"
const ITEM_DESCRIPTION: String = "金色的神秘药剂，蕴含强大力量。\n恢复全部生命值和法力值\n攻击力+20%（持续60秒）"
const ATTACK_BUFF_PERCENT: float = 0.20
const BUFF_DURATION: float = 60.0
const MAX_STACK: int = 20

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
	rarity = ItemRarity.EPIC
	equip_slot = EquipSlot.NONE
	
	max_stack = MAX_STACK
	current_stack = 1
	can_drop = true
	sellable = true
	sell_price = 200
	buy_price = 600
	
	is_temporary = true
	effect_duration = BUFF_DURATION
	
	# 属性加成
	stat_bonuses = {
		"attack_percent": ATTACK_BUFF_PERCENT
	}


func _on_use(user: Node) -> void:
	"""使用道具"""
	super._on_use(user)
	
	# 恢复全部生命和法力
	if "stats" in user and user.stats is PlayerStats:
		user.stats.heal(user.stats.max_health)
		user.stats.restore_mana(user.stats.max_mana)
		
		# 应用临时增益
		user.stats.add_percent_bonus("attack", ATTACK_BUFF_PERCENT)
		
		# 播放效果
		_play_elixir_effect(user)
		
		# 设置增益结束回调
		_start_buff_timer(user)


func _play_elixir_effect(target: Node) -> void:
	"""播放全能药剂效果"""
	# 金色闪烁效果
	var tween: Tween = target.create_tween()
	tween.tween_property(target, "modulate", Color.GOLD, 0.2)
	tween.tween_property(target, "modulate", Color.WHITE, 0.2)
	
	# 播放音效
	AudioManager.play_sfx("power_up", 1.0)


func _start_buff_timer(user: Node) -> void:
	"""启动增益计时器"""
	await get_tree().create_timer(BUFF_DURATION).timeout
	
	# 增益结束，移除效果
	if is_instance_valid(user) and "stats" in user and user.stats is PlayerStats:
		user.stats.remove_percent_bonus("attack", ATTACK_BUFF_PERCENT)
		
		# 播放增益结束提示
		_play_buff_expire_effect(user)


func _play_buff_expire_effect(user: Node) -> void:
	"""播放增益结束效果"""
	var tween: Tween = user.create_tween()
	tween.tween_property(user, "modulate", Color.GRAY, 0.15)
	tween.tween_property(user, "modulate", Color.WHITE, 0.15)


func get_item_info() -> Dictionary:
	"""获取道具信息"""
	var info = super.get_item_info()
	info["buff_duration"] = BUFF_DURATION
	info["attack_buff_percent"] = ATTACK_BUFF_PERCENT * 100
	return info
