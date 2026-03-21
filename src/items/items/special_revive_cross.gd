## Void Hunter - 复活十字
## @description: 死亡时自动复活一次的特殊道具
## @author: Void Hunter Team
## @version: 0.1.0

extends "res://src/items/item_base.gd"
class_name SpecialReviveCross

# =============================================================================
# 配置
# =============================================================================

const ITEM_ID: String = "special_revive_cross"
const ITEM_NAME: String = "复活十字"
const ITEM_DESCRIPTION: String = "神圣的十字架，在死亡时自动复活一次。\n死亡时恢复50%生命值复活\n（被动效果，装备后生效）"
const REVIVE_HEALTH_PERCENT: float = 0.50
const MAX_STACK: int = 1

# =============================================================================
# 私有变量
# =============================================================================

var _is_active: bool = false
var _owner_ref: WeakRef = null

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
	
	item_type = ItemType.KEY_ITEM  # 关键道具，不能直接使用
	rarity = ItemRarity.LEGENDARY
	equip_slot = EquipSlot.ACCESSORY
	
	max_stack = MAX_STACK
	current_stack = 1
	can_drop = true
	sellable = true
	sell_price = 2000
	buy_price = 6000
	
	is_temporary = false


func _on_pickup(picker: Node) -> void:
	"""拾取时激活"""
	super._on_pickup(picker)
	_activate_revive(picker)


func _on_use(user: Node) -> void:
	"""关键道具不能直接使用"""
	push_warning("复活十字是被动道具，不能直接使用")


func _activate_revive(owner: Node) -> void:
	"""激活复活效果"""
	if _is_active:
		return
	
	_is_active = true
	_owner_ref = weakref(owner)
	
	# 监听玩家死亡信号
	if owner.has_signal("died"):
		owner.died.connect(_on_owner_died, CONNECT_DEFERRED)


func _deactivate_revive() -> void:
	"""停用复活效果"""
	_is_active = false
	_owner_ref = null


func _on_owner_died() -> void:
	"""拥有者死亡时触发复活"""
	if not _is_active:
		return
	
	var owner = _owner_ref.get_ref()
	if owner == null or not is_instance_valid(owner):
		return
	
	# 执行复活
	_perform_revive(owner)


func _perform_revive(owner: Node) -> void:
	"""执行复活"""
	# 标记为不再活跃（一次性使用）
	_is_active = false
	
	# 复活玩家
	if "stats" in owner and owner.stats is PlayerStats:
		owner.stats.is_dead = false
		var revive_health: float = owner.stats.max_health * REVIVE_HEALTH_PERCENT
		owner.stats.current_health = revive_health
		owner.stats.health_changed.emit(owner.stats.current_health, owner.stats.max_health)
	
	# 重置玩家状态
	if owner.has_method("initialize"):
		owner.initialize()
	
	# 通知游戏管理器
	GameManager.handle_player_revive()
	
	# 播放复活效果
	_play_revive_effect(owner)
	
	# 消耗道具
	current_stack -= 1
	if current_stack <= 0:
		_schedule_despawn()


func _play_revive_effect(target: Node) -> void:
	"""播放复活效果"""
	# 白色光芒效果
	var tween: Tween = target.create_tween()
	target.modulate = Color.WHITE
	
	tween.tween_property(target, "modulate:a", 0.0, 0.1)
	tween.tween_property(target, "modulate:a", 1.0, 0.1)
	tween.tween_property(target, "modulate:a", 0.0, 0.1)
	tween.tween_property(target, "modulate:a", 1.0, 0.1)
	tween.tween_property(target, "modulate", Color.WHITE, 0.3)
	
	# 播放音效
	AudioManager.play_sfx("revive", 1.0)


func get_item_info() -> Dictionary:
	"""获取道具信息"""
	var info = super.get_item_info()
	info["special_effect"] = "被动效果：死亡时自动复活，恢复50%生命值"
	info["revive_health_percent"] = REVIVE_HEALTH_PERCENT * 100
	info["is_active"] = _is_active
	return info
