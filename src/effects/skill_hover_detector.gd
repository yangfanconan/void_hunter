## Void Hunter - 技能面板悬停检测器
## @description: 检测鼠标悬停并更新面板样式
## @author: Void Hunter Team
## @version: 1.0.0

extends Control

# =============================================================================
# 常量定义
# =============================================================================

## 悬停动画持续时间
const HOVER_TWEEN_DURATION: float = 0.15

## 悬停时缩放比例
const HOVER_SCALE: Vector2 = Vector2(1.03, 1.03)

# =============================================================================
# 私有变量
# =============================================================================

var _parent_panel: Control = null
var _is_hovered: bool = false
var _hover_tween: Tween = null

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""节点就绪时初始化"""
	# 设置为覆盖整个父节点区域
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_PASS
	
	# 获取父面板
	_parent_panel = get_parent()
	if _parent_panel == null:
		push_warning("[SkillHoverDetector] 没有找到父面板节点")


func _notification(what: int) -> void:
	"""处理通知"""
	match what:
		NOTIFICATION_MOUSE_ENTER:
			_on_mouse_entered()
		NOTIFICATION_MOUSE_EXIT:
			_on_mouse_exited()

# =============================================================================
# 私有方法
# =============================================================================

func _on_mouse_entered() -> void:
	"""鼠标进入时触发"""
	if _parent_panel == null:
		return
	
	_is_hovered = true
	
	# 应用悬停样式
	_apply_hover_style(true)
	
	# 播放悬停音效（可选）
	# AudioManager.play_sfx("hover")


func _on_mouse_exited() -> void:
	"""鼠标离开时触发"""
	if _parent_panel == null:
		return
	
	_is_hovered = false
	
	# 恢复默认样式
	_apply_hover_style(false)


func _apply_hover_style(is_hovered: bool) -> void:
	"""
	应用悬停样式
	@param is_hovered: 是否悬停
	"""
	if _parent_panel == null:
		return
	
	# 获取存储的样式颜色
	var original_bg: Color = _parent_panel.get_meta("original_bg_color", Color(0.15, 0.15, 0.2, 0.95))
	var original_border: Color = _parent_panel.get_meta("original_border_color", Color(0.3, 0.3, 0.4))
	var hover_bg: Color = _parent_panel.get_meta("hover_bg_color", Color(0.2, 0.2, 0.28, 0.98))
	var hover_border: Color = _parent_panel.get_meta("hover_border_color", Color(0.5, 0.5, 0.7))
	
	# 取消之前的动画
	if _hover_tween and _hover_tween.is_valid():
		_hover_tween.kill()
	
	# 创建新动画
	_hover_tween = _parent_panel.create_tween()
	_hover_tween.set_parallel(true)
	_hover_tween.set_ease(Tween.EASE_OUT)
	_hover_tween.set_trans(Tween.TRANS_QUAD)
	
	# 更新面板样式
	var style: StyleBoxFlat = _parent_panel.get_theme_stylebox("panel") as StyleBoxFlat
	if style:
		if is_hovered:
			_hover_tween.tween_property(style, "bg_color", hover_bg, HOVER_TWEEN_DURATION)
			_hover_tween.tween_property(style, "border_color", hover_border, HOVER_TWEEN_DURATION)
		else:
			_hover_tween.tween_property(style, "bg_color", original_bg, HOVER_TWEEN_DURATION)
			_hover_tween.tween_property(style, "border_color", original_border, HOVER_TWEEN_DURATION)
	
	# 缩放动画
	if is_hovered:
		_hover_tween.tween_property(_parent_panel, "scale", HOVER_SCALE, HOVER_TWEEN_DURATION)
	else:
		_hover_tween.tween_property(_parent_panel, "scale", Vector2.ONE, HOVER_TWEEN_DURATION)
	
	# 更新按钮样式
	var button: Button = _find_button()
	if button:
		if is_hovered:
			button.modulate = Color(1.1, 1.1, 1.0)
		else:
			button.modulate = Color.WHITE


func _find_button() -> Button:
	"""查找选择按钮"""
	if _parent_panel == null:
		return null
	
	var vbox: VBoxContainer = _parent_panel.find_child("VBoxContainer", true, false)
	if vbox == null:
		vbox = _parent_panel.get_child(0) as VBoxContainer
	
	if vbox == null:
		return null
	
	for child in vbox.get_children():
		if child is Button:
			return child
	
	return null


## 检查当前是否悬停
func is_hovered() -> bool:
	"""返回当前悬停状态"""
	return _is_hovered
