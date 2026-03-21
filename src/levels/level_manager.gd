## level_manager.gd - 关卡管理器
## 整合关卡生成、场景切换、进度保存等功能
## 作为单例(Autoload)使用，提供统一的关卡管理接口

class_name LevelManager
extends Node

# ==================== 信号定义 ====================
## 关卡开始信号
signal level_started(level_data: Dictionary)
## 关卡完成信号
signal level_completed(level_data: Dictionary)
## 关卡失败信号
signal level_failed(reason: String)
## 新关卡生成信号
signal new_level_generating(theme: int, depth: int)
## 关卡加载进度信号
signal level_load_progress(progress: float, stage: String)
## 玩家位置更新信号
signal player_position_updated(position: Vector2)

# ==================== 常量定义 ====================
## 存档路径
const SAVE_PATH: String = "user://level_save.dat"
## 关卡场景路径模板
const LEVEL_SCENE_PATH: String = "res://scenes/levels/level_%d.tscn"
## 最大关卡深度
const MAX_DEPTH: int = 100

# ==================== 成员变量 ====================
## 当前关卡深度
var _current_depth: int = 0
## 当前关卡种子
var _current_seed: int = 0
## 当前主题
var _current_theme: ThemeGenerator.ThemeType = ThemeGenerator.ThemeType.FOREST
## 关卡历史（用于回溯）
var _level_history: Array = []
## 当前关卡数据
var _current_level_data: Dictionary = {}
## 关卡生成器
var _level_generator: LevelGenerator
## 场景切换系统
var _scene_transition: SceneTransition
## 游戏状态
var _game_state: Dictionary = {}
## 玩家引用
var _player: Node = null
## 是否在关卡中
var _in_level: bool = false
## 暂停状态
var _is_paused: bool = false
## 主题序列（关卡主题变化）
var _theme_sequence: Array[ThemeGenerator.ThemeType] = [
	ThemeGenerator.ThemeType.FOREST,
	ThemeGenerator.ThemeType.CAVE,
	ThemeGenerator.ThemeType.DESERT,
	ThemeGenerator.ThemeType.RUINS,
	ThemeGenerator.ThemeType.VOID
]

# ==================== 初始化函数 ====================

## 初始化关卡管理器
func _ready() -> void:
	_setup_level_generator()
	_setup_signals()
	_load_game_state()


## 设置关卡生成器
func _setup_level_generator() -> void:
	_level_generator = LevelGenerator.new()
	add_child(_level_generator)


## 设置信号连接
func _setup_signals() -> void:
	# 连接关卡生成器信号
	_level_generator.generation_started.connect(_on_generation_started)
	_level_generator.generation_progress.connect(_on_generation_progress)
	_level_generator.generation_completed.connect(_on_generation_completed)


## 创建场景切换系统（需要在场景树中）
func setup_scene_transition() -> void:
	if _scene_transition:
		return
	
	_scene_transition = SceneTransition.new()
	get_tree().root.add_child(_scene_transition)

# ==================== 公共接口 ====================

## 开始新游戏
## @param seed: 游戏种子（0表示随机）
func start_new_game(seed: int = 0) -> void:
	_current_depth = 0
	_current_seed = seed if seed != 0 else _generate_seed()
	_level_history.clear()
	_game_state = _create_initial_game_state()
	
	# 开始第一个关卡
	enter_next_level()


## 继续游戏（从存档）
func continue_game() -> bool:
	var save_data: Dictionary = _load_save_data()
	if save_data.is_empty():
		push_warning("No save data found")
		return false
	
	# 恢复游戏状态
	_current_depth = save_data.get("depth", 0)
	_current_seed = save_data.get("seed", 0)
	_game_state = save_data.get("game_state", {})
	_level_history = save_data.get("level_history", [])
	
	# 重新生成当前关卡
	_generate_level_from_seed(_current_seed, _current_theme)
	
	return true


## 进入下一层关卡
func enter_next_level() -> void:
	_current_depth += 1
	_current_theme = _get_theme_for_depth(_current_depth)
	
	# 检查是否到达最大深度
	if _current_depth > MAX_DEPTH:
		_on_game_completed()
		return
	
	# 生成新关卡
	new_level_generating.emit(_current_theme, _current_depth)
	
	# 使用场景切换
	if _scene_transition:
		_scene_transition.fade_out(SceneTransition.TransitionType.FADE_TO_BLACK, 0.5)
		await _scene_transition.transition_midpoint
	
	# 生成关卡
	_generate_current_level()
	
	# 记录到历史
	_level_history.append({
		"depth": _current_depth,
		"seed": _current_seed,
		"theme": _current_theme
	})
	
	# 保存进度
	save_game()
	
	# 淡入
	if _scene_transition:
		_scene_transition.fade_in(SceneTransition.TransitionType.FADE_FROM_BLACK, 0.5)


## 返回上一层（如果可能）
func return_to_previous_level() -> bool:
	if _level_history.size() <= 1:
		push_warning("Cannot return to previous level")
		return false
	
	# 移除当前关卡记录
	_level_history.pop_back()
	
	# 恢复上一关卡数据
	var prev_level: Dictionary = _level_history.back()
	_current_depth = prev_level.depth
	_current_seed = prev_level.seed
	_current_theme = prev_level.theme
	
	# 重新生成关卡
	_generate_level_from_seed(_current_seed, _current_theme)
	
	return true


## 完成当前关卡
func complete_current_level() -> void:
	if not _in_level:
		return
	
	# 记录完成数据
	var completion_data: Dictionary = {
		"depth": _current_depth,
		"time": Time.get_ticks_msec(),
		"items_collected": _game_state.get("items_collected", 0),
		"enemies_defeated": _game_state.get("enemies_defeated", 0)
	}
	
	level_completed.emit(_current_level_data)
	
	# 进入下一层
	enter_next_level()


## 当前关卡失败
func fail_current_level(reason: String = "death") -> void:
	level_failed.emit(reason)
	
	# 根据失败原因处理
	match reason:
		"death":
			# 玩家死亡，可以选择重新开始或从检查点复活
			_handle_player_death()
		"trap":
			# 陷阱死亡
			_handle_player_death()
		_:
			_handle_player_death()


## 保存游戏
func save_game() -> void:
	var save_data: Dictionary = {
		"depth": _current_depth,
		"seed": _current_seed,
		"theme": _current_theme,
		"game_state": _game_state,
		"level_history": _level_history,
		"timestamp": Time.get_datetime_dict_from_system()
	}
	
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()


## 加载存档数据
func _load_save_data() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var data: Dictionary = file.get_var()
		file.close()
		return data
	
	return {}


## 暂停游戏
func pause_game() -> void:
	if _is_paused:
		return
	
	_is_paused = true
	get_tree().paused = true


## 恢复游戏
func resume_game() -> void:
	if not _is_paused:
		return
	
	_is_paused = false
	get_tree().paused = false


## 退出到主菜单
func exit_to_main_menu() -> void:
	_in_level = false
	save_game()
	
	if _scene_transition:
		_scene_transition.transition_to_scene(
			"res://scenes/main_menu.tscn",
			SceneTransition.TransitionType.FADE_TO_BLACK,
			1.0,
			false
		)
	else:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

# ==================== 关卡生成 ====================

## 生成当前关卡
func _generate_current_level() -> void:
	# 生成新种子（每层不同）
	var level_seed: int = _current_seed + _current_depth * 1000
	
	_current_level_data = _level_generator.generate_level(
		level_seed,
		_current_theme,
		128,
		128
	)
	
	_in_level = true
	level_started.emit(_current_level_data)


## 从种子生成关卡（用于恢复）
func _generate_level_from_seed(seed: int, theme: ThemeGenerator.ThemeType) -> void:
	_current_level_data = _level_generator.generate_level(
		seed,
		theme,
		128,
		128
	)
	
	_in_level = true
	level_started.emit(_current_level_data)


## 获取指定深度的主题
func _get_theme_for_depth(depth: int) -> ThemeGenerator.ThemeType:
	# 循环使用主题序列，但随深度增加难度
	var theme_index: int = (depth - 1) % _theme_sequence.size()
	return _theme_sequence[theme_index]

# ==================== 玩家管理 ====================

## 注册玩家
func register_player(player: Node) -> void:
	_player = player
	player.tree_exited.connect(_on_player_removed)


## 获取玩家
func get_player() -> Node:
	return _player


## 获取玩家位置
func get_player_position() -> Vector2:
	if _player and "global_position" in _player:
		return _player.global_position
	return Vector2.ZERO


## 更新玩家状态到游戏状态
func update_player_state() -> void:
	if not _player:
		return
	
	_game_state["player_health"] = _player.get("health") if "health" in _player else 100
	_game_state["player_gold"] = _player.get("gold") if "gold" in _player else 0
	_game_state["player_experience"] = _player.get("experience") if "experience" in _player else 0


## 处理玩家死亡
func _handle_player_death() -> void:
	# 增加死亡计数
	_game_state["death_count"] = _game_state.get("death_count", 0) + 1
	
	# 检查是否有复活次数
	var revives: int = _game_state.get("revives_remaining", 0)
	if revives > 0:
		_game_state["revives_remaining"] = revives - 1
		_revive_player()
	else:
		# 游戏结束
		_on_game_over()

# ==================== 关卡数据获取 ====================

## 获取当前关卡数据
func get_current_level_data() -> Dictionary:
	return _current_level_data


## 获取当前深度
func get_current_depth() -> int:
	return _current_depth


## 获取当前主题
func get_current_theme() -> ThemeGenerator.ThemeType:
	return _current_theme


## 获取关卡生成器（用于调试）
func get_level_generator() -> LevelGenerator:
	return _level_generator


## 获取地形网格
func get_terrain_grid() -> Array:
	return _current_level_data.get("terrain", [])


## 获取起点位置
func get_start_position() -> Vector2i:
	return _current_level_data.get("start_position", Vector2i(64, 64))


## 获取终点位置
func get_end_position() -> Vector2i:
	return _current_level_data.get("end_position", Vector2i(64, 64))


## 获取敌人刷新点
func get_enemy_spawn_points() -> Array:
	var elements: Dictionary = _current_level_data.get("elements", {})
	return elements.get("enemy_spawns", [])


## 获取道具列表
func get_items() -> Array:
	var elements: Dictionary = _current_level_data.get("elements", {})
	return elements.get("items", [])


## 获取陷阱列表
func get_traps() -> Array:
	var elements: Dictionary = _current_level_data.get("elements", {})
	return elements.get("traps", [])


## 获取互动元素列表
func get_interactives() -> Array:
	var elements: Dictionary = _current_level_data.get("elements", {})
	return elements.get("interactives", [])


## 获取秘密区域列表
func get_secrets() -> Array:
	var elements: Dictionary = _current_level_data.get("elements", {})
	return elements.get("secrets", [])


## 获取游戏状态
func get_game_state() -> Dictionary:
	return _game_state.duplicate()

# ==================== 关卡元素操作 ====================

## 移除道具
func remove_item(item_id: int) -> void:
	var items: Array = get_items()
	for i in range(items.size()):
		if items[i].get("id", -1) == item_id:
			items.remove_at(i)
			_game_state["items_collected"] = _game_state.get("items_collected", 0) + 1
			break


## 激活互动元素
func activate_interactive(interactive_id: int) -> void:
	var interactives: Array = get_interactives()
	for interactive in interactives:
		if interactive.get("id", -1) == interactive_id:
			interactive["activated"] = true
			break


## 发现秘密
func discover_secret(secret_id: int) -> void:
	var secrets: Array = get_secrets()
	for secret in secrets:
		if secret.get("id", -1) == secret_id:
			secret["discovered"] = true
			_game_state["secrets_found"] = _game_state.get("secrets_found", 0) + 1
			break


## 击败敌人
func defeat_enemy(enemy_id: int) -> void:
	_game_state["enemies_defeated"] = _game_state.get("enemies_defeated", 0) + 1


## 检查位置是否可行走
func is_position_walkable(world_pos: Vector2) -> bool:
	var grid_pos: Vector2i = _world_to_grid(world_pos)
	var terrain: Array = get_terrain_grid()
	
	if grid_pos.x < 0 or grid_pos.x >= terrain[0].size():
		return false
	if grid_pos.y < 0 or grid_pos.y >= terrain.size():
		return false
	
	var terrain_type: int = terrain[grid_pos.y][grid_pos.x]
	return terrain_type == ThemeGenerator.TerrainType.GROUND or \
		   terrain_type == ThemeGenerator.TerrainType.SAND or \
		   terrain_type == ThemeGenerator.TerrainType.PLATFORM


## 世界坐标转网格坐标
func _world_to_grid(world_pos: Vector2) -> Vector2i:
	# 假设每个网格单元为32像素
	var cell_size: int = 32
	return Vector2i(int(world_pos.x / cell_size), int(world_pos.y / cell_size))

# ==================== 回调函数 ====================

## 关卡生成开始回调
func _on_generation_started(seed: int, theme: int) -> void:
	level_load_progress.emit(0.0, "开始生成关卡")


## 关卡生成进度回调
func _on_generation_progress(stage: String, progress: float) -> void:
	level_load_progress.emit(progress, stage)


## 关卡生成完成回调
func _on_generation_completed(level_data: Dictionary) -> void:
	level_load_progress.emit(1.0, "完成")


## 玩家节点移除回调
func _on_player_removed() -> void:
	_player = null


## 游戏完成回调
func _on_game_completed() -> void:
	# 触发游戏胜利流程
	_game_state["game_completed"] = true
	_game_state["completion_time"] = Time.get_ticks_msec()
	
	# 可以切换到结局场景
	if _scene_transition:
		_scene_transition.transition_to_scene(
			"res://scenes/victory_screen.tscn",
			SceneTransition.TransitionType.FADE_TO_WHITE,
			2.0,
			false
		)


## 游戏结束回调
func _on_game_over() -> void:
	# 触发游戏失败流程
	if _scene_transition:
		_scene_transition.transition_to_scene(
			"res://scenes/game_over.tscn",
			SceneTransition.TransitionType.FADE_TO_BLACK,
			1.5,
			false
		)

# ==================== 辅助函数 ====================

## 创建初始游戏状态
func _create_initial_game_state() -> Dictionary:
	return {
		"player_health": 100,
		"player_max_health": 100,
		"player_gold": 0,
		"player_experience": 0,
		"items_collected": 0,
		"enemies_defeated": 0,
		"secrets_found": 0,
		"death_count": 0,
		"revives_remaining": 1,
		"game_completed": false,
		"start_time": Time.get_ticks_msec()
	}


## 加载游戏状态
func _load_game_state() -> void:
	var save_data: Dictionary = _load_save_data()
	if not save_data.is_empty():
		_game_state = save_data.get("game_state", _create_initial_game_state())
	else:
		_game_state = _create_initial_game_state()


## 生成随机种子
func _generate_seed() -> int:
	return randi()


## 复活玩家
func _revive_player() -> void:
	if _player and "health" in _player:
		_player.health = _player.get("max_health", 100)
		_player.global_position = get_start_position()

# ==================== 调试功能 ====================

## 启用调试模式
func enable_debug_mode(enable: bool = true) -> void:
	if _level_generator:
		_level_generator.enable_debug_mode(enable)


## 获取调试纹理
func get_debug_texture() -> ImageTexture:
	if _level_generator:
		return _level_generator.get_debug_texture()
	return null


## 跳转到指定深度（调试用）
func debug_jump_to_depth(depth: int) -> void:
	if OS.is_debug_build():
		_current_depth = depth - 1
		enter_next_level()


## 重新生成当前关卡（调试用）
func debug_regenerate_level() -> void:
	if OS.is_debug_build():
		_generate_current_level()
