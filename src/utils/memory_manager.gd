## Void Hunter - 内存管理器
## @description: 处理资源卸载、GC控制和内存监控
## @author: Void Hunter Team
## @version: 1.0.0

extends Node

# =============================================================================
# 信号定义
# =============================================================================

## 内存使用变化时触发
signal memory_usage_changed(current_mb: float, peak_mb: float)

## 内存警告时触发
signal memory_warning(level: int, usage_mb: float)

## 资源卸载时触发
signal resource_unloaded(resource_path: String)

## 强制GC完成时触发
signal garbage_collection_completed(freed_bytes: int)

## 低内存模式改变时触发
signal low_memory_mode_changed(enabled: bool)

# =============================================================================
# 枚举定义
# =============================================================================

## 内存警告级别
enum MemoryWarningLevel {
	NORMAL,		## 正常
	CAUTION,	## 警告
	WARNING,	## 严重警告
	CRITICAL	## 危急
}

## 资源优先级
enum ResourcePriority {
	LOW,		## 低优先级（可随时卸载）
	NORMAL,		## 正常优先级
	HIGH,		## 高优先级（必要时才卸载）
	CRITICAL	## 关键资源（永不卸载）
}

## 清理策略
enum CleanupStrategy {
	CONSERVATIVE,	## 保守策略（只清理低优先级）
	MODERATE,		## 中等策略（清理低和普通优先级）
	AGGRESSIVE		## 激进策略（清理所有非关键资源）
}

# =============================================================================
# 常量定义
# =============================================================================

## 内存检查间隔（秒）
const MEMORY_CHECK_INTERVAL: float = 5.0

## 警告级别阈值（MB）
const MEMORY_THRESHOLDS: Dictionary = {
	MemoryWarningLevel.CAUTION: 300,
	MemoryWarningLevel.WARNING: 400,
	MemoryWarningLevel.CRITICAL: 500
}

## 自动清理阈值（MB）
const AUTO_CLEANUP_THRESHOLD: float = 350.0

## 资源未使用超时（秒）
const RESOURCE_UNUSED_TIMEOUT: float = 180.0  # 3分钟

## GC间隔（秒）
const GC_INTERVAL: float = 30.0

## 最小保留内存（MB）
const MIN_RESERVED_MEMORY: float = 100.0

# =============================================================================
# 导出变量
# =============================================================================

## 是否启用内存监控
@export var enable_memory_monitoring: bool = true

## 是否启用自动清理
@export var enable_auto_cleanup: bool = true

## 是否启用定时GC
@export var enable_scheduled_gc: bool = true

## 自动清理策略
@export var auto_cleanup_strategy: CleanupStrategy = CleanupStrategy.MODERATE

## 内存警告阈值系数（0.5-1.0）
@export var warning_threshold_factor: float = 0.8

## 是否在低内存时降低画质
@export var reduce_quality_on_low_memory: bool = true

## 最大缓存资源数
@export var max_cached_resources: int = 100

# =============================================================================
# 公共变量
# =============================================================================

## 当前内存使用（MB）
var current_memory_usage: float = 0.0

## 峰值内存使用（MB）
var peak_memory_usage: float = 0.0

## 当前静态内存（MB）
var static_memory: float = 0.0

## 当前动态内存（MB）
var dynamic_memory: float = 0.0

## 当前警告级别
var current_warning_level: MemoryWarningLevel = MemoryWarningLevel.NORMAL

## 是否处于低内存模式
var is_low_memory_mode: bool = false

## 缓存的资源
var cached_resources: Dictionary = {}

## 资源使用统计
var resource_stats: Dictionary = {}

# =============================================================================
# 私有变量
# =============================================================================

var _is_initialized: bool = false
var _memory_check_timer: float = 0.0
var _gc_timer: float = 0.0
var _resource_last_used: Dictionary = {}
var _unload_queue: Array[String] = []
var _total_freed_bytes: int = 0

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""
	节点就绪时初始化
	"""
	_initialize_memory_manager()


func _process(delta: float) -> void:
	"""
	每帧更新
	"""
	if not enable_memory_monitoring:
		return
	
	_memory_check_timer += delta
	
	if _memory_check_timer >= MEMORY_CHECK_INTERVAL:
		_memory_check_timer = 0.0
		_update_memory_stats()
		_check_memory_status()
	
	# 定时GC
	if enable_scheduled_gc:
		_gc_timer += delta
		if _gc_timer >= GC_INTERVAL:
			_gc_timer = 0.0
			_perform_scheduled_gc()

# =============================================================================
# 公共方法 - 初始化
# =============================================================================

## 初始化内存管理器
func initialize() -> void:
	"""
	手动初始化内存管理器
	"""
	_initialize_memory_manager()

# =============================================================================
# 公共方法 - 内存监控
# =============================================================================

## 获取当前内存使用
func get_memory_usage() -> float:
	"""
	获取当前内存使用量（MB）
	@return: 内存使用量
	"""
	_update_memory_stats()
	return current_memory_usage


## 获取内存使用详情
func get_memory_details() -> Dictionary:
	"""
	获取内存使用详情
	@return: 内存详情字典
	"""
	_update_memory_stats()
	
	return {
		"static_memory_mb": static_memory,
		"dynamic_memory_mb": dynamic_memory,
		"total_memory_mb": current_memory_usage,
		"peak_memory_mb": peak_memory_usage,
		"warning_level": MemoryWarningLevel.keys()[current_warning_level],
		"cached_resources": cached_resources.size(),
		"is_low_memory_mode": is_low_memory_mode
	}


## 获取可用内存估算
func get_available_memory_estimate() -> float:
	"""
	估算可用内存（MB）
	@return: 可用内存
	"""
	# 这是一个粗略估计
	var total_system_memory: float = _get_system_memory_estimate()
	return maxf(total_system_memory - current_memory_usage, 0.0)


## 检查是否内存充足
func is_memory_sufficient(required_mb: float = 100.0) -> bool:
	"""
	检查是否有足够的内存
	@param required_mb: 需要的内存量
	@return: 是否充足
	"""
	return get_available_memory_estimate() >= required_mb

# =============================================================================
# 公共方法 - 资源缓存
# =============================================================================

## 缓存资源
func cache_resource(resource_path: String, priority: ResourcePriority = ResourcePriority.NORMAL) -> void:
	"""
	缓存资源
	@param resource_path: 资源路径
	@param priority: 优先级
	"""
	# 检查是否超过最大缓存数
	if cached_resources.size() >= max_cached_resources:
		_cleanup_low_priority_resources()
	
	cached_resources[resource_path] = {
		"priority": priority,
		"load_time": Time.get_unix_time_from_system(),
		"last_used": Time.get_unix_time_from_system(),
		"use_count": 0
	}
	
	resource_stats[resource_path] = {
		"hits": 0,
		"misses": 0
	}


## 标记资源使用
func touch_resource(resource_path: String) -> void:
	"""
	标记资源被使用
	@param resource_path: 资源路径
	"""
	if cached_resources.has(resource_path):
		cached_resources[resource_path]["last_used"] = Time.get_unix_time_from_system()
		cached_resources[resource_path]["use_count"] += 1
		
		if resource_stats.has(resource_path):
			resource_stats[resource_path]["hits"] += 1


## 检查资源是否缓存
func is_resource_cached(resource_path: String) -> bool:
	"""
	检查资源是否已缓存
	@param resource_path: 资源路径
	@return: 是否已缓存
	"""
	return cached_resources.has(resource_path)


## 获取资源优先级
func get_resource_priority(resource_path: String) -> ResourcePriority:
	"""
	获取资源的优先级
	@param resource_path: 资源路径
	@return: 优先级
	"""
	if cached_resources.has(resource_path):
		return cached_resources[resource_path]["priority"]
	return ResourcePriority.NORMAL

# =============================================================================
# 公共方法 - 资源卸载
# =============================================================================

## 卸载资源
func unload_resource(resource_path: String, force: bool = false) -> bool:
	"""
	卸载指定资源
	@param resource_path: 资源路径
	@param force: 是否强制卸载
	@return: 是否成功
	"""
	if not cached_resources.has(resource_path):
		return false
	
	var info: Dictionary = cached_resources[resource_path]
	
	# 检查优先级
	if not force and info["priority"] == ResourcePriority.CRITICAL:
		return false
	
	# 卸载资源
	var resource: Resource = ResourceLoader.load(resource_path)
	if resource:
		# 释放引用
		resource = null
	
	cached_resources.erase(resource_path)
	resource_stats.erase(resource_path)
	_resource_last_used.erase(resource_path)
	
	resource_unloaded.emit(resource_path)
	
	return true


## 卸载未使用的资源
func unload_unused_resources() -> int:
	"""
	卸载所有未使用的资源
	@return: 卸载的资源数量
	"""
	var current_time: float = Time.get_unix_time_from_system()
	var unloaded_count: int = 0
	
	var to_unload: Array[String] = []
	
	for path in cached_resources.keys():
		var info: Dictionary = cached_resources[path]
		var last_used: float = info["last_used"]
		var priority: ResourcePriority = info["priority"]
		
		# 检查是否超时且非关键资源
		if current_time - last_used > RESOURCE_UNUSED_TIMEOUT:
			if priority != ResourcePriority.CRITICAL:
				to_unload.append(path)
	
	for path in to_unload:
		if unload_resource(path):
			unloaded_count += 1
	
	return unloaded_count


## 按优先级清理资源
func cleanup_by_priority(min_priority: ResourcePriority = ResourcePriority.LOW) -> int:
	"""
	按优先级清理资源
	@param min_priority: 最小优先级（低于此优先级的会被清理）
	@return: 清理数量
	"""
	var cleaned_count: int = 0
	var to_clean: Array[String] = []
	
	for path in cached_resources.keys():
		var priority: ResourcePriority = cached_resources[path]["priority"]
		if priority <= min_priority and priority != ResourcePriority.CRITICAL:
			to_clean.append(path)
	
	for path in to_clean:
		if unload_resource(path):
			cleaned_count += 1
	
	return cleaned_count


## 清空所有缓存
func clear_all_cache() -> void:
	"""
	清空所有资源缓存
	"""
	var to_unload: Array[String] = []
	
	for path in cached_resources.keys():
		if cached_resources[path]["priority"] != ResourcePriority.CRITICAL:
			to_unload.append(path)
	
	for path in to_unload:
		unload_resource(path, false)

# =============================================================================
# 公共方法 - 垃圾回收
# =============================================================================

## 手动触发GC
func trigger_gc() -> void:
	"""
	手动触发垃圾回收
	"""
	_perform_gc()


## 执行内存清理
func perform_memory_cleanup(strategy: CleanupStrategy = CleanupStrategy.MODERATE) -> void:
	"""
	执行内存清理
	@param strategy: 清理策略
	"""
	match strategy:
		CleanupStrategy.CONSERVATIVE:
			cleanup_by_priority(ResourcePriority.LOW)
		
		CleanupStrategy.MODERATE:
			cleanup_by_priority(ResourcePriority.NORMAL)
		
		CleanupStrategy.AGGRESSIVE:
			cleanup_by_priority(ResourcePriority.HIGH)
	
	# 触发GC
	_perform_gc()
	
	# 通知对象池清理
	if has_node("/root/ObjectPool"):
		var object_pool: Node = get_node("/root/ObjectPool")
		if object_pool.has_method("clear_unused_objects"):
			object_pool.call("clear_unused_objects")

# =============================================================================
# 公共方法 - 低内存处理
# =============================================================================

## 进入低内存模式
func enter_low_memory_mode() -> void:
	"""
	进入低内存模式
	"""
	if is_low_memory_mode:
		return
	
	is_low_memory_mode = true
	low_memory_mode_changed.emit(true)
	
	# 执行清理
	perform_memory_cleanup(CleanupStrategy.AGGRESSIVE)
	
	# 降低画质
	if reduce_quality_on_low_memory:
		if has_node("/root/RenderOptimizer"):
			var render_optimizer: Node = get_node("/root/RenderOptimizer")
			if render_optimizer.has_method("enable_low_quality_mode"):
				render_optimizer.call("enable_low_quality_mode", true)
	
	print("[MemoryManager] 进入低内存模式")


## 退出低内存模式
func exit_low_memory_mode() -> void:
	"""
	退出低内存模式
	"""
	if not is_low_memory_mode:
		return
	
	is_low_memory_mode = false
	low_memory_mode_changed.emit(false)
	
	# 恢复画质
	if reduce_quality_on_low_memory:
		if has_node("/root/RenderOptimizer"):
			var render_optimizer: Node = get_node("/root/RenderOptimizer")
			if render_optimizer.has_method("enable_low_quality_mode"):
				render_optimizer.call("enable_low_quality_mode", false)
	
	print("[MemoryManager] 退出低内存模式")


## 处理内存压力
func handle_memory_pressure(level: MemoryWarningLevel) -> void:
	"""
	处理内存压力
	@param level: 警告级别
	"""
	current_warning_level = level
	memory_warning.emit(level, current_memory_usage)
	
	match level:
		MemoryWarningLevel.CAUTION:
			# 警告级别：清理低优先级
			cleanup_by_priority(ResourcePriority.LOW)
		
		MemoryWarningLevel.WARNING:
			# 严重警告：进入低内存模式
			enter_low_memory_mode()
			cleanup_by_priority(ResourcePriority.NORMAL)
		
		MemoryWarningLevel.CRITICAL:
			# 危急：激进清理
			enter_low_memory_mode()
			perform_memory_cleanup(CleanupStrategy.AGGRESSIVE)
			_perform_gc()

# =============================================================================
# 私有方法 - 初始化
# =============================================================================

func _initialize_memory_manager() -> void:
	"""
	初始化内存管理器
	"""
	if _is_initialized:
		return
	
	_is_initialized = true
	
	# 初始内存统计
	_update_memory_stats()
	
	print("[MemoryManager] 初始化完成")
	print("  初始内存: %.2f MB" % current_memory_usage)

# =============================================================================
# 私有方法 - 内存统计
# =============================================================================

func _update_memory_stats() -> void:
	"""
	更新内存统计
	"""
	# 获取静态内存
	static_memory = Performance.get_monitor(Performance.MEMORY_STATIC) / (1024.0 * 1024.0)
	
	# 获取动态内存
	dynamic_memory = Performance.get_monitor(Performance.MEMORY_DYNAMIC) / (1024.0 * 1024.0)
	
	# 计算总内存
	current_memory_usage = static_memory + dynamic_memory
	
	# 更新峰值
	if current_memory_usage > peak_memory_usage:
		peak_memory_usage = current_memory_usage
	
	# 发送信号
	memory_usage_changed.emit(current_memory_usage, peak_memory_usage)


func _check_memory_status() -> void:
	"""
	检查内存状态
	"""
	# 检查警告级别
	var new_level: MemoryWarningLevel = MemoryWarningLevel.NORMAL
	
	if current_memory_usage >= MEMORY_THRESHOLDS[MemoryWarningLevel.CRITICAL]:
		new_level = MemoryWarningLevel.CRITICAL
	elif current_memory_usage >= MEMORY_THRESHOLDS[MemoryWarningLevel.WARNING]:
		new_level = MemoryWarningLevel.WARNING
	elif current_memory_usage >= MEMORY_THRESHOLDS[MemoryWarningLevel.CAUTION]:
		new_level = MemoryWarningLevel.CAUTION
	
	# 如果级别变化
	if new_level != current_warning_level:
		handle_memory_pressure(new_level)
	
	# 自动清理
	if enable_auto_cleanup and current_memory_usage >= AUTO_CLEANUP_THRESHOLD:
		perform_memory_cleanup(auto_cleanup_strategy)
	
	# 检查是否可以退出低内存模式
	if is_low_memory_mode and current_memory_usage < AUTO_CLEANUP_THRESHOLD * 0.7:
		exit_low_memory_mode()

# =============================================================================
# 私有方法 - GC
# =============================================================================

func _perform_gc() -> void:
	"""
	执行垃圾回收
	"""
	var before_memory: float = current_memory_usage
	
	# 清理未使用的资源
	unload_unused_resources()
	
	# 手动触发Godot的内存管理
	# 注意：Godot 4.x没有显式的GC API，但我们可以通过释放引用来帮助
	
	var after_memory: float = get_memory_usage()
	var freed: int = int((before_memory - after_memory) * 1024 * 1024)
	
	if freed > 0:
		_total_freed_bytes += freed
		garbage_collection_completed.emit(freed)
		
		if OS.is_debug_build():
			print("[MemoryManager] GC完成，释放: %.2f MB" % (freed / (1024.0 * 1024.0)))


func _perform_scheduled_gc() -> void:
	"""
	执行定时GC
	"""
	# 只在内存使用较高时执行
	if current_memory_usage > AUTO_CLEANUP_THRESHOLD * 0.8:
		_perform_gc()

# =============================================================================
# 私有方法 - 资源清理
# =============================================================================

func _cleanup_low_priority_resources() -> void:
	"""
	清理低优先级资源以腾出空间
	"""
	cleanup_by_priority(ResourcePriority.LOW)


func _get_system_memory_estimate() -> float:
	"""
	获取系统内存估算（MB）
	@return: 系统内存
	"""
	# 根据平台估算
	if OS.has_feature("web"):
		return 512.0  # WebGL通常有512MB限制
	elif OS.has_feature("mobile"):
		return 1024.0  # 移动设备通常分配1GB给应用
	else:
		return 2048.0  # 桌面平台假设2GB可用

# =============================================================================
# 调试方法
# =============================================================================

## 获取调试信息
func get_debug_info() -> Dictionary:
	"""
	获取调试信息
	@return: 调试信息字典
	"""
	return {
		"current_memory_mb": current_memory_usage,
		"peak_memory_mb": peak_memory_usage,
		"static_memory_mb": static_memory,
		"dynamic_memory_mb": dynamic_memory,
		"warning_level": MemoryWarningLevel.keys()[current_warning_level],
		"is_low_memory_mode": is_low_memory_mode,
		"cached_resources_count": cached_resources.size(),
		"max_cached_resources": max_cached_resources,
		"total_freed_bytes": _total_freed_bytes,
		"auto_cleanup_enabled": enable_auto_cleanup,
		"monitoring_enabled": enable_memory_monitoring
	}


## 获取资源统计
func get_resource_statistics() -> Dictionary:
	"""
	获取资源使用统计
	@return: 资源统计字典
	"""
	var stats: Dictionary = {
		"total_cached": cached_resources.size(),
		"by_priority": {
			"critical": 0,
			"high": 0,
			"normal": 0,
			"low": 0
		},
		"unused_over_60s": 0
	}
	
	var current_time: float = Time.get_unix_time_from_system()
	
	for path in cached_resources.keys():
		var info: Dictionary = cached_resources[path]
		var priority: ResourcePriority = info["priority"]
		
		match priority:
			ResourcePriority.CRITICAL:
				stats["by_priority"]["critical"] += 1
			ResourcePriority.HIGH:
				stats["by_priority"]["high"] += 1
			ResourcePriority.NORMAL:
				stats["by_priority"]["normal"] += 1
			ResourcePriority.LOW:
				stats["by_priority"]["low"] += 1
		
		if current_time - info["last_used"] > 60:
			stats["unused_over_60s"] += 1
	
	return stats
