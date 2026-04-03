## Void Hunter - 游戏结束界面
## @description: 游戏结束时显示的结算界面，展示统计数据和操作按钮
## @author: Void Hunter Team
## @version: 1.0.0

extends Control
class_name GameOver

# =============================================================================
# 信号定义
# =============================================================================

## 重新开始时触发
signal restart_pressed()

## 返回主菜单时触发
signal main_menu_pressed()

# =============================================================================
# 节点引用
# =============================================================================

## 背景遮罩
@onready var overlay: ColorRect = $Overlay

## 主面板
@onready var panel: PanelContainer = $PanelContainer

## 标题区域
@onready var title_label: Label = $PanelContainer/VBoxContainer/TitleContainer/TitleLabel
@onready var subtitle_label: Label = $PanelContainer/VBoxContainer/TitleContainer/SubtitleLabel

## 统计数据容器
@onready var stats_container: GridContainer = $PanelContainer/VBoxContainer/StatsContainer

## 统计数据标签
@onready var time_value: Label = $PanelContainer/VBoxContainer/StatsContainer/TimeValue
@onready var wave_value: Label = $PanelContainer/VBoxContainer/StatsContainer/WaveValue
@onready var kills_value: Label = $PanelContainer/VBoxContainer/StatsContainer/KillsValue
@onready var exp_value: Label = $PanelContainer/VBoxContainer/StatsContainer/ExpValue
@onready var items_value: Label = $PanelContainer/VBoxContainer/StatsContainer/ItemsValue
@onready var damage_value: Label = $PanelContainer/VBoxContainer/StatsContainer/DamageValue

## 新纪录标识
@onready var new_record_container: HBoxContainer = $PanelContainer/VBoxContainer/NewRecordContainer

## 按钮容器
@onready var button_container: HBoxContainer = $PanelContainer/VBoxContainer/ButtonContainer
@onready var button_restart: Button = $PanelContainer/VBoxContainer/ButtonContainer/ButtonRestart
@onready var button_main_menu: Button = $PanelContainer/VBoxContainer/ButtonContainer/ButtonMainMenu

# =============================================================================
# 私有变量
# =============================================================================

var _is_victory: bool = false
var _game_stats: Dictionary = {}
var _is_visible: bool = false

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""
	节点就绪时初始化游戏结束界面
	"""
	_initialize_ui()
	_connect_signals()
	_apply_styles()
	
	# 初始隐藏
	hide()


func _input(event: InputEvent) -> void:
	"""
	处理输入事件
	@param event: 输入事件
	"""
	if not _is_visible:
		return
	
	if event.is_action_pressed("ui_accept"):
		_on_restart_pressed()
	elif event.is_action_pressed("ui_cancel"):
		_on_main_menu_pressed()


# =============================================================================
# 公共方法
# =============================================================================

## 显示游戏结束界面
func show_game_over(is_victory: bool, stats: Dictionary = {}) -> void:
	"""
	显示游戏结束界面
	@param is_victory: 是否胜利
	@param stats: 游戏统计数据
	"""
	_is_victory = is_victory
	_game_stats = stats
	
	# 更新标题
	_update_title()
	
	# 更新统计数据
	_update_stats(stats)
	
	# 检查新纪录
	_check_new_records(stats)
	
	# 显示界面
	show()
	_is_visible = true
	_play_show_animation()
	
	# 播放音效
	if is_victory:
		AudioManager.play_sfx("victory")
	else:
		AudioManager.play_sfx("game_over")


## 隐藏游戏结束界面
func hide_game_over() -> void:
	"""
	隐藏游戏结束界面
	"""
	_play_hide_animation()


## 更新统计数据
func update_stats(stats: Dictionary) -> void:
	"""
	更新统计数据
	@param stats: 统计数据字典
	"""
	_game_stats = stats
	_update_stats(stats)


# =============================================================================
# 私有方法 - 初始化
# =============================================================================

func _initialize_ui() -> void:
	"""
	初始化UI状态
	"""
	# 设置初始值
	time_value.text = "--:--"
	wave_value.text = "-"
	kills_value.text = "-"
	exp_value.text = "-"
	items_value.text = "-"
	damage_value.text = "-"
	
	# 隐藏新纪录标识
	new_record_container.hide()
	
	# 初始动画状态
	modulate.a = 0.0
	panel.scale = Vector2(0.8, 0.8)


func _connect_signals() -> void:
	"""
	连接信号
	"""
	button_restart.pressed.connect(_on_restart_pressed)
	button_main_menu.pressed.connect(_on_main_menu_pressed)
	
	# 焦点效果
	button_restart.focus_entered.connect(_on_button_focused.bind(button_restart))
	button_main_menu.focus_entered.connect(_on_button_focused.bind(button_main_menu))
	button_restart.mouse_entered.connect(button_restart.grab_focus)
	button_main_menu.mouse_entered.connect(button_main_menu.grab_focus)


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
	subtitle_label.add_theme_font_size_override("font_size", UITheme.FONT_SIZE_MD)
	
	# 按钮样式
	UITheme.create_button_style(button_restart, true, "lg")
	UITheme.create_button_style(button_main_menu, false, "lg")
	
	# 统计数据样式
	for child in stats_container.get_children():
		if child is Label:
			child.add_theme_font_size_override("font_size", UITheme.FONT_SIZE_MD)


# =============================================================================
# 私有方法 - 更新
# =============================================================================

func _update_title() -> void:
	"""
	更新标题
	"""
	if _is_victory:
		title_label.text = tr("UI_VICTORY")
		title_label.add_theme_color_override("font_color", UITheme.COLOR_SUCCESS)
		subtitle_label.text = tr("UI_VICTORY_SUBTITLE")
	else:
		title_label.text = tr("UI_GAME_OVER")
		title_label.add_theme_color_override("font_color", UITheme.COLOR_DANGER)
		subtitle_label.text = tr("UI_GAME_OVER_SUBTITLE")


func _update_stats(stats: Dictionary) -> void:
	"""
	更新统计数据
	@param stats: 统计数据字典
	"""
	# 生存时间
	var game_time: float = stats.get("game_time", 0.0)
	time_value.text = UITheme.format_time(game_time)
	
	# 到达波次
	var wave: int = stats.get("level_reached", 0)
	wave_value.text = str(wave)
	
	# 击杀数
	var kills: int = stats.get("enemies_killed", 0)
	kills_value.text = UITheme.format_number(kills)
	
	# 获得经验
	var exp: int = GameManager.total_experience if GameManager else 0
	exp_value.text = UITheme.format_number(exp)
	
	# 收集道具（从GameManager获取，如果没有则为0）
	var items: int = stats.get("items_collected", 0)
	items_value.text = UITheme.format_number(items)
	
	# 造成伤害
	var damage: float = stats.get("damage_dealt", 0.0)
	damage_value.text = UITheme.format_number(int(damage))


func _check_new_records(stats: Dictionary) -> void:
	"""
	检查是否打破纪录
	@param stats: 统计数据
	"""
	# 从存档中加载历史最高纪录进行比较
	var has_new_record: bool = false
	
	# 检查生存时间纪录
	var best_time: float = SaveManager.load_settings().get("records", {}).get("best_time", 0.0)
	if stats.get("game_time", 0.0) > best_time:
		has_new_record = true
	
	# 检查击杀数纪录
	var best_kills: int = SaveManager.load_settings().get("records", {}).get("best_kills", 0)
	if stats.get("enemies_killed", 0) > best_kills:
		has_new_record = true
	
	# 检查波次纪录
	var best_wave: int = SaveManager.load_settings().get("records", {}).get("best_wave", 0)
	if stats.get("level_reached", 0) > best_wave:
		has_new_record = true
	
	# 显示/隐藏新纪录标识
	if has_new_record:
		new_record_container.show()
		_animate_new_record()
	else:
		new_record_container.hide()


func _animate_new_record() -> void:
	"""
	新纪录动画
	"""
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(new_record_container, "modulate", Color.YELLOW, 0.5)
	tween.tween_property(new_record_container, "modulate", Color.WHITE, 0.5)


# =============================================================================
# 私有方法 - 动画
# =============================================================================

func _play_show_animation() -> void:
	"""
	播放显示动画
	"""
	# 重置状态
	modulate.a = 0.0
	panel.scale = Vector2(0.8, 0.8)
	
	var tween := create_tween()
	tween.set_parallel(true)
	
	# 淡入
	tween.tween_property(self, "modulate:a", 1.0, UITheme.ANIM_DURATION_NORMAL)
	
	# 面板缩放弹入
	tween.parallel().tween_property(panel, "scale", Vector2.ONE, UITheme.ANIM_DURATION_NORMAL).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# 统计数据依次显示
	tween.chain()
	var delay: float = 0.1
	for i in range(stats_container.get_child_count()):
		var child: Control = stats_container.get_child(i)
		child.modulate.a = 0.0
		tween.tween_interval(delay)
		tween.tween_property(child, "modulate:a", 1.0, 0.15)
		delay = 0.05
	
	# 按钮淡入
	tween.chain().tween_property(button_container, "modulate:a", 1.0, 0.2)
	
	# 自动聚焦到重新开始按钮
	tween.tween_callback(button_restart.grab_focus)


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


func _on_button_focused(button: Button) -> void:
	"""
	按钮获得焦点时的效果
	@param button: 按钮引用
	"""
	AudioManager.play_sfx("button_hover")
	
	# 轻微缩放动画
	var tween := create_tween()
	tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.1)
	tween.tween_property(button, "scale", Vector2.ONE, 0.1)


# =============================================================================
# 信号回调
# =============================================================================

func _on_restart_pressed() -> void:
	"""
	重新开始按钮按下
	"""
	AudioManager.play_sfx("button_click")
	hide_game_over()
	restart_pressed.emit()

	# 获取游戏场景并重新开始
	var game = get_tree().current_scene
	if game and game.has_method("start_new_game"):
		game.start_new_game()
	else:
		# 后备：重新加载当前场景
		get_tree().paused = false
		get_tree().reload_current_scene()


func _on_main_menu_pressed() -> void:
	"""
	返回主菜单按钮按下
	"""
	AudioManager.play_sfx("button_click")
	hide_game_over()
	main_menu_pressed.emit()

	# 获取游戏场景并返回主菜单
	var game = get_tree().current_scene
	if game and game.has_method("return_to_main_menu"):
		game.return_to_main_menu()
	else:
		# 后备：重新加载场景
		get_tree().paused = false
		get_tree().reload_current_scene()
