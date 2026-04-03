## Void Hunter - 排行榜管理器
## @description: 管理本地排行榜数据，支持多个排行榜类别
## @author: Void Hunter Team
## @version: 1.0.0

extends Node

# =============================================================================
# 信号定义
# =============================================================================

## 排行榜更新时触发
signal leaderboard_updated(category: String)

## 新纪录进入排行榜时触发
signal new_record_added(category: String, rank: int, record: Dictionary)

# =============================================================================
# 常量定义
# =============================================================================

## 排行榜数据保存路径
const LEADERBOARD_PATH := "user://leaderboard.dat"

## 每个排行榜最大记录数
const MAX_RECORDS_PER_CATEGORY: int = 10

## 排行榜类别
enum LeaderboardCategory {
	SURVIVAL_TIME,		## 存活时间
	KILLS,				## 击杀数
	WAVE_REACHED,		## 波次到达
	DAMAGE_DEALT,		## 伤害输出
	COMBO_MAX,			## 最大连击
	GOLD_COLLECTED,		## 金币收集
	SPEEDRUN,			## 速度通关
}

## 排行榜类别名称映射
const CATEGORY_NAMES: Dictionary = {
	LeaderboardCategory.SURVIVAL_TIME: "存活时间",
	LeaderboardCategory.KILLS: "击杀数",
	LeaderboardCategory.WAVE_REACHED: "波次记录",
	LeaderboardCategory.DAMAGE_DEALT: "伤害输出",
	LeaderboardCategory.COMBO_MAX: "最大连击",
	LeaderboardCategory.GOLD_COLLECTED: "金币收集",
	LeaderboardCategory.SPEEDRUN: "速度通关",
}

# =============================================================================
# 私有变量
# =============================================================================

## 各类别排行榜数据
var _leaderboards: Dictionary = {}

## 是否已初始化
var _initialized: bool = false

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""节点就绪时初始化"""
	_initialize()

# =============================================================================
# 公共方法 - 初始化
# =============================================================================

func _initialize() -> void:
	"""初始化排行榜系统"""
	_load_leaderboards()
	_initialized = true
	print("[LeaderboardManager] 初始化完成")

# =============================================================================
# 公共方法 - 记录提交
# =============================================================================

## 提交游戏记录
func submit_game_record(player_name: String, stats: Dictionary) -> Dictionary:
	"""提交游戏记录到所有相关排行榜

	@param player_name: 玩家名称
	@param stats: 游戏统计数据
	@return: 返回各排行榜的排名信息
	"""
	var results: Dictionary = {}

	# 存活时间排行榜
	var survival_time: float = stats.get("game_time", 0.0)
	if survival_time > 0:
		var rank: int = _add_record(
			LeaderboardCategory.SURVIVAL_TIME,
			player_name,
			survival_time,
			_format_time(survival_time)
		)
		if rank > 0:
			results["survival_time"] = {"rank": rank, "value": survival_time}

	# 击杀数排行榜
	var kills: int = stats.get("enemies_killed", 0)
	if kills > 0:
		var rank: int = _add_record(
			LeaderboardCategory.KILLS,
			player_name,
			kills,
			str(kills)
		)
		if rank > 0:
			results["kills"] = {"rank": rank, "value": kills}

	# 波次排行榜
	var wave: int = stats.get("level_reached", 0)
	if wave > 0:
		var rank: int = _add_record(
			LeaderboardCategory.WAVE_REACHED,
			player_name,
			wave,
			"第 %d 波" % wave
		)
		if rank > 0:
			results["wave"] = {"rank": rank, "value": wave}

	# 伤害输出排行榜
	var damage: float = stats.get("damage_dealt", 0.0)
	if damage > 0:
		var rank: int = _add_record(
			LeaderboardCategory.DAMAGE_DEALT,
			player_name,
			damage,
			UITheme.format_number(int(damage))
		)
		if rank > 0:
			results["damage"] = {"rank": rank, "value": damage}

	# 最大连击排行榜
	var combo: int = stats.get("max_combo", 0)
	if combo > 0:
		var rank: int = _add_record(
			LeaderboardCategory.COMBO_MAX,
			player_name,
			combo,
			str(combo) + " 连击"
		)
		if rank > 0:
			results["combo"] = {"rank": rank, "value": combo}

	# 金币收集排行榜
	var gold: int = stats.get("gold_collected", 0)
	if gold > 0:
		var rank: int = _add_record(
			LeaderboardCategory.GOLD_COLLECTED,
			player_name,
			gold,
			str(gold) + " 金币"
		)
		if rank > 0:
			results["gold"] = {"rank": rank, "value": gold}

	# 保存排行榜数据
	_save_leaderboards()

	return results


## 提交速度通关记录
func submit_speedrun_record(player_name: String, wave: int, time: float) -> int:
	"""提交速度通关记录

	@param player_name: 玩家名称
	@param wave: 到达的波次
	@param time: 用时（秒）
	@return: 排名（-1表示未进入排行榜）
	"""
	# 速度通关按波次分组，时间越短越好
	var category_key: String = "speedrun_wave_%d" % wave
	var rank: int = _add_speedrun_record(category_key, player_name, time)
	_save_leaderboards()
	return rank

# =============================================================================
# 公共方法 - 排行榜查询
# =============================================================================

## 获取指定类别的排行榜
func get_leaderboard(category: LeaderboardCategory) -> Array[Dictionary]:
	"""获取指定类别的排行榜

	@param category: 排行榜类别
	@return: 排行榜记录列表
	"""
	var category_key: String = _get_category_key(category)
	var records: Array = _leaderboards.get(category_key, [])

	var result: Array[Dictionary] = []
	for i in range(records.size()):
		var record: Dictionary = records[i].duplicate()
		record["rank"] = i + 1
		result.append(record)

	return result


## 获取指定类别的Top N记录
func get_top_records(category: LeaderboardCategory, count: int = 5) -> Array[Dictionary]:
	"""获取指定类别的Top N记录

	@param category: 排行榜类别
	@param count: 记录数量
	@return: Top N记录列表
	"""
	var all_records: Array[Dictionary] = get_leaderboard(category)
	var result: Array[Dictionary] = []

	for i in range(min(count, all_records.size())):
		result.append(all_records[i])

	return result


## 获取玩家在某类别的最佳记录
func get_player_best_record(category: LeaderboardCategory, player_name: String) -> Dictionary:
	"""获取玩家在某类别的最佳记录

	@param category: 排行榜类别
	@param player_name: 玩家名称
	@return: 最佳记录（如果没有返回空字典）
	"""
	var records: Array[Dictionary] = get_leaderboard(category)

	for record in records:
		if record.get("player_name", "") == player_name:
			return record

	return {}


## 获取玩家在某类别的排名
func get_player_rank(category: LeaderboardCategory, player_name: String) -> int:
	"""获取玩家在某类别的排名

	@param category: 排行榜类别
	@param player_name: 玩家名称
	@return: 排名（-1表示未上榜）
	"""
	var records: Array[Dictionary] = get_leaderboard(category)

	for i in range(records.size()):
		if records[i].get("player_name", "") == player_name:
			return i + 1

	return -1


## 检查记录是否能进入排行榜
func can_enter_leaderboard(category: LeaderboardCategory, value: float) -> bool:
	"""检查记录是否能进入排行榜

	@param category: 排行榜类别
	@param value: 记录值
	@return: 是否能进入排行榜
	"""
	var category_key: String = _get_category_key(category)
	var records: Array = _leaderboards.get(category_key, [])

	# 排行榜未满
	if records.size() < MAX_RECORDS_PER_CATEGORY:
		return true

	# 检查是否超过最低记录
	var min_value: float = records[records.size() - 1].get("value", 0.0)
	return value > min_value


## 获取类别名称
func get_category_name(category: LeaderboardCategory) -> String:
	"""获取排行榜类别名称

	@param category: 排行榜类别
	@return: 类别名称
	"""
	return CATEGORY_NAMES.get(category, "未知")


## 获取所有类别列表
func get_all_categories() -> Array[Dictionary]:
	"""获取所有排行榜类别列表

	@return: 类别信息列表
	"""
	var result: Array[Dictionary] = []

	for category in LeaderboardCategory.values():
		var records: Array[Dictionary] = get_leaderboard(category)
		result.append({
			"category": category,
			"name": CATEGORY_NAMES.get(category, "未知"),
			"records_count": records.size(),
		})

	return result

# =============================================================================
# 公共方法 - 管理操作
# =============================================================================

## 清除指定类别的排行榜
func clear_leaderboard(category: LeaderboardCategory) -> void:
	"""清除指定类别的排行榜

	@param category: 排行榜类别
	"""
	var category_key: String = _get_category_key(category)
	_leaderboards[category_key] = []
	_save_leaderboards()
	leaderboard_updated.emit(category_key)
	print("[LeaderboardManager] 已清除排行榜: %s" % CATEGORY_NAMES.get(category))


## 清除所有排行榜
func clear_all_leaderboards() -> void:
	"""清除所有排行榜"""
	for category in LeaderboardCategory.values():
		var category_key: String = _get_category_key(category)
		_leaderboards[category_key] = []

	# 清除速度通关排行榜
	for key in _leaderboards.keys():
		if key.begins_with("speedrun_wave_"):
			_leaderboards[key] = []

	_save_leaderboards()
	print("[LeaderboardManager] 已清除所有排行榜")


## 设置玩家默认名称
func get_default_player_name() -> String:
	"""获取默认玩家名称"""
	return SaveManager.load_settings().get("player_name", "玩家")

# =============================================================================
# 私有方法 - 记录添加
# =============================================================================

func _add_record(category: LeaderboardCategory, player_name: String, value: float, display_text: String) -> int:
	"""添加记录到排行榜

	@param category: 排行榜类别
	@param player_name: 玩家名称
	@param value: 记录值
	@param display_text: 显示文本
	@return: 排名（-1表示未进入排行榜）
	"""
	var category_key: String = _get_category_key(category)
	var records: Array = _leaderboards.get(category_key, [])

	# 创建新记录
	var new_record: Dictionary = {
		"player_name": player_name,
		"value": value,
		"display": display_text,
		"timestamp": Time.get_datetime_string_from_system(),
	}

	# 查找插入位置（按值降序排列）
	var insert_index: int = -1
	for i in range(records.size()):
		if value > records[i].get("value", 0.0):
			insert_index = i
			break

	# 检查是否能进入排行榜
	if insert_index == -1 and records.size() >= MAX_RECORDS_PER_CATEGORY:
		return -1

	# 插入记录
	if insert_index == -1:
		insert_index = records.size()

	records.insert(insert_index, new_record)

	# 限制记录数量
	if records.size() > MAX_RECORDS_PER_CATEGORY:
		records.resize(MAX_RECORDS_PER_CATEGORY)

	_leaderboards[category_key] = records
	leaderboard_updated.emit(category_key)

	# 计算排名
	var rank: int = insert_index + 1
	if rank <= MAX_RECORDS_PER_CATEGORY:
		new_record_added.emit(category_key, rank, new_record)

	return rank


func _add_speedrun_record(category_key: String, player_name: String, time: float) -> int:
	"""添加速度通关记录（时间越短越好）

	@param category_key: 类别键
	@param player_name: 玩家名称
	@param time: 用时（秒）
	@return: 排名（-1表示未进入排行榜）
	"""
	var records: Array = _leaderboards.get(category_key, [])

	# 创建新记录
	var new_record: Dictionary = {
		"player_name": player_name,
		"value": time,  # 速度通关用时间作为值，但排序时越小越好
		"display": _format_time(time),
		"timestamp": Time.get_datetime_string_from_system(),
	}

	# 查找插入位置（按时间升序排列，越短越好）
	var insert_index: int = -1
	for i in range(records.size()):
		if time < records[i].get("value", 999999.0):
			insert_index = i
			break

	# 检查是否能进入排行榜
	if insert_index == -1 and records.size() >= MAX_RECORDS_PER_CATEGORY:
		return -1

	# 插入记录
	if insert_index == -1:
		insert_index = records.size()

	records.insert(insert_index, new_record)

	# 限制记录数量
	if records.size() > MAX_RECORDS_PER_CATEGORY:
		records.resize(MAX_RECORDS_PER_CATEGORY)

	_leaderboards[category_key] = records
	leaderboard_updated.emit(category_key)

	return insert_index + 1

# =============================================================================
# 私有方法 - 保存/加载
# =============================================================================

func _save_leaderboards() -> void:
	"""保存排行榜数据"""
	var save_data: Dictionary = {
		"leaderboards": _leaderboards,
		"version": 1,
	}

	var file: FileAccess = FileAccess.open(LEADERBOARD_PATH, FileAccess.WRITE)
	if file == null:
		push_error("[LeaderboardManager] 无法保存排行榜数据")
		return

	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()
	print("[LeaderboardManager] 排行榜数据已保存")


func _load_leaderboards() -> void:
	"""加载排行榜数据"""
	# 初始化空排行榜
	for category in LeaderboardCategory.values():
		var category_key: String = _get_category_key(category)
		_leaderboards[category_key] = []

	if not FileAccess.file_exists(LEADERBOARD_PATH):
		print("[LeaderboardManager] 无排行榜存档，使用默认数据")
		return

	var file: FileAccess = FileAccess.open(LEADERBOARD_PATH, FileAccess.READ)
	if file == null:
		push_error("[LeaderboardManager] 无法加载排行榜数据")
		return

	var json_string: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	if json.parse(json_string) != OK:
		push_error("[LeaderboardManager] 排行榜数据解析失败")
		return

	var data: Dictionary = json.data
	_leaderboards = data.get("leaderboards", _leaderboards)

	print("[LeaderboardManager] 排行榜数据已加载")

# =============================================================================
# 私有方法 - 辅助
# =============================================================================

func _get_category_key(category: LeaderboardCategory) -> String:
	"""获取类别键名"""
	match category:
		LeaderboardCategory.SURVIVAL_TIME:
			return "survival_time"
		LeaderboardCategory.KILLS:
			return "kills"
		LeaderboardCategory.WAVE_REACHED:
			return "wave_reached"
		LeaderboardCategory.DAMAGE_DEALT:
			return "damage_dealt"
		LeaderboardCategory.COMBO_MAX:
			return "combo_max"
		LeaderboardCategory.GOLD_COLLECTED:
			return "gold_collected"
		LeaderboardCategory.SPEEDRUN:
			return "speedrun"
		_:
			return "unknown"


func _format_time(seconds: float) -> String:
	"""格式化时间显示"""
	var minutes: int = int(seconds / 60)
	var secs: int = int(seconds) % 60

	if minutes > 0:
		return "%d:%02d" % [minutes, secs]
	else:
		return "%.1f秒" % seconds


func _get_save_manager() -> Node:
	"""获取存档管理器"""
	return SaveManager


func _get_ui_theme() -> Node:
	"""获取UI主题"""
	# UITheme 是类名，可以直接调用静态方法
	return null  # UITheme 的方法是静态的，不需要实例