## Void Hunter - 子弹基类
## @description: 所有子弹的基类，处理移动、碰撞和伤害
## @author: Void Hunter Team
## @version: 1.0.0

extends Area2D
class_name BulletBase

# =============================================================================
# 信号定义
# =============================================================================

## 子弹击中目标时触发
signal hit_target(target: Node)

## 子弹销毁时触发
signal bullet_destroyed()

# =============================================================================
# 常量定义
# =============================================================================

## 默认子弹速度
const DEFAULT_SPEED: float = 400.0

## 默认伤害值
const DEFAULT_DAMAGE: float = 10.0

## 默认生存时间
const DEFAULT_LIFETIME: float = 3.0

## 默认击退力度
const DEFAULT_KNOCKBACK: float = 100.0

# =============================================================================
# 枚举定义
# =============================================================================

## 子弹类型
enum BulletType {
	STRAIGHT,	## 直线飞行
	HOMING,		## 追踪
	SCATTER,	## 散射
	BOUNCING,	## 反弹
	PIERCING	## 穿透
}

## 子弹来源
enum BulletSource {
	PLAYER,		## 玩家发射
	ENEMY,		## 敌人发射
	NEUTRAL		## 中立
}

# =============================================================================
# 导出变量
# =============================================================================

## 子弹类型
@export var bullet_type: BulletType = BulletType.STRAIGHT

## 子弹来源
@export var source: BulletSource = BulletSource.PLAYER

## 飞行速度
@export var speed: float = DEFAULT_SPEED

## 伤害值
@export var damage: float = DEFAULT_DAMAGE

## 生存时间
@export var lifetime: float = DEFAULT_LIFETIME

## 击退力度
@export var knockback_force: float = DEFAULT_KNOCKBACK

## 是否穿透
@export var piercing: bool = false

## 最大穿透次数
@export var max_pierce_count: int = 1

## 追踪强度（仅追踪子弹）
@export_range(0.0, 1.0) var homing_strength: float = 0.1

## 追踪范围（仅追踪子弹）
@export var homing_range: float = 300.0

## 最大反弹次数（仅反弹子弹）
@export var max_bounce_count: int = 3

## 散射角度范围（仅散射子弹）
@export var scatter_angle: float = PI / 6

# =============================================================================
# 公共变量
# =============================================================================

## 飞行方向
var direction: Vector2 = Vector2.RIGHT

## 是否为玩家子弹
var is_player_bullet: bool = true

## 已穿透次数
var pierce_count: int = 0

## 已反弹次数
var bounce_count: int = 0

## 当前追踪目标
var homing_target: Node2D = null

# =============================================================================
# 私有变量
# =============================================================================

var _lifetime_timer: float = 0.0
var _hit_targets: Array[Node] = []

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""
	节点就绪时初始化子弹
	"""
	_initialize_bullet()


func _physics_process(delta: float) -> void:
	"""
	物理帧更新
	@param delta: 帧间隔时间
	"""
	# 更新生存时间
	_update_lifetime(delta)
	
	# 根据类型更新移动
	match bullet_type:
		BulletType.HOMING:
			_update_homing_movement(delta)
		_:
			_update_straight_movement(delta)
	
	# 移动子弹
	position += direction * speed * delta


func _on_body_entered(body: Node2D) -> void:
	"""
	碰撞体进入时处理
	@param body: 碰撞的物体
	"""
	_handle_collision(body)


func _on_area_entered(area: Area2D) -> void:
	"""
	区域进入时处理
	@param area: 碰撞的区域
	"""
	# 检查是否是伤害区域
	if area.is_in_group("hitboxes"):
		var owner_node: Node = area.get_parent()
		_handle_collision(owner_node)

# =============================================================================
# 公共方法
# =============================================================================

## 初始化子弹
func initialize(start_pos: Vector2, dir: Vector2, dmg: float, is_player: bool = true) -> void:
	"""
	初始化子弹参数
	@param start_pos: 起始位置
	@param dir: 飞行方向
	@param dmg: 伤害值
	@param is_player: 是否为玩家子弹
	"""
	global_position = start_pos
	direction = dir.normalized()
	damage = dmg
	is_player_bullet = is_player
	source = BulletSource.PLAYER if is_player else BulletSource.ENEMY
	
	_setup_collision()


## 设置方向
func set_direction(dir: Vector2) -> void:
	"""
	设置飞行方向
	@param dir: 飞行方向
	"""
	direction = dir.normalized()
	rotation = direction.angle()


## 设置伤害
func set_damage(dmg: float) -> void:
	"""
	设置伤害值
	@param dmg: 伤害值
	"""
	damage = dmg


## 设置速度
func set_speed(spd: float) -> void:
	"""
	设置飞行速度
	@param spd: 速度值
	"""
	speed = spd


## 销毁子弹
func destroy() -> void:
	"""
	销毁子弹
	"""
	bullet_destroyed.emit()
	_play_destroy_effect()
	queue_free()


## 强制设置穿透
func set_piercing(enabled: bool, max_pierce: int = 1) -> void:
	"""
	设置穿透属性
	@param enabled: 是否穿透
	@param max_pierce: 最大穿透次数
	"""
	piercing = enabled
	max_pierce_count = max_pierce

# =============================================================================
# 私有方法 - 初始化
# =============================================================================

func _initialize_bullet() -> void:
	"""
	初始化子弹内部状态
	"""
	_lifetime_timer = lifetime
	pierce_count = 0
	bounce_count = 0
	_hit_targets.clear()
	
	# 设置初始旋转
	rotation = direction.angle()
	
	# 连接碰撞信号
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	
	# 设置碰撞
	_setup_collision()


func _setup_collision() -> void:
	"""
	设置碰撞层和掩码
	"""
	if is_player_bullet:
		# 玩家子弹碰撞设置
		collision_layer = 16  # Player Bullet layer
		collision_mask = 2 | 64  # Enemies, Obstacles
	else:
		# 敌人子弹碰撞设置
		collision_layer = 32  # Enemy Bullet layer
		collision_mask = 1 | 64  # Player, Obstacles

# =============================================================================
# 私有方法 - 更新
# =============================================================================

func _update_lifetime(delta: float) -> void:
	"""
	更新生存时间
	@param delta: 帧间隔时间
	"""
	_lifetime_timer -= delta
	if _lifetime_timer <= 0:
		destroy()


func _update_straight_movement(delta: float) -> void:
	"""
	更新直线移动
	@param delta: 帧间隔时间
	"""
	# 直线移动不需要额外处理
	pass


func _update_homing_movement(delta: float) -> void:
	"""
	更新追踪移动
	@param delta: 帧间隔时间
	"""
	# 寻找目标
	if homing_target == null or not is_instance_valid(homing_target):
		_find_homing_target()
	
	# 追踪目标
	if homing_target != null:
		var target_direction: Vector2 = (homing_target.global_position - global_position).normalized()
		direction = direction.lerp(target_direction, homing_strength).normalized()
		rotation = direction.angle()

# =============================================================================
# 私有方法 - 碰撞处理
# =============================================================================

func _handle_collision(body: Node) -> void:
	"""
	处理碰撞
	@param body: 碰撞的物体
	"""
	# 检查是否已经击中过
	if body in _hit_targets:
		return
	
	# 检查是否是障碍物
	if body.is_in_group("obstacles") or body.is_in_group("walls"):
		_handle_obstacle_collision(body)
		return
	
	# 检查是否是有效目标
	var is_valid_target: bool = false
	if is_player_bullet and body.is_in_group("enemies"):
		is_valid_target = true
	elif not is_player_bullet and body.is_in_group("players"):
		is_valid_target = true
	
	if is_valid_target:
		_apply_damage_to_target(body)
		_hit_targets.append(body)
		hit_target.emit(body)
		
		# 检查穿透
		if piercing:
			pierce_count += 1
			if pierce_count >= max_pierce_count:
				destroy()
		else:
			destroy()


func _handle_obstacle_collision(obstacle: Node) -> void:
	"""
	处理障碍物碰撞
	@param obstacle: 障碍物节点
	"""
	if bullet_type == BulletType.BOUNCING and bounce_count < max_bounce_count:
		# 反弹
		_bounce(obstacle)
	else:
		# 销毁
		destroy()


func _bounce(obstacle: Node) -> void:
	"""
	反弹处理
	@param obstacle: 碰撞的障碍物
	"""
	# 简单反弹：反向
	direction = -direction
	bounce_count += 1
	
	# 播放反弹效果
	_play_bounce_effect()


func _apply_damage_to_target(target: Node) -> void:
	"""
	对目标造成伤害
	@param target: 目标节点
	"""
	if target.has_method("take_damage"):
		target.take_damage(damage, self)
		
		# 应用击退
		if target.has_method("_apply_knockback"):
			target._apply_knockback(global_position)
		elif "velocity" in target:
			target.velocity += direction * knockback_force


func _find_homing_target() -> void:
	"""
	寻找追踪目标
	"""
	var targets: Array[Node]
	
	if is_player_bullet:
		targets = get_tree().get_nodes_in_group("enemies")
	else:
		targets = get_tree().get_nodes_in_group("players")
	
	var closest_target: Node2D = null
	var closest_distance: float = homing_range
	
	for target in targets:
		if not is_instance_valid(target) or target is not Node2D:
			continue
		
		var distance: float = global_position.distance_to(target.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_target = target
	
	homing_target = closest_target

# =============================================================================
# 私有方法 - 视觉效果
# =============================================================================

func _play_destroy_effect() -> void:
	"""
	播放销毁效果
	"""
	# 可以添加粒子效果等
	pass


func _play_bounce_effect() -> void:
	"""
	播放反弹效果
	"""
	# 可以添加音效和视觉反馈
	AudioManager.play_sfx_variant("bullet_bounce", 2, 0.3)

# =============================================================================
# 对象池接口
# =============================================================================

func on_spawn() -> void:
	"""
	从对象池取出时的初始化
	"""
	_lifetime_timer = lifetime
	pierce_count = 0
	bounce_count = 0
	_hit_targets.clear()
	homing_target = null
	modulate = Color.WHITE


func on_despawn() -> void:
	"""
	归还到对象池时的清理
	"""
	_hit_targets.clear()
	homing_target = null


func reset() -> void:
	"""
	重置子弹状态
	"""
	on_despawn()
	on_spawn()
