class_name VirtualJoystick
extends Control

signal joystick_moved(direction: Vector2)

@export var max_distance: float = 80.0
@export var dead_zone: float = 10.0

var _touch_index: int = -1
var _joystick_direction: Vector2 = Vector2.ZERO

@onready var _knob: Control = $Knob
@onready var _background: Control = $Background
@onready var _touch_area: Control = $TouchArea

func _ready() -> void:
	if not _knob:
		push_error("VirtualJoystick: 缺少 Knob 子节点")
		return
	if not _background:
		push_error("VirtualJoystick: 缺少 Background 子节点")
		return
	
	_knob.position = _background.position
	
	if not _touch_area:
		_touch_area = self
	
	_touch_area.gui_input.connect(_on_touch_area_gui_input)

func _on_touch_area_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			_touch_index = event.index
			_update_joystick_position(event.position)
		elif not event.pressed and event.index == _touch_index:
			_touch_index = -1
			_reset_joystick()
	
	elif event is InputEventScreenDrag:
		if event.index == _touch_index:
			_update_joystick_position(event.position)

func _update_joystick_position(touch_position: Vector2) -> void:
	var center: Vector2 = _background.position + _background.size / 2
	var direction: Vector2 = touch_position - center
	
	if direction.length() < dead_zone:
		direction = Vector2.ZERO
	else:
		direction = direction.normalized() * min(direction.length(), max_distance)
		direction = direction / max_distance
	
	_joystick_direction = direction
	_knob.position = center + direction * max_distance - _knob.size / 2
	
	joystick_moved.emit(_joystick_direction)
	
	if _joystick_direction.length_squared() > 0.01:
		var simulated_event := InputEventAction.new()
		Input.action_press("ui_up", _joystick_direction.y * -1)
		Input.action_press("ui_down", max(0, _joystick_direction.y))
		Input.action_press("ui_left", max(0, _joystick_direction.x * -1))
		Input.action_press("ui_right", max(0, _joystick_direction.x))

func _reset_joystick() -> void:
	_joystick_direction = Vector2.ZERO
	_knob.position = _background.position + _background.size / 2 - _knob.size / 2
	
	joystick_moved.emit(Vector2.ZERO)
	
	Input.action_release("ui_up")
	Input.action_release("ui_down")
	Input.action_release("ui_left")
	Input.action_release("ui_right")

func get_joystick_direction() -> Vector2:
	return _joystick_direction

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and not event.pressed:
		if event.index == _touch_index:
			_touch_index = -1
			_reset_joystick()
	
	elif event is InputEventScreenDrag:
		if event.index == _touch_index:
			_update_joystick_position(event.position)
