## Void Hunter - 虚空护盾
## @description: 传说稀有度防具，防御+30，每10秒生成护盾
## @author: Void Hunter Team
## @version: 0.1.0

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
		_shield_timer.autostart = true
		_shield_timer.timeout.connect(_on_shield_timer_timeout)
		target.add_child(_shield_timer)
	
	_shield_timer.start()


func _remove_equipment_effects(target: Node) -> void:
	"""移除装备效果"""
	super._remove_equipment_effects(target)
	
	# 停止并移除计时器
	if _shield_timer != null:
		_shield_timer.stop()
		_shield_timer.queue_free()
		_shield_timer = null
	
	_target_ref = null


func _on_shield_timer_timeout() -> void:
	"""护盾计时器触发"""
	if _target_ref == null:
		return
	
	var target = _target_ref.get_ref()
	if target == null or not is_instance_valid(target):
		return
	
	# 生成护盾
	_apply_shield(target)


func _apply_shield(target: Node) -> void:
	"""应用护盾效果"""
	# TODO: 在玩家属性中添加护盾机制
	# target.add_shield(SHIELD_AMOUNT)
	pass


func get_item_info() -> Dictionary:
	"""获取道具信息，添加特殊属性说明"""
	var info = super.get_item_info()
	info["special_effect"] = "虚空护盾: 每10秒自动生成一个可吸收20点伤害的护盾"
	return info
