## Void Hunter - 远程射手
## @description: 保持距离，发射子弹的远程敌人
## @author: Void Hunter Team
## @version: 1.0.0

extends EnemyBase
class_name EnemyRanged

# =============================================================================
# 信号定义
# =============================================================================

## 发射子弹时触发
signal bullet_fired(bullet: Node)

# =============================================================================
# 导出变量
# =============================================================================

## 子弹速度
@export var bullet_speed: float = 250.0

## 子弹伤害
@export var bullet_damage: float = 8.0

## 理想射击距离
@export var ideal_distance: float = 200.0

## 最小射击距离
@export var min_distance: float = 100.0

## 子弹散射角度
@export var bullet_spread: float = 0.1

## 是否三连射
@export var triple_shot: bool = false

# =============================================================================
# 私有变量
# =============================================================================

var _bullet_scene: PackedScene = null

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""
	节点就绪时初始化
	"""
	# 设置远程敌人属性
	enemy_type = EnemyType.RANGED
	enemy_name = "远程射手"
	
	# 中等血量
	max_health = 40.0
	current_health = max_health
	
	# 中等速度
	move_speed = 70.0
	
	# 远程伤害
	attack_damage = bullet_damage
	attack_cooldown = 1.5
	
	# 检测范围大，攻击范围也大
	attack_range = 250.0
	detection_range = 350.0
	
	# 掉落
	experience_reward = 12
	gold_reward = 5
	drop_chance = 0.1
	
	# 加载子弹场景
	_load_bullet_scene()
	
	super._ready()

# =============================================================================
# 重写方法
# =============================================================================

func _handle_chase_state(_delta: float) -> void:
	"""
	处理追逐状态 - 远程敌人保持距离
	"""
	if current_target == null or not is_instance_valid(current_target):
		clear_target()
		return
	
	var distance_to_target: float = global_position.distance_to(current_target.global_position)
	
	# 检查是否超出追击范围
	if distance_to_target > chase_limit:
		clear_target()
		return
	
	# 检查是否进入攻击范围
	if distance_to_target <= attack_range:
		set_state(EnemyState.ATTACK)
		return
	
	# 追击目标
	move_to_position(current_target.global_position)


func _handle_attack_state(_delta: float) -> void:
	"""
	处理攻击状态 - 保持理想距离并射击
	"""
	if current_target == null or not is_instance_valid(current_target):
		clear_target()
		return
	
	var distance_to_target: float = global_position.distance_to(current_target.global_position)
	
	# 面向目标
	facing_direction = (current_target.global_position - global_position).normalized()
	
	# 距离控制
	if distance_to_target < min_distance:
		# 太近，后退
		velocity = -facing_direction * move_speed * 0.8
	elif distance_to_target > attack_range:
		# 太远，追击
		set_state(EnemyState.CHASE)
		return
	else:
		# 在理想范围内，停止移动
		velocity = Vector2.ZERO
	
	# 执行攻击
	if _attack_timer <= 0 and not _is_attacking:
		_perform_attack()

# =============================================================================
# 私有方法 - 攻击
# =============================================================================

func _perform_attack() -> void:
	"""
	执行攻击 - 发射子弹
	"""
	_is_attacking = true
	_attack_timer = attack_cooldown
	
	# 播放攻击动画
	_play_attack_animation()
	
	# 发射子弹
	await get_tree().create_timer(0.2).timeout
	
	if current_target != null and is_instance_valid(current_target):
		_fire_bullet()
	
	_is_attacking = false


func _fire_bullet() -> void:
	"""
	发射子弹
	"""
	var direction: Vector2 = (current_target.global_position - global_position).normalized()
	
	# 添加散射
	direction = direction.rotated(randf_range(-bullet_spread, bullet_spread))
	
	if triple_shot:
		# 三连射
		for i in range(3):
			var spread_angle: float = (i - 1) * 0.2
			var bullet_dir: Vector2 = direction.rotated(spread_angle)
			_create_bullet(bullet_dir)
			await get_tree().create_timer(0.1).timeout
	else:
		_create_bullet(direction)
	
	# 播放射击音效
	AudioManager.play_sfx_variant("enemy_shoot", 2, 0.5)


func _create_bullet(direction: Vector2) -> void:
	"""
	创建子弹
	@param direction: 子弹方向
	"""
	var bullet: Area2D = Area2D.new()
	bullet.add_to_group("enemy_bullets")
	
	# 添加碰撞形状
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 5.0
	collision.shape = shape
	bullet.add_child(collision)
	
	# 添加子弹脚本
	bullet.set_script(preload("res://src/projectiles/bullet_base.gd"))
	bullet.set("direction", direction)
	bullet.set("damage", bullet_damage)
	bullet.set("speed", bullet_speed)
	bullet.set("is_player_bullet", false)
	bullet.global_position = global_position
	
	# 添加视觉效果
	var sprite: Sprite2D = Sprite2D.new()
	var texture: ImageTexture = ImageTexture.new()
	var image: Image = Image.create(10, 10, false, Image.FORMAT_RGBA8)
	image.fill(Color.RED)
	texture.set_image(image)
	sprite.texture = texture
	bullet.add_child(sprite)
	
	# 添加到场景
	get_tree().current_scene.add_child(bullet)
	bullet_fired.emit(bullet)


func _load_bullet_scene() -> void:
	"""
	加载子弹场景
	"""
	var bullet_path: String = "res://scenes/enemy_bullet.tscn"
	if ResourceLoader.exists(bullet_path):
		_bullet_scene = load(bullet_path)

# =============================================================================
# 对象池接口
# =============================================================================

func on_spawn() -> void:
	"""
	从对象池取出时的初始化
	"""
	super.on_spawn()
