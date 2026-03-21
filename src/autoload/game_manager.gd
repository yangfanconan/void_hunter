## Void Hunter - 游戏管理器
## @description: 全局游戏状态管理器，管理游戏数据、波次、统计等
## @author: Void Hunter Team
## @version: 1.0.0

extends Node

# =============================================================================
# 枚举定义
# =============================================================================

enum GameState { MENU, CHARACTER_SELECT, LOADING, PLAYING, PAUSED, GAME_OVER, SKILL_SELECTION, INVENTORY }

# =============================================================================
# 信号定义
# =============================================================================

signal state_changed(new_state: GameState)
signal wave_changed(wave: int)
signal enemy_killed(enemy_type: String)
signal gold_changed(amount: int)
signal difficulty_changed(multiplier: float)

# =============================================================================
# 公共变量
# =============================================================================

## 当前游戏状态
var current_state: GameState = GameState.MENU

## 当前波次
var current_wave: int = 1

## 总击杀数
var total_kills: int = 0

## 本局击杀数
var enemies_killed: int = 0

## 游戏时间
var game_time: float = 0.0

## 金币
var gold_collected: int = 0

## 选中的角色
var selected_character: String = "wandering_swordsman"

## 难度系数
var difficulty_multiplier: float = 1.0

## 是否暂停
var is_paused: bool = false

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""节点就绪"""
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("[GameManager] 初始化完成")


func _process(_delta: float) -> void:
	"""每帧更新"""
	if current_state == GameState.PLAYING:
		game_time += _delta

# =============================================================================
# 公共方法 - 状态管理
# =============================================================================

## 切换游戏状态
func change_state(new_state: GameState) -> void:
	"""切换游戏状态"""
	if current_state == new_state:
		return
	current_state = new_state
	state_changed.emit(new_state)


## 设置游戏状态
func set_game_state(new_state: GameState) -> void:
	"""设置游戏状态"""
	change_state(new_state)


## 开始角色选择
func start_character_selection() -> void:
	"""开始角色选择"""
	change_state(GameState.CHARACTER_SELECT)


## 选择角色并开始游戏
func select_character_and_start(character_id: String) -> void:
	"""选择角色并开始游戏"""
	selected_character = character_id
	change_state(GameState.PLAYING)

# =============================================================================
# 公共方法 - 游戏数据
# =============================================================================

## 记录敌人击杀
func record_enemy_kill(is_elite: bool = false) -> void:
	"""记录敌人击杀"""
	total_kills += 1
	enemies_killed += 1
	enemy_killed.emit("normal" if not is_elite else "elite")


## 获取选中的角色
func get_selected_character() -> String:
	"""获取选中的角色"""
	return selected_character


## 获取当前波次
func get_current_wave() -> int:
	"""获取当前波次"""
	return current_wave


## 获取总击杀数
func get_total_kills() -> int:
	"""获取总击杀数"""
	return total_kills


## 获取本局击杀数
func get_enemies_killed() -> int:
	"""获取本局击杀数"""
	return enemies_killed


## 获取游戏时间
func get_game_time() -> float:
	"""获取游戏时间"""
	return game_time


## 获取格式化的游戏时间
func get_formatted_game_time() -> String:
	"""获取格式化的游戏时间"""
	var mins: int = int(game_time) / 60
	var secs: int = int(game_time) % 60
	return "%02d:%02d" % [mins, secs]

# =============================================================================
# 公共方法 - 设置数据
# =============================================================================

## 设置波次
func set_wave(wave: int) -> void:
	"""设置当前波次"""
	current_wave = wave
	# 更新难度系数
	difficulty_multiplier = 1.0 + (wave - 1) * 0.1
	difficulty_changed.emit(difficulty_multiplier)
	wave_changed.emit(wave)


## 增加游戏时间
func add_game_time(delta: float) -> void:
	"""增加游戏时间"""
	game_time += delta


## 增加金币
func add_gold(amount: int) -> void:
	"""增加金币"""
	gold_collected += amount
	gold_changed.emit(gold_collected)


## 消耗金币
func spend_gold(amount: int) -> bool:
	"""消耗金币"""
	if gold_collected >= amount:
		gold_collected -= amount
		gold_changed.emit(gold_collected)
		return true
	return false

# =============================================================================
# 公共方法 - 游戏控制
# =============================================================================

## 重置游戏
func reset_game() -> void:
	"""重置游戏状态"""
	current_wave = 1
	total_kills = 0
	enemies_killed = 0
	game_time = 0.0
	gold_collected = 0
	difficulty_multiplier = 1.0
	current_state = GameState.MENU
	is_paused = false


## 切换暂停
func toggle_pause() -> void:
	"""切换暂停状态"""
	is_paused = not is_paused
	if is_paused:
		change_state(GameState.PAUSED)
	else:
		change_state(GameState.PLAYING)


## 处理玩家死亡
func handle_player_death(_stats_data: Dictionary = {}) -> void:
	"""处理玩家死亡"""
	change_state(GameState.GAME_OVER)
	print("[GameManager] 玩家死亡!")
	print("[GameManager] 存活时间: %.1f 秒" % game_time)
	print("[GameManager] 总击杀: %d" % total_kills)


## 处理游戏胜利
func handle_game_victory() -> void:
	"""处理游戏胜利"""
	print("[GameManager] 游戏胜利!")
	print("[GameManager] 总时间: %.1f 秒" % game_time)
	print("[GameManager] 总击杀: %d" % total_kills)

# =============================================================================
# 公共方法 - 数据导出
# =============================================================================

## 获取游戏数据
func get_game_data() -> Dictionary:
	"""获取游戏数据字典"""
	return {
		"wave": current_wave,
		"kills": total_kills,
		"enemies_killed": enemies_killed,
		"time": game_time,
		"gold": gold_collected,
		"difficulty": difficulty_multiplier,
		"character": selected_character,
		"state": GameState.keys()[current_state]
	}


## 从字典加载数据
func load_game_data(data: Dictionary) -> void:
	"""从字典加载游戏数据"""
	current_wave = data.get("wave", 1)
	total_kills = data.get("kills", 0)
	enemies_killed = data.get("enemies_killed", 0)
	game_time = data.get("time", 0.0)
	gold_collected = data.get("gold", 0)
	difficulty_multiplier = data.get("difficulty", 1.0)
	selected_character = data.get("character", "wandering_swordsman")
