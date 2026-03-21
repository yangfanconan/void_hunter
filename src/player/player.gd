## Void Hunter - 玩家控制器
## @description: 玩家移动、射击、冲刺和受伤逻辑
## @author: Void Hunter Team
## @version: 1.0.0

extends CharacterBody2D

# =============================================================================
# 信号定义
# =============================================================================

## 受伤时触发
signal damaged(amount: float, source: Node)

## 死亡时触发
signal died()

## 属性变化时触发
signal stats_changed(stats: Resource)

## 升级时触发
signal leveled_up(new_level: int)

## 射击时触发
signal shot_fired(bullet: Node)

## 冲刺开始时触发
signal dash_started()

## 冲刺结束时触发
signal dash_ended()

# =============================================================================
# 常量定义
# =============================================================================

## 基础移动速度
const BASE_MOVE_SPEED: float = 150.0

## 基础冲刺速度倍率
const DASH_SPEED_MULTIPLIER: float = 3.0

## 冲刺持续时间
const DASH_DURATION: float = 0.2

## 冲刺冷却时间
const DASH_COOLDOWN: float = 1.0

## 受伤无敌时间
const INVINCIBILITY_TIME: float = 1.0

## 基础射击冷却
const BASE_SHOOT_COOLDOWN: float = 0.3

## 子弹场景路径
const BULLET_SCRIPT_PATH: String = "res://src/projectiles/bullet_base.gd"

# =============================================================================
# 导出变量
# =============================================================================

## 移动速度
@export_range(50.0, 300.0) var move_speed: float = BASE_MOVE_SPEED

## 冲刺速度倍率
@export_range(1.5, 5.0) var dash_speed_multiplier: float = DASH_SPEED_MULTIPLIER

## 冲刺冷却
@export_range(0.5, 3.0) var dash_cooldown: float = DASH_COOLDOWN

## 射击冷却
@export_range(0.1, 1.0) var shoot_cooldown: float = BASE_SHOOT_COOLDOWN

## 子弹速度
@export var bullet_speed: float = 500.0

## 子弹伤害
@export var bullet_damage: float = 10.0

# =============================================================================
# 公共变量
# =============================================================================

## 玩家属性
var stats: Resource = null

## 瞄准方向
var aim_direction: Vector2 = Vector2.RIGHT

## 移动方向
var move_direction: Vector2 = Vector2.ZERO

# =============================================================================
# 私有变量
# =============================================================================

var _is_dashing: bool = false
var _dash_timer: float = 0.0
var _dash_direction: Vector2 = Vector2.ZERO
var _dash_cooldown_timer: float = 0.0

var _is_invincible: bool = false
var _invincibility_timer: float = 0.0

var _shoot_timer: float = 0.0
var _can_shoot: bool = true

var _bullet_script: GDScript = null
var _projectiles_container: Node = null

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""节点就绪时初始化"""
	_initialize_player()


func _physics_process(delta: float) -> void:
	"""物理帧更新"""
	# 更新计时器
	_update_timers(delta)
	
	# 处理移动
	if _is_dashing:
		_update_dash(delta)
	else:
		_update_movement(delta)
	
	# 处理射击
	_update_shooting(delta)
	
	# 应用移动
	move_and_slide()


func _process(_delta: float) -> void:
	"""每帧更新"""
	# 更新视觉效果
	_update_visuals()
	
	# 更新瞄准方向
	_update_aim_direction()


func _input(event: InputEvent) -> void:
	"""处理输入事件"""
	# 冲刺输入
	if event.is_action_pressed("dash"):
		_try_dash()

# =============================================================================
# 公共方法 - 初始化
# =============================================================================

## 初始化玩家
func initialize() -> void:
	"""手动初始化玩家"""
	_initialize_player()


## 设置属性
func set_stats(new_stats: Resource) -> void:
	"""设置玩家属性"""
	stats = new_stats
	_connect_stats_signals()
	_apply_stats()

# =============================================================================
# 公共方法 - 伤害系统
# =============================================================================

## 受到伤害
func take_damage(amount: float, source: Node = null) -> void:
	"""受到伤害"""
	if _is_invincible or _is_dashing:
		return
	
	if stats == null:
		return
	
	# 计算实际伤害
	var actual_damage: float = amount
	if stats.has_method("get_damage_reduction"):
		var reduction: float = stats.get_damage_reduction()
		actual_damage = amount * (1.0 - reduction)
	
	# 应用伤害
	if stats.has_method("take_damage"):
		stats.take_damage(actual_damage)
	else:
		# 直接修改属性
		var current: float = stats.get("current_health", 100.0)
		stats.set("current_health", max(0, current - actual_damage))
	
	# 触发信号
	damaged.emit(actual_damage, source)
	
	# 受伤效果
	_on_hit_effects(actual_damage, source)
	
	# 检查死亡
	if stats.get("current_health", 100.0) <= 0:
		die()
	else:
		# 开始无敌时间
		_start_invincibility()


## 治疗
func heal(amount: float) -> void:
	"""治疗"""
	if stats == null:
		return
	
	if stats.has_method("heal"):
		stats.heal(amount)
	else:
		var current: float = stats.get("current_health", 100.0)
		var max_hp: float = stats.get("max_health", 100.0)
		stats.set("current_health", min(current + amount, max_hp))


## 死亡
func die() -> void:
	"""死亡"""
	died.emit()
	
	# 通知游戏管理器
	var game: Node = get_tree().current_scene
	if game and game.has_method("handle_player_death"):
		game.handle_player_death()
	
	print("[Player] 玩家死亡")


## 击退
func knockback(direction: Vector2, force: float) -> void:
	"""击退"""
	velocity = direction.normalized() * force

# =============================================================================
# 公共方法 - 属性系统
# =============================================================================

## 获得经验值
func gain_experience(amount: int) -> void:
	"""获得经验值"""
	if stats == null:
		return
	
	if stats.has_method("add_experience"):
		stats.add_experience(amount)
	else:
		var current: int = stats.get("current_experience", 0)
		stats.set("current_experience", current + amount)
		_check_level_up()


## 获取当前生命值百分比
func get_health_percent() -> float:
	"""获取当前生命值百分比"""
	if stats == null:
		return 1.0
	
	var current: float = stats.get("current_health", 100.0)
	var max_hp: float = stats.get("max_health", 100.0)
	
	if max_hp <= 0:
		return 0.0
	return current / max_hp

# =============================================================================
# 私有方法 - 初始化
# =============================================================================

func _initialize_player() -> void:
	"""初始化玩家内部状态"""
	# 加载子弹脚本
	_bullet_script = load(BULLET_SCRIPT_PATH)
	
	# 查找子弹容器
	_find_projectiles_container()
	
	# 初始化属性（如果没有）
	if stats == null:
		stats = PlayerStats.new()
		if stats.has_method("initialize"):
			stats.initialize()
	
	# 连接属性信号
	_connect_stats_signals()
	
	# 添加到玩家组
	add_to_group("players")
	
	# 确保有碰撞形状
	_ensure_collision_shape()
	
	# 确保有视觉表现
	_ensure_visual()
	
	# 确保有瞄准指示器
	_ensure_aim_indicator()
	
	print("[Player] 初始化完成")


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
		shape.radius = 12.0
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
		var image: Image = Image.create(24, 24, false, Image.FORMAT_RGBA8)
		image.fill(Color(0.2, 0.8, 0.3))  # 绿色玩家
		texture.set_image(image)
		sprite.texture = texture
		add_child(sprite)


func _ensure_aim_indicator() -> void:
	"""确保有瞄准指示器"""
	var indicator: Node2D = get_node_or_null("AimIndicator")
	if indicator == null:
		indicator = Node2D.new()
		indicator.name = "AimIndicator"
		add_child(indicator)


func _find_projectiles_container() -> void:
	"""查找子弹容器"""
	var main: Node = get_tree().current_scene
	if main:
		_projectiles_container = main.get_node_or_null("GameWorld/Projectiles")


func _connect_stats_signals() -> void:
	"""连接属性信号"""
	if stats == null:
		return
	
	if stats.has_signal("health_changed"):
		if not stats.health_changed.is_connected(_on_health_changed):
			stats.health_changed.connect(_on_health_changed)
	
	if stats.has_signal("mana_changed"):
		if not stats.mana_changed.is_connected(_on_mana_changed):
			stats.mana_changed.connect(_on_mana_changed)
	
	if stats.has_signal("stamina_changed"):
		if not stats.stamina_changed.is_connected(_on_stamina_changed):
			stats.stamina_changed.connect(_on_stamina_changed)
	
	if stats.has_signal("experience_changed"):
		if not stats.experience_changed.is_connected(_on_experience_changed):
			stats.experience_changed.connect(_on_experience_changed)
	
	if stats.has_signal("leveled_up"):
		if not stats.leveled_up.is_connected(_on_leveled_up):
			stats.leveled_up.connect(_on_leveled_up)


func _apply_stats() -> void:
	"""应用属性到玩家"""
	if stats == null:
		return
	
	# 应用速度加成
	if stats.has("move_speed_bonus"):
		var bonus: float = stats.get("move_speed_bonus", 0.0)
		move_speed = BASE_MOVE_SPEED * (1.0 + bonus)
	
	# 应用伤害加成
	if stats.has("damage_bonus"):
		var bonus: float = stats.get("damage_bonus", 0.0)
		bullet_damage = 10.0 * (1.0 + bonus)

# =============================================================================
# 私有方法 - 更新
# =============================================================================

func _update_timers(delta: float) -> void:
	"""更新计时器"""
	# 冲刺冷却
	if _dash_cooldown_timer > 0:
		_dash_cooldown_timer -= delta
	
	# 无敌时间
	if _is_invincible:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0:
			_is_invincible = false
	
	# 射击冷却
	if _shoot_timer > 0:
		_shoot_timer -= delta
		if _shoot_timer <= 0:
			_can_shoot = true


func _update_movement(_delta: float) -> void:
	"""更新移动"""
	# 获取输入方向
	var input_dir: Vector2 = Vector2.ZERO
	input_dir.x = Input.get_axis("move_left", "move_right")
	input_dir.y = Input.get_axis("move_up", "move_down")
	
	move_direction = input_dir.normalized()
	
	# 应用速度
	velocity = move_direction * move_speed
	
	# 消耗体力
	if move_direction != Vector2.ZERO and stats:
		var stamina_cost: float = 0.5
		if stats.has("current_stamina"):
			var current: float = stats.get("current_stamina", 100.0)
			# 恢复体力
			stats.set("current_stamina", min(current + 0.1, stats.get("max_stamina", 100.0)))


func _update_dash(delta: float) -> void:
	"""更新冲刺"""
	_dash_timer -= delta
	velocity = _dash_direction * move_speed * dash_speed_multiplier
	
	if _dash_timer <= 0:
		_end_dash()


func _update_shooting(_delta: float) -> void:
	"""更新射击"""
	# 检查射击输入
	if Input.is_action_pressed("shoot") and _can_shoot:
		_shoot()
		_can_shoot = false
		_shoot_timer = shoot_cooldown


func _update_aim_direction() -> void:
	"""更新瞄准方向"""
	# 使用鼠标位置
	var mouse_pos: Vector2 = get_global_mouse_position()
	aim_direction = (mouse_pos - global_position).normalized()
	
	# 更新瞄准指示器位置
	var indicator: Node2D = get_node_or_null("AimIndicator")
	if indicator:
		indicator.position = aim_direction * 20.0


func _update_visuals() -> void:
	"""更新视觉效果"""
	# 无敌闪烁
	if _is_invincible:
		modulate.a = 0.5 if fmod(Time.get_ticks_msec(), 100) < 50 else 1.0
	else:
		modulate.a = 1.0
	
	# 冲刺时拉伸
	if _is_dashing:
		scale = Vector2(1.2, 0.8)
	else:
		scale = Vector2.ONE

# =============================================================================
# 私有方法 - 冲刺
# =============================================================================

func _try_dash() -> void:
	"""尝试冲刺"""
	if _is_dashing or _dash_cooldown_timer > 0:
		return
	
	# 检查体力
	if stats:
		var stamina_cost: float = 20.0
		var current: float = stats.get("current_stamina", 100.0)
		if current < stamina_cost:
			return
		# 消耗体力
		stats.set("current_stamina", current - stamina_cost)
	
	_start_dash()


func _start_dash() -> void:
	"""开始冲刺"""
	_is_dashing = true
	_dash_timer = DASH_DURATION
	_dash_cooldown_timer = dash_cooldown
	
	# 使用移动方向或瞄准方向
	if move_direction != Vector2.ZERO:
		_dash_direction = move_direction
	else:
		_dash_direction = aim_direction
	
	# 冲刺时无敌
	_is_invincible = true
	
	dash_started.emit()
	print("[Player] 冲刺开始")


func _end_dash() -> void:
	"""结束冲刺"""
	_is_dashing = false
	_is_invincible = false
	dash_ended.emit()
	print("[Player] 冲刺结束")

# =============================================================================
# 私有方法 - 射击
# =============================================================================

func _shoot() -> void:
	"""射击"""
	# 创建子弹
	var bullet: Area2D = Area2D.new()
	bullet.set_script(_bullet_script)
	bullet.name = "PlayerBullet"
	
	# 设置子弹属性
	bullet.set("direction", aim_direction)
	bullet.set("speed", bullet_speed)
	bullet.set("damage", bullet_damage)
	bullet.set("is_player_bullet", true)
	bullet.global_position = global_position + aim_direction * 15.0
	
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
	image.fill(Color(0.2, 0.8, 0.9))  # 青色子弹
	texture.set_image(image)
	sprite.texture = texture
	bullet.add_child(sprite)
	
	# 添加到场景
	if _projectiles_container:
		_projectiles_container.add_child(bullet)
	else:
		get_tree().current_scene.add_child(bullet)
	
	shot_fired.emit(bullet)
	
	# 播放音效
	AudioManager.play_sfx("player_shoot", 0.5)

# =============================================================================
# 私有方法 - 无敌
# =============================================================================

func _start_invincibility() -> void:
	"""开始无敌时间"""
	_is_invincible = true
	_invincibility_timer = INVINCIBILITY_TIME


func _on_hit_effects(_amount: float, _source: Node) -> void:
	"""受伤效果"""
	# 屏幕震动效果
	# TODO: 实现屏幕震动
	
	# 播放受伤音效
	AudioManager.play_sfx("player_hurt", 0.6)

# =============================================================================
# 私有方法 - 升级
# =============================================================================

func _check_level_up() -> void:
	"""检查升级"""
	if stats == null:
		return
	
	var current: int = stats.get("current_experience", 0)
	var required: int = stats.get("experience_required", 100)
	
	if current >= required:
		_level_up()


func _level_up() -> void:
	"""升级"""
	if stats == null:
		return
	
	var current_level: int = stats.get("level", 1)
	var current_exp: int = stats.get("current_experience", 0)
	var required: int = stats.get("experience_required", 100)
	
	stats.set("level", current_level + 1)
	stats.set("current_experience", current_exp - required)
	stats.set("experience_required", int(required * 1.5))
	
	# 恢复生命值
	var max_hp: float = stats.get("max_health", 100.0)
	stats.set("current_health", max_hp)
	
	leveled_up.emit(current_level + 1)
	
	# 播放升级音效
	AudioManager.play_sfx("level_up", 0.8)
	
	print("[Player] 升级到 %d" % (current_level + 1))

# =============================================================================
# 信号回调
# =============================================================================

func _on_health_changed(current: float, maximum: float) -> void:
	"""生命值变化回调"""
	stats_changed.emit(stats)


func _on_mana_changed(current: float, maximum: float) -> void:
	"""法力值变化回调"""
	stats_changed.emit(stats)


func _on_stamina_changed(current: float, maximum: float) -> void:
	"""体力值变化回调"""
	stats_changed.emit(stats)


func _on_experience_changed(current: float, required: float) -> void:
	"""经验值变化回调"""
	stats_changed.emit(stats)


func _on_leveled_up(new_level: int) -> void:
	"""升级回调"""
	leveled_up.emit(new_level)
