## Void Hunter - 输入管理器
## @description: 跨平台输入管理单例，自动检测设备类型，处理键鼠和触屏输入
## @author: Void Hunter Team
## @version: 1.0.0

extends Node

# =============================================================================
# 信号定义
# =============================================================================

## 输入设备类型改变时触发
signal input_device_changed(old_device: InputDevice, new_device: InputDevice)

## 触屏虚拟按钮按下时触发
signal virtual_button_pressed(button_id: String)

## 触屏虚拟按钮释放时触发
signal virtual_button_released(button_id: String)

## 移动方向改变时触发（触屏摇杆）
signal move_direction_changed(direction: Vector2)

## 瞄准方向改变时触发（触屏）
signal aim_direction_changed(direction: Vector2, global_position: Vector2)

## 攻击状态改变时触发
signal attack_state_changed(is_attacking: bool)

# =============================================================================
# 枚举定义
# =============================================================================

## 输入设备类型
enum InputDevice {
	KEYBOARD_MOUSE,	## 键盘+鼠标
	TOUCH,			## 触屏
	GAMEPAD			## 手柄
}

## 虚拟按钮ID
enum VirtualButton {
	ATTACK,			## 攻击按钮
	SKILL_1,		## 技能1
	SKILL_2,		## 技能2
	SKILL_3,		## 技能3
	DASH,			## 冲刺
	ITEM_1,			## 道具1
	ITEM_2,			## 道具2
	PAUSE			## 暂停
}

# =============================================================================
# 常量定义
# =============================================================================

## 设备检测超时时间
const DEVICE_CHECK_INTERVAL: float = 0.5

## 触屏检测阈值
const TOUCH_DETECTION_THRESHOLD: float = 10.0

## 虚拟摇杆死区
const JOYSTICK_DEADZONE: float = 0.15

# =============================================================================
# 导出变量
# =============================================================================

## 是否启用触屏控制
@export var touch_controls_enabled: bool = true

## 是否自动检测设备
@export var auto_detect_device: bool = true

## 是否显示虚拟控制器（调试用）
@export var show_virtual_controller: bool = false

## 移动摇杆灵敏度
@export var move_joystick_sensitivity: float = 1.0

## 瞄准摇杆灵敏度
@export var aim_joystick_sensitivity: float = 1.0

# =============================================================================
# 公共变量
# =============================================================================

## 当前输入设备
var current_device: InputDevice = InputDevice.KEYBOARD_MOUSE

## 当前移动方向
var move_direction: Vector2 = Vector2.ZERO

## 当前瞄准方向
var aim_direction: Vector2 = Vector2.RIGHT

## 当前瞄准世界坐标
var aim_global_position: Vector2 = Vector2.ZERO

## 是否正在攻击
var is_attacking: bool = false

## 是否触屏模式
var is_touch_mode: bool = false

## 移动摇杆引用
var move_joystick: Node = null

## 攻击摇杆引用
var attack_joystick: Node = null

## 虚拟按钮状态
var virtual_button_states: Dictionary = {}

# =============================================================================
# 私有变量
# =============================================================================

var _last_input_time: float = 0.0
var _last_mouse_position: Vector2 = Vector2.ZERO
var _device_check_timer: float = 0.0
var _touch_count: int = 0
var _is_initialized: bool = false
var _cached_player: Node = null

## 虚拟按钮配置
var _virtual_button_config: Dictionary = {
	VirtualButton.ATTACK: {"action": "attack", "label": "ATK"},
	VirtualButton.SKILL_1: {"action": "skill_1", "label": "S1"},
	VirtualButton.SKILL_2: {"action": "skill_2", "label": "S2"},
	VirtualButton.SKILL_3: {"action": "skill_3", "label": "S3"},
	VirtualButton.DASH: {"action": "dash", "label": "DASH"},
	VirtualButton.ITEM_1: {"action": "item_1", "label": "I1"},
	VirtualButton.ITEM_2: {"action": "item_2", "label": "I2"},
	VirtualButton.PAUSE: {"action": "pause", "label": "||"}
}

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""
	节点就绪时初始化
	"""
	_initialize_input_manager()


func _process(delta: float) -> void:
	"""
	每帧更新
	"""
	if auto_detect_device:
		_device_check_timer += delta
		if _device_check_timer >= DEVICE_CHECK_INTERVAL:
			_device_check_timer = 0.0
			_check_input_device()
	
	# 更新瞄准位置
	_update_aim_position()


func _input(event: InputEvent) -> void:
	"""
	处理输入事件
	"""
	# 检测输入设备
	if event is InputEventKey or event is InputEventMouseButton:
		if current_device != InputDevice.KEYBOARD_MOUSE:
			_switch_device(InputDevice.KEYBOARD_MOUSE)
		_last_input_time = Time.get_unix_time_from_system()
	
	elif event is InputEventScreenTouch or event is InputEventScreenDrag:
		if current_device != InputDevice.TOUCH:
			_switch_device(InputDevice.TOUCH)
		_last_input_time = Time.get_unix_time_from_system()
	
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if current_device != InputDevice.GAMEPAD:
			_switch_device(InputDevice.GAMEPAD)
		_last_input_time = Time.get_unix_time_from_system()

# =============================================================================
# 公共方法 - 初始化
# =============================================================================

## 初始化输入管理器
func initialize() -> void:
	"""
	手动初始化输入管理器
	"""
	_initialize_input_manager()


## 设置移动摇杆引用
func set_move_joystick(joystick: Node) -> void:
	"""
	设置移动摇杆引用
	@param joystick: 摇杆节点
	"""
	move_joystick = joystick
	if move_joystick and move_joystick.has_signal("joystick_moved"):
		if not move_joystick.joystick_moved.is_connected(_on_move_joystick_moved):
			move_joystick.joystick_moved.connect(_on_move_joystick_moved)
		if not move_joystick.joystick_released.is_connected(_on_move_joystick_released):
			move_joystick.joystick_released.connect(_on_move_joystick_released)


## 设置攻击摇杆引用
func set_attack_joystick(joystick: Node) -> void:
	"""
	设置攻击摇杆引用
	@param joystick: 摇杆节点
	"""
	attack_joystick = joystick
	if attack_joystick and attack_joystick.has_signal("joystick_moved"):
		if not attack_joystick.joystick_moved.is_connected(_on_attack_joystick_moved):
			attack_joystick.joystick_moved.connect(_on_attack_joystick_moved)
		if not attack_joystick.joystick_released.is_connected(_on_attack_joystick_released):
			attack_joystick.joystick_released.connect(_on_attack_joystick_released)


## 注册虚拟按钮
func register_virtual_button(button_node: Node, button_id: VirtualButton) -> void:
	"""
	注册虚拟按钮
	@param button_node: 按钮节点
	@param button_id: 按钮ID
	"""
	var button_name: String = VirtualButton.keys()[button_id]
	virtual_button_states[button_name] = {
		"node": button_node,
		"pressed": false
	}
	
	# 连接按钮信号
	if button_node.has_signal("button_down"):
		if not button_node.button_down.is_connected(_on_virtual_button_down.bind(button_name)):
			button_node.button_down.connect(_on_virtual_button_down.bind(button_name))
	
	if button_node.has_signal("button_up"):
		if not button_node.button_up.is_connected(_on_virtual_button_up.bind(button_name)):
			button_node.button_up.connect(_on_virtual_button_up.bind(button_name))

# =============================================================================
# 公共方法 - 设备管理
# =============================================================================

## 获取当前设备类型
func get_current_device() -> InputDevice:
	"""
	获取当前输入设备类型
	@return: 设备类型
	"""
	return current_device


## 切换到指定设备
func switch_to_device(device: InputDevice) -> void:
	"""
	手动切换输入设备
	@param device: 目标设备类型
	"""
	_switch_device(device)


## 检测是否为触屏设备
func is_touch_device() -> bool:
	"""
	检测当前是否为触屏设备
	@return: 是否触屏
	"""
	return current_device == InputDevice.TOUCH or is_touch_mode


## 检测是否支持触屏
func has_touch_support() -> bool:
	"""
	检测系统是否支持触屏
	@return: 是否支持
	"""
	return DisplayServer.is_touch_available() or OS.has_feature("web_android") or OS.has_feature("android")


## 强制启用触屏模式
func enable_touch_mode(enabled: bool) -> void:
	"""
	强制启用或禁用触屏模式
	@param enabled: 是否启用
	"""
	is_touch_mode = enabled
	if enabled:
		_switch_device(InputDevice.TOUCH)
	else:
		_switch_device(InputDevice.KEYBOARD_MOUSE)

# =============================================================================
# 公共方法 - 输入获取
# =============================================================================

## 获取移动方向向量
func get_movement_vector() -> Vector2:
	"""
	获取当前移动方向向量（归一化）
	@return: 移动方向
	"""
	if current_device == InputDevice.TOUCH and is_touch_mode:
		return move_direction * move_joystick_sensitivity
	
	return Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")


## 获取瞄准方向向量
func get_aim_direction() -> Vector2:
	"""
	获取当前瞄准方向向量（归一化）
	@return: 瞄准方向
	"""
	return aim_direction


## 获取瞄准世界坐标
func get_aim_global_position() -> Vector2:
	"""
	获取瞄准的世界坐标位置
	@return: 世界坐标
	"""
	return aim_global_position


## 检测攻击输入
func is_attack_pressed() -> bool:
	"""
	检测是否按下攻击
	@return: 是否按下
	"""
	if current_device == InputDevice.TOUCH:
		return is_attacking
	return Input.is_action_pressed("attack")


## 检测技能输入
func is_skill_pressed(skill_index: int) -> bool:
	"""
	检测是否按下指定技能
	@param skill_index: 技能索引（0-2）
	@return: 是否按下
	"""
	var action_name: String = "skill_" + str(skill_index + 1)
	
	if current_device == InputDevice.TOUCH:
		var button_name: String = VirtualButton.keys()[VirtualButton.SKILL_1 + skill_index]
		return virtual_button_states.get(button_name, {}).get("pressed", false)
	
	return Input.is_action_pressed(action_name)


## 检测冲刺输入
func is_dash_pressed() -> bool:
	"""
	检测是否按下冲刺
	@return: 是否按下
	"""
	if current_device == InputDevice.TOUCH:
		var button_name: String = VirtualButton.keys()[VirtualButton.DASH]
		return virtual_button_states.get(button_name, {}).get("pressed", false)
	
	return Input.is_action_just_pressed("dash")


## 检测暂停输入
func is_pause_pressed() -> bool:
	"""
	检测是否按下暂停
	@return: 是否按下
	"""
	if current_device == InputDevice.TOUCH:
		var button_name: String = VirtualButton.keys()[VirtualButton.PAUSE]
		return virtual_button_states.get(button_name, {}).get("pressed", false)
	
	return Input.is_action_just_pressed("pause")


## 检测虚拟按钮状态
func is_virtual_button_pressed(button_id: VirtualButton) -> bool:
	"""
	检测虚拟按钮是否按下
	@param button_id: 按钮ID
	@return: 是否按下
	"""
	var button_name: String = VirtualButton.keys()[button_id]
	return virtual_button_states.get(button_name, {}).get("pressed", false)

# =============================================================================
# 公共方法 - 手柄支持
# =============================================================================

## 获取手柄左摇杆方向
func get_gamepad_left_stick() -> Vector2:
	"""
	获取手柄左摇杆方向
	@return: 摇杆方向
	"""
	return Vector2(
		Input.get_joy_axis(0, JoyAxis.JOY_AXIS_LEFT_X),
		Input.get_joy_axis(0, JoyAxis.JOY_AXIS_LEFT_Y)
	)


## 获取手柄右摇杆方向
func get_gamepad_right_stick() -> Vector2:
	"""
	获取手柄右摇杆方向
	@return: 摇杆方向
	"""
	return Vector2(
		Input.get_joy_axis(0, JoyAxis.JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(0, JoyAxis.JOY_AXIS_RIGHT_Y)
	)


## 检测手柄连接
func is_gamepad_connected() -> bool:
	"""
	检测是否有手柄连接
	@return: 是否连接
	"""
	return Input.get_connected_joypads().size() > 0

# =============================================================================
# 公共方法 - 输入映射
# =============================================================================

## 模拟输入动作
func simulate_action_press(action: String) -> void:
	"""
	模拟按下输入动作
	@param action: 动作名称
	"""
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)


## 模拟释放输入动作
func simulate_action_release(action: String) -> void:
	"""
	模拟释放输入动作
	@param action: 动作名称
	"""
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = false
	Input.parse_input_event(event)

# =============================================================================
# 私有方法 - 初始化
# =============================================================================

func _initialize_input_manager() -> void:
	"""
	初始化输入管理器
	"""
	if _is_initialized:
		return
	
	_is_initialized = true
	
	# 初始化虚拟按钮状态
	for button_id in VirtualButton.values():
		var button_name: String = VirtualButton.keys()[button_id]
		virtual_button_states[button_name] = {"node": null, "pressed": false}
	
	# 初始设备检测
	_detect_initial_device()
	
	# 连接信号
	_connect_signals()
	
	print("[InputManager] 初始化完成 - 当前设备: %s" % InputDevice.keys()[current_device])


func _detect_initial_device() -> void:
	"""
	检测初始输入设备
	"""
	# 检测触屏支持
	if has_touch_support() and not OS.has_feature("pc"):
		current_device = InputDevice.TOUCH
		is_touch_mode = true
	# 检测手柄
	elif is_gamepad_connected():
		current_device = InputDevice.GAMEPAD
	# 默认键鼠
	else:
		current_device = InputDevice.KEYBOARD_MOUSE


func _connect_signals() -> void:
	"""
	连接信号
	"""
	# 连接手柄连接/断开信号
	Input.joy_connection_changed.connect(_on_joy_connection_changed)

# =============================================================================
# 私有方法 - 设备检测
# =============================================================================

func _check_input_device() -> void:
	"""
	检查输入设备变化
	"""
	# 如果有手柄连接且长时间无键鼠输入
	if is_gamepad_connected() and current_device == InputDevice.GAMEPAD:
		return
	
	# 自动检测触屏
	if has_touch_support():
		var touch_pressed: bool = false
		for i in range(5):
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT + i):
				touch_pressed = true
				break
		
		if touch_pressed and current_device != InputDevice.TOUCH:
			_switch_device(InputDevice.TOUCH)


func _switch_device(new_device: InputDevice) -> void:
	"""
	切换输入设备
	@param new_device: 新设备类型
	"""
	if current_device == new_device:
		return
	
	var old_device: InputDevice = current_device
	current_device = new_device
	
	# 更新触屏模式
	is_touch_mode = (new_device == InputDevice.TOUCH)
	
	# 通知玩家更新输入模式
	_update_player_input_mode()
	
	input_device_changed.emit(old_device, new_device)
	
	print("[InputManager] 设备切换: %s -> %s" % [
		InputDevice.keys()[old_device],
		InputDevice.keys()[new_device]
	])


func _update_player_input_mode() -> void:
	"""
	更新玩家输入模式
	"""
	if _cached_player == null:
		_cached_player = _find_player()
	
	if _cached_player and _cached_player.has_method("set"):
		_cached_player.set("input_mode", Player.InputMode.TOUCH if is_touch_mode else Player.InputMode.KEYBOARD_MOUSE)


func _find_player() -> Node:
	"""
	查找玩家节点
	"""
	var players: Array[Node] = get_tree().get_nodes_in_group("players")
	if players.size() > 0:
		return players[0]
	return null

# =============================================================================
# 私有方法 - 瞄准更新
# =============================================================================

func _update_aim_position() -> void:
	"""
	更新瞄准位置
	"""
	if current_device == InputDevice.TOUCH:
		# 触屏模式下瞄准位置由攻击摇杆更新
		return
	
	# 键鼠模式：使用鼠标位置
	var viewport: Viewport = get_viewport()
	if viewport:
		var mouse_pos: Vector2 = viewport.get_mouse_position()
		var camera: Camera2D = _get_active_camera()
		
		if camera:
			aim_global_position = mouse_pos + camera.get_screen_center_position() - viewport.get_visible_rect().size / 2
		else:
			aim_global_position = mouse_pos
		
		# 更新玩家引用
		if _cached_player:
			aim_direction = (aim_global_position - _cached_player.global_position).normalized()
	else:
		aim_direction = Vector2.RIGHT


func _get_active_camera() -> Camera2D:
	"""
	获取活动摄像机
	"""
	var viewports: Array[Node] = get_tree().get_nodes_in_group("cameras")
	if viewports.size() > 0:
		return viewports[0]
	
	# 尝试从场景中获取
	var camera: Camera2D = get_viewport().get_camera_2d()
	return camera

# =============================================================================
# 信号回调 - 摇杆
# =============================================================================

func _on_move_joystick_moved(direction: Vector2) -> void:
	"""
	移动摇杆移动回调
	"""
	# 应用死区
	if direction.length() < JOYSTICK_DEADZONE:
		move_direction = Vector2.ZERO
	else:
		# 重新归一化，跳过死区
		var adjusted_direction: Vector2 = direction.normalized()
		var adjusted_length: float = (direction.length() - JOYSTICK_DEADZONE) / (1.0 - JOYSTICK_DEADZONE)
		move_direction = adjusted_direction * clamp(adjusted_length, 0.0, 1.0)
	
	# 更新玩家
	if _cached_player and _cached_player.has_method("set_touch_move_direction"):
		_cached_player.set_touch_move_direction(move_direction)
	
	move_direction_changed.emit(move_direction)


func _on_move_joystick_released() -> void:
	"""
	移动摇杆释放回调
	"""
	move_direction = Vector2.ZERO
	
	if _cached_player and _cached_player.has_method("set_touch_move_direction"):
		_cached_player.set_touch_move_direction(Vector2.ZERO)
	
	move_direction_changed.emit(Vector2.ZERO)


func _on_attack_joystick_moved(direction: Vector2) -> void:
	"""
	攻击摇杆移动回调
	"""
	if direction.length() < JOYSTICK_DEADZONE:
		aim_direction = Vector2.ZERO
		is_attacking = false
	else:
		aim_direction = direction.normalized()
		is_attacking = true
		
		# 计算瞄准世界坐标
		if _cached_player:
			aim_global_position = _cached_player.global_position + aim_direction * 200.0
			_cached_player.set_touch_aim_position(aim_global_position)
	
	aim_direction_changed.emit(aim_direction, aim_global_position)
	attack_state_changed.emit(is_attacking)
	
	# 更新玩家攻击状态
	if _cached_player and _cached_player.has_method("set_touch_firing"):
		_cached_player.set_touch_firing(is_attacking)


func _on_attack_joystick_released() -> void:
	"""
	攻击摇杆释放回调
	"""
	is_attacking = false
	aim_direction = Vector2.ZERO
	
	aim_direction_changed.emit(Vector2.ZERO, aim_global_position)
	attack_state_changed.emit(false)
	
	if _cached_player and _cached_player.has_method("set_touch_firing"):
		_cached_player.set_touch_firing(false)

# =============================================================================
# 信号回调 - 虚拟按钮
# =============================================================================

func _on_virtual_button_down(button_name: String) -> void:
	"""
	虚拟按钮按下回调
	"""
	if virtual_button_states.has(button_name):
		virtual_button_states[button_name]["pressed"] = true
		
		# 获取对应的动作
		var button_id: int = VirtualButton[button_name]
		if _virtual_button_config.has(button_id):
			var action: String = _virtual_button_config[button_id]["action"]
			simulate_action_press(action)
		
		virtual_button_pressed.emit(button_name)


func _on_virtual_button_up(button_name: String) -> void:
	"""
	虚拟按钮释放回调
	"""
	if virtual_button_states.has(button_name):
		virtual_button_states[button_name]["pressed"] = false
		
		# 获取对应的动作
		var button_id: int = VirtualButton[button_name]
		if _virtual_button_config.has(button_id):
			var action: String = _virtual_button_config[button_id]["action"]
			simulate_action_release(action)
		
		virtual_button_released.emit(button_name)

# =============================================================================
# 信号回调 - 手柄
# =============================================================================

func _on_joy_connection_changed(device_id: int, connected: bool) -> void:
	"""
	手柄连接状态改变回调
	"""
	if connected:
		print("[InputManager] 手柄连接: 设备 %d" % device_id)
		if current_device == InputDevice.KEYBOARD_MOUSE:
			_switch_device(InputDevice.GAMEPAD)
	else:
		print("[InputManager] 手柄断开: 设备 %d" % device_id)
		if current_device == InputDevice.GAMEPAD:
			# 切换回键鼠
			_switch_device(InputDevice.KEYBOARD_MOUSE)

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
		"current_device": InputDevice.keys()[current_device],
		"is_touch_mode": is_touch_mode,
		"has_touch_support": has_touch_support(),
		"gamepad_connected": is_gamepad_connected(),
		"move_direction": move_direction,
		"aim_direction": aim_direction,
		"is_attacking": is_attacking,
		"virtual_buttons": virtual_button_states.duplicate()
	}
