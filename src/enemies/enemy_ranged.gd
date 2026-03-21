## Void Hunter - 远程敌人
## @description: 远程攻击敌人，保持距离并发射子弹
## @author: Void Hunter Team
## @version: 1.0.0

extends "res://src/enemies/enemy_base.gd"

# =============================================================================
# 信号定义
# =============================================================================

## 射击时触发
signal shot_fired(bullet: Node)

# =============================================================================
# 常量定义
# =============================================================================

## 默认远程速度
const RANGED_SPEED: float = 60.0

## 默认远程生命值
const RANGED_HEALTH: float = 20.0

## 默认远程伤害
const RANGED_DAMAGE: float = 8.0

## 默认远程攻击范围
const RANGED_ATTACK_RANGE: float = 200.0

## 默认远程攻击冷却
const RANGED_ATTACK_COOLDOWN: float = 2.0

## 子弹场景路径
const BULLET_SCENE_PATH: String = "res://src/projectiles/bullet_base.gd"

# =============================================================================
# 导出变量
# =============================================================================

## 子弹速度
@export_range(100.0, 500.0) var bullet_speed: float = 250.0

## 子弹伤害
@export var bullet_damage: float = 8.0

## 保持距离
@export_range(100.0, 300.0) var preferred_distance: float = 150.0

## 子弹场景
@export var bullet_scene: PackedScene = null

# =============================================================================
# 私有变量
# =============================================================================

var _bullet_script: GDScript = null
var _is_retreating: bool = false

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""节点就绪时初始化"""
	_setup_ranged_stats()
	_load_bullet_resource()
	super._ready()

# =============================================================================
# 公共方法
# =============================================================================

## 设置远程属性
func setup_ranged(speed: float, health: float, damage: float) -> void:
	"""设置远程敌人属性"""
	move_speed = speed
	max_health = health
	attack_damage = damage
	current_health = max_health

# =============================================================================
# 私有方法 - 初始化
# =============================================================================

func _setup_ranged_stats() -> void:
	"""设置远程敌人属性"""
	# 如果使用默认值，则设置远程专用属性
	if move_speed == DEFAULT_SPEED:
		move_speed = RANGED_SPEED
	if max_health == DEFAULT_MAX_HEALTH:
		max_health = RANGED_HEALTH
	if attack_damage == DEFAULT_ATTACK_DAMAGE:
		attack_damage = RANGED_DAMAGE
	if attack_range == DEFAULT_ATTACK_RANGE:
		attack_range = RANGED_ATTACK_RANGE
	if attack_cooldown == 1.0:
		attack_cooldown = RANGED_ATTACK_COOLDOWN
	
	# 设置敌人类型
	enemy_type = EnemyType.RANGED
	
	# 设置经验值和金币奖励
	experience_reward = 15
	gold_reward = 8
	
	# 子弹伤害等于攻击伤害
	bullet_damage = attack_damage
	
	print("[EnemyRanged] 初始化完成")


func _load_bullet_resource() -> void:
	"""加载子弹资源"""
	_bullet_script = load(BULLET_SCENE_PATH)

# =============================================================================
# 重写父类方法
# =============================================================================

func _update_chase(_delta: float) -> void:
	"""更新追击状态 - 远程敌人保持距离"""
	if target == null or not is_instance_valid(target):
		clear_target()
		_change_state(State.IDLE)
		return
	
	var dist: float = global_position.distance_to(target.global_position)
	
	# 检查是否超出追击范围
	if dist > chase_range:
		clear_target()
		_change_state(State.IDLE)
		return
	
	# 如果太近，后退
	if dist < preferred_distance * 0.8:
		_is_retreating = true
		var dir: Vector2 = (global_position - target.global_position).normalized()
		velocity = dir * move_speed
	# 如果在攻击范围内，攻击
	elif dist <= attack_range:
		_change_state(State.ATTACK)
		entered_attack_range.emit(target)
	# 如果太远，靠近
	elif dist > attack_range:
		_is_retreating = false
		var dir: Vector2 = (target.global_position - global_position).normalized()
		velocity = dir * move_speed


func _perform_attack() -> void:
	"""执行远程攻击"""
	if target == null or not is_instance_valid(target):
		return
	
	# 发射子弹
	_fire_bullet()
	
	# 播放音效
	AudioManager.play_sfx("enemy_shoot", 0.4)
	
	print("[EnemyRanged] 发射子弹，伤害: %.1f" % bullet_damage)


func _fire_bullet() -> void:
	"""发射子弹"""
	var bullet: Area2D = Area2D.new()
	bullet.set_script(_bullet_script)
	bullet.name = "EnemyBullet"
	
	# 设置子弹属性
	var direction: Vector2 = (target.global_position - global_position).normalized()
	bullet.set("direction", direction)
	bullet.set("speed", bullet_speed)
	bullet.set("damage", bullet_damage)
	bullet.set("is_player_bullet", false)
	bullet.global_position = global_position
	
	# 添加碰撞形状
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 5.0
	collision.shape = shape
	bullet.add_child(collision)
	
	# 添加视觉表现
	var sprite: Sprite2D = Sprite2D.new()
	var texture: ImageTexture = ImageTexture.new()
	var image: Image = Image.create(10, 10, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.8, 0.3, 0.3))  # 红色子弹
	texture.set_image(image)
	sprite.texture = texture
	bullet.add_child(sprite)
	
	# 添加到场景
	var projectiles_container: Node = get_tree().current_scene.get_node_or_null("GameWorld/Projectiles")
	if projectiles_container:
		projectiles_container.add_child(bullet)
	else:
		get_tree().current_scene.add_child(bullet)
	
	shot_fired.emit(bullet)

# =============================================================================
# 视觉效果
# =============================================================================

func _update_visuals() -> void:
	"""更新视觉效果"""
	super._update_visuals()
	
	# 后退时面向玩家
	if _is_retreating and target:
		var angle: float = (target.global_position - global_position).angle()
		rotation = angle
	else:
		rotation = 0
