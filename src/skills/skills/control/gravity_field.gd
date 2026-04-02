## Void Hunter - 引力场技能
## @description: 将敌人吸向中心
## @author: Void Hunter Team
## @version: 1.0.0

extends SkillBase
class_name SkillGravityField

# =============================================================================
# 信号
# =============================================================================

signal gravity_field_created(position: Vector2, radius: float)
signal enemy_pulled(enemy: Node, pull_force: float)
signal gravity_field_expired()

# =============================================================================
# 配置参数
# =============================================================================

## 引力场半径
@export var field_radius: float = 120.0

## 持续时间
@export var field_duration: float = 3.0

## 拉扯力强度
@export var pull_force: float = 200.0

## 中心伤害（每秒）
@export var center_damage_per_second: float = 10.0

## 中心伤害范围
@export var center_damage_radius: float = 40.0

## 减速效果
@export_range(0.0, 1.0) var slow_in_field: float = 0.3

# =============================================================================
# 内部变量
# =============================================================================

var _field_position: Vector2 = Vector2.ZERO
var _duration_timer: float = 0.0
var _is_active: bool = false
var _field_area: Area2D = null
var _visual_effect: Node2D = null
var _affected_enemies: Array[WeakRef] = []

# =============================================================================
# 初始化
# =============================================================================

func _init() -> void:
	skill_id = "gravity_field"
	skill_name = "引力场"
	description = "在目标位置创建引力场，将敌人拉向中心并造成持续伤害。"
	skill_type = SkillType.ACTIVE
	skill_category = SkillCategory.CONTROL
	target_type = TargetType.POSITION
	element = SkillElement.ARCANE
	hotkey_slot = 4

	base_damage = center_damage_per_second
	base_cooldown = 14.0
	base_mana_cost = 35.0
	effect_range = field_radius
	duration = field_duration


func initialize(owner: Node) -> void:
	super.initialize(owner)
	_is_active = false


func update(delta: float) -> void:
	super.update(delta)

	if _is_active:
		_duration_timer -= delta

		# 应用拉扯力和伤害
		_apply_gravity_effects(delta)

		if _duration_timer <= 0:
			_deactivate_gravity_field()


# =============================================================================
# 技能效果
# =============================================================================

func _execute_position_effect(target_position: Variant) -> void:
	"""
	在目标位置创建引力场
	"""
	if target_position == null:
		return

	var pos: Vector2 = target_position if target_position is Vector2 else Vector2.ZERO

	# 如果已有引力场，先移除
	if _is_active:
		_deactivate_gravity_field()

	_create_gravity_field(pos)


func _create_gravity_field(pos: Vector2) -> void:
	"""
	创建引力场
	"""
	_is_active = true
	_field_position = pos
	_duration_timer = get_duration()

	# VFX: 引力场激活爆炸效果
	if VFXManager:
		VFXManager.spawn_effect("explosion_small", pos, {"color": Color(0.5, 0, 0.8)})

	# 创建引力场区域
	_create_field_area()

	# 创建视觉效果
	_create_visual_effect()

	gravity_field_created.emit(pos, get_field_radius())

	AudioManager.play_sfx("gravity_field")


func _deactivate_gravity_field() -> void:
	"""
	停用引力场
	"""
	_is_active = false

	# 移除区域
	if _field_area and is_instance_valid(_field_area):
		_field_area.queue_free()
		_field_area = null

	# 移除视觉效果
	if _visual_effect and is_instance_valid(_visual_effect):
		_visual_effect.queue_free()
		_visual_effect = null

	# 清空受影响列表
	_affected_enemies.clear()

	gravity_field_expired.emit()


func _create_field_area() -> void:
	"""
	创建引力场检测区域
	"""
	if owner_node == null:
		return

	_field_area = Area2D.new()
	_field_area.collision_layer = 0
	_field_area.collision_mask = 2  # Enemy layer

	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = get_field_radius()
	collision.shape = shape
	_field_area.add_child(collision)

	# 连接信号
	_field_area.body_entered.connect(_on_enemy_entered_field)
	_field_area.body_exited.connect(_on_enemy_exited_field)

	# 添加到场景
	owner_node.get_tree().current_scene.add_child(_field_area)
	_field_area.global_position = _field_position


# =============================================================================
# 引力效果
# =============================================================================

func _on_enemy_entered_field(enemy: Node) -> void:
	"""
	敌人进入引力场
	"""
	_affected_enemies.append(weakref(enemy))


func _on_enemy_exited_field(enemy: Node) -> void:
	"""
	敌人离开引力场
	"""
	for i in range(_affected_enemies.size() - 1, -1, -1):
		var ref: WeakRef = _affected_enemies[i]
		var target: Node = ref.get_ref()
		if target == null or target == enemy:
			_affected_enemies.remove_at(i)


func _apply_gravity_effects(delta: float) -> void:
	"""
	应用引力效果（拉扯和伤害）
	"""
	for i in range(_affected_enemies.size() - 1, -1, -1):
		var ref: WeakRef = _affected_enemies[i]
		var enemy: Node = ref.get_ref()

		if enemy == null or not is_instance_valid(enemy):
			_affected_enemies.remove_at(i)
			continue

		# 计算到中心的距离和方向
		var to_center: Vector2 = _field_position - enemy.global_position
		var distance: float = to_center.length()

		if distance <= 5.0:
			continue

		var direction: Vector2 = to_center.normalized()

		# 应用拉扯力（距离越近力越小）
		var pull_multiplier: float = clampf(distance / get_field_radius(), 0.3, 1.0)
		var actual_pull: float = get_pull_force() * pull_multiplier * delta

		# 移动敌人
		if "velocity" in enemy:
			enemy.velocity += direction * actual_pull
		elif "global_position" in enemy:
			enemy.global_position += direction * actual_pull

		# 应用减速
		if "speed_modifier" in enemy:
			enemy.speed_modifier = 1.0 - slow_in_field

		# 中心区域伤害
		if distance <= get_center_damage_radius():
			if enemy.has_method("take_damage"):
				enemy.take_damage(get_damage() * delta, owner_node)

		enemy_pulled.emit(enemy, actual_pull)


# =============================================================================
# 视觉效果
# =============================================================================

func _create_visual_effect() -> void:
	"""
	创建引力场视觉效果
	"""
	if owner_node == null:
		return

	_visual_effect = Node2D.new()
	_visual_effect.name = "GravityFieldVisual"
	_visual_effect.global_position = _field_position
	_visual_effect.modulate = Color(0.5, 0.2, 0.8, 0.5)
	_visual_effect.z_index = -1

	owner_node.get_tree().current_scene.add_child(_visual_effect)

	# 脉冲动画
	var tween: Tween = owner_node.create_tween()
	tween.set_loops()
	tween.tween_property(_visual_effect, "modulate:a", 0.3, 0.5)
	tween.tween_property(_visual_effect, "modulate:a", 0.6, 0.5)


# =============================================================================
# 属性获取
# =============================================================================

func get_field_radius() -> float:
	"""
	获取引力场半径（受等级影响）
	"""
	return field_radius * (1.0 + (current_level - 1) * 0.2)


func get_pull_force() -> float:
	"""
	获取拉扯力（受等级影响）
	"""
	return pull_force * (1.0 + (current_level - 1) * 0.25)


func get_center_damage_radius() -> float:
	"""
	获取中心伤害范围（受等级影响）
	"""
	return center_damage_radius * (1.0 + (current_level - 1) * 0.3)


# =============================================================================
# 公共方法
# =============================================================================

func is_field_active() -> bool:
	"""
	引力场是否激活
	"""
	return _is_active


func get_field_position() -> Vector2:
	"""
	获取引力场位置
	"""
	return _field_position


# =============================================================================
# 升级效果
# =============================================================================

func _on_level_up(new_level: int) -> void:
	"""
	升级时增强引力场
	"""
	match new_level:
		2:
			pull_force = 250.0
			field_radius = 150.0
			center_damage_per_second = 15.0
		3:
			pull_force = 300.0
			field_radius = 180.0
			center_damage_per_second = 25.0
			center_damage_radius = 60.0
			slow_in_field = 0.5
