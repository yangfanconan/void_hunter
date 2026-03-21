## Void Hunter - 散射子弹
## @description: 发射多个子弹的散射模式
## @author: Void Hunter Team
## @version: 1.0.0

extends BulletBase
class_name BulletScatter

# =============================================================================
# 导出变量
# =============================================================================

## 散射子弹数量
@export var bullet_count: int = 5

## 散射角度范围（总角度）
@export var spread_angle: float = PI / 3

## 是否同时发射
@export var fire_simultaneously: bool = true

## 连续发射间隔
@export var burst_interval: float = 0.05

## 子弹之间的伤害衰减
@export_range(0.0, 1.0) var damage_falloff: float = 0.0

# =============================================================================
# 私有变量
# =============================================================================

var _bullets_spawned: int = 0
var _burst_timer: float = 0.0
var _is_spawning: bool = true

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""
	节点就绪时初始化
	"""
	bullet_type = BulletType.SCATTER
	super._ready()
	
	if fire_simultaneously:
		_spawn_all_bullets()


func _physics_process(delta: float) -> void:
	"""
	物理帧更新
	@param delta: 帧间隔时间
	"""
	if not _is_spawning:
		super._physics_process(delta)
		return
	
	# 连续发射模式
	if not fire_simultaneously:
		_burst_timer -= delta
		if _burst_timer <= 0 and _bullets_spawned < bullet_count:
			_spawn_single_bullet()
			_burst_timer = burst_interval
		
		if _bullets_spawned >= bullet_count:
			_is_spawning = false
			# 散射器自身销毁
			destroy()

# =============================================================================
# 公共方法
# =============================================================================

## 设置散射参数
func setup_scatter(base_direction: Vector2, count: int, spread: float) -> void:
	"""
	设置散射参数
	@param base_direction: 基础方向
	@param count: 子弹数量
	@param spread: 散射角度
	"""
	direction = base_direction
	bullet_count = count
	spread_angle = spread

# =============================================================================
# 私有方法
# =============================================================================

func _spawn_all_bullets() -> void:
	"""
	同时生成所有散射子弹
	"""
	var angle_step: float = spread_angle / (bullet_count - 1) if bullet_count > 1 else 0.0
	var start_angle: float = -spread_angle / 2.0
	
	for i in range(bullet_count):
		var bullet_angle: float = start_angle + angle_step * i
		var bullet_direction: Vector2 = direction.rotated(bullet_angle)
		
		# 计算伤害衰减
		var damage_mult: float = 1.0 - damage_falloff * abs(float(i - bullet_count / 2.0) / (bullet_count / 2.0))
		var bullet_damage: float = damage * damage_mult
		
		_create_bullet(bullet_direction, bullet_damage)
	
	# 散射器自身立即销毁
	_is_spawning = false
	queue_free()


func _spawn_single_bullet() -> void:
	"""
	生成单个散射子弹
	"""
	var angle_step: float = spread_angle / bullet_count
	var bullet_angle: float = -spread_angle / 2.0 + angle_step * _bullets_spawned
	var bullet_direction: Vector2 = direction.rotated(bullet_angle)
	
	var damage_mult: float = 1.0 - damage_falloff * abs(float(_bullets_spawned - bullet_count / 2.0) / (bullet_count / 2.0))
	var bullet_damage: float = damage * damage_mult
	
	_create_bullet(bullet_direction, bullet_damage)
	_bullets_spawned += 1


func _create_bullet(bullet_direction: Vector2, bullet_damage: float) -> void:
	"""
	创建单个子弹
	@param bullet_direction: 子弹方向
	@param bullet_damage: 子弹伤害
	"""
	var bullet: BulletBase = BulletBase.new()
	bullet.bullet_type = BulletType.STRAIGHT
	bullet.direction = bullet_direction
	bullet.damage = bullet_damage
	bullet.speed = speed
	bullet.is_player_bullet = is_player_bullet
	bullet.global_position = global_position
	bullet.knockback_force = knockback_force
	
	# 添加碰撞形状
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 5.0
	collision.shape = shape
	bullet.add_child(collision)
	
	# 添加可视表示
	var sprite: Sprite2D = Sprite2D.new()
	var texture: ImageTexture = ImageTexture.new()
	var image: Image = Image.create(10, 10, false, Image.FORMAT_RGBA8)
	image.fill(Color.YELLOW if is_player_bullet else Color.RED)
	texture.set_image(image)
	sprite.texture = texture
	bullet.add_child(sprite)
	
	get_tree().current_scene.add_child(bullet)
