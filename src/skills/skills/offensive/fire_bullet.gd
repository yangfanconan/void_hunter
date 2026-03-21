## Void Hunter - 火焰弹技能
## @description: 发射火焰弹，造成燃烧伤害
## @author: Void Hunter Team
## @version: 1.0.0

extends SkillBase
class_name SkillFireBullet

# =============================================================================
# 配置参数
# =============================================================================

## 燃烧持续时间
@export var burn_duration: float = 3.0

## 燃烧伤害（每秒）
@export var burn_damage_per_second: float = 5.0

## 燃烧伤害倍率（相对于基础伤害）
@export var burn_damage_ratio: float = 0.2

# =============================================================================
# 内部变量
# =============================================================================

var _active_burns: Array[Dictionary] = []

# =============================================================================
# 初始化
# =============================================================================

func _init() -> void:
	skill_id = "fire_bullet"
	skill_name = "火焰弹"
	description = "发射一枚火焰弹，对命中的敌人造成伤害并附加燃烧效果，持续造成火焰伤害。"
	skill_type = SkillType.ACTIVE
	skill_category = SkillCategory.OFFENSIVE
	target_type = TargetType.PROJECTILE
	element = SkillElement.FIRE
	hotkey_slot = 1
	
	base_damage = 25.0
	base_cooldown = 2.5
	base_mana_cost = 15.0
	effect_range = 80.0
	duration = burn_duration
	projectile_speed = 500.0


func initialize(owner: Node) -> void:
	super.initialize(owner)
	_active_burns.clear()


func update(delta: float) -> void:
	super.update(delta)
	_update_burns(delta)


# =============================================================================
# 技能效果
# =============================================================================

func _execute_projectile_effect(target_position: Variant) -> void:
	"""
	发射火焰弹
	"""
	if owner_node == null:
		return
	
	var spawn_position: Vector2 = owner_node.global_position
	var direction: Vector2 = Vector2.RIGHT
	
	if target_position is Vector2:
		direction = (target_position - spawn_position).normalized()
	
	# 创建火焰弹投射物
	_create_fire_projectile(spawn_position, direction)


func _create_fire_projectile(pos: Vector2, dir: Vector2) -> void:
	"""
	创建火焰弹投射物
	"""
	var projectile: Area2D = Area2D.new()
	projectile.name = "FireBullet"
	projectile.position = pos
	
	# 添加碰撞形状
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = get_effect_range() / 2.0
	collision.shape = shape
	projectile.add_child(collision)
	
	# 添加可视效果
	var visual: Node2D = _create_fire_visual()
	projectile.add_child(visual)
	
	# 设置投射物脚本
	var script: GDScript = GDScript.new()
	script.source_code = """
extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 500.0
var damage: float = 25.0
var burn_duration: float = 3.0
var burn_dps: float = 5.0
var owner_node: Node = null
var lifetime: float = 3.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body == owner_node:
		return
	_apply_effect(body)

func _on_area_entered(area: Node) -> void:
	if area.get_parent() == owner_node:
		return
	var parent = area.get_parent()
	if parent.has_method("take_damage"):
		_apply_effect(parent)

func _apply_effect(target: Node) -> void:
	if target.has_method("take_damage"):
		target.take_damage(damage, owner_node)
	
	# 应用燃烧效果
	if target.has_method("apply_burn"):
		target.apply_burn(burn_dps, burn_duration, owner_node)
	elif "burn_damage" in target:
		target.burn_damage = burn_dps
		target.burn_timer = burn_duration
	
	queue_free()
"""
	script.reload()
	projectile.set_script(script)
	
	# 设置属性
	projectile.set("direction", dir)
	projectile.set("speed", projectile_speed)
	projectile.set("damage", get_damage())
	projectile.set("burn_duration", get_burn_duration())
	projectile.set("burn_dps", get_burn_damage())
	projectile.set("owner_node", owner_node)
	
	# 添加到场景
	owner_node.get_tree().current_scene.add_child(projectile)


func _create_fire_visual() -> Node2D:
	"""
	创建火焰弹视觉效果
	"""
	var visual: Node2D = Node2D.new()
	
	# 简单的火焰效果（使用动画或粒子系统）
	var fire_sprite: Sprite2D = Sprite2D.new()
	# 这里可以设置火焰纹理
	visual.add_child(fire_sprite)
	
	return visual


# =============================================================================
# 燃烧效果管理
# =============================================================================

func _update_burns(delta: float) -> void:
	"""
	更新所有燃烧效果
	"""
	var to_remove: Array[int] = []
	
	for i in range(_active_burns.size()):
		var burn: Dictionary = _active_burns[i]
		burn["timer"] -= delta
		
		# 应用燃烧伤害
		var target: Node = burn.get("target")
		if target and is_instance_valid(target):
			if target.has_method("take_damage"):
				target.take_damage(burn.get("damage_per_tick", 0.0) * delta, owner_node)
		
		# 检查是否结束
		if burn.get("timer", 0.0) <= 0:
			to_remove.append(i)
	
	# 移除结束的燃烧效果
	for i in range(to_remove.size() - 1, -1, -1):
		_active_burns.remove_at(to_remove[i])


func apply_burn_to_target(target: Node) -> void:
	"""
	对目标应用燃烧效果
	"""
	if target == null:
		return
	
	# 检查是否已经有燃烧效果
	for burn in _active_burns:
		if burn.get("target") == target:
			# 刷新持续时间
			burn["timer"] = get_burn_duration()
			return
	
	# 添加新的燃烧效果
	_active_burns.append({
		"target": target,
		"timer": get_burn_duration(),
		"damage_per_tick": get_burn_damage()
	})


# =============================================================================
# 属性获取
# =============================================================================

func get_burn_duration() -> float:
	"""
	获取燃烧持续时间（受等级影响）
	"""
	return burn_duration * (1.0 + (current_level - 1) * 0.15)


func get_burn_damage() -> float:
	"""
	获取燃烧伤害（受等级影响）
	"""
	return get_damage() * burn_damage_ratio


# =============================================================================
# 升级效果
# =============================================================================

func _on_level_up(new_level: int) -> void:
	"""
	升级时增强燃烧效果
	"""
	match new_level:
		2:
			burn_damage_ratio = 0.3
		3:
			burn_damage_ratio = 0.4
			burn_duration = 4.0
