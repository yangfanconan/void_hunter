## Void Hunter - UI管理器
## @description: 统一管理所有UI界面的显示、隐藏和切换
## @author: Void Hunter Team
## @version: 1.0.0

extends CanvasLayer
class_name UIManager

# =============================================================================
# 信号定义
# =============================================================================

## UI界面打开时触发
signal ui_opened(ui_name: String)

## UI界面关闭时触发
signal ui_closed(ui_name: String)

## 通知显示时触发
signal notification_displayed(notification_type: int, message: String)

# =============================================================================
# 常量定义
# =============================================================================

## UI层级
enum UILayer {
	BACKGROUND,		## 背景层
	GAME,			## 游戏层（HUD等）
	POPUP,			## 弹出层
	MODAL,			## 模态层
	NOTIFICATION,	## 通知层
	LOADING			## 加载层
}

# =============================================================================
# 单例访问
# =============================================================================

static var _instance: UIManager = null

static func get_instance() -> UIManager:
	"""
	获取UIManager单例
	@return: UIManager实例
	"""
	return _instance


# =============================================================================
# 节点引用
# =============================================================================

## UI层级容器
var _layers: Dictionary = {}

## UI预制体缓存
var _ui_cache: Dictionary = {}

## 当前打开的UI列表
var _open_uis: Array[String] = []

# =============================================================================
# UI界面引用
# =============================================================================

var main_menu: MainMenu = null
var hud: HUD = null
var pause_menu: PauseMenu = null
var settings_menu: SettingsMenu = null
var game_over: GameOver = null
var notification_system: NotificationSystem = null

# =============================================================================
# 私有变量
# =============================================================================

var _is_initialized: bool = false

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""
	节点就绪时初始化UI管理器
	"""
	_instance = self
	_initialize_ui_manager()
	_create_ui_layers()
	_preload_ui_scenes()


func _input(event: InputEvent) -> void:
	"""
	处理输入事件
	@param event: 输入事件
	"""
	# 处理暂停键
	if event.is_action_pressed("pause"):
		if GameManager.current_state == GameManager.GameState.PLAYING:
			if pause_menu:
				pause_menu.toggle()
		elif GameManager.current_state == GameManager.GameState.PAUSED:
			if pause_menu:
				pause_menu.toggle()

# =============================================================================
# 公共方法
# =============================================================================

## 初始化UI管理器
func initialize() -> void:
	"""
	手动初始化UI管理器
	"""
	if not _is_initialized:
		_initialize_ui_manager()


## 显示主菜单
func show_main_menu() -> void:
	"""
	显示主菜单
	"""
	if main_menu:
		main_menu.show_menu()
		ui_opened.emit("main_menu")


## 隐藏主菜单
func hide_main_menu() -> void:
	"""
	隐藏主菜单
	"""
	if main_menu:
		main_menu.hide_menu()
		ui_closed.emit("main_menu")


## 显示HUD
func show_hud() -> void:
	"""
	显示游戏HUD
	"""
	if hud:
		hud.show_hud()
		ui_opened.emit("hud")


## 隐藏HUD
func hide_hud() -> void:
	"""
	隐藏游戏HUD
	"""
	if hud:
		hud.hide_hud()
		ui_closed.emit("hud")


## 显示暂停菜单
func show_pause_menu() -> void:
	"""
	显示暂停菜单
	"""
	if pause_menu:
		pause_menu.show_pause_menu()
		ui_opened.emit("pause_menu")


## 隐藏暂停菜单
func hide_pause_menu() -> void:
	"""
	隐藏暂停菜单
	"""
	if pause_menu:
		pause_menu.hide_pause_menu()
		ui_closed.emit("pause_menu")


## 显示设置界面
func show_settings() -> void:
	"""
	显示设置界面
	"""
	if settings_menu:
		settings_menu.show_settings()
		ui_opened.emit("settings_menu")


## 隐藏设置界面
func hide_settings() -> void:
	"""
	隐藏设置界面
	"""
	if settings_menu:
		settings_menu.hide_settings()
		ui_closed.emit("settings_menu")


## 显示游戏结束界面
func show_game_over(is_victory: bool, stats: Dictionary = {}) -> void:
	"""
	显示游戏结束界面
	@param is_victory: 是否胜利
	@param stats: 游戏统计数据
	"""
	if game_over:
		game_over.show_game_over(is_victory, stats)
		ui_opened.emit("game_over")


## 隐藏游戏结束界面
func hide_game_over() -> void:
	"""
	隐藏游戏结束界面
	"""
	if game_over:
		game_over.hide_game_over()
		ui_closed.emit("game_over")


## 显示通知
func show_notification(
	type: NotificationSystem.NotificationType,
	title: String,
	message: String,
	icon: Texture2D = null,
	duration: float = 3.0
) -> void:
	"""
	显示通知
	@param type: 通知类型
	@param title: 标题
	@param message: 消息内容
	@param icon: 图标
	@param duration: 显示时间
	"""
	if notification_system:
		notification_system.show_notification(type, title, message, icon, duration)
		notification_displayed.emit(type, message)


## 显示成就解锁通知
func show_achievement_notification(achievement_name: String, description: String = "") -> void:
	"""
	显示成就解锁通知
	@param achievement_name: 成就名称
	@param description: 成就描述
	"""
	if notification_system:
		notification_system.show_achievement(achievement_name, description)


## 显示角色解锁通知
func show_character_unlocked_notification(character_name: String) -> void:
	"""
	显示角色解锁通知
	@param character_name: 角色名称
	"""
	if notification_system:
		notification_system.show_character_unlocked(character_name)


## 显示道具获得通知
func show_item_notification(item_name: String, rarity: String = "common") -> void:
	"""
	显示道具获得通知
	@param item_name: 道具名称
	@param rarity: 稀有度
	"""
	if notification_system:
		notification_system.show_item_obtained(item_name, rarity)


## 显示升级通知
func show_level_up_notification(new_level: int) -> void:
	"""
	显示升级通知
	@param new_level: 新等级
	"""
	if notification_system:
		notification_system.show_level_up(new_level)


## 绑定玩家属性到HUD
func bind_player_stats_to_hud(stats: PlayerStats) -> void:
	"""
	绑定玩家属性到HUD
	@param stats: 玩家属性引用
	"""
	if hud:
		hud.bind_player_stats(stats)


## 绑定波次管理器到HUD
func bind_wave_manager_to_hud(manager: WaveManager) -> void:
	"""
	绑定波次管理器到HUD
	@param manager: 波次管理器引用
	"""
	if hud:
		hud.bind_wave_manager(manager)


## 更新HUD波次信息
func update_hud_wave_info(wave: int, enemy_count: int = 0) -> void:
	"""
	更新HUD波次信息
	@param wave: 当前波次
	@param enemy_count: 剩余敌人数量
	"""
	if hud:
		hud.update_wave_info(wave, enemy_count)


## 更新HUD击杀数
func update_hud_kill_count(count: int) -> void:
	"""
	更新HUD击杀数
	@param count: 击杀数量
	"""
	if hud:
		hud.update_kill_count(count)


## 创建伤害数字
func create_damage_number(
	world_position: Vector2,
	value: float,
	type: DamageNumber.NumberType = DamageNumber.NumberType.DAMAGE
) -> DamageNumber:
	"""
	创建伤害数字
	@param world_position: 世界坐标位置
	@param value: 数值
	@param type: 数字类型
	@return: 创建的伤害数字实例
	"""
	# 在游戏场景中创建伤害数字
	var game_layer: CanvasLayer = get_tree().get_first_node_in_group("game_layer")
	if game_layer:
		return DamageNumber.create(game_layer, world_position, value, type)
	return null


## 切换UI显示
func toggle_ui(ui_name: String) -> void:
	"""
	切换UI显示状态
	@param ui_name: UI名称
	"""
	match ui_name:
		"pause_menu":
			if pause_menu:
				pause_menu.toggle()
		"settings":
			if settings_menu:
				if settings_menu.visible:
					hide_settings()
				else:
					show_settings()


## 关闭所有弹窗UI
func close_all_popup_uis() -> void:
	"""
	关闭所有弹窗UI
	"""
	if pause_menu and pause_menu.visible:
		hide_pause_menu()
	if settings_menu and settings_menu.visible:
		hide_settings()


## 获取当前打开的UI列表
func get_open_uis() -> Array[String]:
	"""
	获取当前打开的UI列表
	@return: UI名称数组
	"""
	return _open_uis.duplicate()


## 检查是否有UI打开
func is_any_ui_open() -> bool:
	"""
	检查是否有UI打开
	@return: 是否有UI打开
	"""
	return _open_uis.size() > 0


# =============================================================================
# 私有方法 - 初始化
# =============================================================================

func _initialize_ui_manager() -> void:
	"""
	初始化UI管理器
	"""
	if _is_initialized:
		return
	
	_is_initialized = true
	
	# 连接游戏管理器信号
	_connect_game_manager_signals()
	
	# 设置处理模式
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if GameManager.debug_mode:
		print("[UIManager] 初始化完成")


func _create_ui_layers() -> void:
	"""
	创建UI层级容器
	"""
	# 创建各层级
	for layer_name in UILayer.keys():
		var layer := CanvasLayer.new()
		layer.name = layer_name
		layer.layer = UILayer[layer_name]
		add_child(layer)
		_layers[layer_name] = layer


func _preload_ui_scenes() -> void:
	"""
	预加载UI场景
	"""
	# 预加载UI场景
	var ui_scenes: Dictionary = {
		"main_menu": "res://scenes/ui/main_menu.tscn",
		"hud": "res://scenes/ui/hud.tscn",
		"pause_menu": "res://scenes/ui/pause_menu.tscn",
		"settings_menu": "res://scenes/ui/settings_menu.tscn",
		"game_over": "res://scenes/ui/game_over.tscn"
	}
	
	for ui_name in ui_scenes:
		var scene_path: String = ui_scenes[ui_name]
		if ResourceLoader.exists(scene_path):
			_ui_cache[ui_name] = load(scene_path)


func _connect_game_manager_signals() -> void:
	"""
	连接游戏管理器信号
	"""
	if GameManager:
		GameManager.game_state_changed.connect(_on_game_state_changed)
		GameManager.game_ended.connect(_on_game_ended)
		GameManager.character_unlocked.connect(_on_character_unlocked)
		GameManager.achievement_unlocked.connect(_on_achievement_unlocked)


# =============================================================================
# 私有方法 - 游戏状态回调
# =============================================================================

func _on_game_state_changed(_old_state: GameManager.GameState, new_state: GameManager.GameState) -> void:
	"""
	游戏状态变化回调
	@param _old_state: 旧状态
	@param new_state: 新状态
	"""
	match new_state:
		GameManager.GameState.MENU:
			hide_hud()
			hide_pause_menu()
			hide_game_over()
			show_main_menu()
		
		GameManager.GameState.PLAYING:
			hide_main_menu()
			hide_pause_menu()
			hide_game_over()
			show_hud()
		
		GameManager.GameState.PAUSED:
			show_pause_menu()
		
		GameManager.GameState.GAME_OVER:
			hide_hud()
			hide_pause_menu()
			show_game_over(false, GameManager.get_game_stats())
		
		GameManager.GameState.VICTORY:
			hide_hud()
			hide_pause_menu()
			show_game_over(true, GameManager.get_game_stats())


func _on_game_ended(is_victory: bool, final_stats: Dictionary) -> void:
	"""
	游戏结束回调
	@param is_victory: 是否胜利
	@param final_stats: 最终统计
	"""
	show_game_over(is_victory, final_stats)


func _on_character_unlocked(_character_id: String, character_name: String) -> void:
	"""
	角色解锁回调
	@param _character_id: 角色ID
	@param character_name: 角色名称
	"""
	show_character_unlocked_notification(character_name)


func _on_achievement_unlocked(achievement_id: String) -> void:
	"""
	成就解锁回调
	@param achievement_id: 成就ID
	"""
	# TODO: 从成就系统获取成就名称
	show_achievement_notification(achievement_id)


# =============================================================================
# 静态方法 - 便捷访问
# =============================================================================

static func show_notification_static(
	type: NotificationSystem.NotificationType,
	title: String,
	message: String
) -> void:
	"""
	静态方法：显示通知
	@param type: 通知类型
	@param title: 标题
	@param message: 消息
	"""
	if _instance:
		_instance.show_notification(type, title, message)


static func show_damage_number_static(
	world_position: Vector2,
	value: float,
	type: DamageNumber.NumberType = DamageNumber.NumberType.DAMAGE
) -> DamageNumber:
	"""
	静态方法：创建伤害数字
	@param world_position: 世界坐标
	@param value: 数值
	@param type: 类型
	@return: 伤害数字实例
	"""
	if _instance:
		return _instance.create_damage_number(world_position, value, type)
	return null
