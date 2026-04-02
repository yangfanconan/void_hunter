## Void Hunter - 简易设置界面
## @description: 游戏设置界面，包含音量和画面设置
## @version: 2.0.0

extends Control
class_name SettingsMenu

# =============================================================================
# 信号定义
# =============================================================================

signal closed()

# =============================================================================
# 私有变量
# =============================================================================

var _settings: Dictionary = {}
var _bg: ColorRect
var _panel: PanelContainer
var _master_slider: HSlider
var _music_slider: HSlider
var _sfx_slider: HSlider
var _fullscreen_check: CheckBox

# =============================================================================
# 生命周期
# =============================================================================

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_load_settings()
	hide()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		hide_settings()

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

	# 主面板 - 使用size + position居中
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(500, 400)
	# 使用中心和全矩形结合的方式
	_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_panel.anchor_left = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -250
	_panel.offset_top = -200
	_panel.offset_right = 250
	_panel.offset_bottom = 200
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	style.border_color = Color(0.4, 0.35, 0.6)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	# 标题
	var title := Label.new()
	title.text = "设置"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.95, 0.9, 0.75))
	vbox.add_child(title)

	# 音量设置
	var audio_section := _create_section("音频设置")
	vbox.add_child(audio_section)

	# 主音量
	_master_slider = _create_slider("主音量", 100.0)
	_master_slider.value_changed.connect(_on_master_changed)
	vbox.add_child(_master_slider.get_parent())

	# 音乐音量
	_music_slider = _create_slider("音乐", 80.0)
	_music_slider.value_changed.connect(_on_music_changed)
	vbox.add_child(_music_slider.get_parent())

	# 音效音量
	_sfx_slider = _create_slider("音效", 100.0)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	vbox.add_child(_sfx_slider.get_parent())

	# 画面设置
	var graphics_section := _create_section("画面设置")
	vbox.add_child(graphics_section)

	# 全屏
	_fullscreen_check = CheckBox.new()
	_fullscreen_check.text = "全屏模式"
	_fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	vbox.add_child(_fullscreen_check)

	# 按钮
	var btn_container := HBoxContainer.new()
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_container.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_container)

	var btn_apply := Button.new()
	btn_apply.text = "应用"
	btn_apply.custom_minimum_size = Vector2(100, 36)
	btn_apply.pressed.connect(_on_apply_pressed)
	btn_container.add_child(btn_apply)

	var btn_back := Button.new()
	btn_back.text = "返回"
	btn_back.custom_minimum_size = Vector2(100, 36)
	btn_back.pressed.connect(hide_settings)
	btn_container.add_child(btn_back)

func _create_section(title: String) -> Label:
	var label := Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	return label

func _create_slider(label_text: String, default_value: float) -> HSlider:
	var container := HBoxContainer.new()
	container.add_theme_constant_override("separation", 10)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 80
	container.add_child(label)

	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.value = default_value
	slider.custom_minimum_size = Vector2(200, 24)
	container.add_child(slider)

	var value_label := Label.new()
	value_label.text = "%d%%" % int(default_value)
	value_label.custom_minimum_size.x = 50
	slider.set_meta("value_label", value_label)
	slider.value_changed.connect(func(v): value_label.text = "%d%%" % int(v))
	container.add_child(value_label)

	container.set_meta("slider", slider)
	return slider

# =============================================================================
# 设置操作
# =============================================================================

func _load_settings() -> void:
	if SaveManager:
		_settings = SaveManager.load_settings()

	var audio: Dictionary = _settings.get("audio", {})
	_master_slider.value = audio.get("master_volume", 1.0) * 100
	_music_slider.value = audio.get("music_volume", 0.8) * 100
	_sfx_slider.value = audio.get("sfx_volume", 1.0) * 100

	var graphics: Dictionary = _settings.get("graphics", {})
	_fullscreen_check.button_pressed = graphics.get("fullscreen", false)

func _save_settings() -> void:
	_settings["audio"] = {
		"master_volume": _master_slider.value / 100.0,
		"music_volume": _music_slider.value / 100.0,
		"sfx_volume": _sfx_slider.value / 100.0
	}
	_settings["graphics"] = {
		"fullscreen": _fullscreen_check.button_pressed
	}

	if SaveManager:
		SaveManager.save_settings(_settings)

# =============================================================================
# 显示控制
# =============================================================================

func show_settings() -> void:
	_load_settings()
	show()

func hide_settings() -> void:
	hide()
	closed.emit()

# =============================================================================
# 信号回调
# =============================================================================

func _on_master_changed(value: float) -> void:
	if AudioManager:
		AudioManager.set_bus_volume(AudioManager.BUS_MASTER, value / 100.0)

func _on_music_changed(value: float) -> void:
	if AudioManager:
		AudioManager.set_bus_volume(AudioManager.BUS_MUSIC, value / 100.0)

func _on_sfx_changed(value: float) -> void:
	if AudioManager:
		AudioManager.set_bus_volume(AudioManager.BUS_SFX, value / 100.0)

func _on_fullscreen_toggled(is_fullscreen: bool) -> void:
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_apply_pressed() -> void:
	_save_settings()
	hide_settings()