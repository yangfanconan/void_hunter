## Void Hunter - 敌人AI行为基类
## @description: 敌人AI行为树的基类，定义通用AI行为接口
## @author: Void Hunter Team
## @version: 0.1.0

extends Node
class_name EnemyAIBase

# =============================================================================
# 信号定义
# =============================================================================

## AI状态改变时触发
signal ai_state_changed(old_state: String, new_state: String)

## 行为执行完成时触发
signal behavior_completed(behavior_name: String, success: bool)

# =============================================================================
# 枚举定义
# =============================================================================

## AI状态
enum AIState {
	IDLE,		## 空闲
	PATROL,		## 巡逻
	CHASE,		## 追击
	ATTACK,		## 攻击
	FLEE,		## 逃跑
	STUNNED		## 眩晕
}

## 行为状态
enum BehaviorStatus {
	RUNNING,	## 执行中
	SUCCESS,	## 成功
	FAILURE		## 失败
}

# =============================================================================
# 导出变量
# =============================================================================

## AI更新频率（秒）
@export var update_interval: float = 0.1

## 是否启用调试
@export var debug_enabled: bool = false

# =============================================================================
# 公共变量
# =============================================================================

## 当前AI状态
var current_state: AIState = AIState.IDLE

## AI是否激活
var is_active: bool = true

## AI所有者
var owner_enemy: EnemyBase = null

# =============================================================================
# 私有变量
# =============================================================================

var _update_timer: float = 0.0
var _behavior_tree: Node = null
var _blackboard: Dictionary = {}

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""
	节点就绪时初始化AI
	"""
	_initialize_ai()


func _process(delta: float) -> void:
	"""
	每帧更新AI
	@param delta: 帧间隔时间
	"""
	if not is_active or owner_enemy == null:
		return
	
	_update_timer += delta
	
	if _update_timer >= update_interval:
		_update_timer = 0.0
		_update_ai(delta)


# =============================================================================
# 公共方法
# =============================================================================

## 初始化AI
func initialize(enemy: EnemyBase) -> void:
	"""
	初始化AI
	@param enemy: 敌人引用
	"""
	owner_enemy = enemy
	_initialize_ai()


## 设置AI状态
func set_state(new_state: AIState) -> void:
	"""
	设置AI状态
	@param new_state: 新状态
	"""
	if current_state == new_state:
		return
	
	var old_state: AIState = current_state
	current_state = new_state
	
	# 状态进入处理
	_on_state_enter(new_state)
	
	ai_state_changed.emit(AIState.keys()[old_state], AIState.keys()[new_state])


## 强制执行行为
func force_behavior(behavior_name: String) -> BehaviorStatus:
	"""
	强制执行指定行为
	@param behavior_name: 行为名称
	@return: 行为状态
	"""
	return _execute_behavior(behavior_name)


## 停止当前行为
func stop_current_behavior() -> void:
	"""
	停止当前正在执行的行为
	"""
	# 子类实现
	pass


## 获取黑板数据
func get_blackboard_value(key: String, default_value: Variant = null) -> Variant:
	"""
	从黑板获取数据
	@param key: 键名
	@param default_value: 默认值
	@return: 数据值
	"""
	return _blackboard.get(key, default_value)


## 设置黑板数据
func set_blackboard_value(key: String, value: Variant) -> void:
	"""
	设置黑板数据
	@param key: 键名
	@param value: 数据值
	"""
	_blackboard[key] = value


# =============================================================================
# 私有方法
# =============================================================================

func _initialize_ai() -> void:
	"""
	初始化AI内部状态
	"""
	_blackboard.clear()
	current_state = AIState.IDLE


func _update_ai(delta: float) -> void:
	"""
	更新AI逻辑
	@param delta: 帧间隔时间
	"""
	# 根据当前状态执行相应逻辑
	match current_state:
		AIState.IDLE:
			_update_idle(delta)
		AIState.PATROL:
			_update_patrol(delta)
		AIState.CHASE:
			_update_chase(delta)
		AIState.ATTACK:
			_update_attack(delta)
		AIState.FLEE:
			_update_flee(delta)
		AIState.STUNNED:
			_update_stunned(delta)


func _update_idle(delta: float) -> void:
	"""
	更新空闲状态
	"""
	# 检查是否有目标
	if owner_enemy.current_target != null:
		set_state(AIState.CHASE)


func _update_patrol(delta: float) -> void:
	"""
	更新巡逻状态
	"""
	# 检查是否有目标
	if owner_enemy.current_target != null:
		set_state(AIState.CHASE)
		return
	
	# 执行巡逻逻辑
	_execute_behavior("patrol")


func _update_chase(delta: float) -> void:
	"""
	更新追击状态
	"""
	if owner_enemy.current_target == null:
		set_state(AIState.IDLE)
		return
	
	# 检查是否在攻击范围内
	var distance: float = owner_enemy.global_position.distance_to(
		owner_enemy.current_target.global_position
	)
	
	if distance <= owner_enemy.attack_range:
		set_state(AIState.ATTACK)
		return
	
	# 执行追击逻辑
	_execute_behavior("chase")


func _update_attack(delta: float) -> void:
	"""
	更新攻击状态
	"""
	if owner_enemy.current_target == null:
		set_state(AIState.IDLE)
		return
	
	# 检查是否还在攻击范围内
	var distance: float = owner_enemy.global_position.distance_to(
		owner_enemy.current_target.global_position
	)
	
	if distance > owner_enemy.attack_range * 1.5:
		set_state(AIState.CHASE)
		return
	
	# 执行攻击逻辑
	_execute_behavior("attack")


func _update_flee(delta: float) -> void:
	"""
	更新逃跑状态
	"""
	# 执行逃跑逻辑
	_execute_behavior("flee")


func _update_stunned(delta: float) -> void:
	"""
	更新眩晕状态
	"""
	# 眩晕状态下不执行任何行为
	pass


func _on_state_enter(state: AIState) -> void:
	"""
	进入新状态时的处理
	@param state: 新状态
	"""
	if debug_enabled:
		print("[AI] State changed to: %s" % AIState.keys()[state])


func _execute_behavior(behavior_name: String) -> BehaviorStatus:
	"""
	执行指定行为
	@param behavior_name: 行为名称
	@return: 行为状态
	"""
	# 子类实现具体行为
	match behavior_name:
		"patrol":
			return _behavior_patrol()
		"chase":
			return _behavior_chase()
		"attack":
			return _behavior_attack()
		"flee":
			return _behavior_flee()
	
	return BehaviorStatus.FAILURE


# =============================================================================
# 虚方法 - 子类重写
# =============================================================================

func _behavior_patrol() -> BehaviorStatus:
	"""
	巡逻行为
	@return: 行为状态
	"""
	return BehaviorStatus.SUCCESS


func _behavior_chase() -> BehaviorStatus:
	"""
	追击行为
	@return: 行为状态
	"""
	if owner_enemy.current_target == null:
		return BehaviorStatus.FAILURE
	
	owner_enemy.move_to_position(owner_enemy.current_target.global_position)
	return BehaviorStatus.RUNNING


func _behavior_attack() -> BehaviorStatus:
	"""
	攻击行为
	@return: 行为状态
	"""
	if owner_enemy.current_target == null:
		return BehaviorStatus.FAILURE
	
	owner_enemy.force_attack()
	return BehaviorStatus.SUCCESS


func _behavior_flee() -> BehaviorStatus:
	"""
	逃跑行为
	@return: 行为状态
	"""
	return BehaviorStatus.SUCCESS
