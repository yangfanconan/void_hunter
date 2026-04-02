## Void Hunter - 暗影斩技能
## @description: 穿透敌人的暗影刃
## @author: Void Hunter Team
## @version: 1.0.0

extends SkillBase
class_name SkillShadowSlash

# =============================================================================
# 配置参数
# =============================================================================

## 斩击宽度
@export var slash_width: float = 80.0

## 斩击距离
@export var slash_distance: float = 200.0

## 穿透次数（-1为无限穿透）
@export var penetration: int = -1

## 暗影印记持续时间
@export var mark_duration: float = 5.0

## 暗影印记伤害加成
@export var mark_damage_bonus: float = 0.3

# =============================================================================
# 初始化
# =============================================================================

func _init() -> void:
	skill_id = "shadow_slash"
	skill_name = "暗影斩"
	description = "释放一道暗影刃，穿透所有敌人并留下暗影印记，下次攻击造成额外伤害。"
	skill_type = SkillType.ACTIVE
	skill_category = SkillCategory.OFFENSIVE
	target_type = TargetType.DIRECTION
	element = SkillElement.SHADOW
	hotkey_slot = 2

	base_damage = 35.0
	base_cooldown = 3.5
	base_mana_cost = 22.0
	effect_range = slash_distance


# =============================================================================
# 技能效果
# =============================================================================

func _execute_direction_effect(direction: Variant) -> void:
	"""
	向指定方向释放暗影斩
	"""
	if owner_node == null:
		return

	var dir: Vector2 = Vector2.RIGHT
	if direction is Vector2:
		dir = direction.normalized()
	elif direction is Vector2:
		dir = direction

	# 创建暗影斩击区域
	_create_shadow_slash(owner_node.global_position, dir)


func _create_shadow_slash(origin: Vector2, direction: Vector2) -> void:
	"""
	创建暗影斩击效果
	"""
	# 创建斩击区域
	var slash_area: Area2D = Area2D.new()
	slash_area.collision_layer = 0
	slash_area.collision_mask = 2  # Enemy layer

	# 计算斩击区域形状
	var shape: ConvexPolygonShape2D = ConvexPolygonShape2D.new()
	var points: PackedVector2Array = []

	var half_width: float = get_slash_width() / 2.0
	var distance: float = get_slash_distance()

	# 创建扇形区域
	var angle: float = direction.angle()
	var spread: float = 0.3  # 扇形角度范围

	points.append(Vector2(0, -half_width * 0.3))
	points.append(Vector2(distance, -half_width))
	points.append(Vector2(distance, half_width))
	points.append(Vector2(0, half_width * 0.3))

	shape.set_point_cloud(points)

	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = shape
	collision.rotation = angle
	slash_area.add_child(collision)

	# 设置脚本
	var script: GDScript = GDScript.new()
	script.source_code = """
extends Area2D

var damage: float = 35.0
var mark_duration: float = 5.0
var mark_bonus: float = 0.3
var owner_node: Node = null
var hit_targets: Array = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# 短暂存在后移除
	await get_tree().create_timer(0.2).timeout
	queue_free()

func _on_body_entered(body: Node) -> void:
	if body == owner_node:
		return
	if body in hit_targets:
		return

	hit_targets.append(body)

	# 计算最终伤害（包含暗影印记加成）
	var final_damage: float = damage
	if body.has_method("has_shadow_mark") and body.has_shadow_mark():
		final_damage *= (1.0 + mark_bonus)
		if body.has_method("remove_shadow_mark"):
			body.remove_shadow_mark()

	# 造成伤害
	if body.has_method("take_damage"):
		body.take_damage(final_damage, owner_node)

	# VFX: shadow hit spark
	if VFXManager:
		VFXManager.spawn_effect("hit_spark", body.global_position, {"color": Color(0.5, 0.3, 0.8)})

	# 应用暗影印记
	if body.has_method("apply_shadow_mark"):
		body.apply_shadow_mark(mark_duration)
"""
	script.reload()
	slash_area.set_script(script)

	slash_area.set("damage", get_damage())
	slash_area.set("mark_duration", get_mark_duration())
	slash_area.set("mark_bonus", mark_damage_bonus)
	slash_area.set("owner_node", owner_node)

	# 创建视觉效果
	_create_slash_visual(origin, direction)

	# 添加到场景
	owner_node.get_tree().current_scene.add_child(slash_area)
	slash_area.global_position = origin


func _create_slash_visual(origin: Vector2, direction: Vector2) -> void:
	"""
	创建暗影斩视觉效果
	"""
	var visual: Line2D = Line2D.new()
	visual.width = get_slash_width()
	visual.default_color = Color(0.3, 0.1, 0.5, 0.7)

	var end_pos: Vector2 = origin + direction * get_slash_distance()
	visual.add_point(origin)
	visual.add_point(end_pos)

	owner_node.get_tree().current_scene.add_child(visual)

	# 淡出效果
	var tween: Tween = owner_node.create_tween()
	tween.tween_property(visual, "modulate:a", 0.0, 0.3)
	tween.tween_callback(visual.queue_free)


# =============================================================================
# 属性获取
# =============================================================================

func get_slash_width() -> float:
	"""
	获取斩击宽度（受等级影响）
	"""
	return slash_width * (1.0 + (current_level - 1) * 0.2)


func get_slash_distance() -> float:
	"""
	获取斩击距离（受等级影响）
	"""
	return slash_distance * (1.0 + (current_level - 1) * 0.15)


func get_mark_duration() -> float:
	"""
	获取暗影印记持续时间（受等级影响）
	"""
	return mark_duration * (1.0 + (current_level - 1) * 0.25)


# =============================================================================
# 升级效果
# =============================================================================

func _on_level_up(new_level: int) -> void:
	"""
	升级时增强暗影斩
	"""
	match new_level:
		2:
			mark_damage_bonus = 0.5
			slash_width = 100.0
		3:
			mark_damage_bonus = 0.75
			slash_width = 120.0
			slash_distance = 250.0
