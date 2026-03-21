## Void Hunter - 攻击摇杆
## @description: 用于瞄准和射击的虚拟摇杆
## @author: Void Hunter Team
## @version: 1.0.0

extends VirtualJoystick
class_name VirtualJoystickAttack

# =============================================================================
# 信号定义
# =============================================================================

## 开始射击时触发
signal fire_started(direction: Vector2)

## 停止射击时触发
signal fire_stopped()

# =============================================================================
# 导出变量
# =============================================================================

## 是否自动射击（持续射击）
@export var auto_fire: bool = true

## 射击延迟（秒）
@export var fire_delay: float = 0.0

## 是否在拖动时射击
@export var fire_while_dragging: bool = true

# =============================================================================
# 私有变量
# =============================================================================

var _is_firing: bool = false
var _fire_delay_timer: float = 0.0

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""
	节点就绪时初始化
	"""
	# 设置攻击摇杆特定属性
	joystick_mode = JoystickMode.DYNAMIC
	deadzone_radius = 30.0
	max_radius = 60.0
	background_color = Color(1, 0.5, 0.5, 0.3)
	knob_color = Color(1, 0.3, 0.3, 0.6)
	
	super._ready()


func _process(delta: float) -> void:
	"""
	每帧更新
	@param delta: 帧间隔时间
	"""
	# 更新射击延迟
	if _fire_delay_timer > 0:
		_fire_delay_timer -= delta
		
		if _fire_delay_timer <= 0 and is_touching and not _is_firing:
			_start_firing()


func _gui_input(event: InputEvent) -> void:
	"""
	处理GUI输入事件
	@param event: 输入事件
	"""
	# 触摸开始
	if event is InputEventScreenTouch and event.pressed:
		if touch_index == -1 and _is_touch_in_area(event.position):
			_start_touch(event)
			
			# 开始射击
			if fire_while_dragging:
				if fire_delay > 0:
					_fire_delay_timer = fire_delay
				else:
					_start_firing()
			
			accept_event()
	
	# 触摸移动
	elif event is InputEventScreenDrag:
		if event.index == touch_index:
			_update_touch(event.position)
			accept_event()


func _input(event: InputEvent) -> void:
	"""
	处理全局输入事件
	@param event: 输入事件
	"""
	if event is InputEventScreenTouch and not event.pressed and event.index == touch_index:
		_stop_firing()
		_reset_joystick()


# =============================================================================
# 私有方法
# =============================================================================

func _is_touch_in_area(touch_pos: Vector2) -> bool:
	"""
	检查触摸是否在区域内（右半屏幕）
	@param touch_pos: 触摸位置
	@return: 是否在区域内
	"""
	return touch_pos.x > get_viewport().size.x / 2


func _start_firing() -> void:
	"""
	开始射击
	"""
	_is_firing = true
	fire_started.emit(joystick_direction)


func _stop_firing() -> void:
	"""
	停止射击
	"""
	_is_firing = false
	_fire_delay_timer = 0.0
	fire_stopped.emit()


# =============================================================================
# 公共方法
# =============================================================================

## 是否正在射击
func is_firing() -> bool:
	"""
	检查是否正在射击
	@return: 是否正在射击
	"""
	return _is_firing


## 获取瞄准方向
func get_aim_direction() -> Vector2:
	"""
	获取瞄准方向
	@return: 瞄准方向
	"""
	if is_in_deadzone():
		return Vector2.ZERO
	return joystick_direction
