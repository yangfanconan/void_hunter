## Void Hunter - 激光束技能
## @description: 发射一道直线激光，穿透所有敌人并造成持续伤害
## @author: Void Hunter Team
## @version: 1.0.0

extends SkillBase
class_name SkillLaserBeam

# =============================================================================
# 配置参数
# =============================================================================

## 激光宽度
@export var beam_width: float = 30.0

## 激光长度
@export var beam_length: float = 800.0

## 持续时间
@export var beam_duration: float = 1.5

## 伤害间隔
@export var damage_interval: float = 0.1

## 是否穿透
@export var pierce: bool = true

# =============================================================================
# 内部变量
# =============================================================================

var _beam_instance: Node2D = null
var _damage_timer: float = 0.0
var _is_firing: bool = false
var _beam_direction: Vector2 = Vector2.RIGHT

# =============================================================================
# 初始化
# =============================================================================

func _init() -> void:
	skill_id = "laser_beam"
	skill_name = "激光束"
	description = "发射一道高能激光束，穿透敌人并造成持续伤害。"
	skill_type = SkillType.ACTIVE
	skill_category = SkillCategory.OFFENSIVE
	target_type = TargetType.DIRECTION
	element = SkillElement.ARCANE
	hotkey_slot = 3

	base_damage = 8.0  # 每次tick的伤害
	base_cooldown = 5.0
	base_mana_cost = 35.0
	effect_range = beam_width
	duration = beam_duration
	projectile_speed = 0.0  # 激光是瞬时的


func update(delta: float) -> void:
	super.update(delta)

	# 更新激光
	if _is_firing and _beam_instance:
		_update_beam(delta)


# =============================================================================
# 技能效果
# =============================================================================

func _execute_direction_effect(direction: Variant) -> void:
	"""
	执行激光束效果
	"""
	if owner_node == null:
		return

	var dir: Vector2 = Vector2.RIGHT
	if direction is Vector2:
		dir = direction.normalized()

	_beam_direction = dir
	_is_firing = true
	_damage_timer = 0.0

	# 创建激光
	_create_laser_beam(dir)

	# 播放音效
	AudioManager.play_sfx("laser_beam")


func _create_laser_beam(direction: Vector2) -> void:
	"""
	创建激光束视觉效果
	"""
	if owner_node == null:
		return

	# 创建激光容器
	_beam_instance = Node2D.new()
	_beam_instance.name = "LaserBeam"

	# 创建激光视觉效果（使用Line2D）
	var laser_line: Line2D = Line2D.new()
	laser_line.name = "LaserLine"
	laser_line.width = get_beam_width()
	laser_line.default_color = Color(0.2, 0.8, 1.0, 0.8)  # 青色激光
	laser_line.z_index = 10

	# 添加发光效果
	laser_line.add_point(Vector2.ZERO)
	laser_line.add_point(Vector2(get_beam_length(), 0))

	# 设置材质
	var material: CanvasItemMaterial = CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	laser_line.material = material

	_beam_instance.add_child(laser_line)

	# 创建核心激光（更细更亮）
	var core_line: Line2D = Line2D.new()
	core_line.name = "CoreLine"
	core_line.width = get_beam_width() * 0.3
	core_line.default_color = Color(1.0, 1.0, 1.0, 1.0)  # 白色核心
	core_line.z_index = 11
	core_line.add_point(Vector2.ZERO)
	core_line.add_point(Vector2(get_beam_length(), 0))

	_beam_instance.add_child(core_line)

	# 设置位置和旋转
	_beam_instance.global_position = owner_node.global_position
	_beam_instance.rotation = direction.angle()

	# 添加到场景
	owner_node.get_tree().current_scene.add_child(_beam_instance)

	# 设置持续时间后自动销毁
	_schedule_beam_end()


func _schedule_beam_end() -> void:
	"""
	设置激光结束计时器
	"""
	await owner_node.get_tree().create_timer(get_beam_duration()).timeout
	_end_beam()


func _update_beam(delta: float) -> void:
	"""
	更新激光状态
	"""
	if not _is_firing or _beam_instance == null or owner_node == null:
		return

	# 更新激光位置跟随玩家
	_beam_instance.global_position = owner_node.global_position

	# 伤害计时
	_damage_timer += delta
	if _damage_timer >= damage_interval:
		_damage_timer = 0.0
		_apply_beam_damage()


func _apply_beam_damage() -> void:
	"""
	应用激光伤害
	"""
	if owner_node == null:
		return

	# 获取激光路径上的所有敌人
	var targets: Array[Node] = _get_targets_in_beam_path()

	for target in targets:
		if target.has_method("take_damage"):
			target.take_damage(get_damage(), owner_node)
			skill_hit.emit(self, target, get_damage())

			# VFX: laser hit spark
			if VFXManager:
				VFXManager.spawn_effect("hit_spark", target.global_position)


func _get_targets_in_beam_path() -> Array[Node]:
	"""
	获取激光路径上的目标
	"""
	var targets: Array[Node] = []

	if owner_node == null:
		return targets

	var space_state: PhysicsDirectSpaceState2D = owner_node.get_world_2d().direct_space_state

	# 使用射线检测
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.new()
	query.from = owner_node.global_position
	query.to = owner_node.global_position + _beam_direction * get_beam_length()
	query.collision_mask = 2  # Enemy layer

	# 检测多个目标
	var shape_query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(get_beam_length(), get_beam_width())
	shape_query.shape = shape

	# 计算矩形中心位置
	var rect_center: Vector2 = owner_node.global_position + _beam_direction * get_beam_length() / 2
	shape_query.transform = Transform2D(_beam_direction.angle(), rect_center)
	shape_query.collision_mask = 2

	var results: Array[Dictionary] = space_state.intersect_shape(shape_query, 32)

	for result in results:
		var collider: Node = result.get("collider")
		if collider and collider.has_method("take_damage"):
			targets.append(collider)

	return targets


func _end_beam() -> void:
	"""
	结束激光
	"""
	_is_firing = false

	if _beam_instance and is_instance_valid(_beam_instance):
		# 淡出效果
		var tween: Tween = owner_node.create_tween()
		tween.tween_property(_beam_instance, "modulate:a", 0.0, 0.2)
		tween.tween_callback(_beam_instance.queue_free)

	_beam_instance = null


# =============================================================================
# 属性获取
# =============================================================================

func get_beam_width() -> float:
	"""
	获取激光宽度（受等级影响）
	"""
	return beam_width * (1.0 + (current_level - 1) * 0.2)


func get_beam_length() -> float:
	"""
	获取激光长度（受等级影响）
	"""
	return beam_length * (1.0 + (current_level - 1) * 0.15)


func get_beam_duration() -> float:
	"""
	获取激光持续时间（受等级影响）
	"""
	return beam_duration * (1.0 + (current_level - 1) * 0.25)


# =============================================================================
# 升级效果
# =============================================================================

func _on_level_up(new_level: int) -> void:
	"""
	升级时增强激光束
	"""
	match new_level:
		2:
			base_damage = 12.0
			damage_interval = 0.08
		3:
			base_damage = 18.0
			beam_duration = 2.0
