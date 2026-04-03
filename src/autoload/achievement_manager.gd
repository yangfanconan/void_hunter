## Void Hunter - 成就管理器
## @description: 管理成就解锁、进度追踪、保存和通知
## @author: Void Hunter Team
## @version: 1.0.0

extends Node

# =============================================================================
# 信号定义
# =============================================================================

## 成就解锁时触发
signal achievement_unlocked(achievement_id: String, achievement_data: Dictionary)

## 成就进度更新时触发
signal achievement_progress_updated(achievement_id: String, current: int, target: int)

## 所有成就加载完成时触发
signal achievements_loaded(unlocked_count: int, total_count: int)

# =============================================================================
# 常量定义
# =============================================================================

## 成就数据保存路径
const ACHIEVEMENTS_PATH := "user://achievements.dat"

## 成就类别
enum AchievementCategory {
	GAMEPLAY,		## 游戏玩法
	COMBAT,			## 战斗相关
	COLLECTION,		## 收集相关
	CHARACTER,		## 角色相关
	SKILL,			## 技能相关
	SPECIAL			## 特殊成就
}

## 成就类型
enum AchievementType {
	COUNTER,		## 计数型（如击杀1000敌人）
	MILESTONE,		## 里程碑型（如到达第10波）
	ONE_TIME,		## 一次性（如首次通关）
	COLLECTION,		## 收集型（如收集所有角色）
	SPEED			## 速度型（如60秒内通关第5波）
}

# =============================================================================
# 成就定义数据库
# =============================================================================

var _achievement_definitions: Dictionary = {
	# 游戏玩法成就
	"first_game": {
		"id": "first_game",
		"name": "初次冒险",
		"description": "完成第一次游戏",
		"category": AchievementCategory.GAMEPLAY,
		"type": AchievementType.ONE_TIME,
		"target": 1,
		"icon": "achievement_first_game",
		"reward_exp": 100,
		"reward_gold": 50,
	},
	"survivor_5min": {
		"id": "survivor_5min",
		"name": "初学幸存者",
		"description": "存活5分钟",
		"category": AchievementCategory.GAMEPLAY,
		"type": AchievementType.MILESTONE,
		"target": 300,  # 5分钟 = 300秒
		"icon": "achievement_time",
		"reward_exp": 200,
	},
	"survivor_10min": {
		"id": "survivor_10min",
		"name": "坚韧幸存者",
		"description": "存活10分钟",
		"category": AchievementCategory.GAMEPLAY,
		"type": AchievementType.MILESTONE,
		"target": 600,
		"icon": "achievement_time",
		"reward_exp": 500,
	},
	"survivor_30min": {
		"id": "survivor_30min",
		"name": "永恒幸存者",
		"description": "存活30分钟",
		"category": AchievementCategory.GAMEPLAY,
		"type": AchievementType.MILESTONE,
		"target": 1800,
		"icon": "achievement_time",
		"reward_exp": 1000,
		"reward_gold": 200,
	},

	# 战斗成就
	"kill_100": {
		"id": "kill_100",
		"name": "刽子手",
		"description": "击杀100个敌人",
		"category": AchievementCategory.COMBAT,
		"type": AchievementType.COUNTER,
		"target": 100,
		"icon": "achievement_kill",
		"reward_exp": 300,
	},
	"kill_500": {
		"id": "kill_500",
		"name": "战场收割者",
		"description": "击杀500个敌人",
		"category": AchievementCategory.COMBAT,
		"type": AchievementType.COUNTER,
		"target": 500,
		"icon": "achievement_kill",
		"reward_exp": 800,
	},
	"kill_1000": {
		"id": "kill_1000",
		"name": "死亡使者",
		"description": "击杀1000个敌人",
		"category": AchievementCategory.COMBAT,
		"type": AchievementType.COUNTER,
		"target": 1000,
		"icon": "achievement_kill",
		"reward_exp": 1500,
		"reward_gold": 300,
	},
	"kill_elite_10": {
		"id": "kill_elite_10",
		"name": "精英猎手",
		"description": "击杀10个精英敌人",
		"category": AchievementCategory.COMBAT,
		"type": AchievementType.COUNTER,
		"target": 10,
		"icon": "achievement_elite",
		"reward_exp": 400,
	},
	"kill_boss_1": {
		"id": "kill_boss_1",
		"name": "Boss终结者",
		"description": "击杀第一个Boss",
		"category": AchievementCategory.COMBAT,
		"type": AchievementType.ONE_TIME,
		"target": 1,
		"icon": "achievement_boss",
		"reward_exp": 500,
		"reward_gold": 100,
	},
	"kill_boss_5": {
		"id": "kill_boss_5",
		"name": "征服者",
		"description": "击杀5个Boss",
		"category": AchievementCategory.COMBAT,
		"type": AchievementType.COUNTER,
		"target": 5,
		"icon": "achievement_boss",
		"reward_exp": 1200,
	},

	# 波次成就
	"wave_5": {
		"id": "wave_5",
		"name": "突破第五波",
		"description": "到达第5波",
		"category": AchievementCategory.GAMEPLAY,
		"type": AchievementType.MILESTONE,
		"target": 5,
		"icon": "achievement_wave",
		"reward_exp": 250,
	},
	"wave_10": {
		"id": "wave_10",
		"name": "十波挑战者",
		"description": "到达第10波",
		"category": AchievementCategory.GAMEPLAY,
		"type": AchievementType.MILESTONE,
		"target": 10,
		"icon": "achievement_wave",
		"reward_exp": 600,
	},
	"wave_20": {
		"id": "wave_20",
		"name": "波次大师",
		"description": "到达第20波",
		"category": AchievementCategory.GAMEPLAY,
		"type": AchievementType.MILESTONE,
		"target": 20,
		"icon": "achievement_wave",
		"reward_exp": 1000,
		"reward_gold": 150,
	},
	"wave_50": {
		"id": "wave_50",
		"name": "无尽传说",
		"description": "到达第50波",
		"category": AchievementCategory.GAMEPLAY,
		"type": AchievementType.MILESTONE,
		"target": 50,
		"icon": "achievement_wave",
		"reward_exp": 3000,
		"reward_gold": 500,
	},

	# 收集成就
	"collect_items_50": {
		"id": "collect_items_50",
		"name": "道具收藏家",
		"description": "收集50个道具",
		"category": AchievementCategory.COLLECTION,
		"type": AchievementType.COUNTER,
		"target": 50,
		"icon": "achievement_item",
		"reward_exp": 400,
	},
	"collect_gold_1000": {
		"id": "collect_gold_1000",
		"name": "财富积累",
		"description": "累计获得1000金币",
		"category": AchievementCategory.COLLECTION,
		"type": AchievementType.COUNTER,
		"target": 1000,
		"icon": "achievement_gold",
		"reward_exp": 300,
	},

	# 技能成就
	"skill_level_max": {
		"id": "skill_level_max",
		"name": "技能大师",
		"description": "将一个技能升至最高等级",
		"category": AchievementCategory.SKILL,
		"type": AchievementType.ONE_TIME,
		"target": 1,
		"icon": "achievement_skill",
		"reward_exp": 500,
	},
	"combo_100": {
		"id": "combo_100",
		"name": "连击达人",
		"description": "达成100连击",
		"category": AchievementCategory.SKILL,
		"type": AchievementType.MILESTONE,
		"target": 100,
		"icon": "achievement_combo",
		"reward_exp": 600,
	},
	"combo_500": {
		"id": "combo_500",
		"name": "连击传说",
		"description": "达成500连击",
		"category": AchievementCategory.SKILL,
		"type": AchievementType.MILESTONE,
		"target": 500,
		"icon": "achievement_combo",
		"reward_exp": 1500,
		"reward_gold": 200,
	},

	# 角色成就
	"unlock_all_characters": {
		"id": "unlock_all_characters",
		"name": "全角色解锁",
		"description": "解锁所有角色",
		"category": AchievementCategory.CHARACTER,
		"type": AchievementType.COLLECTION,
		"target": 8,  # 8个角色
		"icon": "achievement_character",
		"reward_exp": 2000,
		"reward_gold": 300,
	},

	# 特殊成就
	"no_damage_wave": {
		"id": "no_damage_wave",
		"name": "完美防御",
		"description": "在一波中不受到任何伤害",
		"category": AchievementCategory.SPECIAL,
		"type": AchievementType.ONE_TIME,
		"target": 1,
		"icon": "achievement_perfect",
		"reward_exp": 800,
	},
	"speedrun_wave5": {
		"id": "speedrun_wave5",
		"name": "闪电突破",
		"description": "在120秒内到达第5波",
		"category": AchievementCategory.SPECIAL,
		"type": AchievementType.SPEED,
		"target": 120,
		"icon": "achievement_speed",
		"reward_exp": 1000,
	},
}

# =============================================================================
# 私有变量
# =============================================================================

## 已解锁的成就
var _unlocked_achievements: Dictionary = {}

## 成就进度数据
var _achievement_progress: Dictionary = {}

## 累计统计数据
var _stats: Dictionary = {
	"total_kills": 0,
	"elite_kills": 0,
	"boss_kills": 0,
	"total_items_collected": 0,
	"total_gold_collected": 0,
	"max_combo": 0,
	"max_wave": 0,
	"max_survival_time": 0.0,
	"characters_unlocked": 0,
	"skills_maxed": 0,
	"games_played": 0,
}

## 当前游戏会话统计
var _session_stats: Dictionary = {}

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
	"""初始化成就系统"""
	_load_achievements()
	_initialized = true
	print("[AchievementManager] 初始化完成，已解锁 %d/%d 成就" % [_unlocked_achievements.size(), _achievement_definitions.size()])
	achievements_loaded.emit(_unlocked_achievements.size(), _achievement_definitions.size())

# =============================================================================
# 公共方法 - 统计更新
# =============================================================================

## 开始新游戏会话
func start_session() -> void:
	"""开始新的游戏会话，重置会话统计"""
	_session_stats = {
		"kills": 0,
		"elite_kills": 0,
		"boss_kills": 0,
		"items_collected": 0,
		"gold_collected": 0,
		"damage_taken": 0.0,
		"max_combo": 0,
		"start_time": Time.get_ticks_msec() / 1000.0,
		"wave": 0,
	}


## 记录击杀
func record_kill(enemy_type: String = "normal") -> void:
	"""记录敌人击杀"""
	_stats["total_kills"] += 1
	_session_stats["kills"] += 1

	# 根据敌人类型更新统计
	match enemy_type:
		"elite":
			_stats["elite_kills"] += 1
			_session_stats["elite_kills"] += 1
		"boss":
			_stats["boss_kills"] += 1
			_session_stats["boss_kills"] += 1

	# 检查击杀相关成就
	_check_counter_achievement("kill_100", _stats["total_kills"])
	_check_counter_achievement("kill_500", _stats["total_kills"])
	_check_counter_achievement("kill_1000", _stats["total_kills"])
	_check_counter_achievement("kill_elite_10", _stats["elite_kills"])
	_check_counter_achievement("kill_boss_1", _stats["boss_kills"])
	_check_counter_achievement("kill_boss_5", _stats["boss_kills"])


## 记录波次到达
func record_wave(wave_number: int) -> void:
	"""记录到达的波次"""
	_session_stats["wave"] = wave_number

	if wave_number > _stats["max_wave"]:
		_stats["max_wave"] = wave_number

	# 检查波次成就
	_check_milestone_achievement("wave_5", wave_number)
	_check_milestone_achievement("wave_10", wave_number)
	_check_milestone_achievement("wave_20", wave_number)
	_check_milestone_achievement("wave_50", wave_number)


## 记录存活时间
func record_survival_time(time: float) -> void:
	"""记录存活时间"""
	_session_stats["survival_time"] = time

	if time > _stats["max_survival_time"]:
		_stats["max_survival_time"] = time

	# 检查存活时间成就
	_check_milestone_achievement("survivor_5min", time)
	_check_milestone_achievement("survivor_10min", time)
	_check_milestone_achievement("survivor_30min", time)

	# 检查速度成就（在到达第5波时）
	if _session_stats["wave"] >= 5:
		var elapsed: float = Time.get_ticks_msec() / 1000.0 - _session_stats["start_time"]
		if elapsed <= 120:  # 120秒内到达第5波
			_unlock_achievement("speedrun_wave5")


## 记录道具收集
func record_item_collected() -> void:
	"""记录道具收集"""
	_stats["total_items_collected"] += 1
	_session_stats["items_collected"] += 1

	_check_counter_achievement("collect_items_50", _stats["total_items_collected"])


## 记录金币获得
func record_gold_collected(amount: int) -> void:
	"""记录金币获得"""
	_stats["total_gold_collected"] += amount
	_session_stats["gold_collected"] += amount

	_check_counter_achievement("collect_gold_1000", _stats["total_gold_collected"])


## 记录连击
func record_combo(combo_count: int) -> void:
	"""记录连击数"""
	if combo_count > _session_stats["max_combo"]:
		_session_stats["max_combo"] = combo_count

	if combo_count > _stats["max_combo"]:
		_stats["max_combo"] = combo_count

	_check_milestone_achievement("combo_100", combo_count)
	_check_milestone_achievement("combo_500", combo_count)


## 记录受伤
func record_damage_taken(amount: float) -> void:
	"""记录受到的伤害"""
	_session_stats["damage_taken"] += amount


## 记录技能升级到最高级
func record_skill_maxed() -> void:
	"""记录技能升至最高级"""
	_stats["skills_maxed"] += 1
	_check_one_time_achievement("skill_level_max")


## 记录角色解锁
func record_character_unlocked() -> void:
	"""记录角色解锁"""
	_stats["characters_unlocked"] += 1
	_check_counter_achievement("unlock_all_characters", _stats["characters_unlocked"])


## 结束游戏会话
func end_session() -> void:
	"""结束游戏会话，保存数据并检查成就"""
	_stats["games_played"] += 1

	# 检查首次游戏成就
	_check_one_time_achievement("first_game")

	# 检查完美防御成就（一波中没受伤）
	if _session_stats["damage_taken"] == 0 and _session_stats["wave"] >= 1:
		_unlock_achievement("no_damage_wave")

	# 保存成就数据
	_save_achievements()

	print("[AchievementManager] 会话结束，统计: 击杀=%d, 波次=%d, 时间=%.1f秒" % [
		_session_stats["kills"],
		_session_stats["wave"],
		_session_stats.get("survival_time", 0.0)
	])

# =============================================================================
# 公共方法 - 成就查询
# =============================================================================

## 获取成就名称
func get_achievement_name(achievement_id: String) -> String:
	"""获取成就名称"""
	var data: Dictionary = _achievement_definitions.get(achievement_id, {})
	return data.get("name", achievement_id)


## 获取成就描述
func get_achievement_description(achievement_id: String) -> String:
	"""获取成就描述"""
	var data: Dictionary = _achievement_definitions.get(achievement_id, {})
	return data.get("description", "")


## 获取成就进度
func get_achievement_progress(achievement_id: String) -> Dictionary:
	"""获取成就进度"""
	var data: Dictionary = _achievement_definitions.get(achievement_id, {})
	var target: int = data.get("target", 1)
	var current: int = _achievement_progress.get(achievement_id, 0)

	return {
		"current": current,
		"target": target,
		"percent": float(current) / float(target) * 100.0 if target > 0 else 0.0,
		"unlocked": _unlocked_achievements.has(achievement_id),
	}


## 获取所有成就列表
func get_all_achievements() -> Array[Dictionary]:
	"""获取所有成就列表"""
	var result: Array[Dictionary] = []

	for id in _achievement_definitions:
		var data: Dictionary = _achievement_definitions[id].duplicate()
		data["unlocked"] = _unlocked_achievements.has(id)
		data["progress"] = get_achievement_progress(id)
		result.append(data)

	return result


## 获取已解锁成就列表
func get_unlocked_achievements() -> Array[Dictionary]:
	"""获取已解锁成就列表"""
	var result: Array[Dictionary] = []

	for id in _unlocked_achievements:
		var data: Dictionary = _achievement_definitions.get(id, {}).duplicate()
		data["unlock_time"] = _unlocked_achievements[id].get("unlock_time", "")
		result.append(data)

	return result


## 检查成就是否已解锁
func is_achievement_unlocked(achievement_id: String) -> bool:
	"""检查成就是否已解锁"""
	return _unlocked_achievements.has(achievement_id)


## 获取统计数据
func get_stats() -> Dictionary:
	"""获取累计统计数据"""
	return _stats.duplicate()


## 获取会话统计
func get_session_stats() -> Dictionary:
	"""获取当前会话统计"""
	return _session_stats.duplicate()

# =============================================================================
# 公共方法 - 手动解锁（用于测试或特殊情况）
# =============================================================================

## 手动解锁成就
func unlock_achievement(achievement_id: String) -> bool:
	"""手动解锁成就"""
	return _unlock_achievement(achievement_id)


## 重置所有成就（用于测试）
func reset_all_achievements() -> void:
	"""重置所有成就"""
	_unlocked_achievements.clear()
	_achievement_progress.clear()
	_stats = {
		"total_kills": 0,
		"elite_kills": 0,
		"boss_kills": 0,
		"total_items_collected": 0,
		"total_gold_collected": 0,
		"max_combo": 0,
		"max_wave": 0,
		"max_survival_time": 0.0,
		"characters_unlocked": 0,
		"skills_maxed": 0,
		"games_played": 0,
	}
	_save_achievements()
	print("[AchievementManager] 所有成就已重置")

# =============================================================================
# 私有方法 - 成就检查
# =============================================================================

func _check_counter_achievement(achievement_id: String, current_value: int) -> void:
	"""检查计数型成就"""
	if _unlocked_achievements.has(achievement_id):
		return

	var data: Dictionary = _achievement_definitions.get(achievement_id, {})
	if data.is_empty():
		return

	var target: int = data.get("target", 1)

	# 更新进度
	_achievement_progress[achievement_id] = min(current_value, target)

	# 检查是否达成
	if current_value >= target:
		_unlock_achievement(achievement_id)
	else:
		achievement_progress_updated.emit(achievement_id, current_value, target)


func _check_milestone_achievement(achievement_id: String, current_value: float) -> void:
	"""检查里程碑型成就"""
	if _unlocked_achievements.has(achievement_id):
		return

	var data: Dictionary = _achievement_definitions.get(achievement_id, {})
	if data.is_empty():
		return

	var target: int = data.get("target", 1)

	# 更新进度
	_achievement_progress[achievement_id] = int(min(current_value, target))

	# 检查是否达成
	if current_value >= target:
		_unlock_achievement(achievement_id)
	else:
		achievement_progress_updated.emit(achievement_id, int(current_value), target)


func _check_one_time_achievement(achievement_id: String) -> void:
	"""检查一次性成就"""
	if _unlocked_achievements.has(achievement_id):
		return

	_unlock_achievement(achievement_id)


func _unlock_achievement(achievement_id: String) -> bool:
	"""解锁成就"""
	if _unlocked_achievements.has(achievement_id):
		return false

	var data: Dictionary = _achievement_definitions.get(achievement_id, {})
	if data.is_empty():
		push_warning("[AchievementManager] 未知的成就ID: %s" % achievement_id)
		return false

	# 记录解锁时间
	_unlocked_achievements[achievement_id] = {
		"unlock_time": Time.get_datetime_string_from_system(),
	}

	# 标记进度完成
	_achievement_progress[achievement_id] = data.get("target", 1)

	# 触发信号
	achievement_unlocked.emit(achievement_id, data)

	# 显示通知
	_show_achievement_notification(achievement_id, data)

	# 保存数据
	_save_achievements()

	print("[AchievementManager] 成就解锁: %s - %s" % [achievement_id, data.get("name", "")])
	return true


func _show_achievement_notification(achievement_id: String, data: Dictionary) -> void:
	"""显示成就解锁通知"""
	# 查找通知系统
	var notification_system: Node = _get_notification_system()
	if notification_system == null:
		return

	var name: String = data.get("name", achievement_id)
	var description: String = data.get("description", "")

	# 调用通知系统
	if notification_system.has_method("show_notification"):
		# 使用枚举值 0 = ACHIEVEMENT
		notification_system.show_notification(
			0,  # NotificationType.ACHIEVEMENT
			"成就解锁！",
			name + "\n" + description,
			null,  # 图标稍后从SpriteManager加载
			4.0  # 成就通知显示更长时间
		)

# =============================================================================
# 私有方法 - 保存/加载
# =============================================================================

func _save_achievements() -> void:
	"""保存成就数据"""
	var save_data: Dictionary = {
		"unlocked": _unlocked_achievements,
		"progress": _achievement_progress,
		"stats": _stats,
		"version": 1,
	}

	var file: FileAccess = FileAccess.open(ACHIEVEMENTS_PATH, FileAccess.WRITE)
	if file == null:
		push_error("[AchievementManager] 无法保存成就数据")
		return

	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()
	print("[AchievementManager] 成就数据已保存")


func _load_achievements() -> void:
	"""加载成就数据"""
	if not FileAccess.file_exists(ACHIEVEMENTS_PATH):
		print("[AchievementManager] 无存档文件，使用默认数据")
		return

	var file: FileAccess = FileAccess.open(ACHIEVEMENTS_PATH, FileAccess.READ)
	if file == null:
		push_error("[AchievementManager] 无法加载成就数据")
		return

	var json_string: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	if json.parse(json_string) != OK:
		push_error("[AchievementManager] 成就数据解析失败")
		return

	var data: Dictionary = json.data
	_unlocked_achievements = data.get("unlocked", {})
	_achievement_progress = data.get("progress", {})
	_stats = data.get("stats", _stats)

	print("[AchievementManager] 成就数据已加载")

# =============================================================================
# 私有方法 - 辅助
# =============================================================================

func _get_notification_system() -> Node:
	"""获取通知系统"""
	if get_tree() and get_tree().root:
		# 尝试从UIManager获取
		var ui_manager: Node = get_tree().root.get_node_or_null("UIManager")
		if ui_manager and "notification_system" in ui_manager:
			return ui_manager.notification_system
		# 直接查找
		return get_tree().root.get_node_or_null("NotificationSystem")
	return null


func _get_save_manager() -> Node:
	"""获取存档管理器"""
	if get_tree() and get_tree().root:
		return get_tree().root.get_node_or_null("SaveManager")
	return null