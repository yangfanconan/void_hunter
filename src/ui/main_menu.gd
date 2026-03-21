## Void Hunter - 主菜单控制器
## @description: 处理主菜单的交互和导航
## @author: Void Hunter Team
## @version: 1.0.0

extends Control

# =============================================================================
# 信号定义
# =============================================================================

## 新游戏按钮点击
signal new_game_pressed()

## 继续游戏按钮点击
signal continue_pressed()

## 设置按钮点击
signal settings_pressed()

## 退出按钮点击
signal quit_pressed()

# =============================================================================
# 节点引用
# =============================================================================

@onready var _title: Label = $VBoxContainer/Title
@onready var _button_new_game: Button = $VBoxContainer/ButtonNewGame
@onready var _button_continue: Button = $VBoxContainer/ButtonContinue
@onready var _button_settings: Button = $VBoxContainer/ButtonSettings
@onready var _button_quit: Button = $VBoxContainer/ButtonQuit

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""节点就绪时初始化"""
	_setup_signals()
	_check_save()
	
	# 设置标题样式
	if _title:
		_title.add_theme_font_size_override("font_size", 48)


func _input(event: InputEvent) -> void:
	"""处理输入事件"""
	if event.is_action_pressed("ui_accept"):
		if _button_new_game:
			_button_new_game.grab_focus()

# =============================================================================
# 公共方法
# =============================================================================

## 显示菜单
func show_menu() -> void:
	"""显示主菜单"""
	visible = true
	_check_save()


## 隐藏菜单
func hide_menu() -> void:
	"""隐藏主菜单"""
	visible = false

# =============================================================================
# 私有方法
# =============================================================================

func _setup_signals() -> void:
	"""设置信号连接"""
	if _button_new_game:
		_button_new_game.pressed.connect(_on_new_game)
	if _button_continue:
		_button_continue.pressed.connect(_on_continue)
	if _button_settings:
		_button_settings.pressed.connect(_on_settings)
	if _button_quit:
		_button_quit.pressed.connect(_on_quit)


func _check_save() -> void:
	"""检查存档是否存在"""
	var has_save: bool = false
	if SaveManager:
		has_save = SaveManager.has_save()
	
	if _button_continue:
		_button_continue.disabled = not has_save

# =============================================================================
# 信号回调
# =============================================================================

func _on_new_game() -> void:
	"""新游戏按钮点击"""
	print("[MainMenu] 新游戏")
	new_game_pressed.emit()


func _on_continue() -> void:
	"""继续游戏按钮点击"""
	print("[MainMenu] 继续游戏")
	continue_pressed.emit()


func _on_settings() -> void:
	"""设置按钮点击"""
	print("[MainMenu] 设置")
	settings_pressed.emit()


func _on_quit() -> void:
	"""退出按钮点击"""
	print("[MainMenu] 退出")
	quit_pressed.emit()
	get_tree().quit()
