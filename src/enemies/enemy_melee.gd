## Void Hunter - 近战敌人
## @description: 基础近战敌人，追踪并攻击玩家
## @author: Void Hunter Team
## @version: 1.0.0

extends "res://src/enemies/enemy_base.gd"

# =============================================================================
# 信号定义
# =============================================================================

## 攻击时触发
signal attack_performed()

# =============================================================================
# 常量定义
# =============================================================================

## 默认近战速度
const MELEE_SPEED: float = 100.0

## 默认近战生命值
const MELEE_HEALTH: float = 25.0

## 默认近战伤害
const MELEE_DAMAGE: float = 10.0

## 默认近战攻击范围
const MELEE_ATTACK_RANGE: float = 35.0

## 默认近战攻击冷却
const MELEE_ATTACK_COOLDOWN: float = 1.0

# =============================================================================
# 导出变量
# =============================================================================

## 冲刺速度倍率
@export_range(1.0, 3.0) var dash_speed_multiplier: float = 1.5

## 冲刺距离
@export_range(50.0, 200.0) var dash_distance: float = 100.0

## 攻击前摇时间
@export_range(0.0, 0.5) var attack_windup: float = 0.2

## 攻击后摇时间
@export_range(0.0, 0.5) var attack_winddown: float = 0.1

# =============================================================================
# 私有变量
# =============================================================================

var _is_dashing: bool = false
var _dash_timer: float = 0.0
var _dash_direction: Vector2 = Vector2.ZERO
var _is_in_attack_anim: bool = false
var _attack_anim_timer: float = 0.0

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""节点就绪时初始化"""
	_setup_melee_stats()
	super._ready()


func _physics_process(delta: float) -> void:
	"""物理帧更新"""
	# 处理冲刺
	if _is_dashing:
		_update_dash(delta)
		return
	
	# 处理攻击动画
	if _is_in_attack_anim:
		_update_attack_anim(delta)
		return
	
	# 调用父类处理
	super._physics_process(delta)

# =============================================================================
# 公共方法
# =============================================================================

## 设置近战属性
func setup_melee(speed: float, health: float, damage: float) -> void:
	"""设置近战敌人属性"""
	move_speed = speed
	max_health = health
	attack_damage = damage
	current_health = max_health


## 执行冲刺攻击
func perform_dash_attack() -> void:
	"""执行冲刺攻击"""
	if _is_dashing or target == null:
		return
	
	_is_dashing = true
	_dash_direction = (target.global_position - global_position).normalized()
	_dash_timer = dash_distance / (move_speed * dash_speed_multiplier)

# =============================================================================
# 私有方法 - 初始化
# =============================================================================

func _setup_melee_stats() -> void:
	"""设置近战敌人属性"""
	# 如果使用默认值，则设置近战专用属性
	if move_speed == DEFAULT_SPEED:
		move_speed = MELEE_SPEED
	if max_health == DEFAULT_MAX_HEALTH:
		max_health = MELEE_HEALTH
	if attack_damage == DEFAULT_ATTACK_DAMAGE:
		attack_damage = MELEE_DAMAGE
	if attack_range == DEFAULT_ATTACK_RANGE:
		attack_range = MELEE_ATTACK_RANGE
	if attack_cooldown == 1.0:
		attack_cooldown = MELEE_ATTACK_COOLDOWN
	
	# 设置敌人类型
	enemy_type = EnemyType.MELEE
	
	# 设置经验值和金币奖励
	experience_reward = 10
	gold_reward = 5
	
	print("[EnemyMelee] 初始化完成")

# =============================================================================
# 私有方法 - 更新
# =============================================================================

func _update_dash(delta: float) -> void:
	"""更新冲刺"""
	_dash_timer -= delta
	velocity = _dash_direction * move_speed * dash_speed_multiplier
	move_and_slide()
	
	if _dash_timer <= 0:
		_is_dashing = false


func _update_attack_anim(delta: float) -> void:
	"""更新攻击动画"""
	_attack_anim_timer -= delta
	velocity = Vector2.ZERO
	
	if _attack_anim_timer <= 0:
		_is_in_attack_anim = false

# =============================================================================
# 重写父类方法
# =============================================================================

func _perform_attack() -> void:
	"""执行近战攻击"""
	if target == null or not is_instance_valid(target):
		return
	
	# 进入攻击动画状态
	_is_in_attack_anim = true
	_attack_anim_timer = attack_windup + attack_winddown
	
	# 延迟造成伤害（等待前摇）
	await get_tree().create_timer(attack_windup).timeout
	
	# 检查目标是否还在范围内
	if target and is_instance_valid(target):
		var dist: float = global_position.distance_to(target.global_position)
		if dist <= attack_range * 1.2:
			# 造成伤害
			if target.has_method("take_damage"):
				target.take_damage(attack_damage, self)
			
			# 播放攻击音效
			AudioManager.play_sfx("melee_hit", 0.5)
			
			attack_performed.emit()
			
			print("[EnemyMelee] 攻击玩家，伤害: %.1f" % attack_damage)

# =============================================================================
# 视觉效果
# =============================================================================

func _update_visuals() -> void:
	"""更新视觉效果"""
	super._update_visuals()
	
	# 冲刺时拉伸效果
	if _is_dashing:
		var angle: float = _dash_direction.angle()
		rotation = angle
		scale = Vector2(1.2, 0.8)
	else:
		rotation = 0
		scale = Vector2.ONE
