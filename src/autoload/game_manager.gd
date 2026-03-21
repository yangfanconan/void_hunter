## Void Hunter - 游戏管理器
## @description: 全局游戏状态管理单例，负责游戏生命周期、状态切换和事件协调
## @author: Void Hunter Team
## @version: 2.0.0

extends Node

# =============================================================================
# 信号定义
# =============================================================================

## 游戏状态改变时触发
signal game_state_changed(old_state: GameState, new_state: GameState)

## 游戏暂停状态改变时触发
signal pause_state_changed(is_paused: bool)

## 关卡改变时触发
signal level_changed(level_id: String, level_data: Dictionary)

## 玩家死亡时触发
signal player_died(player_stats: Dictionary)

## 游戏结束事件（胜利/失败）
signal game_ended(is_victory: bool, final_stats: Dictionary)

## 成就解锁事件
signal achievement_unlocked(achievement_id: String)

## 角色选择完成事件
signal character_selected(character_id: String)

## 角色解锁事件（转发自挑战系统）
signal character_unlocked(character_id: String, character_name: String)

# =============================================================================
# 枚举定义
# =============================================================================

## 游戏状态枚举
enum GameState {
	MENU,				## 主菜单
	CHARACTER_SELECT,	## 角色选择
	LOADING,			## 加载中
	PLAYING,			## 游戏进行中
	PAUSED,				## 暂停
	INVENTORY,			## 物品栏/商店
	SKILL_SELECTION,	## 技能选择
	GAME_OVER,			## 游戏结束
	VICTORY				## 胜利
}

## 游戏模式枚举
enum GameMode {
	STANDARD,		## 标准模式
	ENDLESS,		## 无尽模式
	BOSS_RUSH,		## Boss Rush
	DAILY_CHALLENGE ## 每日挑战
}

# =============================================================================
# 常量定义
# =============================================================================

const MAX_LEVELS: int = 10				## 最大关卡数
const BASE_ENEMY_SPAWN_RATE: float = 2.0	## 基础敌人生成间隔（秒）
const DIFFICULTY_SCALING: float = 1.15		## 难度缩放系数

# =============================================================================
# 导出变量
# =============================================================================

## 当前游戏模式
@export var current_game_mode: GameMode = GameMode.STANDARD

## 是否启用调试模式
@export var debug_mode: bool = true

# =============================================================================
# 公共变量
# =============================================================================

## 当前游戏状态
var current_state: GameState = GameState.MENU

## 当前关卡索引（从1开始）
var current_level_index: int = 0

## 当前游戏时长（秒）
var game_time: float = 0.0

## 击杀敌人数量
var enemies_killed: int = 0

## 获得的金币数量
var gold_collected: int = 0

## 累计造成的伤害
var total_damage_dealt: float = 0.0

## 累计承受的伤害
var total_damage_taken: float = 0.0

## 已解锁的角色列表
var unlocked_characters: Array[String] = ["warrior"]

## 当前难度系数
var difficulty_multiplier: float = 1.0

## 当前波次
var current_wave: int = 0

## 总获得经验值
var total_experience: int = 0

## 当前选中的角色ID
var current_character_id: String = "wandering_swordsman"

## 挑战系统引用
var challenge_system: ChallengeSystem = null

# =============================================================================
# 私有变量
# =============================================================================

var _is_initialized: bool = false
var _previous_state: GameState = GameState.MENU
var _pause_stack: Array[bool] = []

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""
	节点就绪时初始化游戏管理器
	"""
	_initialize_game_manager()


func _process(delta: float) -> void:
	"""
	每帧更新游戏状态
	@param delta: 帧间隔时间
	"""
	if current_state == GameState.PLAYING:
		game_time += delta


func _notification(what: int) -> void:
	"""
	处理系统通知
	@param what: 通知类型
	"""
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST:
			_on_game_close()
		NOTIFICATION_WM_GO_BACK_REQUEST:
			_on_back_pressed()

# =============================================================================
# 公共方法
# =============================================================================

## 初始化游戏管理器
func initialize() -> void:
	"""
	手动初始化游戏管理器（如果需要重新初始化）
	"""
	if not _is_initialized:
		_initialize_game_manager()


## 开始新游戏
func start_new_game(mode: GameMode = GameMode.STANDARD, character_id: String = "") -> void:
	"""
	开始一个新的游戏会话
	@param mode: 游戏模式
	@param character_id: 选择的角色ID（可选，默认使用当前选中角色）
	"""
	current_game_mode = mode

	# 设置角色
	if not character_id.is_empty():
		current_character_id = character_id

	_reset_game_stats()
	set_game_state(GameState.LOADING)

	# 初始化挑战系统会话
	if challenge_system:
		challenge_system.start_session(current_character_id)

	# 加载初始关卡
	await get_tree().process_frame
	_load_level(1)


## 开始角色选择
func start_character_selection() -> void:
	"""
	进入角色选择界面
	"""
	set_game_state(GameState.CHARACTER_SELECT)


## 选择角色并开始游戏
func select_character_and_start(character_id: String, mode: GameMode = GameMode.STANDARD) -> void:
	"""
	选择角色并开始游戏
	@param character_id: 角色ID
	@param mode: 游戏模式
	"""
	current_character_id = character_id
	character_selected.emit(character_id)

	# 记录选择的角色
	if challenge_system:
		challenge_system.set_current_character(character_id)

	# 开始游戏
	start_new_game(mode, character_id)


## 继续游戏（从存档）
func continue_game() -> bool:
	"""
	从最近的存档继续游戏
	@return: 是否成功加载存档
	"""
	var save_data: Dictionary = SaveManager.load_game()
	
	if save_data.is_empty():
		push_warning("没有找到有效的存档")
		return false
	
	_apply_save_data(save_data)
	set_game_state(GameState.PLAYING)
	return true


## 暂停游戏
func pause_game() -> void:
	"""
	暂停游戏（支持暂停堆栈）
	"""
	if current_state == GameState.PLAYING:
		_pause_stack.append(true)
		set_game_state(GameState.PAUSED)
		get_tree().paused = true
		pause_state_changed.emit(true)


## 恢复游戏
func resume_game() -> void:
	"""
	恢复游戏（支持暂停堆栈）
	"""
	if _pause_stack.size() > 0:
		_pause_stack.pop_back()
	
	if _pause_stack.is_empty():
		set_game_state(GameState.PREVIOUS_STATE if _previous_state != GameState.PAUSED else GameState.PLAYING)
		get_tree().paused = false
		pause_state_changed.emit(false)


## 切换暂停状态
func toggle_pause() -> void:
	"""
	切换暂停状态
	"""
	if get_tree().paused:
		resume_game()
	else:
		pause_game()


## 设置游戏状态
func set_game_state(new_state: GameState) -> void:
	"""
	设置游戏状态
	@param new_state: 新的游戏状态
	"""
	if current_state == new_state:
		return
	
	_previous_state = current_state
	current_state = new_state
	
	_on_state_enter(new_state)
	game_state_changed.emit(_previous_state, new_state)


## 进入下一关卡
func advance_to_next_level() -> void:
	"""
	进入下一关卡
	"""
	if current_level_index >= MAX_LEVELS:
		_trigger_victory()
		return
	
	_load_level(current_level_index + 1)


## 玩家死亡处理
func handle_player_death(stats: Dictionary) -> void:
	"""
	处理玩家死亡
	@param stats: 玩家死亡时的属性
	"""
	player_died.emit(stats)
	
	# 根据游戏模式决定是否可以复活
	if current_game_mode == GameMode.ENDLESS:
		# 无尽模式可以复活
		_handle_revival()
	else:
		# 其他模式游戏结束
		trigger_game_over(false)


## 触发游戏结束
func trigger_game_over(is_victory: bool = false) -> void:
	"""
	触发游戏结束
	@param is_victory: 是否胜利
	"""
	var final_stats: Dictionary = _collect_final_stats()
	set_game_state(GameState.VICTORY if is_victory else GameState.GAME_OVER)
	game_ended.emit(is_victory, final_stats)

	# 结束挑战系统会话
	if challenge_system:
		challenge_system.end_session(is_victory)

	# 自动保存
	SaveManager.save_game(_generate_save_data())


## 处理游戏胜利（波次系统调用）
func handle_game_victory() -> void:
	"""
	处理游戏胜利（达到最大波次）
	"""
	trigger_game_over(true)


## 解锁角色
func unlock_character(character_id: String) -> void:
	"""
	解锁角色
	@param character_id: 角色ID
	"""
	# 委托给挑战系统处理
	if challenge_system:
		challenge_system.force_unlock_character(character_id)
	else:
		# 兼容旧逻辑
		if character_id not in unlocked_characters:
			unlocked_characters.append(character_id)
			achievement_unlocked.emit("character_" + character_id)
			SaveManager.save_unlock_data({"characters": unlocked_characters})


## 记录击杀敌人
func record_enemy_kill(is_elite: bool = false) -> void:
	"""
	记录击杀敌人
	@param is_elite: 是否为精英敌人
	"""
	enemies_killed += 1

	if challenge_system:
		challenge_system.record_kill(is_elite)


## 记录造成伤害
func record_damage_dealt(damage: float) -> void:
	"""
	记录造成的伤害
	@param damage: 伤害值
	"""
	total_damage_dealt += damage

	if challenge_system:
		challenge_system.record_damage_dealt(damage)


## 记录承受伤害
func record_damage_taken(damage: float) -> void:
	"""
	记录承受的伤害
	@param damage: 伤害值
	"""
	total_damage_taken += damage

	if challenge_system:
		challenge_system.record_damage_taken(damage)


## 记录玩家死亡
func record_player_death() -> void:
	"""记录玩家死亡"""
	if challenge_system:
		challenge_system.record_death()


## 记录收集技能
func record_skill_collected(skill_id: String) -> void:
	"""
	记录收集的技能
	@param skill_id: 技能ID
	"""
	if challenge_system:
		challenge_system.record_skill_collected(skill_id)


## 记录到达层数
func record_level_reached(level: int) -> void:
	"""
	记录到达的层数
	@param level: 层数
	"""
	if challenge_system:
		challenge_system.record_level_reached(level)


## 获取当前角色
func get_current_character() -> CharacterBase:
	"""
	获取当前角色对象
	@return: 角色对象
	"""
	if challenge_system:
		return challenge_system.get_current_character()
	return null


## 获取当前角色基础属性
func get_current_character_stats() -> Dictionary:
	"""
	获取当前角色的基础属性
	@return: 属性字典
	"""
	if challenge_system:
		return challenge_system.get_current_character_base_stats()
	return {}


## 触发角色被动 - 攻击
func trigger_character_attack_passive(attack_data: Dictionary) -> Dictionary:
	"""
	触发角色攻击时的被动效果
	@param attack_data: 攻击数据
	@return: 修改后的攻击数据
	"""
	if challenge_system:
		return challenge_system.trigger_attack_passive(attack_data)
	return attack_data


## 触发角色被动 - 受伤
func trigger_character_damage_passive(damage_data: Dictionary) -> Dictionary:
	"""
	触发角色受伤时的被动效果
	@param damage_data: 伤害数据
	@return: 修改后的伤害数据
	"""
	if challenge_system:
		return challenge_system.trigger_damage_passive(damage_data)
	return damage_data


## 触发角色被动 - 帧更新
func trigger_character_process_passive(delta: float, player_stats: Dictionary) -> Dictionary:
	"""
	触发角色每帧更新的被动效果
	@param delta: 帧间隔
	@param player_stats: 玩家属性
	@return: 效果数据
	"""
	if challenge_system:
		return challenge_system.trigger_process_passive(delta, player_stats)
	return {}


## 触发角色被动 - 死亡
func trigger_character_death_passive() -> Dictionary:
	"""
	触发角色死亡时的被动效果
	@return: 效果数据
	"""
	if challenge_system:
		return challenge_system.trigger_death_passive()
	return {}


## 触发角色被动 - 游戏开始
func trigger_character_game_start_passive() -> Dictionary:
	"""
	触发游戏开始时的被动效果
	@return: 效果数据
	"""
	if challenge_system:
		return challenge_system.trigger_game_start_passive()
	return {}


## 更新难度系数
func update_difficulty() -> void:
	"""
	根据当前进度更新难度系数
	"""
	difficulty_multiplier = pow(DIFFICULTY_SCALING, current_level_index - 1)
	
	if current_game_mode == GameMode.ENDLESS:
		difficulty_multiplier *= 1.0 + (current_level_index - MAX_LEVELS) * 0.1


## 获取游戏统计信息
func get_game_stats() -> Dictionary:
	"""
	获取当前游戏统计信息
	@return: 统计信息字典
	"""
	return {
		"game_time": game_time,
		"enemies_killed": enemies_killed,
		"gold_collected": gold_collected,
		"damage_dealt": total_damage_dealt,
		"damage_taken": total_damage_taken,
		"level_reached": current_level_index,
		"difficulty": difficulty_multiplier
	}


## 返回主菜单
func return_to_main_menu() -> void:
	"""
	返回主菜单
	"""
	get_tree().paused = false
	_pause_stack.clear()
	_reset_game_stats()
	set_game_state(GameState.MENU)
	get_tree().change_scene_to_file("res://scenes/main.tscn")

# =============================================================================
# 私有方法
# =============================================================================

func _initialize_game_manager() -> void:
	"""
	初始化游戏管理器内部状态
	"""
	_is_initialized = true

	# 加载已解锁内容
	var unlock_data: Dictionary = SaveManager.load_unlock_data()
	if unlock_data.has("characters"):
		unlocked_characters = unlock_data["characters"]

	# 连接其他管理器信号
	_connect_manager_signals()

	# 初始化挑战系统
	_initialize_challenge_system()

	if debug_mode:
		print("[GameManager] 初始化完成")


func _initialize_challenge_system() -> void:
	"""
	初始化挑战系统
	"""
	# 获取或创建挑战系统
	challenge_system = ChallengeSystem.get_instance()
	if challenge_system:
		# 连接挑战系统信号
		if not challenge_system.character_unlocked.is_connected(_on_challenge_character_unlocked):
			challenge_system.character_unlocked.connect(_on_challenge_character_unlocked)

		# 同步解锁角色列表
		unlocked_characters = challenge_system.get_unlocked_characters()


func _on_challenge_character_unlocked(char_id: String, char_name: String) -> void:
	"""
	挑战系统角色解锁回调
	@param char_id: 角色ID
	@param char_name: 角色名称
	"""
	# 转发信号
	character_unlocked.emit(char_id, char_name)
	achievement_unlocked.emit("character_" + char_id)


func _connect_manager_signals() -> void:
	"""
	连接其他管理器的信号
	"""
	# 这里可以连接其他全局管理器的信号
	pass


func _reset_game_stats() -> void:
	"""
	重置游戏统计数据
	"""
	current_level_index = 0
	game_time = 0.0
	enemies_killed = 0
	gold_collected = 0
	total_damage_dealt = 0.0
	total_damage_taken = 0.0
	difficulty_multiplier = 1.0
	current_wave = 0
	total_experience = 0


func _load_level(level_index: int) -> void:
	"""
	加载指定关卡
	@param level_index: 关卡索引
	"""
	set_game_state(GameState.LOADING)
	current_level_index = level_index
	update_difficulty()
	
	# 通知关卡生成器生成新关卡
	# 实际的关卡加载逻辑在 LevelGenerator 中处理
	var level_data: Dictionary = {
		"level_index": level_index,
		"difficulty": difficulty_multiplier,
		"game_mode": current_game_mode
	}
	
	level_changed.emit(str(level_index), level_data)
	set_game_state(GameState.PLAYING)


func _on_state_enter(state: GameState) -> void:
	"""
	进入新状态时的处理
	@param state: 新状态
	"""
	match state:
		GameState.PAUSED:
			get_tree().paused = true
		GameState.PLAYING:
			get_tree().paused = false
		GameState.SKILL_SELECTION:
			# 暂停游戏以进行技能选择
			get_tree().paused = true


func _handle_revival() -> void:
	"""
	处理复活逻辑（无尽模式）
	"""
	# 扣除金币作为复活代价
	gold_collected = maxi(0, gold_collected - 100)
	# 通知玩家复活
	# 实际的复活逻辑在 Player 中处理


func _trigger_victory() -> void:
	"""
	触发胜利
	"""
	trigger_game_over(true)


func _collect_final_stats() -> Dictionary:
	"""
	收集最终统计信息
	@return: 统计信息字典
	"""
	return get_game_stats()


func _generate_save_data() -> Dictionary:
	"""
	生成存档数据
	@return: 存档数据字典
	"""
	return {
		"version": ProjectSettings.get_setting("application/config/version"),
		"timestamp": Time.get_unix_time_from_system(),
		"game_mode": current_game_mode,
		"level_index": current_level_index,
		"stats": get_game_stats(),
		"unlocked_characters": unlocked_characters
	}


func _apply_save_data(save_data: Dictionary) -> void:
	"""
	应用存档数据
	@param save_data: 存档数据
	"""
	current_level_index = save_data.get("level_index", 1)
	current_game_mode = save_data.get("game_mode", GameMode.STANDARD)
	
	var stats: Dictionary = save_data.get("stats", {})
	game_time = stats.get("game_time", 0.0)
	enemies_killed = stats.get("enemies_killed", 0)
	gold_collected = stats.get("gold_collected", 0)
	total_damage_dealt = stats.get("damage_dealt", 0.0)
	total_damage_taken = stats.get("damage_taken", 0.0)
	
	unlocked_characters = save_data.get("unlocked_characters", ["warrior"])
	update_difficulty()


func _on_game_close() -> void:
	"""
	游戏关闭时的处理
	"""
	if current_state == GameState.PLAYING:
		SaveManager.save_game(_generate_save_data())
	get_tree().quit()


func _on_back_pressed() -> void:
	"""
	返回键按下时的处理（移动端）
	"""
	if current_state == GameState.PLAYING:
		pause_game()
	elif current_state == GameState.PAUSED:
		resume_game()
	elif current_state not in [GameState.MENU, GameState.LOADING]:
		return_to_main_menu()
