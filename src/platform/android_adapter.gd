## Void Hunter - Android平台适配器
## @description: Android平台特定功能的适配处理
## @author: Void Hunter Team
## @version: 1.0.0

extends Node

# =============================================================================
# 信号定义
# =============================================================================

## 返回键按下时触发
signal back_button_pressed()

## 内存压力警告时触发
signal low_memory_warning(level: int)

## 应用进入后台时触发
signal app_paused()

## 应用恢复前台时触发
signal app_resumed()

## 屏幕方向改变时触发
signal screen_orientation_changed(orientation: int)

## 分辨率改变时触发
signal resolution_changed(new_resolution: Vector2i)

## 权限请求结果时触发
signal permission_result(permission: String, granted: bool)

# =============================================================================
# 枚举定义
# =============================================================================

## 内存压力级别
enum MemoryPressure {
	NONE,		## 无压力
	MODERATE,	## 中等压力
	HIGH,		## 高压力
	CRITICAL	## 严重压力
}

## 屏幕方向
enum ScreenOrientation {
	PORTRAIT,			## 竖屏
	PORTRAIT_UPSIDE_DOWN,	## 倒置竖屏
	LANDSCAPE_LEFT,		## 左横屏
	LANDSCAPE_RIGHT,	## 右横屏
	AUTO				## 自动旋转
}

## 安全区域类型
enum SafeAreaType {
	NONE,		## 无安全区域
	NOTCH,		## 刘海屏
	CUTOUT,		## 挖孔屏
	ROUNDED		## 圆角屏
}

# =============================================================================
# 常量定义
# =============================================================================

## 设计分辨率
const DESIGN_RESOLUTION: Vector2i = Vector2i(1280, 720)

## 最小支持分辨率
const MIN_RESOLUTION: Vector2i = Vector2i(640, 360)

## 内存检查间隔
const MEMORY_CHECK_INTERVAL: float = 3.0

## 低内存阈值（MB）
const LOW_MEMORY_THRESHOLD: int = 128

## 严重内存阈值（MB）
const CRITICAL_MEMORY_THRESHOLD: int = 64

# =============================================================================
# 导出变量
# =============================================================================

## 是否启用返回键处理
@export var handle_back_button: bool = true

## 是否启用内存监控
@export var enable_memory_monitoring: bool = true

## 是否启用分辨率自适应
@export var auto_resolution_adapt: bool = true

## 目标帧率（移动端）
@export var target_fps_mobile: int = 60

## 是否启用省电模式
@export var enable_battery_saver: bool = false

## 低内存时自动降低画质
@export var auto_reduce_quality_on_low_memory: bool = true

# =============================================================================
# 公共变量
# =============================================================================

## 当前是否运行在Android平台
var is_android_platform: bool = false

## 当前屏幕分辨率
var current_resolution: Vector2i = Vector2i.ZERO

## 安全区域
var safe_area: Rect2 = Rect2()

## 当前屏幕方向
var current_orientation: ScreenOrientation = ScreenOrientation.LANDSCAPE_LEFT

## 是否处于低内存状态
var is_low_memory: bool = false

## 当前内存压力级别
var memory_pressure_level: MemoryPressure = MemoryPressure.NONE

## 安全区域类型
var safe_area_type: SafeAreaType = SafeAreaType.NONE

## 是否暂停状态
var is_paused: bool = false

# =============================================================================
# 私有变量
# =============================================================================

var _is_initialized: bool = false
var _memory_check_timer: float = 0.0
var _last_memory_usage: int = 0
var _java_class: JavaClassWrapper = null
var _java_object: JavaObject = null

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""
	节点就绪时初始化
	"""
	_initialize_android_adapter()


func _process(delta: float) -> void:
	"""
	每帧更新
	"""
	if not is_android_platform:
		return
	
	# 内存监控
	if enable_memory_monitoring:
		_update_memory_monitoring(delta)


func _notification(what: int) -> void:
	"""
	处理系统通知
	"""
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST:
			_on_back_button_pressed()
		NOTIFICATION_APPLICATION_PAUSED:
			_on_app_paused()
		NOTIFICATION_APPLICATION_RESUMED:
			_on_app_resumed()
		NOTIFICATION_WM_SIZE_CHANGED:
			_on_size_changed()

# =============================================================================
# 公共方法 - 初始化
# =============================================================================

## 初始化Android适配器
func initialize() -> void:
	"""
	手动初始化Android适配器
	"""
	_initialize_android_adapter()


## 检测是否运行在Android平台
func is_android() -> bool:
	"""
	检测是否运行在Android平台
	@return: 是否Android平台
	"""
	return OS.has_feature("android")

# =============================================================================
# 公共方法 - 返回键处理
# =============================================================================

## 设置返回键行为
func set_back_button_enabled(enabled: bool) -> void:
	"""
	设置是否启用返回键处理
	@param enabled: 是否启用
	"""
	handle_back_button = enabled


## 模拟返回键按下
func simulate_back_press() -> void:
	"""
	模拟返回键按下
	"""
	_on_back_button_pressed()

# =============================================================================
# 公共方法 - 内存管理
# =============================================================================

## 获取可用内存
func get_available_memory() -> int:
	"""
	获取可用内存（MB）
	@return: 可用内存
	"""
	if not is_android_platform:
		return 1024  # 返回一个默认值
	
	return _get_android_available_memory()


## 获取总内存
func get_total_memory() -> int:
	"""
	获取总内存（MB）
	@return: 总内存
	"""
	if not is_android_platform:
		return 2048
	
	return _get_android_total_memory()


## 获取内存使用量
func get_memory_usage() -> int:
	"""
	获取当前内存使用量（MB）
	@return: 内存使用量
	"""
	var static_mem: int = Performance.get_monitor(Performance.MEMORY_STATIC) / (1024 * 1024)
	var dynamic_mem: int = Performance.get_monitor(Performance.MEMORY_DYNAMIC) / (1024 * 1024)
	return static_mem + dynamic_mem


## 触发内存清理
func trigger_memory_cleanup() -> void:
	"""
	触发内存清理
	"""
	# 清理资源缓存
	_cleanup_resource_cache()
	
	# 清理对象池
	_cleanup_object_pools()
	
	# 请求GC
	_request_garbage_collection()


## 处理低内存警告
func handle_low_memory(level: MemoryPressure) -> void:
	"""
	处理低内存警告
	@param level: 内存压力级别
	"""
	memory_pressure_level = level
	is_low_memory = level >= MemoryPressure.HIGH
	
	low_memory_warning.emit(level)
	
	if auto_reduce_quality_on_low_memory:
		_apply_memory_saving_measures(level)

# =============================================================================
# 公共方法 - 分辨率适配
# =============================================================================

## 获取屏幕分辨率
func get_screen_resolution() -> Vector2i:
	"""
	获取当前屏幕分辨率
	@return: 屏幕分辨率
	"""
	return Vector2i(DisplayServer.screen_get_size())


## 获取安全区域
func get_safe_area_rect() -> Rect2:
	"""
	获取安全区域矩形
	@return: 安全区域
	"""
	return safe_area


## 获取UI缩放因子
func get_ui_scale_factor() -> float:
	"""
	获取UI缩放因子
	@return: 缩放因子
	"""
	var screen_size: Vector2i = get_screen_resolution()
	var base_scale: float = float(screen_size.y) / float(DESIGN_RESOLUTION.y)
	
	# 考虑安全区域
	var safe_height: float = float(screen_size.y - safe_area.position.y - safe_area.size.y)
	if safe_height > 0:
		base_scale = min(base_scale, safe_height / float(DESIGN_RESOLUTION.y))
	
	return base_scale


## 计算适配后的视口尺寸
func calculate_adapted_viewport() -> Vector2i:
	"""
	计算适配后的视口尺寸
	@return: 视口尺寸
	"""
	var screen_size: Vector2i = get_screen_resolution()
	var screen_aspect: float = float(screen_size.x) / float(screen_size.y)
	var design_aspect: float = float(DESIGN_RESOLUTION.x) / float(DESIGN_RESOLUTION.y)
	
	var adapted_size: Vector2i
	
	if screen_aspect > design_aspect:
		# 屏幕更宽，以高度为基准
		adapted_size.y = DESIGN_RESOLUTION.y
		adapted_size.x = int(DESIGN_RESOLUTION.y * screen_aspect)
	else:
		# 屏幕更高，以宽度为基准
		adapted_size.x = DESIGN_RESOLUTION.x
		adapted_size.y = int(DESIGN_RESOLUTION.x / screen_aspect)
	
	return adapted_size

# =============================================================================
# 公共方法 - 屏幕方向
# =============================================================================

## 设置屏幕方向
func set_screen_orientation(orientation: ScreenOrientation) -> void:
	"""
	设置屏幕方向
	@param orientation: 目标方向
	"""
	if not is_android_platform:
		return
	
	current_orientation = orientation
	
	var mode: int
	match orientation:
		ScreenOrientation.PORTRAIT:
			mode = DisplayServer.SCREEN_PORTRAIT
		ScreenOrientation.PORTRAIT_UPSIDE_DOWN:
			mode = DisplayServer.SCREEN_REVERSE_LANDSCAPE
		ScreenOrientation.LANDSCAPE_LEFT:
			mode = DisplayServer.SCREEN_LANDSCAPE
		ScreenOrientation.LANDSCAPE_RIGHT:
			mode = DisplayServer.SCREEN_REVERSE_LANDSCAPE
		ScreenOrientation.AUTO:
			mode = DisplayServer.SCREEN_SENSOR_LANDSCAPE
	
	DisplayServer.screen_set_orientation(mode)
	screen_orientation_changed.emit(orientation)


## 获取当前屏幕方向
func get_current_orientation() -> ScreenOrientation:
	"""
	获取当前屏幕方向
	@return: 屏幕方向
	"""
	return current_orientation

# =============================================================================
# 公共方法 - 触摸控制
# =============================================================================

## 是否支持多点触控
func supports_multitouch() -> bool:
	"""
	检测是否支持多点触控
	@return: 是否支持
	"""
	if not is_android_platform:
		return false
	
	return DisplayServer.is_touch_available()


## 获取最大触控点数
func get_max_touch_points() -> int:
	"""
	获取最大触控点数
	@return: 触控点数
	"""
	return 5  # Android通常支持5点触控


## 优化触摸响应
func optimize_touch_response() -> void:
	"""
	优化触摸响应设置
	"""
	# 降低输入延迟
	ProjectSettings.set_setting("input/buffering/agile_event_flushing", true)

# =============================================================================
# 公共方法 - 权限管理
# =============================================================================

## 请求权限
func request_permission(permission: String) -> void:
	"""
	请求Android权限
	@param permission: 权限名称
	"""
	if not is_android_platform:
		permission_result.emit(permission, true)
		return
	
	# 使用Godot的权限API
	var permissions: PackedStringArray = [permission]
	OS.request_permissions()


## 检查权限
func check_permission(permission: String) -> bool:
	"""
	检查是否拥有权限
	@param permission: 权限名称
	@return: 是否拥有
	"""
	if not is_android_platform:
		return true
	
	return OS.has_permission(permission)


## 获取已授权权限列表
func get_granted_permissions() -> PackedStringArray:
	"""
	获取已授权的权限列表
	@return: 权限列表
	"""
	if not is_android_platform:
		return []
	
	return OS.get_granted_permissions()

# =============================================================================
# 公共方法 - 性能优化
# =============================================================================

## 设置目标帧率
func set_target_fps(fps: int) -> void:
	"""
	设置目标帧率
	@param fps: 帧率
	"""
	Engine.max_fps = fps


## 启用省电模式
func enable_power_saving(enabled: bool) -> void:
	"""
	启用省电模式
	@param enabled: 是否启用
	"""
	enable_battery_saver = enabled
	
	if enabled:
		# 降低帧率
		set_target_fps(30)
		# 降低画质
		_apply_low_quality_settings()
	else:
		# 恢复正常帧率
		set_target_fps(target_fps_mobile)
		# 恢复画质
		_apply_normal_quality_settings()


## 获取电池状态
func get_battery_status() -> Dictionary:
	"""
	获取电池状态
	@return: 电池状态字典
	"""
	var status: Dictionary = {
		"level": -1,  # -1表示未知
		"charging": false,
		"power_save": false
	}
	
	if not is_android_platform:
		return status
	
	# 尝试获取电池信息
	if OS.has_method("get_battery_level"):
		status["level"] = OS.get_battery_level()
	
	status["power_save"] = OS.is_in_low_processor_usage_mode()
	
	return status

# =============================================================================
# 公共方法 - 震动反馈
# =============================================================================

## 触发震动
func vibrate(duration_ms: int = 50) -> void:
	"""
	触发震动反馈
	@param duration_ms: 震动时长（毫秒）
	"""
	if not is_android_platform:
		return
	
	if check_permission("android.permission.VIBRATE"):
		Input.vibrate_handheld(duration_ms)


## 触发模式震动
func vibrate_pattern(pattern: Array) -> void:
	"""
	触发模式震动
	@param pattern: 震动模式数组 [等待, 震动, 等待, 震动, ...]
	"""
	if not is_android_platform:
		return
	
	# Godot 4.x 不直接支持模式震动，使用简单震动代替
	vibrate(100)

# =============================================================================
# 私有方法 - 初始化
# =============================================================================

func _initialize_android_adapter() -> void:
	"""
	初始化Android适配器
	"""
	if _is_initialized:
		return
	
	_is_initialized = true
	is_android_platform = is_android()
	
	if not is_android_platform:
		print("[AndroidAdapter] 非Android平台，适配器将以兼容模式运行")
		return
	
	print("[AndroidAdapter] 初始化Android适配器...")
	
	# 获取屏幕信息
	current_resolution = get_screen_resolution()
	print("[AndroidAdapter] 屏幕分辨率: %s" % str(current_resolution))
	
	# 检测安全区域
	_detect_safe_area()
	
	# 检测屏幕方向
	_detect_screen_orientation()
	
	# 初始化Java接口
	_init_java_interface()
	
	# 应用移动端优化
	_apply_mobile_optimizations()
	
	# 设置帧率
	set_target_fps(target_fps_mobile)
	
	print("[AndroidAdapter] 初始化完成")


func _init_java_interface() -> void:
	"""
	初始化Java接口
	"""
	# 尝试获取Android Activity
	if OS.has_method("get_native_handle"):
		# 获取Java类包装器
		_java_class = JavaClassWrapper.new()


func _detect_safe_area() -> void:
	"""
	检测安全区域
	"""
	var screen_size: Vector2i = get_screen_resolution()
	
	# 默认安全区域为整个屏幕
	safe_area = Rect2(Vector2.ZERO, Vector2(screen_size))
	
	# 检测刘海/挖孔屏
	# 通过窗口Insets检测
	var window: Window = get_window()
	if window:
		var insets: Dictionary = window.get_content_scale_size()
		# 这里需要更精确的检测逻辑
		# 暂时使用常见的安全区域值
		var top_inset: int = _get_status_bar_height()
		var bottom_inset: int = _get_navigation_bar_height()
		
		safe_area = Rect2(
			Vector2(0, top_inset),
			Vector2(screen_size.x, screen_size.y - top_inset - bottom_inset)
		)
		
		# 判断安全区域类型
		if top_inset > 50:
			safe_area_type = SafeAreaType.NOTCH
		elif bottom_inset > 50:
			safe_area_type = SafeAreaType.ROUNDED
	
	print("[AndroidAdapter] 安全区域: %s, 类型: %s" % [
		str(safe_area),
		SafeAreaType.keys()[safe_area_type]
	])


func _get_status_bar_height() -> int:
	"""
	获取状态栏高度
	"""
	# 常见的状态栏高度（像素）
	return 48


func _get_navigation_bar_height() -> int:
	"""
	获取导航栏高度
	"""
	# 常见的导航栏高度（像素）
	return 0  # 全屏游戏通常隐藏导航栏


func _detect_screen_orientation() -> void:
	"""
	检测屏幕方向
	"""
	var screen_size: Vector2i = get_screen_resolution()
	
	if screen_size.x > screen_size.y:
		current_orientation = ScreenOrientation.LANDSCAPE_LEFT
	else:
		current_orientation = ScreenOrientation.PORTRAIT


func _apply_mobile_optimizations() -> void:
	"""
	应用移动端优化设置
	"""
	# 优化触摸响应
	optimize_touch_response()
	
	# 设置输入缓冲
	ProjectSettings.set_setting("input/buffering/agile_event_flushing", true)
	
	# 优化渲染
	ProjectSettings.set_setting("rendering/renderer/rendering_method", "mobile")

# =============================================================================
# 私有方法 - 内存监控
# =============================================================================

func _update_memory_monitoring(delta: float) -> void:
	"""
	更新内存监控
	"""
	_memory_check_timer += delta
	
	if _memory_check_timer >= MEMORY_CHECK_INTERVAL:
		_memory_check_timer = 0.0
		_check_memory_status()


func _check_memory_status() -> void:
	"""
	检查内存状态
	"""
	var available: int = get_available_memory()
	
	var level: MemoryPressure = MemoryPressure.NONE
	
	if available < CRITICAL_MEMORY_THRESHOLD:
		level = MemoryPressure.CRITICAL
	elif available < LOW_MEMORY_THRESHOLD:
		level = MemoryPressure.HIGH
	elif available < LOW_MEMORY_THRESHOLD * 2:
		level = MemoryPressure.MODERATE
	
	if level != memory_pressure_level:
		if level > MemoryPressure.MODERATE:
			handle_low_memory(level)


func _apply_memory_saving_measures(level: MemoryPressure) -> void:
	"""
	应用内存节省措施
	"""
	match level:
		MemoryPressure.HIGH:
			print("[AndroidAdapter] 应用高级内存节省措施")
			# 清理缓存
			_cleanup_resource_cache()
			# 降低纹理质量
			_reduce_texture_quality()
		
		MemoryPressure.CRITICAL:
			print("[AndroidAdapter] 应用紧急内存节省措施")
			# 清理所有缓存
			_cleanup_resource_cache()
			_cleanup_object_pools()
			# 大幅降低画质
			_apply_low_quality_settings()
			# 请求GC
			_request_garbage_collection()


func _cleanup_resource_cache() -> void:
	"""
	清理资源缓存
	"""
	# 通知资源管理器清理
	if has_node("/root/ResourceManager"):
		var resource_manager: Node = get_node("/root/ResourceManager")
		if resource_manager.has_method("clear_cache"):
			resource_manager.call("clear_cache")


func _cleanup_object_pools() -> void:
	"""
	清理对象池
	"""
	if has_node("/root/ObjectPool"):
		var object_pool: Node = get_node("/root/ObjectPool")
		if object_pool.has_method("shrink_all_pools"):
			object_pool.call("shrink_all_pools")


func _request_garbage_collection() -> void:
	"""
	请求垃圾回收
	"""
	# Godot会自动管理内存，这里只是建议
	if OS.has_method("dump_memory_to_file"):
		pass  # 仅在调试时使用


func _reduce_texture_quality() -> void:
	"""
	降低纹理质量
	"""
	# 通知渲染优化器
	if has_node("/root/RenderOptimizer"):
		var render_optimizer: Node = get_node("/root/RenderOptimizer")
		if render_optimizer.has_method("set_texture_quality"):
			render_optimizer.call("set_texture_quality", 0)  # 最低质量


func _apply_low_quality_settings() -> void:
	"""
	应用低画质设置
	"""
	# 降低粒子数量
	if has_node("/root/RenderOptimizer"):
		var render_optimizer: Node = get_node("/root/RenderOptimizer")
		if render_optimizer.has_method("set_particle_quality"):
			render_optimizer.call("set_particle_quality", 0)


func _apply_normal_quality_settings() -> void:
	"""
	应用正常画质设置
	"""
	if has_node("/root/RenderOptimizer"):
		var render_optimizer: Node = get_node("/root/RenderOptimizer")
		if render_optimizer.has_method("set_particle_quality"):
			render_optimizer.call("set_particle_quality", 2)


func _get_android_available_memory() -> int:
	"""
	获取Android可用内存
	"""
	# 使用Performance监控
	var static_mem: int = Performance.get_monitor(Performance.MEMORY_STATIC) / (1024 * 1024)
	
	# 返回估计值
	return maxi(512 - static_mem, 64)


func _get_android_total_memory() -> int:
	"""
	获取Android总内存
	"""
	# 返回估计值（通常Android设备有2-8GB内存）
	return 2048

# =============================================================================
# 私有方法 - 事件处理
# =============================================================================

func _on_back_button_pressed() -> void:
	"""
	返回键按下处理
	"""
	if not handle_back_button:
		return
	
	print("[AndroidAdapter] 返回键按下")
	back_button_pressed.emit()
	
	# 默认行为：如果游戏暂停则恢复，否则暂停
	if is_paused:
		# 游戏已暂停，恢复游戏
		if has_node("/root/GameManager"):
			var game_manager: Node = get_node("/root/GameManager")
			if game_manager.has_method("resume_game"):
				game_manager.call("resume_game")
	else:
		# 游戏进行中，暂停游戏
		if has_node("/root/GameManager"):
			var game_manager: Node = get_node("/root/GameManager")
			if game_manager.has_method("pause_game"):
				game_manager.call("pause_game")


func _on_app_paused() -> void:
	"""
	应用暂停处理
	"""
	is_paused = true
	print("[AndroidAdapter] 应用进入后台")
	app_paused.emit()
	
	# 保存游戏状态
	if has_node("/root/SaveManager"):
		var save_manager: Node = get_node("/root/SaveManager")
		if save_manager.has_method("auto_save"):
			save_manager.call("auto_save")


func _on_app_resumed() -> void:
	"""
	应用恢复处理
	"""
	is_paused = false
	print("[AndroidAdapter] 应用恢复前台")
	app_resumed.emit()
	
	# 检查内存状态
	_check_memory_status()


func _on_size_changed() -> void:
	"""
	屏幕尺寸变化处理
	"""
	var new_resolution: Vector2i = get_screen_resolution()
	
	if new_resolution != current_resolution:
		current_resolution = new_resolution
		_detect_safe_area()
		_detect_screen_orientation()
		resolution_changed.emit(new_resolution)
		print("[AndroidAdapter] 分辨率变化: %s" % str(new_resolution))

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
		"is_android_platform": is_android_platform,
		"screen_resolution": str(current_resolution),
		"safe_area": str(safe_area),
		"safe_area_type": SafeAreaType.keys()[safe_area_type],
		"screen_orientation": ScreenOrientation.keys()[current_orientation],
		"memory_pressure": MemoryPressure.keys()[memory_pressure_level],
		"is_low_memory": is_low_memory,
		"available_memory_mb": get_available_memory(),
		"memory_usage_mb": get_memory_usage(),
		"battery_status": get_battery_status(),
		"is_paused": is_paused,
		"target_fps": Engine.max_fps
	}
