## Void Hunter - 渲染优化器
## @description: 处理渲染性能优化，包括批处理、视口裁剪、LOD系统和帧率限制
## @author: Void Hunter Team
## @version: 1.0.0

extends Node

# =============================================================================
# 信号定义
# =============================================================================

## 帧率改变时触发
signal fps_limit_changed(new_limit: int)

## 画质等级改变时触发
signal quality_level_changed(new_level: QualityLevel)

## 对象被裁剪时触发
signal object_culled(object: Node)

## LOD等级改变时触发
signal lod_changed(object: Node, lod_level: int)

## 性能警告时触发
signal performance_warning(metric: String, value: float)

# =============================================================================
# 枚举定义
# =============================================================================

## 画质等级
enum QualityLevel {
	LOW,		## 低画质
	MEDIUM,		## 中画质
	HIGH,		## 高画质
	ULTRA		## 超高画质
}

## LOD等级
enum LODLevel {
	LOD_0,		## 最高细节（近距离）
	LOD_1,		## 中等细节
	LOD_2,		## 低细节
	LOD_3,		## 最低细节（远距离）
	CULLED		## 被裁剪
}

## 性能指标
enum PerformanceMetric {
	FPS,
	FRAME_TIME,
	DRAW_CALLS,
	MEMORY_USAGE,
	OBJECT_COUNT
}

# =============================================================================
# 常量定义
# =============================================================================

## 默认帧率限制
const DEFAULT_FPS_LIMIT: int = 60

## LOD距离阈值
const LOD_DISTANCES: Array[float] = [200.0, 400.0, 600.0, 800.0]  # LOD 0-3的距离

## 视口裁剪边距
const CULL_MARGIN: float = 100.0

## 性能检查间隔
const PERFORMANCE_CHECK_INTERVAL: float = 1.0

## 低帧率阈值
const LOW_FPS_THRESHOLD: float = 30.0

## 高帧时间阈值（毫秒）
const HIGH_FRAME_TIME_THRESHOLD: float = 33.0

## 画质配置
const QUALITY_CONFIGS: Dictionary = {
	QualityLevel.LOW: {
		"particle_ratio": 0.3,
		"shadow_enabled": false,
		"msaa": Viewport.MSAA_DISABLED,
		"max_particles": 100,
		"lod_bias": 0.5,
		"texture_filter": CanvasItem.TEXTURE_FILTER_NEAREST
	},
	QualityLevel.MEDIUM: {
		"particle_ratio": 0.5,
		"shadow_enabled": false,
		"msaa": Viewport.MSAA_2X,
		"max_particles": 200,
		"lod_bias": 0.75,
		"texture_filter": CanvasItem.TEXTURE_FILTER_LINEAR
	},
	QualityLevel.HIGH: {
		"particle_ratio": 0.75,
		"shadow_enabled": true,
		"msaa": Viewport.MSAA_4X,
		"max_particles": 400,
		"lod_bias": 1.0,
		"texture_filter": CanvasItem.TEXTURE_FILTER_LINEAR
	},
	QualityLevel.ULTRA: {
		"particle_ratio": 1.0,
		"shadow_enabled": true,
		"msaa": Viewport.MSAA_8X,
		"max_particles": 800,
		"lod_bias": 1.5,
		"texture_filter": CanvasItem.TEXTURE_FILTER_LINEAR_MIPMAP
	}
}

# =============================================================================
# 导出变量
# =============================================================================

## 当前画质等级
@export var quality_level: QualityLevel = QualityLevel.HIGH:
	set(value):
		if quality_level != value:
			quality_level = value
			_apply_quality_settings()

## 帧率限制
@export var fps_limit: int = DEFAULT_FPS_LIMIT:
	set(value):
		fps_limit = clamp(value, 30, 144)
		_apply_fps_limit()

## 是否启用视口裁剪
@export var enable_viewport_culling: bool = true

## 是否启用LOD系统
@export var enable_lod_system: bool = true

## 是否启用动态画质调整
@export var enable_dynamic_quality: bool = true

## 是否启用性能监控
@export var enable_performance_monitoring: bool = true

## 自动降低画质的帧率阈值
@export var auto_quality_down_threshold: float = 30.0

## 自动提升画质的帧率阈值
@export var auto_quality_up_threshold: float = 55.0

## 最大粒子数量
@export var max_particles: int = 400

# =============================================================================
# 公共变量
# =============================================================================

## 当前帧率
var current_fps: float = 60.0

## 当前帧时间（毫秒）
var current_frame_time: float = 16.67

## 当前绘制调用数
var current_draw_calls: int = 0

## 裁剪的对象数量
var culled_objects_count: int = 0

## 是否处于低性能模式
var is_low_performance_mode: bool = false

## 性能统计
var performance_stats: Dictionary = {}

# =============================================================================
# 私有变量
# =============================================================================

var _is_initialized: bool = false
var _performance_check_timer: float = 0.0
var _frame_count: int = 0
var _fps_accumulator: float = 0.0
var _lod_objects: Array[Dictionary] = []
var _culling_camera: Camera2D = null
var _viewport_rect: Rect2 = Rect2()
var _auto_quality_cooldown: float = 0.0
var _consecutive_low_fps: int = 0
var _consecutive_high_fps: int = 0

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""
	节点就绪时初始化
	"""
	_initialize_render_optimizer()


func _process(delta: float) -> void:
	"""
	每帧更新
	"""
	# 更新帧率统计
	_update_fps_stats(delta)
	
	# 性能监控
	if enable_performance_monitoring:
		_performance_check_timer += delta
		if _performance_check_timer >= PERFORMANCE_CHECK_INTERVAL:
			_performance_check_timer = 0.0
			_check_performance()
	
	# 自动画质调整冷却
	if _auto_quality_cooldown > 0:
		_auto_quality_cooldown -= delta

# =============================================================================
# 公共方法 - 初始化
# =============================================================================

## 初始化渲染优化器
func initialize() -> void:
	"""
	手动初始化渲染优化器
	"""
	_initialize_render_optimizer()

# =============================================================================
# 公共方法 - 帧率控制
# =============================================================================

## 设置帧率限制
func set_fps_limit(limit: int) -> void:
	"""
	设置帧率限制
	@param limit: 帧率限制（30-144）
	"""
	fps_limit = clamp(limit, 30, 144)
	_apply_fps_limit()


## 获取当前帧率
func get_current_fps() -> float:
	"""
	获取当前帧率
	@return: 帧率
	"""
	return current_fps


## 获取平均帧时间
func get_average_frame_time() -> float:
	"""
	获取平均帧时间（毫秒）
	@return: 帧时间
	"""
	return current_frame_time

# =============================================================================
# 公共方法 - 画质控制
# =============================================================================

## 设置画质等级
func set_quality_level(level: QualityLevel) -> void:
	"""
	设置画质等级
	@param level: 画质等级
	"""
	quality_level = level


## 获取当前画质配置
func get_quality_config() -> Dictionary:
	"""
	获取当前画质配置
	@return: 配置字典
	"""
	return QUALITY_CONFIGS.get(quality_level, QUALITY_CONFIGS[QualityLevel.MEDIUM])


## 启用低画质模式
func enable_low_quality_mode(enabled: bool) -> void:
	"""
	启用低画质模式
	@param enabled: 是否启用
	"""
	is_low_performance_mode = enabled
	
	if enabled:
		set_quality_level(QualityLevel.LOW)
		max_particles = 100
	else:
		set_quality_level(QualityLevel.HIGH)
		max_particles = 400


## 获取推荐的画质等级
func get_recommended_quality() -> QualityLevel:
	"""
	根据系统性能获取推荐的画质等级
	@return: 推荐画质
	"""
	# 基于设备类型判断
	if OS.has_feature("web"):
		return QualityLevel.MEDIUM
	elif OS.has_feature("mobile"):
		return QualityLevel.MEDIUM
	else:
		# 桌面平台，检查内存
		var total_memory: int = OS.get_static_memory_usage()
		if total_memory > 500 * 1024 * 1024:  # 500MB
			return QualityLevel.HIGH
		else:
			return QualityLevel.MEDIUM

# =============================================================================
# 公共方法 - 视口裁剪
# =============================================================================

## 设置裁剪摄像机
func set_culling_camera(camera: Camera2D) -> void:
	"""
	设置用于视口裁剪的摄像机
	@param camera: 摄像机
	"""
	_culling_camera = camera


## 检查对象是否在视口内
func is_in_viewport(global_position: Vector2, margin: float = CULL_MARGIN) -> bool:
	"""
	检查位置是否在视口内
	@param global_position: 全局坐标
	@param margin: 边距
	@return: 是否可见
	"""
	_update_viewport_rect()
	
	var expanded_rect: Rect2 = _viewport_rect.grow(margin)
	return expanded_rect.has_point(global_position)


## 检查矩形是否在视口内
func is_rect_in_viewport(rect: Rect2, margin: float = CULL_MARGIN) -> bool:
	"""
	检查矩形区域是否与视口相交
	@param rect: 矩形区域
	@param margin: 边距
	@return: 是否可见
	"""
	_update_viewport_rect()
	
	var expanded_rect: Rect2 = _viewport_rect.grow(margin)
	return expanded_rect.intersects(rect)


## 对象视口裁剪
func cull_object(obj: Node2D) -> bool:
	"""
	检查对象是否应该被裁剪
	@param obj: 对象
	@return: true表示应该裁剪（不可见）
	"""
	if not enable_viewport_culling:
		return false
	
	if not is_instance_valid(obj):
		return true
	
	var pos: Vector2 = obj.global_position
	
	if not is_in_viewport(pos):
		object_culled.emit(obj)
		culled_objects_count += 1
		return true
	
	return false


## 批量视口裁剪检查
func cull_objects(objects: Array[Node2D]) -> Array[Node2D]:
	"""
	批量检查对象裁剪，返回可见对象列表
	@param objects: 对象数组
	@return: 可见对象数组
	"""
	var visible_objects: Array[Node2D] = []
	culled_objects_count = 0
	
	for obj in objects:
		if not cull_object(obj):
			visible_objects.append(obj)
	
	return visible_objects

# =============================================================================
# 公共方法 - LOD系统
# =============================================================================

## 注册LOD对象
func register_lod_object(obj: Node2D, lod_distances: Array[float] = LOD_DISTANCES) -> void:
	"""
	注册需要LOD处理的对象
	@param obj: 对象
	@param lod_distances: LOD距离数组
	"""
	# 检查是否已注册
	for lod_info in _lod_objects:
		if lod_info["object"] == obj:
			return
	
	_lod_objects.append({
		"object": obj,
		"lod_distances": lod_distances,
		"current_lod": LODLevel.LOD_0
	})


## 注销LOD对象
func unregister_lod_object(obj: Node2D) -> void:
	"""
	注销LOD对象
	@param obj: 对象
	"""
	for i in range(_lod_objects.size() - 1, -1, -1):
		if _lod_objects[i]["object"] == obj:
			_lod_objects.remove_at(i)
			break


## 计算LOD等级
func calculate_lod_level(distance: float, config: Dictionary = {}) -> LODLevel:
	"""
	根据距离计算LOD等级
	@param distance: 距离
	@param config: LOD配置
	@return: LOD等级
	"""
	var distances: Array[float] = config.get("lod_distances", LOD_DISTANCES)
	var bias: float = get_quality_config().get("lod_bias", 1.0)
	
	for i in range(distances.size()):
		if distance < distances[i] * bias:
			return i as LODLevel
	
	return LODLevel.CULLED


## 更新所有LOD对象
func update_lod_objects(reference_position: Vector2) -> void:
	"""
	更新所有LOD对象的等级
	@param reference_position: 参考位置（通常是玩家或摄像机位置）
	"""
	if not enable_lod_system:
		return
	
	for lod_info in _lod_objects:
		var obj: Node2D = lod_info["object"]
		
		if not is_instance_valid(obj):
			continue
		
		var distance: float = reference_position.distance_to(obj.global_position)
		var new_lod: LODLevel = calculate_lod_level(distance, lod_info)
		var current_lod: LODLevel = lod_info["current_lod"]
		
		if new_lod != current_lod:
			lod_info["current_lod"] = new_lod
			_apply_lod_to_object(obj, new_lod)
			lod_changed.emit(obj, new_lod)


## 获取对象的当前LOD等级
func get_object_lod(obj: Node2D) -> LODLevel:
	"""
	获取对象的当前LOD等级
	@param obj: 对象
	@return: LOD等级
	"""
	for lod_info in _lod_objects:
		if lod_info["object"] == obj:
			return lod_info["current_lod"]
	return LODLevel.LOD_0

# =============================================================================
# 公共方法 - 粒子控制
# =============================================================================

## 设置最大粒子数量
func set_max_particles(max_count: int) -> void:
	"""
	设置最大粒子数量
	@param max_count: 最大数量
	"""
	max_particles = max_count


## 限制粒子系统
func limit_particle_systems(particle_systems: Array[Node]) -> int:
	"""
	限制粒子系统的总粒子数
	@param particle_systems: 粒子系统数组
	@return: 实际使用的粒子数
	"""
	var ratio: float = get_quality_config().get("particle_ratio", 1.0)
	var actual_max: int = int(max_particles * ratio)
	var current_count: int = 0
	
	for particle in particle_systems:
		if current_count >= actual_max:
			# 超过限制，禁用粒子
			if "emitting" in particle:
				particle.emitting = false
		else:
			# 计算当前粒子数
			if "amount" in particle:
				current_count += particle.amount
	
	return current_count

# =============================================================================
# 公共方法 - 性能监控
# =============================================================================

## 获取性能报告
func get_performance_report() -> Dictionary:
	"""
	获取性能报告
	@return: 性能报告字典
	"""
	return {
		"fps": current_fps,
		"frame_time_ms": current_frame_time,
		"quality_level": QualityLevel.keys()[quality_level],
		"culled_objects": culled_objects_count,
		"lod_objects": _lod_objects.size(),
		"max_particles": max_particles,
		"low_performance_mode": is_low_performance_mode,
		"stats": performance_stats.duplicate()
	}


## 检查性能瓶颈
func check_performance_bottleneck() -> String:
	"""
	检查性能瓶颈
	@return: 瓶颈描述
	"""
	if current_fps < LOW_FPS_THRESHOLD:
		if current_frame_time > HIGH_FRAME_TIME_THRESHOLD:
			return "GPU渲染瓶颈"
		else:
			return "CPU逻辑瓶颈"
	
	return "无瓶颈"

# =============================================================================
# 私有方法 - 初始化
# =============================================================================

func _initialize_render_optimizer() -> void:
	"""
	初始化渲染优化器
	"""
	if _is_initialized:
		return
	
	_is_initialized = true
	
	# 应用初始设置
	_apply_quality_settings()
	_apply_fps_limit()
	
	# 初始化性能统计
	performance_stats = {
		"min_fps": 60.0,
		"max_fps": 60.0,
		"avg_fps": 60.0,
		"fps_samples": []
	}
	
	# 获取推荐画质
	if enable_dynamic_quality:
		var recommended: QualityLevel = get_recommended_quality()
		if recommended != quality_level:
			quality_level = recommended
	
	print("[RenderOptimizer] 初始化完成 - 画质: %s, 帧率限制: %d" % [
		QualityLevel.keys()[quality_level], fps_limit
	])

# =============================================================================
# 私有方法 - 帧率统计
# =============================================================================

func _update_fps_stats(delta: float) -> void:
	"""
	更新帧率统计
	@param delta: 帧间隔
	"""
	_frame_count += 1
	_fps_accumulator += delta
	
	# 每秒更新一次
	if _fps_accumulator >= 1.0:
		current_fps = float(_frame_count) / _fps_accumulator
		current_frame_time = 1000.0 / current_fps
		_frame_count = 0
		_fps_accumulator = 0.0
		
		# 更新统计
		_update_performance_stats()

# =============================================================================
# 私有方法 - 性能监控
# =============================================================================

func _update_performance_stats() -> void:
	"""
	更新性能统计
	"""
	performance_stats["min_fps"] = min(performance_stats.get("min_fps", 60.0), current_fps)
	performance_stats["max_fps"] = max(performance_stats.get("max_fps", 60.0), current_fps)
	
	var samples: Array = performance_stats.get("fps_samples", [])
	samples.append(current_fps)
	
	# 保留最近60个样本
	if samples.size() > 60:
		samples.pop_front()
	
	# 计算平均值
	var sum: float = 0.0
	for sample in samples:
		sum += sample
	performance_stats["avg_fps"] = sum / float(samples.size())
	performance_stats["fps_samples"] = samples


func _check_performance() -> void:
	"""
	检查性能状态
	"""
	# 检查低帧率警告
	if current_fps < LOW_FPS_THRESHOLD:
		performance_warning.emit("fps", current_fps)
	
	# 动态画质调整
	if enable_dynamic_quality and _auto_quality_cooldown <= 0:
		_check_auto_quality_adjustment()


func _check_auto_quality_adjustment() -> void:
	"""
	检查是否需要自动调整画质
	"""
	# 低帧率检测
	if current_fps < auto_quality_down_threshold:
		_consecutive_low_fps += 1
		_consecutive_high_fps = 0
		
		# 连续3次低帧率，降低画质
		if _consecutive_low_fps >= 3 and quality_level > QualityLevel.LOW:
			_decrease_quality()
			_consecutive_low_fps = 0
			_auto_quality_cooldown = 10.0  # 10秒冷却
	
	# 高帧率检测
	elif current_fps > auto_quality_up_threshold:
		_consecutive_high_fps += 1
		_consecutive_low_fps = 0
		
		# 连续5次高帧率，提升画质
		if _consecutive_high_fps >= 5 and quality_level < QualityLevel.HIGH:
			_increase_quality()
			_consecutive_high_fps = 0
			_auto_quality_cooldown = 15.0  # 15秒冷却
	else:
		_consecutive_low_fps = 0
		_consecutive_high_fps = 0


func _decrease_quality() -> void:
	"""
	降低画质
	"""
	if quality_level > QualityLevel.LOW:
		quality_level -= 1
		print("[RenderOptimizer] 自动降低画质至: %s" % QualityLevel.keys()[quality_level])


func _increase_quality() -> void:
	"""
	提升画质
	"""
	if quality_level < QualityLevel.HIGH:
		quality_level += 1
		print("[RenderOptimizer] 自动提升画质至: %s" % QualityLevel.keys()[quality_level])

# =============================================================================
# 私有方法 - 设置应用
# =============================================================================

func _apply_fps_limit() -> void:
	"""
	应用帧率限制
	"""
	Engine.max_fps = fps_limit
	fps_limit_changed.emit(fps_limit)


func _apply_quality_settings() -> void:
	"""
	应用画质设置
	"""
	var config: Dictionary = get_quality_config()
	
	# 应用粒子比例
	max_particles = config.get("max_particles", 400)
	
	# 应用MSAA
	var viewport: Viewport = get_viewport()
	if viewport:
		viewport.msaa_2d = config.get("msaa", Viewport.MSAA_DISABLED)
	
	# 通知质量变化
	quality_level_changed.emit(quality_level)
	
	if _is_initialized:
		print("[RenderOptimizer] 应用画质设置: %s" % QualityLevel.keys()[quality_level])


func _apply_lod_to_object(obj: Node2D, lod_level: LODLevel) -> void:
	"""
	应用LOD到对象
	@param obj: 对象
	@param lod_level: LOD等级
	"""
	match lod_level:
		LODLevel.CULLED:
			# 完全隐藏
			obj.visible = false
		LODLevel.LOD_3:
			# 最低细节
			obj.visible = true
			if obj.has_method("set_lod"):
				obj.call("set_lod", 3)
		LODLevel.LOD_2:
			# 低细节
			obj.visible = true
			if obj.has_method("set_lod"):
				obj.call("set_lod", 2)
		LODLevel.LOD_1:
			# 中等细节
			obj.visible = true
			if obj.has_method("set_lod"):
				obj.call("set_lod", 1)
		LODLevel.LOD_0:
			# 最高细节
			obj.visible = true
			if obj.has_method("set_lod"):
				obj.call("set_lod", 0)

# =============================================================================
# 私有方法 - 视口计算
# =============================================================================

func _update_viewport_rect() -> void:
	"""
	更新视口矩形
	"""
	var viewport: Viewport = get_viewport()
	if viewport:
		var size: Vector2 = viewport.get_visible_rect().size
		
		if _culling_camera:
			var camera_pos: Vector2 = _culling_camera.global_position
			_viewport_rect = Rect2(
				camera_pos - size / 2,
				size
			)
		else:
			_viewport_rect = Rect2(Vector2.ZERO, size)

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
		"quality_level": QualityLevel.keys()[quality_level],
		"fps_limit": fps_limit,
		"current_fps": current_fps,
		"frame_time_ms": current_frame_time,
		"culled_objects": culled_objects_count,
		"lod_objects_count": _lod_objects.size(),
		"max_particles": max_particles,
		"viewport_culling_enabled": enable_viewport_culling,
		"lod_system_enabled": enable_lod_system,
		"dynamic_quality_enabled": enable_dynamic_quality,
		"low_performance_mode": is_low_performance_mode,
		"bottleneck": check_performance_bottleneck()
	}
