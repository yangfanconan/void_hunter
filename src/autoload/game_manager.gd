## Void Hunter - 游戏管理器
## @description: 全局游戏状态管理器

extends Node

enum GameState { MENU, CHARACTER_SELECT, LOADING, PLAYING, PAUSED, GAME_OVER, SKILL_SELECTION, INVENTORY }

signal state_changed(new_state: GameState)
signal wave_changed(wave: int)
signal enemy_killed(enemy_type: String)
signal gold_changed(amount: int)
signal difficulty_changed(multiplier: float)

var current_state: GameState = GameState.MENU
var current_wave: int = 1
var total_kills: int = 0
var enemies_killed: int = 0
var game_time: float = 0.0
var gold_collected: int = 0
var selected_character: String = "wandering_swordsman"
var difficulty_multiplier: float = 1.0
var is_paused: bool = false

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

func get_selected_character() -> String:
	return selected_character

func set_wave(wave: int) -> void:
	current_wave = wave
	difficulty_multiplier = 1.0 + (wave - 1) * 0.1
	difficulty_changed.emit(difficulty_multiplier)
	wave_changed.emit(wave)

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

func handle_game_victory() -> void:
	print("[GameManager] 游戏胜利!")
	print("[GameManager] 总时间: %.1f 秒" % game_time)
	print("[GameManager] 总击杀: %d" % total_kills)

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
