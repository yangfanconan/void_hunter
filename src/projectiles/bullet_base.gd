## Void Hunter - 子弹基类
## @description: 所有子弹的基类，处理移动、碰撞和伤害
## @author: Void Hunter Team
## @version: 1.0.0

extends Area2D

# =============================================================================
# 信号定义
# =============================================================================

## 击中目标时触发
signal hit_target(target: Node)

## 子弹销毁时触发
signal destroyed()

## 穿透时触发
signal pierced(target: Node)

# =============================================================================
# 常量定义
# =============================================================================

## 默认子弹速度
const DEFAULT_SPEED: float = 400.0

## 默认子弹伤害
const DEFAULT_DAMAGE: float = 10.0

## 默认子弹存活时间
const DEFAULT_LIFETIME: float = 3.0

## 默认穿透次数
const DEFAULT_PIERCE_COUNT: int = 0

# =============================================================================
# 导出变量
# =============================================================================

## 移动速度
@export var speed: float = DEFAULT_SPEED

## 伤害值
@export var damage: float = DEFAULT_DAMAGE

## 存活时间
@export_range(0.5, 10.0) var lifetime: float = DEFAULT_LIFETIME

## 是否是玩家子弹
@export var is_player_bullet: bool = true

## 穿透次数（0 = 无穿透）
@export var pierce_count: int = DEFAULT_PIERCE_COUNT

## 是否有击退效果
@export var has_knockback: bool = true

## 击退力度
@export var knockback_force: float = 100.0

## 子弹大小
@export var bullet_size: float = 1.0

# =============================================================================
# 公共变量
# =============================================================================

## 移动方向
var direction: Vector2 = Vector2.RIGHT

## 当前穿透次数
var current_pierce: int = 0

## 已击中的目标列表
var hit_targets: Array[Node] = []

# =============================================================================
# 私有变量
# =============================================================================

var _lifetime_timer: float = 0.0
var _is_destroyed: bool = false

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""节点就绪时初始化"""
	_initialize_bullet()


func _physics_process(delta: float) -> void:
	"""物理帧更新"""
	# 更新存活时间
	_lifetime_timer += delta
	if _lifetime_timer >= lifetime:
		_destroy_bullet()
		return
	
	# 移动子弹
	_move_bullet(delta)


func _process(_delta: float) -> void:
	"""每帧更新"""
	# 更新旋转（面向移动方向）
	if direction != Vector2.ZERO:
		rotation = direction.angle()

# =============================================================================
# 公共方法 - 初始化
# =============================================================================

## 初始化子弹
func initialize(dir: Vector2, spd: float, dmg: float) -> void:
	"""初始化子弹参数"""
	direction = dir.normalized()
	speed = spd
	damage = dmg


## 设置方向
func set_direction(dir: Vector2) -> void:
	"""设置移动方向"""
	direction = dir.normalized()


## 设置伤害
func set_damage(dmg: float) -> void:
	"""设置伤害值"""
	damage = dmg


## 设置速度
func set_speed(spd: float) -> void:
	"""设置移动速度"""
	speed = spd

# =============================================================================
# 公共方法 - 控制
# =============================================================================

## 销毁子弹
func destroy() -> void:
	"""手动销毁子弹"""
	_destroy_bullet()

# =============================================================================
# 私有方法 - 初始化
# =============================================================================

func _initialize_bullet() -> void:
	"""初始化子弹内部状态"""
	_lifetime_timer = 0.0
	current_pierce = pierce_count
	hit_targets.clear()
	
	# 连接碰撞信号
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# 设置碰撞层和掩码
	_setup_collision()
	
	# 确保有碰撞形状
	_ensure_collision_shape()
	
	# 确保有视觉表现
	_ensure_visual()


func _setup_collision() -> void:
	"""设置碰撞层和掩码"""
	if is_player_bullet:
		# 玩家子弹：在第3层，检测敌人和障碍物（第2和第4层）
		collision_layer = 4  # 第3层 (1 << 2)
		collision_mask = 6   # 第2和第3层 (1 << 1 | 1 << 2)
	else:
		# 敌人子弹：在第3层，检测玩家和障碍物
		collision_layer = 4  # 第3层
		collision_mask = 12  # 第3和第4层 (1 << 2 | 1 << 3)


func _ensure_collision_shape() -> void:
	"""确保有碰撞形状"""
	var has_collision: bool = false
	for child in get_children():
		if child is CollisionShape2D:
			has_collision = true
			break
	
	if not has_collision:
		var collision: CollisionShape2D = CollisionShape2D.new()
		collision.name = "CollisionShape2D"
		var shape: CircleShape2D = CircleShape2D.new()
		shape.radius = 5.0 * bullet_size
		collision.shape = shape
		add_child(collision)


func _ensure_visual() -> void:
	"""确保有视觉表现"""
	var has_sprite: bool = false
	for child in get_children():
		if child is Sprite2D:
			has_sprite = true
			break
	
	if not has_sprite:
		var sprite: Sprite2D = Sprite2D.new()
		sprite.name = "Sprite"
		var texture: ImageTexture = ImageTexture.new()
		var size: int = int(10 * bullet_size)
		var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
		
		# 玩家子弹是青色，敌人子弹是红色
		if is_player_bullet:
			image.fill(Color(0.2, 0.8, 0.9))
		else:
			image.fill(Color(0.9, 0.3, 0.2))
		
		texture.set_image(image)
		sprite.texture = texture
		add_child(sprite)

# =============================================================================
# 私有方法 - 更新
# =============================================================================

func _move_bullet(delta: float) -> void:
	"""移动子弹"""
	global_position += direction * speed * delta


func _destroy_bullet() -> void:
	"""销毁子弹"""
	if _is_destroyed:
		return
	
	_is_destroyed = true
	destroyed.emit()
	queue_free()

# =============================================================================
# 私有方法 - 伤害处理
# =============================================================================

func _apply_damage(target: Node) -> void:
	"""对目标造成伤害"""
	if target.has_method("take_damage"):
		target.take_damage(damage, self)
	
	# 应用击退
	if has_knockback and target.has_method("knockback"):
		target.knockback(direction, knockback_force)
	
	# 记录击中
	hit_targets.append(target)
	hit_target.emit(target)


func _check_pierce() -> bool:
	"""检查是否可以穿透"""
	if current_pierce > 0:
		current_pierce -= 1
		pierced.emit(hit_targets[-1] if hit_targets.size() > 0 else null)
		return true
	return false

# =============================================================================
# 信号回调
# =============================================================================

func _on_body_entered(body: Node) -> void:
	"""身体进入检测区域"""
	# 检查是否已经击中过
	if body in hit_targets:
		return
	
	# 玩家子弹击中敌人
	if is_player_bullet:
		if body.is_in_group("enemies"):
			_apply_damage(body)
			if not _check_pierce():
				_destroy_bullet()
		elif body.is_in_group("obstacles"):
			# 击中障碍物
			_destroy_bullet()
	# 敌人子弹击中玩家
	else:
		if body.is_in_group("players"):
			_apply_damage(body)
			if not _check_pierce():
				_destroy_bullet()
		elif body.is_in_group("obstacles"):
			# 击中障碍物
			_destroy_bullet()


func _on_area_entered(area: Node) -> void:
	"""区域进入检测"""
	# 检查是否已经击中过
	if area in hit_targets:
		return
	
	# 处理区域类型的碰撞体
	if area.has_method("take_damage"):
		_apply_damage(area)
		if not _check_pierce():
			_destroy_bullet()
