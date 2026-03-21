## Void Hunter - 虚拟摇杆
## @description: 触屏控制的虚拟摇杆组件
## @author: Void Hunter Team
## @version: 1.0.0

extends Control
class_name VirtualJoystick

# =============================================================================
# 信号定义
# =============================================================================

## 摇杆移动时触发
signal joystick_moved(direction: Vector2)

## 摇杆按下时触发
signal joystick_pressed()

## 摇杆释放时触发
signal joystick_released()

# =============================================================================
# 常量定义
# =============================================================================

## 默认死区半径
const DEFAULT_DEADZONE: float = 20.0

## 默认最大半径
const DEFAULT_MAX_RADIUS: float = 80.0

# =============================================================================
# 枚举定义
# =============================================================================

## 摇杆模式
enum JoystickMode {
	FIXED,		## 固定位置
	DYNAMIC,	## 动态（触摸位置）
	FOLLOWING	## 跟随手指
}

# =============================================================================
# 导出变量
# =============================================================================

## 摇杆模式
@export var joystick_mode: JoystickMode = JoystickMode.DYNAMIC

## 死区半径（小于此值不响应）
@export var deadzone_radius: float = DEFAULT_DEADZONE

## 最大移动半径
@export var max_radius: float = DEFAULT_MAX_RADIUS

## 是否显示背景
@export var show_background: bool = true

## 背景颜色
@export var background_color: Color = Color(1, 1, 1, 0.3)

## 摇杆颜色
@export var knob_color: Color = Color(1, 1, 1, 0.6)

## 是否水平方向
@export var horizontal_enabled: bool = true

## 是否垂直方向
@export var vertical_enabled: bool = true

## 触摸区域（自动或手动）
@export var touch_area: Rect2 = Rect2()

## 是否使用触摸区域
@export var use_touch_area: bool = false

# =============================================================================
# 公共变量
# =============================================================================

## 当前摇杆方向（-1到1）
var joystick_direction: Vector2 = Vector2.ZERO

## 是否正在触摸
var is_touching: bool = false

## 当前触摸ID
var touch_index: int = -1

# =============================================================================
# 私有变量
# =============================================================================

var _knob_position: Vector2 = Vector2.ZERO
var _base_position: Vector2 = Vector2.ZERO
var _base_rect: Rect2 = Rect2()
var _knob_rect: Rect2 = Rect2()
var _is_initialized: bool = false

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""
	节点就绪时初始化
	"""
	_initialize_joystick()
	_setup_visual_elements()


func _gui_input(event: InputEvent) -> void:
	"""
	处理GUI输入事件
	@param event: 输入事件
	"""
	_handle_input(event)


func _input(event: InputEvent) -> void:
	"""
	处理全局输入事件
	@param event: 输入事件
	"""
	# 处理触摸释放
	if event is InputEventScreenTouch and not event.pressed and event.index == touch_index:
		_reset_joystick()


func _draw() -> void:
	"""
	绘制摇杆
	"""
	if not _is_initialized:
		return
	
	# 绘制背景
	if show_background:
		draw_circle(_base_position, max_radius + 10, background_color)
	
	# 绘制摇杆
	draw_circle(_base_position + _knob_position, 30, knob_color)

# =============================================================================
# 公共方法
# =============================================================================

## 初始化摇杆
func initialize() -> void:
	"""
	手动初始化摇杆
	"""
	_initialize_joystick()


## 重置摇杆
func reset() -> void:
	"""
	重置摇杆状态
	"""
	_reset_joystick()


## 设置摇杆颜色
func set_colors(bg_color: Color, knob_col: Color) -> void:
	"""
	设置摇杆颜色
	@param bg_color: 背景颜色
	@param knob_col: 摇杆颜色
	"""
	background_color = bg_color
	knob_color = knob_col
	queue_redraw()


## 获取归一化方向
func get_normalized_direction() -> Vector2:
	"""
	获取归一化的方向向量
	@return: 归一化方向
	"""
	return joystick_direction


## 获取原始方向（未归一化）
func get_raw_direction() -> Vector2:
	"""
	获取原始方向向量
	@return: 原始方向
	"""
	return _knob_position / max_radius if max_radius > 0 else Vector2.ZERO


## 是否在死区内
func is_in_deadzone() -> bool:
	"""
	检查当前是否在死区内
	@return: 是否在死区
	"""
	return _knob_position.length() < deadzone_radius

# =============================================================================
# 私有方法 - 初始化
# =============================================================================

func _initialize_joystick() -> void:
	"""
	初始化摇杆内部状态
	"""
	# 设置锚点和位置
	anchor_right = 0.0
	anchor_bottom = 0.0
	
	# 设置初始位置
	if joystick_mode == JoystickMode.FIXED:
		_base_position = size / 2
	else:
		_base_position = Vector2(150, size.y - 150)
	
	_knob_position = Vector2.ZERO
	_is_initialized = true
	
	# 更新碰撞区域
	_update_touch_rect()


func _setup_visual_elements() -> void:
	"""
	设置视觉元素
	"""
	# 设置最小尺寸
	custom_minimum_size = Vector2(200, 200)


func _update_touch_rect() -> void:
	"""
	更新触摸区域
	"""
	if use_touch_area:
		_base_rect = touch_area
	else:
		_base_rect = Rect2(Vector2.ZERO, size)

# =============================================================================
# 私有方法 - 输入处理
# =============================================================================

func _handle_input(event: InputEvent) -> void:
	"""
	处理输入事件
	@param event: 输入事件
	"""
	# 触摸开始
	if event is InputEventScreenTouch and event.pressed:
		if touch_index == -1 and _is_touch_in_area(event.position):
			_start_touch(event)
			accept_event()
	
	# 触摸移动
	elif event is InputEventScreenDrag:
		if event.index == touch_index:
			_update_touch(event.position)
			accept_event()


func _is_touch_in_area(touch_pos: Vector2) -> bool:
	"""
	检查触摸是否在区域内
	@param touch_pos: 触摸位置
	@return: 是否在区域内
	"""
	if use_touch_area:
		return touch_area.has_point(touch_pos)
	
	# 动态模式：检查左半屏幕
	if joystick_mode == JoystickMode.DYNAMIC:
		return touch_pos.x < get_viewport().size.x / 2
	
	# 固定模式：检查摇杆区域
	return _base_rect.has_point(touch_pos)


func _start_touch(event: InputEventScreenTouch) -> void:
	"""
	开始触摸
	@param event: 触摸事件
	"""
	touch_index = event.index
	is_touching = true
	
	# 动态模式：将摇杆移动到触摸位置
	if joystick_mode == JoystickMode.DYNAMIC:
		_base_position = event.position
	
	joystick_pressed.emit()
	_update_touch(event.position)


func _update_touch(touch_pos: Vector2) -> void:
	"""
	更新触摸位置
	@param touch_pos: 触摸位置
	"""
	if not is_touching:
		return
	
	# 计算摇杆偏移
	var offset: Vector2 = touch_pos - _base_position
	
	# 限制方向
	if not horizontal_enabled:
		offset.x = 0
	if not vertical_enabled:
		offset.y = 0
	
	# 限制在最大半径内
	var distance: float = offset.length()
	if distance > max_radius:
		offset = offset.normalized() * max_radius
	
	_knob_position = offset
	
	# 计算归一化方向（考虑死区）
	if distance < deadzone_radius:
		joystick_direction = Vector2.ZERO
	else:
		joystick_direction = offset.normalized()
		# 应用死区补偿
		var adjusted_length: float = (distance - deadzone_radius) / (max_radius - deadzone_radius)
		joystick_direction = joystick_direction * clamp(adjusted_length, 0.0, 1.0)
	
	# 触发信号
	joystick_moved.emit(joystick_direction)
	
	# 重绘
	queue_redraw()


func _reset_joystick() -> void:
	"""
	重置摇杆状态
	"""
	is_touching = false
	touch_index = -1
	_knob_position = Vector2.ZERO
	joystick_direction = Vector2.ZERO
	
	# 如果是动态模式，重置基础位置
	if joystick_mode == JoystickMode.DYNAMIC:
		_base_position = Vector2(150, size.y - 150)
	
	joystick_released.emit()
	queue_redraw()

# =============================================================================
# 调整大小
# =============================================================================

func _notification(what: int) -> void:
	"""
	处理通知
	@param what: 通知类型
	"""
	if what == NOTIFICATION_RESIZED:
		_on_size_changed()


func _on_size_changed() -> void:
	"""
	尺寸改变时更新
	"""
	_update_touch_rect()
	if joystick_mode == JoystickMode.FIXED:
		_base_position = size / 2
	queue_redraw()
