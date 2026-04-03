## Void Hunter - 陨石打击
## @description: 从天空召唤陨石，对大范围区域造成高额伤害并留下燃烧区域
## @version: 1.0.0

extends "res://src/skills/skill_base.gd"

# =============================================================================
# 导出变量
# =============================================================================

## 陨石坠落延迟（给玩家预警时间）
@export var fall_delay: float = 1.0

## 陨石冲击半径
@export var impact_radius: float = 120.0

## 燃烧区域持续时间
@export var burn_duration: float = 3.0

## 燃烧区域半径（比冲击范围小）
@export var burn_radius: float = 80.0

## 燃烧伤害（每秒）
@export var burn_damage: float = 8.0

## 冲击波推进距离
@export var knockback_distance: float = 100.0

# =============================================================================
# 初始化
# =============================================================================

func _init() -> void:
	skill_id = "meteor_strike"
	skill_name = "陨石打击"
	description = "召唤陨石从天而降，造成巨大伤害并留下燃烧区域"
	skill_type = SkillBase.SkillType.ACTIVE
	skill_category = SkillBase.SkillCategory.OFFENSIVE
	element = SkillBase.SkillElement.FIRE
	target_type = SkillBase.TargetType.POSITION
	base_damage = 80.0
	effect_range = impact_radius
	duration = burn_duration
	base_cooldown = 12.0
	base_mana_cost = 50.0

# =============================================================================
# 技能执行
# =============================================================================

func _execute_position_effect(target_position: Variant) -> void:
	"""执行陨石打击"""
	if target_position == null:
		if owner_node:
			target_position = owner_node.global_position
		else:
			return

	var pos: Vector2 = target_position as Vector2

	# 显示预警标记
	_show_warning_indicator(pos)

	# 延迟后坠落陨石
	await owner_node.get_tree().create_timer(fall_delay).timeout

	# 创建陨石冲击
	_create_meteor_impact(pos)

func _show_warning_indicator(position: Vector2) -> void:
	"""显示坠落预警"""
	var indicator = Area2D.new()
	indicator.name = "MeteorWarning"

	# 红色警告圆圈
	var visual = Line2D.new()
	visual.width = 2.0
	visual.default_color = Color(1.0, 0.3, 0.1, 0.5)
	var points: Array[Vector2] = []
	var radius: float = get_effect_range()
	for i in range(33):
		var angle = TAU * i / 32
		points.append(Vector2(cos(angle) * radius, sin(angle) * radius))
	visual.points = points
	indicator.add_child(visual)

	indicator.global_position = position
	owner_node.get_tree().current_scene.add_child(indicator)

	# 闪烁效果
	var tween = indicator.create_tween()
	tween.tween_property(visual, "default_color:a", 1.0, 0.2)
	tween.tween_property(visual, "default_color:a", 0.3, 0.2)
	tween.set_loops(int(fall_delay / 0.4))
	tween.tween_callback(indicator.queue_free)

func _create_meteor_impact(position: Vector2) -> void:
	"""创建陨石冲击"""
	# 冲击伤害
	var impact_area = Area2D.new()
	impact_area.collision_layer = 0
	impact_area.collision_mask = 2

	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = get_effect_range()
	collision.shape = shape
	impact_area.add_child(collision)

	impact_area.global_position = position
	owner_node.get_tree().current_scene.add_child(impact_area)

	# 伤害范围内的敌人
	await owner_node.get_tree().physics_frame
	var bodies = impact_area.get_overlapping_bodies()
	for body in bodies:
		if body.has_method("take_damage"):
			var damage = get_damage() * (1.0 + (current_level - 1) * 0.4)
			body.take_damage(damage, owner_node)

			# 冲击波推进
			if body is Node2D:
				var knockback_dir = (body.global_position - position).normalized()
				if body.has_method("apply_knockback"):
					body.apply_knockback(knockback_dir * knockback_distance)
				elif "velocity" in body:
					body.velocity += knockback_dir * knockback_distance

	impact_area.queue_free()

	# 视觉冲击效果
	_show_impact_visual(position)

	# 创建燃烧区域（等级2+）
	if current_level >= 2:
		_create_burn_zone(position)

func _show_impact_visual(position: Vector2) -> void:
	"""显示冲击视觉效果"""
	# 火焰爆发
	var explosion = Sprite2D.new()
	var tex = ImageTexture.new()
	var img = Image.create(100, 100, false, Image.FORMAT_RGBA8)

	# 绘制火焰色渐变圆
	var center = Vector2(50, 50)
	for x in range(100):
		for y in range(100):
			var dist = Vector2(x, y).distance_to(center) / 50.0
			if dist <= 1.0:
				var color = Color(1.0, 0.5 - dist * 0.3, 0.1, 1.0 - dist * 0.5)
				img.set_pixel(x, y, color)

	tex.set_image(img)
	explosion.texture = tex
	explosion.centered = true
	explosion.scale = Vector2(1.5, 1.5)
	explosion.global_position = position
	owner_node.get_tree().current_scene.add_child(explosion)

	# 消失动画
	var tween = explosion.create_tween()
	tween.tween_property(explosion, "scale", Vector2(2.5, 2.5), 0.3)
	tween.parallel().tween_property(explosion, "modulate:a", 0.0, 0.4)
	tween.tween_callback(explosion.queue_free)

func _create_burn_zone(position: Vector2) -> void:
	"""创建燃烧区域"""
	var burn_zone = Area2D.new()
	burn_zone.name = "BurnZone"
	burn_zone.collision_layer = 0
	burn_zone.collision_mask = 2

	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = burn_radius * (1.0 + (current_level - 2) * 0.15)
	collision.shape = shape
	burn_zone.add_child(collision)

	# 燃烧视觉效果
	var visual = _create_burn_visual()
	burn_zone.add_child(visual)

	burn_zone.global_position = position
	burn_zone.set_script(_create_burn_script())
	owner_node.get_tree().current_scene.add_child(burn_zone)

func _create_burn_visual() -> Node2D:
	"""创建燃烧视觉效果"""
	var visual = Node2D.new()

	# 火焰地面
	var ground = Sprite2D.new()
	var tex = ImageTexture.new()
	var img = Image.create(60, 60, false, Image.FORMAT_RGBA8)
	img.fill(Color(1.0, 0.4, 0.1, 0.6))
	tex.set_image(img)
	ground.texture = tex
	ground.centered = true
	visual.add_child(ground)

	return visual

func _create_burn_script() -> GDScript:
	"""创建燃烧区域脚本"""
	var script = GDScript.new()
	script.source_code = """
extends Area2D

var burn_duration: float = 3.0
var burn_damage: float = 8.0
var damage_interval: float = 0.5
var owner_node: Node = null
var level: int = 2

var _time_elapsed: float = 0.0
var _damage_timer: float = 0.0

func _ready():
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	_time_elapsed += delta
	if _time_elapsed >= burn_duration:
		queue_free()
		return

	_damage_timer += delta
	if _damage_timer >= damage_interval:
		_damage_timer = 0.0
		_damage_enemies_inside()

func _on_body_entered(body):
	_apply_burn_damage(body)

func _damage_enemies_inside():
	var bodies = get_overlapping_bodies()
	for body in bodies:
		_apply_burn_damage(body)

func _apply_burn_damage(body):
	if body.has_method('take_damage'):
		var damage = burn_damage * (1.0 + (level - 2) * 0.3)
		body.take_damage(damage, owner_node)

	if body.has_method('apply_burn'):
		body.apply_burn(burn_damage * 0.5, 1.0)
"""
	script.reload()
	return script

func _on_level_up(new_level: int) -> void:
	"""升级效果"""
	# 每级提升伤害和范围
	effect_range = impact_radius * (1.0 + (new_level - 1) * 0.15)
	burn_duration = burn_duration * (1.0 + (new_level - 1) * 0.3)

	# 等级3额外增加燃烧伤害
	if new_level >= 3:
		burn_damage = burn_damage * 1.5