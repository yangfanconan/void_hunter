## Void Hunter - 冰霜箭技能
## @description: 发射冰霜箭，减速敌人，有冻结几率
## @author: Void Hunter Team
## @version: 1.0.0

extends SkillBase
class_name SkillFrostArrow

# =============================================================================
# 配置参数
# =============================================================================

## 减速百分比
@export var slow_percent: float = 0.4

## 减速持续时间
@export var slow_duration: float = 2.5

## 冻结概率
@export_range(0.0, 1.0) var freeze_chance: float = 0.15

## 冻结持续时间
@export var freeze_duration: float = 1.5

## 穿透数量（-1为无限穿透）
@export var pierce_count: int = 1

# =============================================================================
# 初始化
# =============================================================================

func _init() -> void:
	skill_id = "frost_arrow"
	skill_name = "冰霜箭"
	description = "发射一支冰霜箭，对敌人造成伤害并减速，有概率冻结敌人。"
	skill_type = SkillType.ACTIVE
	skill_category = SkillCategory.OFFENSIVE
	target_type = TargetType.PROJECTILE
	element = SkillElement.ICE
	hotkey_slot = 1
	
	base_damage = 20.0
	base_cooldown = 3.0
	base_mana_cost = 18.0
	effect_range = 60.0
	duration = slow_duration
	projectile_speed = 450.0


# =============================================================================
# 技能效果
# =============================================================================

func _execute_projectile_effect(target_position: Variant) -> void:
	"""
	发射冰霜箭
	"""
	if owner_node == null:
		return
	
	var spawn_position: Vector2 = owner_node.global_position
	var direction: Vector2 = Vector2.RIGHT
	
	if target_position is Vector2:
		direction = (target_position - spawn_position).normalized()
	
	_create_frost_projectile(spawn_position, direction)


func _create_frost_projectile(pos: Vector2, dir: Vector2) -> void:
	"""
	创建冰霜箭投射物
	"""
	var projectile: Area2D = Area2D.new()
	projectile.name = "FrostArrow"
	projectile.position = pos
	projectile.collision_layer = 0
	projectile.collision_mask = 2  # Enemy layer
	
	# 添加碰撞形状
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: CapsuleShape2D = CapsuleShape2D.new()
	shape.radius = get_effect_range() / 3.0
	shape.height = get_effect_range()
	collision.shape = shape
	collision.rotation = PI / 2.0
	projectile.add_child(collision)
	
	# 设置投射物脚本
	var script: GDScript = GDScript.new()
	script.source_code = """
extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 450.0
var damage: float = 20.0
var slow_percent: float = 0.4
var slow_duration: float = 2.5
var freeze_chance: float = 0.15
var freeze_duration: float = 1.5
var pierce_count: int = 1
var owner_node: Node = null
var lifetime: float = 4.0
var hit_targets: Array = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body == owner_node:
		return
	if body in hit_targets:
		return
	
	_apply_effect(body)
	hit_targets.append(body)
	
	# 检查穿透
	if pierce_count > 0:
		pierce_count -= 1
		if pierce_count < 0:
			queue_free()
	else:
		queue_free()

func _apply_effect(target: Node) -> void:
	# 造成伤害
	if target.has_method("take_damage"):
		target.take_damage(damage, owner_node)
	
	# 应用减速
	if target.has_method("apply_slow"):
		target.apply_slow(slow_percent, slow_duration)
	elif "speed_modifier" in target:
		target.speed_modifier = 1.0 - slow_percent
	
	# 检查冻结
	if randf() < freeze_chance:
		if target.has_method("apply_freeze"):
			target.apply_freeze(freeze_duration)
		elif "frozen" in target:
			target.frozen = true
			await get_tree().create_timer(freeze_duration).timeout
			target.frozen = false
"""
	script.reload()
	projectile.set_script(script)
	
	# 设置属性
	projectile.set("direction", dir)
	projectile.set("speed", projectile_speed)
	projectile.set("damage", get_damage())
	projectile.set("slow_percent", get_slow_percent())
	projectile.set("slow_duration", get_slow_duration())
	projectile.set("freeze_chance", get_freeze_chance())
	projectile.set("freeze_duration", get_freeze_duration())
	projectile.set("pierce_count", get_pierce_count())
	projectile.set("owner_node", owner_node)
	
	# 添加到场景
	owner_node.get_tree().current_scene.add_child(projectile)


# =============================================================================
# 属性获取
# =============================================================================

func get_slow_percent() -> float:
	"""
	获取减速百分比（受等级影响）
	"""
	return slow_percent + (current_level - 1) * 0.1


func get_slow_duration() -> float:
	"""
	获取减速持续时间（受等级影响）
	"""
	return slow_duration * (1.0 + (current_level - 1) * 0.2)


func get_freeze_chance() -> float:
	"""
	获取冻结概率（受等级影响）
	"""
	return freeze_chance + (current_level - 1) * 0.1


func get_freeze_duration() -> float:
	"""
	获取冻结持续时间（受等级影响）
	"""
	return freeze_duration * (1.0 + (current_level - 1) * 0.25)


func get_pierce_count() -> int:
	"""
	获取穿透数量（受等级影响）
	"""
	return pierce_count + (current_level - 1)


# =============================================================================
# 升级效果
# =============================================================================

func _on_level_up(new_level: int) -> void:
	"""
	升级时增强冰霜效果
	"""
	match new_level:
		2:
			freeze_chance = 0.25
			slow_percent = 0.5
		3:
			freeze_chance = 0.35
			slow_percent = 0.6
			pierce_count = 3
