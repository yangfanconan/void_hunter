## Void Hunter - 护盾技能
## @description: 生成临时护盾
## @author: Void Hunter Team
## @version: 1.0.0

extends SkillBase
class_name SkillShield

# =============================================================================
# 信号
# =============================================================================

signal shield_broken()
signal shield_expired()

# =============================================================================
# 配置参数
# =============================================================================

## 护盾生命值（基于最大生命值百分比）
@export_range(0.0, 1.0) var shield_health_percent: float = 0.3

## 护盾固定生命值
@export var shield_flat_health: float = 50.0

## 护盾持续时间
@export var shield_duration: float = 5.0

## 护盾破碎时的爆炸伤害
@export var shatter_damage: float = 20.0

## 护盾破碎爆炸范围
@export var shatter_range: float = 80.0

# =============================================================================
# 内部变量
# =============================================================================

var _shield_active: bool = false
var _shield_health: float = 0.0
var _shield_max_health: float = 0.0
var _shield_timer: float = 0.0
var _shield_visual: Node2D = null

# =============================================================================
# 初始化
# =============================================================================

func _init() -> void:
	skill_id = "shield"
	skill_name = "魔法护盾"
	description = "生成一个临时护盾，吸收伤害。护盾破碎时对周围敌人造成伤害。"
	skill_type = SkillType.ACTIVE
	skill_category = SkillCategory.DEFENSIVE
	target_type = TargetType.SELF
	element = SkillElement.ARCANE
	hotkey_slot = 3
	
	base_damage = shatter_damage
	base_cooldown = 12.0
	base_mana_cost = 30.0
	effect_range = shatter_range
	duration = shield_duration


func initialize(owner: Node) -> void:
	super.initialize(owner)
	_shield_active = false
	_shield_health = 0.0


func update(delta: float) -> void:
	super.update(delta)
	
	if _shield_active:
		_shield_timer -= delta
		
		if _shield_timer <= 0:
			_expire_shield()
		elif _shield_health <= 0:
			_break_shield()


# =============================================================================
# 技能效果
# =============================================================================

func _execute_self_effect() -> void:
	"""
	激活护盾
	"""
	if _shield_active:
		# 刷新护盾
		_remove_shield()
	
	_create_shield()


func _create_shield() -> void:
	"""
	创建护盾
	"""
	_shield_active = true
	_shield_max_health = _calculate_shield_health()
	_shield_health = _shield_max_health
	_shield_timer = get_shield_duration()
	
	# 创建护盾视觉效果
	_create_shield_visual()
	
	# 连接伤害信号
	if owner_node and "damaged" in owner_node:
		if not owner_node.damaged.is_connected(_on_owner_damaged):
			owner_node.damaged.connect(_on_owner_damaged)


func _remove_shield() -> void:
	"""
	移除护盾
	"""
	_shield_active = false
	_shield_health = 0.0
	
	# 移除视觉效果
	if _shield_visual and is_instance_valid(_shield_visual):
		_shield_visual.queue_free()
		_shield_visual = null
	
	# 断开信号
	if owner_node and "damaged" in owner_node:
		if owner_node.damaged.is_connected(_on_owner_damaged):
			owner_node.damaged.disconnect(_on_owner_damaged)


func _expire_shield() -> void:
	"""
	护盾自然过期
	"""
	shield_expired.emit()
	_remove_shield()


func _break_shield() -> void:
	"""
	护盾破碎
	"""
	# 触发爆炸效果
	_trigger_shatter_explosion()
	
	shield_broken.emit()
	_remove_shield()


func _trigger_shatter_explosion() -> void:
	"""
	触发护盾破碎爆炸
	"""
	if owner_node == null:
		return
	
	var targets: Array[Node] = _get_targets_in_area(
		owner_node.global_position, 
		get_shatter_range()
	)
	
	var damage: float = get_damage()
	for target in targets:
		if target.has_method("take_damage"):
			target.take_damage(damage, owner_node)
	
	# 创建爆炸视觉效果
	_create_shatter_visual()


# =============================================================================
# 视觉效果
# =============================================================================

func _create_shield_visual() -> void:
	"""
	创建护盾视觉效果
	"""
	if owner_node == null:
		return
	
	_shield_visual = Node2D.new()
	_shield_visual.name = "ShieldVisual"
	
	# 创建护盾圆形
	var circle: Node2D = Node2D.new()
	_shield_visual.add_child(circle)
	
	owner_node.add_child(_shield_visual)
	
	# 护盾闪烁动画
	var tween: Tween = owner_node.create_tween()
	tween.set_loops()
	tween.tween_property(_shield_visual, "modulate:a", 0.6, 0.5)
	tween.tween_property(_shield_visual, "modulate:a", 1.0, 0.5)


func _create_shatter_visual() -> void:
	"""
	创建护盾破碎视觉效果
	"""
	if owner_node == null:
		return
	
	# 创建爆炸效果
	var explosion: Node2D = Node2D.new()
	explosion.modulate = Color(0.5, 0.7, 1.0, 1.0)
	owner_node.add_child(explosion)
	
	# 淡出并移除
	var tween: Tween = owner_node.create_tween()
	tween.tween_property(explosion, "modulate:a", 0.0, 0.3)
	tween.tween_callback(explosion.queue_free)


# =============================================================================
# 属性计算
# =============================================================================

func _calculate_shield_health() -> float:
	"""
	计算护盾生命值
	"""
	var base_shield: float = shield_flat_health
	
	# 如果拥有者有属性系统，基于最大生命值计算
	if owner_node and "stats" in owner_node:
		var stats: PlayerStats = owner_node.stats
		if stats:
			base_shield += stats.max_health * shield_health_percent
	
	return base_shield


func get_shield_duration() -> float:
	"""
	获取护盾持续时间（受等级影响）
	"""
	return shield_duration * (1.0 + (current_level - 1) * 0.25)


func get_shatter_range() -> float:
	"""
	获取破碎爆炸范围（受等级影响）
	"""
	return shatter_range * (1.0 + (current_level - 1) * 0.2)


# =============================================================================
# 公共方法
# =============================================================================

func absorb_damage(amount: float) -> float:
	"""
	吸收伤害
	@param amount: 原始伤害
	@return: 剩余伤害（护盾吸收后）
	"""
	if not _shield_active or _shield_health <= 0:
		return amount
	
	var absorbed: float = minf(_shield_health, amount)
	_shield_health -= absorbed
	
	# 更新视觉效果
	_update_shield_visual()
	
	return amount - absorbed


func get_shield_health() -> float:
	"""
	获取当前护盾生命值
	"""
	return _shield_health


func get_shield_percent() -> float:
	"""
	获取护盾百分比
	"""
	if _shield_max_health <= 0:
		return 0.0
	return _shield_health / _shield_max_health


func is_shield_active() -> bool:
	"""
	护盾是否激活
	"""
	return _shield_active


# =============================================================================
# 内部方法
# =============================================================================

func _update_shield_visual() -> void:
	"""
	更新护盾视觉效果
	"""
	if _shield_visual == null:
		return
	
	# 根据护盾百分比调整透明度
	var percent: float = get_shield_percent()
	_shield_visual.modulate.a = 0.3 + percent * 0.7


# =============================================================================
# 信号回调
# =============================================================================

func _on_owner_damaged(amount: float, source: Node) -> void:
	"""
	持有者受到伤害时
	"""
	if _shield_active and _shield_health > 0:
		absorb_damage(amount)


# =============================================================================
# 升级效果
# =============================================================================

func _on_level_up(new_level: int) -> void:
	"""
	升级时增强护盾
	"""
	match new_level:
		2:
			shield_health_percent = 0.4
			shield_flat_health = 70.0
		3:
			shield_health_percent = 0.5
			shield_flat_health = 100.0
			shatter_damage = 35.0
