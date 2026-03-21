## Void Hunter - 主菜单
## @description: 游戏主菜单界面，包含游戏Logo、开始游戏、角色选择、道具图鉴、设置等入口
## @author: Void Hunter Team
## @version: 1.0.0

extends Control
class_name MainMenu

# =============================================================================
# 信号定义
# =============================================================================

## 开始新游戏时触发
signal new_game_started()

## 继续游戏时触发
signal game_continued()

## 打开角色选择时触发
signal character_selection_opened()

## 打开道具图鉴时触发
signal item_codex_opened()

## 打开设置时触发
signal settings_opened()

# =============================================================================
# 节点引用
# =============================================================================

## Logo和标题区域
@onready var logo_container: Control = $VBoxContainer/LogoContainer
@onready var title_label: Label = $VBoxContainer/LogoContainer/TitleLabel
@onready var subtitle_label: Label = $VBoxContainer/LogoContainer/SubtitleLabel

## 按钮容器
@onready var button_container: VBoxContainer = $VBoxContainer/ButtonContainer

## 主按钮
@onready var button_start: Button = $VBoxContainer/ButtonContainer/ButtonStart
@onready var button_character: Button = $VBoxContainer/ButtonContainer/ButtonCharacter
@onready var button_codex: Button = $VBoxContainer/ButtonContainer/ButtonCodex
@onready var button_settings: Button = $VBoxContainer/ButtonContainer/ButtonSettings
@onready var button_quit: Button = $VBoxContainer/ButtonContainer/ButtonQuit

## 版本号
@onready var version_label: Label = $VersionLabel

## 子界面容器
@onready var settings_menu: Control = $SettingsMenu
@onready var character_select: Control = $CharacterSelect
@onready var item_codex: Control = $ItemCodex

## 背景效果
@onready var background: ColorRect = $Background
@onready var particles: GPUParticles2D = $Particles

# =============================================================================
# 私有变量
# =============================================================================

var _selected_button_index: int = 0
var _buttons: Array[Button] = []
var _is_transitioning: bool = false

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""
	节点就绪时初始化主菜单
	"""
	_initialize_menu()
	_connect_signals()
	_apply_styles()
	_check_save_data()
	_setup_animations()


func _input(event: InputEvent) -> void:
	"""
	处理输入事件
	@param event: 输入事件
	"""
	if event.is_action_pressed("ui_cancel"):
		# 如果子界面打开，关闭子界面
		if _is_sub_menu_open():
			_close_all_sub_menus()
		elif settings_menu.visible:
			_close_settings()
		elif character_select.visible:
			_close_character_select()
		elif item_codex.visible:
			_close_item_codex()


# =============================================================================
# 公共方法
# =============================================================================

## 显示主菜单
func show_menu() -> void:
	"""
	显示主菜单（带动画）
	"""
	show()
	_check_save_data()
	_play_enter_animation()


## 隐藏主菜单
func hide_menu() -> void:
	"""
	隐藏主菜单（带动画）
	"""
	_play_exit_animation()


## 刷新按钮状态
func refresh_buttons() -> void:
	"""
	刷新按钮可用状态
	"""
	_check_save_data()


# =============================================================================
# 私有方法 - 初始化
# =============================================================================

func _initialize_menu() -> void:
	"""
	初始化菜单状态
	"""
	# 播放主菜单背景音乐
	AudioManager.play_bgm("main_menu", true, 1.0)
	
	# 设置游戏状态
	GameManager.set_game_state(GameManager.GameState.MENU)
	
	# 收集按钮
	_buttons = [button_start, button_character, button_codex, button_settings]
	
	# Android平台隐藏退出按钮（或改为返回桌面）
	if OS.has_feature("android"):
		button_quit.text = tr("UI_QUIT_TO_DESKTOP")
	
	# 设置版本号
	var version: String = ProjectSettings.get_setting("application/config/version", "0.1.0")
	version_label.text = "v" + version
	
	# 初始隐藏子界面
	if settings_menu:
		settings_menu.hide()
	if character_select:
		character_select.hide()
	if item_codex:
		item_codex.hide()


func _connect_signals() -> void:
	"""
	连接按钮信号
	"""
	# 主按钮
	button_start.pressed.connect(_on_start_pressed)
	button_character.pressed.connect(_on_character_pressed)
	button_codex.pressed.connect(_on_codex_pressed)
	button_settings.pressed.connect(_on_settings_pressed)
	button_quit.pressed.connect(_on_quit_pressed)
	
	# 按钮焦点信号
	for button in _buttons:
		button.focus_entered.connect(_on_button_focused.bind(button))
		button.mouse_entered.connect(_on_button_hovered.bind(button))


func _apply_styles() -> void:
	"""
	应用UI样式
	"""
	# 应用按钮样式
	UITheme.create_button_style(button_start, true, "lg")
	UITheme.create_button_style(button_character, false, "md")
	UITheme.create_button_style(button_codex, false, "md")
	UITheme.create_button_style(button_settings, false, "md")
	UITheme.create_button_style(button_quit, false, "md")
	
	# 设置标题样式
	title_label.add_theme_font_size_override("font_size", UITheme.FONT_SIZE_DISPLAY)
	title_label.add_theme_color_override("font_color", UITheme.COLOR_PRIMARY)
	
	subtitle_label.add_theme_font_size_override("font_size", UITheme.FONT_SIZE_LG)
	subtitle_label.add_theme_color_override("font_color", UITheme.COLOR_TEXT_SECONDARY)
	
	# 版本号样式
	version_label.add_theme_font_size_override("font_size", UITheme.FONT_SIZE_XS)
	version_label.add_theme_color_override("font_color", UITheme.COLOR_TEXT_SECONDARY)


func _check_save_data() -> void:
	"""
	检查是否有存档，控制继续按钮的可用性
	"""
	# 如果需要继续游戏按钮，可以在这里添加逻辑
	pass


func _setup_animations() -> void:
	"""
	设置初始动画状态
	"""
	# 初始状态：隐藏
	modulate.a = 0.0
	logo_container.modulate.a = 0.0
	logo_container.position.y -= 50
	
	for button in _buttons:
		button.modulate.a = 0.0
	
	version_label.modulate.a = 0.0


# =============================================================================
# 私有方法 - 动画
# =============================================================================

func _play_enter_animation() -> void:
	"""
	播放进入动画
	"""
	_is_transitioning = true
	
	var tween := create_tween()
	tween.set_parallel(true)
	
	# 整体淡入
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	
	# Logo滑入
	tween.chain().tween_property(logo_container, "modulate:a", 1.0, 0.4)
	tween.parallel().tween_property(logo_container, "position:y", logo_container.position.y + 50, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# 按钮依次淡入
	var delay: float = 0.6
	for button in _buttons:
		tween.chain().tween_interval(delay)
		tween.set_parallel(true)
		tween.tween_property(button, "modulate:a", 1.0, 0.2)
		tween.parallel().tween_property(button, "custom_minimum_size:x", UITheme.BUTTON_MIN_WIDTH, 0.2)
		delay = 0.1
	
	# 版本号淡入
	tween.chain().tween_property(version_label, "modulate:a", 1.0, 0.3)
	
	tween.chain().tween_callback(func(): _is_transitioning = false)


func _play_exit_animation() -> void:
	"""
	播放退出动画
	"""
	_is_transitioning = true
	
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func():
		_is_transitioning = false
		hide()
	)


func _on_button_focused(button: Button) -> void:
	"""
	按钮获得焦点时的效果
	@param button: 按钮引用
	"""
	if _is_transitioning:
		return
	
	# 播放音效
	AudioManager.play_ui_sound("button_hover")
	
	# 轻微缩放动画
	var tween := create_tween()
	tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.1)
	tween.tween_property(button, "scale", Vector2.ONE, 0.1)


func _on_button_hovered(button: Button) -> void:
	"""
	鼠标悬停按钮时
	@param button: 按钮引用
	"""
	# 让按钮获得焦点
	button.grab_focus()


# =============================================================================
# 私有方法 - 子菜单
# =============================================================================

func _is_sub_menu_open() -> bool:
	"""
	检查是否有子菜单打开
	@return: 是否有子菜单打开
	"""
	return (settings_menu and settings_menu.visible) or \
		   (character_select and character_select.visible) or \
		   (item_codex and item_codex.visible)


func _close_all_sub_menus() -> void:
	"""
	关闭所有子菜单
	"""
	if settings_menu and settings_menu.visible:
		_close_settings()
	if character_select and character_select.visible:
		_close_character_select()
	if item_codex and item_codex.visible:
		_close_item_codex()


func _open_settings() -> void:
	"""
	打开设置界面
	"""
	AudioManager.play_ui_sound("button_click")
	settings_opened.emit()
	
	if settings_menu:
		settings_menu.show()
		UITheme.fade_in(settings_menu)


func _close_settings() -> void:
	"""
	关闭设置界面
	"""
	if settings_menu:
		UITheme.fade_out(settings_menu).tween_callback(settings_menu.hide)


func _open_character_select() -> void:
	"""
	打开角色选择界面
	"""
	AudioManager.play_ui_sound("button_click")
	character_selection_opened.emit()
	
	if character_select:
		character_select.show()
		UITheme.fade_in(character_select)


func _close_character_select() -> void:
	"""
	关闭角色选择界面
	"""
	if character_select:
		UITheme.fade_out(character_select).tween_callback(character_select.hide)


func _open_item_codex() -> void:
	"""
	打开道具图鉴界面
	"""
	AudioManager.play_ui_sound("button_click")
	item_codex_opened.emit()
	
	if item_codex:
		item_codex.show()
		UITheme.fade_in(item_codex)


func _close_item_codex() -> void:
	"""
	关闭道具图鉴界面
	"""
	if item_codex:
		UITheme.fade_out(item_codex).tween_callback(item_codex.hide)


# =============================================================================
# 信号回调
# =============================================================================

func _on_start_pressed() -> void:
	"""
	开始游戏按钮按下
	"""
	AudioManager.play_ui_sound("button_click")
	hide_menu()
	
	# 开始新游戏
	GameManager.start_new_game()
	new_game_started.emit()


func _on_character_pressed() -> void:
	"""
	角色选择按钮按下
	"""
	_open_character_select()


func _on_codex_pressed() -> void:
	"""
	道具图鉴按钮按下
	"""
	_open_item_codex()


func _on_settings_pressed() -> void:
	"""
	设置按钮按下
	"""
	_open_settings()


func _on_quit_pressed() -> void:
	"""
	退出按钮按下
	"""
	AudioManager.play_ui_sound("button_click")
	
	# Android平台返回桌面
	if OS.has_feature("android"):
		# 保存数据
		SaveManager.save_settings(AudioManager.save_audio_settings())
		get_tree().quit()
	else:
		# PC平台直接退出
		get_tree().quit()
