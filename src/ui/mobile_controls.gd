## Void Hunter - 移动端触摸控件
## 简化版：处理虚拟摇杆和技能按钮
class_name MobileControls
extends CanvasLayer

signal move_direction_changed(direction: Vector2)
signal attack_pressed()
signal dash_pressed()
signal skill_1_pressed()
signal skill_2_pressed()
signal skill_3_pressed()
signal skill_4_pressed()
signal item_1_pressed()
signal item_2_pressed()
signal item_3_pressed()

## 配置参数
@export var joystick_size: float = 140.0
@export var button_size: float = 70.0
@export var small_button_size: float = 50.0
@export var joystick_max_distance: float = 50.0

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
var _attack_button: Button = null
var _dash_button: Button = null
var _item_buttons: Array[Button] = []

## 是否可见
var _controls_visible: bool = true


func _ready() -> void:
	layer = 5  # 较低的层级，技能选择面板在更高层
	_create_ui()
	# 默认隐藏，只有在游戏开始时才显示
	hide_controls()


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

	# 创建摇杆 - 左下角
	_create_joystick(screen_size)

	# 创建技能按钮 - 右下角，4个按钮横向排列
	_create_skill_buttons(screen_size)

	# 创建攻击按钮 - 右侧中间位置
	_create_attack_button(screen_size)

	# 创建冲刺按钮 - 攻击按钮左边
	_create_dash_button(screen_size)

	# 道具按钮默认隐藏，只有拾取道具后才显示
	_create_item_buttons(screen_size)
	hide_item_buttons()

	print("[MobileControls] UI 创建完成, 屏幕尺寸: ", screen_size)


func _create_joystick(screen_size: Vector2) -> void:
	"""创建虚拟摇杆"""
	# 摇杆位置：左下角
	var margin := 80.0
	_joystick_center = Vector2(margin + joystick_size / 2, screen_size.y - margin - joystick_size / 2)

	# 摇杆底座
	_joystick_base = Control.new()
	_joystick_base.name = "JoystickBase"
	_joystick_base.custom_minimum_size = Vector2(joystick_size, joystick_size)
	_joystick_base.position = _joystick_center - Vector2(joystick_size / 2, joystick_size / 2)
	_joystick_base.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var base_style := StyleBoxFlat.new()
	base_style.bg_color = Color(0.1, 0.1, 0.25, 0.5)
	base_style.border_color = Color(0.3, 0.3, 0.5, 0.6)
	base_style.set_border_width_all(2)
	base_style.set_corner_radius_all(joystick_size / 2)
	_joystick_base.add_theme_stylebox_override("panel", base_style)
	_root.add_child(_joystick_base)

	# 摇杆手柄
	var knob_size := joystick_size * 0.35
	_joystick_knob = Control.new()
	_joystick_knob.name = "JoystickKnob"
	_joystick_knob.custom_minimum_size = Vector2(knob_size, knob_size)
	_joystick_knob.position = Vector2((joystick_size - knob_size) / 2, (joystick_size - knob_size) / 2)

	var knob_style := StyleBoxFlat.new()
	knob_style.bg_color = Color(1, 1, 1, 0.75)
	knob_style.set_corner_radius_all(knob_size / 2)
	_joystick_knob.add_theme_stylebox_override("panel", knob_style)
	_joystick_base.add_child(_joystick_knob)


func _create_skill_buttons(screen_size: Vector2) -> void:
	"""创建技能按钮 - 右下角4个按钮"""
	var margin_right := 20.0
	var margin_bottom := 20.0
	var spacing := 12.0
	var total_width := button_size * 4 + spacing * 3
	var start_x := screen_size.x - margin_right - total_width
	var btn_y := screen_size.y - margin_bottom - button_size

	for i in range(4):
		var btn := Button.new()
		btn.name = "Skill%dButton" % (i + 1)
		btn.custom_minimum_size = Vector2(button_size, button_size)
		btn.text = str(i + 1)
		btn.add_theme_font_size_override("font_size", 22)
		btn.position = Vector2(start_x + i * (button_size + spacing), btn_y)
		btn.mouse_filter = Control.MOUSE_FILTER_STOP

		# 按钮样式
		var btn_style := StyleBoxFlat.new()
		btn_style.bg_color = Color(0.15, 0.15, 0.35, 0.85)
		btn_style.border_color = Color(0.4, 0.4, 0.7)
		btn_style.set_border_width_all(2)
		btn_style.set_corner_radius_all(12)
		btn.add_theme_stylebox_override("normal", btn_style)

		var hover_style := StyleBoxFlat.new()
		hover_style.bg_color = Color(0.25, 0.25, 0.5, 0.9)
		hover_style.border_color = Color(0.5, 0.5, 0.8)
		hover_style.set_border_width_all(2)
		hover_style.set_corner_radius_all(12)
		btn.add_theme_stylebox_override("hover", hover_style)
		btn.add_theme_stylebox_override("pressed", hover_style)

		_root.add_child(btn)
		_skill_buttons.append(btn)

		var skill_num := i + 1
		btn.pressed.connect(_on_skill_button_pressed.bind(skill_num))


func _create_attack_button(screen_size: Vector2) -> void:
	"""创建攻击按钮 - 右侧中间偏下"""
	var margin_right := 30.0
	var margin_bottom := 100.0 + button_size + 20
	var btn_size := button_size * 1.1
	var btn_x := screen_size.x - margin_right - btn_size
	var btn_y := screen_size.y - margin_bottom - btn_size

	_attack_button = Button.new()
	_attack_button.name = "AttackButton"
	_attack_button.custom_minimum_size = Vector2(btn_size, btn_size)
	_attack_button.text = "⚔"
	_attack_button.add_theme_font_size_override("font_size", 26)
	_attack_button.position = Vector2(btn_x, btn_y)
	_attack_button.mouse_filter = Control.MOUSE_FILTER_STOP

	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(0.55, 0.15, 0.15, 0.85)
	btn_style.border_color = Color(0.8, 0.3, 0.3)
	btn_style.set_border_width_all(3)
	btn_style.set_corner_radius_all(btn_size / 2)
	_attack_button.add_theme_stylebox_override("normal", btn_style)

	var pressed_style := StyleBoxFlat.new()
	pressed_style.bg_color = Color(0.7, 0.25, 0.25, 0.95)
	pressed_style.border_color = Color(1.0, 0.4, 0.4)
	pressed_style.set_border_width_all(3)
	pressed_style.set_corner_radius_all(btn_size / 2)
	_attack_button.add_theme_stylebox_override("pressed", pressed_style)

	_root.add_child(_attack_button)
	_attack_button.pressed.connect(_on_attack_pressed)


func _create_dash_button(screen_size: Vector2) -> void:
	"""创建冲刺按钮 - 攻击按钮左边"""
	var margin_right := 120.0 + button_size * 1.1
	var margin_bottom := 100.0 + button_size + 10
	var btn_size := button_size * 0.85
	var btn_x := screen_size.x - margin_right - btn_size
	var btn_y := screen_size.y - margin_bottom - btn_size

	_dash_button = Button.new()
	_dash_button.name = "DashButton"
	_dash_button.custom_minimum_size = Vector2(btn_size, btn_size)
	_dash_button.text = "➤"
	_dash_button.add_theme_font_size_override("font_size", 22)
	_dash_button.position = Vector2(btn_x, btn_y)
	_dash_button.mouse_filter = Control.MOUSE_FILTER_STOP

	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(0.15, 0.35, 0.55, 0.85)
	btn_style.border_color = Color(0.3, 0.5, 0.7)
	btn_style.set_border_width_all(2)
	btn_style.set_corner_radius_all(btn_size / 2)
	_dash_button.add_theme_stylebox_override("normal", btn_style)

	var pressed_style := StyleBoxFlat.new()
	pressed_style.bg_color = Color(0.25, 0.45, 0.65, 0.95)
	pressed_style.border_color = Color(0.4, 0.6, 0.8)
	pressed_style.set_border_width_all(2)
	pressed_style.set_corner_radius_all(btn_size / 2)
	_dash_button.add_theme_stylebox_override("pressed", pressed_style)

	_root.add_child(_dash_button)
	_dash_button.pressed.connect(_on_dash_pressed)


func _create_item_buttons(screen_size: Vector2) -> void:
	"""创建道具按钮 - 左侧中间位置，默认隐藏"""
	var margin_left := 30.0
	var margin_bottom := 200.0
	var spacing := 10.0
	var btn_y := screen_size.y - margin_bottom - small_button_size

	for i in range(3):
		var btn := Button.new()
		btn.name = "Item%dButton" % (i + 1)
		btn.custom_minimum_size = Vector2(small_button_size, small_button_size)
		btn.text = str(i + 1)
		btn.add_theme_font_size_override("font_size", 16)
		btn.position = Vector2(margin_left + i * (small_button_size + spacing), btn_y)
		btn.mouse_filter = Control.MOUSE_FILTER_STOP

		var btn_style := StyleBoxFlat.new()
		btn_style.bg_color = Color(0.25, 0.45, 0.25, 0.85)
		btn_style.border_color = Color(0.4, 0.6, 0.4)
		btn_style.set_border_width_all(2)
		btn_style.set_corner_radius_all(10)
		btn.add_theme_stylebox_override("normal", btn_style)

		_root.add_child(btn)
		_item_buttons.append(btn)

		var item_num := i + 1
		btn.pressed.connect(_on_item_button_pressed.bind(item_num))


## 显示道具按钮
func show_item_buttons() -> void:
	"""显示道具按钮"""
	for btn in _item_buttons:
		if btn:
			btn.visible = true


## 隐藏道具按钮
func hide_item_buttons() -> void:
	"""隐藏道具按钮"""
	for btn in _item_buttons:
		if btn:
			btn.visible = false


## 更新道具按钮状态
func update_item_button(index: int, has_item: bool, icon: String = "") -> void:
	"""
	更新道具按钮状态
	@param index: 道具索引 (0-2)
	@param has_item: 是否有道具
	@param icon: 图标文字
	"""
	if index < 0 or index >= _item_buttons.size():
		return

	var btn: Button = _item_buttons[index]
	if btn:
		btn.visible = has_item
		if has_item and not icon.is_empty():
			btn.text = icon


## 隐藏所有控件
func hide_controls() -> void:
	"""隐藏所有控件"""
	if _root:
		_root.visible = false
	_controls_visible = false


## 显示所有控件
func show_controls() -> void:
	"""显示所有控件"""
	if _root:
		_root.visible = true
	_controls_visible = true


# =============================================================================
# 输入处理
# =============================================================================

func _input(event: InputEvent) -> void:
	if not _controls_visible:
		return

	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		_handle_touch_event(event)


func _handle_touch_event(event: InputEvent) -> void:
	var touch_pos: Vector2
	var touch_idx: int

	if event is InputEventScreenTouch:
		touch_pos = event.position
		touch_idx = event.index
	elif event is InputEventScreenDrag:
		touch_pos = event.position
		touch_idx = event.index
	else:
		return

	# 摇杆触摸处理
	if event is InputEventScreenTouch:
		if event.pressed:
			# 检查是否在摇杆区域内开始触摸
			if _joystick_base.get_rect().has_point(touch_pos):
				_joystick_touch_idx = touch_idx
				_is_joystick_active = true
		else:
			if touch_idx == _joystick_touch_idx:
				_joystick_touch_idx = -1
				_is_joystick_active = false
				_reset_joystick()

	if event is InputEventScreenDrag:
		if touch_idx == _joystick_touch_idx and _is_joystick_active:
			_update_joystick(touch_pos)


func _update_joystick(touch_pos: Vector2) -> void:
	var delta := touch_pos - _joystick_center
	var distance := delta.length()

	if distance > joystick_max_distance:
		delta = delta.normalized() * joystick_max_distance

	# 更新摇杆手柄位置
	var knob_size := joystick_size * 0.35
	_joystick_knob.position = Vector2(
		(joystick_size - knob_size) / 2 + delta.x,
		(joystick_size - knob_size) / 2 + delta.y
	)

	# 计算移动方向
	if distance > 5:
		_move_direction = delta.normalized()
	else:
		_move_direction = Vector2.ZERO

	move_direction_changed.emit(_move_direction)


func _reset_joystick() -> void:
	var knob_size := joystick_size * 0.35
	_joystick_knob.position = Vector2((joystick_size - knob_size) / 2, (joystick_size - knob_size) / 2)
	_move_direction = Vector2.ZERO
	move_direction_changed.emit(Vector2.ZERO)


# =============================================================================
# 信号回调
# =============================================================================

func _on_attack_pressed() -> void:
	attack_pressed.emit()
	print("[MobileControls] 攻击按钮按下")


func _on_dash_pressed() -> void:
	dash_pressed.emit()
	print("[MobileControls] 冲刺按钮按下")


func _on_skill_button_pressed(skill_num: int) -> void:
	print("[MobileControls] 技能 %d 按下" % skill_num)
	match skill_num:
		1: skill_1_pressed.emit()
		2: skill_2_pressed.emit()
		3: skill_3_pressed.emit()
		4: skill_4_pressed.emit()


func _on_item_button_pressed(item_num: int) -> void:
	print("[MobileControls] 道具 %d 按下" % item_num)
	match item_num:
		1: item_1_pressed.emit()
		2: item_2_pressed.emit()
		3: item_3_pressed.emit()