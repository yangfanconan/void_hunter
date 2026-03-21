## Void Hunter - 坦克敌人
## @description: 高生命值、高防御的坦克敌人
## @author: Void Hunter Team
## @version: 1.0.0

extends "res://src/enemies/enemy_base.gd"

# =============================================================================
# 信号定义
# =============================================================================

## 冲锋开始时触发
signal charge_started()

## 冲锋结束时触发
signal charge_ended()

# =============================================================================
# 常量定义
# =============================================================================

## 默认坦克速度
const TANK_SPEED: float = 50.0

## 默认坦克生命值
const TANK_HEALTH: float = 80.0

## 默认坦克伤害
const TANK_DAMAGE: float = 15.0

## 默认坦克攻击范围
const TANK_ATTACK_RANGE: float = 45.0

## 默认坦克攻击冷却
const TANK_ATTACK_COOLDOWN: float = 2.0

## 冲锋速度倍率
const CHARGE_SPEED_MULTIPLIER: float = 3.0

## 冲锋距离
const CHARGE_DISTANCE: float = 200.0

## 冲锋冷却
const CHARGE_COOLDOWN: float = 5.0

# =============================================================================
# 导出变量
# =============================================================================

## 伤害减免百分比
@export_range(0.0, 0.8) var damage_reduction: float = 0.3

## 冲锋速度倍率
@export_range(2.0, 5.0) var charge_speed_multiplier: float = CHARGE_SPEED_MULTIPLIER

## 冲锋冷却时间
@export_range(3.0, 10.0) var charge_cooldown: float = CHARGE_COOLDOWN

## 冲锋伤害
@export var charge_damage: float = 25.0

# =============================================================================
# 私有变量
# =============================================================================

var _is_charging: bool = false
var _charge_timer: float = 0.0
var _charge_direction: Vector2 = Vector2.ZERO
var _charge_cooldown_timer: float = 0.0
var _charge_distance_remaining: float = 0.0

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""节点就绪时初始化"""
	_setup_tank_stats()
	super._ready()


func _physics_process(delta: float) -> void:
	"""物理帧更新"""
	# 更新冲锋冷却
	if _charge_cooldown_timer > 0:
		_charge_cooldown_timer -= delta
	
	# 处理冲锋
	if _is_charging:
		_update_charge(delta)
		return
	
	# 调用父类处理
	super._physics_process(delta)

# =============================================================================
# 公共方法
# =============================================================================

## 开始冲锋
func start_charge() -> void:
	"""开始冲锋"""
	if _is_charging or _charge_cooldown_timer > 0 or target == null:
		return
	
	_is_charging = true
	_charge_direction = (target.global_position - global_position).normalized()
	_charge_distance_remaining = CHARGE_DISTANCE
	_charge_timer = 0
	
	charge_started.emit()
	
	print("[EnemyTank] 开始冲锋")


## 设置坦克属性
func setup_tank(speed: float, health: float, damage: float) -> void:
	"""设置坦克敌人属性"""
	move_speed = speed
	max_health = health
	attack_damage = damage
	current_health = max_health

# =============================================================================
# 私有方法 - 初始化
# =============================================================================

func _setup_tank_stats() -> void:
	"""设置坦克敌人属性"""
	# 如果使用默认值，则设置坦克专用属性
	if move_speed == DEFAULT_SPEED:
		move_speed = TANK_SPEED
	if max_health == DEFAULT_MAX_HEALTH:
		max_health = TANK_HEALTH
	if attack_damage == DEFAULT_ATTACK_DAMAGE:
		attack_damage = TANK_DAMAGE
	if attack_range == DEFAULT_ATTACK_RANGE:
		attack_range = TANK_ATTACK_RANGE
	if attack_cooldown == 1.0:
		attack_cooldown = TANK_ATTACK_COOLDOWN
	
	# 设置敌人类型
	enemy_type = EnemyType.TANK
	
	# 设置经验值和金币奖励
	experience_reward = 25
	gold_reward = 15
	
	# 冲锋伤害
	charge_damage = attack_damage * 1.5
	
	print("[EnemyTank] 初始化完成")

# =============================================================================
# 私有方法 - 更新
# =============================================================================

func _update_charge(delta: float) -> void:
	"""更新冲锋"""
	var charge_speed: float = move_speed * charge_speed_multiplier
	velocity = _charge_direction * charge_speed
	
	# 计算移动距离
	var move_dist: float = charge_speed * delta
	_charge_distance_remaining -= move_dist
	
	move_and_slide()
	
	# 检测碰撞
	var collision: KinematicCollision2D = get_last_slide_collision()
	if collision:
		var collider: Node = collision.get_collider()
		# 如果碰到玩家
		if collider and collider.is_in_group("players"):
			if collider.has_method("take_damage"):
				collider.take_damage(charge_damage, self)
			# 击退玩家
			if collider.has_method("knockback"):
				collider.knockback(_charge_direction, 200.0)
		
		# 碰到障碍物停止冲锋
		if collider and not collider.is_in_group("players"):
			_end_charge()
			return
	
	# 冲锋距离结束
	if _charge_distance_remaining <= 0:
		_end_charge()


func _end_charge() -> void:
	"""结束冲锋"""
	_is_charging = false
	_charge_cooldown_timer = charge_cooldown
	charge_ended.emit()
	
	print("[EnemyTank] 冲锋结束")

# =============================================================================
# 重写父类方法
# =============================================================================

func take_damage(amount: float, source: Node = null) -> void:
	"""受到伤害 - 应用伤害减免"""
	# 计算减免后的伤害
	var reduced_damage: float = amount * (1.0 - damage_reduction)
	super.take_damage(reduced_damage, source)


func _update_chase(delta: float) -> void:
	"""更新追击状态"""
	# 检查是否可以冲锋
	if _charge_cooldown_timer <= 0 and target and is_instance_valid(target):
		var dist: float = global_position.distance_to(target.global_position)
		if dist >= 100.0 and dist <= CHARGE_DISTANCE:
			start_charge()
			return
	
	# 调用父类处理
	super._update_chase(delta)

# =============================================================================
# 视觉效果
# =============================================================================

func _update_visuals() -> void:
	"""更新视觉效果"""
	super._update_visuals()
	
	# 冲锋时变大
	if _is_charging:
		scale = Vector2(1.3, 0.7)
		rotation = _charge_direction.angle()
	else:
		scale = Vector2.ONE
		rotation = 0
