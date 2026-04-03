## Void Hunter - 骷髅军团
## @description: 召唤骷髅士兵协助战斗，骷髅会自动攻击附近敌人
## @version: 1.0.0

extends "res://src/skills/skill_base.gd"

# =============================================================================
# 导出变量
# =============================================================================

## 基础召唤数量
@export var base_skeleton_count: int = 3

## 最大召唤数量（等级3）
@export var max_skeleton_count: int = 5

## 骷髅存活时间
@export var skeleton_lifetime: float = 12.0

## 骷髅基础生命
@export var skeleton_health: float = 30.0

## 骷髅基础攻击力
@export var skeleton_damage: float = 10.0

## 骷髅移动速度
@export var skeleton_speed: float = 80.0

## 骷髅攻击间隔
@export var skeleton_attack_interval: float = 1.0

## 骷髅攻击范围
@export var skeleton_attack_range: float = 50.0

## 召唤范围（骷髅出现的位置）
@export var spawn_range: float = 100.0

# =============================================================================
# 初始化
# =============================================================================

func _init() -> void:
	skill_id = "skeleton_army"
	skill_name = "骷髅军团"
	description = "召唤骷髅士兵协助战斗，骷髅会自动攻击附近敌人"
	skill_type = SkillBase.SkillType.ACTIVE
	skill_category = SkillBase.SkillCategory.SUPPORT
	element = SkillBase.SkillElement.SHADOW
	target_type = SkillBase.TargetType.SELF
	base_damage = skeleton_damage
	effect_range = spawn_range
	duration = skeleton_lifetime
	base_cooldown = 15.0
	base_mana_cost = 40.0

# =============================================================================
# 技能执行
# =============================================================================

func _execute_self_effect() -> void:
	"""执行召唤效果"""
	if owner_node == null:
		return

	var count: int = _get_skeleton_count()
	var spawn_center: Vector2 = owner_node.global_position

	for i in range(count):
		# 随机位置召唤
		var angle: float = TAU * i / count + randf_range(-0.3, 0.3)
		var distance: float = randf_range(spawn_range * 0.5, spawn_range)
		var spawn_pos: Vector2 = spawn_center + Vector2(cos(angle) * distance, sin(angle) * distance)

		_create_skeleton(spawn_pos)

	# 召唤音效和视觉
	_show_summon_visual(spawn_center)

func _get_skeleton_count() -> int:
	"""获取当前等级的召唤数量"""
	var level_ratio: float = float(current_level - 1) / float(MAX_SKILL_LEVEL - 1)
	return base_skeleton_count + int((max_skeleton_count - base_skeleton_count) * level_ratio)

func _create_skeleton(position: Vector2) -> void:
	"""创建骷髅单位"""
	var skeleton = CharacterBody2D.new()
	skeleton.name = "SkeletonMinion"

	# 碰撞设置
	skeleton.collision_layer = 1  # Player layer（友方）
	skeleton.collision_mask = 2   # Enemy layer

	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(16, 24)
	collision.shape = shape
	skeleton.add_child(collision)

	# 骷髅视觉
	var visual = _create_skeleton_visual()
	skeleton.add_child(visual)

	# 属性和脚本
	skeleton.set_script(_create_skeleton_script())
	skeleton.global_position = position

	owner_node.get_tree().current_scene.add_child(skeleton)

	# 配置骷髅参数
	_configure_skeleton(skeleton)

	# 出现动画
	_play_spawn_animation(skeleton)

func _create_skeleton_visual() -> Node2D:
	"""创建骷髅视觉"""
	var visual = Node2D.new()
	visual.name = "SkeletonVisual"

	# 骷髅身体（灰色方块代表）
	var body = Sprite2D.new()
	var tex = ImageTexture.new()
	var img = Image.create(16, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.6, 0.6, 0.65))  # 骷髅灰白色
	tex.set_image(img)
	body.texture = tex
	body.centered = true
	body.offset = Vector2(0, -12)
	visual.add_child(body)

	# 头部（稍亮的颜色）
	var head = Sprite2D.new()
	var tex2 = ImageTexture.new()
	var img2 = Image.create(12, 12, false, Image.FORMAT_RGBA8)
	img2.fill(Color(0.7, 0.7, 0.75))
	tex2.set_image(img2)
	head.texture = tex2
	head.centered = true
	head.offset = Vector2(0, -26)
	visual.add_child(head)

	return visual

func _create_skeleton_script() -> GDScript:
	"""创建骷髅AI脚本"""
	var script = GDScript.new()
	script.source_code = """
extends CharacterBody2D

var max_health: float = 30.0
var current_health: float = 30.0
var attack_damage: float = 10.0
var move_speed: float = 80.0
var attack_range: float = 50.0
var attack_interval: float = 1.0
var lifetime: float = 12.0
var owner_node: Node = null
var level: int = 1

var _attack_timer: float = 0.0
var _target: Node = null
var _lifetime_timer: float = 0.0

func _ready():
	add_to_group('player_summons')

func _physics_process(delta):
	_lifetime_timer += delta
	if _lifetime_timer >= lifetime:
		die()
		return

	_attack_timer += delta

	# 寻找目标
	if _target == null or not is_instance_valid(_target):
		_find_target()

	# 移动和攻击
	if _target:
		var distance = global_position.distance_to(_target.global_position)
		if distance <= attack_range:
			if _attack_timer >= attack_interval:
				_attack_timer = 0.0
				attack()
		else:
			move_to_target(delta)

func _find_target():
	var enemies = get_tree().get_nodes_in_group('enemies')
	if enemies.is_empty():
		return

	# 找最近的敌人
	var closest = null
	var closest_dist = INF
	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist = global_position.distance_to(enemy.global_position)
			if dist < closest_dist:
				closest = enemy
				closest_dist = dist

	_target = closest

func move_to_target(delta):
	if _target == null:
		return

	var direction = (_target.global_position - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()

func attack():
	if _target == null or not is_instance_valid(_target):
		return

	if _target.has_method('take_damage'):
		var damage = attack_damage * (1.0 + (level - 1) * 0.2)
		_target.take_damage(damage, owner_node)

	# 攻击视觉
	_show_attack_visual()

func _show_attack_visual():
	var visual = get_node_or_null('SkeletonVisual')
	if visual:
		var tween = create_tween()
		tween.tween_property(visual, 'modulate', Color(1.2, 1.2, 1.0), 0.1)
		tween.tween_property(visual, 'modulate', Color.WHITE, 0.15)

func take_damage(amount, source):
	current_health -= amount
	if current_health <= 0:
		die()

func die():
	# 死亡效果
	var visual = get_node_or_null('SkeletonVisual')
	if visual:
		var tween = create_tween()
		tween.tween_property(visual, 'modulate:a', 0.0, 0.3)
		tween.tween_callback(queue_free)
	else:
		queue_free()
"""
	script.reload()
	return script

func _configure_skeleton(skeleton: CharacterBody2D) -> void:
	"""配置骷髅参数"""
	# 使用set方法或直接赋值
	if skeleton.has_method("set_max_health"):
		skeleton.max_health = skeleton_health * (1.0 + (current_level - 1) * 0.2)
		skeleton.current_health = skeleton_health * (1.0 + (current_level - 1) * 0.2)
		skeleton.attack_damage = skeleton_damage * (1.0 + (current_level - 1) * 0.25)
		skeleton.move_speed = skeleton_speed * (1.0 + (current_level - 1) * 0.1)
		skeleton.attack_range = skeleton_attack_range
		skeleton.attack_interval = skeleton_attack_interval * (1.0 - (current_level - 1) * 0.1)
		skeleton.lifetime = get_duration()
		skeleton.owner_node = owner_node
		skeleton.level = current_level

func _play_spawn_animation(skeleton: CharacterBody2D) -> void:
	"""播放召唤出现动画"""
	var visual = skeleton.get_node_or_null("SkeletonVisual")
	if visual:
		visual.modulate = Color(0.3, 0.3, 0.35, 0.3)
		var tween = skeleton.create_tween()
		tween.tween_property(visual, "modulate", Color.WHITE, 0.3)

func _show_summon_visual(center: Vector2) -> void:
	"""显示召唤视觉效果"""
	# 暗影波动
	var wave = Sprite2D.new()
	var tex = ImageTexture.new()
	var img = Image.create(50, 50, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.3, 0.3, 0.5, 0.5))
	tex.set_image(img)
	wave.texture = tex
	wave.centered = true
	wave.global_position = center
	owner_node.get_tree().current_scene.add_child(wave)

	var tween = wave.create_tween()
	tween.tween_property(wave, "scale", Vector2(3.0, 3.0), 0.4)
	tween.parallel().tween_property(wave, "modulate:a", 0.0, 0.4)
	tween.tween_callback(wave.queue_free)

func _on_level_up(new_level: int) -> void:
	"""升级效果"""
	# 每级增加骷髅数量和属性
	duration = skeleton_lifetime * (1.0 + (new_level - 1) * 0.3)
	effect_range = spawn_range * (1.0 + (new_level - 1) * 0.1)