## Void Hunter - 游戏主控制器
## @description: 管理游戏状态、初始化玩家、启动波次系统
## @author: Void Hunter Team
## @version: 1.0.0

extends Node

const VERSION := "1.0.0"
const GAME_NAME := "Void Hunter"

enum GameState { LOADING, MAIN_MENU, PLAYING, PAUSED, GAME_OVER }

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
	_setup_signals()
	_setup_level_background()
	_show_main_menu()
	_is_initialized = true
	print("[Game] %s v%s 初始化完成" % [GAME_NAME, VERSION])


func _process(delta: float) -> void:
	"""每帧更新"""
	if current_state == GameState.PLAYING:
		game_time += delta


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
	# 主菜单按钮
	var new_game_btn = _main_menu.get_node_or_null("VBoxContainer/ButtonNewGame")
	var continue_btn = _main_menu.get_node_or_null("VBoxContainer/ButtonContinue")
	var settings_btn = _main_menu.get_node_or_null("VBoxContainer/ButtonSettings")
	var quit_btn = _main_menu.get_node_or_null("VBoxContainer/ButtonQuit")
	
	if new_game_btn and not new_game_btn.pressed.is_connected(_on_new_game_pressed):
		new_game_btn.pressed.connect(_on_new_game_pressed)
	if continue_btn and not continue_btn.pressed.is_connected(_on_continue_pressed):
		continue_btn.pressed.connect(_on_continue_pressed)
	if settings_btn and not settings_btn.pressed.is_connected(_on_settings_pressed):
		settings_btn.pressed.connect(_on_settings_pressed)
	if quit_btn and not quit_btn.pressed.is_connected(_on_quit_pressed):
		quit_btn.pressed.connect(_on_quit_pressed)
	
	# 暂停菜单按钮
	var resume_btn = _pause_menu.get_node_or_null("Panel/VBoxContainer/ButtonResume")
	var pause_settings_btn = _pause_menu.get_node_or_null("Panel/VBoxContainer/ButtonSettings")
	var main_menu_btn = _pause_menu.get_node_or_null("Panel/VBoxContainer/ButtonMainMenu")
	
	if resume_btn and not resume_btn.pressed.is_connected(_on_pause_resume):
		resume_btn.pressed.connect(_on_pause_resume)
	if pause_settings_btn and not pause_settings_btn.pressed.is_connected(_on_pause_settings):
		pause_settings_btn.pressed.connect(_on_pause_settings)
	if main_menu_btn and not main_menu_btn.pressed.is_connected(_on_pause_main_menu):
		main_menu_btn.pressed.connect(_on_pause_main_menu)


func _setup_level_background() -> void:
	"""设置关卡背景（简单的地板）"""
	# 尝试使用AI生成的主题背景
	var theme_tex: ImageTexture = SpriteManager.get_theme_background(0)
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
	var player_tex: ImageTexture = SpriteManager.get_player_frame(0)
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
		print("[Game] V2系统集成器已初始化")

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

	# 暂停游戏逻辑（但不暂停UI动画）
	get_tree().paused = true

	# 收集游戏统计数据
	var stats := _collect_game_stats()

	# 保存纪录
	_save_records(stats)

	if _game_over_screen:
		# 使用已有的 GameOver UI
		_game_over_screen.process_mode = Node.PROCESS_MODE_ALWAYS
		_game_over_screen.show_game_over(false, stats)
		# 连接游戏结束信号
		if _game_over_screen.has_signal("restart_pressed") and not _game_over_screen.restart_pressed.is_connected(_on_game_over_restart):
			_game_over_screen.restart_pressed.connect(_on_game_over_restart)
		if _game_over_screen.has_signal("main_menu_pressed") and not _game_over_screen.main_menu_pressed.is_connected(_on_game_over_main_menu):
			_game_over_screen.main_menu_pressed.connect(_on_game_over_main_menu)
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
	if GameManager:
		stats["total_experience"] = GameManager.total_experience if "total_experience" in GameManager else 0

	return stats


func _save_records(stats: Dictionary) -> void:
	"""保存游戏纪录"""
	if not SaveManager:
		return

	var settings: Dictionary = SaveManager.load_settings()
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
		var settings: Dictionary = SaveManager.load_settings()
		settings["records"] = records
		SaveManager.save_settings(settings)
		print("[Game] 新纪录已保存!")


func _create_fallback_game_over(stats: Dictionary) -> void:
	"""创建简易后备游戏结束界面"""
	var overlay := ColorRect.new()
	overlay.name = "FallbackGameOver"
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 1000
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.position = Vector2(400, 200)
	overlay.add_child(vbox)

	# 标题
	var title := Label.new()
	title.text = "游戏结束"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color.RED)
	vbox.add_child(title)

	# 统计信息
	var info_text := "存活时间: %.1f秒\n击杀数: %d\n到达波次: %d\n总伤害: %.0f" % [
		stats.get("game_time", 0.0),
		stats.get("enemies_killed", 0),
		stats.get("level_reached", 0),
		stats.get("damage_dealt", 0.0)
	]
	var info := Label.new()
	info.text = info_text
	info.add_theme_font_size_override("font_size", 20)
	info.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(info)

	# 重新开始按钮
	var restart_btn := Button.new()
	restart_btn.text = "重新开始"
	restart_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	restart_btn.pressed.connect(_on_game_over_restart)
	vbox.add_child(restart_btn)

	# 返回主菜单按钮
	var menu_btn := Button.new()
	menu_btn.text = "返回主菜单"
	menu_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	menu_btn.pressed.connect(_on_game_over_main_menu)
	vbox.add_child(menu_btn)

	$CanvasLayer.add_child(overlay)


func _on_game_over_restart() -> void:
	"""游戏结束界面重新开始"""
	get_tree().paused = false
	var fallback = get_node_or_null("CanvasLayer/FallbackGameOver")
	if fallback:
		fallback.queue_free()
	_cleanup_game()
	_start_game()


func _on_game_over_main_menu() -> void:
	"""游戏结束界面返回主菜单"""
	get_tree().paused = false
	var fallback = get_node_or_null("CanvasLayer/FallbackGameOver")
	if fallback:
		fallback.queue_free()
	_cleanup_game()
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
	if SaveManager and SaveManager.has_save():
		SaveManager.load_game()
	_start_game()


func _on_settings_pressed() -> void:
	"""设置按钮点击"""
	print("[Game] 打开设置...")


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
	print("[Game] 暂停菜单设置...")


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
	GameManager.set_wave(wave_number)
	
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
	GameManager.record_enemy_kill()
	
	# V2: 通知连击系统
	if system_integrator:
		system_integrator.on_enemy_killed(enemy)
	
	# 通知波次管理器
	if wave_manager and wave_manager.has_method("on_enemy_died"):
		wave_manager.on_enemy_died(enemy)
