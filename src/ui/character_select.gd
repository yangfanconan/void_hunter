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

## 角色卡片场景路径（需要创建对应的tscn文件）
const CHARACTER_CARD_SCENE: String = "res://scenes/ui/character_card.tscn"

## 每行显示的角色数量
const CHARACTERS_PER_ROW: int = 4

## 卡片间距
const CARD_SPACING: int = 20

## 动画持续时间
const ANIMATION_DURATION: float = 0.3

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
	_setup_ui()
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

## 设置UI
func _setup_ui() -> void:
	"""初始化UI组件"""
	# 如果没有在编辑器中设置，则动态创建
	if card_container == null:
		card_container = _create_grid_container()

	if detail_panel == null:
		detail_panel = _create_detail_panel()

	if select_button:
		select_button.text = "选择角色"
		select_button.disabled = true

	if back_button:
		back_button.text = "返回"


## 创建网格容器
func _create_grid_container() -> GridContainer:
	"""动态创建网格容器"""
	var container = GridContainer.new()
	container.name = "CharacterGrid"
	container.columns = CHARACTERS_PER_ROW
	container.add_theme_constant_override("h_separation", CARD_SPACING)
	container.add_theme_constant_override("v_separation", CARD_SPACING)
	return container


## 创建详情面板
func _create_detail_panel() -> PanelContainer:
	"""动态创建详情面板"""
	var panel = PanelContainer.new()
	panel.name = "DetailPanel"
	panel.custom_minimum_size = Vector2(400, 500)
	return panel


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
	if not _challenge_system:
		await get_tree().process_frame
		_challenge_system = ChallengeSystem.get_instance()

	if not _challenge_system:
		push_error("ChallengeSystem 未找到")
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


## 清除所有角色卡片
func _clear_character_cards() -> void:
	"""清除所有角色卡片"""
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
	if not _challenge_system or selected_character_id.is_empty():
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
		{"name": "速度", "value": character.base_speed, "rating": character.get_stat_rating("speed")}
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
