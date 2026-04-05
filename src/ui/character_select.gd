## Void Hunter - 角色选择界面
## @description: 显示所有角色、解锁条件、属性预览和被动技能说明
## @author: Void Hunter Team
## @version: 1.0.0

extends Control
class_name CharacterSelect

# =============================================================================
# 信号定义
# =============================================================================

## 角色被选中时触发
signal character_selected(character_id: String)

## 返回按钮被按下
signal back_pressed()

# =============================================================================
# 常量定义
# =============================================================================

## 每行显示的角色数量
const CHARACTERS_PER_ROW: int = 5

## 卡片间距
const CARD_SPACING: int = 12

## 动画持续时间
const ANIMATION_DURATION: float = 0.3

## 卡片尺寸
const CARD_WIDTH: int = 140
const CARD_HEIGHT: int = 180

# =============================================================================
# 导出变量
# =============================================================================

## 卡片容器
@export var card_container: GridContainer

## 角色详情面板
@export var detail_panel: PanelContainer

## 角色名称标签
@export var name_label: Label

## 角色类型标签
@export var type_label: Label

## 角色描述标签
@export var description_label: Label

## 属性显示容器
@export var stats_container: VBoxContainer

## 被动技能名称标签
@export var passive_name_label: Label

## 被动技能描述标签
@export var passive_desc_label: Label

## 解锁条件标签
@export var unlock_condition_label: Label

## 解锁进度条
@export var unlock_progress_bar: ProgressBar

## 选择按钮
@export var select_button: Button

## 返回按钮
@export var back_button: Button

## 角色立绘显示区域
@export var portrait_display: TextureRect

## 角色图标显示区域
@export var icon_display: TextureRect

## 角色等级标签
@export var level_label: Label

## 角色经验条
@export var exp_progress_bar: ProgressBar

## 角色通关次数标签
@export var clear_count_label: Label

# =============================================================================
# 公共变量
# =============================================================================

## 当前选中的角色ID
var selected_character_id: String = ""

## 角色卡片字典
var character_cards: Dictionary = {}

## 是否正在显示解锁动画
var is_showing_unlock_animation: bool = false

# =============================================================================
# 私有变量
# =============================================================================

var _challenge_system: ChallengeSystem = null
var _tween: Tween = null

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	_build_full_ui()
	_connect_signals()
	_initialize_character_grid()


func _enter_tree() -> void:
	# 获取挑战系统引用
	_challenge_system = ChallengeSystem.get_instance()
	if _challenge_system:
		_connect_challenge_signals()


func _exit_tree() -> void:
	if _challenge_system:
		_disconnect_challenge_signals()

# =============================================================================
# 公共方法 - 初始化
# =============================================================================

## 构建完整UI
func _build_full_ui() -> void:
	"""构建完整的角色选择UI"""
	print("[CharacterSelect] 开始构建UI")

	# 背景
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0.05, 0.05, 0.1, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.z_index = -1
	add_child(bg)

	# 主容器 - 使用 MarginContainer 包裹
	var margin = MarginContainer.new()
	margin.name = "MainMargin"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	# 主容器
	var main_hbox = HBoxContainer.new()
	main_hbox.name = "MainContainer"
	main_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_hbox.add_theme_constant_override("separation", 20)
	margin.add_child(main_hbox)

	# 左侧：角色网格
	var left_panel = PanelContainer.new()
	left_panel.name = "LeftPanel"
	left_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var left_style = StyleBoxFlat.new()
	left_style.bg_color = Color(0.12, 0.12, 0.18, 1.0)
	left_style.set_corner_radius_all(8)
	left_panel.add_theme_stylebox_override("panel", left_style)
	main_hbox.add_child(left_panel)

	var left_margin = MarginContainer.new()
	left_margin.add_theme_constant_override("margin_left", 15)
	left_margin.add_theme_constant_override("margin_right", 15)
	left_margin.add_theme_constant_override("margin_top", 15)
	left_margin.add_theme_constant_override("margin_bottom", 15)
	left_panel.add_child(left_margin)

	var left_vbox = VBoxContainer.new()
	left_vbox.add_theme_constant_override("separation", 15)
	left_margin.add_child(left_vbox)

	# 标题
	var title = Label.new()
	title.text = "选择角色"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
	left_vbox.add_child(title)

	# 分隔线
	var sep = HSeparator.new()
	sep.custom_minimum_size.y = 10
	left_vbox.add_child(sep)

	# 角色网格容器
	card_container = GridContainer.new()
	card_container.name = "CharacterGrid"
	card_container.columns = CHARACTERS_PER_ROW
	card_container.add_theme_constant_override("h_separation", CARD_SPACING)
	card_container.add_theme_constant_override("v_separation", CARD_SPACING)
	card_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vbox.add_child(card_container)

	# 右侧：详情面板
	detail_panel = PanelContainer.new()
	detail_panel.name = "DetailPanel"
	detail_panel.custom_minimum_size = Vector2(320, 0)
	detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var right_style = StyleBoxFlat.new()
	right_style.bg_color = Color(0.12, 0.12, 0.18, 1.0)
	right_style.set_corner_radius_all(8)
	detail_panel.add_theme_stylebox_override("panel", right_style)
	main_hbox.add_child(detail_panel)

	var detail_margin = MarginContainer.new()
	detail_margin.add_theme_constant_override("margin_left", 15)
	detail_margin.add_theme_constant_override("margin_right", 15)
	detail_margin.add_theme_constant_override("margin_top", 15)
	detail_margin.add_theme_constant_override("margin_bottom", 15)
	detail_panel.add_child(detail_margin)

	var detail_vbox = VBoxContainer.new()
	detail_vbox.add_theme_constant_override("separation", 12)
	detail_margin.add_child(detail_vbox)

	# 角色名称
	name_label = Label.new()
	name_label.text = "角色名称"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
	detail_vbox.add_child(name_label)

	# 角色类型
	type_label = Label.new()
	type_label.text = "类型"
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_label.add_theme_font_size_override("font_size", 14)
	type_label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	detail_vbox.add_child(type_label)

	# 分隔线
	var sep2 = HSeparator.new()
	detail_vbox.add_child(sep2)

	# 角色描述
	description_label = Label.new()
	description_label.text = "角色描述"
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	description_label.add_theme_font_size_override("font_size", 13)
	description_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	detail_vbox.add_child(description_label)

	# 被动技能名称
	passive_name_label = Label.new()
	passive_name_label.text = "被动技能"
	passive_name_label.add_theme_font_size_override("font_size", 14)
	passive_name_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.4))
	detail_vbox.add_child(passive_name_label)

	# 被动技能描述
	passive_desc_label = Label.new()
	passive_desc_label.text = "被动技能描述"
	passive_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	passive_desc_label.add_theme_font_size_override("font_size", 12)
	passive_desc_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	detail_vbox.add_child(passive_desc_label)

	# 分隔线
	var sep3 = HSeparator.new()
	detail_vbox.add_child(sep3)

	# 解锁条件
	unlock_condition_label = Label.new()
	unlock_condition_label.text = "解锁条件"
	unlock_condition_label.add_theme_font_size_override("font_size", 12)
	detail_vbox.add_child(unlock_condition_label)

	# 属性容器
	stats_container = VBoxContainer.new()
	stats_container.name = "StatsContainer"
	stats_container.add_theme_constant_override("separation", 5)
	detail_vbox.add_child(stats_container)

	# 填充空间
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_vbox.add_child(spacer)

	# 按钮容器
	var btn_container = HBoxContainer.new()
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_container.add_theme_constant_override("separation", 20)
	detail_vbox.add_child(btn_container)

	# 返回按钮
	back_button = Button.new()
	back_button.text = "返回"
	back_button.custom_minimum_size = Vector2(100, 40)
	btn_container.add_child(back_button)

	# 选择按钮
	select_button = Button.new()
	select_button.text = "选择角色"
	select_button.custom_minimum_size = Vector2(120, 40)
	btn_container.add_child(select_button)

	print("[CharacterSelect] UI构建完成")


## 设置UI
func _setup_ui() -> void:
	"""初始化UI组件"""
	# UI已在_build_full_ui中创建
	if select_button:
		select_button.text = "选择角色"
		select_button.disabled = true

	if back_button:
		back_button.text = "返回"


## 连接信号
func _connect_signals() -> void:
	"""连接UI信号"""
	if select_button:
		select_button.pressed.connect(_on_select_button_pressed)

	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)


## 连接挑战系统信号
func _connect_challenge_signals() -> void:
	"""连接挑战系统信号"""
	if _challenge_system:
		_challenge_system.character_unlocked.connect(_on_character_unlocked)
		_challenge_system.unlock_progress_updated.connect(_on_unlock_progress_updated)


## 断开挑战系统信号
func _disconnect_challenge_signals() -> void:
	"""断开挑战系统信号"""
	if _challenge_system:
		if _challenge_system.character_unlocked.is_connected(_on_character_unlocked):
			_challenge_system.character_unlocked.disconnect(_on_character_unlocked)

# =============================================================================
# 公共方法 - 角色网格
# =============================================================================

## 初始化角色网格
func _initialize_character_grid() -> void:
	"""创建所有角色卡片"""
	print("[CharacterSelect] 初始化角色网格, card_container: %s" % str(card_container))

	if card_container == null:
		print("[CharacterSelect] 错误: card_container 为 null")
		return

	# 尝试获取 ChallengeSystem
	_challenge_system = ChallengeSystem.get_instance()

	if not _challenge_system:
		print("[CharacterSelect] ChallengeSystem 未找到，使用默认角色列表")
		_create_default_character_cards()
		return

	# 清除现有卡片
	_clear_character_cards()

	# 获取所有角色
	var all_characters: Array = _challenge_system.get_all_characters()

	for char_id in all_characters:
		var card: Control = _create_character_card(char_id)
		if card:
			card_container.add_child(card)
			character_cards[char_id] = card

	# 默认选中第一个已解锁角色
	var unlocked: Array = _challenge_system.get_unlocked_characters()
	if unlocked.size() > 0:
		select_character(unlocked[0])


## 创建默认角色卡片（当ChallengeSystem不可用时）
func _create_default_character_cards() -> void:
	"""创建默认的角色卡片列表"""
	print("[CharacterSelect] 创建默认角色卡片, card_container: %s" % str(card_container))

	if card_container == null:
		print("[CharacterSelect] 错误: card_container 为 null，无法创建卡片")
		return

	# 清除现有卡片
	_clear_character_cards()

	# 默认角色列表（全部16个角色）
	var default_characters: Array = [
		{"id": "wandering_swordsman", "name": "流浪剑客", "type": "近战", "description": "使用剑术的流浪战士"},
		{"id": "arcane_warlock", "name": "奥术术士", "type": "法师", "description": "操控奥术能量的术士"},
		{"id": "berserker", "name": "狂战士", "type": "近战", "description": "无畏的战场杀戮者"},
		{"id": "elemental_mage", "name": "元素法师", "type": "法师", "description": "掌控元素的法师"},
		{"id": "frost_witch", "name": "冰霜女巫", "type": "法师", "description": "操控冰霜之力的女巫"},
		{"id": "holy_knight", "name": "圣骑士", "type": "近战", "description": "信仰神圣的骑士"},
		{"id": "holy_paladin", "name": "神圣圣骑", "type": "坦克", "description": "守护正义的圣骑"},
		{"id": "mech_engineer", "name": "机械工程师", "type": "远程", "description": "使用机械装置战斗"},
		{"id": "mechanic", "name": "机械师", "type": "远程", "description": "精通机械的技术员"},
		{"id": "night_ranger", "name": "暗夜游侠", "type": "远程", "description": "暗夜中的狩猎者"},
		{"id": "shadow_assassin", "name": "暗影刺客", "type": "刺客", "description": "来自暗影的杀手"},
		{"id": "thunder_lord", "name": "雷霆领主", "type": "法师", "description": "掌控雷电之力"},
		{"id": "time_walker", "name": "时间行者", "type": "法师", "description": "操控时间的神秘者"},
		{"id": "void_hunter", "name": "虚空猎人", "type": "近战", "description": "猎杀虚空生物"},
		{"id": "void_reaper", "name": "虚空收割者", "type": "刺客", "description": "收割虚空的灵魂"},
		{"id": "dragon_sage", "name": "龙之贤者", "type": "法师", "description": "龙族智慧的传承者"},
	]

	print("[CharacterSelect] 创建 %d 个默认角色卡片" % default_characters.size())

	for char_data in default_characters:
		var card: Control = _create_default_card(char_data)
		if card:
			card_container.add_child(card)
			character_cards[char_data["id"]] = card
			print("[CharacterSelect] 添加卡片: %s" % char_data["name"])

	# 默认选中第一个角色
	if default_characters.size() > 0:
		select_character(default_characters[0]["id"])


## 清除所有角色卡片
func _clear_character_cards() -> void:
	"""清除所有角色卡片"""
	if card_container:
		for child in card_container.get_children():
			child.queue_free()
	character_cards.clear()


## 创建单个角色卡片
func _create_character_card(char_id: String) -> Control:
	"""
	创建单个角色卡片
	@param char_id: 角色ID
	@return: 卡片控件
	"""
	var character: CharacterBase = _challenge_system.get_character(char_id)
	if not character:
		return null

	var card: Control = Control.new()
	card.name = char_id
	card.custom_minimum_size = Vector2(150, 200)

	# 背景
	var background: PanelContainer = PanelContainer.new()
	background.name = "Background"
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	card.add_child(background)

	# 内容容器
	var content: VBoxContainer = VBoxContainer.new()
	content.name = "Content"
	background.add_child(content)

	# 角色图标
	var icon_rect: TextureRect = TextureRect.new()
	icon_rect.name = "Icon"
	icon_rect.custom_minimum_size = Vector2(80, 80)
	icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.texture = character.icon
	content.add_child(icon_rect)

	# 角色名称
	var name_lbl: Label = Label.new()
	name_lbl.name = "NameLabel"
	name_lbl.text = character.character_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(name_lbl)

	# 角色类型
	var type_lbl: Label = Label.new()
	type_lbl.name = "TypeLabel"
	type_lbl.text = character.get_type_name()
	type_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_lbl.add_theme_font_size_override("font_size", 12)
	content.add_child(type_lbl)

	# 解锁状态
	var is_unlocked: bool = _challenge_system.is_character_unlocked(char_id)
	var status_lbl: Label = Label.new()
	status_lbl.name = "StatusLabel"
	if is_unlocked:
		status_lbl.text = "Lv.%d" % character.character_level
	else:
		status_lbl.text = "未解锁"
		status_lbl.add_theme_color_override("font_color", Color.RED)
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(status_lbl)

	# 未解锁时添加锁定遮罩
	if not is_unlocked:
		var lock_overlay: ColorRect = ColorRect.new()
		lock_overlay.name = "LockOverlay"
		lock_overlay.color = Color(0, 0, 0, 0.5)
		lock_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		card.add_child(lock_overlay)

		# 锁定图标
		var lock_icon: Label = Label.new()
		lock_icon.text = "🔒"
		lock_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lock_icon.set_anchors_preset(Control.PRESET_CENTER)
		lock_overlay.add_child(lock_icon)

	# 保存角色ID用于点击检测
	card.set_meta("character_id", char_id)

	# 连接点击信号
	card.gui_input.connect(_on_card_gui_input.bind(char_id))

	return card


## 处理卡片点击
func _on_card_gui_input(event: InputEvent, char_id: String) -> void:
	"""
	处理角色卡片的输入事件
	@param event: 输入事件
	@param char_id: 角色ID
	"""
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			select_character(char_id)

# =============================================================================
# 公共方法 - 选择角色
# =============================================================================

## 选择角色
func select_character(char_id: String) -> void:
	"""
	选中指定角色
	@param char_id: 角色ID
	"""
	selected_character_id = char_id
	_update_card_selection()
	_update_detail_panel()


## 更新卡片选中状态
func _update_card_selection() -> void:
	"""更新所有卡片的选中视觉效果"""
	for char_id in character_cards:
		var card: Control = character_cards[char_id]
		var background: PanelContainer = card.get_node_or_null("Background")

		if background:
			var style: StyleBoxFlat = StyleBoxFlat.new()
			if char_id == selected_character_id:
				style.bg_color = Color(0.3, 0.5, 0.8, 1.0)
				style.border_color = Color(0.5, 0.8, 1.0)
				style.set_border_width_all(3)
			else:
				style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
				style.set_border_width_all(0)

			background.add_theme_stylebox_override("panel", style)


## 更新详情面板
func _update_detail_panel() -> void:
	"""更新角色详情面板显示"""
	if selected_character_id.is_empty():
		return

	# 如果没有ChallengeSystem，使用默认角色信息
	if not _challenge_system:
		_update_detail_panel_default()
		return

	var character: CharacterBase = _challenge_system.get_character(selected_character_id)
	if not character:
		return

	var is_unlocked: bool = _challenge_system.is_character_unlocked(selected_character_id)

	# 更新基本信息
	if name_label:
		name_label.text = character.character_name

	if type_label:
		type_label.text = character.get_type_name()

	if description_label:
		description_label.text = character.description

	# 更新立绘/图标
	if portrait_display and character.portrait:
		portrait_display.texture = character.portrait
	elif icon_display and character.icon:
		icon_display.texture = character.icon

	# 更新被动技能信息
	if passive_name_label:
		passive_name_label.text = "被动: " + character.passive_name

	if passive_desc_label:
		passive_desc_label.text = character.passive_description

	# 更新解锁信息
	if unlock_condition_label:
		if is_unlocked:
			unlock_condition_label.text = "已解锁"
			unlock_condition_label.add_theme_color_override("font_color", Color.GREEN)
		else:
			unlock_condition_label.text = character.get_unlock_condition_text()
			unlock_condition_label.add_theme_color_override("font_color", Color.RED)

	if unlock_progress_bar:
		unlock_progress_bar.value = character.unlock_progress * 100
		unlock_progress_bar.visible = not is_unlocked

	# 更新角色成长信息
	if is_unlocked:
		if level_label:
			level_label.text = "等级: %d" % character.character_level

		if exp_progress_bar:
			var required_exp: int = character.get_experience_required_for_level(character.character_level)
			exp_progress_bar.value = (float(character.character_experience) / float(required_exp)) * 100
			exp_progress_bar.visible = true

		if clear_count_label:
			clear_count_label.text = "通关次数: %d" % character.clear_count
			clear_count_label.visible = true
	else:
		if level_label:
			level_label.text = ""
		if exp_progress_bar:
			exp_progress_bar.visible = false
		if clear_count_label:
			clear_count_label.visible = false

	# 更新属性显示
	_update_stats_display(character)

	# 更新选择按钮
	if select_button:
		select_button.disabled = not is_unlocked
		select_button.text = "选择角色" if is_unlocked else "未解锁"


## 更新详情面板（默认角色）
func _update_detail_panel_default() -> void:
	"""使用默认角色信息更新详情面板"""
	# 默认角色数据（全部16个角色）
	var default_data: Dictionary = {
		"wandering_swordsman": {"name": "流浪剑客", "type": "近战", "desc": "使用剑术的流浪战士", "passive": "剑气", "passive_desc": "攻击附带剑气，增加攻击范围"},
		"arcane_warlock": {"name": "奥术术士", "type": "法师", "desc": "操控奥术能量的术士", "passive": "奥术共鸣", "passive_desc": "增加奥术技能伤害15%"},
		"berserker": {"name": "狂战士", "type": "近战", "desc": "无畏的战场杀戮者", "passive": "狂暴", "passive_desc": "低血量时增加攻击力"},
		"elemental_mage": {"name": "元素法师", "type": "法师", "desc": "掌控元素的法师", "passive": "元素掌握", "passive_desc": "元素技能伤害提升10%"},
		"frost_witch": {"name": "冰霜女巫", "type": "法师", "desc": "操控冰霜之力的女巫", "passive": "冰霜之心", "passive_desc": "冰霜技能有概率冻结敌人"},
		"holy_knight": {"name": "圣骑士", "type": "近战", "desc": "信仰神圣的骑士", "passive": "神圣护盾", "passive_desc": "受到致命伤害时获得护盾"},
		"holy_paladin": {"name": "神圣圣骑", "type": "坦克", "desc": "守护正义的圣骑", "passive": "圣光庇护", "passive_desc": "增加队友防御力"},
		"mech_engineer": {"name": "机械工程师", "type": "远程", "desc": "使用机械装置战斗", "passive": "机械精通", "passive_desc": "炮台和机关伤害提升"},
		"mechanic": {"name": "机械师", "type": "远程", "desc": "精通机械的技术员", "passive": "快速修理", "passive_desc": "机械单位修复速度加快"},
		"night_ranger": {"name": "暗夜游侠", "type": "远程", "desc": "暗夜中的狩猎者", "passive": "暗夜猎手", "passive_desc": "夜间或暗处攻击力提升"},
		"shadow_assassin": {"name": "暗影刺客", "type": "刺客", "desc": "来自暗影的杀手", "passive": "暗影步", "passive_desc": "闪避后提升移动速度"},
		"thunder_lord": {"name": "雷霆领主", "type": "法师", "desc": "掌控雷电之力", "passive": "雷霆之力", "passive_desc": "雷电技能有连锁效果"},
		"time_walker": {"name": "时间行者", "type": "法师", "desc": "操控时间的神秘者", "passive": "时间扭曲", "passive_desc": "技能冷却减少10%"},
		"void_hunter": {"name": "虚空猎人", "type": "近战", "desc": "猎杀虚空生物", "passive": "虚空之眼", "passive_desc": "对虚空生物伤害提升"},
		"void_reaper": {"name": "虚空收割者", "type": "刺客", "desc": "收割虚空的灵魂", "passive": "灵魂收割", "passive_desc": "击杀敌人恢复生命值"},
		"dragon_sage": {"name": "龙之贤者", "type": "法师", "desc": "龙族智慧的传承者", "passive": "龙血", "passive_desc": "最大生命值和法力值提升"},
	}

	if not default_data.has(selected_character_id):
		return

	var data: Dictionary = default_data[selected_character_id]

	# 更新基本信息
	if name_label:
		name_label.text = data["name"]
	if type_label:
		type_label.text = data["type"]
	if description_label:
		description_label.text = data["desc"]
	if passive_name_label:
		passive_name_label.text = "被动: " + data["passive"]
	if passive_desc_label:
		passive_desc_label.text = data["passive_desc"]
	if unlock_condition_label:
		unlock_condition_label.text = "已解锁"
		unlock_condition_label.add_theme_color_override("font_color", Color.GREEN)
	if select_button:
		select_button.disabled = false
		select_button.text = "选择角色"


## 更新属性显示
func _update_stats_display(character: CharacterBase) -> void:
	"""更新角色属性显示"""
	if not stats_container:
		return

	# 清除现有属性显示
	for child in stats_container.get_children():
		child.queue_free()

	# 创建属性条目
	var stats: Array = [
		{"name": "生命", "value": character.base_health, "rating": character.get_stat_rating("health")},
		{"name": "攻击", "value": character.base_attack, "rating": character.get_stat_rating("attack")},
		{"name": "防御", "value": character.base_defense, "rating": character.get_stat_rating("defense")},
		{"name": "速度", "value": character.base_speed, "rating": character.get_stat_rating("speed")},
	]

	for stat in stats:
		var stat_row: HBoxContainer = HBoxContainer.new()

		# 属性名称
		var name_lbl: Label = Label.new()
		name_lbl.text = stat.name
		name_lbl.custom_minimum_size.x = 50
		stat_row.add_child(name_lbl)

		# 属性值
		var value_lbl: Label = Label.new()
		value_lbl.text = str(int(stat.value))
		value_lbl.custom_minimum_size.x = 50
		stat_row.add_child(value_lbl)

		# 星级显示
		var stars_lbl: Label = Label.new()
		var stars: String = ""
		for i in range(5):
			if i < stat.rating:
				stars += "*"
			else:
				stars += "-"
		stars_lbl.text = stars
		stars_lbl.add_theme_color_override("font_color", Color.YELLOW)
		stat_row.add_child(stars_lbl)

		stats_container.add_child(stat_row)

# =============================================================================
# 公共方法 - 按钮回调
# =============================================================================

## 选择按钮按下
func _on_select_button_pressed() -> void:
	"""选择按钮被按下"""
	if selected_character_id.is_empty():
		return

	if _challenge_system and _challenge_system.is_character_unlocked(selected_character_id):
		# 播放选择音效
		AudioManager.play_sfx("select")

		# 发送选中信号
		character_selected.emit(selected_character_id)

		# 播放选择动画
		_play_select_animation()


## 返回按钮按下
func _on_back_button_pressed() -> void:
	"""返回按钮被按下"""
	AudioManager.play_sfx("cancel")
	back_pressed.emit()

# =============================================================================
# 公共方法 - 动画
# =============================================================================

## 播放选择动画
func _play_select_animation() -> void:
	"""播放角色选择动画"""
	if selected_character_id in character_cards:
		var card: Control = character_cards[selected_character_id]

		# 创建缩放动画
		if _tween:
			_tween.kill()

		_tween = create_tween()
		_tween.tween_property(card, "scale", Vector2(1.2, 1.2), 0.1)
		_tween.tween_property(card, "scale", Vector2.ONE, 0.2)


## 播放解锁动画
func play_unlock_animation(char_id: String) -> void:
	"""
	播放角色解锁动画
	@param char_id: 角色ID
	"""
	is_showing_unlock_animation = true

	if char_id in character_cards:
		var card: Control = character_cards[char_id]

		# 移除锁定遮罩
		var lock_overlay: ColorRect = card.get_node_or_null("LockOverlay")
		if lock_overlay:
			# 淡出锁定遮罩
			var tween: Tween = create_tween()
			tween.tween_property(lock_overlay, "modulate:a", 0.0, 0.5)
			tween.tween_callback(lock_overlay.queue_free)

		# 闪烁效果
		var flash_tween: Tween = create_tween()
		flash_tween.tween_property(card, "modulate", Color.YELLOW, 0.2)
		flash_tween.tween_property(card, "modulate", Color.WHITE, 0.2)
		flash_tween.tween_property(card, "modulate", Color.YELLOW, 0.2)
		flash_tween.tween_property(card, "modulate", Color.WHITE, 0.2)

		# 播放解锁音效
		AudioManager.play_sfx("unlock")

	is_showing_unlock_animation = false


## 刷新角色卡片
func refresh_character_card(char_id: String) -> void:
	"""
	刷新指定角色的卡片
	@param char_id: 角色ID
	"""
	if char_id in character_cards:
		var old_card: Control = character_cards[char_id]
		var index: int = old_card.get_index()

		# 移除旧卡片
		old_card.queue_free()
		character_cards.erase(char_id)

		# 创建新卡片
		var new_card: Control = _create_character_card(char_id)
		if new_card:
			card_container.add_child(new_card)
			card_container.move_child(new_card, index)
			character_cards[char_id] = new_card

# =============================================================================
# 信号回调
# =============================================================================

## 角色解锁回调
func _on_character_unlocked(char_id: String, char_name: String) -> void:
	"""
	角色解锁时的回调
	@param char_id: 角色ID
	@param char_name: 角色名称
	"""
	# 刷新卡片
	refresh_character_card(char_id)

	# 播放解锁动画
	play_unlock_animation(char_id)

	# 显示解锁提示
	_show_unlock_notification(char_name)


## 解锁进度更新回调
func _on_unlock_progress_updated(char_id: String, progress: float) -> void:
	"""
	解锁进度更新时的回调
	@param char_id: 角色ID
	@param progress: 进度（0-1）
	"""
	if char_id == selected_character_id:
		if unlock_progress_bar:
			unlock_progress_bar.value = progress * 100


## 显示解锁提示
func _show_unlock_notification(char_name: String) -> void:
	"""
	显示角色解锁通知
	@param char_name: 角色名称
	"""
	var notification: AcceptDialog = AcceptDialog.new()
	notification.dialog_text = "恭喜解锁新角色:\n%s!" % char_name
	notification.title = "角色解锁"
	add_child(notification)
	notification.popup_centered()
	notification.confirmed.connect(notification.queue_free)

# =============================================================================
# 公共方法 - 外部调用
# =============================================================================

## 显示角色选择界面
func show_select() -> void:
	"""显示角色选择界面"""
	print("[CharacterSelect] show_select 被调用")
	visible = true
	# 重新初始化角色网格以确保正确显示
	_initialize_character_grid()
	# 强制更新布局
	if card_container:
		card_container.queue_sort()
	print("[CharacterSelect] 界面显示完成，卡片数量: %d" % character_cards.size())

## 隐藏角色选择界面
func hide_select() -> void:
	"""隐藏角色选择界面"""
	visible = false

## 获取当前选中的角色
func get_selected_character() -> String:
	"""
	获取当前选中的角色ID
	@return: 角色ID
	"""
	return selected_character_id


## 设置当前选中角色（外部调用）
func set_selected_character(char_id: String) -> void:
	"""
	设置选中的角色
	@param char_id: 角色ID
	"""
	if char_id in character_cards:
		select_character(char_id)


## 刷新所有角色
func refresh_all_characters() -> void:
	"""刷新所有角色卡片"""
	_initialize_character_grid()


## 创建默认角色卡片
func _create_default_card(char_data: Dictionary) -> Control:
	"""创建一个简单的默认角色卡片"""
	var card: Control = Control.new()
	card.name = char_data["id"]
	card.custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)

	# 背景
	var background: PanelContainer = PanelContainer.new()
	background.name = "Background"
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.2, 0.2, 0.3, 1.0)
	bg_style.border_color = Color(0.5, 0.5, 0.7)
	bg_style.set_border_width_all(2)
	bg_style.set_corner_radius_all(10)
	background.add_theme_stylebox_override("panel", bg_style)
	card.add_child(background)

	# 内容容器
	var content: VBoxContainer = VBoxContainer.new()
	content.name = "Content"
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.add_theme_constant_override("separation", 6)
	content.add_theme_constant_override("margin_left", 8)
	content.add_theme_constant_override("margin_right", 8)
	content.add_theme_constant_override("margin_top", 8)
	content.add_theme_constant_override("margin_bottom", 8)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE  # 让点击传递到卡片
	background.add_child(content)

	# 角色图标 - 使用SpriteManager获取玩家精灵
	var icon_rect = TextureRect.new()
	icon_rect.name = "IconRect"
	icon_rect.custom_minimum_size = Vector2(64, 64)
	icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	# 尝试从SpriteManager获取角色头像
	var sprite_mgr = _get_sprite_manager()
	var has_texture := false
	if sprite_mgr:
		var portrait = sprite_mgr.get_character_portrait(char_data["id"])
		if portrait:
			icon_rect.texture = portrait
			has_texture = true
		else:
			# 后备：使用玩家精灵的第一帧
			var player_frame = sprite_mgr.get_player_frame(0)
			if player_frame:
				icon_rect.texture = player_frame
				has_texture = true

	if has_texture:
		content.add_child(icon_rect)
	else:
		# 没有纹理时使用颜色占位符
		var icon_placeholder = ColorRect.new()
		icon_placeholder.color = _get_character_color(char_data["type"])
		icon_placeholder.custom_minimum_size = Vector2(64, 64)
		content.add_child(icon_placeholder)

	# 角色名称
	var name_lbl: Label = Label.new()
	name_lbl.name = "NameLabel"
	name_lbl.text = char_data["name"]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	content.add_child(name_lbl)

	# 角色类型
	var type_lbl: Label = Label.new()
	type_lbl.name = "TypeLabel"
	type_lbl.text = char_data["type"]
	type_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_lbl.add_theme_font_size_override("font_size", 11)
	type_lbl.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	content.add_child(type_lbl)

	# 描述
	var desc_lbl: Label = Label.new()
	desc_lbl.name = "DescLabel"
	desc_lbl.text = char_data["description"]
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	content.add_child(desc_lbl)

	# 保存角色ID用于点击检测
	card.set_meta("character_id", char_data["id"])

	# 设置所有子控件的鼠标过滤为忽略，让点击事件传递到卡片
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.mouse_filter = Control.MOUSE_FILTER_STOP  # 卡片本身接收点击

	# 连接点击信号
	card.gui_input.connect(_on_card_gui_input.bind(char_data["id"]))

	return card


## 获取SpriteManager
func _get_sprite_manager() -> Node:
	"""安全获取SpriteManager"""
	if get_tree() and get_tree().root:
		return get_tree().root.get_node_or_null("SpriteManager")
	return null


## 根据角色类型获取颜色
func _get_character_color(type: String) -> Color:
	"""根据角色类型返回不同的颜色"""
	match type:
		"近战": return Color(0.8, 0.3, 0.3)  # 红色
		"法师": return Color(0.3, 0.5, 0.8)  # 蓝色
		"远程": return Color(0.3, 0.7, 0.4)  # 绿色
		"刺客": return Color(0.5, 0.2, 0.6)  # 紫色
		"坦克": return Color(0.6, 0.5, 0.3)  # 橙色
		_: return Color(0.4, 0.4, 0.5)       # 默认灰色