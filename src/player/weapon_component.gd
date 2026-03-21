## Void Hunter - 武器组件
## @description: 管理玩家的武器和射击系统
## @author: Void Hunter Team
## @version: 1.0.0

extends Node
class_name WeaponComponent

# =============================================================================
# 信号定义
# =============================================================================

## 武器开火时触发
signal weapon_fired(bullet: Node)

## 弹药改变时触发
signal ammo_changed(current: int, maximum: int)

## 武器切换时触发
signal weapon_switched(weapon_id: String)

## 装弹开始时触发
signal reload_started()

## 装弹完成时触发
signal reload_completed()

# =============================================================================
# 枚举定义
# =============================================================================

## 子弹类型
enum BulletType {
	STRAIGHT,	## 直线
	HOMING,		## 追踪
	SCATTER,	## 散射
	PIERCING,	## 穿透
	BOUNCING	## 反弹
}

## 射击模式
enum FireMode {
	SINGLE,		## 单发
	AUTO,		## 自动
	BURST		## 连发
}

# =============================================================================
# 导出变量
# =============================================================================

## 子弹类型
@export var bullet_type: BulletType = BulletType.STRAIGHT

## 射击模式
@export var fire_mode: FireMode = FireMode.AUTO

## 基础射击间隔
@export var base_fire_rate: float = 0.5

## 基础伤害
@export var base_damage: float = 10.0

## 子弹速度
@export var bullet_speed: float = 400.0

## 最大弹药（0为无限）
@export var max_ammo: int = 0

## 装弹时间
@export var reload_time: float = 1.5

## 散射子弹数量（仅散射模式）
@export var scatter_count: int = 5

## 散射角度
@export var scatter_angle: float = PI / 3

## 穿透次数（仅穿透模式）
@export var pierce_count: int = 3

## 反弹次数（仅反弹模式）
@export var bounce_count: int = 3

## 追踪强度（仅追踪模式）
@export_range(0.0, 1.0) var homing_strength: float = 0.1

## 连发数量（仅连发模式）
@export var burst_count: int = 3

## 连发间隔
@export var burst_interval: float = 0.1

# =============================================================================
# 公共变量
# =============================================================================

## 当前弹药
var current_ammo: int = 0

## 是否正在装弹
var is_reloading: bool = false

## 是否可以射击
var can_fire: bool = true

## 武器所有者
var owner_node: Node = null

# =============================================================================
# 私有变量
# =============================================================================

var _fire_timer: float = 0.0
var _reload_timer: float = 0.0
var _burst_fired: int = 0
var _burst_timer: float = 0.0
var _is_bursting: bool = false
var _bullet_scenes: Dictionary = {}

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""
	节点就绪时初始化
	"""
	_initialize_weapon()


func _process(delta: float) -> void:
	"""
	每帧更新
	@param delta: 帧间隔时间
	"""
	_update_timers(delta)


# =============================================================================
# 公共方法
# =============================================================================

## 初始化武器
func initialize(owner: Node) -> void:
	"""
	初始化武器
	@param owner: 武器所有者
	"""
	owner_node = owner
	_initialize_weapon()


## 尝试射击
func try_fire(direction: Vector2, damage_multiplier: float = 1.0) -> bool:
	"""
	尝试射击
	@param direction: 射击方向
	@param damage_multiplier: 伤害倍率
	@return: 是否成功射击
	"""
	if not can_fire or is_reloading:
		return false
	
	if _fire_timer > 0:
		return false
	
	# 检查弹药
	if max_ammo > 0 and current_ammo <= 0:
		start_reload()
		return false
	
	# 根据射击模式处理
	match fire_mode:
		FireMode.SINGLE:
			return _fire_single(direction, damage_multiplier)
		FireMode.AUTO:
			return _fire_single(direction, damage_multiplier)
		FireMode.BURST:
			return _fire_burst(direction, damage_multiplier)
	
	return false


## 开始装弹
func start_reload() -> bool:
	"""
	开始装弹
	@return: 是否成功开始装弹
	"""
	if is_reloading or max_ammo == 0:
		return false
	
	if current_ammo >= max_ammo:
		return false
	
	is_reloading = true
	_reload_timer = reload_time
	reload_started.emit()
	
	return true


## 取消装弹
func cancel_reload() -> void:
	"""
	取消装弹
	"""
	is_reloading = false
	_reload_timer = 0.0


## 切换子弹类型
func switch_bullet_type(new_type: BulletType) -> void:
	"""
	切换子弹类型
	@param new_type: 新的子弹类型
	"""
	bullet_type = new_type


## 获取当前武器信息
func get_weapon_info() -> Dictionary:
	"""
	获取武器信息
	@return: 武器信息字典
	"""
	return {
		"bullet_type": BulletType.keys()[bullet_type],
		"fire_mode": FireMode.keys()[fire_mode],
		"fire_rate": base_fire_rate,
		"damage": base_damage,
		"current_ammo": current_ammo,
		"max_ammo": max_ammo,
		"is_reloading": is_reloading
	}


## 增加弹药
func add_ammo(amount: int) -> void:
	"""
	增加弹药
	@param amount: 弹药数量
	"""
	if max_ammo > 0:
		current_ammo = mini(max_ammo, current_ammo + amount)
		ammo_changed.emit(current_ammo, max_ammo)

# =============================================================================
# 私有方法 - 初始化
# =============================================================================

func _initialize_weapon() -> void:
	"""
	初始化武器内部状态
	"""
	current_ammo = max_ammo
	_fire_timer = 0.0
	_reload_timer = 0.0
	is_reloading = false
	can_fire = true
	_is_bursting = false
	_burst_fired = 0
	
	# 预加载子弹场景
	_preload_bullet_scenes()


func _preload_bullet_scenes() -> void:
	"""
	预加载子弹场景
	"""
	_bullet_scenes = {
		BulletType.STRAIGHT: preload("res://src/projectiles/bullet_base.gd"),
		BulletType.HOMING: preload("res://src/projectiles/bullet_homing.gd"),
		BulletType.SCATTER: preload("res://src/projectiles/bullet_scatter.gd"),
		BulletType.PIERCING: preload("res://src/projectiles/bullet_piercing.gd"),
		BulletType.BOUNCING: preload("res://src/projectiles/bullet_bouncing.gd")
	}

# =============================================================================
# 私有方法 - 更新
# =============================================================================

func _update_timers(delta: float) -> void:
	"""
	更新计时器
	@param delta: 帧间隔时间
	"""
	# 射击冷却
	if _fire_timer > 0:
		_fire_timer -= delta
	
	# 装弹计时
	if is_reloading:
		_reload_timer -= delta
		if _reload_timer <= 0:
			_complete_reload()
	
	# 连发计时
	if _is_bursting:
		_burst_timer -= delta
		if _burst_timer <= 0:
			_burst_fired = 0
			_is_bursting = false

# =============================================================================
# 私有方法 - 射击
# =============================================================================

func _fire_single(direction: Vector2, damage_multiplier: float) -> bool:
	"""
	单发射击
	@param direction: 射击方向
	@param damage_multiplier: 伤害倍率
	@return: 是否成功
	"""
	_create_bullet(direction, base_damage * damage_multiplier)
	_fire_timer = base_fire_rate
	
	# 消耗弹药
	if max_ammo > 0:
		current_ammo -= 1
		ammo_changed.emit(current_ammo, max_ammo)
	
	return true


func _fire_burst(direction: Vector2, damage_multiplier: float) -> bool:
	"""
	连发射击
	@param direction: 射击方向
	@param damage_multiplier: 伤害倍率
	@return: 是否成功
	"""
	if _is_bursting and _burst_fired >= burst_count:
		return false
	
	if not _is_bursting:
		_is_bursting = true
		_burst_fired = 0
	
	_create_bullet(direction, base_damage * damage_multiplier)
	_burst_fired += 1
	_burst_timer = burst_interval
	
	# 连发完成后设置冷却
	if _burst_fired >= burst_count:
		_fire_timer = base_fire_rate
	
	# 消耗弹药
	if max_ammo > 0:
		current_ammo -= 1
		ammo_changed.emit(current_ammo, max_ammo)
	
	return true


func _create_bullet(direction: Vector2, damage: float) -> Node:
	"""
	创建子弹
	@param direction: 飞行方向
	@param damage: 伤害值
	@return: 子弹节点
	"""
	var bullet: Node = null
	
	# 根据类型创建子弹
	match bullet_type:
		BulletType.STRAIGHT:
			bullet = _create_straight_bullet(direction, damage)
		BulletType.HOMING:
			bullet = _create_homing_bullet(direction, damage)
		BulletType.SCATTER:
			bullet = _create_scatter_bullets(direction, damage)
		BulletType.PIERCING:
			bullet = _create_piercing_bullet(direction, damage)
		BulletType.BOUNCING:
			bullet = _create_bouncing_bullet(direction, damage)
		_:
			bullet = _create_straight_bullet(direction, damage)
	
	if bullet:
		# 设置位置
		if owner_node:
			bullet.global_position = owner_node.global_position
		
		# 添加到场景
		get_tree().current_scene.add_child(bullet)
		weapon_fired.emit(bullet)
		
		# 播放射击音效
		AudioManager.play_sfx_variant("shoot", 3, 0.5)
	
	return bullet


func _create_straight_bullet(direction: Vector2, damage: float) -> BulletBase:
	"""
	创建直线子弹
	"""
	var bullet: BulletBase = BulletBase.new()
	bullet.direction = direction.normalized()
	bullet.damage = damage
	bullet.speed = bullet_speed
	bullet.is_player_bullet = true
	_setup_bullet_collision(bullet)
	_setup_bullet_visual(bullet, Color.YELLOW)
	return bullet


func _create_homing_bullet(direction: Vector2, damage: float) -> BulletHoming:
	"""
	创建追踪子弹
	"""
	var bullet: BulletHoming = BulletHoming.new()
	bullet.direction = direction.normalized()
	bullet.damage = damage
	bullet.speed = bullet_speed
	bullet.is_player_bullet = true
	bullet.homing_strength = homing_strength
	_setup_bullet_collision(bullet)
	_setup_bullet_visual(bullet, Color.CYAN)
	return bullet


func _create_scatter_bullets(direction: Vector2, damage: float) -> BulletScatter:
	"""
	创建散射子弹
	"""
	var scatter: BulletScatter = BulletScatter.new()
	scatter.direction = direction.normalized()
	scatter.damage = damage
	scatter.speed = bullet_speed
	scatter.is_player_bullet = true
	scatter.bullet_count = scatter_count
	scatter.spread_angle = scatter_angle
	scatter.global_position = owner_node.global_position if owner_node else Vector2.ZERO
	return scatter


func _create_piercing_bullet(direction: Vector2, damage: float) -> BulletPiercing:
	"""
	创建穿透子弹
	"""
	var bullet: BulletPiercing = BulletPiercing.new()
	bullet.direction = direction.normalized()
	bullet.damage = damage
	bullet.speed = bullet_speed
	bullet.is_player_bullet = true
	bullet.max_pierce_count = pierce_count
	_setup_bullet_collision(bullet)
	_setup_bullet_visual(bullet, Color.ORANGE)
	return bullet


func _create_bouncing_bullet(direction: Vector2, damage: float) -> BulletBouncing:
	"""
	创建反弹子弹
	"""
	var bullet: BulletBouncing = BulletBouncing.new()
	bullet.direction = direction.normalized()
	bullet.damage = damage
	bullet.speed = bullet_speed
	bullet.is_player_bullet = true
	bullet.max_bounce_count = bounce_count
	_setup_bullet_collision(bullet)
	_setup_bullet_visual(bullet, Color.LIME)
	return bullet


func _setup_bullet_collision(bullet: Area2D) -> void:
	"""
	设置子弹碰撞
	"""
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 5.0
	collision.shape = shape
	bullet.add_child(collision)


func _setup_bullet_visual(bullet: Node2D, color: Color) -> void:
	"""
	设置子弹视觉效果
	"""
	var sprite: Sprite2D = Sprite2D.new()
	var texture: ImageTexture = ImageTexture.new()
	var image: Image = Image.create(10, 10, false, Image.FORMAT_RGBA8)
	image.fill(color)
	texture.set_image(image)
	sprite.texture = texture
	bullet.add_child(sprite)


func _complete_reload() -> void:
	"""
	完成装弹
	"""
	is_reloading = false
	current_ammo = max_ammo
	reload_completed.emit()
	ammo_changed.emit(current_ammo, max_ammo)
