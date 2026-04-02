## Void Hunter - 加速光环技能
## @description: 提升移动和攻击速度
## @author: Void Hunter Team
## @version: 1.0.0

extends SkillBase
class_name SkillSpeedAura

# =============================================================================
# 信号
# =============================================================================

signal speed_boost_applied(movement_bonus: float, attack_bonus: float)
signal aura_activated()
signal aura_deactivated()

# =============================================================================
# 配置参数
# =============================================================================

## 移动速度加成
@export_range(0.0, 1.0) var movement_speed_bonus: float = 0.2

## 攻击速度加成
@export_range(0.0, 1.0) var attack_speed_bonus: float = 0.15

## 光环范围
@export var aura_radius: float = 120.0

## 冷却缩减加成
@export_range(0.0, 1.0) var cooldown_reduction: float = 0.0

## 是否影响附近友方
@export var affect_allies: bool = false

# =============================================================================
# 内部变量
# =============================================================================

var _is_active: bool = false
var _aura_visual: Node2D = null
var _original_speed_bonus: float = 0.0
var _affected_allies: Array[Node] = []

# =============================================================================
# 初始化
# =============================================================================

func _init() -> void:
	skill_id = "speed_aura"
	skill_name = "加速光环"
	description = "激活加速光环，提升移动速度和攻击速度。"
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
	激活加速光环
	"""
	_is_active = true

	# VFX: 加速光环激活拖尾效果
	if VFXManager:
		VFXManager.spawn_dash_trail(owner_node.global_position)

	# 应用属性加成
	_apply_speed_bonuses()

	# 创建视觉效果
	_create_aura_visual()

	aura_activated.emit()
	speed_boost_applied.emit(get_movement_bonus(), get_attack_bonus())


func _deactivate_aura() -> void:
	"""
	停用加速光环
	"""
	_is_active = false

	# 移除属性加成
	_remove_speed_bonuses()

	# 移除视觉效果
	if _aura_visual and is_instance_valid(_aura_visual):
		_aura_visual.queue_free()
		_aura_visual = null

	aura_deactivated.emit()


func _apply_speed_bonuses() -> void:
	"""
	应用速度加成
	"""
	if owner_node == null:
		return

	# 应用移动速度加成
	if "stats" in owner_node:
		var stats: PlayerStats = owner_node.stats
		if stats:
			_original_speed_bonus = stats.speed_bonus_percent
			stats.speed_bonus_percent += get_movement_bonus()

	# 如果影响友方
	if affect_allies:
		_apply_to_allies()


func _remove_speed_bonuses() -> void:
	"""
	移除速度加成
	"""
	if owner_node == null:
		return

	# 恢复移动速度
	if "stats" in owner_node:
		var stats: PlayerStats = owner_node.stats
		if stats:
			stats.speed_bonus_percent = _original_speed_bonus

	# 移除友方加成
	if affect_allies:
		_remove_from_allies()


func _apply_to_allies() -> void:
	"""对友方应用加成"""
	_affected_allies.clear()
	var allies := _get_allies_in_range()
	for ally in allies:
		if ally == owner_node:
			continue
		if "stats" in ally:
			var ally_stats = ally.stats
			if ally_stats and "speed_bonus_percent" in ally_stats:
				ally_stats.speed_bonus_percent += get_movement_bonus()
				_affected_allies.append(ally)


func _remove_from_allies() -> void:
	"""移除友方加成"""
	for ally in _affected_allies:
		if is_instance_valid(ally) and "stats" in ally:
			var ally_stats = ally.stats
			if ally_stats and "speed_bonus_percent" in ally_stats:
				ally_stats.speed_bonus_percent -= get_movement_bonus()
	_affected_allies.clear()


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
	_aura_visual.name = "SpeedAuraVisual"
	_aura_visual.modulate = Color(1.0, 0.8, 0.2, 0.3)
	_aura_visual.z_index = -1

	owner_node.add_child(_aura_visual)

	# 快速脉冲动画
	var tween: Tween = owner_node.create_tween()
	tween.set_loops()
	tween.tween_property(_aura_visual, "modulate:a", 0.2, 0.3)
	tween.tween_property(_aura_visual, "modulate:a", 0.4, 0.3)


# =============================================================================
# 属性获取
# =============================================================================

func get_movement_bonus() -> float:
	"""
	获取移动速度加成（受等级影响）
	"""
	return movement_speed_bonus + (current_level - 1) * 0.1


func get_attack_bonus() -> float:
	"""
	获取攻击速度加成（受等级影响）
	"""
	return attack_speed_bonus + (current_level - 1) * 0.08


func get_cooldown_reduction() -> float:
	"""
	获取冷却缩减（受等级影响）
	"""
	return cooldown_reduction + (current_level - 1) * 0.05


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


func get_total_speed_multiplier() -> float:
	"""
	获取总速度倍率
	"""
	return 1.0 + get_movement_bonus()


# =============================================================================
# 升级效果
# =============================================================================

func _on_level_up(new_level: int) -> void:
	"""
	升级时增强加速光环
	"""
	match new_level:
		2:
			movement_speed_bonus = 0.3
			attack_speed_bonus = 0.25
			aura_radius = 150.0
		3:
			movement_speed_bonus = 0.4
			attack_speed_bonus = 0.35
			aura_radius = 180.0
			cooldown_reduction = 0.15
			affect_allies = true



func _get_allies_in_range() -> Array[Node]:
	"""获取范围内的友方单位"""
	var allies: Array[Node] = []
	if owner_node == null:
		return allies
	var bodies: Array = owner_node.get_tree().get_nodes_in_group("allies")
	for body in bodies:
		if body == owner_node:
			continue
		if owner_node.global_position.distance_to(body.global_position) <= get_aura_radius():
			allies.append(body)
	return allies
