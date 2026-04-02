## Void Hunter - 追踪导弹技能
## @description: 发射自动追踪最近敌人的导弹，有爆炸范围伤害
## @author: Void Hunter Team
## @version: 1.0.0

extends SkillBase
class_name SkillHomingMissile

# =============================================================================
# 配置参数
# =============================================================================

## 导弹速度
@export var missile_speed: float = 250.0

## 最大速度
@export var max_speed: float = 450.0

## 转向速度
@export var turn_rate: float = 5.0

## 爆炸半径
@export var explosion_radius: float = 80.0

## 爆炸伤害衰减
@export var explosion_falloff: float = 0.5

## 导弹存活时间
@export var missile_lifetime: float = 5.0

## 同时发射数量
@export var missile_count: int = 1

## 发射间隔
@export var launch_interval: float = 0.2

# =============================================================================
# 初始化
# =============================================================================

func _init() -> void:
	skill_id = "homing_missile"
	skill_name = "追踪导弹"
	description = "发射自动追踪敌人的导弹，命中后产生范围爆炸伤害。"
	skill_type = SkillType.ACTIVE
	skill_category = SkillCategory.OFFENSIVE
	target_type = TargetType.ENEMY
	element = SkillElement.FIRE
	hotkey_slot = 1

	base_damage = 35.0
	base_cooldown = 3.5
	base_mana_cost = 30.0
	effect_range = explosion_radius
	projectile_speed = missile_speed


# =============================================================================
# 技能效果
# =============================================================================

func _execute_enemy_effect(target: Node) -> void:
	"""
	执行追踪导弹效果
	"""
	if owner_node == null:
		return

	# 发射多枚导弹
	for i in range(get_missile_count()):
		if i > 0:
			await owner_node.get_tree().create_timer(launch_interval).timeout
		_launch_missile(target)

	# 播放音效
	AudioManager.play_sfx("missile_launch")


func _launch_missile(initial_target: Node) -> void:
	"""
	发射单枚导弹
	"""
	if owner_node == null:
		return

	# 创建导弹
	var missile: Area2D = Area2D.new()
	missile.name = "HomingMissile"

	# 添加碰撞形状
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 8.0
	collision.shape = shape
	missile.add_child(collision)

	# 创建视觉效果
	var sprite: Sprite2D = Sprite2D.new()
	var texture: ImageTexture = ImageTexture.new()
	var image: Image = Image.create(16, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color(1.0, 0.4, 0.1))  # 橙红色导弹
	texture.set_image(image)
	sprite.texture = texture
	missile.add_child(sprite)

	# 添加尾焰效果
	var trail: Line2D = Line2D.new()
	trail.name = "Trail"
	trail.width = 4.0
	trail.default_color = Color(1.0, 0.6, 0.2, 0.6)
	missile.add_child(trail)

	# 设置导弹脚本
	var script: GDScript = GDScript.new()
	script.source_code = """
extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 250.0
var max_speed: float = 450.0
var turn_rate: float = 5.0
var damage: float = 35.0
var explosion_radius: float = 80.0
var explosion_falloff: float = 0.5
var owner_node: Node = null
var lifetime: float = 5.0
var current_target: Node = null
var trail_points: Array = []
var max_trail_points: int = 15

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	find_target()

func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0:
		explode()

	# 追踪目标
	if current_target and is_instance_valid(current_target):
		var target_dir: Vector2 = (current_target.global_position - global_position).normalized()
		direction = direction.lerp(target_dir, turn_rate * delta).normalized()
	else:
		find_target()

	# 加速
	speed = min(speed + 100.0 * delta, max_speed)

	# 移动
	position += direction * speed * delta
	rotation = direction.angle()

	# 更新尾迹
	update_trail()

func find_target() -> void:
	var enemies: Array = get_tree().get_nodes_in_group("enemies")
	var closest: Node = null
	var closest_dist: float = INF

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist: float = global_position.distance_to(enemy.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = enemy

	current_target = closest

func update_trail() -> void:
	var trail: Line2D = get_node_or_null("Trail")
	if trail == null:
		return

	trail_points.push_front(global_position)
	if trail_points.size() > max_trail_points:
		trail_points.pop_back()

	trail.clear_points()
	for point in trail_points:
		trail.add_point(to_local(point))

func _on_body_entered(body: Node) -> void:
	if body == owner_node:
		return
	if body.is_in_group("enemies"):
		explode()

func _on_area_entered(area: Node) -> void:
	if area.get_parent() == owner_node:
		return
	var parent = area.get_parent()
	if parent.is_in_group("enemies"):
		explode()

func explode() -> void:
	# 爆炸伤害
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = explosion_radius
	query.shape = shape
	query.transform = Transform2D(0, global_position)
	query.collision_mask = 2

	var results: Array = space_state.intersect_shape(query, 32)

	for result in results:
		var enemy: Node = result.get("collider")
		if enemy and enemy.has_method("take_damage"):
			var dist: float = global_position.distance_to(enemy.global_position)
			var damage_mult: float = 1.0 - (dist / explosion_radius) * explosion_falloff
			enemy.take_damage(damage * damage_mult, owner_node)

	# VFX: small explosion on missile hit
	if VFXManager:
		VFXManager.spawn_effect("explosion_small", global_position)

	# 创建爆炸效果
	create_explosion_visual()
	queue_free()

func create_explosion_visual() -> void:
	var explosion: Node2D = Node2D.new()
	explosion.global_position = global_position

	var sprite: Sprite2D = Sprite2D.new()
	var texture: ImageTexture = ImageTexture.new()
	var size: int = int(explosion_radius * 2)
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(1.0, 0.5, 0.1, 0.7))
	texture.set_image(image)
	sprite.texture = texture
	sprite.modulate = Color(1.0, 0.6, 0.2)
	explosion.add_child(sprite)

	get_tree().current_scene.add_child(explosion)

	var tween: Tween = get_tree().create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.5, 1.5), 0.2)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.3)
	tween.tween_callback(explosion.queue_free)
"""
	script.reload()
	missile.set_script(script)

	# 设置属性
	var initial_dir: Vector2 = Vector2.RIGHT
	if initial_target and is_instance_valid(initial_target):
		initial_dir = (initial_target.global_position - owner_node.global_position).normalized()
	else:
		# 随机方向
		initial_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()

	missile.set("direction", initial_dir)
	missile.set("speed", get_missile_speed())
	missile.set("max_speed", max_speed)
	missile.set("turn_rate", turn_rate)
	missile.set("damage", get_damage())
	missile.set("explosion_radius", get_explosion_radius())
	missile.set("explosion_falloff", explosion_falloff)
	missile.set("owner_node", owner_node)
	missile.set("lifetime", missile_lifetime)
	missile.set("current_target", initial_target)

	# 设置位置
	missile.global_position = owner_node.global_position + initial_dir * 25.0

	# 设置碰撞
	missile.collision_layer = 4
	missile.collision_mask = 2 | 16

	# 添加到场景
	owner_node.get_tree().current_scene.add_child(missile)


# =============================================================================
# 属性获取
# =============================================================================

func get_missile_count() -> int:
	"""
	获取导弹数量（受等级影响）
	"""
	return missile_count + (current_level - 1)


func get_missile_speed() -> float:
	"""
	获取导弹初始速度
	"""
	return missile_speed * (1.0 + (current_level - 1) * 0.1)


func get_explosion_radius() -> float:
	"""
	获取爆炸半径
	"""
	return explosion_radius * (1.0 + (current_level - 1) * 0.2)


# =============================================================================
# 升级效果
# =============================================================================

func _on_level_up(new_level: int) -> void:
	"""
	升级时增强追踪导弹
	"""
	match new_level:
		2:
			missile_count = 2
			explosion_radius = 100.0
		3:
			missile_count = 3
			turn_rate = 7.0
			max_speed = 550.0
