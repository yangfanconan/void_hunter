## Void Hunter - 虚空裂隙
## @description: 在目标位置创建虚空裂隙，持续造成伤害并减速敌人
## @version: 1.0.0

extends "res://src/skills/skill_base.gd"

# =============================================================================
# 导出变量
# =============================================================================

## 裂隙持续时间
@export var rift_duration: float = 4.0

## 裂隙半径
@export var rift_radius: float = 80.0

## 每秒伤害次数
@export var damage_ticks_per_second: int = 3

## 减速比例
@export var slow_amount: float = 0.4

## 减速持续时间
@export var slow_duration: float = 0.5

## 牵引力度（将敌人拉向裂隙中心）
@export var pull_strength: float = 50.0

# =============================================================================
# 初始化
# =============================================================================

func _init() -> void:
	skill_id = "void_rift"
	skill_name = "虚空裂隙"
	description = "在目标位置创建虚空裂隙，持续造成伤害并牵引、减速敌人"
	skill_type = SkillBase.SkillType.ACTIVE
	skill_category = SkillBase.SkillCategory.CONTROL
	element = SkillBase.SkillElement.ARCANE
	target_type = SkillBase.TargetType.POSITION
	base_damage = 15.0
	effect_range = rift_radius
	duration = rift_duration
	base_cooldown = 8.0
	base_mana_cost = 35.0

# =============================================================================
# 技能执行
# =============================================================================

func _execute_position_effect(target_position: Variant) -> void:
	"""在目标位置创建虚空裂隙"""
	if target_position == null:
		if owner_node:
			target_position = owner_node.global_position + Vector2(100, 0)
		else:
			return

	var pos: Vector2 = target_position as Vector2

	# 创建裂隙节点
	var rift = _create_rift(pos)
	owner_node.get_tree().current_scene.add_child(rift)

	# 应用裂隙效果
	_apply_rift_effects(rift)

func _create_rift(position: Vector2) -> Node2D:
	"""创建虚空裂隙视觉节点"""
	var rift = Area2D.new()
	rift.name = "VoidRift"
	rift.collision_layer = 0
	rift.collision_mask = 2  # Enemies layer

	# 碰撞区域
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = rift_radius * (1.0 + (current_level - 1) * 0.15)
	collision.shape = shape
	rift.add_child(collision)

	# 视觉效果 - 紫色漩涡
	var visual = _create_rift_visual()
	visual.position = Vector2.ZERO
	rift.add_child(visual)

	rift.global_position = position
	rift.set_script(_create_rift_script())

	return rift

func _create_rift_visual() -> Node2D:
	"""创建裂隙视觉效果"""
	var visual = Node2D.new()
	visual.name = "RiftVisual"

	# 中心黑色圆
	var center = Sprite2D.new()
	var tex = ImageTexture.new()
	var img = Image.create(40, 40, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.1, 0.05, 0.15, 0.9))
	tex.set_image(img)
	center.texture = tex
	center.centered = true
	visual.add_child(center)

	# 外圈紫色光环
	var ring = Line2D.new()
	ring.width = 3.0
	ring.default_color = Color(0.6, 0.3, 0.9, 0.7)
	var points: Array[Vector2] = []
	var radius: float = rift_radius
	for i in range(33):
		var angle = TAU * i / 32
		points.append(Vector2(cos(angle) * radius, sin(angle) * radius))
	ring.points = points
	visual.add_child(ring)

	# 旋转动画
	var tween = visual.create_tween()
	tween.set_loops()
	tween.tween_property(visual, "rotation", TAU, 2.0)

	return visual

func _create_rift_script() -> GDScript:
	"""创建裂隙运行脚本"""
	var script = GDScript.new()
	script.source_code = """
extends Area2D

var duration: float = 4.0
var damage_per_tick: float = 15.0
var tick_interval: float = 0.33
var slow_amount: float = 0.4
var slow_duration: float = 0.5
var pull_strength: float = 50.0
var radius: float = 80.0
var owner_node: Node = null
var level: int = 1

var _tick_timer: float = 0.0
var _time_elapsed: float = 0.0

func _ready():
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	_time_elapsed += delta
	if _time_elapsed >= duration:
		queue_free()
		return

	_tick_timer += delta
	if _tick_timer >= tick_interval:
		_tick_timer = 0.0
		_damage_enemies_inside()
		_pull_enemies_inside()

func _on_body_entered(body):
	if body.has_method('apply_slow'):
		body.apply_slow(slow_amount, slow_duration)
	elif 'move_speed' in body:
		body.move_speed *= (1.0 - slow_amount)

func _damage_enemies_inside():
	var bodies = get_overlapping_bodies()
	for body in bodies:
		if body.has_method('take_damage'):
			var damage = damage_per_tick * (1.0 + (level - 1) * 0.3)
			body.take_damage(damage, owner_node)

func _pull_enemies_inside():
	var bodies = get_overlapping_bodies()
	for body in bodies:
		if body is Node2D:
			var direction = (global_position - body.global_position).normalized()
			if body.has_method('apply_force'):
				body.apply_force(direction * pull_strength)
			elif 'velocity' in body:
				body.velocity += direction * pull_strength * 0.1
"""
	script.reload()
	return script

func _apply_rift_effects(rift: Node2D) -> void:
	"""设置裂隙参数"""
	if rift.has_method("set_damage_per_tick"):
		rift.damage_per_tick = get_damage()
		rift.duration = get_duration()
		rift.radius = get_effect_range()
		rift.slow_amount = slow_amount
		rift.slow_duration = slow_duration
		rift.pull_strength = pull_strength * (1.0 + (current_level - 1) * 0.2)
		rift.owner_node = owner_node
		rift.level = current_level

func _on_level_up(new_level: int) -> void:
	"""升级效果"""
	# 每级提升范围和持续时间
	duration = rift_duration * (1.0 + (new_level - 1) * 0.25)
	effect_range = rift_radius * (1.0 + (new_level - 1) * 0.15)
	pull_strength = pull_strength * (1.0 + (new_level - 1) * 0.2)