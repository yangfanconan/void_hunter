## Void Hunter - 响应式布局管理器
## @description: 处理多分辨率适配、UI自动缩放和安全区域适配
## @author: Void Hunter Team
## @version: 1.0.0

extends Node

# =============================================================================
# 信号定义
# =============================================================================

## 分辨率改变时触发
signal resolution_changed(old_resolution: Vector2i, new_resolution: Vector2i)

## 宽高比改变时触发
signal aspect_ratio_changed(old_ratio: float, new_ratio: float)

## 安全区域改变时触发
signal safe_area_changed(new_safe_area: Rect2)

## 屏幕方向改变时触发
signal orientation_changed(is_landscape: bool)

## 缩放因子改变时触发
signal scale_factor_changed(new_scale: float)

# =============================================================================
# 枚举定义
# =============================================================================

## 预设分辨率类型
enum ResolutionPreset {
	HD_720P,		## 1280x720 (16:9)
	FHD_1080P,		## 1920x1080 (16:9)
	QHD_1440P,		## 2560x1440 (16:9)
	UHD_4K,			## 3840x2160 (16:9)
	HD_PLUS_18_9,	## 2160x1080 (18:9)
	SVGA_4_3,		## 1024x768 (4:3)
	XGA_4_3,		## 1280x960 (4:3)
	CUSTOM			## 自定义
}

## 屏幕方向
enum ScreenOrientation {
	LANDSCAPE,		## 横屏
	PORTRAIT,		## 竖屏
	SQUARE			## 正方形（罕见）
}

## UI锚点类型
enum AnchorType {
	TOP_LEFT,
	TOP_CENTER,
	TOP_RIGHT,
	CENTER_LEFT,
	CENTER,
	CENTER_RIGHT,
	BOTTOM_LEFT,
	BOTTOM_CENTER,
	BOTTOM_RIGHT,
	STRETCH_ALL,
	STRETCH_HORIZONTAL,
	STRETCH_VERTICAL
}

## 安全区域适配模式
enum SafeAreaMode {
	NONE,			## 不适配安全区域
	PADDING,		## 使用内边距适配
	SCALE,			## 缩放适配
	COMBINED		## 组合适配
}

# =============================================================================
# 常量定义
# =============================================================================

## 设计分辨率（基准）
const DESIGN_RESOLUTION: Vector2i = Vector2i(1280, 720)

## 预设分辨率配置
const PRESET_RESOLUTIONS: Dictionary = {
	ResolutionPreset.HD_720P: {"size": Vector2i(1280, 720), "aspect": 16.0/9.0},
	ResolutionPreset.FHD_1080P: {"size": Vector2i(1920, 1080), "aspect": 16.0/9.0},
	ResolutionPreset.QHD_1440P: {"size": Vector2i(2560, 1440), "aspect": 16.0/9.0},
	ResolutionPreset.UHD_4K: {"size": Vector2i(3840, 2160), "aspect": 16.0/9.0},
	ResolutionPreset.HD_PLUS_18_9: {"size": Vector2i(2160, 1080), "aspect": 18.0/9.0},
	ResolutionPreset.SVGA_4_3: {"size": Vector2i(1024, 768), "aspect": 4.0/3.0},
	ResolutionPreset.XGA_4_3: {"size": Vector2i(1280, 960), "aspect": 4.0/3.0}
}

## 标准宽高比
const ASPECT_16_9: float = 16.0 / 9.0
const ASPECT_18_9: float = 18.0 / 9.0
const ASPECT_4_3: float = 4.0 / 3.0
const ASPECT_21_9: float = 21.0 / 9.0

## 宽高比容差
const ASPECT_TOLERANCE: float = 0.05

# =============================================================================
# 导出变量
# =============================================================================

## 安全区域适配模式
@export var safe_area_mode: SafeAreaMode = SafeAreaMode.PADDING

## 是否自动调整UI缩放
@export var auto_scale_ui: bool = true

## 最小缩放因子
@export var min_scale_factor: float = 0.5

## 最大缩放因子
@export var max_scale_factor: float = 2.0

## 是否保持宽高比
@export var maintain_aspect_ratio: bool = true

## 目标宽高比
@export var target_aspect_ratio: float = ASPECT_16_9

## 是否在宽屏时添加黑边
@export var letterbox_on_ultrawide: bool = false

## 是否在竖屏时添加黑边
@export var pillarbox_on_portrait: bool = true

# =============================================================================
# 公共变量
# =============================================================================

## 当前屏幕分辨率
var current_resolution: Vector2i = Vector2i.ZERO

## 当前宽高比
var current_aspect_ratio: float = ASPECT_16_9

## 当前屏幕方向
var current_orientation: ScreenOrientation = ScreenOrientation.LANDSCAPE

## 当前缩放因子
var current_scale_factor: float = 1.0

## 当前安全区域
var current_safe_area: Rect2 = Rect2()

## 当前分辨率预设
var current_preset: ResolutionPreset = ResolutionPreset.HD_720P

## UI根节点引用
var ui_root: Control = null

# =============================================================================
# 私有变量
# =============================================================================

var _is_initialized: bool = false
var _registered_elements: Array[Dictionary] = []
var _letterbox_color: Color = Color.BLACK
var _letterbox_top: ColorRect = null
var _letterbox_bottom: ColorRect = null
var _pillarbox_left: ColorRect = null
var _pillarbox_right: ColorRect = null

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""
	节点就绪时初始化
	"""
	_initialize_responsive_layout()


func _notification(what: int) -> void:
	"""
	处理通知
	"""
	match what:
		NOTIFICATION_WM_SIZE_CHANGED:
			_on_window_size_changed()
		NOTIFICATION_APPLICATION_RESUMED:
			_check_resolution_change()

# =============================================================================
# 公共方法 - 初始化
# =============================================================================

## 初始化响应式布局
func initialize() -> void:
	"""
	手动初始化响应式布局
	"""
	_initialize_responsive_layout()


## 设置UI根节点
func set_ui_root(root: Control) -> void:
	"""
	设置UI根节点
	@param root: UI根节点
	"""
	ui_root = root
	_apply_layout_to_ui()

# =============================================================================
# 公共方法 - 分辨率检测
# =============================================================================

## 获取当前分辨率
func get_resolution() -> Vector2i:
	"""
	获取当前屏幕分辨率
	@return: 分辨率
	"""
	return Vector2i(DisplayServer.window_get_size())


## 获取视口大小
func get_viewport_size() -> Vector2i:
	"""
	获取视口大小
	@return: 视口大小
	"""
	var viewport: Viewport = get_viewport()
	if viewport:
		return Vector2i(viewport.get_visible_rect().size)
	return DESIGN_RESOLUTION


## 计算宽高比
func calculate_aspect_ratio(size: Vector2i) -> float:
	"""
	计算指定尺寸的宽高比
	@param size: 尺寸
	@return: 宽高比
	"""
	return float(size.x) / float(size.y)


## 检测分辨率预设
func detect_resolution_preset(size: Vector2i) -> ResolutionPreset:
	"""
	检测最接近的分辨率预设
	@param size: 分辨率
	@return: 预设类型
	"""
	for preset in PRESET_RESOLUTIONS.keys():
		var preset_size: Vector2i = PRESET_RESOLUTIONS[preset]["size"]
		if abs(size.x - preset_size.x) < 10 and abs(size.y - preset_size.y) < 10:
			return preset
	
	return ResolutionPreset.CUSTOM


## 检测屏幕方向
func detect_orientation(size: Vector2i) -> ScreenOrientation:
	"""
	检测屏幕方向
	@param size: 分辨率
	@return: 屏幕方向
	"""
	if size.x > size.y:
		return ScreenOrientation.LANDSCAPE
	elif size.y > size.x:
		return ScreenOrientation.PORTRAIT
	else:
		return ScreenOrientation.SQUARE

# =============================================================================
# 公共方法 - 缩放计算
# =============================================================================

## 计算UI缩放因子
func calculate_scale_factor(screen_size: Vector2i = Vector2i.ZERO) -> float:
	"""
	计算UI缩放因子
	@param screen_size: 屏幕尺寸（可选）
	@return: 缩放因子
	"""
	if screen_size == Vector2i.ZERO:
		screen_size = get_resolution()
	
	var base_scale: float = float(screen_size.y) / float(DESIGN_RESOLUTION.y)
	
	# 限制缩放范围
	base_scale = clamp(base_scale, min_scale_factor, max_scale_factor)
	
	return base_scale


## 计算适配后的尺寸
func calculate_fitted_size(screen_size: Vector2i, target_aspect: float = ASPECT_16_9) -> Vector2i:
	"""
	计算保持宽高比后的适配尺寸
	@param screen_size: 屏幕尺寸
	@param target_aspect: 目标宽高比
	@return: 适配后尺寸
	"""
	var screen_aspect: float = calculate_aspect_ratio(screen_size)
	
	if abs(screen_aspect - target_aspect) < ASPECT_TOLERANCE:
		return screen_size
	
	if screen_aspect > target_aspect:
		# 屏幕更宽，以高度为基准
		var fitted_width: int = int(screen_size.y * target_aspect)
		return Vector2i(fitted_width, screen_size.y)
	else:
		# 屏幕更高，以宽度为基准
		var fitted_height: int = int(screen_size.x / target_aspect)
		return Vector2i(screen_size.x, fitted_height)


## 计算安全区域
func calculate_safe_area(screen_size: Vector2i = Vector2i.ZERO) -> Rect2:
	"""
	计算安全区域
	@param screen_size: 屏幕尺寸
	@return: 安全区域
	"""
	if screen_size == Vector2i.ZERO:
		screen_size = get_resolution()
	
	# 获取系统安全区域
	var window: Window = get_window()
	if window:
		# 尝试获取系统安全区域
		# 注意：这需要平台支持
		pass
	
	# 默认返回整个屏幕
	return Rect2(Vector2.ZERO, Vector2(screen_size))

# =============================================================================
# 公共方法 - UI元素注册
# =============================================================================

## 注册UI元素
func register_ui_element(element: Control, anchor: AnchorType, 
		safe_area_aware: bool = true, stretch_ratio: float = 1.0) -> void:
	"""
	注册UI元素以进行自动布局
	@param element: UI元素
	@param anchor: 锚点类型
	@param safe_area_aware: 是否考虑安全区域
	@param stretch_ratio: 拉伸比例
	"""
	var element_info: Dictionary = {
		"element": element,
		"anchor": anchor,
		"safe_area_aware": safe_area_aware,
		"stretch_ratio": stretch_ratio,
		"original_size": element.size,
		"original_position": element.position
	}
	
	_registered_elements.append(element_info)
	_apply_anchor_to_element(element_info)


## 注销UI元素
func unregister_ui_element(element: Control) -> void:
	"""
	注销UI元素
	@param element: UI元素
	"""
	for i in range(_registered_elements.size() - 1, -1, -1):
		if _registered_elements[i]["element"] == element:
			_registered_elements.remove_at(i)
			break


## 更新所有注册的UI元素
func update_all_elements() -> void:
	"""
	更新所有注册的UI元素布局
	"""
	for element_info in _registered_elements:
		_apply_anchor_to_element(element_info)

# =============================================================================
# 公共方法 - 黑边/柱状边
# =============================================================================

## 显示黑边（Letterbox）
func show_letterbox(top_height: float, bottom_height: float) -> void:
	"""
	显示黑边
	@param top_height: 顶部黑边高度
	@param bottom_height: 底部黑边高度
	"""
	# 创建或更新顶部黑边
	if _letterbox_top == null:
		_letterbox_top = _create_letterbox_rect()
		add_child(_letterbox_top)
	
	_letterbox_top.anchors_preset = Control.PRESET_TOP_WIDE
	_letterbox_top.custom_minimum_size = Vector2(0, top_height)
	_letterbox_top.visible = top_height > 0
	
	# 创建或更新底部黑边
	if _letterbox_bottom == null:
		_letterbox_bottom = _create_letterbox_rect()
		add_child(_letterbox_bottom)
	
	_letterbox_bottom.anchors_preset = Control.PRESET_BOTTOM_WIDE
	_letterbox_bottom.custom_minimum_size = Vector2(0, bottom_height)
	_letterbox_bottom.visible = bottom_height > 0


## 显示柱状边（Pillarbox）
func show_pillarbox(left_width: float, right_width: float) -> void:
	"""
	显示柱状边
	@param left_width: 左侧柱状边宽度
	@param right_width: 右侧柱状边宽度
	"""
	# 创建或更新左侧柱状边
	if _pillarbox_left == null:
		_pillarbox_left = _create_letterbox_rect()
		add_child(_pillarbox_left)
	
	_pillarbox_left.anchors_preset = Control.PRESET_LEFT_WIDE
	_pillarbox_left.custom_minimum_size = Vector2(left_width, 0)
	_pillarbox_left.visible = left_width > 0
	
	# 创建或更新右侧柱状边
	if _pillarbox_right == null:
		_pillarbox_right = _create_letterbox_rect()
		add_child(_pillarbox_right)
	
	_pillarbox_right.anchors_preset = Control.PRESET_RIGHT_WIDE
	_pillarbox_right.custom_minimum_size = Vector2(right_width, 0)
	_pillarbox_right.visible = right_width > 0


## 隐藏所有黑边
func hide_letterbox() -> void:
	"""
	隐藏所有黑边和柱状边
	"""
	if _letterbox_top:
		_letterbox_top.visible = false
	if _letterbox_bottom:
		_letterbox_bottom.visible = false
	if _pillarbox_left:
		_pillarbox_left.visible = false
	if _pillarbox_right:
		_pillarbox_right.visible = false


## 设置黑边颜色
func set_letterbox_color(color: Color) -> void:
	"""
	设置黑边颜色
	@param color: 颜色
	"""
	_letterbox_color = color
	
	if _letterbox_top:
		_letterbox_top.color = color
	if _letterbox_bottom:
		_letterbox_bottom.color = color
	if _pillarbox_left:
		_pillarbox_left.color = color
	if _pillarbox_right:
		_pillarbox_right.color = color

# =============================================================================
# 公共方法 - 布局适配
# =============================================================================

## 应用16:9适配
func apply_16_9_layout() -> void:
	"""
	应用16:9分辨率布局
	"""
	_apply_aspect_layout(ASPECT_16_9)


## 应用18:9适配
func apply_18_9_layout() -> void:
	"""
	应用18:9分辨率布局
	"""
	_apply_aspect_layout(ASPECT_18_9)


## 应用4:3适配
func apply_4_3_layout() -> void:
	"""
	应用4:3分辨率布局
	"""
	_apply_aspect_layout(ASPECT_4_3)


## 获取UI边距（考虑安全区域）
func get_ui_margins() -> Dictionary:
	"""
	获取UI边距
	@return: 边距字典 {top, bottom, left, right}
	"""
	var margins: Dictionary = {"top": 0.0, "bottom": 0.0, "left": 0.0, "right": 0.0}
	
	if safe_area_mode == SafeAreaMode.NONE:
		return margins
	
	var screen_size: Vector2i = get_resolution()
	
	# 计算安全区域边距
	margins["top"] = current_safe_area.position.y
	margins["bottom"] = screen_size.y - current_safe_area.end.y
	margins["left"] = current_safe_area.position.x
	margins["right"] = screen_size.x - current_safe_area.end.x
	
	# 应用缩放
	if safe_area_mode == SafeAreaMode.SCALE or safe_area_mode == SafeAreaMode.COMBINED:
		var scale: float = current_scale_factor
		margins["top"] *= scale
		margins["bottom"] *= scale
		margins["left"] *= scale
		margins["right"] *= scale
	
	return margins

# =============================================================================
# 私有方法 - 初始化
# =============================================================================

func _initialize_responsive_layout() -> void:
	"""
	初始化响应式布局
	"""
	if _is_initialized:
		return
	
	_is_initialized = true
	
	# 获取初始分辨率
	current_resolution = get_resolution()
	current_aspect_ratio = calculate_aspect_ratio(current_resolution)
	current_orientation = detect_orientation(current_resolution)
	current_preset = detect_resolution_preset(current_resolution)
	current_scale_factor = calculate_scale_factor()
	current_safe_area = calculate_safe_area()
	
	print("[ResponsiveLayout] 初始化完成")
	print("  分辨率: %s" % str(current_resolution))
	print("  宽高比: %.2f" % current_aspect_ratio)
	print("  方向: %s" % ScreenOrientation.keys()[current_orientation])
	print("  预设: %s" % ResolutionPreset.keys()[current_preset])
	print("  缩放: %.2f" % current_scale_factor)


func _create_letterbox_rect() -> ColorRect:
	"""
	创建黑边矩形
	@return: ColorRect节点
	"""
	var rect: ColorRect = ColorRect.new()
	rect.color = _letterbox_color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect

# =============================================================================
# 私有方法 - 布局应用
# =============================================================================

func _apply_layout_to_ui() -> void:
	"""
	应用布局到UI
	"""
	if ui_root == null:
		return
	
	# 更新所有注册的元素
	update_all_elements()
	
	# 应用缩放
	if auto_scale_ui:
		ui_root.scale = Vector2(current_scale_factor, current_scale_factor)


func _apply_anchor_to_element(element_info: Dictionary) -> void:
	"""
	应用锚点到UI元素
	@param element_info: 元素信息
	"""
	var element: Control = element_info["element"]
	var anchor: AnchorType = element_info["anchor"]
	var safe_area_aware: bool = element_info["safe_area_aware"]
	
	if element == null or not is_instance_valid(element):
		return
	
	# 获取安全区域边距
	var margins: Dictionary = get_ui_margins() if safe_area_aware else {"top": 0, "bottom": 0, "left": 0, "right": 0}
	
	# 应用锚点
	match anchor:
		AnchorType.TOP_LEFT:
			element.anchors_preset = Control.PRESET_TOP_LEFT
			element.offset_top = margins["top"]
			element.offset_left = margins["left"]
		
		AnchorType.TOP_CENTER:
			element.anchors_preset = Control.PRESET_CENTER_TOP
			element.offset_top = margins["top"]
		
		AnchorType.TOP_RIGHT:
			element.anchors_preset = Control.PRESET_TOP_RIGHT
			element.offset_top = margins["top"]
			element.offset_right = -margins["right"]
		
		AnchorType.CENTER_LEFT:
			element.anchors_preset = Control.PRESET_CENTER_LEFT
			element.offset_left = margins["left"]
		
		AnchorType.CENTER:
			element.anchors_preset = Control.PRESET_CENTER
		
		AnchorType.CENTER_RIGHT:
			element.anchors_preset = Control.PRESET_CENTER_RIGHT
			element.offset_right = -margins["right"]
		
		AnchorType.BOTTOM_LEFT:
			element.anchors_preset = Control.PRESET_BOTTOM_LEFT
			element.offset_bottom = -margins["bottom"]
			element.offset_left = margins["left"]
		
		AnchorType.BOTTOM_CENTER:
			element.anchors_preset = Control.PRESET_CENTER_BOTTOM
			element.offset_bottom = -margins["bottom"]
		
		AnchorType.BOTTOM_RIGHT:
			element.anchors_preset = Control.PRESET_BOTTOM_RIGHT
			element.offset_bottom = -margins["bottom"]
			element.offset_right = -margins["right"]
		
		AnchorType.STRETCH_ALL:
			element.anchors_preset = Control.PRESET_FULL_RECT
			element.offset_top = margins["top"]
			element.offset_bottom = -margins["bottom"]
			element.offset_left = margins["left"]
			element.offset_right = -margins["right"]
		
		AnchorType.STRETCH_HORIZONTAL:
			element.anchor_left = 0.0
			element.anchor_right = 1.0
			element.offset_left = margins["left"]
			element.offset_right = -margins["right"]
		
		AnchorType.STRETCH_VERTICAL:
			element.anchor_top = 0.0
			element.anchor_bottom = 1.0
			element.offset_top = margins["top"]
			element.offset_bottom = -margins["bottom"]


func _apply_aspect_layout(target_aspect: float) -> void:
	"""
	应用指定宽高比布局
	@param target_aspect: 目标宽高比
	"""
	var screen_size: Vector2i = get_resolution()
	var screen_aspect: float = calculate_aspect_ratio(screen_size)
	
	if abs(screen_aspect - target_aspect) < ASPECT_TOLERANCE:
		# 宽高比匹配，无需黑边
		hide_letterbox()
		return
	
	if screen_aspect > target_aspect:
		# 屏幕更宽，添加柱状边
		if pillarbox_on_portrait or letterbox_on_ultrawide:
			var fitted_width: float = screen_size.y * target_aspect
			var pillar_width: float = (screen_size.x - fitted_width) / 2.0
			show_pillarbox(pillar_width, pillar_width)
			hide_letterbox()  # 隐藏黑边
		else:
			hide_letterbox()
	else:
		# 屏幕更高，添加黑边
		var fitted_height: float = screen_size.x / target_aspect
		var letter_height: float = (screen_size.y - fitted_height) / 2.0
		show_letterbox(letter_height, letter_height)
		hide_letterbox()  # 隐藏柱状边

# =============================================================================
# 私有方法 - 事件处理
# =============================================================================

func _on_window_size_changed() -> void:
	"""
	窗口大小改变处理
	"""
	var old_resolution: Vector2i = current_resolution
	var old_aspect: float = current_aspect_ratio
	
	current_resolution = get_resolution()
	current_aspect_ratio = calculate_aspect_ratio(current_resolution)
	current_orientation = detect_orientation(current_resolution)
	current_preset = detect_resolution_preset(current_resolution)
	current_scale_factor = calculate_scale_factor()
	current_safe_area = calculate_safe_area()
	
	# 检查分辨率是否改变
	if current_resolution != old_resolution:
		resolution_changed.emit(old_resolution, current_resolution)
	
	# 检查宽高比是否改变
	if abs(current_aspect_ratio - old_aspect) > ASPECT_TOLERANCE:
		aspect_ratio_changed.emit(old_aspect, current_aspect_ratio)
		_apply_aspect_layout(target_aspect_ratio)
	
	# 更新UI
	_apply_layout_to_ui()
	
	print("[ResponsiveLayout] 窗口大小改变: %s, 宽高比: %.2f" % [
		str(current_resolution), current_aspect_ratio
	])


func _check_resolution_change() -> void:
	"""
	检查分辨率变化（应用恢复时）
	"""
	var new_resolution: Vector2i = get_resolution()
	if new_resolution != current_resolution:
		_on_window_size_changed()

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
		"current_resolution": str(current_resolution),
		"design_resolution": str(DESIGN_RESOLUTION),
		"aspect_ratio": current_aspect_ratio,
		"orientation": ScreenOrientation.keys()[current_orientation],
		"preset": ResolutionPreset.keys()[current_preset],
		"scale_factor": current_scale_factor,
		"safe_area": str(current_safe_area),
		"registered_elements": _registered_elements.size(),
		"safe_area_mode": SafeAreaMode.keys()[safe_area_mode]
	}


## 获取适配建议
func get_adaptation_recommendations() -> Array[String]:
	"""
	获取当前分辨率的适配建议
	@return: 建议列表
	"""
	var recommendations: Array[String] = []
	
	match current_preset:
		ResolutionPreset.HD_PLUS_18_9:
			recommendations.append("18:9屏幕：考虑调整UI元素位置以避免被拉长")
		ResolutionPreset.SVGA_4_3, ResolutionPreset.XGA_4_3:
			recommendations.append("4:3屏幕：建议添加柱状边以保持16:9宽高比")
		ResolutionPreset.CUSTOM:
			recommendations.append("非标准分辨率：检查UI元素是否正确显示")
	
	if current_scale_factor < 0.8:
		recommendations.append("低分辨率：考虑简化UI布局")
	elif current_scale_factor > 1.5:
		recommendations.append("高分辨率：UI元素可能显得过大")
	
	var safe_area_margins: Dictionary = get_ui_margins()
	if safe_area_margins["top"] > 50 or safe_area_margins["bottom"] > 50:
		recommendations.append("检测到较大安全区域：确保UI不被遮挡")
	
	return recommendations
