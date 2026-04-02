## Void Hunter - 虚空护盾
## @description: 传说稀有度防具，防御+30，每10秒生成护盾
## @author: Void Hunter Team
## @version: 0.2.0

extends "res://src/items/item_base.gd"
class_name ArmorVoidShield

# =============================================================================
# 配置
# =============================================================================

const ITEM_ID: String = "armor_void_shield"
const ITEM_NAME: String = "虚空护盾"
const ITEM_DESCRIPTION: String = "由虚空能量构成的护盾，定期自动恢复。\n防御力 +30\n每10秒生成护盾（吸收20点伤害）"
const DEFENSE_BONUS: int = 30
const SHIELD_AMOUNT: int = 20
const SHIELD_COOLDOWN: float = 10.0

# =============================================================================
# 私有变量
# =============================================================================

var _shield_timer: Timer = null
var _target_ref: WeakRef = null

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
	sell_price = 1500
	buy_price = 4500

	# 设置属性加成
	stat_bonuses = {
		"defense": DEFENSE_BONUS,
		"auto_shield": SHIELD_AMOUNT
	}

	is_temporary = false


func _apply_equipment_effects(target: Node) -> void:
	"""应用装备效果"""
	super._apply_equipment_effects(target)

	_target_ref = weakref(target)

	# 创建护盾计时器
	if _shield_timer == null:
		_shield_timer = Timer.new()
		_shield_timer.wait_time = SHIELD_COOLDOWN
		_shield_timer.one_shot = false
		_shield_timer.autostart = true
		_shield_timer.timeout.connect(_on_shield_timer_timeout)
		target.add_child(_shield_timer)
	else:
		_shield_timer.start()

	# 装备时立即生成一个护盾
	_apply_shield(target)


func _remove_equipment_effects(target: Node) -> void:
	"""移除装备效果"""
	super._remove_equipment_effects(target)

	# 停止并移除计时器
	if _shield_timer != null:
		_shield_timer.stop()
		if _shield_timer.get_parent() != null:
			_shield_timer.queue_free()
		_shield_timer = null

	_target_ref = null


func _on_shield_timer_timeout() -> void:
	"""护盾计时器触发"""
	if _target_ref == null:
		return

	var target = _target_ref.get_ref()
	if target == null or not is_instance_valid(target):
		# 目标已失效，清理计时器
		if _shield_timer != null:
			_shield_timer.stop()
		return

	# 生成护盾
	_apply_shield(target)


func _apply_shield(target: Node) -> void:
	"""应用护盾效果"""
	# 尝试通过状态效果管理器应用护盾
	var status_mgr: Node = _get_status_manager()
	if status_mgr and status_mgr.has_method("apply_shield"):
		status_mgr.apply_shield(target, float(SHIELD_AMOUNT), target)
		return

	# 后备方案：直接在玩家属性上设置护盾
	if "stats" in target and target.stats is PlayerStats:
		if target.stats.has_method("add_shield"):
			target.stats.add_shield(SHIELD_AMOUNT)
		elif "shield" in target.stats:
			target.stats.shield = mini(target.stats.shield + SHIELD_AMOUNT, SHIELD_AMOUNT)


func _get_status_manager() -> Node:
	"""获取状态效果管理器"""
	var scene := get_tree().current_scene
	if scene:
		return scene.get_node_or_null("StatusEffectManager")
	return null


func get_item_info() -> Dictionary:
	"""获取道具信息，添加特殊属性说明"""
	var info = super.get_item_info()
	info["special_effect"] = "虚空护盾: 每10秒自动生成一个可吸收20点伤害的护盾"
	return info
