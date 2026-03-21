## Void Hunter - 对象池管理器
## @description: 全局对象池管理单例，负责游戏对象的复用以优化性能
## @author: Void Hunter Team
## @version: 2.0.0

extends Node

# =============================================================================
# 信号定义
# =============================================================================

## 对象从池中取出时触发
signal object_spawned(pool_name: String, object: Node)

## 对象归还到池中时触发
signal object_despawned(pool_name: String, object: Node)

## 对象池创建时触发
signal pool_created(pool_name: String, initial_size: int)

## 对象池清空时触发
signal pool_cleared(pool_name: String)

## 对象池扩容时触发
signal pool_expanded(pool_name: String, new_size: int)

## 对象池收缩时触发
signal pool_shrunk(pool_name: String, new_size: int)

## 池耗尽警告
signal pool_exhausted(pool_name: String)

# =============================================================================
# 枚举定义
# =============================================================================

## 预定义池类型
enum PredefinedPoolType {
	BULLET,			## 子弹池
	ENEMY,			## 敌人池
	PARTICLE,		## 粒子效果池
	DAMAGE_NUMBER,	## 伤害数字池
	DROP_ITEM,		## 掉落物池
	PROJECTILE,		## 投射物池
	VFX				## 视觉效果池
}

## 扩容策略
enum ExpandStrategy {
	DISABLED,		## 禁用自动扩容
	LINEAR,			## 线性扩容（每次增加固定数量）
	EXPONENTIAL,	## 指数扩容（每次翻倍）
	ADAPTIVE		## 自适应扩容（根据使用情况）
}

# =============================================================================
# 常量定义
# =============================================================================

## 默认初始池大小
const DEFAULT_INITIAL_SIZE: int = 10

## 默认最大池大小
const DEFAULT_MAX_SIZE: int = 100

## 默认是否启用自动扩展
const DEFAULT_AUTO_EXPAND: bool = true

## 池清理检查间隔（秒）
const CLEANUP_CHECK_INTERVAL: float = 60.0

## 未使用对象最大存活时间（秒）
const MAX_UNUSED_TIME: float = 300.0  # 5分钟

## 预定义池配置
const PREDEFINED_POOL_CONFIGS: Dictionary = {
	PredefinedPoolType.BULLET: {
		"scene_path": "res://scenes/bullet.tscn",
		"initial_size": 100,
		"max_size": 500,
		"expand_strategy": ExpandStrategy.LINEAR,
		"expand_amount": 50
	},
	PredefinedPoolType.ENEMY: {
		"scene_path": "res://scenes/enemy.tscn",
		"initial_size": 50,
		"max_size": 200,
		"expand_strategy": ExpandStrategy.ADAPTIVE,
		"expand_amount": 20
	},
	PredefinedPoolType.PARTICLE: {
		"scene_path": "res://scenes/particle.tscn",
		"initial_size": 30,
		"max_size": 100,
		"expand_strategy": ExpandStrategy.LINEAR,
		"expand_amount": 10
	},
	PredefinedPoolType.DAMAGE_NUMBER: {
		"scene_path": "res://scenes/damage_number.tscn",
		"initial_size": 50,
		"max_size": 200,
		"expand_strategy": ExpandStrategy.LINEAR,
		"expand_amount": 25
	},
	PredefinedPoolType.DROP_ITEM: {
		"scene_path": "res://scenes/drop_item.tscn",
		"initial_size": 30,
		"max_size": 100,
		"expand_strategy": ExpandStrategy.LINEAR,
		"expand_amount": 10
	},
	PredefinedPoolType.PROJECTILE: {
		"scene_path": "res://scenes/projectile.tscn",
		"initial_size": 40,
		"max_size": 150,
		"expand_strategy": ExpandStrategy.LINEAR,
		"expand_amount": 20
	},
	PredefinedPoolType.VFX: {
		"scene_path": "res://scenes/vfx.tscn",
		"initial_size": 20,
		"max_size": 80,
		"expand_strategy": ExpandStrategy.LINEAR,
		"expand_amount": 10
	}
}

## 线性扩容默认数量
const LINEAR_EXPAND_AMOUNT: int = 10

## 指数扩容最大倍数
const MAX_EXPONENTIAL_MULTIPLIER: int = 8

## 自适应扩容使用率阈值
const ADAPTIVE_USAGE_THRESHOLD: float = 0.8

# =============================================================================
# 导出变量
# =============================================================================

## 是否启用调试日志
@export var debug_logging: bool = false

## 是否启用自动清理
@export var auto_cleanup_enabled: bool = true

## 全局最大总对象数
@export var global_max_objects: int = 2000

## 默认扩容策略
@export var default_expand_strategy: ExpandStrategy = ExpandStrategy.LINEAR

## 是否自动初始化预定义池
@export var auto_init_predefined_pools: bool = true

## 收缩阈值（使用率低于此值时收缩）
@export var shrink_threshold: float = 0.3

## 是否启用自动收缩
@export var auto_shrink_enabled: bool = true

# =============================================================================
# 公共变量
# =============================================================================

## 当前总对象数
var total_objects: int = 0

## 当前使用中对象数
var total_in_use: int = 0

## 池使用统计
var pool_statistics: Dictionary = {}

# =============================================================================
# 私有变量
# =============================================================================

## 对象池字典 {pool_name: {available: [], in_use: [], scene: PackedScene, settings: Dictionary}}
var _pools: Dictionary = {}

## 对象最后使用时间 {object: timestamp}
var _last_used_time: Dictionary = {}

## 清理计时器
var _cleanup_timer: Timer

## 对象到池名的映射
var _object_to_pool: Dictionary = {}

## 已初始化的预定义池
var _initialized_predefined_pools: Array[PredefinedPoolType] = []

## 池使用峰值记录
var _pool_peak_usage: Dictionary = {}

## 池扩容历史
var _pool_expand_history: Dictionary = {}

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""
	节点就绪时初始化对象池管理器
	"""
	_initialize_object_pool()


# =============================================================================
# 公共方法 - 初始化
# =============================================================================

## 初始化对象池管理器
func initialize() -> void:
	"""
	手动初始化对象池管理器
	"""
	_initialize_object_pool()


## 初始化预定义池
func initialize_predefined_pools() -> void:
	"""
	初始化所有预定义的对象池
	"""
	for pool_type in PredefinedPoolType.values():
		initialize_predefined_pool(pool_type)


## 初始化指定的预定义池
func initialize_predefined_pool(pool_type: PredefinedPoolType) -> bool:
	"""
	初始化指定的预定义池
	@param pool_type: 池类型
	@return: 是否成功
	"""
	if pool_type in _initialized_predefined_pools:
		return true
	
	var config: Dictionary = PREDEFINED_POOL_CONFIGS.get(pool_type, {})
	if config.is_empty():
		push_warning("未找到预定义池配置: %s" % PredefinedPoolType.keys()[pool_type])
		return false
	
	var pool_name: String = _get_predefined_pool_name(pool_type)
	var scene_path: String = config.get("scene_path", "")
	
	# 检查场景是否存在
	if not ResourceLoader.exists(scene_path):
		if debug_logging:
			print("[ObjectPool] 预定义池场景不存在，跳过: %s" % scene_path)
		return false
	
	var initial_size: int = config.get("initial_size", DEFAULT_INITIAL_SIZE)
	var max_size: int = config.get("max_size", DEFAULT_MAX_SIZE)
	var expand_strategy: ExpandStrategy = config.get("expand_strategy", default_expand_strategy)
	var expand_amount: int = config.get("expand_amount", LINEAR_EXPAND_AMOUNT)
	
	# 创建池
	var success: bool = create_pool(pool_name, scene_path, initial_size, max_size, true)
	
	if success:
		# 设置扩容策略
		_pools[pool_name]["settings"]["expand_strategy"] = expand_strategy
		_pools[pool_name]["settings"]["expand_amount"] = expand_amount
		
		_initialized_predefined_pools.append(pool_type)
		
		if debug_logging:
			print("[ObjectPool] 初始化预定义池: %s, 初始大小: %d" % [pool_name, initial_size])
	
	return success


## 获取预定义池名称
func _get_predefined_pool_name(pool_type: PredefinedPoolType) -> String:
	"""
	获取预定义池的名称
	@param pool_type: 池类型
	@return: 池名称
	"""
	return "predefined_%s" % PredefinedPoolType.keys()[pool_type].to_lower()

# =============================================================================
# 公共方法 - 池管理
# =============================================================================

## 创建对象池
func create_pool(pool_name: String, scene_path: String, initial_size: int = DEFAULT_INITIAL_SIZE, 
		max_size: int = DEFAULT_MAX_SIZE, auto_expand: bool = DEFAULT_AUTO_EXPAND) -> bool:
	"""
	创建一个新的对象池
	@param pool_name: 池名称
	@param scene_path: 场景文件路径
	@param initial_size: 初始大小
	@param max_size: 最大大小
	@param auto_expand: 是否自动扩展
	@return: 是否创建成功
	"""
	# 检查池是否已存在
	if _pools.has(pool_name):
		push_warning("对象池已存在: %s" % pool_name)
		return false
	
	# 加载场景
	var scene: PackedScene = load(scene_path)
	if scene == null:
		push_error("无法加载场景: %s" % scene_path)
		return false
	
	# 创建池结构
	_pools[pool_name] = {
		"scene": scene,
		"available": [],
		"in_use": [],
		"settings": {
			"max_size": max_size,
			"auto_expand": auto_expand,
			"scene_path": scene_path,
			"expand_strategy": default_expand_strategy,
			"expand_amount": LINEAR_EXPAND_AMOUNT
		}
	}
	
	# 初始化统计
	pool_statistics[pool_name] = {
		"total_spawns": 0,
		"total_despawns": 0,
		"peak_usage": 0,
		"expand_count": 0
	}
	_pool_peak_usage[pool_name] = 0
	_pool_expand_history[pool_name] = []
	
	# 预创建对象
	_precreate_objects(pool_name, initial_size)
	
	pool_created.emit(pool_name, initial_size)
	
	if debug_logging:
		print("[ObjectPool] 创建对象池: %s, 初始大小: %d" % [pool_name, initial_size])
	
	return true


## 销毁对象池
func destroy_pool(pool_name: String) -> bool:
	"""
	销毁指定对象池
	@param pool_name: 池名称
	@return: 是否销毁成功
	"""
	if not _pools.has(pool_name):
		push_warning("对象池不存在: %s" % pool_name)
		return false
	
	var pool: Dictionary = _pools[pool_name]
	
	# 释放所有对象
	for obj in pool["available"]:
		if is_instance_valid(obj):
			obj.queue_free()
			total_objects -= 1
	
	for obj in pool["in_use"]:
		if is_instance_valid(obj):
			obj.queue_free()
			total_objects -= 1
			total_in_use -= 1
	
	# 清理映射
	for obj in pool["available"] + pool["in_use"]:
		_object_to_pool.erase(obj)
		_last_used_time.erase(obj)
	
	_pools.erase(pool_name)
	pool_statistics.erase(pool_name)
	_pool_peak_usage.erase(pool_name)
	_pool_expand_history.erase(pool_name)
	
	pool_cleared.emit(pool_name)
	
	if debug_logging:
		print("[ObjectPool] 销毁对象池: %s" % pool_name)
	
	return true


## 检查池是否存在
func has_pool(pool_name: String) -> bool:
	"""
	检查指定对象池是否存在
	@param pool_name: 池名称
	@return: 是否存在
	"""
	return _pools.has(pool_name)


## 获取池信息
func get_pool_info(pool_name: String) -> Dictionary:
	"""
	获取对象池信息
	@param pool_name: 池名称
	@return: 池信息字典
	"""
	if not _pools.has(pool_name):
		return {}
	
	var pool: Dictionary = _pools[pool_name]
	var stats: Dictionary = pool_statistics.get(pool_name, {})
	
	return {
		"name": pool_name,
		"available_count": pool["available"].size(),
		"in_use_count": pool["in_use"].size(),
		"total_count": pool["available"].size() + pool["in_use"].size(),
		"max_size": pool["settings"]["max_size"],
		"auto_expand": pool["settings"]["auto_expand"],
		"expand_strategy": ExpandStrategy.keys()[pool["settings"].get("expand_strategy", default_expand_strategy)],
		"usage_rate": float(pool["in_use"].size()) / float(maxi(pool["in_use"].size() + pool["available"].size(), 1)),
		"peak_usage": stats.get("peak_usage", 0),
		"expand_count": stats.get("expand_count", 0)
	}


## 获取所有池信息
func get_all_pools_info() -> Array[Dictionary]:
	"""
	获取所有对象池的信息
	@return: 池信息数组
	"""
	var infos: Array[Dictionary] = []
	for pool_name in _pools.keys():
		infos.append(get_pool_info(pool_name))
	return infos

# =============================================================================
# 公共方法 - 对象操作
# =============================================================================

## 从池中获取对象
func spawn(pool_name: String, parent: Node = null, position: Variant = null, 
		rotation: Variant = null) -> Node:
	"""
	从对象池中获取一个对象
	@param pool_name: 池名称
	@param parent: 父节点（可选）
	@param position: 初始位置（可选）
	@param rotation: 初始旋转（可选）
	@return: 对象实例（失败返回null）
	"""
	if not _pools.has(pool_name):
		push_error("对象池不存在: %s" % pool_name)
		return null
	
	var pool: Dictionary = _pools[pool_name]
	var obj: Node = null
	
	# 从可用列表获取
	if pool["available"].size() > 0:
		obj = pool["available"].pop_back()
	else:
		# 池为空，尝试扩容
		if pool["settings"]["auto_expand"]:
			var expanded: bool = _try_expand_pool(pool_name)
			if expanded and pool["available"].size() > 0:
				obj = pool["available"].pop_back()
			elif total_objects < global_max_objects:
				# 扩容失败但还能创建新对象
				obj = _create_new_object(pool_name)
			else:
				push_warning("已达到全局最大对象数限制")
				pool_exhausted.emit(pool_name)
				return null
		else:
			push_warning("对象池已满且不允许扩展: %s" % pool_name)
			pool_exhausted.emit(pool_name)
			return null
	
	if obj == null:
		return null
	
	# 移动到使用中列表
	pool["in_use"].append(obj)
	total_in_use += 1
	
	# 更新统计
	_update_spawn_statistics(pool_name)
	
	# 设置父节点
	if parent != null:
		if obj.get_parent() != null:
			obj.get_parent().remove_child(obj)
		parent.add_child(obj)
	
	# 设置位置和旋转
	if position != null and "position" in obj:
		obj.position = position
	
	if rotation != null and "rotation" in obj:
		obj.rotation = rotation
	
	# 更新使用时间
	_last_used_time[obj] = Time.get_unix_time_from_system()
	
	# 调用对象的初始化方法（如果存在）
	if obj.has_method("on_spawn"):
		obj.on_spawn()
	
	object_spawned.emit(pool_name, obj)
	
	return obj


## 从预定义池获取对象
func spawn_from_predefined(pool_type: PredefinedPoolType, parent: Node = null, 
		position: Variant = null, rotation: Variant = null) -> Node:
	"""
	从预定义池获取对象
	@param pool_type: 池类型
	@param parent: 父节点
	@param position: 位置
	@param rotation: 旋转
	@return: 对象实例
	"""
	var pool_name: String = _get_predefined_pool_name(pool_type)
	
	# 如果池未初始化，尝试初始化
	if not has_pool(pool_name):
		if not initialize_predefined_pool(pool_type):
			return null
	
	return spawn(pool_name, parent, position, rotation)


## 将对象归还到池中
func despawn(obj: Node, delay: float = 0.0) -> void:
	"""
	将对象归还到对象池
	@param obj: 对象实例
	@param delay: 延迟时间（秒）
	"""
	if obj == null or not is_instance_valid(obj):
		return
	
	if delay > 0.0:
		# 延迟归还
		await get_tree().create_timer(delay).timeout
		if not is_instance_valid(obj):
			return
	
	# 获取对象所属的池
	var pool_name: String = _object_to_pool.get(obj, "")
	if pool_name.is_empty():
		push_warning("对象不属于任何对象池")
		return
	
	if not _pools.has(pool_name):
		return
	
	var pool: Dictionary = _pools[pool_name]
	
	# 从使用中列表移除
	var index: int = pool["in_use"].find(obj)
	if index == -1:
		push_warning("对象不在使用中列表")
		return
	
	pool["in_use"].remove_at(index)
	total_in_use -= 1
	
	# 更新统计
	pool_statistics[pool_name]["total_despawns"] += 1
	
	# 调用对象的清理方法（如果存在）
	if obj.has_method("on_despawn"):
		obj.on_despawn()
	
	# 重置对象状态
	_reset_object(obj)
	
	# 添加回可用列表
	pool["available"].append(obj)
	
	# 更新使用时间
	_last_used_time[obj] = Time.get_unix_time_from_system()
	
	object_despawned.emit(pool_name, obj)


## 批量归还对象
func despawn_all(pool_name: String) -> void:
	"""
	归还指定池中的所有对象
	@param pool_name: 池名称
	"""
	if not _pools.has(pool_name):
		return
	
	var pool: Dictionary = _pools[pool_name]
	var in_use_copy: Array = pool["in_use"].duplicate()
	
	for obj in in_use_copy:
		if is_instance_valid(obj):
			despawn(obj)


## 清空对象池（销毁所有对象）
func clear_pool(pool_name: String) -> void:
	"""
	清空指定对象池
	@param pool_name: 池名称
	"""
	if not _pools.has(pool_name):
		return
	
	var pool: Dictionary = _pools[pool_name]
	
	# 销毁所有对象
	for obj in pool["available"] + pool["in_use"]:
		if is_instance_valid(obj):
			obj.queue_free()
			total_objects -= 1
		_object_to_pool.erase(obj)
		_last_used_time.erase(obj)
	
	pool["available"].clear()
	pool["in_use"].clear()
	total_in_use -= pool["in_use"].size()
	
	pool_cleared.emit(pool_name)
	
	if debug_logging:
		print("[ObjectPool] 清空对象池: %s" % pool_name)


## 清空所有对象池
func clear_all_pools() -> void:
	"""
	清空所有对象池
	"""
	for pool_name in _pools.keys():
		clear_pool(pool_name)
	
	if debug_logging:
		print("[ObjectPool] 清空所有对象池")


## 清理未使用对象
func clear_unused_objects() -> void:
	"""
	清理所有池中未使用的对象（收缩池）
	"""
	for pool_name in _pools.keys():
		shrink_pool(pool_name, 0.5)  # 保留50%

# =============================================================================
# 公共方法 - 扩容/收缩
# =============================================================================

## 手动扩容池
func expand_pool(pool_name: String, amount: int = -1) -> bool:
	"""
	手动扩展对象池
	@param pool_name: 池名称
	@param amount: 扩展数量（-1表示使用默认策略）
	@return: 是否成功
	"""
	if not _pools.has(pool_name):
		return false
	
	var pool: Dictionary = _pools[pool_name]
	
	if amount < 0:
		amount = pool["settings"].get("expand_amount", LINEAR_EXPAND_AMOUNT)
	
	return _expand_pool_by_amount(pool_name, amount)


## 收缩池
func shrink_pool(pool_name: String, target_ratio: float = 0.5) -> void:
	"""
	收缩对象池到指定比例
	@param pool_name: 池名称
	@param target_ratio: 目标比例（0.0-1.0）
	"""
	if not _pools.has(pool_name):
		return
	
	var pool: Dictionary = _pools[pool_name]
	var available: Array = pool["available"]
	
	# 计算需要保留的数量
	var keep_count: int = int(available.size() * target_ratio)
	
	# 销毁多余的对象
	while available.size() > keep_count:
		var obj: Node = available.pop_back()
		if is_instance_valid(obj):
			obj.queue_free()
			total_objects -= 1
		_object_to_pool.erase(obj)
		_last_used_time.erase(obj)
	
	pool_shrunk.emit(pool_name, pool["available"].size() + pool["in_use"].size())
	
	if debug_logging:
		print("[ObjectPool] 收缩对象池: %s, 保留 %d 个对象" % [pool_name, keep_count])


## 收缩所有池
func shrink_all_pools(target_ratio: float = 0.5) -> void:
	"""
	收缩所有对象池
	"""
	for pool_name in _pools.keys():
		shrink_pool(pool_name, target_ratio)

# =============================================================================
# 公共方法 - 预热
# =============================================================================

## 预热对象池
func warm_up_pool(pool_name: String, count: int) -> bool:
	"""
	预热对象池，提前创建指定数量的对象
	@param pool_name: 池名称
	@param count: 预热数量
	@return: 是否成功
	"""
	if not _pools.has(pool_name):
		push_error("对象池不存在: %s" % pool_name)
		return false
	
	_precreate_objects(pool_name, count)
	
	if debug_logging:
		print("[ObjectPool] 预热对象池: %s, 数量: %d" % [pool_name, count])
	
	return true


## 预热所有预定义池
func warm_up_all_predefined() -> void:
	"""
	预热所有预定义池
	"""
	for pool_type in _initialized_predefined_pools:
		var pool_name: String = _get_predefined_pool_name(pool_type)
		var config: Dictionary = PREDEFINED_POOL_CONFIGS.get(pool_type, {})
		var warm_count: int = config.get("initial_size", DEFAULT_INITIAL_SIZE)
		warm_up_pool(pool_name, warm_count)

# =============================================================================
# 私有方法 - 初始化
# =============================================================================

func _initialize_object_pool() -> void:
	"""
	初始化对象池管理器
	"""
	# 创建自动清理计时器
	if auto_cleanup_enabled:
		_setup_cleanup_timer()
	
	# 自动初始化预定义池
	if auto_init_predefined_pools:
		initialize_predefined_pools()
	
	if debug_logging:
		print("[ObjectPool] 初始化完成")


func _setup_cleanup_timer() -> void:
	"""
	设置自动清理计时器
	"""
	_cleanup_timer = Timer.new()
	_cleanup_timer.wait_time = CLEANUP_CHECK_INTERVAL
	_cleanup_timer.autostart = true
	_cleanup_timer.timeout.connect(_on_cleanup_timeout)
	add_child(_cleanup_timer)

# =============================================================================
# 私有方法 - 扩容
# =============================================================================

func _try_expand_pool(pool_name: String) -> bool:
	"""
	尝试根据策略扩展池
	@param pool_name: 池名称
	@return: 是否成功
	"""
	var pool: Dictionary = _pools[pool_name]
	var strategy: ExpandStrategy = pool["settings"].get("expand_strategy", default_expand_strategy)
	
	var expand_amount: int = 0
	
	match strategy:
		ExpandStrategy.DISABLED:
			return false
		
		ExpandStrategy.LINEAR:
			expand_amount = pool["settings"].get("expand_amount", LINEAR_EXPAND_AMOUNT)
		
		ExpandStrategy.EXPONENTIAL:
			var current_size: int = pool["available"].size() + pool["in_use"].size()
			var history: Array = _pool_expand_history.get(pool_name, [])
			var multiplier: int = mini(pow(2, history.size()), MAX_EXPONENTIAL_MULTIPLIER)
			expand_amount = current_size * (multiplier - 1)
		
		ExpandStrategy.ADAPTIVE:
			expand_amount = _calculate_adaptive_expand_amount(pool_name)
	
	if expand_amount <= 0:
		return false
	
	return _expand_pool_by_amount(pool_name, expand_amount)


func _expand_pool_by_amount(pool_name: String, amount: int) -> bool:
	"""
	按指定数量扩展池
	@param pool_name: 池名称
	@param amount: 扩展数量
	@return: 是否成功
	"""
	var pool: Dictionary = _pools[pool_name]
	var max_size: int = pool["settings"]["max_size"]
	var current_size: int = pool["available"].size() + pool["in_use"].size()
	
	# 检查是否达到最大限制
	if current_size >= max_size:
		return false
	
	# 计算实际可扩展数量
	var actual_expand: int = mini(amount, max_size - current_size)
	
	if actual_expand <= 0:
		return false
	
	# 检查全局限制
	if total_objects + actual_expand > global_max_objects:
		actual_expand = global_max_objects - total_objects
	
	if actual_expand <= 0:
		return false
	
	# 创建新对象
	_precreate_objects(pool_name, actual_expand)
	
	# 记录扩容历史
	_pool_expand_history[pool_name].append(actual_expand)
	pool_statistics[pool_name]["expand_count"] += 1
	
	pool_expanded.emit(pool_name, pool["available"].size() + pool["in_use"].size())
	
	if debug_logging:
		print("[ObjectPool] 扩展对象池: %s, 增加 %d 个对象" % [pool_name, actual_expand])
	
	return true


func _calculate_adaptive_expand_amount(pool_name: String) -> int:
	"""
	计算自适应扩容数量
	@param pool_name: 池名称
	@return: 扩容数量
	"""
	var pool: Dictionary = _pools[pool_name]
	var stats: Dictionary = pool_statistics.get(pool_name, {})
	
	# 获取使用峰值
	var peak: int = stats.get("peak_usage", 0)
	var current_available: int = pool["available"].size()
	
	# 如果峰值很高，扩容更多
	if peak > current_available:
		return mini(peak - current_available + 10, 50)
	
	# 默认线性扩容
	return pool["settings"].get("expand_amount", LINEAR_EXPAND_AMOUNT)

# =============================================================================
# 私有方法 - 对象管理
# =============================================================================

func _precreate_objects(pool_name: String, count: int) -> void:
	"""
	预创建对象
	@param pool_name: 池名称
	@param count: 创建数量
	"""
	var pool: Dictionary = _pools[pool_name]
	
	for i in range(count):
		if total_objects >= global_max_objects:
			push_warning("已达到全局最大对象数限制")
			break
		
		var obj: Node = _create_new_object(pool_name)
		if obj != null:
			pool["available"].append(obj)


func _create_new_object(pool_name: String) -> Node:
	"""
	创建新对象
	@param pool_name: 池名称
	@return: 新创建的对象
	"""
	var pool: Dictionary = _pools[pool_name]
	var scene: PackedScene = pool["scene"]
	
	var obj: Node = scene.instantiate()
	
	# 设置对象为非活动状态
	_reset_object(obj)
	
	# 记录映射
	_object_to_pool[obj] = pool_name
	_last_used_time[obj] = Time.get_unix_time_from_system()
	
	total_objects += 1
	
	return obj


func _reset_object(obj: Node) -> void:
	"""
	重置对象状态
	@param obj: 对象实例
	"""
	# 从父节点移除
	if obj.get_parent() != null:
		obj.get_parent().remove_child(obj)
	
	# 重置常见属性
	if "position" in obj:
		obj.position = Vector2.ZERO
	if "rotation" in obj:
		obj.rotation = 0.0
	if "visible" in obj:
		obj.visible = false
	
	# 如果对象有重置方法，调用它
	if obj.has_method("reset"):
		obj.reset()


func _update_spawn_statistics(pool_name: String) -> void:
	"""
	更新生成统计
	@param pool_name: 池名称
	"""
	if not pool_statistics.has(pool_name):
		pool_statistics[pool_name] = {
			"total_spawns": 0,
			"total_despawns": 0,
			"peak_usage": 0,
			"expand_count": 0
		}
	
	var stats: Dictionary = pool_statistics[pool_name]
	stats["total_spawns"] += 1
	
	var pool: Dictionary = _pools[pool_name]
	var current_usage: int = pool["in_use"].size()
	
	if current_usage > stats["peak_usage"]:
		stats["peak_usage"] = current_usage

# =============================================================================
# 私有方法 - 清理
# =============================================================================

func _on_cleanup_timeout() -> void:
	"""
	自动清理超时回调
	"""
	var current_time: float = Time.get_unix_time_from_system()
	
	for pool_name in _pools.keys():
		var pool: Dictionary = _pools[pool_name]
		var to_remove: Array = []
		
		# 检查可用列表中的对象
		for obj in pool["available"]:
			if not is_instance_valid(obj):
				to_remove.append(obj)
				continue
			
			var last_used: float = _last_used_time.get(obj, 0.0)
			if current_time - last_used > MAX_UNUSED_TIME:
				# 对象长时间未使用，销毁它
				obj.queue_free()
				to_remove.append(obj)
				total_objects -= 1
				_object_to_pool.erase(obj)
				_last_used_time.erase(obj)
		
		# 从可用列表移除
		for obj in to_remove:
			pool["available"].erase(obj)
		
		if not to_remove.is_empty() and debug_logging:
			print("[ObjectPool] 自动清理对象池 %s: 移除 %d 个未使用对象" % [pool_name, to_remove.size()])
		
		# 自动收缩
		if auto_shrink_enabled:
			var usage_rate: float = float(pool["in_use"].size()) / float(maxi(pool["in_use"].size() + pool["available"].size(), 1))
			if usage_rate < shrink_threshold and pool["available"].size() > 10:
				shrink_pool(pool_name, 0.5)

# =============================================================================
# 公共方法 - 调试
# =============================================================================

## 获取调试信息
func get_debug_info() -> Dictionary:
	"""
	获取对象池调试信息
	@return: 调试信息字典
	"""
	return {
		"total_pools": _pools.size(),
		"total_objects": total_objects,
		"total_in_use": total_in_use,
		"global_max_objects": global_max_objects,
		"predefined_pools_initialized": _initialized_predefined_pools.size(),
		"pools": get_all_pools_info(),
		"statistics": pool_statistics.duplicate()
	}


## 获取池使用率
func get_pool_usage_rate(pool_name: String) -> float:
	"""
	获取指定池的使用率
	@param pool_name: 池名称
	@return: 使用率（0.0-1.0）
	"""
	if not _pools.has(pool_name):
		return 0.0
	
	var pool: Dictionary = _pools[pool_name]
	var total: int = pool["available"].size() + pool["in_use"].size()
	
	if total == 0:
		return 0.0
	
	return float(pool["in_use"].size()) / float(total)


## 获取内存使用估算
func get_estimated_memory_usage() -> int:
	"""
	获取估算的内存使用量（MB）
	@return: 内存使用量
	"""
	# 这是一个粗略估计
	return total_objects * 2  # 假设每个对象平均占用2KB
