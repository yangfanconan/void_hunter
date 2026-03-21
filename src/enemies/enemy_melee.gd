## Void Hunter - 近战小怪
## @description: 低血量、快速追踪的近战敌人
## @author: Void Hunter Team
## @version: 1.0.0

extends EnemyBase
class_name EnemyMelee

# =============================================================================
# 导出变量
# =============================================================================

## 冲锋速度倍率
@export var charge_speed_multiplier: float = 1.5

## 冲锋距离
@export var charge_distance: float = 100.0

## 攻击前摇时间
@export var attack_windup: float = 0.3

# =============================================================================
# 私有变量
# =============================================================================

var _is_charging: bool = false
var _charge_timer: float = 0.0

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""
	节点就绪时初始化
	"""
	# 设置近战敌人属性
	enemy_type = EnemyType.MELEE
	enemy_name = "近战小怪"
	
	# 低血量
	max_health = 30.0
	current_health = max_health
	
	# 快速移动
	move_speed = 120.0
	
	# 近战伤害
	attack_damage = 8.0
	attack_cooldown = 0.8
	
	# 攻击范围
	attack_range = 40.0
	detection_range = 250.0
	
	# 掉落
	experience_reward = 8
	gold_reward = 3
	drop_chance = 0.05
	
	super._ready()


func _physics_process(delta: float) -> void:
	"""
	物理帧更新
	@param delta: 帧间隔时间
	"""
	# 更新冲锋计时
	if _is_charging:
		_charge_timer -= delta
		if _charge_timer <= 0:
			_is_charging = false
	
	super._physics_process(delta)

# =============================================================================
# 重写方法
# =============================================================================

func _handle_chase_state(_delta: float) -> void:
	"""
	处理追逐状态 - 近战敌人会冲锋
	"""
	if current_target == null or not is_instance_valid(current_target):
		clear_target()
		return
	
	# 更新目标位置
	if _track_timer >= track_precision:
		_track_timer = 0.0
		_last_known_target_position = current_target.global_position
	
	var distance_to_target: float = global_position.distance_to(current_target.global_position)
	
	# 检查是否超出追击范围
	if distance_to_target > chase_limit:
		clear_target()
		return
	
	# 检查是否进入攻击范围
	if distance_to_target <= attack_range:
		set_state(EnemyState.ATTACK)
		return
	
	# 冲锋逻辑
	var speed_mult: float = 1.0
	if not _is_charging and distance_to_target <= charge_distance:
		# 触发冲锋
		_is_charging = true
		_charge_timer = 0.5
		speed_mult = charge_speed_multiplier
	elif _is_charging:
		speed_mult = charge_speed_multiplier
	
	# 追击目标
	move_to_position(current_target.global_position, speed_mult)


func _perform_attack() -> void:
	"""
	执行攻击 - 近战攻击
	"""
	_is_attacking = true
	_attack_timer = attack_cooldown
	
	# 播放攻击前摇
	_play_attack_windup()
	
	await get_tree().create_timer(attack_windup).timeout
	
	# 检查目标是否仍在范围内
	if current_target != null and is_instance_valid(current_target):
		var distance: float = global_position.distance_to(current_target.global_position)
		if distance <= attack_range * 1.2:  # 稍微宽松的范围
			_deal_damage_to_target(current_target)
	
	_is_attacking = false


func _play_attack_windup() -> void:
	"""
	播放攻击前摇动画
	"""
	# 身体后拉然后冲刺
	var tween: Tween = create_tween()
	var attack_dir: Vector2 = facing_direction
	tween.tween_property(self, "position", global_position - attack_dir * 10, attack_windup * 0.5)
	tween.tween_property(self, "position", global_position + attack_dir * 5, attack_windup * 0.5)

# =============================================================================
# 对象池接口
# =============================================================================

func on_spawn() -> void:
	"""
	从对象池取出时的初始化
	"""
	super.on_spawn()
	_is_charging = false
	_charge_timer = 0.0
