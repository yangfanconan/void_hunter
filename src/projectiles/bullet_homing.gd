## Void Hunter - 追踪子弹
## @description: 自动追踪最近敌人的子弹
## @author: Void Hunter Team
## @version: 1.0.0

extends BulletBase
class_name BulletHoming

# =============================================================================
# 导出变量
# =============================================================================

## 追踪强度（转向速度）
@export var turn_rate: float = 5.0

## 最大转向角度（每帧）
@export var max_turn_angle: float = PI / 8

## 失去目标后的行为
@export var lose_target_behavior: String = "straight"  # straight, destroy, wander

## 追踪预测（预判目标移动）
@export var prediction_factor: float = 0.3

# =============================================================================
# 私有变量
# =============================================================================

var _last_target_position: Vector2 = Vector2.ZERO
var _target_velocity: Vector2 = Vector2.ZERO

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""
	节点就绪时初始化
	"""
	bullet_type = BulletType.HOMING
	super._ready()


func _physics_process(delta: float) -> void:
	"""
	物理帧更新
	@param delta: 帧间隔时间
	"""
	# 更新生存时间
	_update_lifetime(delta)
	
	# 更新追踪
	_update_homing(delta)
	
	# 移动子弹
	position += direction * speed * delta

# =============================================================================
# 私有方法
# =============================================================================

func _update_homing(delta: float) -> void:
	"""
	更新追踪逻辑
	@param delta: 帧间隔时间
	"""
	# 寻找或更新目标
	if homing_target == null or not is_instance_valid(homing_target):
		_find_best_target()
		
		if homing_target == null:
			_handle_no_target()
			return
	
	# 计算目标位置（带预测）
	var target_position: Vector2 = _calculate_predicted_position()
	
	# 计算转向
	var target_direction: Vector2 = (target_position - global_position).normalized()
	var current_angle: float = direction.angle()
	var target_angle: float = target_direction.angle()
	
	# 平滑转向
	var angle_diff: float = wrapf(target_angle - current_angle, -PI, PI)
	var turn_amount: float = clamp(angle_diff * turn_rate * delta, -max_turn_angle, max_turn_angle)
	
	var new_angle: float = current_angle + turn_amount
	direction = Vector2.from_angle(new_angle)
	rotation = new_angle
	
	# 更新目标速度记录
	_update_target_velocity(target_position)


func _calculate_predicted_position() -> Vector2:
	"""
	计算预测的目标位置
	@return: 预测位置
	"""
	if homing_target == null:
		return global_position + direction * 100.0
	
	var target_position: Vector2 = homing_target.global_position
	
	# 如果目标有速度属性，使用预测
	if "velocity" in homing_target:
		var target_vel: Vector2 = homing_target.velocity
		var distance: float = global_position.distance_to(target_position)
		var time_to_reach: float = distance / speed
		return target_position + target_vel * time_to_reach * prediction_factor
	
	return target_position


func _update_target_velocity(current_position: Vector2) -> void:
	"""
	更新目标速度估计
	@param current_position: 当前目标位置
	"""
	if _last_target_position != Vector2.ZERO:
		_target_velocity = (current_position - _last_target_position)
	_last_target_position = current_position


func _find_best_target() -> void:
	"""
	寻找最佳追踪目标
	"""
	var targets: Array[Node]
	
	if is_player_bullet:
		targets = get_tree().get_nodes_in_group("enemies")
	else:
		targets = get_tree().get_nodes_in_group("players")
	
	var best_target: Node2D = null
	var best_score: float = -INF
	
	for target in targets:
		if not is_instance_valid(target) or target is not Node2D:
			continue
		
		var distance: float = global_position.distance_to(target.global_position)
		
		# 超出范围跳过
		if distance > homing_range:
			continue
		
		# 计算角度偏差（优先追踪前方的目标）
		var to_target: Vector2 = (target.global_position - global_position).normalized()
		var angle_diff: float = abs(direction.angle_to(to_target))
		
		# 综合评分：距离越近、角度越小，分数越高
		var score: float = -distance - angle_diff * 100.0
		
		# 检查目标是否有效（未被击中）
		if target in _hit_targets:
			continue
		
		if score > best_score:
			best_score = score
			best_target = target
	
	homing_target = best_target


func _handle_no_target() -> void:
	"""
	处理没有目标的情况
	"""
	match lose_target_behavior:
		"destroy":
			destroy()
		"wander":
			# 随机改变方向
			direction = direction.rotated(randf_range(-0.1, 0.1))
			rotation = direction.angle()
		_:  # straight
			# 继续直线飞行
			pass
