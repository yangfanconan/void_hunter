## Void Hunter - 游戏主控制器
## @description: 管理游戏状态、初始化玩家、启动波次系统
## @author: Void Hunter Team
## @version: 1.0.0

extends Node

const VERSION := "1.0.0"
const GAME_NAME := "Void Hunter"

enum GameState { LOADING, MAIN_MENU, CHARACTER_SELECT, PLAYING, PAUSED, SKILL_SELECTION, GAME_OVER }

# =============================================================================
# 导出变量
# =============================================================================

## 玩家场景引用
@export var player_scene: PackedScene = null

## 调试模式
@export var debug_mode: bool = false

# =============================================================================
# 公共变量
# =============================================================================

var current_state: GameState = GameState.LOADING
var _is_initialized: bool = false

## 当前玩家实例
var player: Node = null

## 波次管理器
var wave_manager: Node = null

## V2系统集成器
var system_integrator: Node = null

## 游戏时间
var game_time: float = 0.0

## 总击杀数
var total_kills: int = 0

# =============================================================================
# 节点引用
# =============================================================================

@onready var _main_menu: Control = $CanvasLayer/MainMenu
@onready var _game_world: Node2D = $GameWorld
@onready var _hud: Control = $HUD
@onready var _pause_menu: Control = $PauseMenu
@onready var _player_spawn: Marker2D = $GameWorld/PlayerSpawn
@onready var _entities: Node2D = $GameWorld/Entities
@onready var _projectiles: Node2D = $GameWorld/Projectiles
@onready var _level_container: Node2D = $GameWorld/LevelContainer
@onready var _game_over_screen: Control = get_node_or_null("CanvasLayer/GameOver")

## UI组件
var _settings_menu: Control = null
var _talent_tree_ui: Control = null
var _skill_selection: Control = null
var _character_select: Control = null

## 当前选择的角色ID
var _selected_character_id: String = "arcane_warlock"

## 玩家造成总伤害
var _total_damage_dealt: float = 0.0

## 收集道具数
var _items_collected: int = 0

# =============================================================================
# 信号定义
# =============================================================================

signal game_started()
signal game_paused()
signal game_resumed()
signal player_died()
signal wave_completed(wave_number: int)

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""节点就绪时初始化"""
	await get_tree().process_frame
	_initialize_ui_components()
	_setup_signals()
	_setup_level_background()
	_show_main_menu()
	_is_initialized = true
	print("[Game] %s v%s 初始化完成" % [GAME_NAME, VERSION])


func _initialize_ui_components() -> void:
	"""初始化UI组件"""
	# 查找或创建设置菜单
	_settings_menu = _main_menu.get_node_or_null("SettingsMenu")
	if _settings_menu == null:
		# 创建设置菜单
		var settings_script = load("res://src/ui/settings_menu.gd")
		if settings_script:
			_settings_menu = Control.new()
			_settings_menu.name = "SettingsMenu"
			_settings_menu.set_script(settings_script)
			_main_menu.add_child(_settings_menu)

	# 创建天赋树UI
	var talent_script = load("res://src/ui/talent_tree_ui.gd")
	if talent_script:
		_talent_tree_ui = Control.new()
		_talent_tree_ui.name = "TalentTreeUI"
		_talent_tree_ui.set_script(talent_script)
		add_child(_talent_tree_ui)
		if _talent_tree_ui.has_signal("close_requested"):
			_talent_tree_ui.close_requested.connect(_on_talent_tree_closed)

	# 创建技能选择UI
	var skill_script = load("res://src/ui/skill_selection.gd")
	if skill_script:
		_skill_selection = Control.new()
		_skill_selection.name = "SkillSelection"
		_skill_selection.set_script(skill_script)
		add_child(_skill_selection)
		if _skill_selection.has_signal("skill_selected"):
			_skill_selection.skill_selected.connect(_on_skill_selected)
		if _skill_selection.has_signal("selection_skipped"):
			_skill_selection.selection_skipped.connect(_on_skill_selection_skipped)

	# 查找角色选择界面
	_character_select = _main_menu.get_node_or_null("CharacterSelect")


func _process(delta: float) -> void:
	"""每帧更新"""
	if current_state == GameState.PLAYING:
		game_time += delta
		_update_combo_display()


func _input(event: InputEvent) -> void:
	"""处理输入事件"""
	if not _is_initialized:
		return
	
	if event.is_action_pressed("pause"):
		if current_state == GameState.PLAYING:
			_pause_game()
		elif current_state == GameState.PAUSED:
			_resume_game()

# =============================================================================
# 公共方法 - 游戏控制
# =============================================================================

## 开始新游戏
func start_new_game() -> void:
	"""开始新游戏"""
	_start_game()


## 暂停游戏
func pause_game() -> void:
	"""暂停游戏"""
	_pause_game()


## 恢复游戏
func resume_game() -> void:
	"""恢复游戏"""
	_resume_game()


## 返回主菜单
func return_to_main_menu() -> void:
	"""返回主菜单"""
	_cleanup_game()
	_show_main_menu()


## 获取玩家引用
func get_player() -> Node:
	"""获取当前玩家实例"""
	return player


## 获取游戏时间
func get_game_time() -> float:
	"""获取游戏时间"""
	return game_time


## 获取总击杀数
func get_total_kills() -> int:
	"""获取总击杀数"""
	return total_kills


## 玩家死亡处理
func handle_player_death() -> void:
	"""处理玩家死亡"""
	current_state = GameState.GAME_OVER
	player_died.emit()
	
	# 显示游戏结束界面
	_show_game_over()


## 敌人击杀记录
func record_enemy_kill() -> void:
	"""记录敌人击杀"""
	total_kills += 1

# =============================================================================
# 私有方法 - 初始化
# =============================================================================

func _setup_signals() -> void:
	"""设置信号连接"""
	# 主菜单按钮 - 使用main_menu.tscn中的按钮名称
	var start_btn = _main_menu.get_node_or_null("VBoxContainer/ButtonContainer/ButtonStart")
	var char_btn = _main_menu.get_node_or_null("VBoxContainer/ButtonContainer/ButtonCharacter")
	var settings_btn = _main_menu.get_node_or_null("VBoxContainer/ButtonContainer/ButtonSettings")
	var quit_btn = _main_menu.get_node_or_null("VBoxContainer/ButtonContainer/ButtonQuit")

	# 后备：使用旧版按钮名称
	if start_btn == null:
		start_btn = _main_menu.get_node_or_null("VBoxContainer/ButtonNewGame")
	if settings_btn == null:
		settings_btn = _main_menu.get_node_or_null("VBoxContainer/ButtonSettings")
	if quit_btn == null:
		quit_btn = _main_menu.get_node_or_null("VBoxContainer/ButtonQuit")
	var continue_btn = _main_menu.get_node_or_null("VBoxContainer/ButtonContinue")

	if start_btn and not start_btn.pressed.is_connected(_on_new_game_pressed):
		start_btn.pressed.connect(_on_new_game_pressed)
	if continue_btn and not continue_btn.pressed.is_connected(_on_continue_pressed):
		continue_btn.pressed.connect(_on_continue_pressed)
	if char_btn and not char_btn.pressed.is_connected(_on_character_select_pressed):
		char_btn.pressed.connect(_on_character_select_pressed)
	if settings_btn and not settings_btn.pressed.is_connected(_on_settings_pressed):
		settings_btn.pressed.connect(_on_settings_pressed)
	if quit_btn and not quit_btn.pressed.is_connected(_on_quit_pressed):
		quit_btn.pressed.connect(_on_quit_pressed)

	# 暂停菜单按钮
	var resume_btn = _pause_menu.get_node_or_null("Panel/VBoxContainer/ButtonResume")
	var pause_settings_btn = _pause_menu.get_node_or_null("Panel/VBoxContainer/ButtonSettings")
	var main_menu_btn = _pause_menu.get_node_or_null("Panel/VBoxContainer/ButtonMainMenu")
	var talent_btn = _pause_menu.get_node_or_null("Panel/VBoxContainer/ButtonTalent")

	if resume_btn and not resume_btn.pressed.is_connected(_on_pause_resume):
		resume_btn.pressed.connect(_on_pause_resume)
	if pause_settings_btn and not pause_settings_btn.pressed.is_connected(_on_pause_settings):
		pause_settings_btn.pressed.connect(_on_pause_settings)
	if main_menu_btn and not main_menu_btn.pressed.is_connected(_on_pause_main_menu):
		main_menu_btn.pressed.connect(_on_pause_main_menu)
	if talent_btn and not talent_btn.pressed.is_connected(_on_pause_talent):
		talent_btn.pressed.connect(_on_pause_talent)

	# HUD技能按钮信号
	if _hud and _hud.has_signal("skill_button_pressed"):
		if not _hud.skill_button_pressed.is_connected(_on_skill_button_pressed):
			_hud.skill_button_pressed.connect(_on_skill_button_pressed)


func _setup_level_background() -> void:
	"""设置关卡背景（简单的地板）"""
	# 尝试使用AI生成的主题背景
	var sprite_mgr = _get_sprite_manager()
	var theme_tex: ImageTexture = null
	if sprite_mgr:
		theme_tex = sprite_mgr.get_theme_background(0)
	if theme_tex:
		var bg_sprite := TextureRect.new()
		bg_sprite.name = "FloorBackground"
		bg_sprite.texture = theme_tex
		bg_sprite.stretch_mode = TextureRect.STRETCH_SCALE
		bg_sprite.custom_minimum_size = Vector2(2000, 2000)
		bg_sprite.position = Vector2(-500, -500)
		bg_sprite.z_index = -10
		_level_container.add_child(bg_sprite)
	else:
		# 后备：使用简单色块
		var floor_bg = ColorRect.new()
		floor_bg.name = "FloorBackground"
		floor_bg.color = Color(0.15, 0.15, 0.2, 1.0)
		floor_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		floor_bg.custom_minimum_size = Vector2(2000, 2000)
		floor_bg.position = Vector2(-500, -500)
		floor_bg.z_index = -10
		_level_container.add_child(floor_bg)
	
	# 创建网格线效果
	_create_grid_lines()


func _create_grid_lines() -> void:
	"""创建网格线效果"""
	var grid_size := 64
	var grid_color := Color(0.2, 0.2, 0.25, 0.5)
	var line_width := 1.0
	
	# 创建一个大的网格节点
	var grid_node := Node2D.new()
	grid_node.name = "GridLines"
	grid_node.z_index = -5
	_level_container.add_child(grid_node)
	
	# 使用 Line2D 创建网格
	for x in range(-10, 30):
		var line := Line2D.new()
		line.add_point(Vector2(x * grid_size, -500))
		line.add_point(Vector2(x * grid_size, 1500))
		line.width = line_width
		line.default_color = grid_color
		grid_node.add_child(line)
	
	for y in range(-10, 30):
		var line := Line2D.new()
		line.add_point(Vector2(-500, y * grid_size))
		line.add_point(Vector2(1500, y * grid_size))
		line.width = line_width
		line.default_color = grid_color
		grid_node.add_child(line)

# =============================================================================
# 私有方法 - 游戏流程
# =============================================================================

func _show_main_menu() -> void:
	"""显示主菜单"""
	_main_menu.visible = true
	_game_world.visible = false
	_hud.visible = false
	_pause_menu.visible = false
	current_state = GameState.MAIN_MENU


func _start_game() -> void:
	"""开始游戏"""
	print("[Game] 开始游戏...")
	
	# 隐藏主菜单
	_main_menu.visible = false
	_game_world.visible = true
	_hud.visible = true
	_pause_menu.visible = false
	
	# 重置游戏状态
	game_time = 0.0
	total_kills = 0
	_total_damage_dealt = 0.0
	_items_collected = 0

	# 隐藏游戏结束界面（如果存在）
	if _game_over_screen:
		_game_over_screen.hide()

	# 创建玩家
	_spawn_player()
	
	# 初始化V2系统集成器
	_setup_system_integrator()

	# 创建波次管理器
	_setup_wave_manager()
	
	# 设置 HUD
	_setup_hud()
	
	# 设置游戏状态
	current_state = GameState.PLAYING
	game_started.emit()
	
	print("[Game] 游戏开始完成")


func _spawn_player() -> void:
	"""生成玩家"""
	# 如果已有玩家，先清理
	if player and is_instance_valid(player):
		player.queue_free()
	
	# 创建玩家
	if player_scene:
		player = player_scene.instantiate()
	else:
		# 动态创建玩家
		player = _create_player_instance()
	
	# 设置玩家位置
	if _player_spawn:
		player.global_position = _player_spawn.global_position
	else:
		player.global_position = Vector2(576, 320)  # 默认屏幕中心
	
	# 添加到实体节点
	_entities.add_child(player)
	
	# 连接玩家信号
	_connect_player_signals()
	
	print("[Game] 玩家已生成于: ", player.global_position)


func _get_sprite_manager() -> Node:
	"""安全获取精灵管理器"""
	if get_tree() and get_tree().root:
		return get_tree().root.get_node_or_null("SpriteManager")
	return null

func _create_player_instance() -> CharacterBody2D:
	"""动态创建玩家实例"""
	var player_node := CharacterBody2D.new()
	player_node.set_script(preload("res://src/player/player.gd"))
	player_node.name = "Player"
	
	# 创建玩家属性
	var stats := PlayerStats.new()
	stats.initialize()
	player_node.set("stats", stats)
	
	# 添加碰撞形状
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 12.0
	collision.shape = shape
	player_node.add_child(collision)
	
	# 添加视觉表现 - 使用精灵管理器加载AI生成的美术素材
	var sprite := Sprite2D.new()
	var sprite_mgr = _get_sprite_manager()
	var player_tex: ImageTexture = null
	if sprite_mgr:
		player_tex = sprite_mgr.get_player_frame(0)
	if player_tex:
		sprite.texture = player_tex
	else:
		# 后备：使用简单色块
		var texture := ImageTexture.new()
		var image := Image.create(24, 24, false, Image.FORMAT_RGBA8)
		image.fill(Color(0.2, 0.8, 0.3))
		texture.set_image(image)
		sprite.texture = texture
	player_node.add_child(sprite)
	
	# 添加瞄准指示器
	var aim_indicator := Node2D.new()
	aim_indicator.name = "AimIndicator"
	player_node.add_child(aim_indicator)
	
	return player_node


func _connect_player_signals() -> void:
	"""连接玩家信号"""
	if not player:
		return
	
	# 连接受伤信号
	if player.has_signal("damaged"):
		player.damaged.connect(_on_player_damaged)
	
	# 连接死亡信号
	if player.has_signal("died"):
		player.died.connect(_on_player_died)
	
	# 连接属性变化信号
	if player.has_signal("stats_changed"):
		player.stats_changed.connect(_on_player_stats_changed)
	
	# 连接升级信号
	if player.has_signal("leveled_up"):
		player.leveled_up.connect(_on_player_leveled_up)


func _setup_wave_manager() -> void:
	"""设置波次管理器"""
	# 查找现有波次管理器
	wave_manager = get_node_or_null("GameWorld/WaveManager")
	
	if wave_manager == null:
		# 创建新的波次管理器
		wave_manager = Node.new()
		wave_manager.set_script(preload("res://src/managers/wave_manager.gd"))
		wave_manager.name = "WaveManager"
		_game_world.add_child(wave_manager)
	
	# 设置玩家引用
	if wave_manager.has_method("set_player"):
		wave_manager.set_player(player)
	
	# 连接波次信号
	if wave_manager.has_signal("wave_started"):
		wave_manager.wave_started.connect(_on_wave_started)
	if wave_manager.has_signal("wave_completed"):
		wave_manager.wave_completed.connect(_on_wave_completed)
	if wave_manager.has_signal("enemy_spawned"):
		wave_manager.enemy_spawned.connect(_on_enemy_spawned)
	
	# 启动波次
	if wave_manager.has_method("start_game"):
		wave_manager.start_game()
	
	print("[Game] 波次管理器已启动")


func _setup_hud() -> void:
	"""设置 HUD"""
	if _hud and _hud.has_method("set_player"):
		_hud.set_player(player)
	
	# 初始化 HUD 显示
	if player and "stats" in player:
		var stats = player.stats
		if _hud:
			_hud.update_health(stats.current_health, stats.max_health)
			_hud.update_mana(stats.current_mana, stats.max_mana)
			_hud.update_exp(stats.current_experience, stats.experience_required)



func _setup_system_integrator() -> void:
	"""初始化V2系统集成器"""
	var integrator_script := load("res://src/systems/game_system_integrator.gd")
	if integrator_script:
		system_integrator = Node.new()
		system_integrator.set_script(integrator_script)
		system_integrator.name = "GameSystemIntegrator"
		_game_world.add_child(system_integrator)

		# 设置玩家引用
		system_integrator.setup_player(player)

		# 连接连击系统信号到HUD
		_connect_combo_signals()

		print("[Game] V2系统集成器已初始化")


func _connect_combo_signals() -> void:
	"""连接连击系统信号"""
	if system_integrator and system_integrator.combo_system:
		var combo = system_integrator.combo_system
		# 连接暴走模式信号
		if combo.has_signal("rage_mode_activated"):
			combo.rage_mode_activated.connect(_on_rage_mode_activated)
		if combo.has_signal("rage_mode_deactivated"):
			combo.rage_mode_deactivated.connect(_on_rage_mode_deactivated)


func _on_rage_mode_activated(_duration: float) -> void:
	"""暴走模式激活"""
	if _hud and _hud.has_method("show_rage_mode"):
		_hud.show_rage_mode(true)


func _on_rage_mode_deactivated() -> void:
	"""暴走模式结束"""
	if _hud and _hud.has_method("show_rage_mode"):
		_hud.show_rage_mode(false)


func _update_combo_display() -> void:
	"""更新连击显示"""
	if system_integrator == null or _hud == null:
		return

	if not _hud.has_method("update_combo") or not _hud.has_method("update_combo_timer"):
		return

	# 获取连击数据
	var combo_count: int = system_integrator.get_combo_count()
	var kill_streak: int = system_integrator.get_kill_streak()
	var combo_timer: float = system_integrator.get_combo_timer()

	# 更新HUD显示
	_hud.update_combo(combo_count, kill_streak)

	# 连击计时器（假设基础连击时间为3秒）
	const BASE_COMBO_TIME: float = 3.0
	if combo_timer > 0:
		_hud.update_combo_timer(combo_timer, BASE_COMBO_TIME)
	else:
		_hud.update_combo_timer(0, BASE_COMBO_TIME)

func _cleanup_game() -> void:
	"""清理游戏状态"""
	# 清理玩家
	if player and is_instance_valid(player):
		player.queue_free()
		player = null
	
	# 清理波次管理器
	if wave_manager and is_instance_valid(wave_manager):
		wave_manager.queue_free()
		wave_manager = null
	
	# 清理V2系统集成器
	if system_integrator and is_instance_valid(system_integrator):
		system_integrator.queue_free()
		system_integrator = null
	
	# 清理所有敌人和子弹
	if _entities:
		for child in _entities.get_children():
			if child != player:
				child.queue_free()
	
	if _projectiles:
		for child in _projectiles.get_children():
			child.queue_free()
	
	# 重置状态
	game_time = 0.0
	total_kills = 0
	_total_damage_dealt = 0.0
	_items_collected = 0


func _pause_game() -> void:
	"""暂停游戏"""
	_pause_menu.visible = true
	get_tree().paused = true
	current_state = GameState.PAUSED
	game_paused.emit()


func _resume_game() -> void:
	"""恢复游戏"""
	_pause_menu.visible = false
	get_tree().paused = false
	current_state = GameState.PLAYING
	game_resumed.emit()


func _show_game_over() -> void:
	"""显示游戏结束界面"""
	print("[Game] 游戏结束!")
	print("[Game] 存活时间: %.1f 秒" % game_time)
	print("[Game] 总击杀: %d" % total_kills)

	# 停止波次管理器
	if wave_manager:
		if wave_manager.has_method("pause_wave"):
			wave_manager.pause_wave()
		wave_manager.set_physics_process(false)

	# 暂停游戏逻辑（但不暂停UI动画）
	get_tree().paused = true

	# 收集游戏统计数据
	var stats := _collect_game_stats()

	# 保存纪录
	_save_records(stats)

	if _game_over_screen:
		# 使用已有的 GameOver UI
		_game_over_screen.process_mode = Node.PROCESS_MODE_ALWAYS
		# 断开之前的连接（避免重复）
		if _game_over_screen.has_signal("restart_pressed"):
			if _game_over_screen.restart_pressed.is_connected(_on_game_over_restart):
				_game_over_screen.restart_pressed.disconnect(_on_game_over_restart)
			_game_over_screen.restart_pressed.connect(_on_game_over_restart)
		if _game_over_screen.has_signal("main_menu_pressed"):
			if _game_over_screen.main_menu_pressed.is_connected(_on_game_over_main_menu):
				_game_over_screen.main_menu_pressed.disconnect(_on_game_over_main_menu)
			_game_over_screen.main_menu_pressed.connect(_on_game_over_main_menu)
		_game_over_screen.show_game_over(false, stats)
	else:
		# 后备：动态创建简易游戏结束界面
		_create_fallback_game_over(stats)


func _collect_game_stats() -> Dictionary:
	"""收集游戏统计数据"""
	var stats := {
		"game_time": game_time,
		"enemies_killed": total_kills,
		"level_reached": 1,
		"damage_dealt": _total_damage_dealt,
		"items_collected": _items_collected,
	}

	# 从波次管理器获取当前波次
	if wave_manager and "current_wave" in wave_manager:
		stats["level_reached"] = wave_manager.current_wave

	# 从GameManager获取额外数据
	var gm = _get_game_manager()
	if gm:
		stats["total_experience"] = gm.total_experience if "total_experience" in gm else 0

	return stats


func _get_game_manager() -> Node:
	"""安全获取GameManager"""
	if get_tree() and get_tree().root:
		return get_tree().root.get_node_or_null("GameManager")
	return null


func _get_save_manager() -> Node:
	"""安全获取SaveManager"""
	if get_tree() and get_tree().root:
		return get_tree().root.get_node_or_null("SaveManager")
	return null


func _save_records(stats: Dictionary) -> void:
	"""保存游戏纪录"""
	var sm = _get_save_manager()
	if not sm:
		return

	var settings: Dictionary = sm.load_settings()
	var records: Dictionary = settings.get("records", {})
	var updated := false

	if stats.get("game_time", 0.0) > records.get("best_time", 0.0):
		records["best_time"] = stats["game_time"]
		updated = true
	if stats.get("enemies_killed", 0) > records.get("best_kills", 0):
		records["best_kills"] = stats["enemies_killed"]
		updated = true
	if stats.get("level_reached", 0) > records.get("best_wave", 0):
		records["best_wave"] = stats["level_reached"]
		updated = true

	if updated:
		settings["records"] = records
		sm.save_settings(settings)
		print("[Game] 新纪录已保存!")


func _create_fallback_game_over(stats: Dictionary) -> void:
	"""创建简易后备游戏结束界面"""
	var overlay := ColorRect.new()
	overlay.name = "FallbackGameOver"
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 1000
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS

	# 主面板 - 居中显示
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -200.0
	panel.offset_top = -200.0
	panel.offset_right = 200.0
	panel.offset_bottom = 200.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	style.set_border_width_all(2)
	style.border_color = Color(0.4, 0.35, 0.6)
	style.set_corner_radius_all(12)
	panel.add_theme_stylebox_override("panel", style)
	overlay.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	# 标题
	var title := Label.new()
	title.text = "游戏结束"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	vbox.add_child(title)

	# 分隔线
	var sep := HSeparator.new()
	vbox.add_child(sep)

	# 统计信息
	var info_text := "存活时间: %.1f秒\n击杀数: %d\n到达波次: %d\n总伤害: %.0f" % [
		stats.get("game_time", 0.0),
		stats.get("enemies_killed", 0),
		stats.get("level_reached", 0),
		stats.get("damage_dealt", 0.0)
	]
	var info := Label.new()
	info.text = info_text
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 18)
	info.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(info)

	# 按钮容器
	var btn_container := HBoxContainer.new()
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_container.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_container)

	# 重新开始按钮
	var restart_btn := Button.new()
	restart_btn.text = "重新开始"
	restart_btn.custom_minimum_size = Vector2(120, 40)
	restart_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	restart_btn.pressed.connect(_on_game_over_restart)
	btn_container.add_child(restart_btn)

	# 返回主菜单按钮
	var menu_btn := Button.new()
	menu_btn.text = "返回主菜单"
	menu_btn.custom_minimum_size = Vector2(120, 40)
	menu_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	menu_btn.pressed.connect(_on_game_over_main_menu)
	btn_container.add_child(menu_btn)

	$CanvasLayer.add_child(overlay)


func _on_game_over_restart() -> void:
	"""游戏结束界面重新开始"""
	print("[Game] 重新开始游戏...")

	# 取消暂停
	get_tree().paused = false

	# 清理后备游戏结束界面
	var fallback = get_node_or_null("CanvasLayer/FallbackGameOver")
	if fallback:
		fallback.queue_free()

	# 隐藏游戏结束界面
	if _game_over_screen:
		_game_over_screen.hide()

	# 清理游戏状态
	_cleanup_game()

	# 重新开始游戏
	_start_game()


func _on_game_over_main_menu() -> void:
	"""游戏结束界面返回主菜单"""
	print("[Game] 返回主菜单...")

	# 取消暂停
	get_tree().paused = false

	# 清理后备游戏结束界面
	var fallback = get_node_or_null("CanvasLayer/FallbackGameOver")
	if fallback:
		fallback.queue_free()

	# 隐藏游戏结束界面
	if _game_over_screen:
		_game_over_screen.hide()

	# 清理游戏状态
	_cleanup_game()

	# 返回主菜单
	_show_main_menu()


# =============================================================================
# 私有方法 - 场景管理
# =============================================================================

## 获取子弹容器
func get_projectiles_container() -> Node2D:
	"""获取子弹容器节点"""
	return _projectiles


## 获取实体容器
func get_entities_container() -> Node2D:
	"""获取实体容器节点"""
	return _entities


## 生成子弹
func spawn_bullet(bullet: Node) -> void:
	"""将子弹添加到场景"""
	_projectiles.add_child(bullet)

# =============================================================================
# 信号回调 - 主菜单
# =============================================================================

func _on_new_game_pressed() -> void:
	"""新游戏按钮点击"""
	_start_game()


func _on_continue_pressed() -> void:
	"""继续游戏按钮点击"""
	var sm = _get_save_manager()
	if sm and sm.has_save():
		sm.load_game()
	_start_game()


func _on_settings_pressed() -> void:
	"""设置按钮点击"""
	if _settings_menu and _settings_menu.has_method("show_settings"):
		_settings_menu.show_settings()
	else:
		print("[Game] 设置菜单未初始化")


func _on_character_select_pressed() -> void:
	"""角色选择按钮点击"""
	if _character_select:
		_main_menu.visible = false
		_character_select.visible = true
		current_state = GameState.CHARACTER_SELECT
	else:
		print("[Game] 角色选择界面未初始化，直接开始游戏")
		_start_game()


func _on_quit_pressed() -> void:
	"""退出按钮点击"""
	get_tree().quit()


func _on_main_menu_new_game() -> void:
	"""主菜单新游戏信号"""
	_start_game()


func _on_main_menu_continue() -> void:
	"""主菜单继续游戏信号"""
	_on_continue_pressed()


func _on_main_menu_settings() -> void:
	"""主菜单设置信号"""
	_on_settings_pressed()


func _on_main_menu_quit() -> void:
	"""主菜单退出信号"""
	_on_quit_pressed()

# =============================================================================
# 信号回调 - 暂停菜单
# =============================================================================

func _on_pause_resume() -> void:
	"""暂停菜单继续"""
	_resume_game()


func _on_pause_settings() -> void:
	"""暂停菜单设置"""
	if _settings_menu and _settings_menu.has_method("show_settings"):
		_settings_menu.show_settings()


func _on_pause_talent() -> void:
	"""暂停菜单天赋树"""
	if _talent_tree_ui and _talent_tree_ui.has_method("show_talent_tree"):
		_talent_tree_ui.show_talent_tree()


func _on_talent_tree_closed() -> void:
	"""天赋树关闭回调"""
	if current_state == GameState.PAUSED:
		_resume_game()


func _on_skill_button_pressed(slot: int) -> void:
	"""技能按钮点击回调"""
	if player and player.has_method("use_skill_at_slot"):
		player.use_skill_at_slot(slot)


func _on_skill_selected(skill_id: String) -> void:
	"""技能选择回调"""
	print("[Game] 选择技能: %s" % skill_id)
	if player and player.has_method("learn_skill"):
		player.learn_skill(skill_id)


func _on_skill_selection_skipped() -> void:
	"""跳过技能选择"""
	print("[Game] 跳过技能选择")


func _on_pause_main_menu() -> void:
	"""暂停菜单返回主菜单"""
	get_tree().paused = false
	_cleanup_game()
	_show_main_menu()

# =============================================================================
# 信号回调 - 玩家
# =============================================================================

func _on_player_damaged(amount: float, source: Node) -> void:
	"""玩家受伤回调"""
	if debug_mode:
		print("[Game] 玩家受到伤害: ", amount)


## 记录玩家造成伤害
func record_damage_dealt(amount: float) -> void:
	"""记录玩家造成的伤害"""
	_total_damage_dealt += amount


## 记录道具拾取
func record_item_collected() -> void:
	"""记录道具拾取"""
	_items_collected += 1


func _on_player_died() -> void:
	"""玩家死亡回调"""
	handle_player_death()


func _on_player_stats_changed(stats: Resource) -> void:
	"""玩家属性变化回调"""
	if _hud:
		_hud.update_health(stats.current_health, stats.max_health)
		_hud.update_mana(stats.current_mana, stats.max_mana)
		_hud.update_exp(stats.current_experience, stats.experience_required)


func _on_player_leveled_up(new_level: int) -> void:
	"""玩家升级回调"""
	print("[Game] 玩家升级到: ", new_level)
	
	# V2: 通知天赋树
	if system_integrator:
		system_integrator.on_player_level_up(new_level)

# =============================================================================
# 信号回调 - 波次
# =============================================================================

func _on_wave_started(wave_number: int) -> void:
	"""波次开始回调"""
	print("[Game] 第 %d 波开始" % wave_number)
	var gm = _get_game_manager()
	if gm:
		gm.set_wave(wave_number)

	# V2: 设置波次主题
	if system_integrator:
		system_integrator.setup_wave_theme(wave_number)


func _on_wave_completed(wave_number: int) -> void:
	"""波次完成回调"""
	print("[Game] 第 %d 波完成" % wave_number)
	wave_completed.emit(wave_number)


func _on_enemy_spawned(enemy: Node) -> void:
	"""敌人生成回调"""
	# 连接敌人死亡信号
	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died.bind(enemy))


func _on_enemy_died(killer: Node, enemy: Node) -> void:
	"""敌人死亡回调"""
	record_enemy_kill()
	var gm = _get_game_manager()
	if gm:
		gm.record_enemy_kill()

	# V2: 通知连击系统
	if system_integrator:
		system_integrator.on_enemy_killed(enemy)
	
	# 通知波次管理器
	if wave_manager and wave_manager.has_method("on_enemy_died"):
		wave_manager.on_enemy_died(enemy)
