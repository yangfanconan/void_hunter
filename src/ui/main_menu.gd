## Void Hunter - 主菜单控制器
## @description: 处理主菜单的交互和导航
## @author: Void Hunter Team
## @version: 1.1.0

extends Control

# =============================================================================
# 信号定义
# =============================================================================

## 游戏开始请求
signal game_start_requested(mode: String, level_id: int)

## 退出游戏
signal quit_pressed()

# =============================================================================
# 节点引用
# =============================================================================

@onready var _button_container: VBoxContainer = get_node_or_null("VBoxContainer/ButtonContainer")
@onready var _button_start: Button = get_node_or_null("VBoxContainer/ButtonContainer/ButtonStart")
@onready var _button_character: Button = get_node_or_null("VBoxContainer/ButtonContainer/ButtonCharacter")
@onready var _button_codex: Button = get_node_or_null("VBoxContainer/ButtonContainer/ButtonCodex")
@onready var _button_settings: Button = get_node_or_null("VBoxContainer/ButtonContainer/ButtonSettings")
@onready var _button_quit: Button = get_node_or_null("VBoxContainer/ButtonContainer/ButtonQuit")

@onready var _character_select: Control = get_node_or_null("CharacterSelect")
@onready var _settings_menu: Control = get_node_or_null("SettingsMenu")
@onready var _item_codex: Control = get_node_or_null("ItemCodex")

# =============================================================================
# 私有变量
# =============================================================================

## 当前选中的关卡ID（0=无尽模式）
var _selected_level_id: int = 0

## 当前选中的角色
var _selected_character: String = "wandering_swordsman"

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	_setup_signals()
	_setup_sub_menus()
	_load_game_manager_progress()
	_show_main_buttons()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		# ESC键返回主菜单
		if _character_select and _character_select.visible:
			_show_main_buttons()
		elif _settings_menu and _settings_menu.visible:
			_show_main_buttons()
		elif _item_codex and _item_codex.visible:
			_show_main_buttons()

# =============================================================================
# 公共方法
# =============================================================================

func show_menu() -> void:
	visible = true
	_show_main_buttons()

func hide_menu() -> void:
	visible = false

# =============================================================================
# 私有方法 - 初始化
# =============================================================================

func _setup_signals() -> void:
	if _button_start:
		_button_start.pressed.connect(_on_start_game)
	if _button_character:
		_button_character.pressed.connect(_on_character_select)
	if _button_codex:
		_button_codex.pressed.connect(_on_codex)
	if _button_settings:
		_button_settings.pressed.connect(_on_settings)
	if _button_quit:
		_button_quit.pressed.connect(_on_quit)

func _setup_sub_menus() -> void:
	# 角色选择界面
	if _character_select:
		_character_select.visible = false
		if _character_select.has_signal("character_selected"):
			_character_select.character_selected.connect(_on_character_selected)
		if _character_select.has_signal("back_pressed"):
			_character_select.back_pressed.connect(_show_main_buttons)

	# 设置界面
	if _settings_menu:
		_settings_menu.visible = false

	# 物品图鉴
	if _item_codex:
		_item_codex.visible = false

func _load_game_manager_progress() -> void:
	var gm: Node = _get_game_manager()
	if gm:
		gm.load_level_progress()

func _get_game_manager() -> Node:
	if get_tree() and get_tree().root:
		return get_tree().root.get_node_or_null("GameManager")
	return null

# =============================================================================
# 私有方法 - UI控制
# =============================================================================

func _show_main_buttons() -> void:
	if _button_container:
		_button_container.visible = true

	if _character_select:
		_character_select.visible = false
	if _settings_menu:
		_settings_menu.visible = false
	if _item_codex:
		_item_codex.visible = false

func _hide_main_buttons() -> void:
	if _button_container:
		_button_container.visible = false

# =============================================================================
# 信号回调 - 主菜单按钮
# =============================================================================

func _on_start_game() -> void:
	print("[MainMenu] 开始游戏 - 角色: %s" % _selected_character)

	# 设置GameManager
	var gm: Node = _get_game_manager()
	if gm:
		gm.selected_character = _selected_character
		if _selected_level_id > 0:
			gm.start_level(_selected_level_id)
		else:
			gm.start_endless_mode()

	game_start_requested.emit("level" if _selected_level_id > 0 else "endless", _selected_level_id)

func _on_character_select() -> void:
	print("[MainMenu] 角色选择")
	_hide_main_buttons()
	if _character_select:
		_character_select.visible = true
		if _character_select.has_method("show_select"):
			_character_select.show_select()

func _on_codex() -> void:
	print("[MainMenu] 物品图鉴")
	_hide_main_buttons()
	if _item_codex:
		_item_codex.visible = true

func _on_settings() -> void:
	print("[MainMenu] 设置")
	_hide_main_buttons()
	if _settings_menu:
		_settings_menu.visible = true

func _on_quit() -> void:
	print("[MainMenu] 退出")
	quit_pressed.emit()
	get_tree().quit()

# =============================================================================
# 信号回调 - 子菜单
# =============================================================================

func _on_character_selected(character_id: String) -> void:
	print("[MainMenu] 选择角色: %s" % character_id)
	_selected_character = character_id
	_show_main_buttons()