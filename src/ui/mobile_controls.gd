## Void Hunter - 移动端触摸控件
## 简化版：处理虚拟摇杆和技能按钮
class_name MobileControls
extends CanvasLayer

signal move_direction_changed(direction: Vector2)
signal skill_1_pressed()
signal skill_2_pressed()
signal skill_3_pressed()
signal skill_4_pressed()

## 配置参数
@export var joystick_size: float = 160.0
@export var button_size: float = 80.0
@export var joystick_max_distance: float = 60.0

## 玩家引用
var player: Node = null

## 移动方向
var _move_direction: Vector2 = Vector2.ZERO

## 摇杆状态
var _joystick_touch_idx: int = -1
var _joystick_center: Vector2 = Vector2.ZERO
var _is_joystick_active: bool = false

## UI 节点
var _root: Control = null
var _joystick_base: Control = null
var _joystick_knob: Control = null
var _skill_buttons: Array[Button] = []

## 是否可见
var _controls_visible: bool = true


func _ready() -> void:
	layer = 5  # 较低的层级，技能选择面板在更高层
	_create_ui()


func _create_ui() -> void:
	"""创建 UI 控件"""
	var screen_size := get_viewport().get_visible_rect().size
	if screen_size.y <= 0:
		screen_size = Vector2(1280, 720)
	
	# 创建根控件
	_root = Control.new()
	_root.name = "MobileControlsRoot"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	
	# 创建摇杆
	_create_joystick(screen_size)
	
	# 创建技能按钮
	_create_skill_buttons(screen_size)
	
	print("[MobileControls] UI 创建完成, 屏幕尺寸: ", screen_size)


func _create_joystick(screen_size: Vector2) -> void:
	"""创建虚拟摇杆"""
	# 摇杆位置：左下角
	var margin := 100.0
	_joystick_center = Vector2(margin + joystick_size / 2, screen_size.y - margin - joystick_size / 2)
	
	# 摇杆底座
	_joystick_base = Control.new()
	_joystick_base.name = "JoystickBase"
	_joystick_base.custom_minimum_size = Vector2(joystick_size, joystick_size)
	_joystick_base.position = _joystick_center - Vector2(joystick_size / 2, joystick_size / 2)
	_joystick_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var base_style := StyleBoxFlat.new()
	base_style.bg_color = Color(0.1, 0.1, 0.3, 0.6)
	base_style.border_color = Color(0.3, 0.3, 0.5, 0.8)
	base_style.set_border_width_all(3)
	base_style.set_corner_radius_all(joystick_size / 2)
	_joystick_base.add_theme_stylebox_override("panel", base_style)
	_root.add_child(_joystick_base)
	
	# 摇杆手柄
	var knob_size := joystick_size * 0.4
	_joystick_knob = Control.new()
	_joystick_knob.name = "JoystickKnob"
	_joystick_knob.custom_minimum_size = Vector2(knob_size, knob_size)
	_joystick_knob.position = Vector2((joystick_size - knob_size) / 2, (joystick_size - knob_size) / 2)
	
	var knob_style := StyleBoxFlat.new()
	knob_style.bg_color = Color(1, 1, 1, 0.85)
	knob_style.set_corner_radius_all(knob_size / 2)
	_joystick_knob.add_theme_stylebox_override("panel", knob_style)
	_joystick_base.add_child(_joystick_knob)


func _create_skill_buttons(screen_size: Vector2) -> void:
	"""创建技能按钮"""
	var margin := 100.0
	var spacing := 20.0
	var start_x := screen_size.x - margin - button_size * 4 - spacing * 3
	var btn_y := screen_size.y - margin - button_size
	
	for i in range(4):
		var btn := Button.new()
		btn.name = "Skill%dButton" % (i + 1)
		btn.custom_minimum_size = Vector2(button_size, button_size)
		btn.text = str(i + 1)
		btn.add_theme_font_size_override("font_size", 24)
		btn.position = Vector2(start_x + i * (button_size + spacing), btn_y)
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		
		# 按钮样式
		var btn_style := StyleBoxFlat.new()
		btn_style.bg_color = Color(0.2, 0.2, 0.4, 0.8)
		btn_style.border_color = Color(0.4, 0.4, 0.6)
		btn_style.set_border_width_all(2)
		btn_style.set_corner_radius_all(10)
		btn.add_theme_stylebox_override("normal", btn_style)
		
		var hover_style := StyleBoxFlat.new()
		hover_style.bg_color = Color(0.3, 0.3, 0.5, 0.9)
		hover_style.border_color = Color(0.6, 0.6, 0.8)
		hover_style.set_border_width_all(2)
		hover_style.set_corner_radius_all(10)
		btn.add_theme_stylebox_override("hover", hover_style)
		btn.add_theme_stylebox_override("pressed", hover_style)
		
		_root.add_child(btn)
		_skill_buttons.append(btn)
		
		var skill_num := i + 1
		btn.pressed.connect(_on_skill_button_pressed.bind(skill_num))


func _input(event: InputEvent) -> void:
	"""处理触摸输入"""
	if not _controls_visible:
		return
	
	if get_tree().paused:
		return
	
	# 处理摇杆触摸
	if event is InputEventScreenTouch:
		_handle_joystick_touch(event)
	elif event is InputEventScreenDrag:
		_handle_joystick_drag(event)


func _handle_joystick_touch(event: InputEventScreenTouch) -> void:
	"""处理摇杆触摸事件"""
	var touch_pos := event.position
	var dist_to_center := touch_pos.distance_to(_joystick_center)
	var touch_radius := joystick_size * 0.7  # 触摸检测范围
	
	if event.pressed:
		# 检查是否在摇杆区域内
		if dist_to_center <= touch_radius and _joystick_touch_idx == -1:
			_joystick_touch_idx = event.index
			_is_joystick_active = true
			_update_joystick(touch_pos)
			get_viewport().set_input_as_handled()
	else:
		# 触摸结束
		if event.index == _joystick_touch_idx:
			_joystick_touch_idx = -1
			_is_joystick_active = false
			_reset_joystick()
			get_viewport().set_input_as_handled()


func _handle_joystick_drag(event: InputEventScreenDrag) -> void:
	"""处理摇杆拖动事件"""
	if event.index == _joystick_touch_idx and _is_joystick_active:
		_update_joystick(event.position)
		get_viewport().set_input_as_handled()


func _update_joystick(touch_pos: Vector2) -> void:
	"""更新摇杆位置和方向"""
	var direction := touch_pos - _joystick_center
	var distance := direction.length()
	
	# 限制最大距离
	if distance > joystick_max_distance:
		direction = direction.normalized() * joystick_max_distance
		distance = joystick_max_distance
	
	# 计算归一化方向
	_move_direction = direction / joystick_max_distance if joystick_max_distance > 0 else Vector2.ZERO
	
	# 更新手柄位置
	if _joystick_knob:
		var knob_size := joystick_size * 0.4
		var base_offset := (joystick_size - knob_size) / 2
		_joystick_knob.position = Vector2(
			base_offset + direction.x,
			base_offset + direction.y
		)
	
	# 发送信号
	move_direction_changed.emit(_move_direction)
	
	# 更新玩家移动方向
	if player and is_instance_valid(player):
		player.mobile_move_direction = _move_direction


func _reset_joystick() -> void:
	"""重置摇杆"""
	_move_direction = Vector2.ZERO
	
	if _joystick_knob:
		var knob_size := joystick_size * 0.4
		var base_offset := (joystick_size - knob_size) / 2
		_joystick_knob.position = Vector2(base_offset, base_offset)
	
	move_direction_changed.emit(Vector2.ZERO)
	
	if player and is_instance_valid(player):
		player.mobile_move_direction = Vector2.ZERO


func _on_skill_button_pressed(skill_num: int) -> void:
	"""技能按钮点击"""
	print("[MobileControls] 技能 %d 按下" % skill_num)
	
	match skill_num:
		1: skill_1_pressed.emit()
		2: skill_2_pressed.emit()
		3: skill_3_pressed.emit()
		4: skill_4_pressed.emit()


# =============================================================================
# 公共方法
# =============================================================================

func set_player(p: Node) -> void:
	"""设置玩家引用"""
	player = p


func get_move_direction() -> Vector2:
	"""获取当前移动方向"""
	return _move_direction


func show_controls() -> void:
	"""显示控件"""
	_controls_visible = true
	if _root:
		_root.visible = true
		_root.mouse_filter = Control.MOUSE_FILTER_IGNORE


func hide_controls() -> void:
	"""隐藏控件"""
	_controls_visible = false
	if _root:
		_root.visible = false
		_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 重置摇杆状态
	_joystick_touch_idx = -1
	_is_joystick_active = false
	_reset_joystick()


func set_controls_visible(is_visible: bool) -> void:
	"""设置控件可见性"""
	if is_visible:
		show_controls()
	else:
		hide_controls()
