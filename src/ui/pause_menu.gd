## Void Hunter - 暂停菜单
## @description: 游戏暂停时的菜单界面，包含继续、设置、返回主菜单等功能
## @author: Void Hunter Team
## @version: 1.0.0

extends Control
class_name PauseMenu

# =============================================================================
# 信号定义
# =============================================================================

## 继续游戏时触发
signal resume_pressed()

## 打开设置时触发
signal settings_opened()

## 返回主菜单时触发
signal main_menu_pressed()

## 退出游戏时触发
signal quit_pressed()

# =============================================================================
# 节点引用
# =============================================================================

## 背景遮罩
@onready var overlay: ColorRect = $Overlay

## 主面板
@onready var panel: Panel = $PanelContainer

## 标题
@onready var title_label: Label = $PanelContainer/VBoxContainer/TitleLabel

## 按钮容器
@onready var button_container: VBoxContainer = $PanelContainer/VBoxContainer/ButtonContainer

## 按钮
@onready var button_resume: Button = $PanelContainer/VBoxContainer/ButtonContainer/ButtonResume
@onready var button_settings: Button = $PanelContainer/VBoxContainer/ButtonContainer/ButtonSettings
@onready var button_main_menu: Button = $PanelContainer/VBoxContainer/ButtonContainer/ButtonMainMenu
@onready var button_quit: Button = $PanelContainer/VBoxContainer/ButtonContainer/ButtonQuit

## 设置界面引用
@onready var settings_menu: Control = $SettingsMenu

## 游戏统计显示
@onready var stats_container: VBoxContainer = $PanelContainer/VBoxContainer/StatsContainer
@onready var time_label: Label = $PanelContainer/VBoxContainer/StatsContainer/TimeLabel
@onready var wave_label: Label = $PanelContainer/VBoxContainer/StatsContainer/WaveLabel
@onready var kills_label: Label = $PanelContainer/VBoxContainer/StatsContainer/KillsLabel

# =============================================================================
# 私有变量
# =============================================================================

var _is_visible: bool = false
var _buttons: Array[Button] = []

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""
	节点就绪时初始化暂停菜单
	"""
	_initialize_menu()
	_connect_signals()
	_apply_styles()
	
	# 初始隐藏
	hide()


func _input(event: InputEvent) -> void:
	"""
	处理输入事件
	@param event: 输入事件
	"""
	if event.is_action_pressed("pause"):
		if _is_visible:
			_on_resume_pressed()
		elif settings_menu and settings_menu.visible:
			_close_settings()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		if settings_menu and settings_menu.visible:
			_close_settings()
			get_viewport().set_input_as_handled()

# =============================================================================
# 公共方法
# =============================================================================

## 显示暂停菜单
func show_pause_menu() -> void:
	"""
	显示暂停菜单（带动画）
	"""
	_is_visible = true
	
	# 更新统计数据
	_update_stats()
	
	# 显示并播放动画
	show()
	_play_show_animation()
	
	# 暂停游戏
	GameManager.pause_game()
	
	# 播放音效
	AudioManager.play_ui_sound("pause_open")


## 隐藏暂停菜单
func hide_pause_menu() -> void:
	"""
	隐藏暂停菜单（带动画）
	"""
	_play_hide_animation()


## 切换显示状态
func toggle() -> void:
	"""
	切换暂停菜单显示状态
	"""
	if _is_visible:
		hide_pause_menu()
	else:
		show_pause_menu()


## 更新统计显示
func update_stats(game_time: float, wave: int, kills: int) -> void:
	"""
	更新游戏统计显示
	@param game_time: 游戏时长（秒）
	@param wave: 当前波次
	@param kills: 击杀数
	"""
	time_label.text = tr("UI_SURVIVAL_TIME") % UITheme.format_time(game_time)
	wave_label.text = tr("UI_WAVE_REACHED") % wave
	kills_label.text = tr("UI_KILLS") % UITheme.format_number(kills)

# =============================================================================
# 私有方法 - 初始化
# =============================================================================

func _initialize_menu() -> void:
	"""
	初始化菜单状态
	"""
	# 收集按钮
	_buttons = [button_resume, button_settings, button_main_menu, button_quit]
	
	# Android平台调整退出按钮文字
	if OS.has_feature("android"):
		button_quit.text = tr("UI_QUIT_TO_DESKTOP")
	
	# 初始隐藏设置界面
	if settings_menu:
		settings_menu.hide()
	
	# 设置初始动画状态
	modulate.a = 0.0
	panel.scale = Vector2(0.9, 0.9)


func _connect_signals() -> void:
	"""
	连接按钮信号
	"""
	button_resume.pressed.connect(_on_resume_pressed)
	button_settings.pressed.connect(_on_settings_pressed)
	button_main_menu.pressed.connect(_on_main_menu_pressed)
	button_quit.pressed.connect(_on_quit_pressed)
	
	# 按钮焦点效果
	for button in _buttons:
		button.focus_entered.connect(_on_button_focused.bind(button))
		button.mouse_entered.connect(button.grab_focus)


func _apply_styles() -> void:
	"""
	应用UI样式
	"""
	# 背景遮罩
	overlay.color = UITheme.COLOR_BG_OVERLAY
	
	# 面板样式
	UITheme.create_panel_style(panel)
	
	# 标题样式
	title_label.add_theme_font_size_override("font_size", UITheme.FONT_SIZE_TITLE)
	title_label.add_theme_color_override("font_color", UITheme.COLOR_PRIMARY)
	
	# 按钮样式
	UITheme.create_button_style(button_resume, true, "lg")
	UITheme.create_button_style(button_settings, false, "md")
	UITheme.create_button_style(button_main_menu, false, "md")
	UITheme.create_button_style(button_quit, false, "md")
	
	# 统计信息样式
	for child in stats_container.get_children():
		if child is Label:
			child.add_theme_font_size_override("font_size", UITheme.FONT_SIZE_SM)
			child.add_theme_color_override("font_color", UITheme.COLOR_TEXT_SECONDARY)


# =============================================================================
# 私有方法 - 更新
# =============================================================================

func _update_stats() -> void:
	"""
	更新统计数据
	"""
	update_stats(
		GameManager.game_time,
		GameManager.current_wave,
		GameManager.enemies_killed
	)


# =============================================================================
# 私有方法 - 动画
# =============================================================================

func _play_show_animation() -> void:
	"""
	播放显示动画
	"""
	var tween := create_tween()
	tween.set_parallel(true)
	
	# 背景淡入
	tween.tween_property(self, "modulate:a", 1.0, UITheme.ANIM_DURATION_FAST)
	
	# 面板缩放弹入
	tween.parallel().tween_property(panel, "scale", Vector2.ONE, UITheme.ANIM_DURATION_NORMAL)
	tween.parallel().tween_property(panel, "scale", Vector2.ONE, UITheme.ANIM_DURATION_NORMAL).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# 按钮依次淡入
	tween.chain()
	for i in range(_buttons.size()):
		var button: Button = _buttons[i]
		button.modulate.a = 0.0
		button.position.x -= 20
		
		tween.tween_property(button, "modulate:a", 1.0, 0.1)
		tween.parallel().tween_property(button, "position:x", button.position.x + 20, 0.1)


func _play_hide_animation() -> void:
	"""
	播放隐藏动画
	"""
	var tween := create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(self, "modulate:a", 0.0, UITheme.ANIM_DURATION_FAST)
	tween.parallel().tween_property(panel, "scale", Vector2(0.9, 0.9), UITheme.ANIM_DURATION_FAST)
	
	tween.tween_callback(_on_hide_complete)


func _on_hide_complete() -> void:
	"""
	隐藏动画完成回调
	"""
	_is_visible = false
	hide()
	
	# 恢复游戏
	GameManager.resume_game()
	
	# 重置面板状态
	panel.scale = Vector2(0.9, 0.9)
	for button in _buttons:
		button.modulate.a = 1.0


func _on_button_focused(button: Button) -> void:
	"""
	按钮获得焦点时的效果
	@param button: 按钮引用
	"""
	AudioManager.play_ui_sound("button_hover")


# =============================================================================
# 私有方法 - 设置界面
# =============================================================================

func _open_settings() -> void:
	"""
	打开设置界面
	"""
	if settings_menu:
		settings_menu.show()
		UITheme.fade_in(settings_menu)


func _close_settings() -> void:
	"""
	关闭设置界面
	"""
	if settings_menu:
		UITheme.fade_out(settings_menu).tween_callback(settings_menu.hide)

# =============================================================================
# 信号回调
# =============================================================================

func _on_resume_pressed() -> void:
	"""
	继续游戏按钮按下
	"""
	AudioManager.play_ui_sound("button_click")
	hide_pause_menu()
	resume_pressed.emit()


func _on_settings_pressed() -> void:
	"""
	设置按钮按下
	"""
	AudioManager.play_ui_sound("button_click")
	settings_opened.emit()
	_open_settings()


func _on_main_menu_pressed() -> void:
	"""
	返回主菜单按钮按下
	"""
	AudioManager.play_ui_sound("button_click")
	
	# 确认对话框（简化版本）
	# TODO: 添加确认对话框
	_hide_immediate()
	main_menu_pressed.emit()
	
	# 返回主菜单
	GameManager.return_to_main_menu()


func _on_quit_pressed() -> void:
	"""
	退出游戏按钮按下
	"""
	AudioManager.play_ui_sound("button_click")
	
	# 保存设置
	SaveManager.save_settings(AudioManager.save_audio_settings())
	
	# 退出游戏
	quit_pressed.emit()
	get_tree().quit()


func _hide_immediate() -> void:
	"""
	立即隐藏（不播放动画）
	"""
	_is_visible = false
	hide()
	get_tree().paused = false
