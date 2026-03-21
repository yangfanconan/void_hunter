## Void Hunter - WebGL平台适配器
## @description: WebGL/Web平台特定功能的适配处理
## @author: Void Hunter Team
## @version: 1.0.0

extends Node

# =============================================================================
# 信号定义
# =============================================================================

## 全屏状态改变时触发
signal fullscreen_state_changed(is_fullscreen: bool)

## 窗口大小改变时触发
signal window_size_changed(new_size: Vector2i)

## 浏览器可见性改变时触发
signal visibility_changed(is_visible: bool)

## WebGL上下文丢失时触发
signal webgl_context_lost()

## WebGL上下文恢复时触发
signal webgl_context_restored()

## 内存警告时触发
signal memory_warning(memory_level: int)

# =============================================================================
# 枚举定义
# =============================================================================

## 内存警告级别
enum MemoryLevel {
	NORMAL,		## 正常
	WARNING,	## 警告
	CRITICAL	## 严重
}

# =============================================================================
# 常量定义
# =============================================================================

## 最小窗口尺寸
const MIN_WINDOW_SIZE: Vector2i = Vector2i(640, 360)

## 设计分辨率
const DESIGN_RESOLUTION: Vector2i = Vector2i(1280, 720)

## 内存检查间隔（秒）
const MEMORY_CHECK_INTERVAL: float = 5.0

## 内存警告阈值（MB）
const MEMORY_WARNING_THRESHOLD: int = 256

## 内存严重阈值（MB）
const MEMORY_CRITICAL_THRESHOLD: int = 128

# =============================================================================
# 导出变量
# =============================================================================

## 是否启用自动全屏
@export var auto_fullscreen_on_mobile: bool = true

## 是否启用窗口自适应
@export var enable_window_resize: bool = true

## 是否保持宽高比
@export var maintain_aspect_ratio: bool = true

## 目标宽高比（16:9）
@export var target_aspect_ratio: float = 16.0 / 9.0

## 是否启用触摸事件优化
@export var optimize_touch_events: bool = true

## 是否启用内存监控
@export var enable_memory_monitoring: bool = true

# =============================================================================
# 公共变量
# =============================================================================

## 当前是否运行在WebGL环境
var is_web_platform: bool = false

## 当前是否全屏
var is_fullscreen: bool = false

## 当前窗口大小
var current_window_size: Vector2i = Vector2i.ZERO

## 是否为移动端浏览器
var is_mobile_browser: bool = false

## 浏览器可见性
var is_browser_visible: bool = true

## 当前缩放因子
var scale_factor: float = 1.0

## 安全区域偏移
var safe_area_margins: Dictionary = {"top": 0, "bottom": 0, "left": 0, "right": 0}

# =============================================================================
# 私有变量
# =============================================================================

var _is_initialized: bool = false
var _memory_check_timer: float = 0.0
var _last_canvas_size: Vector2i = Vector2i.ZERO
var _java_script_interface: JavaScriptObject = null

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""
	节点就绪时初始化
	"""
	_initialize_web_adapter()


func _process(delta: float) -> void:
	"""
	每帧更新
	"""
	if not is_web_platform:
		return
	
	# 检查窗口大小变化
	if enable_window_resize:
		_check_window_resize()
	
	# 内存监控
	if enable_memory_monitoring:
		_update_memory_monitoring(delta)

# =============================================================================
# 公共方法 - 初始化
# =============================================================================

## 初始化Web适配器
func initialize() -> void:
	"""
	手动初始化Web适配器
	"""
	_initialize_web_adapter()


## 检测是否运行在Web平台
func is_web() -> bool:
	"""
	检测是否运行在Web平台
	@return: 是否Web平台
	"""
	return OS.has_feature("web")

# =============================================================================
# 公共方法 - 全屏控制
# =============================================================================

## 请求进入全屏
func request_fullscreen() -> bool:
	"""
	请求进入全屏模式
	@return: 是否成功
	"""
	if not is_web_platform:
		return false
	
	if is_fullscreen:
		return true
	
	# 通过JavaScript API请求全屏
	var success: bool = _js_request_fullscreen()
	if success:
		is_fullscreen = true
		fullscreen_state_changed.emit(true)
	
	return success


## 退出全屏
func exit_fullscreen() -> bool:
	"""
	退出全屏模式
	@return: 是否成功
	"""
	if not is_web_platform:
		return false
	
	if not is_fullscreen:
		return true
	
	var success: bool = _js_exit_fullscreen()
	if success:
		is_fullscreen = false
		fullscreen_state_changed.emit(false)
	
	return success


## 切换全屏状态
func toggle_fullscreen() -> void:
	"""
	切换全屏状态
	"""
	if is_fullscreen:
		exit_fullscreen()
	else:
		request_fullscreen()

# =============================================================================
# 公共方法 - 窗口控制
# =============================================================================

## 获取当前窗口尺寸
func get_window_size() -> Vector2i:
	"""
	获取当前窗口尺寸
	@return: 窗口尺寸
	"""
	if is_web_platform:
		return _js_get_window_size()
	return Vector2i(DisplayServer.window_get_size())


## 获取Canvas尺寸
func get_canvas_size() -> Vector2i:
	"""
	获取Canvas元素尺寸
	@return: Canvas尺寸
	"""
	if is_web_platform:
		return _js_get_canvas_size()
	return get_window_size()


## 设置Canvas尺寸
func set_canvas_size(size: Vector2i) -> void:
	"""
	设置Canvas元素尺寸
	@param size: 目标尺寸
	"""
	if not is_web_platform:
		return
	
	_js_set_canvas_size(size)


## 获取缩放因子
func get_scale_factor() -> float:
	"""
	获取当前缩放因子
	@return: 缩放因子
	"""
	return scale_factor


## 计算适配后的尺寸
func calculate_fitted_size(window_size: Vector2i) -> Vector2i:
	"""
	计算保持宽高比后的适配尺寸
	@param window_size: 窗口尺寸
	@return: 适配后的尺寸
	"""
	if not maintain_aspect_ratio:
		return window_size
	
	var window_aspect: float = float(window_size.x) / float(window_size.y)
	
	if window_aspect > target_aspect_ratio:
		# 窗口更宽，以高度为基准
		var fitted_width: int = int(window_size.y * target_aspect_ratio)
		return Vector2i(fitted_width, window_size.y)
	else:
		# 窗口更高，以宽度为基准
		var fitted_height: int = int(window_size.x / target_aspect_ratio)
		return Vector2i(window_size.x, fitted_height)

# =============================================================================
# 公共方法 - 触摸支持
# =============================================================================

## 是否支持触摸
func has_touch_support() -> bool:
	"""
	检测是否支持触摸
	@return: 是否支持
	"""
	if not is_web_platform:
		return false
	
	return _js_has_touch_support()


## 禁用浏览器默认触摸行为
func disable_default_touch_behavior() -> void:
	"""
	禁用浏览器默认的触摸行为（如缩放、滚动）
	"""
	if not is_web_platform:
		return
	
	_js_disable_touch_defaults()


## 启用浏览器默认触摸行为
func enable_default_touch_behavior() -> void:
	"""
	启用浏览器默认的触摸行为
	"""
	if not is_web_platform:
		return
	
	_js_enable_touch_defaults()

# =============================================================================
# 公共方法 - 移动端浏览器
# =============================================================================

## 检测是否为移动端浏览器
func detect_mobile_browser() -> bool:
	"""
	检测是否为移动端浏览器
	@return: 是否移动端
	"""
	if not is_web_platform:
		return false
	
	return _js_is_mobile_browser()


## 获取设备像素比
func get_device_pixel_ratio() -> float:
	"""
	获取设备像素比（用于高DPI支持）
	@return: 设备像素比
	"""
	if not is_web_platform:
		return 1.0
	
	return _js_get_device_pixel_ratio()


## 获取安全区域
func get_safe_area() -> Dictionary:
	"""
	获取安全区域（用于刘海屏等）
	@return: 安全区域边距
	"""
	if not is_web_platform:
		return {"top": 0, "bottom": 0, "left": 0, "right": 0}
	
	return _js_get_safe_area()

# =============================================================================
# 公共方法 - WebGL优化
# =============================================================================

## 获取WebGL内存使用
func get_webgl_memory_usage() -> int:
	"""
	获取WebGL内存使用量（近似值，单位MB）
	@return: 内存使用量
	"""
	if not is_web_platform:
		return 0
	
	return _js_get_webgl_memory()


## 强制垃圾回收（如果可用）
func force_garbage_collect() -> void:
	"""
	尝试强制执行垃圾回收
	"""
	if not is_web_platform:
		return
	
	_js_force_gc()


## 设置WebGL上下文丢失处理
func setup_context_loss_handling() -> void:
	"""
	设置WebGL上下文丢失的处理
	"""
	if not is_web_platform:
		return
	
	_js_setup_context_loss(_on_webgl_context_lost, _on_webgl_context_restored)

# =============================================================================
# 公共方法 - 性能优化
# =============================================================================

## 优化移动端性能
func optimize_for_mobile() -> void:
	"""
	应用移动端性能优化设置
	"""
	if not is_mobile_browser:
		return
	
	# 降低渲染分辨率
	_set_render_scale(0.75)
	
	# 通知其他系统进行优化
	_notify_low_performance_mode()


## 恢复默认性能设置
func restore_default_performance() -> void:
	"""
	恢复默认性能设置
	"""
	_set_render_scale(1.0)


## 设置渲染缩放
func _set_render_scale(scale: float) -> void:
	"""
	设置渲染缩放比例
	@param scale: 缩放比例（0.5-1.0）
	"""
	scale = clamp(scale, 0.5, 1.0)
	
	# 更新视口缩放
	var window_size: Vector2i = get_window_size()
	var scaled_size: Vector2i = Vector2i(
		int(window_size.x * scale),
		int(window_size.y * scale)
	)
	
	get_viewport().set_size(scaled_size)

# =============================================================================
# 私有方法 - 初始化
# =============================================================================

func _initialize_web_adapter() -> void:
	"""
	初始化Web适配器
	"""
	if _is_initialized:
		return
	
	_is_initialized = true
	is_web_platform = is_web()
	
	if not is_web_platform:
		print("[WebAdapter] 非Web平台，适配器将以兼容模式运行")
		return
	
	print("[WebAdapter] 初始化WebGL适配器...")
	
	# 检测移动端
	is_mobile_browser = detect_mobile_browser()
	print("[WebAdapter] 移动端浏览器: %s" % ("是" if is_mobile_browser else "否"))
	
	# 获取初始窗口大小
	current_window_size = get_window_size()
	_last_canvas_size = get_canvas_size()
	
	# 获取设备像素比
	scale_factor = get_device_pixel_ratio()
	print("[WebAdapter] 设备像素比: %.2f" % scale_factor)
	
	# 获取安全区域
	safe_area_margins = get_safe_area()
	
	# 设置触摸优化
	if optimize_touch_events and has_touch_support():
		disable_default_touch_behavior()
	
	# 设置WebGL上下文丢失处理
	setup_context_loss_handling()
	
	# 移动端自动全屏
	if is_mobile_browser and auto_fullscreen_on_mobile:
		# 延迟请求全屏，等待用户交互
		await get_tree().create_timer(0.5).timeout
	
	# 设置可见性监听
	_setup_visibility_listener()
	
	print("[WebAdapter] 初始化完成")


func _setup_visibility_listener() -> void:
	"""
	设置浏览器可见性监听
	"""
	if not is_web_platform:
		return
	
	# 注册JavaScript回调
	_js_setup_visibility_listener(_on_visibility_change)

# =============================================================================
# 私有方法 - 窗口监控
# =============================================================================

func _check_window_resize() -> void:
	"""
	检查窗口大小变化
	"""
	var new_size: Vector2i = get_window_size()
	
	if new_size != current_window_size:
		current_window_size = new_size
		_handle_window_resize(new_size)


func _handle_window_resize(new_size: Vector2i) -> void:
	"""
	处理窗口大小变化
	@param new_size: 新的窗口尺寸
	"""
	# 确保不小于最小尺寸
	new_size.x = maxi(new_size.x, MIN_WINDOW_SIZE.x)
	new_size.y = maxi(new_size.y, MIN_WINDOW_SIZE.y)
	
	# 计算适配后的尺寸
	var fitted_size: Vector2i = calculate_fitted_size(new_size)
	
	# 更新视口
	var viewport: Viewport = get_viewport()
	if viewport:
		# 更新拉伸模式
		_update_stretch_mode(fitted_size)
	
	window_size_changed.emit(new_size)
	
	if OS.is_debug_build():
		print("[WebAdapter] 窗口大小变化: %s, 适配后: %s" % [str(new_size), str(fitted_size)])


func _update_stretch_mode(target_size: Vector2i) -> void:
	"""
	更新拉伸模式
	@param target_size: 目标尺寸
	"""
	# 通过项目设置更新拉伸
	var scale: Vector2 = Vector2(
		float(current_window_size.x) / float(DESIGN_RESOLUTION.x),
		float(current_window_size.y) / float(DESIGN_RESOLUTION.y)
	)
	
	# 保持宽高比的缩放
	var uniform_scale: float = min(scale.x, scale.y)
	get_tree().root.content_scale_factor = uniform_scale

# =============================================================================
# 私有方法 - 内存监控
# =============================================================================

func _update_memory_monitoring(delta: float) -> void:
	"""
	更新内存监控
	@param delta: 帧间隔
	"""
	_memory_check_timer += delta
	
	if _memory_check_timer >= MEMORY_CHECK_INTERVAL:
		_memory_check_timer = 0.0
		_check_memory_status()


func _check_memory_status() -> void:
	"""
	检查内存状态
	"""
	var memory_usage: int = get_webgl_memory_usage()
	
	var level: MemoryLevel = MemoryLevel.NORMAL
	
	if memory_usage < MEMORY_CRITICAL_THRESHOLD:
		level = MemoryLevel.CRITICAL
	elif memory_usage < MEMORY_WARNING_THRESHOLD:
		level = MemoryLevel.WARNING
	
	if level != MemoryLevel.NORMAL:
		memory_warning.emit(level)
		_handle_memory_warning(level)


func _handle_memory_warning(level: MemoryLevel) -> void:
	"""
	处理内存警告
	@param level: 警告级别
	"""
	match level:
		MemoryLevel.WARNING:
			print("[WebAdapter] 内存警告: 建议释放资源")
			# 请求清理缓存
			_request_cache_cleanup()
		
		MemoryLevel.CRITICAL:
			print("[WebAdapter] 内存严重: 执行紧急清理")
			# 紧急清理
			_request_emergency_cleanup()
			# 强制GC
			force_garbage_collect()


func _request_cache_cleanup() -> void:
	"""
	请求清理缓存
	"""
	# 通知资源管理器清理缓存
	if has_node("/root/ResourceManager"):
		var resource_manager: Node = get_node("/root/ResourceManager")
		if resource_manager.has_method("clear_unused_cache"):
			resource_manager.clear_unused_cache()


func _request_emergency_cleanup() -> void:
	"""
	请求紧急清理
	"""
	# 清理对象池
	if has_node("/root/ObjectPool"):
		var object_pool: Node = get_node("/root/ObjectPool")
		if object_pool.has_method("clear_unused_objects"):
			object_pool.clear_unused_objects()


func _notify_low_performance_mode() -> void:
	"""
	通知进入低性能模式
	"""
	# 通知渲染优化器
	if has_node("/root/RenderOptimizer"):
		var render_optimizer: Node = get_node("/root/RenderOptimizer")
		if render_optimizer.has_method("enable_low_quality_mode"):
			render_optimizer.enable_low_quality_mode(true)

# =============================================================================
# JavaScript接口桥接
# =============================================================================

func _js_request_fullscreen() -> bool:
	"""
	通过JavaScript请求全屏
	"""
	if not is_web_platform:
		return false
	
	var js_code: String = """
	function() {
		var canvas = document.getElementById('canvas');
		if (!canvas) return false;
		
		if (canvas.requestFullscreen) {
			canvas.requestFullscreen();
			return true;
		} else if (canvas.webkitRequestFullscreen) {
			canvas.webkitRequestFullscreen();
			return true;
		} else if (canvas.mozRequestFullScreen) {
			canvas.mozRequestFullScreen();
			return true;
		}
		return false;
	}
	"""
	
	JavaScriptBridge.eval(js_code, true)
	return true


func _js_exit_fullscreen() -> bool:
	"""
	通过JavaScript退出全屏
	"""
	if not is_web_platform:
		return false
	
	var js_code: String = """
	function() {
		if (document.exitFullscreen) {
			document.exitFullscreen();
			return true;
		} else if (document.webkitExitFullscreen) {
			document.webkitExitFullscreen();
			return true;
		} else if (document.mozCancelFullScreen) {
			document.mozCancelFullScreen();
			return true;
		}
		return false;
	}
	"""
	
	JavaScriptBridge.eval(js_code, true)
	return true


func _js_get_window_size() -> Vector2i:
	"""
	通过JavaScript获取窗口尺寸
	"""
	if not is_web_platform:
		return Vector2i(1280, 720)
	
	var js_code: String = """
	(function() {
		return {
			width: window.innerWidth,
			height: window.innerHeight
		};
	})()
	"""
	
	var result: Variant = JavaScriptBridge.eval(js_code, true)
	if result is Dictionary:
		return Vector2i(result.get("width", 1280), result.get("height", 720))
	return Vector2i(1280, 720)


func _js_get_canvas_size() -> Vector2i:
	"""
	通过JavaScript获取Canvas尺寸
	"""
	if not is_web_platform:
		return Vector2i(1280, 720)
	
	var js_code: String = """
	(function() {
		var canvas = document.getElementById('canvas');
		if (!canvas) return {width: 1280, height: 720};
		return {
			width: canvas.width,
			height: canvas.height
		};
	})()
	"""
	
	var result: Variant = JavaScriptBridge.eval(js_code, true)
	if result is Dictionary:
		return Vector2i(result.get("width", 1280), result.get("height", 720))
	return Vector2i(1280, 720)


func _js_set_canvas_size(size: Vector2i) -> void:
	"""
	通过JavaScript设置Canvas尺寸
	"""
	if not is_web_platform:
		return
	
	var js_code: String = """
	(function(width, height) {
		var canvas = document.getElementById('canvas');
		if (!canvas) return;
		canvas.width = width;
		canvas.height = height;
	})(%d, %d)
	""" % [size.x, size.y]
	
	JavaScriptBridge.eval(js_code, true)


func _js_has_touch_support() -> bool:
	"""
	通过JavaScript检测触摸支持
	"""
	if not is_web_platform:
		return false
	
	var js_code: String = """
	(function() {
		return ('ontouchstart' in window) || 
			   (navigator.maxTouchPoints > 0) || 
			   (navigator.msMaxTouchPoints > 0);
	})()
	"""
	
	return JavaScriptBridge.eval(js_code, true)


func _js_is_mobile_browser() -> bool:
	"""
	通过JavaScript检测移动端浏览器
	"""
	if not is_web_platform:
		return false
	
	var js_code: String = """
	(function() {
		var ua = navigator.userAgent.toLowerCase();
		return /android|webos|iphone|ipad|ipod|blackberry|iemobile|opera mini/i.test(ua);
	})()
	"""
	
	return JavaScriptBridge.eval(js_code, true)


func _js_get_device_pixel_ratio() -> float:
	"""
	通过JavaScript获取设备像素比
	"""
	if not is_web_platform:
		return 1.0
	
	var js_code: String = "window.devicePixelRatio || 1"
	var result: Variant = JavaScriptBridge.eval(js_code, true)
	
	if result is float or result is int:
		return float(result)
	return 1.0


func _js_get_safe_area() -> Dictionary:
	"""
	通过JavaScript获取安全区域
	"""
	if not is_web_platform:
		return {"top": 0, "bottom": 0, "left": 0, "right": 0}
	
	var js_code: String = """
	(function() {
		var style = getComputedStyle(document.documentElement);
		return {
			top: parseInt(style.getPropertyValue('--sat') || '0'),
			bottom: parseInt(style.getPropertyValue('--sab') || '0'),
			left: parseInt(style.getPropertyValue('--sal') || '0'),
			right: parseInt(style.getPropertyValue('--sar') || '0')
		};
	})()
	"""
	
	var result: Variant = JavaScriptBridge.eval(js_code, true)
	if result is Dictionary:
		return result
	return {"top": 0, "bottom": 0, "left": 0, "right": 0}


func _js_disable_touch_defaults() -> void:
	"""
	通过JavaScript禁用默认触摸行为
	"""
	if not is_web_platform:
		return
	
	var js_code: String = """
	(function() {
		var canvas = document.getElementById('canvas');
		if (canvas) {
			canvas.style.touchAction = 'none';
		}
		document.body.style.overscrollBehavior = 'none';
	})()
	"""
	
	JavaScriptBridge.eval(js_code, true)


func _js_enable_touch_defaults() -> void:
	"""
	通过JavaScript启用默认触摸行为
	"""
	if not is_web_platform:
		return
	
	var js_code: String = """
	(function() {
		var canvas = document.getElementById('canvas');
		if (canvas) {
			canvas.style.touchAction = 'auto';
		}
		document.body.style.overscrollBehavior = 'auto';
	})()
	"""
	
	JavaScriptBridge.eval(js_code, true)


func _js_get_webgl_memory() -> int:
	"""
	通过JavaScript获取WebGL内存使用（近似值）
	"""
	if not is_web_platform:
		return 0
	
	var js_code: String = """
	(function() {
		if (performance && performance.memory) {
			return Math.round(performance.memory.usedJSHeapSize / (1024 * 1024));
		}
		return 0;
	})()
	"""
	
	var result: Variant = JavaScriptBridge.eval(js_code, true)
	if result is int or result is float:
		return int(result)
	return 0


func _js_force_gc() -> void:
	"""
	尝试通过JavaScript强制GC
	"""
	if not is_web_platform:
		return
	
	# 注意：现代浏览器通常不允许强制GC
	# 这只是一个尝试
	var js_code: String = """
	(function() {
		if (window.gc) {
			window.gc();
		}
	})()
	"""
	
	JavaScriptBridge.eval(js_code, true)


func _js_setup_context_loss(on_lost: Callable, on_restored: Callable) -> void:
	"""
	设置WebGL上下文丢失处理
	"""
	if not is_web_platform:
		return
	
	# 存储回调
	_java_script_interface = JavaScriptObject.new()
	
	var js_code: String = """
	(function() {
		var canvas = document.getElementById('canvas');
		if (!canvas) return;
		
		canvas.addEventListener('webglcontextlost', function(e) {
			e.preventDefault();
			console.warn('WebGL context lost');
		}, false);
		
		canvas.addEventListener('webglcontextrestored', function() {
			console.log('WebGL context restored');
		}, false);
	})()
	"""
	
	JavaScriptBridge.eval(js_code, true)


func _js_setup_visibility_listener(on_change: Callable) -> void:
	"""
	设置可见性监听
	"""
	if not is_web_platform:
		return
	
	var js_code: String = """
	(function() {
		document.addEventListener('visibilitychange', function() {
			if (document.hidden) {
				console.log('Page hidden');
			} else {
				console.log('Page visible');
			}
		});
	})()
	"""
	
	JavaScriptBridge.eval(js_code, true)

# =============================================================================
# 回调方法
# =============================================================================

func _on_webgl_context_lost() -> void:
	"""
	WebGL上下文丢失回调
	"""
	print("[WebAdapter] WebGL上下文丢失!")
	webgl_context_lost.emit()


func _on_webgl_context_restored() -> void:
	"""
	WebGL上下文恢复回调
	"""
	print("[WebAdapter] WebGL上下文已恢复")
	webgl_context_restored.emit()


func _on_visibility_change(is_visible: bool) -> void:
	"""
	可见性变化回调
	"""
	is_browser_visible = is_visible
	visibility_changed.emit(is_visible)
	
	if not is_visible:
		# 页面隐藏时暂停音频等
		if has_node("/root/AudioManager"):
			var audio_manager: Node = get_node("/root/AudioManager")
			if audio_manager.has_method("pause_all"):
				audio_manager.call("pause_all")
	else:
		# 页面显示时恢复音频
		if has_node("/root/AudioManager"):
			var audio_manager: Node = get_node("/root/AudioManager")
			if audio_manager.has_method("resume_all"):
				audio_manager.call("resume_all")

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
		"is_web_platform": is_web_platform,
		"is_mobile_browser": is_mobile_browser,
		"is_fullscreen": is_fullscreen,
		"window_size": str(current_window_size),
		"scale_factor": scale_factor,
		"safe_area": safe_area_margins,
		"has_touch_support": has_touch_support() if is_web_platform else false,
		"device_pixel_ratio": get_device_pixel_ratio() if is_web_platform else 1.0,
		"webgl_memory_mb": get_webgl_memory_usage() if is_web_platform else 0
	}
