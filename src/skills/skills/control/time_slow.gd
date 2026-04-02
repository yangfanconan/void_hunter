## Void Hunter - 时间减缓技能
## @description: 减缓周围敌人速度
## @author: Void Hunter Team
## @version: 1.0.0

extends SkillBase
class_name SkillTimeSlow

# =============================================================================
# 信号
# =============================================================================

signal time_slow_activated()
signal time_slow_deactivated()
signal enemy_slowed(enemy: Node, slow_amount: float)

# =============================================================================
# 配置参数
# =============================================================================

## 减速百分比
@export_range(0.0, 1.0) var slow_percent: float = 0.5

## 效果范围
@export var slow_radius: float = 150.0

## 持续时间
@export var slow_duration: float = 4.0

## 攻击速度减缓
@export_range(0.0, 1.0) var attack_speed_slow: float = 0.3

## 是否冻结新进入范围的敌人
@export var affect_new_targets: bool = true

# =============================================================================
# 内部变量
# =============================================================================

var _is_active: bool = false
var _duration_timer: float = 0.0
var _affected_enemies: Array[Node] = []
var _slow_area: Area2D = null
var _visual_effect: Node2D = null

# =============================================================================
# 初始化
# =============================================================================

func _init() -> void:
	skill_id = "time_slow"
	skill_name = "时间减缓"
	description = "减缓周围敌人的移动速度和攻击速度。"
	skill_type = SkillType.ACTIVE
	skill_category = SkillCategory.CONTROL
	target_type = TargetType.SELF
	element = SkillElement.ARCANE
	hotkey_slot = 4

	base_damage = 0.0
	base_cooldown = 18.0
	base_mana_cost = 40.0
	effect_range = slow_radius
	duration = slow_duration


func initialize(owner: Node) -> void:
	super.initialize(owner)
	_is_active = false
	_affected_enemies.clear()


func update(delta: float) -> void:
	super.update(delta)

	if _is_active:
		_duration_timer -= delta

		# 更新减速区域位置
		if _slow_area and is_instance_valid(_slow_area):
			_slow_area.global_position = owner_node.global_position

		# 更新视觉效果位置
		if _visual_effect and is_instance_valid(_visual_effect):
			_visual_effect.global_position = owner_node.global_position

		if _duration_timer <= 0:
			_deactivate_time_slow()


# =============================================================================
# 技能效果
# =============================================================================

func _execute_self_effect() -> void:
	"""
	激活时间减缓
	"""
	if _is_active:
		# 刷新持续时间
		_duration_timer = get_duration()
		return

	_activate_time_slow()


func _activate_time_slow() -> void:
	"""
	激活时间减缓效果
	"""
	_is_active = true
	_duration_timer = get_duration()

	# 创建减速区域
	_create_slow_area()

	# 创建视觉效果
	_create_visual_effect()

	time_slow_activated.emit()

	AudioManager.play_sfx("time_slow")


func _deactivate_time_slow() -> void:
	"""
	停用时间减缓
	"""
	_is_active = false

	# 移除所有敌人的减速效果
	_remove_all_slow_effects()

	# 移除减速区域
	if _slow_area and is_instance_valid(_slow_area):
		_slow_area.queue_free()
		_slow_area = null

	# 移除视觉效果
	if _visual_effect and is_instance_valid(_visual_effect):
		_visual_effect.queue_free()
		_visual_effect = null

	time_slow_deactivated.emit()


func _create_slow_area() -> void:
	"""
	创建减速检测区域
	"""
	if owner_node == null:
		return

	_slow_area = Area2D.new()
	_slow_area.collision_layer = 0
	_slow_area.collision_mask = 2  # Enemy layer

	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = get_slow_radius()
	collision.shape = shape
	_slow_area.add_child(collision)

	# 连接信号
	_slow_area.body_entered.connect(_on_enemy_entered)
	_slow_area.body_exited.connect(_on_enemy_exited)

	# 添加到场景
	owner_node.get_tree().current_scene.add_child(_slow_area)
	_slow_area.global_position = owner_node.global_position


# =============================================================================
# 减速逻辑
# =============================================================================

func _on_enemy_entered(enemy: Node) -> void:
	"""
	敌人进入减速范围
	"""
	if not _is_active:
		return

	if not affect_new_targets:
		return

	_apply_slow_to_enemy(enemy)


func _on_enemy_exited(enemy: Node) -> void:
	"""
	敌人离开减速范围
	"""
	_remove_slow_from_enemy(enemy)


func _apply_slow_to_enemy(enemy: Node) -> void:
	"""
	对敌人应用减速效果
	"""
	if enemy == null or not is_instance_valid(enemy):
		return

	# 应用移动速度减缓
	if "speed_modifier" in enemy:
		enemy.speed_modifier = 1.0 - get_slow_percent()
	elif "move_speed" in enemy:
		enemy.set_meta("original_speed", enemy.move_speed)
		enemy.move_speed *= (1.0 - get_slow_percent())

	# 应用攻击速度减缓
	if "attack_speed_modifier" in enemy:
		enemy.attack_speed_modifier = 1.0 - attack_speed_slow

	# VFX: 减速冻结效果
	if VFXManager:
		VFXManager.spawn_status_vfx(enemy.global_position, "freeze")

	# 添加到受影响列表
	if enemy not in _affected_enemies:
		_affected_enemies.append(enemy)

	enemy_slowed.emit(enemy, get_slow_percent())


func _remove_slow_from_enemy(enemy: Node) -> void:
	"""
	移除敌人的减速效果
	"""
	if enemy == null or not is_instance_valid(enemy):
		return

	# 恢复移动速度
	if "speed_modifier" in enemy:
		enemy.speed_modifier = 1.0
	elif enemy.has_meta("original_speed") and "move_speed" in enemy:
		enemy.move_speed = enemy.get_meta("original_speed")
		enemy.remove_meta("original_speed")

	# 恢复攻击速度
	if "attack_speed_modifier" in enemy:
		enemy.attack_speed_modifier = 1.0

	# 从受影响列表移除
	if enemy in _affected_enemies:
		_affected_enemies.erase(enemy)


func _remove_all_slow_effects() -> void:
	"""
	移除所有减速效果
	"""
	for enemy in _affected_enemies:
		if is_instance_valid(enemy):
			_remove_slow_from_enemy(enemy)

	_affected_enemies.clear()


# =============================================================================
# 视觉效果
# =============================================================================

func _create_visual_effect() -> void:
	"""
	创建时间减缓视觉效果
	"""
	if owner_node == null:
		return

	_visual_effect = Node2D.new()
	_visual_effect.name = "TimeSlowVisual"
	_visual_effect.modulate = Color(0.3, 0.5, 1.0, 0.4)
	_visual_effect.z_index = -1

	owner_node.get_tree().current_scene.add_child(_visual_effect)
	_visual_effect.global_position = owner_node.global_position


# =============================================================================
# 属性获取
# =============================================================================

func get_slow_percent() -> float:
	"""
	获取减速百分比（受等级影响）
	"""
	return slow_percent + (current_level - 1) * 0.1


func get_slow_radius() -> float:
	"""
	获取减速范围（受等级影响）
	"""
	return slow_radius * (1.0 + (current_level - 1) * 0.2)


# =============================================================================
# 公共方法
# =============================================================================

func is_time_slow_active() -> bool:
	"""
	时间减缓是否激活
	"""
	return _is_active


func get_affected_count() -> int:
	"""
	获取受影响的敌人数量
	"""
	return _affected_enemies.size()


# =============================================================================
# 升级效果
# =============================================================================

func _on_level_up(new_level: int) -> void:
	"""
	升级时增强时间减缓
	"""
	match new_level:
		2:
			slow_percent = 0.6
			slow_radius = 180.0
			attack_speed_slow = 0.4
		3:
			slow_percent = 0.7
			slow_radius = 220.0
			attack_speed_slow = 0.5
			# 3级时对范围内敌人造成少量伤害
			base_damage = 5.0
