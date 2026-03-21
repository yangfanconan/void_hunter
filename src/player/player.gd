## Void Hunter - 玩家控制器
## @description: 处理玩家输入、移动、战斗和基本交互逻辑
## @author: Void Hunter Team
## @version: 1.0.0

extends CharacterBody2D
class_name Player

# =============================================================================
# 信号定义
# =============================================================================

## 玩家受到伤害时触发
signal damaged(amount: float, source: Node)

## 玩家死亡时触发
signal died()

## 玩家升级时触发
signal leveled_up(new_level: int)

## 玩家拾取物品时触发
signal item_picked_up(item: Node)

## 玩家使用技能时触发
signal skill_used(skill_id: String)

## 玩家属性改变时触发
signal stats_changed(stats: PlayerStats)

## 玩家射击时触发
signal fired_bullet(bullet: Node)

## 冲刺开始时触发
signal dash_started()

## 冲刺结束时触发
signal dash_ended()

## 玩家重生时触发
signal respawned()

# =============================================================================
# 常量定义
# =============================================================================

## 基础移动速度
const BASE_MOVE_SPEED: float = 150.0

## 受伤无敌帧持续时间
const HURT_INVINCIBILITY_DURATION: float = 1.0

## 冲刺冷却时间
const DASH_COOLDOWN: float = 3.0

## 冲刺速度倍率
const DASH_SPEED_MULTIPLIER: float = 3.0

## 冲刺持续时间
const DASH_DURATION: float = 0.2

## 冲刺无敌帧
const DASH_INVINCIBILITY_DURATION: float = 0.3

## 击退力度
const KNOCKBACK_FORCE: float = 200.0

## 击退持续时间
const KNOCKBACK_DURATION: float = 0.15

## 基础射击间隔（秒）
const BASE_FIRE_RATE: float = 0.5

## 重生延迟（秒）
const RESPAWN_DELAY: float = 3.0

# =============================================================================
# 枚举定义
# =============================================================================

## 玩家状态
enum PlayerState {
	NORMAL,		## 正常状态
	DASHING,	## 冲刺中
	KNOCKBACK,	## 击退中
	HURT,		## 受伤中
	DEAD,		## 死亡
	RESPAWNING	## 重生中
}

## 输入模式
enum InputMode {
	KEYBOARD_MOUSE,	## 键盘+鼠标
	TOUCH			## 触屏
}

# =============================================================================
# 导出变量
# =============================================================================

## 玩家属性引用
@export var stats: PlayerStats

## 移动速度（受道具加成影响）
@export var move_speed: float = BASE_MOVE_SPEED

## 是否启用无敌帧
@export var invincibility_enabled: bool = true

## 是否启用调试模式
@export var debug_mode: bool = false

## 调试无敌模式
@export var debug_god_mode: bool = false

## 自动射击开关
@export var auto_fire_enabled: bool = false

## 输入模式
@export var input_mode: InputMode = InputMode.KEYBOARD_MOUSE

# =============================================================================
# 公共变量
# =============================================================================

## 是否可以移动
var can_move: bool = true

## 是否可以攻击
var can_attack: bool = true

## 是否可以使用技能
var can_use_skill: bool = true

## 是否正在冲刺
var is_dashing: bool = false

## 是否处于无敌状态
var is_invincible: bool = false

## 当前朝向
var facing_direction: Vector2 = Vector2.RIGHT

## 瞄准方向（鼠标/触摸位置）
var aim_direction: Vector2 = Vector2.RIGHT

## 当前玩家状态
var current_state: PlayerState = PlayerState.NORMAL

## 是否触屏控制中
var is_touch_controlling: bool = false

## 触屏移动方向
var touch_move_direction: Vector2 = Vector2.ZERO

## 触屏瞄准位置（全局坐标）
var touch_aim_position: Vector2 = Vector2.ZERO

## 是否触屏射击中
var is_touch_firing: bool = false

# =============================================================================
# 私有变量
# =============================================================================

var _velocity: Vector2 = Vector2.ZERO
var _invincibility_timer: float = 0.0
var _dash_timer: float = 0.0
var _dash_cooldown_timer: float = 0.0
var _dash_direction: Vector2 = Vector2.ZERO
var _input_direction: Vector2 = Vector2.ZERO
var _knockback_timer: float = 0.0
var _knockback_direction: Vector2 = Vector2.ZERO
var _fire_timer: float = 0.0
var _respawn_timer: float = 0.0
var _health_regen_timer: float = 0.0
var _stamina_regen_timer: float = 0.0
var _invincibility_tween: Tween = null

# 子弹场景引用
var _bullet_scene: PackedScene = null

# 武器组件引用
var _weapon: Node = null

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""
	节点就绪时初始化玩家
	"""
	_initialize_player()
	_load_bullet_scene()
	_setup_weapon()


func _physics_process(delta: float) -> void:
	"""
	物理帧更新
	@param delta: 帧间隔时间
	"""
	# 更新计时器
	_update_timers(delta)
	
	# 根据状态处理
	match current_state:
		PlayerState.DASHING:
			_handle_dash(delta)
		PlayerState.KNOCKBACK:
			_handle_knockback(delta)
		PlayerState.DEAD:
			_handle_dead(delta)
		PlayerState.RESPAWNING:
			_handle_respawn(delta)
		_:
			if can_move:
				_handle_movement(delta)
				_handle_shooting(delta)
	
	# 应用移动
	move_and_slide()
	
	# 更新动画
	_update_animation()


func _process(delta: float) -> void:
	"""
	每帧更新
	@param delta: 帧间隔时间
	"""
	# 更新瞄准方向
	_update_aim_direction()
	
	# 自动恢复
	_handle_regeneration(delta)


func _input(event: InputEvent) -> void:
	"""
	处理输入事件
	@param event: 输入事件
	"""
	# 处理冲刺
	if event.is_action_pressed("dash"):
		_try_dash()
	
	# 处理技能输入
	if event.is_action_pressed("skill_1"):
		use_skill(0)
	elif event.is_action_pressed("skill_2"):
		use_skill(1)
	elif event.is_action_pressed("skill_3"):
		use_skill(2)
	
	# 处理物品栏输入
	if event.is_action_pressed("inventory"):
		toggle_inventory()
	
	# 处理暂停输入
	if event.is_action_pressed("pause"):
		GameManager.toggle_pause()
	
	# 处理自动射击切换
	if event.is_action_pressed("toggle_auto_fire"):
		auto_fire_enabled = not auto_fire_enabled
		if debug_mode:
			print("[Player] 自动射击: ", "开启" if auto_fire_enabled else "关闭")
	
	# 调试功能
	if debug_mode:
		_handle_debug_input(event)

# =============================================================================
# 公共方法 - 初始化
# =============================================================================

## 初始化玩家
func initialize() -> void:
	"""
	手动初始化玩家
	"""
	_initialize_player()


## 重置玩家状态
func reset() -> void:
	"""
	重置玩家到初始状态
	"""
	current_state = PlayerState.NORMAL
	is_dashing = false
	is_invincible = false
	can_move = true
	can_attack = true
	can_use_skill = true
	
	_dash_cooldown_timer = 0.0
	_fire_timer = 0.0
	_invincibility_timer = 0.0
	_knockback_timer = 0.0
	
	if stats:
		stats.initialize()
	
	modulate = Color.WHITE
	_stop_invincibility_flash()

# =============================================================================
# 公共方法 - 战斗
# =============================================================================

## 受到伤害
func take_damage(amount: float, source: Node = null) -> void:
	"""
	玩家受到伤害
	@param amount: 伤害值
	@param source: 伤害来源
	"""
	# 调试无敌模式
	if debug_god_mode:
		if debug_mode:
			print("[Player] 调试无敌模式 - 忽略伤害")
		return
	
	if is_invincible or current_state == PlayerState.DEAD:
		return
	
	if stats.is_dead:
		return
	
	# 应用伤害
	var actual_damage: float = stats.apply_damage(amount)
	damaged.emit(actual_damage, source)
	
	# 播放受伤效果
	_play_hurt_effect()
	
	# 启动受伤无敌帧
	if invincibility_enabled:
		start_invincibility(HURT_INVINCIBILITY_DURATION)
	
	# 应用击退
	if source != null and is_instance_valid(source):
		_apply_knockback(source.global_position)
	
	# 检查死亡
	if stats.current_health <= 0:
		die()
	else:
		current_state = PlayerState.HURT
		await get_tree().create_timer(0.1).timeout
		if current_state == PlayerState.HURT:
			current_state = PlayerState.NORMAL


## 治疗
func heal(amount: float) -> void:
	"""
	治疗玩家
	@param amount: 治疗量
	"""
	if stats.current_health >= stats.max_health:
		return
	
	stats.heal(amount)
	stats_changed.emit(stats)
	
	# 播放治疗效果
	_play_heal_effect()


## 冲刺
func dash(direction: Vector2 = Vector2.ZERO) -> bool:
	"""
	执行冲刺
	@param direction: 冲刺方向（默认为当前移动方向）
	@return: 是否成功冲刺
	"""
	return _try_dash(direction)


## 开始无敌状态
func start_invincibility(duration: float = HURT_INVINCIBILITY_DURATION) -> void:
	"""
	启动无敌状态
	@param duration: 无敌持续时间
	"""
	is_invincible = true
	_invincibility_timer = duration
	
	# 闪烁效果
	_start_invincibility_flash()


## 使用技能
func use_skill(skill_index: int) -> bool:
	"""
	使用指定索引的技能
	@param skill_index: 技能索引（0-2）
	@return: 是否成功使用
	"""
	if not can_use_skill:
		return false
	
	if current_state == PlayerState.DEAD:
		return false
	
	var skill_id: String = str(skill_index)
	skill_used.emit(skill_id)
	
	return true


## 拾取物品
func pickup_item(item: Node) -> void:
	"""
	拾取物品
	@param item: 物品节点
	"""
	item_picked_up.emit(item)
	
	# 播放拾取音效
	AudioManager.play_sfx("pickup", 0.8)


## 切换物品栏
func toggle_inventory() -> void:
	"""
	切换物品栏显示
	"""
	if GameManager.current_state == GameManager.GameState.INVENTORY:
		GameManager.set_game_state(GameManager.GameState.PLAYING)
	elif GameManager.current_state == GameManager.GameState.PLAYING:
		GameManager.set_game_state(GameManager.GameState.INVENTORY)


## 死亡
func die() -> void:
	"""
	玩家死亡
	"""
	if stats.is_dead:
		return
	
	stats.is_dead = true
	current_state = PlayerState.DEAD
	can_move = false
	can_attack = false
	can_use_skill = false
	
	# 停止无敌闪烁
	_stop_invincibility_flash()
	
	# 播放死亡动画
	_play_death_animation()
	
	# 通知游戏管理器
	died.emit()
	GameManager.handle_player_death(stats.to_dictionary())


## 重生
func respawn() -> void:
	"""
	玩家重生
	"""
	if current_state != PlayerState.DEAD:
		return
	
	current_state = PlayerState.RESPAWNING
	_respawn_timer = RESPAWN_DELAY
	
	# 重置属性
	stats.is_dead = false
	stats.current_health = stats.max_health
	stats.current_mana = stats.max_mana
	stats.current_stamina = stats.max_stamina
	
	can_move = true
	can_attack = true
	can_use_skill = true
	
	# 重置状态
	is_dashing = false
	is_invincible = false
	_dash_cooldown_timer = 0.0
	
	# 播放重生动画
	_play_respawn_animation()
	
	# 启动重生无敌
	start_invincibility(HURT_INVINCIBILITY_DURATION * 2)
	
	current_state = PlayerState.NORMAL
	respawned.emit()
	
	if debug_mode:
		print("[Player] 玩家已重生")


## 强制设置位置
func set_position_warp(position: Vector2) -> void:
	"""
	传送玩家到指定位置
	@param position: 目标位置
	"""
	global_position = position
	velocity = Vector2.ZERO

# =============================================================================
# 公共方法 - 触屏控制
# =============================================================================

## 设置触屏移动方向
func set_touch_move_direction(direction: Vector2) -> void:
	"""
	设置触屏移动方向
	@param direction: 移动方向（归一化向量）
	"""
	touch_move_direction = direction
	is_touch_controlling = direction != Vector2.ZERO


## 设置触屏瞄准位置
func set_touch_aim_position(global_pos: Vector2) -> void:
	"""
	设置触屏瞄准位置
	@param global_pos: 全局坐标位置
	"""
	touch_aim_position = global_pos


## 设置触屏射击状态
func set_touch_firing(firing: bool) -> void:
	"""
	设置触屏射击状态
	@param firing: 是否射击中
	"""
	is_touch_firing = firing


## 获取世界坐标瞄准位置
func get_aim_global_position() -> Vector2:
	"""
	获取当前瞄准的世界坐标位置
	@return: 瞄准位置
	"""
	return global_position + aim_direction * 100.0

# =============================================================================
# 私有方法 - 初始化
# =============================================================================

func _initialize_player() -> void:
	"""
	初始化玩家内部状态
	"""
	# 如果没有设置属性，创建默认属性
	if stats == null:
		stats = PlayerStats.new()
		stats.initialize()
	
	# 连接属性变化信号
	if not stats.health_changed.is_connected(_on_health_changed):
		stats.health_changed.connect(_on_health_changed)
	if not stats.leveled_up.is_connected(_on_leveled_up):
		stats.leveled_up.connect(_on_leveled_up)
	
	# 设置碰撞层
	collision_layer = 1  # Player layer
	collision_mask = 2 | 8 | 32  # Enemies, Items, Triggers
	
	# 添加到玩家组
	add_to_group("players")
	
	current_state = PlayerState.NORMAL
	
	if debug_mode:
		print("[Player] 初始化完成")


func _load_bullet_scene() -> void:
	"""
	加载子弹场景
	"""
	var bullet_path: String = "res://scenes/bullet.tscn"
	if ResourceLoader.exists(bullet_path):
		_bullet_scene = load(bullet_path)
	elif debug_mode:
		print("[Player] 警告: 子弹场景不存在: ", bullet_path)


func _setup_weapon() -> void:
	"""
	设置武器组件
	"""
	_weapon = get_node_or_null("WeaponComponent")
	if _weapon == null:
		if debug_mode:
			print("[Player] 未找到武器组件，使用默认射击")

# =============================================================================
# 私有方法 - 更新
# =============================================================================

func _update_timers(delta: float) -> void:
	"""
	更新各种计时器
	@param delta: 帧间隔时间
	"""
	# 无敌帧计时
	if is_invincible and _invincibility_timer > 0:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0:
			is_invincible = false
			_stop_invincibility_flash()
	
	# 冲刺计时
	if is_dashing:
		_dash_timer -= delta
		if _dash_timer <= 0:
			_end_dash()
	
	# 冲刺冷却计时
	if _dash_cooldown_timer > 0:
		_dash_cooldown_timer -= delta
	
	# 击退计时
	if _knockback_timer > 0:
		_knockback_timer -= delta
		if _knockback_timer <= 0:
			if current_state == PlayerState.KNOCKBACK:
				current_state = PlayerState.NORMAL
	
	# 射击计时
	if _fire_timer > 0:
		_fire_timer -= delta


func _handle_movement(delta: float) -> void:
	"""
	处理玩家移动
	@param delta: 帧间隔时间
	"""
	# 获取输入方向（支持键盘和触屏）
	if input_mode == InputMode.TOUCH and is_touch_controlling:
		_input_direction = touch_move_direction
	else:
		_input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# 计算速度
	var target_speed: float = move_speed * stats.speed_multiplier
	velocity = _input_direction * target_speed
	
	# 更新朝向
	if _input_direction != Vector2.ZERO:
		facing_direction = _input_direction.normalized()


func _handle_dash(delta: float) -> void:
	"""
	处理冲刺移动
	@param delta: 帧间隔时间
	"""
	velocity = _dash_direction * move_speed * DASH_SPEED_MULTIPLIER


func _handle_knockback(delta: float) -> void:
	"""
	处理击退
	@param delta: 帧间隔时间
	"""
	velocity = _knockback_direction * KNOCKBACK_FORCE


func _handle_dead(delta: float) -> void:
	"""
	处理死亡状态
	@param delta: 帧间隔时间
	"""
	velocity = Vector2.ZERO


func _handle_respawn(delta: float) -> void:
	"""
	处理重生状态
	@param delta: 帧间隔时间
	"""
	velocity = Vector2.ZERO
	
	_respawn_timer -= delta
	if _respawn_timer <= 0:
		respawn()


func _update_aim_direction() -> void:
	"""
	更新瞄准方向
	"""
	if input_mode == InputMode.TOUCH:
		# 触屏模式：使用触屏瞄准位置
		if touch_aim_position != Vector2.ZERO:
			aim_direction = (touch_aim_position - global_position).normalized()
	else:
		# 键盘+鼠标模式：使用鼠标位置
		var mouse_pos: Vector2 = get_global_mouse_position()
		aim_direction = (mouse_pos - global_position).normalized()


func _handle_shooting(delta: float) -> void:
	"""
	处理射击
	@param delta: 帧间隔时间
	"""
	if not can_attack:
		return
	
	var is_firing: bool = false
	
	# 检测射击输入
	if input_mode == InputMode.TOUCH:
		is_firing = is_touch_firing or auto_fire_enabled
	else:
		is_firing = Input.is_action_pressed("attack") or auto_fire_enabled
	
	if is_firing and _fire_timer <= 0:
		_fire_bullet()
		_fire_timer = BASE_FIRE_RATE / stats.fire_rate_multiplier


func _handle_regeneration(delta: float) -> void:
	"""
	处理自动恢复
	@param delta: 帧间隔时间
	"""
	if current_state == PlayerState.DEAD:
		return
	
	# 生命恢复
	if stats.health_regen > 0 and stats.current_health < stats.max_health:
		_health_regen_timer += delta
		if _health_regen_timer >= 1.0:
			_health_regen_timer = 0.0
			var regen_amount: float = stats.max_health * (stats.health_regen / 100.0)
			heal(regen_amount)
	
	# 体力恢复
	if stats.stamina_regen > 0 and stats.current_stamina < stats.max_stamina:
		_stamina_regen_timer += delta
		if _stamina_regen_timer >= 0.1:
			_stamina_regen_timer = 0.0
			stats.restore_stamina(stats.stamina_regen)


# =============================================================================
# 私有方法 - 冲刺
# =============================================================================

func _try_dash(direction: Vector2 = Vector2.ZERO) -> bool:
	"""
	尝试执行冲刺
	@param direction: 冲刺方向
	@return: 是否成功
	"""
	if is_dashing or _dash_cooldown_timer > 0:
		return false
	
	if current_state == PlayerState.DEAD:
		return false
	
	if not can_move:
		return false
	
	# 检查体力
	var stamina_cost: float = 20.0
	if stats.current_stamina < stamina_cost:
		if debug_mode:
			print("[Player] 体力不足，无法冲刺")
		return false
	
	# 消耗体力
	stats.consume_stamina(stamina_cost)
	
	# 设置冲刺方向
	if direction == Vector2.ZERO:
		if _input_direction != Vector2.ZERO:
			direction = _input_direction
		else:
			direction = facing_direction
	
	_dash_direction = direction.normalized()
	is_dashing = true
	current_state = PlayerState.DASHING
	_dash_timer = DASH_DURATION
	_dash_cooldown_timer = DASH_COOLDOWN
	
	# 启动冲刺时的无敌
	if invincibility_enabled:
		start_invincibility(DASH_INVINCIBILITY_DURATION)
	
	dash_started.emit()
	
	if debug_mode:
		print("[Player] 冲刺! 方向: ", _dash_direction)
	
	return true


func _end_dash() -> void:
	"""
	结束冲刺
	"""
	is_dashing = false
	if current_state == PlayerState.DASHING:
		current_state = PlayerState.NORMAL
	dash_ended.emit()

# =============================================================================
# 私有方法 - 射击
# =============================================================================

func _fire_bullet() -> void:
	"""
	发射子弹
	"""
	if _bullet_scene == null:
		# 如果没有子弹场景，创建基础子弹
		_create_and_fire_basic_bullet()
		return
	
	var bullet: Node = _bullet_scene.instantiate()
	bullet.global_position = global_position
	bullet.direction = aim_direction
	bullet.damage = stats.attack
	bullet.is_player_bullet = true
	
	get_tree().current_scene.add_child(bullet)
	fired_bullet.emit(bullet)
	
	# 播放射击音效
	AudioManager.play_sfx_variant("shoot", 3, 0.6)


func _create_and_fire_basic_bullet() -> void:
	"""
	创建并发射基础子弹
	"""
	var bullet: Node2D = Node2D.new()
	bullet.set_script(preload("res://src/projectiles/bullet_base.gd"))
	bullet.global_position = global_position
	bullet.set("direction", aim_direction)
	bullet.set("damage", stats.attack)
	bullet.set("is_player_bullet", true)
	bullet.set("speed", 400.0)
	
	# 添加碰撞形状
	var area: Area2D = Area2D.new()
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 5.0
	collision.shape = shape
	area.add_child(collision)
	bullet.add_child(area)
	
	# 添加可视表示
	var sprite: Sprite2D = Sprite2D.new()
	var texture: ImageTexture = ImageTexture.new()
	var image: Image = Image.create(10, 10, false, Image.FORMAT_RGBA8)
	image.fill(Color.YELLOW)
	texture.set_image(image)
	sprite.texture = texture
	bullet.add_child(sprite)
	
	get_tree().current_scene.add_child(bullet)
	fired_bullet.emit(bullet)

# =============================================================================
# 私有方法 - 击退
# =============================================================================

func _apply_knockback(source_position: Vector2) -> void:
	"""
	应用击退效果
	@param source_position: 伤害来源位置
	"""
	_knockback_direction = (global_position - source_position).normalized()
	_knockback_timer = KNOCKBACK_DURATION
	current_state = PlayerState.KNOCKBACK

# =============================================================================
# 私有方法 - 视觉效果
# =============================================================================

func _update_animation() -> void:
	"""
	更新玩家动画状态
	"""
	# 这里应该与动画系统集成
	# 根据移动方向更新动画
	pass


func _play_hurt_effect() -> void:
	"""
	播放受伤效果
	"""
	# 闪烁效果
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate", Color.RED, 0.05)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
	
	# 播放受伤音效
	AudioManager.play_sfx("player_hurt", 0.9)


func _play_heal_effect() -> void:
	"""
	播放治疗效果
	"""
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate", Color.GREEN, 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)


func _play_death_animation() -> void:
	"""
	播放死亡动画
	"""
	# 淡出效果
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.3, 0.5)
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	
	# 播放死亡音效
	AudioManager.play_sfx("player_death")


func _play_respawn_animation() -> void:
	"""
	播放重生动画
	"""
	modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	
	# 播放重生音效
	AudioManager.play_sfx("respawn")


func _start_invincibility_flash() -> void:
	"""
	启动无敌闪烁效果
	"""
	# 先停止之前的闪烁
	_stop_invincibility_flash()
	
	# 创建新的闪烁效果
	_invincibility_tween = create_tween()
	_invincibility_tween.set_loops()
	_invincibility_tween.tween_property(self, "modulate:a", 0.3, 0.1)
	_invincibility_tween.tween_property(self, "modulate:a", 1.0, 0.1)


func _stop_invincibility_flash() -> void:
	"""
	停止无敌闪烁效果
	"""
	if _invincibility_tween and _invincibility_tween.is_valid():
		_invincibility_tween.kill()
		_invincibility_tween = null
	modulate.a = 1.0

# =============================================================================
# 私有方法 - 调试
# =============================================================================

func _handle_debug_input(event: InputEvent) -> void:
	"""
	处理调试输入
	@param event: 输入事件
	"""
	# F1 - 切换无敌模式
	if event.is_action_pressed("debug_god_mode"):
		debug_god_mode = not debug_god_mode
		print("[Player] 调试无敌模式: ", "开启" if debug_god_mode else "关闭")
	
	# F2 - 恢复满血
	if event.is_action_pressed("debug_heal"):
		heal(stats.max_health)
		print("[Player] 已恢复满血")
	
	# F3 - 增加经验
	if event.is_action_pressed("debug_add_exp"):
		stats.add_experience(100)
		print("[Player] 增加100经验")
	
	# F4 - 升级
	if event.is_action_pressed("debug_level_up"):
		stats.add_experience(stats.experience_required - stats.current_experience + 1)
		print("[Player] 强制升级")


func _add_debug_actions_to_input_map() -> void:
	"""
	添加调试动作到输入映射（仅调试模式）
	"""
	if not debug_mode:
		return
	
	# 这里可以动态添加输入映射
	# 实际应该在项目设置中配置

# =============================================================================
# 信号回调
# =============================================================================

func _on_health_changed(current: float, maximum: float) -> void:
	"""
	生命值变化回调
	@param current: 当前生命值
	@param maximum: 最大生命值
	"""
	stats_changed.emit(stats)


func _on_leveled_up(new_level: int) -> void:
	"""
	升级回调
	@param new_level: 新等级
	"""
	leveled_up.emit(new_level)
	
	# 播放升级效果
	_play_level_up_effect()
	AudioManager.play_sfx("level_up")
	
	# 恢复满生命和法力
	stats.current_health = stats.max_health
	stats.current_mana = stats.max_mana
	
	# 通知游戏管理器
	GameManager.set_game_state(GameManager.GameState.SKILL_SELECTION)


func _play_level_up_effect() -> void:
	"""
	播放升级效果
	"""
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.2)
	tween.tween_property(self, "scale", Vector2.ONE, 0.2)
	tween.tween_property(self, "modulate", Color.YELLOW, 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
