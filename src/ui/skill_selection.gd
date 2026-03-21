## Void Hunter - 技能选择界面
## @description: 升级时的技能选择界面，提供三个随机技能供选择
## @author: Void Hunter Team
## @version: 1.0.0

extends Control
class_name SkillSelection

# =============================================================================
# 信号定义
# =============================================================================

## 技能被选中时触发
signal skill_selected(skill_id: String)

## 选择被跳过时触发
signal selection_skipped()

## 组合技能被选中
signal combination_selected(combination_id: String)

# =============================================================================
# 常量定义
# =============================================================================

## 选项数量
const OPTION_COUNT: int = 3

## 技能类型图标路径
const SKILL_ICONS_PATH: String = "res://assets/icons/skills/"

# =============================================================================
# 节点引用
# =============================================================================

@onready var panel: PanelContainer = $Panel
@onready var margin_container: MarginContainer = $Panel/MarginContainer
@onready var vbox_main: VBoxContainer = $Panel/MarginContainer/VBoxContainer
@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var option_container: HBoxContainer = $Panel/MarginContainer/VBoxContainer/OptionContainer
@onready var hint_container: VBoxContainer = $Panel/MarginContainer/VBoxContainer/HintContainer
@onready var button_skip: Button = $Panel/MarginContainer/VBoxContainer/ButtonSkip
@onready var hotkey_display: HBoxContainer = $Panel/MarginContainer/VBoxContainer/HotkeyDisplay

# =============================================================================
# 公共变量
# =============================================================================

## 当前可选技能列表
var available_skills: Array[Dictionary] = []

## 当前显示的选项
var current_options: Array[Dictionary] = []

## 技能管理器引用
var skill_manager: SkillManager = null

## 当前激活的组合提示
var combination_hints: Array[Dictionary] = []

# =============================================================================
# 私有变量
# =============================================================================

var _option_panels: Array[Control] = []
var _is_combination_mode: bool = false

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""
	节点就绪时初始化技能选择界面
	"""
	_initialize_skill_selection()
	_connect_signals()


func _input(event: InputEvent) -> void:
	"""
	处理输入事件
	"""
	if not visible:
		return
	
	# 数字键快速选择
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("skill_1"):
		if _option_panels.size() > 0 and _option_panels[0].visible:
			_on_option_selected(0)
	elif event.is_action_pressed("skill_2"):
		if _option_panels.size() > 1 and _option_panels[1].visible:
			_on_option_selected(1)
	elif event.is_action_pressed("skill_3"):
		if _option_panels.size() > 2 and _option_panels[2].visible:
			_on_option_selected(2)
	elif event.is_action_pressed("ui_cancel"):
		_on_skip_pressed()

# =============================================================================
# 公共方法
# =============================================================================

## 显示技能选择
func show_skill_selection(skills: Array[Dictionary] = []) -> void:
	"""
	显示技能选择界面
	@param skills: 可选技能列表（为空则随机生成）
	"""
	_is_combination_mode = false
	
	# 设置游戏状态
	GameManager.set_game_state(GameManager.GameState.SKILL_SELECTION)
	
	# 暂停游戏
	get_tree().paused = true
	
	# 生成选项
	if skills.is_empty():
		current_options = _generate_random_options()
	else:
		current_options = skills
	
	# 更新显示
	_update_options_display()
	
	# 更新组合提示
	_update_combination_hints()
	
	# 更新标题
	title_label.text = "选择技能升级"
	
	show()


## 显示组合技能选择
func show_combination_selection(combinations: Array[Dictionary]) -> void:
	"""
	显示组合技能选择界面
	@param combinations: 可选组合列表
	"""
	_is_combination_mode = true
	
	# 设置游戏状态
	GameManager.set_game_state(GameManager.GameState.SKILL_SELECTION)
	
	# 暂停游戏
	get_tree().paused = true
	
	current_options = combinations
	
	# 更新显示
	_update_options_display(is_combination = true)
	
	# 隐藏组合提示
	hint_container.hide()
	
	# 更新标题
	title_label.text = "选择组合技能"
	
	show()


## 隐藏技能选择
func hide_skill_selection() -> void:
	"""
	隐藏技能选择界面
	"""
	hide()
	
	# 恢复游戏
	get_tree().paused = false
	GameManager.set_game_state(GameManager.GameState.PLAYING)


## 设置可选技能池
func set_available_skills(skills: Array[Dictionary]) -> void:
	"""
	设置可选技能池
	@param skills: 技能数据数组
	"""
	available_skills = skills


## 设置技能管理器引用
func set_skill_manager(manager: SkillManager) -> void:
	"""
	设置技能管理器引用
	@param manager: 技能管理器
	"""
	skill_manager = manager


# =============================================================================
# 私有方法 - 初始化
# =============================================================================

func _initialize_skill_selection() -> void:
	"""
	初始化技能选择界面
	"""
	# 创建选项面板
	_create_option_panels()
	
	# 创建快捷键显示
	_create_hotkey_display()
	
	# 隐藏界面
	hide()


func _connect_signals() -> void:
	"""
	连接信号
	"""
	button_skip.pressed.connect(_on_skip_pressed)


func _create_option_panels() -> void:
	"""
	创建技能选项面板
	"""
	# 清除现有面板
	for panel_node in _option_panels:
		panel_node.queue_free()
	_option_panels.clear()
	
	# 创建新面板
	for i in range(OPTION_COUNT):
		var panel_node: Control = _create_option_panel(i)
		option_container.add_child(panel_node)
		_option_panels.append(panel_node)


func _create_option_panel(index: int) -> Control:
	"""
	创建单个技能选项面板
	@param index: 选项索引
	@return: 面板控件
	"""
	var panel_node: PanelContainer = PanelContainer.new()
	panel_node.custom_minimum_size = Vector2(220, 350)
	panel_node.name = "OptionPanel_%d" % index
	
	# 添加样式
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.95)
	style.border_color = Color(0.3, 0.3, 0.4)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	panel_node.add_theme_stylebox_override("panel", style)
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel_node.add_child(vbox)
	
	# 快捷键提示
	var hotkey_label: Label = Label.new()
	hotkey_label.name = "HotkeyLabel"
	hotkey_label.text = "[%d]" % (index + 1)
	hotkey_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hotkey_label.add_theme_font_size_override("font_size", 14)
	hotkey_label.modulate = Color(0.7, 0.7, 0.8)
	vbox.add_child(hotkey_label)
	
	# 技能图标容器
	var icon_container: CenterContainer = CenterContainer.new()
	vbox.add_child(icon_container)
	
	# 技能图标
	var icon: TextureRect = TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(96, 96)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_container.add_child(icon)
	
	# 技能名称
	var name_label: Label = Label.new()
	name_label.name = "NameLabel"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	vbox.add_child(name_label)
	
	# 技能等级（如果是升级）
	var level_label: Label = Label.new()
	level_label.name = "LevelLabel"
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", 14)
	level_label.modulate = Color(0.6, 0.8, 1.0)
	vbox.add_child(level_label)
	
	# 技能类型标签
	var type_container: HBoxContainer = HBoxContainer.new()
	type_container.name = "TypeContainer"
	type_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(type_container)
	
	var category_label: Label = Label.new()
	category_label.name = "CategoryLabel"
	category_label.add_theme_font_size_override("font_size", 12)
	type_container.add_child(category_label)
	
	var element_label: Label = Label.new()
	element_label.name = "ElementLabel"
	element_label.add_theme_font_size_override("font_size", 12)
	type_container.add_child(element_label)
	
	# 分隔线
	var separator: HSeparator = HSeparator.new()
	vbox.add_child(separator)
	
	# 技能描述
	var desc_label: Label = Label.new()
	desc_label.name = "DescLabel"
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(desc_label)
	
	# 属性信息
	var stats_label: Label = Label.new()
	stats_label.name = "StatsLabel"
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	stats_label.add_theme_font_size_override("font_size", 11)
	stats_label.modulate = Color(0.7, 0.9, 0.7)
	vbox.add_child(stats_label)
	
	# 选择按钮
	var button: Button = Button.new()
	button.name = "SelectButton"
	button.text = "选择"
	button.custom_minimum_size.y = 40
	button.pressed.connect(_on_option_selected.bind(index))
	vbox.add_child(button)
	
	return panel_node


func _create_hotkey_display() -> void:
	"""
	创建快捷键显示
	"""
	if hotkey_display == null:
		return
	
	# 清空现有内容
	for child in hotkey_display.get_children():
		child.queue_free()
	
	# 添加提示
	var hint: Label = Label.new()
	hint.text = "快捷键: [1] [2] [3] 选择  |  [ESC] 跳过"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.modulate = Color(0.6, 0.6, 0.6)
	hotkey_display.add_child(hint)


# =============================================================================
# 私有方法 - 选项生成
# =============================================================================

func _generate_random_options() -> Array[Dictionary]:
	"""
	生成随机技能选项
	@return: 技能选项数组
	"""
	var options: Array[Dictionary] = []
	
	# 如果没有可用技能池，使用默认技能
	if available_skills.is_empty():
		available_skills = _get_default_skills()
	
	# 分离新技能和可升级技能
	var new_skills: Array[Dictionary] = []
	var upgrade_skills: Array[Dictionary] = []
	
	for skill in available_skills:
		if skill.get("is_owned", false):
			upgrade_skills.append(skill)
		else:
			new_skills.append(skill)
	
	# 随机打乱
	new_skills.shuffle()
	upgrade_skills.shuffle()
	
	# 优先选择新技能（最多2个）
	var new_count: int = mini(2, new_skills.size())
	for i in range(new_count):
		options.append(new_skills[i])
	
	# 填充升级技能
	while options.size() < OPTION_COUNT and upgrade_skills.size() > 0:
		var idx: int = options.size() - new_count
		if idx < upgrade_skills.size():
			options.append(upgrade_skills[idx])
		else:
			break
	
	# 如果还是不足，从新技能补充
	while options.size() < OPTION_COUNT and options.size() < new_skills.size():
		options.append(new_skills[options.size()])
	
	# 如果不足3个，用空选项填充
	while options.size() < OPTION_COUNT:
		options.append({})
	
	return options


func _get_default_skills() -> Array[Dictionary]:
	"""
	获取默认技能列表
	@return: 默认技能数组
	"""
	return [
		{
			"id": "fire_bullet",
			"name": "火焰弹",
			"description": "发射火焰弹，造成燃烧伤害。",
			"type": "ACTIVE",
			"category": "OFFENSIVE",
			"element": "FIRE",
			"damage": 25,
			"cooldown": 2.5,
			"mana_cost": 15,
			"is_owned": false
		},
		{
			"id": "frost_arrow",
			"name": "冰霜箭",
			"description": "发射冰霜箭，减速敌人。",
			"type": "ACTIVE",
			"category": "OFFENSIVE",
			"element": "ICE",
			"damage": 20,
			"cooldown": 3.0,
			"mana_cost": 18,
			"is_owned": false
		},
		{
			"id": "lightning_chain",
			"name": "闪电链",
			"description": "连锁攻击多个敌人。",
			"type": "ACTIVE",
			"category": "OFFENSIVE",
			"element": "LIGHTNING",
			"damage": 30,
			"cooldown": 4.0,
			"mana_cost": 25,
			"is_owned": false
		},
		{
			"id": "shadow_slash",
			"name": "暗影斩",
			"description": "穿透敌人的暗影刃。",
			"type": "ACTIVE",
			"category": "OFFENSIVE",
			"element": "SHADOW",
			"damage": 35,
			"cooldown": 3.5,
			"mana_cost": 22,
			"is_owned": false
		},
		{
			"id": "shield",
			"name": "魔法护盾",
			"description": "生成临时护盾。",
			"type": "ACTIVE",
			"category": "DEFENSIVE",
			"element": "ARCANE",
			"cooldown": 12.0,
			"mana_cost": 30,
			"is_owned": false
		},
		{
			"id": "blink",
			"name": "闪现",
			"description": "瞬移到目标位置。",
			"type": "ACTIVE",
			"category": "DEFENSIVE",
			"element": "ARCANE",
			"cooldown": 8.0,
			"mana_cost": 20,
			"is_owned": false
		},
		{
			"id": "iron_wall",
			"name": "铁壁",
			"description": "短时间大幅提升防御。",
			"type": "ACTIVE",
			"category": "DEFENSIVE",
			"element": "PHYSICAL",
			"cooldown": 15.0,
			"mana_cost": 35,
			"is_owned": false
		},
		{
			"id": "reflect",
			"name": "反射",
			"description": "反弹敌人子弹。",
			"type": "ACTIVE",
			"category": "DEFENSIVE",
			"element": "ARCANE",
			"cooldown": 12.0,
			"mana_cost": 25,
			"is_owned": false
		},
		{
			"id": "time_slow",
			"name": "时间减缓",
			"description": "减缓周围敌人速度。",
			"type": "ACTIVE",
			"category": "CONTROL",
			"element": "ARCANE",
			"cooldown": 18.0,
			"mana_cost": 40,
			"is_owned": false
		},
		{
			"id": "gravity_field",
			"name": "引力场",
			"description": "将敌人吸向中心。",
			"type": "ACTIVE",
			"category": "CONTROL",
			"element": "ARCANE",
			"cooldown": 14.0,
			"mana_cost": 35,
			"is_owned": false
		},
		{
			"id": "healing_aura",
			"name": "治愈光环",
			"description": "持续恢复生命。",
			"type": "PASSIVE",
			"category": "SUPPORT",
			"element": "HOLY",
			"is_owned": false
		},
		{
			"id": "speed_aura",
			"name": "加速光环",
			"description": "提升移动和攻击速度。",
			"type": "PASSIVE",
			"category": "SUPPORT",
			"element": "HOLY",
			"is_owned": false
		}
	]


# =============================================================================
# 私有方法 - 显示更新
# =============================================================================

func _update_options_display(is_combination: bool = false) -> void:
	"""
	更新选项显示
	@param is_combination: 是否是组合技能模式
	"""
	for i in range(_option_panels.size()):
		var panel_node: Control = _option_panels[i]
		var option: Dictionary = current_options[i] if i < current_options.size() else {}
		
		if is_combination:
			_update_combination_panel(panel_node, option)
		else:
			_update_option_panel(panel_node, option)


func _update_option_panel(panel_node: Control, option: Dictionary) -> void:
	"""
	更新单个技能选项面板
	@param panel_node: 面板控件
	@param option: 选项数据
	"""
	var icon: TextureRect = panel_node.get_node("Icon")
	var name_label: Label = panel_node.get_node("NameLabel")
	var level_label: Label = panel_node.get_node("LevelLabel")
	var category_label: Label = panel_node.get_node("CategoryLabel")
	var element_label: Label = panel_node.get_node("ElementLabel")
	var desc_label: Label = panel_node.get_node("DescLabel")
	var stats_label: Label = panel_node.get_node("StatsLabel")
	var button: Button = panel_node.get_node_or_null("SelectButton")
	
	if option.is_empty():
		panel_node.hide()
		return
	
	panel_node.show()
	
	# 更新图标
	if icon:
		var icon_path: String = SKILL_ICONS_PATH + option.get("id", "") + ".png"
		if ResourceLoader.exists(icon_path):
			icon.texture = load(icon_path)
		else:
			# 使用默认图标
			icon.texture = null
	
	# 更新名称
	if name_label:
		name_label.text = option.get("name", "Unknown")
	
	# 更新等级显示
	if level_label:
		var is_owned: bool = option.get("is_owned", false)
		var current_level: int = option.get("level", 1)
		if is_owned:
			level_label.text = "Lv.%d -> Lv.%d" % [current_level, current_level + 1]
			level_label.show()
		else:
			level_label.text = "新技能"
			level_label.show()
	
	# 更新类型标签
	if category_label:
		category_label.text = _get_category_display_name(option.get("category", ""))
		category_label.modulate = _get_category_color(option.get("category", ""))
	
	if element_label:
		element_label.text = _get_element_display_name(option.get("element", ""))
		element_label.modulate = _get_element_color(option.get("element", ""))
	
	# 更新描述
	if desc_label:
		desc_label.text = option.get("description", "")
	
	# 更新属性信息
	if stats_label:
		var stats_text: String = ""
		if option.has("damage"):
			stats_text += "伤害: %d  " % option.damage
		if option.has("cooldown"):
			stats_text += "冷却: %.1fs  " % option.cooldown
		if option.has("mana_cost"):
			stats_text += "法力: %d" % option.mana_cost
		stats_label.text = stats_text
	
	# 更新按钮
	if button:
		button.disabled = false
		button.text = "选择" if not option.get("is_owned", false) else "升级"


func _update_combination_panel(panel_node: Control, option: Dictionary) -> void:
	"""
	更新组合技能选项面板
	@param panel_node: 面板控件
	@param option: 组合数据
	"""
	var icon: TextureRect = panel_node.get_node("Icon")
	var name_label: Label = panel_node.get_node("NameLabel")
	var level_label: Label = panel_node.get_node("LevelLabel")
	var category_label: Label = panel_node.get_node("CategoryLabel")
	var element_label: Label = panel_node.get_node("ElementLabel")
	var desc_label: Label = panel_node.get_node("DescLabel")
	var stats_label: Label = panel_node.get_node("StatsLabel")
	var button: Button = panel_node.get_node_or_null("SelectButton")
	
	if option.is_empty():
		panel_node.hide()
		return
	
	panel_node.show()
	
	# 更新名称
	if name_label:
		name_label.text = option.get("name", "Unknown")
	
	# 更新等级显示
	if level_label:
		level_label.text = "组合技能"
		level_label.show()
	
	# 更新类型标签
	if category_label:
		category_label.text = "组合"
		category_label.modulate = Color(1.0, 0.8, 0.2)
	
	if element_label:
		element_label.text = ""
	
	# 更新描述
	if desc_label:
		desc_label.text = option.get("description", "")
	
	# 更新属性信息
	if stats_label:
		var bonuses: Dictionary = option.get("bonuses", {})
		var bonus_text: String = ""
		for stat in bonuses.keys():
			bonus_text += "%s: +%.0f%%  " % [stat, bonuses[stat] * 100]
		stats_label.text = bonus_text
	
	# 更新按钮
	if button:
		button.disabled = false
		button.text = "激活"


func _update_combination_hints() -> void:
	"""
	更新组合提示
	"""
	if hint_container == null:
		return
	
	# 清空现有提示
	for child in hint_container.get_children():
		child.queue_free()
	
	# 获取组合提示
	if skill_manager and skill_manager.skill_combinations:
		combination_hints = skill_manager.skill_combinations.get_combination_hints()
	
	if combination_hints.is_empty():
		hint_container.hide()
		return
	
	hint_container.show()
	
	# 添加提示标题
	var title: Label = Label.new()
	title.text = "可解锁的组合:"
	title.modulate = Color(0.8, 0.7, 0.4)
	hint_container.add_child(title)
	
	# 添加每个提示
	for hint in combination_hints:
		var hint_label: Label = Label.new()
		hint_label.text = "- %s (需要: %d/%d)" % [
			hint.get("name", ""),
			hint.get("owned_count", 0),
			hint.get("required_count", 2)
		]
		hint_label.modulate = Color(0.6, 0.6, 0.7)
		hint_label.add_theme_font_size_override("font_size", 11)
		hint_container.add_child(hint_label)


# =============================================================================
# 辅助方法
# =============================================================================

func _get_category_display_name(category: String) -> String:
	"""
	获取类别显示名称
	"""
	match category:
		"OFFENSIVE": return "攻击"
		"DEFENSIVE": return "防御"
		"CONTROL": return "控制"
		"SUPPORT": return "辅助"
		_: return category


func _get_category_color(category: String) -> Color:
	"""
	获取类别颜色
	"""
	match category:
		"OFFENSIVE": return Color(1.0, 0.4, 0.4)
		"DEFENSIVE": return Color(0.4, 0.7, 1.0)
		"CONTROL": return Color(0.7, 0.4, 1.0)
		"SUPPORT": return Color(0.4, 1.0, 0.6)
		_: return Color(0.7, 0.7, 0.7)


func _get_element_display_name(element: String) -> String:
	"""
	获取元素显示名称
	"""
	match element:
		"FIRE": return "火焰"
		"ICE": return "冰霜"
		"LIGHTNING": return "闪电"
		"SHADOW": return "暗影"
		"HOLY": return "神圣"
		"ARCANE": return "奥术"
		"PHYSICAL": return "物理"
		_: return element


func _get_element_color(element: String) -> Color:
	"""
	获取元素颜色
	"""
	match element:
		"FIRE": return Color(1.0, 0.5, 0.2)
		"ICE": return Color(0.5, 0.8, 1.0)
		"LIGHTNING": return Color(1.0, 1.0, 0.4)
		"SHADOW": return Color(0.5, 0.3, 0.8)
		"HOLY": return Color(1.0, 1.0, 0.8)
		"ARCANE": return Color(0.7, 0.4, 1.0)
		"PHYSICAL": return Color(0.7, 0.7, 0.7)
		_: return Color(0.5, 0.5, 0.5)


# =============================================================================
# 信号回调
# =============================================================================

func _on_option_selected(index: int) -> void:
	"""
	选项被选中
	@param index: 选项索引
	"""
	if index < 0 or index >= current_options.size():
		return
	
	var selected_option: Dictionary = current_options[index]
	if selected_option.is_empty():
		return
	
	AudioManager.play_ui_sound("skill_select")
	AudioManager.play_sfx("level_up")
	
	if _is_combination_mode:
		combination_selected.emit(selected_option.get("combination_id", ""))
	else:
		skill_selected.emit(selected_option.get("id", ""))
	
	hide_skill_selection()


func _on_skip_pressed() -> void:
	"""
	跳过按钮按下
	"""
	AudioManager.play_ui_sound("button_click")
	selection_skipped.emit()
	hide_skill_selection()
