## Void Hunter - 治愈光环技能
## @description: 持续恢复生命
## @author: Void Hunter Team
## @version: 1.0.0

extends SkillBase
class_name SkillHealingAura

# =============================================================================
# 信号
# =============================================================================

signal heal_triggered(amount: float)
signal aura_activated()
signal aura_deactivated()

# =============================================================================
# 配置参数
# =============================================================================

## 每秒治疗量
@export var heal_per_second: float = 5.0

## 光环范围
@export var aura_radius: float = 100.0

## 是否只治疗自己
@export var self_only: bool = true

## 治疗间隔
@export var heal_interval: float = 1.0

## 激活时立即治疗一次
@export var heal_on_activate: bool = true

# =============================================================================
# 内部变量
# =============================================================================

var _is_active: bool = false
var _heal_timer: float = 0.0
var _aura_visual: Node2D = null

# =============================================================================
# 初始化
# =============================================================================

func _init() -> void:
	skill_id = "healing_aura"
	skill_name = "治愈光环"
	description = "激活治愈光环，持续恢复生命值。"
	skill_type = SkillType.PASSIVE  # 被动技能
	skill_category = SkillCategory.SUPPORT
	target_type = TargetType.SELF
	element = SkillElement.HOLY
	hotkey_slot = 0
	
	base_damage = 0.0
	base_cooldown = 0.0
	base_mana_cost = 0.0
	effect_range = aura_radius
	duration = 0.0


func initialize(owner: Node) -> void:
	super.initialize(owner)
	_is_active = false


func update(delta: float) -> void:
	super.update(delta)
	
	if _is_active:
		_heal_timer += delta
		
		if _heal_timer >= heal_interval:
			_heal_timer = 0.0
			_apply_heal()


# =============================================================================
# 技能效果
# =============================================================================

func _on_passive_activate() -> void:
	"""
	被动技能激活时
	"""
	_activate_aura()


func _on_passive_deactivate() -> void:
	"""
	被动技能停用时
	"""
	_deactivate_aura()


func _activate_aura() -> void:
	"""
	激活治愈光环
	"""
	_is_active = true
	_heal_timer = 0.0
	
	# 创建视觉效果
	_create_aura_visual()
	
	# 激活时立即治疗
	if heal_on_activate:
		_apply_heal()
	
	aura_activated.emit()


func _deactivate_aura() -> void:
	"""
	停用治愈光环
	"""
	_is_active = false
	
	# 移除视觉效果
	if _aura_visual and is_instance_valid(_aura_visual):
		_aura_visual.queue_free()
		_aura_visual = null
	
	aura_deactivated.emit()


func _apply_heal() -> void:
	"""
	应用治疗效果
	"""
	if owner_node == null:
		return
	
	var heal_amount: float = get_heal_amount()
	
	if self_only:
		# 只治疗自己
		if owner_node.has_method("heal"):
			owner_node.heal(heal_amount)
		elif "stats" in owner_node:
			var stats: PlayerStats = owner_node.stats
			if stats:
				stats.heal(heal_amount)
	else:
		# 治疗范围内所有友方单位
		var allies: Array[Node] = _get_allies_in_range()
		var heal_per_ally: float = heal_amount / maxf(1, allies.size())
		
		for ally in allies:
			if ally.has_method("heal"):
				ally.heal(heal_per_ally)
			elif "stats" in ally:
				var stats: PlayerStats = ally.stats
				if stats:
					stats.heal(heal_per_ally)
	
	heal_triggered.emit(heal_amount)


func _get_allies_in_range() -> Array[Node]:
	"""
	获取范围内的友方单位
	"""
	var allies: Array[Node] = []
	
	if owner_node == null:
		return allies
	
	# 自己也算
	allies.append(owner_node)
	
	# TODO: 添加其他友方单位的检测逻辑
	
	return allies


# =============================================================================
# 视觉效果
# =============================================================================

func _create_aura_visual() -> void:
	"""
	创建光环视觉效果
	"""
	if owner_node == null:
		return
	
	_aura_visual = Node2D.new()
	_aura_visual.name = "HealingAuraVisual"
	_aura_visual.modulate = Color(0.2, 1.0, 0.3, 0.3)
	_aura_visual.z_index = -1
	
	owner_node.add_child(_aura_visual)
	
	# 脉冲动画
	var tween: Tween = owner_node.create_tween()
	tween.set_loops()
	tween.tween_property(_aura_visual, "modulate:a", 0.2, 0.5)
	tween.tween_property(_aura_visual, "modulate:a", 0.5, 0.5)


# =============================================================================
# 属性获取
# =============================================================================

func get_heal_amount() -> float:
	"""
	获取治疗量（受等级影响）
	"""
	return heal_per_second * heal_interval * (1.0 + (current_level - 1) * LEVEL_BONUS_PERCENT)


func get_aura_radius() -> float:
	"""
	获取光环范围（受等级影响）
	"""
	return aura_radius * (1.0 + (current_level - 1) * 0.2)


# =============================================================================
# 公共方法
# =============================================================================

func is_aura_active() -> bool:
	"""
	光环是否激活
	"""
	return _is_active


# =============================================================================
# 升级效果
# =============================================================================

func _on_level_up(new_level: int) -> void:
	"""
	升级时增强治愈光环
	"""
	match new_level:
		2:
			heal_per_second = 8.0
			aura_radius = 120.0
		3:
			heal_per_second = 12.0
			aura_radius = 150.0
			# 3级时可以治疗附近友方
			self_only = false
