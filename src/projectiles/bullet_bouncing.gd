## Void Hunter - 反弹子弹
## @description: 可以在墙壁和障碍物上反弹的子弹
## @author: Void Hunter Team
## @version: 1.0.0

extends BulletBase
class_name BulletBouncing

# =============================================================================
# 导出变量
# =============================================================================

## 反弹后的速度衰减
@export_range(0.0, 1.0) var speed_reduction_per_bounce: float = 0.1

## 反弹后的伤害衰减
@export_range(0.0, 1.0) var damage_reduction_per_bounce: float = 0.15

## 反弹音效
@export var bounce_sfx: String = "bullet_bounce"

## 是否在反弹时重置生存时间
@export var reset_lifetime_on_bounce: bool = false

## 反弹检测射线长度
@export var raycast_length: float = 20.0

# =============================================================================
# 私有变量
# =============================================================================

var _raycast: RayCast2D = null

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""
	节点就绪时初始化
	"""
	bullet_type = BulletType.BOUNCING
	super._ready()
	_setup_raycast()


func _physics_process(delta: float) -> void:
	"""
	物理帧更新
	@param delta: 帧间隔时间
	"""
	# 检测即将碰撞
	if _raycast:
		_raycast.target_position = direction * raycast_length
		if _raycast.is_colliding():
			_prepare_bounce(_raycast.get_collision_normal())
	
	super._physics_process(delta)

# =============================================================================
# 私有方法
# =============================================================================

func _setup_raycast() -> void:
	"""
	设置射线检测
	"""
	_raycast = RayCast2D.new()
	_raycast.enabled = true
	_raycast.collision_mask = collision_mask
	add_child(_raycast)


func _prepare_bounce(normal: Vector2) -> void:
	"""
	准备反弹
	@param normal: 碰撞法线
	"""
	# 计算反射方向
	var new_direction: Vector2 = direction.bounce(normal)
	
	# 更新方向
	direction = new_direction
	rotation = direction.angle()


func _bounce(_obstacle: Node) -> void:
	"""
	反弹处理
	@param _obstacle: 碰撞的障碍物
	"""
	bounce_count += 1
	
	# 速度衰减
	speed *= (1.0 - speed_reduction_per_bounce)
	
	# 伤害衰减
	damage *= (1.0 - damage_reduction_per_bounce)
	
	# 重置生存时间
	if reset_lifetime_on_bounce:
		_lifetime_timer = lifetime
	
	# 播放反弹效果
	_play_bounce_effect()
	
	# 检查是否达到最大反弹次数
	if bounce_count >= max_bounce_count:
		destroy()

# =============================================================================
# 重写方法
# =============================================================================

func _play_bounce_effect() -> void:
	"""
	播放反弹效果
	"""
	# 闪烁效果
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate", Color.CYAN, 0.05)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
	
	# 音效
	AudioManager.play_sfx_variant(bounce_sfx, 2, 0.3)
