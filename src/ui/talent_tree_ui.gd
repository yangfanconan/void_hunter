## Void Hunter - 天赋树UI界面
## @description: 显示和操作永久天赋树
## @version: 1.0.0

extends Control
class_name TalentTreeUI

# =============================================================================
# 信号定义
# =============================================================================

signal talent_upgraded(talent_id: String)
signal close_requested()

# =============================================================================
# 常量定义
# =============================================================================

const BRANCH_NAMES := {
	0: "攻击",  # Branch.OFFENSE
	1: "防御",  # Branch.DEFENSE
	2: "辅助"   # Branch.UTILITY
}

const BRANCH_COLORS := {
	0: Color(0.9, 0.3, 0.3),  # Branch.OFFENSE
	1: Color(0.3, 0.6, 0.9),  # Branch.DEFENSE
	2: Color(0.9, 0.7, 0.3)   # Branch.UTILITY
}

# =============================================================================
# 私有变量
# =============================================================================

var _talent_tree: Node = null
var _current_branch: int = 0  # 0=OFFENSE, 1=DEFENSE, 2=UTILITY
var _talent_nodes: Dictionary = {}
var _bg: ColorRect
var _main_panel: PanelContainer
var _title_label: Label
var _points_label: Label
var _branch_tabs: HBoxContainer
var _branch_container: VBoxContainer
var _button_reset: Button
var _button_close: Button

# =============================================================================
# 生命周期
# =============================================================================

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_talent_tree = get_node_or_null("/root/PermanentTalentTree")
	if _talent_tree == null:
		# 尝试加载脚本并创建实例
		var talent_script = load("res://src/systems/permanent_talent_tree.gd")
		if talent_script:
			_talent_tree = Node.new()
			_talent_tree.set_script(talent_script)
			_talent_tree.name = "PermanentTalentTree"
			add_child(_talent_tree)

	_build_ui()
	_connect_signals()
	hide()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()

# =============================================================================
# UI构建
# =============================================================================

func _build_ui() -> void:
	# 背景
	_bg = ColorRect.new()
	_bg.color = Color(0, 0, 0, 0.8)
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)

	# 主面板 - 居中显示
	_main_panel = PanelContainer.new()
	_main_panel.custom_minimum_size = Vector2(800, 700)
	_main_panel.anchor_left = 0.5
	_main_panel.anchor_top = 0.5
	_main_panel.anchor_right = 0.5
	_main_panel.anchor_bottom = 0.5
	_main_panel.offset_left = -400
	_main_panel.offset_top = -350
	_main_panel.offset_right = 400
	_main_panel.offset_bottom = 350
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	style.border_color = Color(0.4, 0.35, 0.6)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	_main_panel.add_theme_stylebox_override("panel", style)
	add_child(_main_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 16)
	_main_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	# 标题行
	var title_row := HBoxContainer.new()
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(title_row)

	_title_label = Label.new()
	_title_label.text = "天赋树"
	_title_label.add_theme_font_size_override("font_size", 24)
	_title_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.75))
	title_row.add_child(_title_label)

	# 点数显示
	_points_label = Label.new()
	_points_label.text = "可用点数: 0"
	_points_label.add_theme_font_size_override("font_size", 16)
	_points_label.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))
	title_row.add_child(_points_label)

	var spacer := Control.new()
	spacer.custom_minimum_size.x = 50
	title_row.add_child(spacer)

	_button_reset = Button.new()
	_button_reset.text = "重置"
	_button_reset.custom_minimum_size = Vector2(80, 32)
	title_row.add_child(_button_reset)

	_button_close = Button.new()
	_button_close.text = "关闭"
	_button_close.custom_minimum_size = Vector2(80, 32)
	title_row.add_child(_button_close)

	# 分支标签
	_branch_tabs = HBoxContainer.new()
	_branch_tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	_branch_tabs.add_theme_constant_override("separation", 10)
	vbox.add_child(_branch_tabs)

	for branch in BRANCH_NAMES.keys():
		var btn := Button.new()
		btn.text = BRANCH_NAMES[branch]
		btn.custom_minimum_size = Vector2(100, 36)
		btn.set_meta("branch", branch)
		_branch_tabs.add_child(btn)

	# 分隔线
	var sep := HSeparator.new()
	vbox.add_child(sep)

	# 分支内容容器
	_branch_container = VBoxContainer.new()
	_branch_container.add_theme_constant_override("separation", 8)
	vbox.add_child(_branch_container)

	# 刷新显示
	_update_points_display()
	_select_branch(_current_branch)

func _connect_signals() -> void:
	if _button_reset:
		_button_reset.pressed.connect(_on_reset_pressed)
	if _button_close:
		_button_close.pressed.connect(_on_close_pressed)

	for btn in _branch_tabs.get_children():
		if btn.has_meta("branch"):
			btn.pressed.connect(_on_branch_tab_pressed.bind(btn.get_meta("branch")))

	if _talent_tree:
		_talent_tree.talent_points_changed.connect(_on_points_changed)
		_talent_tree.talent_upgraded.connect(_on_talent_upgraded_signal)

# =============================================================================
# 显示控制
# =============================================================================

func show_talent_tree() -> void:
	get_tree().paused = true
	_update_points_display()
	_select_branch(_current_branch)
	show()

func hide_talent_tree() -> void:
	get_tree().paused = false
	hide()

# =============================================================================
# 分支显示
# =============================================================================

func _select_branch(branch: int) -> void:
	_current_branch = branch

	# 更新标签样式
	for btn in _branch_tabs.get_children():
		if btn.has_meta("branch"):
			var btn_branch: int = btn.get_meta("branch")
			if btn_branch == branch:
				btn.modulate = BRANCH_COLORS[branch]
			else:
				btn.modulate = Color.WHITE

	# 清除现有节点
	for child in _branch_container.get_children():
		child.queue_free()
	_talent_nodes.clear()

	# 创建天赋节点
	var talents: Array = _talent_tree.get_talents_by_branch(branch)
	for talent in talents:
		var node := _create_talent_node(talent)
		_branch_container.add_child(node)
		_talent_nodes[talent.id] = node

func _create_talent_node(talent) -> Control:
	var panel_node := PanelContainer.new()
	panel_node.custom_minimum_size = Vector2(750, 50)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.9)
	style.set_corner_radius_all(6)
	panel_node.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	panel_node.add_child(hbox)

	# 名称
	var name_lbl := Label.new()
	name_lbl.text = talent.name
	name_lbl.custom_minimum_size.x = 120
	name_lbl.add_theme_font_size_override("font_size", 14)
	hbox.add_child(name_lbl)

	# 等级显示
	var level_lbl := Label.new()
	level_lbl.text = "Lv.%d/%d" % [talent.current_level, talent.max_level]
	level_lbl.custom_minimum_size.x = 60
	level_lbl.add_theme_font_size_override("font_size", 12)
	level_lbl.modulate = Color(0.6, 0.8, 1.0)
	hbox.add_child(level_lbl)

	# 效果显示
	var effect_lbl := Label.new()
	var current_effect: float = talent.get_current_effect()
	var next_effect: float = talent.get_next_level_effect()
	if talent.current_level > 0:
		effect_lbl.text = "+%.1f%%" % (current_effect * 100) if current_effect < 1.0 else "+%d" % int(current_effect)
	else:
		effect_lbl.text = ""
	if talent.current_level < talent.max_level:
		effect_lbl.text += " -> +%.1f%%" % (next_effect * 100) if next_effect < 1.0 else "-> +%d" % int(next_effect)
	effect_lbl.custom_minimum_size.x = 100
	effect_lbl.add_theme_font_size_override("font_size", 11)
	effect_lbl.modulate = Color(0.6, 0.9, 0.6)
	hbox.add_child(effect_lbl)

	# 描述
	var desc_lbl := Label.new()
	desc_lbl.text = talent.description
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_lbl.custom_minimum_size.x = 300
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.modulate = Color(0.7, 0.7, 0.7)
	hbox.add_child(desc_lbl)

	# 升级按钮
	var upgrade_btn := Button.new()
	upgrade_btn.text = "+" if talent.current_level < talent.max_level else "MAX"
	upgrade_btn.custom_minimum_size = Vector2(40, 32)
	upgrade_btn.disabled = not _talent_tree.can_upgrade_talent(talent.id)
	upgrade_btn.set_meta("talent_id", talent.id)
	upgrade_btn.pressed.connect(_on_upgrade_pressed.bind(talent.id))
	hbox.add_child(upgrade_btn)

	panel_node.set_meta("talent_id", talent.id)
	return panel_node

func _update_talent_node(talent_id: String) -> void:
	if not _talent_nodes.has(talent_id):
		return

	var talent: Resource = _talent_tree.get_talent(talent_id)
	if talent == null:
		return

	var node: Control = _talent_nodes[talent_id]
	var hbox: HBoxContainer = node.get_child(0)
	if hbox == null:
		return

	# 更新等级
	var level_lbl: Label = hbox.get_child(1)
	if level_lbl:
		level_lbl.text = "Lv.%d/%d" % [talent.current_level, talent.max_level]

	# 更新效果
	var effect_lbl: Label = hbox.get_child(2)
	if effect_lbl:
		var current_effect: float = talent.get_current_effect()
		var next_effect: float = talent.get_next_level_effect()
		if talent.current_level > 0:
			effect_lbl.text = "+%.1f%%" % (current_effect * 100) if current_effect < 1.0 else "+%d" % int(current_effect)
		else:
			effect_lbl.text = ""
		if talent.current_level < talent.max_level:
			effect_lbl.text += " -> +%.1f%%" % (next_effect * 100) if next_effect < 1.0 else "-> +%d" % int(next_effect)

	# 更新按钮
	var upgrade_btn: Button = hbox.get_child(4)
	if upgrade_btn:
		upgrade_btn.text = "+" if talent.current_level < talent.max_level else "MAX"
		upgrade_btn.disabled = not _talent_tree.can_upgrade_talent(talent.id)

	# 更新所有依赖此天赋的节点
	_update_all_nodes_availability()

func _update_all_nodes_availability() -> void:
	for talent_id in _talent_nodes:
		var node: Control = _talent_nodes[talent_id]
		var hbox: HBoxContainer = node.get_child(0)
		if hbox == null:
			continue
		var upgrade_btn: Button = hbox.get_child(4)
		if upgrade_btn:
			upgrade_btn.disabled = not _talent_tree.can_upgrade_talent(talent_id)

func _update_points_display() -> void:
	if _points_label and _talent_tree:
		_points_label.text = "可用点数: %d" % _talent_tree.talent_points

# =============================================================================
# 信号回调
# =============================================================================

func _on_branch_tab_pressed(branch: int) -> void:
	_select_branch(branch)

func _on_upgrade_pressed(talent_id: String) -> void:
	if _talent_tree and _talent_tree.upgrade_talent(talent_id):
		_update_talent_node(talent_id)
		talent_upgraded.emit(talent_id)

func _on_reset_pressed() -> void:
	if _talent_tree:
		_talent_tree.reset_all_talents()
		_select_branch(_current_branch)
		_update_points_display()

func _on_close_pressed() -> void:
	hide_talent_tree()
	close_requested.emit()

func _on_points_changed(points: int) -> void:
	_update_points_display()
	_update_all_nodes_availability()

func _on_talent_upgraded_signal(talent_id: String, new_level: int) -> void:
	if _current_branch == _talent_tree.get_talent(talent_id).branch:
		_update_talent_node(talent_id)