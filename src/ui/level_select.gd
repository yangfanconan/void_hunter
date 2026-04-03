## Void Hunter - 关卡选择界面
## @description: 显示关卡列表，包含解锁状态、主题、Boss信息
## @author: Void Hunter Team
## @version: 1.0.0

extends Control

# =============================================================================
# 信号定义
# =============================================================================

## 关卡被选中
signal level_selected(level_id: int)

## 无尽模式被选中
signal endless_selected()

## 返回主菜单
signal back_pressed()

# =============================================================================
# 常量定义
# =============================================================================

## 关卡按钮大小
const BUTTON_SIZE: Vector2 = Vector2(200, 280)

## 每行关卡数量
const COLUMNS: int = 4

## 关卡卡片间距
const CARD_SPACING: int = 20

# =============================================================================
# 节点引用
# =============================================================================

@onready var _scroll_container: ScrollContainer = $VBoxContainer/ScrollContainer
@onready var _cards_container: GridContainer = $VBoxContainer/ScrollContainer/GridContainer
@onready var _back_button: Button = $VBoxContainer/HBoxContainer/ButtonBack
@onready var _endless_button: Button = $VBoxContainer/HBoxContainer/ButtonEndless
@onready var _title_label: Label = $VBoxContainer/TitleLabel

# =============================================================================
# 私有变量
# =============================================================================

## 已完成的关卡列表
var _completed_levels: Array = []

## 关卡卡片节点缓存
var _level_cards: Dictionary = {}

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""节点就绪时初始化"""
	_setup_signals()
	_load_progress()
	_create_level_cards()
	_update_cards_visibility()

# =============================================================================
# 公共方法
# =============================================================================

## 显示关卡选择
func show_select() -> void:
	"""显示关卡选择界面"""
	visible = true
	_load_progress()
	_update_cards_visibility()

## 隐藏关卡选择
func hide_select() -> void:
	"""隐藏关卡选择界面"""
	visible = false

# =============================================================================
# 私有方法 - 初始化
# =============================================================================

func _setup_signals() -> void:
	"""设置信号连接"""
	if _back_button:
		_back_button.pressed.connect(_on_back_pressed)
	if _endless_button:
		_endless_button.pressed.connect(_on_endless_pressed)

func _load_progress() -> void:
	"""加载关卡进度"""
	var gm: Node = _get_game_manager()
	if gm:
		gm.load_level_progress()
		_completed_levels = gm.get_completed_levels()
	else:
		_completed_levels = []

func _get_game_manager() -> Node:
	"""获取GameManager"""
	if get_tree() and get_tree().root:
		return get_tree().root.get_node_or_null("GameManager")
	return null

# =============================================================================
# 私有方法 - UI构建
# =============================================================================

func _create_level_cards() -> void:
	"""创建关卡卡片"""
	if not _cards_container:
		return

	# 清除现有卡片
	for child in _cards_container.get_children():
		child.queue_free()

	_level_cards.clear()

	# 设置GridContainer列数
	_cards_container.columns = COLUMNS

	# 创建7个关卡卡片
	for level_id in range(1, 8):
		var card: Control = _create_single_card(level_id)
		_cards_container.add_child(card)
		_level_cards[level_id] = card

func _create_single_card(level_id: int) -> Control:
	"""创建单个关卡卡片"""
	var config: Dictionary = LevelConfigData.get_level_config(level_id)

	# 卡片容器
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = BUTTON_SIZE
	card.name = "LevelCard_%d" % level_id

	# 内部布局
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(vbox)

	# 关卡图标（主题颜色）
	var icon_rect: ColorRect = ColorRect.new()
	icon_rect.custom_minimum_size = Vector2(80, 80)
	var theme_color: Color = config.get("background_color", Color.GRAY)
	icon_rect.color = theme_color
	vbox.add_child(icon_rect)

	# 关卡名称
	var name_label: Label = Label.new()
	name_label.text = config.get("name", "关卡 %d" % level_id)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	# Boss名称
	var boss_label: Label = Label.new()
	boss_label.text = "Boss: " + config.get("boss_name", "未知")
	boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_label.add_theme_font_size_override("font_size", 12)
	boss_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))
	vbox.add_child(boss_label)

	# 波次信息
	var waves_label: Label = Label.new()
	waves_label.text = "波次: %d" % config.get("waves", 5)
	waves_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	waves_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(waves_label)

	# 难度星级
	var difficulty_label: Label = Label.new()
	var difficulty: float = config.get("difficulty", 1.0)
	var stars: String = _get_difficulty_stars(difficulty)
	difficulty_label.text = "难度: " + stars
	difficulty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	difficulty_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(difficulty_label)

	# 状态标签（解锁/锁定）
	var status_label: Label = Label.new()
	var is_unlocked: bool = LevelConfigData.is_level_unlocked(level_id, _completed_levels)
	if is_unlocked:
		if level_id in _completed_levels:
			status_label.text = "[已通关]"
			status_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
		else:
			status_label.text = "[已解锁]"
			status_label.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))
	else:
		status_label.text = "[未解锁]"
		status_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(status_label)

	# 描述信息
	var desc_label: Label = Label.new()
	desc_label.text = config.get("description", "")
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 10)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)

	# 添加按钮功能
	var button: Button = Button.new()
	button.name = "SelectButton"
	button.text = "选择"
	button.disabled = not is_unlocked
	button.pressed.connect(_on_level_card_pressed.bind(level_id))
	vbox.add_child(button)

	return card

func _get_difficulty_stars(difficulty: float) -> String:
	"""根据难度返回星级显示"""
	var star_count: int = int(round(difficulty * 2.0))
	var stars: String = ""
	for i in range(star_count):
		stars += "*"
	return stars

func _update_cards_visibility() -> void:
	"""更新所有卡片状态"""
	_load_progress()

	for level_id in _level_cards.keys():
		var card: Control = _level_cards.get(level_id)
		if not card:
			continue

		var is_unlocked: bool = LevelConfigData.is_level_unlocked(level_id, _completed_levels)

		# 更新按钮状态
		var button: Button = card.find_child("SelectButton", true, false)
		if button:
			button.disabled = not is_unlocked

		# 更新状态标签
		var vbox: VBoxContainer = card.get_child(0) as VBoxContainer
		if vbox:
			for child in vbox.get_children():
				if child is Label and child.text.begins_with("["):
					if is_unlocked:
						if level_id in _completed_levels:
							child.text = "[已通关]"
							child.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
						else:
							child.text = "[已解锁]"
							child.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))
					else:
						child.text = "[未解锁]"
						child.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))

# =============================================================================
# 信号回调
# =============================================================================

func _on_level_card_pressed(level_id: int) -> void:
	"""关卡卡片点击"""
	print("[LevelSelect] 选择关卡 %d" % level_id)
	level_selected.emit(level_id)

func _on_endless_pressed() -> void:
	"""无尽模式按钮点击"""
	print("[LevelSelect] 选择无尽模式")
	endless_selected.emit()

func _on_back_pressed() -> void:
	"""返回按钮点击"""
	print("[LevelSelect] 返回主菜单")
	back_pressed.emit()