## Void Hunter - 扇形弹幕技能
## @description: 同时发射多颗子弹，呈扇形展开
## @author: Void Hunter Team
## @version: 1.0.0

extends SkillBase
class_name SkillFanShot

# =============================================================================
# 配置参数
# =============================================================================

## 扇形子弹数量
@export var bullet_count: int = 5

## 扇形展开角度（总角度，度）
@export var spread_angle: float = 60.0

## 每颗子弹伤害倍率（相对于基础伤害）
@export var bullet_damage_ratio: float = 0.6

## 子弹速度
@export var bullet_speed: float = 450.0

## 子弹存活时间
@export var bullet_lifetime: float = 2.5

# =============================================================================
# 初始化
# =============================================================================

func _init() -> void:
	skill_id = "fan_shot"
	skill_name = "扇形弹幕"
	description = "同时发射多颗子弹，呈扇形展开，覆盖更大范围。"
	skill_type = SkillType.ACTIVE
	skill_category = SkillCategory.OFFENSIVE
	target_type = TargetType.DIRECTION
	element = SkillElement.PHYSICAL
	hotkey_slot = 1

	base_damage = 15.0
	base_cooldown = 3.0
	base_mana_cost = 20.0
	effect_range = 100.0
	projectile_speed = bullet_speed


# =============================================================================
# 技能效果
# =============================================================================

func _execute_direction_effect(direction: Variant) -> void:
	"""
	执行扇形弹幕效果
	"""
	if owner_node == null:
		return

	var dir: Vector2 = Vector2.RIGHT
	if direction is Vector2:
		dir = direction.normalized()
	elif direction is Dictionary:
		if direction.has("x") and direction.has("y"):
			dir = Vector2(direction.x, direction.y).normalized()

	# 计算扇形参数
	var count: int = get_bullet_count()
	var half_spread: float = deg_to_rad(get_spread_angle() / 2.0)
	var base_angle: float = dir.angle()

	# 发射扇形子弹
	for i in range(count):
		var t: float = count / 2.0
		if count > 1:
			t = (float(i) / float(count - 1)) - 0.5
		else:
			t = 0.0

		var bullet_angle: float = base_angle + deg_to_rad(t * get_spread_angle())
		var bullet_dir: Vector2 = Vector2(cos(bullet_angle), sin(bullet_angle))

		_create_fan_bullet(bullet_dir)

	# 播放音效
	AudioManager.play_sfx("fan_shot")


func _create_fan_bullet(direction: Vector2) -> void:
	"""
	创建单颗扇形子弹
	"""
	if owner_node == null:
		return

	var bullet: Area2D = Area2D.new()
	bullet.name = "FanBullet"

	# 设置碰撞形状
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 6.0
	collision.shape = shape
	bullet.add_child(collision)

	# 创建视觉效果
	var sprite: Sprite2D = Sprite2D.new()
	var texture: ImageTexture = ImageTexture.new()
	var image: Image = Image.create(12, 12, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.9, 0.7, 0.3))  # 金黄色子弹
	texture.set_image(image)
	sprite.texture = texture
	bullet.add_child(sprite)

	# 设置子弹脚本
	var script: GDScript = GDScript.new()
	script.source_code = """
extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 450.0
var damage: float = 9.0
var owner_node: Node = null
var lifetime: float = 2.5
var hit_targets: Array = []

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
	if body in hit_targets:
		return
	if body.has_method("take_damage"):
		body.take_damage(damage, owner_node)
		hit_targets.append(body)
	queue_free()

func _on_area_entered(area: Node) -> void:
	if area.get_parent() == owner_node:
		return
	var parent = area.get_parent()
	if parent in hit_targets:
		return
	if parent.has_method("take_damage"):
		parent.take_damage(damage, owner_node)
		hit_targets.append(parent)
	queue_free()
"""
	script.reload()
	bullet.set_script(script)

	# 设置属性
	bullet.set("direction", direction)
	bullet.set("speed", get_bullet_speed())
	bullet.set("damage", get_bullet_damage())
	bullet.set("owner_node", owner_node)
	bullet.set("lifetime", bullet_lifetime)

	# 设置位置
	bullet.global_position = owner_node.global_position + direction * 20.0

	# 设置碰撞
	bullet.collision_layer = 4
	bullet.collision_mask = 2 | 16

	# 添加到场景
	owner_node.get_tree().current_scene.add_child(bullet)


# =============================================================================
# 属性获取
# =============================================================================

func get_bullet_count() -> int:
	"""
	获取子弹数量（受等级影响）
	"""
	# 等级1: 5颗, 等级2: 6颗, 等级3: 7颗
	return bullet_count + (current_level - 1)


func get_spread_angle() -> float:
	"""
	获取展开角度（受等级影响）
	"""
	# 每级增加5度
	return spread_angle + (current_level - 1) * 5.0


func get_bullet_damage() -> float:
	"""
	获取单颗子弹伤害
	"""
	return get_damage() * bullet_damage_ratio


func get_bullet_speed() -> float:
	"""
	获取子弹速度
	"""
	return projectile_speed * (1.0 + (current_level - 1) * 0.1)


# =============================================================================
# 升级效果
# =============================================================================

func _on_level_up(new_level: int) -> void:
	"""
	升级时增强扇形弹幕
	"""
	match new_level:
		2:
			bullet_damage_ratio = 0.7
		3:
			bullet_damage_ratio = 0.8
			bullet_lifetime = 3.0
