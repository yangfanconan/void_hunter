## Void Hunter - 反射技能
## @description: 反弹敌人子弹
## @author: Void Hunter Team
## @version: 1.0.0

extends SkillBase
class_name SkillReflect

# =============================================================================
# 信号
# =============================================================================

signal projectile_reflected(projectile: Node, damage: float)
signal reflect_activated()
signal reflect_deactivated()

# =============================================================================
# 配置参数
# =============================================================================

## 反射持续时间
@export var reflect_duration: float = 3.0

## 反射伤害倍率
@export var reflect_damage_multiplier: float = 0.8

## 反射范围
@export var reflect_range: float = 60.0

## 最大反射次数（0为无限）
@export var max_reflects: int = 0

## 反射后子弹速度倍率
@export var reflected_speed_multiplier: float = 1.2

# =============================================================================
# 内部变量
# =============================================================================

var _is_active: bool = false
var _duration_timer: float = 0.0
var _reflect_count: int = 0
var _reflect_area: Area2D = null

# =============================================================================
# 初始化
# =============================================================================

func _init() -> void:
	skill_id = "reflect"
	skill_name = "反射"
	description = "激活反射护盾，反弹敌人的投射物攻击。"
	skill_type = SkillType.ACTIVE
	skill_category = SkillCategory.DEFENSIVE
	target_type = TargetType.SELF
	element = SkillElement.ARCANE
	hotkey_slot = 4

	base_cooldown = 12.0
	base_mana_cost = 25.0
	duration = reflect_duration
	effect_range = reflect_range


func initialize(owner: Node) -> void:
	super.initialize(owner)
	_is_active = false


func update(delta: float) -> void:
	super.update(delta)

	if _is_active:
		_duration_timer -= delta

		if _duration_timer <= 0:
			_deactivate_reflect()

		# 更新反射区域位置
		if _reflect_area and is_instance_valid(_reflect_area):
			_reflect_area.global_position = owner_node.global_position


# =============================================================================
# 技能效果
# =============================================================================

func _execute_self_effect() -> void:
	"""
	激活反射
	"""
	if _is_active:
		# 刷新持续时间
		_duration_timer = get_duration()
		return

	_activate_reflect()


func _activate_reflect() -> void:
	"""
	激活反射护盾
	"""
	_is_active = true
	_duration_timer = get_duration()
	_reflect_count = 0

	# VFX: 反射护盾激活脉冲效果
	if VFXManager:
		VFXManager.spawn_effect("shield_pulse", owner_node.global_position, {"color": Color(1, 0.8, 0.2)})

	# 创建反射区域
	_create_reflect_area()

	# 创建视觉效果
	_create_reflect_visual()

	reflect_activated.emit()

	AudioManager.play_sfx("reflect_on")


func _deactivate_reflect() -> void:
	"""
	停用反射护盾
	"""
	_is_active = false

	# 移除反射区域
	if _reflect_area and is_instance_valid(_reflect_area):
		_reflect_area.queue_free()
		_reflect_area = null

	reflect_deactivated.emit()


func _create_reflect_area() -> void:
	"""
	创建反射检测区域
	"""
	if owner_node == null:
		return

	_reflect_area = Area2D.new()
	_reflect_area.collision_layer = 0
	_reflect_area.collision_mask = 4  # Enemy projectile layer

	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = get_reflect_range()
	collision.shape = shape
	_reflect_area.add_child(collision)

	# 连接信号
	_reflect_area.area_entered.connect(_on_projectile_entered)

	# 添加到场景
	owner_node.get_tree().current_scene.add_child(_reflect_area)
	_reflect_area.global_position = owner_node.global_position


# =============================================================================
# 反射逻辑
# =============================================================================

func _on_projectile_entered(projectile: Node) -> void:
	"""
	投射物进入反射范围
	"""
	if not _is_active:
		return

	# 检查反射次数限制
	if max_reflects > 0 and _reflect_count >= max_reflects:
		return

	# 检查是否是敌方投射物
	if not _is_enemy_projectile(projectile):
		return

	# 反弹投射物
	_reflect_projectile(projectile)
	_reflect_count += 1


func _is_enemy_projectile(projectile: Node) -> bool:
	"""
	检查是否是敌方投射物
	"""
	# 检查投射物是否有owner属性，且不是玩家
	if "owner" in projectile:
		return projectile.owner != owner_node
	return true


func _reflect_projectile(projectile: Node) -> void:
	"""
	反弹投射物
	"""
	# 获取投射物信息
	var original_damage: float = 0.0
	var original_speed: float = 300.0
	var direction: Vector2 = Vector2.RIGHT

	if "damage" in projectile:
		original_damage = projectile.damage
	if "speed" in projectile:
		original_speed = projectile.speed
	if "direction" in projectile:
		direction = -projectile.direction  # 反转方向
	elif "velocity" in projectile:
		direction = -projectile.velocity.normalized()

	# 计算反射伤害
	var reflected_damage: float = original_damage * get_reflect_damage_multiplier()

	# 修改投射物属性
	if "damage" in projectile:
		projectile.damage = reflected_damage
	if "speed" in projectile:
		projectile.speed = original_speed * reflected_speed_multiplier
	if "direction" in projectile:
		projectile.direction = direction
	if "velocity" in projectile:
		projectile.velocity = direction * original_speed * reflected_speed_multiplier

	# 修改归属
	if "owner" in projectile:
		projectile.owner = owner_node

	# 修改碰撞层（从敌人投射物变为玩家投射物）
	if "collision_layer" in projectile:
		projectile.collision_layer = 16  # Player projectile layer
	if "collision_mask" in projectile:
		projectile.collision_mask = 2  # Target enemies

	# 视觉效果
	_create_reflect_effect(projectile.global_position)

	# 发送信号
	projectile_reflected.emit(projectile, reflected_damage)

	AudioManager.play_sfx("reflect")


# =============================================================================
# 视觉效果
# =============================================================================

func _create_reflect_visual() -> void:
	"""
	创建反射护盾视觉效果
	"""
	if owner_node == null:
		return

	var visual: Node2D = Node2D.new()
	visual.name = "ReflectVisual"
	owner_node.add_child(visual)

	# 循环动画
	var tween: Tween = owner_node.create_tween()
	tween.set_loops()
	tween.tween_property(visual, "modulate:a", 0.5, 0.3)
	tween.tween_property(visual, "modulate:a", 1.0, 0.3)

	# 持续时间结束后移除
	await owner_node.get_tree().create_timer(get_duration()).timeout

	if is_instance_valid(visual):
		visual.queue_free()


func _create_reflect_effect(pos: Vector2) -> void:
	"""
	创建反弹效果
	"""
	if owner_node == null:
		return

	var effect: Node2D = Node2D.new()
	effect.global_position = pos
	effect.modulate = Color(0.3, 0.6, 1.0, 1.0)

	owner_node.get_tree().current_scene.add_child(effect)

	var tween: Tween = owner_node.create_tween()
	tween.tween_property(effect, "modulate:a", 0.0, 0.2)
	tween.tween_callback(effect.queue_free)


# =============================================================================
# 属性获取
# =============================================================================

func get_reflect_damage_multiplier() -> float:
	"""
	获取反射伤害倍率（受等级影响）
	"""
	return reflect_damage_multiplier + (current_level - 1) * 0.2


func get_reflect_range() -> float:
	"""
	获取反射范围（受等级影响）
	"""
	return reflect_range * (1.0 + (current_level - 1) * 0.25)


# =============================================================================
# 公共方法
# =============================================================================

func is_reflect_active() -> bool:
	"""
	反射是否激活
	"""
	return _is_active


# =============================================================================
# 升级效果
# =============================================================================

func _on_level_up(new_level: int) -> void:
	"""
	升级时增强反射
	"""
	match new_level:
		2:
			reflect_damage_multiplier = 1.0
			reflect_range = 80.0
		3:
			reflect_damage_multiplier = 1.2
			reflect_range = 100.0
			max_reflects = 10
			reflected_speed_multiplier = 1.5
