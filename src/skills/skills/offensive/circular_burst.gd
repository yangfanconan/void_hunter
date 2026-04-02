## Void Hunter - 圆形弹幕技能
## @description: 向四周发射子弹，形成圆形弹幕
## @author: Void Hunter Team
## @version: 1.0.0

extends SkillBase
class_name SkillCircularBurst

# =============================================================================
# 配置参数
# =============================================================================

## 圆形子弹数量
@export var bullet_count: int = 12

## 每颗子弹伤害倍率
@export var bullet_damage_ratio: float = 0.5

## 子弹速度
@export var bullet_speed: float = 350.0

## 子弹存活时间
@export var bullet_lifetime: float = 3.0

## 是否发射多波
@export var multi_wave: bool = false

## 波次间隔
@export var wave_interval: float = 0.3

## 额外波次数
@export var extra_waves: int = 1

# =============================================================================
# 内部变量
# =============================================================================

var _current_wave: int = 0

# =============================================================================
# 初始化
# =============================================================================

func _init() -> void:
	skill_id = "circular_burst"
	skill_name = "圆形弹幕"
	description = "向四周发射子弹，形成360度圆形弹幕，覆盖所有方向。"
	skill_type = SkillType.ACTIVE
	skill_category = SkillCategory.OFFENSIVE
	target_type = TargetType.SELF
	element = SkillElement.ARCANE
	hotkey_slot = 2

	base_damage = 12.0
	base_cooldown = 4.0
	base_mana_cost = 25.0
	effect_range = 80.0
	projectile_speed = bullet_speed


# =============================================================================
# 技能效果
# =============================================================================

func _execute_self_effect() -> void:
	"""
	执行圆形弹幕效果
	"""
	if owner_node == null:
		return

	# 检查是否有多波
	if is_multi_wave():
		_fire_wave_series()
	else:
		_fire_circular_burst(0.0)


func _fire_wave_series() -> void:
	"""
	发射多波弹幕
	"""
	for wave in range(get_wave_count()):
		await owner_node.get_tree().create_timer(wave * wave_interval).timeout
		_fire_circular_burst(wave * (PI / get_wave_count()))


func _fire_circular_burst(angle_offset: float = 0.0) -> void:
	"""
	发射一圈弹幕
	"""
	var count: int = get_bullet_count()
	var angle_step: float = TAU / count

	for i in range(count):
		var angle: float = i * angle_step + angle_offset
		var direction: Vector2 = Vector2(cos(angle), sin(angle))
		_create_circular_bullet(direction)

	# 播放音效
	AudioManager.play_sfx("circular_burst")


func _create_circular_bullet(direction: Vector2) -> void:
	"""
	创建单颗圆形弹幕子弹
	"""
	if owner_node == null:
		return

	var bullet: Area2D = Area2D.new()
	bullet.name = "CircularBullet"

	# 设置碰撞形状
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 5.0
	collision.shape = shape
	bullet.add_child(collision)

	# 创建视觉效果 - 紫色奥术能量
	var sprite: Sprite2D = Sprite2D.new()
	var texture: ImageTexture = ImageTexture.new()
	var image: Image = Image.create(10, 10, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.6, 0.3, 0.9))  # 紫色
	texture.set_image(image)
	sprite.texture = texture
	bullet.add_child(sprite)

	# 设置子弹脚本
	var script: GDScript = GDScript.new()
	script.source_code = """
extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 350.0
var damage: float = 6.0
var owner_node: Node = null
var lifetime: float = 3.0
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

	# VFX: small explosion on burst hit
	if VFXManager:
		VFXManager.spawn_effect("explosion_small", global_position)

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

	# VFX: small explosion on burst hit
	if VFXManager:
		VFXManager.spawn_effect("explosion_small", global_position)

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
	bullet.global_position = owner_node.global_position + direction * 15.0

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
	# 等级1: 12颗, 等级2: 14颗, 等级3: 16颗
	return bullet_count + (current_level - 1) * 2


func get_bullet_damage() -> float:
	"""
	获取单颗子弹伤害
	"""
	return get_damage() * bullet_damage_ratio


func get_bullet_speed() -> float:
	"""
	获取子弹速度
	"""
	return projectile_speed * (1.0 + (current_level - 1) * 0.15)


func is_multi_wave() -> bool:
	"""
	是否发射多波
	"""
	return multi_wave or current_level >= 3


func get_wave_count() -> int:
	"""
	获取波次数量
	"""
	if current_level >= 3:
		return extra_waves + 2
	return extra_waves + 1


# =============================================================================
# 升级效果
# =============================================================================

func _on_level_up(new_level: int) -> void:
	"""
	升级时增强圆形弹幕
	"""
	match new_level:
		2:
			bullet_damage_ratio = 0.6
			multi_wave = true
		3:
			bullet_damage_ratio = 0.7
			bullet_lifetime = 3.5
