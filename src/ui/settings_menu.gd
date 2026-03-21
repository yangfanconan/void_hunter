## Void Hunter - 设置界面
## @description: 游戏设置界面，包含音量、语言、控制和画面设置
## @author: Void Hunter Team
## @version: 1.0.0

extends Control
class_name SettingsMenu

# =============================================================================
# 信号定义
# =============================================================================

## 设置关闭时触发
signal closed()

## 设置应用时触发
signal settings_applied(settings: Dictionary)

# =============================================================================
# 节点引用
# =============================================================================

## 背景遮罩
@onready var overlay: ColorRect = $Overlay

## 主面板
@onready var panel: Panel = $PanelContainer

## 标题
@onready var title_label: Label = $PanelContainer/VBoxContainer/TitleLabel

## 标签页
@onready var tab_container: TabContainer = $PanelContainer/VBoxContainer/TabContainer

## 音频设置页
@onready var audio_tab: Control = $PanelContainer/VBoxContainer/TabContainer/AudioTab
@onready var master_slider: HSlider = $PanelContainer/VBoxContainer/TabContainer/AudioTab/MasterContainer/MasterSlider
@onready var master_value_label: Label = $PanelContainer/VBoxContainer/TabContainer/AudioTab/MasterContainer/MasterValueLabel
@onready var music_slider: HSlider = $PanelContainer/VBoxContainer/TabContainer/AudioTab/MusicContainer/MusicSlider
@onready var music_value_label: Label = $PanelContainer/VBoxContainer/TabContainer/AudioTab/MusicContainer/MusicValueLabel
@onready var sfx_slider: HSlider = $PanelContainer/VBoxContainer/TabContainer/AudioTab/SFXContainer/SFXSlider
@onready var sfx_value_label: Label = $PanelContainer/VBoxContainer/TabContainer/AudioTab/SFXContainer/SFXValueLabel

## 画面设置页
@onready var graphics_tab: Control = $PanelContainer/VBoxContainer/TabContainer/GraphicsTab
@onready var fullscreen_check: CheckBox = $PanelContainer/VBoxContainer/TabContainer/GraphicsTab/FullscreenCheck
@onready var vsync_check: CheckBox = $PanelContainer/VBoxContainer/TabContainer/GraphicsTab/VSyncCheck
@onready var resolution_option: OptionButton = $PanelContainer/VBoxContainer/TabContainer/GraphicsTab/ResolutionContainer/ResolutionOption

## 控制设置页
@onready var controls_tab: Control = $PanelContainer/VBoxContainer/TabContainer/ControlsTab
@onready var touch_controls_check: CheckBox = $PanelContainer/VBoxContainer/TabContainer/ControlsTab/TouchControlsCheck

## 语言设置页
@onready var language_tab: Control = $PanelContainer/VBoxContainer/TabContainer/LanguageTab
@onready var language_option: OptionButton = $PanelContainer/VBoxContainer/TabContainer/LanguageTab/LanguageContainer/LanguageOption

## 底部按钮
@onready var button_container: HBoxContainer = $PanelContainer/VBoxContainer/ButtonContainer
@onready var button_apply: Button = $PanelContainer/VBoxContainer/ButtonContainer/ButtonApply
@onready var button_reset: Button = $PanelContainer/VBoxContainer/ButtonContainer/ButtonReset
@onready var button_back: Button = $PanelContainer/VBoxContainer/ButtonContainer/ButtonBack

# =============================================================================
# 私有变量
# =============================================================================

var _settings: Dictionary = {}
var _pending_settings: Dictionary = {}
var _is_rebinding: bool = false
var _rebind_action: String = ""

# 支持的分辨率
var _resolutions: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160)
]

# 支持的语言
var _languages: Array[Dictionary] = [
	{"code": "en", "name": "English"},
	{"code": "zh", "name": "简体中文"},
	{"code": "ja", "name": "日本語"},
	{"code": "ko", "name": "한국어"}
]

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""
	节点就绪时初始化设置界面
	"""
	_initialize_settings()
	_connect_signals()
	_apply_styles()
	_populate_options()
	_load_settings()
	
	# 初始隐藏
	hide()


func _input(event: InputEvent) -> void:
	"""
	处理输入事件
	@param event: 输入事件
	"""
	if event.is_action_pressed("ui_cancel"):
		if _is_rebinding:
			_cancel_rebind()
		else:
			_on_back_pressed()


# =============================================================================
# 公共方法
# =============================================================================

## 显示设置界面
func show_settings() -> void:
	"""
	显示设置界面（带动画）
	"""
	show()
	_load_settings()
	_play_show_animation()


## 隐藏设置界面
func hide_settings() -> void:
	"""
	隐藏设置界面（带动画）
	"""
	_play_hide_animation()


## 获取当前设置
func get_settings() -> Dictionary:
	"""
	获取当前设置
	@return: 设置字典
	"""
	return _settings.duplicate()


## 应用设置
func apply_settings() -> void:
	"""
	应用当前设置
	"""
	_apply_pending_settings()


## 重置为默认设置
func reset_to_defaults() -> void:
	"""
	重置为默认设置
	"""
	_settings = _get_default_settings()
	_update_ui_from_settings()
	_apply_pending_settings()

# =============================================================================
# 私有方法 - 初始化
# =============================================================================

func _initialize_settings() -> void:
	"""
	初始化设置
	"""
	_settings = _get_default_settings()
	_pending_settings = _settings.duplicate()


func _get_default_settings() -> Dictionary:
	"""
	获取默认设置
	@return: 默认设置字典
	"""
	return {
		"audio": {
			"master_volume": 1.0,
			"music_volume": 0.8,
			"sfx_volume": 1.0
		},
		"graphics": {
			"fullscreen": false,
			"vsync": true,
			"resolution_index": 0
		},
		"controls": {
			"touch_controls": OS.has_feature("android") or OS.has_feature("ios")
		},
		"language": {
			"code": "en"
		}
	}


func _connect_signals() -> void:
	"""
	连接信号
	"""
	# 音频滑块
	master_slider.value_changed.connect(_on_master_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	
	# 画面设置
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	vsync_check.toggled.connect(_on_vsync_toggled)
	resolution_option.item_selected.connect(_on_resolution_selected)
	
	# 控制设置
	touch_controls_check.toggled.connect(_on_touch_controls_toggled)
	
	# 语言设置
	language_option.item_selected.connect(_on_language_selected)
	
	# 底部按钮
	button_apply.pressed.connect(_on_apply_pressed)
	button_reset.pressed.connect(_on_reset_pressed)
	button_back.pressed.connect(_on_back_pressed)


func _apply_styles() -> void:
	"""
	应用UI样式
	"""
	# 面板样式
	UITheme.create_panel_style(panel)
	
	# 标题样式
	title_label.add_theme_font_size_override("font_size", UITheme.FONT_SIZE_TITLE)
	title_label.add_theme_color_override("font_color", UITheme.COLOR_PRIMARY)
	
	# 滑块样式
	for slider in [master_slider, music_slider, sfx_slider]:
		slider.custom_minimum_size.y = 30
	
	# 按钮样式
	UITheme.create_button_style(button_apply, true, "md")
	UITheme.create_button_style(button_reset, false, "md")
	UITheme.create_button_style(button_back, false, "md")


func _populate_options() -> void:
	"""
	填充选项列表
	"""
	# 分辨率选项
	resolution_option.clear()
	for i in range(_resolutions.size()):
		var res: Vector2i = _resolutions[i]
		resolution_option.add_item("%d x %d" % [res.x, res.y], i)
	
	# 语言选项
	language_option.clear()
	for i in range(_languages.size()):
		var lang: Dictionary = _languages[i]
		language_option.add_item(lang.name, i)

# =============================================================================
# 私有方法 - 设置加载/保存
# =============================================================================

func _load_settings() -> void:
	"""
	加载设置
	"""
	# 从SaveManager加载设置
	var saved_settings: Dictionary = SaveManager.load_settings()
	
	if not saved_settings.is_empty():
		# 合并加载的设置与默认设置
		_merge_settings(saved_settings)
	
	# 更新UI
	_update_ui_from_settings()


func _merge_settings(saved: Dictionary) -> void:
	"""
	合并保存的设置
	@param saved: 保存的设置字典
	"""
	for category in saved.keys():
		if _settings.has(category) and saved[category] is Dictionary:
			_settings[category].merge(saved[category], true)


func _update_ui_from_settings() -> void:
	"""
	从设置更新UI
	"""
	# 音频设置
	var audio: Dictionary = _settings.get("audio", {})
	master_slider.value = audio.get("master_volume", 1.0) * 100
	music_slider.value = audio.get("music_volume", 0.8) * 100
	sfx_slider.value = audio.get("sfx_volume", 1.0) * 100
	
	# 画面设置
	var graphics: Dictionary = _settings.get("graphics", {})
	fullscreen_check.button_pressed = graphics.get("fullscreen", false)
	vsync_check.button_pressed = graphics.get("vsync", true)
	resolution_option.select(graphics.get("resolution_index", 0))
	
	# 控制设置
	var controls: Dictionary = _settings.get("controls", {})
	touch_controls_check.button_pressed = controls.get("touch_controls", false)
	
	# 语言设置
	var language: Dictionary = _settings.get("language", {})
	var lang_code: String = language.get("code", "en")
	for i in range(_languages.size()):
		if _languages[i].code == lang_code:
			language_option.select(i)
			break
	
	# 复制到待应用设置
	_pending_settings = _settings.duplicate()


func _apply_pending_settings() -> void:
	"""
	应用待应用的设置
	"""
	_settings = _pending_settings.duplicate()
	
	# 应用音频设置
	_apply_audio_settings()
	
	# 应用画面设置
	_apply_graphics_settings()
	
	# 应用控制设置
	_apply_controls_settings()
	
	# 应用语言设置
	_apply_language_settings()
	
	# 保存设置
	SaveManager.save_settings(_settings)
	
	# 发送信号
	settings_applied.emit(_settings)
	
	# 播放音效
	AudioManager.play_ui_sound("button_click")


func _apply_audio_settings() -> void:
	"""
	应用音频设置
	"""
	var audio: Dictionary = _settings.get("audio", {})
	AudioManager.set_bus_volume(AudioManager.BUS_MASTER, audio.get("master_volume", 1.0))
	AudioManager.set_bus_volume(AudioManager.BUS_MUSIC, audio.get("music_volume", 0.8))
	AudioManager.set_bus_volume(AudioManager.BUS_SFX, audio.get("sfx_volume", 1.0))


func _apply_graphics_settings() -> void:
	"""
	应用画面设置
	"""
	var graphics: Dictionary = _settings.get("graphics", {})
	
	# 全屏
	if graphics.get("fullscreen", false):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	# VSync
	var vsync_mode: int = DisplayServer.VSYNC_ENABLED if graphics.get("vsync", true) else DisplayServer.VSYNC_DISABLED
	DisplayServer.window_set_vsync_mode(vsync_mode)
	
	# 分辨率
	var res_index: int = graphics.get("resolution_index", 0)
	if res_index >= 0 and res_index < _resolutions.size():
		var res: Vector2i = _resolutions[res_index]
		DisplayServer.window_set_size(res)


func _apply_controls_settings() -> void:
	"""
	应用控制设置
	"""
	var controls: Dictionary = _settings.get("controls", {})
	# 触屏控制设置会保存在这里，实际应用在游戏主循环中
	pass


func _apply_language_settings() -> void:
	"""
	应用语言设置
	"""
	var language: Dictionary = _settings.get("language", {})
	var lang_code: String = language.get("code", "en")
	TranslationServer.set_locale(lang_code)

# =============================================================================
# 私有方法 - 动画
# =============================================================================

func _play_show_animation() -> void:
	"""
	播放显示动画
	"""
	modulate.a = 0.0
	panel.scale = Vector2(0.9, 0.9)
	
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, UITheme.ANIM_DURATION_FAST)
	tween.parallel().tween_property(panel, "scale", Vector2.ONE, UITheme.ANIM_DURATION_NORMAL).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


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
	hide()
	closed.emit()

# =============================================================================
# 私有方法 - 按键重绑定
# =============================================================================

func _start_rebind(action: String) -> void:
	"""
	开始按键重绑定
	@param action: 动作名称
	"""
	_is_rebinding = true
	_rebind_action = action
	# TODO: 显示"按下新按键"提示


func _cancel_rebind() -> void:
	"""
	取消按键重绑定
	"""
	_is_rebinding = false
	_rebind_action = ""
	# TODO: 隐藏提示


func _complete_rebind(event: InputEvent) -> void:
	"""
	完成按键重绑定
	@param event: 输入事件
	"""
	# TODO: 保存新的按键映射
	_is_rebinding = false
	_rebind_action = ""

# =============================================================================
# 信号回调 - 音频
# =============================================================================

func _on_master_volume_changed(value: float) -> void:
	"""
	主音量改变
	@param value: 滑块值
	"""
	var volume: float = value / 100.0
	master_value_label.text = "%d%%" % int(value)
	_pending_settings["audio"]["master_volume"] = volume
	
	# 即时预览
	AudioManager.set_bus_volume(AudioManager.BUS_MASTER, volume)


func _on_music_volume_changed(value: float) -> void:
	"""
	音乐音量改变
	@param value: 滑块值
	"""
	var volume: float = value / 100.0
	music_value_label.text = "%d%%" % int(value)
	_pending_settings["audio"]["music_volume"] = volume
	
	# 即时预览
	AudioManager.set_bus_volume(AudioManager.BUS_MUSIC, volume)


func _on_sfx_volume_changed(value: float) -> void:
	"""
	音效音量改变
	@param value: 滑块值
	"""
	var volume: float = value / 100.0
	sfx_value_label.text = "%d%%" % int(value)
	_pending_settings["audio"]["sfx_volume"] = volume
	
	# 即时预览并播放示例音效
	AudioManager.set_bus_volume(AudioManager.BUS_SFX, volume)
	AudioManager.play_ui_sound("button_click")

# =============================================================================
# 信号回调 - 画面
# =============================================================================

func _on_fullscreen_toggled(is_fullscreen: bool) -> void:
	"""
	全屏切换
	@param is_fullscreen: 是否全屏
	"""
	_pending_settings["graphics"]["fullscreen"] = is_fullscreen


func _on_vsync_toggled(is_vsync: bool) -> void:
	"""
	VSync切换
	@param is_vsync: 是否启用VSync
	"""
	_pending_settings["graphics"]["vsync"] = is_vsync


func _on_resolution_selected(index: int) -> void:
	"""
	分辨率选择
	@param index: 选项索引
	"""
	_pending_settings["graphics"]["resolution_index"] = index

# =============================================================================
# 信号回调 - 控制
# =============================================================================

func _on_touch_controls_toggled(is_enabled: bool) -> void:
	"""
	触屏控制切换
	@param is_enabled: 是否启用
	"""
	_pending_settings["controls"]["touch_controls"] = is_enabled

# =============================================================================
# 信号回调 - 语言
# =============================================================================

func _on_language_selected(index: int) -> void:
	"""
	语言选择
	@param index: 选项索引
	"""
	if index >= 0 and index < _languages.size():
		_pending_settings["language"]["code"] = _languages[index].code

# =============================================================================
# 信号回调 - 按钮
# =============================================================================

func _on_apply_pressed() -> void:
	"""
	应用按钮按下
	"""
	_apply_pending_settings()


func _on_reset_pressed() -> void:
	"""
	重置按钮按下
	"""
	AudioManager.play_ui_sound("button_click")
	reset_to_defaults()


func _on_back_pressed() -> void:
	"""
	返回按钮按下
	"""
	AudioManager.play_ui_sound("button_click")
	hide_settings()
