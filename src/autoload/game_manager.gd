## Void Hunter - 游戏管理器
## @description: 全局游戏状态管理器

extends Node

enum GameState { MENU, CHARACTER_SELECT, LOADING, PLAYING, PAUSED, GAME_OVER, SKILL_SELECTION, INVENTORY }

signal state_changed(new_state: GameState)
signal wave_changed(wave: int)
signal enemy_killed(enemy_type: String)
signal gold_changed(amount: int)
signal difficulty_changed(multiplier: float)
signal account_exp_gained(amount: int, reason: String)

var current_state: GameState = GameState.MENU
var current_wave: int = 1
var total_kills: int = 0
var enemies_killed: int = 0
var game_time: float = 0.0
var gold_collected: int = 0
var selected_character: String = "wandering_swordsman"
var difficulty_multiplier: float = 1.0
var is_paused: bool = false

# 账户经验奖励配置
const EXP_PER_ENEMY: int = 10
const EXP_PER_ELITE: int = 50
const EXP_PER_BOSS: int = 200
const EXP_PER_WAVE: int = 30
const EXP_PER_MINUTE: int = 5

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("[GameManager] 初始化完成")

func _process(_delta: float) -> void:
	if current_state == GameState.PLAYING:
		game_time += _delta

func change_state(new_state: GameState) -> void:
	if current_state == new_state:
		return
	current_state = new_state
	state_changed.emit(new_state)

func record_enemy_kill(is_elite: bool = false) -> void:
	total_kills += 1
	enemies_killed += 1
	enemy_killed.emit("normal" if not is_elite else "elite")

	# 给账户经验
	var exp_amount: int = EXP_PER_ELITE if is_elite else EXP_PER_ENEMY
	_add_account_exp(exp_amount, "kill")

func record_boss_kill() -> void:
	_add_account_exp(EXP_PER_BOSS, "boss_kill")

func get_selected_character() -> String:
	return selected_character

func set_wave(wave: int) -> void:
	current_wave = wave
	difficulty_multiplier = 1.0 + (wave - 1) * 0.1
	difficulty_changed.emit(difficulty_multiplier)
	wave_changed.emit(wave)

	# 波次奖励经验
	_add_account_exp(EXP_PER_WAVE * wave, "wave_complete")

func add_game_time(delta: float) -> void:
	game_time += delta

func add_gold(amount: int) -> void:
	gold_collected += amount
	gold_changed.emit(gold_collected)

func reset_game() -> void:
	current_wave = 1
	total_kills = 0
	enemies_killed = 0
	game_time = 0.0
	gold_collected = 0
	difficulty_multiplier = 1.0
	current_state = GameState.MENU
	is_paused = false

func toggle_pause() -> void:
	is_paused = not is_paused
	if is_paused:
		change_state(GameState.PAUSED)
	else:
		change_state(GameState.PLAYING)

func handle_player_death(_stats_data: Dictionary = {}) -> void:
	change_state(GameState.GAME_OVER)
	print("[GameManager] 玩家死亡!")
	print("[GameManager] 存活时间: %.1f 秒" % game_time)
	print("[GameManager] 总击杀: %d" % total_kills)

	# 结算账户经验
	_settle_account_exp()

func handle_game_victory() -> void:
	print("[GameManager] 游戏胜利!")
	print("[GameManager] 总时间: %.1f 秒" % game_time)
	print("[GameManager] 总击杀: %d" % total_kills)

	# 结算账户经验（胜利额外奖励）
	_settle_account_exp(true)

func get_current_wave() -> int:
	return current_wave

func get_total_kills() -> int:
	return total_kills

func set_game_state(new_state: GameState) -> void:
	change_state(new_state)

func trigger_game_over(is_victory: bool = false) -> void:
	if is_victory:
		handle_game_victory()
	else:
		change_state(GameState.GAME_OVER)

func get_game_data() -> Dictionary:
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

func load_game_data(data: Dictionary) -> void:
	current_wave = data.get("wave", 1)
	total_kills = data.get("kills", 0)
	enemies_killed = data.get("enemies_killed", 0)
	game_time = data.get("time", 0.0)
	gold_collected = data.get("gold", 0)
	difficulty_multiplier = data.get("difficulty", 1.0)
	selected_character = data.get("character", "wandering_swordsman")

# =============================================================================
# 账户经验系统
# =============================================================================

func _get_permanent_growth() -> Node:
	"""安全获取永久成长系统"""
	var root = get_tree().root if get_tree() else null
	if root:
		return root.get_node_or_null("PermanentGrowth")
	return null

func _add_account_exp(amount: int, reason: String) -> void:
	"""添加账户经验"""
	var pg = _get_permanent_growth()
	if pg:
		# 应用经验加成天赋
		var bonuses: Dictionary = pg.get_permanent_bonuses()
		var exp_bonus: float = bonuses.get("exp_bonus", 0.0)
		var final_amount: int = int(amount * (1.0 + exp_bonus))
		pg.add_account_experience(final_amount, reason)
		account_exp_gained.emit(final_amount, reason)

func _settle_account_exp(is_victory: bool = false) -> void:
	"""结算游戏结束时的账户经验"""
	var total_exp: int = 0

	# 时间奖励
	var minutes: int = int(game_time / 60.0)
	total_exp += minutes * EXP_PER_MINUTE

	# 击杀奖励已实时结算，这里只加额外奖励

	# 胜利奖励
	if is_victory:
		total_exp += 500 + current_wave * 50

	if total_exp > 0:
		var pg = _get_permanent_growth()
		if pg:
			pg.add_account_experience(total_exp, "game_settlement")
			print("[GameManager] 结算经验: %d" % total_exp)

func get_permanent_bonuses() -> Dictionary:
	"""获取永久属性加成"""
	var pg = _get_permanent_growth()
	if pg:
		return pg.get_permanent_bonuses()
	return {}
