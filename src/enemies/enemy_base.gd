## Void Hunter - 敌人基类
## @description: 所有敌人的基类，包含通用行为和属性
## @author: Void Hunter Team
## @version: 1.0.0

extends CharacterBody2D

# =============================================================================
# 信号定义
# =============================================================================

## 受伤时触发
signal damaged(amount: float, source: Node)

## 死亡时触发
signal died(killer: Node)

## 状态变化时触发
signal state_changed(old_state: int, new_state: int)

## 目标丢失时触发
signal target_lost()

## 进入攻击范围时触发
signal entered_attack_range(target: Node)

# =============================================================================
# 常量定义
# =============================================================================

## 默认移动速度
const DEFAULT_SPEED: float = 80.0

## 默认最大生命值
const DEFAULT_MAX_HEALTH: float = 30.0

## 默认攻击伤害
const DEFAULT_ATTACK_DAMAGE: float = 10.0

## 默认攻击范围
const DEFAULT_ATTACK_RANGE: float = 40.0

## 默认检测范围
const DEFAULT_DETECTION_RANGE: float = 400.0

## 默认追击范围
const DEFAULT_CHASE_RANGE: float = 500.0

## 受伤无敌时间
const HIT_INVINCIBILITY_TIME: float = 0.2

## 路径更新间隔
const PATH_UPDATE_INTERVAL: float = 0.5

## 漫游等待时间范围
const WANDER_WAIT_RANGE: Vector2 = Vector2(1.0, 3.0)

# =============================================================================
# 枚举定义
# =============================================================================

## 敌人状态
enum State {
	IDLE,		## 空闲
	WANDER,		## 漫游
	CHASE,		## 追击
	ATTACK,		## 攻击
	STUNNED,	## 眩晕
	DEAD		## 死亡
}

## 敌人类型
enum EnemyType {
	MELEE,		## 近战
	RANGED,		## 远程
	TANK,		## 坦克
	ELITE,		## 精英
	BOSS		## Boss
}

# =============================================================================
# 导出变量
# =============================================================================

## 敌人类型
@export var enemy_type: EnemyType = EnemyType.MELEE

## 移动速度
@export_range(10.0, 500.0) var move_speed: float = DEFAULT_SPEED

## 最大生命值
@export_range(1.0, 1000.0) var max_health: float = DEFAULT_MAX_HEALTH

## 攻击伤害
@export_range(1.0, 100.0) var attack_damage: float = DEFAULT_ATTACK_DAMAGE

## 攻击范围
@export_range(10.0, 200.0) var attack_range: float = DEFAULT_ATTACK_RANGE

## 检测范围
@export_range(50.0, 1000.0) var detection_range: float = DEFAULT_DETECTION_RANGE

## 追击范围（超出此范围停止追击）
@export_range(100.0, 1500.0) var chase_range: float = DEFAULT_CHASE_RANGE

## 攻击冷却时间
@export_range(0.1, 5.0) var attack_cooldown: float = 1.0

## 经验值奖励
@export var experience_reward: int = 10

## 金币奖励
@export var gold_reward: int = 5

## 是否启用漫游
@export var enable_wander: bool = true

## 漫游范围
@export var wander_range: float = 100.0

# =============================================================================
# 公共变量
# =============================================================================

## 当前生命值
var current_health: float = 0.0

## 当前状态
var current_state: State = State.IDLE

## 当前目标
var target: Node = null

## 难度系数
var difficulty_multiplier: float = 1.0

## 是否无敌
var is_invincible: bool = false

## 是否被击退
var is_knockback: bool = false

# =============================================================================
# 私有变量
# =============================================================================

var _attack_timer: float = 0.0
var _invincibility_timer: float = 0.0
var _path_update_timer: float = 0.0
var _wander_timer: float = 0.0
var _wander_target: Vector2 = Vector2.ZERO
var _knockback_velocity: Vector2 = Vector2.ZERO
var _stun_timer: float = 0.0
var _initial_position: Vector2 = Vector2.ZERO
var _difficulty_applied: bool = false

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""节点就绪时初始化"""
	_initialize_enemy()


func _physics_process(delta: float) -> void:
	"""物理帧更新"""
	if current_state == State.DEAD:
		return
	
	# 更新计时器
	_update_timers(delta)
	
	# 更新状态
	_update_state(delta)
	
	# 移动
	_apply_movement(delta)


func _process(_delta: float) -> void:
	"""每帧更新"""
	# 更新视觉效果
	_update_visuals()

# =============================================================================
# 公共方法 - 初始化
# =============================================================================

## 初始化敌人
func initialize_enemy() -> void:
	"""手动初始化敌人"""
	_initialize_enemy()


## 应用难度系数
func apply_difficulty(multiplier: float) -> void:
	"""应用难度系数"""
	if _difficulty_applied:
		return
	
	difficulty_multiplier = multiplier
	max_health *= multiplier
	current_health = max_health
	attack_damage *= multiplier
	# 速度稍微增加
	move_speed *= (1.0 + (multiplier - 1.0) * 0.3)
	
	# 奖励也增加
	experience_reward = int(float(experience_reward) * multiplier)
	gold_reward = int(float(gold_reward) * multiplier)
	
	_difficulty_applied = true

# =============================================================================
# 公共方法 - 伤害系统
# =============================================================================

## 受到伤害
func take_damage(amount: float, source: Node = null) -> void:
	"""受到伤害"""
	if current_state == State.DEAD or is_invincible:
		return
	
	var actual_damage: float = amount
	current_health -= actual_damage
	
	# 触发受伤信号
	damaged.emit(actual_damage, source)
	
	# 受伤效果
	_on_hit_effects(actual_damage, source)
	
	# 检查死亡
	if current_health <= 0:
		die(source)
	else:
		# 无敌帧
		is_invincible = true
		_invincibility_timer = HIT_INVINCIBILITY_TIME
		
		# 击退
		_apply_knockback(source)


## 治疗
func heal(amount: float) -> void:
	"""治疗"""
	current_health = minf(current_health + amount, max_health)


## 死亡
func die(killer: Node = null) -> void:
	"""死亡"""
	if current_state == State.DEAD:
		return
	
	current_state = State.DEAD
	
	# 死亡效果
	_on_death_effects(killer)
	
	# 触发死亡信号
	died.emit(killer)
	
	# 给予奖励
	_grant_rewards(killer)
	
	# 延迟删除
	await get_tree().create_timer(0.5).timeout
	queue_free()


## 眩晕
func stun(duration: float) -> void:
	"""眩晕敌人"""
	_stun_timer = duration
	_change_state(State.STUNNED)

# =============================================================================
# 公共方法 - 状态
# =============================================================================

## 获取生命值百分比
func get_health_percent() -> float:
	"""获取生命值百分比"""
	if max_health <= 0:
		return 0.0
	return current_health / max_health


## 检查是否死亡
func is_dead() -> bool:
	"""检查是否死亡"""
	return current_state == State.DEAD


## 设置目标
func set_target(new_target: Node) -> void:
	"""设置目标"""
	target = new_target


## 清除目标
func clear_target() -> void:
	"""清除目标"""
	target = null
	target_lost.emit()

# =============================================================================
# 公共方法 - 移动
# =============================================================================

## 击退
func knockback(direction: Vector2, force: float) -> void:
	"""击退"""
	_knockback_velocity = direction.normalized() * force
	is_knockback = true


## 停止移动
func stop_movement() -> void:
	"""停止移动"""
	velocity = Vector2.ZERO

# =============================================================================
# 私有方法 - 初始化
# =============================================================================

func _initialize_enemy() -> void:
	"""初始化敌人内部状态"""
	current_health = max_health
	current_state = State.IDLE
	_initial_position = global_position
	
	# 添加到敌人组
	add_to_group("enemies")
	
	# 初始化计时器
	_attack_timer = 0.0
	_invincibility_timer = 0.0
	_path_update_timer = 0.0
	_wander_timer = randf_range(WANDER_WAIT_RANGE.x, WANDER_WAIT_RANGE.y)
	
	# 确保有碰撞形状
	_ensure_collision_shape()
	
	# 查找玩家
	_find_target()
	
	print("[EnemyBase] 初始化完成: %s" % name)


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

# =============================================================================
# 私有方法 - 更新
# =============================================================================

func _update_timers(delta: float) -> void:
	"""更新计时器"""
	# 攻击冷却
	if _attack_timer > 0:
		_attack_timer -= delta
	
	# 无敌时间
	if _invincibility_timer > 0:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0:
			is_invincible = false
	
	# 眩晕时间
	if _stun_timer > 0:
		_stun_timer -= delta
		if _stun_timer <= 0 and current_state == State.STUNNED:
			_change_state(State.IDLE)


func _update_state(delta: float) -> void:
	"""更新状态机"""
	# 如果被击退，优先处理
	if is_knockback:
		return
	
	# 如果眩晕，不处理
	if current_state == State.STUNNED:
		return
	
	# 根据当前状态更新
	match current_state:
		State.IDLE:
			_update_idle(delta)
		State.WANDER:
			_update_wander(delta)
		State.CHASE:
			_update_chase(delta)
		State.ATTACK:
			_update_attack(delta)
	
	# 检查目标
	_check_target()


func _update_idle(_delta: float) -> void:
	"""更新空闲状态"""
	# 检查是否有目标
	if target and is_instance_valid(target):
		var dist: float = global_position.distance_to(target.global_position)
		if dist <= detection_range:
			_change_state(State.CHASE)
	elif enable_wander:
		_wander_timer -= _delta
		if _wander_timer <= 0:
			_start_wander()


func _update_wander(delta: float) -> void:
	"""更新漫游状态"""
	if target and is_instance_valid(target):
		var dist: float = global_position.distance_to(target.global_position)
		if dist <= detection_range:
			_change_state(State.CHASE)
			return
	
	# 移动到漫游目标
	var dir: Vector2 = (_wander_target - global_position).normalized()
	velocity = dir * move_speed * 0.5
	
	# 检查是否到达
	if global_position.distance_to(_wander_target) < 10:
		_change_state(State.IDLE)
		_wander_timer = randf_range(WANDER_WAIT_RANGE.x, WANDER_WAIT_RANGE.y)


func _update_chase(_delta: float) -> void:
	"""更新追击状态"""
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
	
	# 检查是否进入攻击范围
	if dist <= attack_range:
		_change_state(State.ATTACK)
		entered_attack_range.emit(target)
		return
	
	# 追击目标
	var dir: Vector2 = (target.global_position - global_position).normalized()
	velocity = dir * move_speed


func _update_attack(_delta: float) -> void:
	"""更新攻击状态"""
	# 停止移动
	velocity = Vector2.ZERO
	
	if target == null or not is_instance_valid(target):
		clear_target()
		_change_state(State.IDLE)
		return
	
	var dist: float = global_position.distance_to(target.global_position)
	
	# 检查目标是否离开攻击范围
	if dist > attack_range * 1.2:
		_change_state(State.CHASE)
		return
	
	# 攻击
	if _attack_timer <= 0:
		_perform_attack()
		_attack_timer = attack_cooldown


func _apply_movement(delta: float) -> void:
	"""应用移动"""
	# 击退效果
	if is_knockback:
		velocity = _knockback_velocity
		_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, 500 * delta)
		if _knockback_velocity.length() < 10:
			is_knockback = false
	
	# 应用移动
	move_and_slide()


func _update_visuals() -> void:
	"""更新视觉效果"""
	# 受伤闪烁
	if is_invincible:
		modulate.a = 0.5 if fmod(Time.get_ticks_msec(), 100) < 50 else 1.0
	else:
		modulate.a = 1.0


func _check_target() -> void:
	"""检查目标"""
	if target == null or not is_instance_valid(target):
		_find_target()


func _find_target() -> void:
	"""查找目标（玩家）"""
	var players: Array[Node] = get_tree().get_nodes_in_group("players")
	if not players.is_empty():
		target = players[0]

# =============================================================================
# 私有方法 - 状态切换
# =============================================================================

func _change_state(new_state: State) -> void:
	"""切换状态"""
	if current_state == new_state:
		return
	
	var old_state: State = current_state
	current_state = new_state
	state_changed.emit(old_state, new_state)


func _start_wander() -> void:
	"""开始漫游"""
	_change_state(State.WANDER)
	
	# 随机漫游目标
	var angle: float = randf() * TAU
	var dist: float = randf() * wander_range
	_wander_target = _initial_position + Vector2(cos(angle), sin(angle)) * dist

# =============================================================================
# 私有方法 - 战斗
# =============================================================================

func _perform_attack() -> void:
	"""执行攻击（子类重写）"""
	# 基础近战攻击
	if target and is_instance_valid(target):
		if target.has_method("take_damage"):
			target.take_damage(attack_damage, self)


func _apply_knockback(source: Node) -> void:
	"""应用击退"""
	if source == null:
		return
	
	var direction: Vector2 = global_position - source.global_position
	knockback(direction, 100.0)


func _on_hit_effects(_amount: float, _source: Node) -> void:
	"""受伤效果"""
	# 闪烁效果通过 _update_visuals 处理


func _on_death_effects(_killer: Node) -> void:
	"""死亡效果"""
	# 变成灰色并缩小
	modulate = Color(0.5, 0.5, 0.5, 0.5)
	
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.3)


func _grant_rewards(killer: Node) -> void:
	"""给予奖励"""
	if killer == null:
		return
	
	# 经验值
	if killer.has_method("gain_experience"):
		killer.gain_experience(experience_reward)
	
	# 金币
	GameManager.add_gold(gold_reward)

# =============================================================================
# 碰撞检测
# =============================================================================

func _on_body_entered(body: Node) -> void:
	"""身体进入检测"""
	if body.is_in_group("players") and target == null:
		target = body
		if current_state == State.IDLE or current_state == State.WANDER:
			_change_state(State.CHASE)
