## Void Hunter - 挑战系统
## @description: 追踪游戏统计数据、检测解锁条件、管理挑战进度
## @author: Void Hunter Team
## @version: 1.0.0

extends Node
class_name ChallengeSystemSingleton

# =============================================================================
# 信号定义
# =============================================================================

## 角色解锁时触发
signal character_unlocked(character_id: String, character_name: String)

## 解锁进度更新时触发
signal unlock_progress_updated(character_id: String, progress: float)

## 挑战完成时触发
signal challenge_completed(challenge_id: String, reward: Dictionary)

## 统计数据更新时触发
signal stats_updated(stat_name: String, new_value: Variant)

## 成就解锁时触发
signal achievement_unlocked(achievement_id: String, achievement_data: Dictionary)

# =============================================================================
# 常量定义
# =============================================================================

## 自动保存间隔（秒）
const AUTO_SAVE_INTERVAL: float = 60.0

# =============================================================================
# 单例访问
# =============================================================================

static var _instance: ChallengeSystem = null

static func get_instance() -> ChallengeSystem:
	"""获取挑战系统单例"""
	return _instance

# =============================================================================
# 公共变量 - 本局统计数据
# =============================================================================

## 本局击杀敌人数
var session_kills: int = 0

## 本局造成的总伤害
var session_damage_dealt: float = 0.0

## 本局承受的总伤害
var session_damage_taken: float = 0.0

## 本局生存时间
var session_survive_time: float = 0.0

## 本局是否死亡过
var session_has_died: bool = false

## 本局收集的技能ID列表
var session_skills_collected: Array[String] = []

## 本局击杀的精英敌人数
var session_elite_kills: int = 0

## 本局到达的最大层数
var session_max_level: int = 1

# =============================================================================
# 公共变量 - 累计统计数据
# =============================================================================

## 累计总击杀数
var total_kills: int = 0

## 累计总游戏时间
var total_play_time: float = 0.0

## 累计精英击杀数
var total_elite_kills: int = 0

## 累计造成的伤害
var total_damage_dealt: float = 0.0

## 最高到达层数
var max_level_reached: int = 1

## 最长生存时间
var longest_survive_time: float = 0.0

## 累计通关次数
var total_clears: int = 0

## 收集过的所有技能
var all_skills_ever_collected: Array[String] = []

# =============================================================================
# 公共变量 - 角色通关记录
# =============================================================================

## 每个角色的通关次数
var character_clear_counts: Dictionary = {}

## 当前使用的角色ID
var current_character_id: String = "wandering_swordsman"

## 已解锁的角色ID列表
var unlocked_characters: Array[String] = []

## 角色数据缓存
var character_data: Dictionary = {}

# =============================================================================
# 公共变量 - 成就系统
# =============================================================================

## 已解锁的成就列表
var unlocked_achievements: Array[String] = []

## 成就进度
var achievement_progress: Dictionary = {}

# =============================================================================
# 私有变量
# =============================================================================

var _characters: Dictionary = {}
var _auto_save_timer: float = 0.0
var _is_initialized: bool = false

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	_instance = self
	_initialize_system()


func _process(delta: float) -> void:
	# 更新本局生存时间
	if GameManager and GameManager.current_state == GameManager.GameState.PLAYING:
		session_survive_time += delta

	# 自动保存
	_auto_save_timer += delta
	if _auto_save_timer >= AUTO_SAVE_INTERVAL:
		_auto_save_timer = 0.0
		_auto_save_progress()

# =============================================================================
# 公共方法 - 初始化
# =============================================================================

## 初始化挑战系统
func initialize() -> void:
	"""手动初始化"""
	if not _is_initialized:
		_initialize_system()


func _initialize_system() -> void:
	"""内部初始化"""
	_is_initialized = true

	# 加载所有角色
	_load_all_characters()

	# 加载存档数据
	_load_progress()

	# 初始化角色通关计数
	_initialize_character_clear_counts()

	print("[ChallengeSystem] 初始化完成")


func _load_all_characters() -> void:
	"""加载所有角色定义（使用内置数据创建CharacterBase对象）"""
	var all_characters: Dictionary = {
		"wandering_swordsman": {"name": "流浪剑客", "type": "melee", "health": 100, "mana": 50, "attack": 15, "defense": 5, "speed": 200},
		"arcane_warlock": {"name": "奥术术士", "type": "mage", "health": 80, "mana": 100, "attack": 20, "defense": 3, "speed": 180},
		"berserker": {"name": "狂战士", "type": "melee", "health": 150, "mana": 30, "attack": 20, "defense": 3, "speed": 220},
		"elemental_mage": {"name": "元素法师", "type": "mage", "health": 70, "mana": 120, "attack": 18, "defense": 2, "speed": 170},
		"frost_witch": {"name": "冰霜女巫", "type": "mage", "health": 75, "mana": 90, "attack": 18, "defense": 4, "speed": 175},
		"holy_knight": {"name": "圣骑士", "type": "tank", "health": 130, "mana": 40, "attack": 12, "defense": 8, "speed": 160},
		"holy_paladin": {"name": "神圣圣骑", "type": "tank", "health": 140, "mana": 50, "attack": 14, "defense": 9, "speed": 155},
		"mech_engineer": {"name": "机械工程师", "type": "ranged", "health": 85, "mana": 60, "attack": 16, "defense": 4, "speed": 190},
		"mechanic": {"name": "机械师", "type": "ranged", "health": 90, "mana": 55, "attack": 17, "defense": 5, "speed": 185},
		"night_ranger": {"name": "暗夜游侠", "type": "ranged", "health": 80, "mana": 45, "attack": 22, "defense": 3, "speed": 210},
		"shadow_assassin": {"name": "暗影刺客", "type": "assassin", "health": 70, "mana": 35, "attack": 25, "defense": 2, "speed": 240},
		"thunder_lord": {"name": "雷霆领主", "type": "mage", "health": 85, "mana": 80, "attack": 19, "defense": 4, "speed": 180},
		"time_walker": {"name": "时间行者", "type": "assassin", "health": 75, "mana": 70, "attack": 20, "defense": 3, "speed": 200},
		"void_hunter": {"name": "虚空猎人", "type": "ranged", "health": 85, "mana": 50, "attack": 21, "defense": 4, "speed": 195},
		"void_reaper": {"name": "虚空收割者", "type": "assassin", "health": 65, "mana": 40, "attack": 28, "defense": 2, "speed": 250},
		"dragon_sage": {"name": "龙之贤者", "type": "mage", "health": 95, "mana": 85, "attack": 17, "defense": 5, "speed": 175},
	}

	for char_id in all_characters:
		var data = all_characters[char_id]
		character_data[char_id] = data

		# 创建 CharacterBase 对象
		var character := CharacterBase.new()
		character.character_id = char_id
		character.character_name = data.get("name", char_id)
		character.base_health = data.get("health", 100)
		character.base_mana = data.get("mana", 50)
		character.base_attack = data.get("attack", 15)
		character.base_defense = data.get("defense", 5)
		character.base_speed = data.get("speed", 200)
		character.is_unlocked = true
		character.is_default_unlocked = true
		_characters[char_id] = character

		# 默认所有角色已解锁
		if char_id not in unlocked_characters:
			unlocked_characters.append(char_id)


func _initialize_character_clear_counts() -> void:
	"""初始化角色通关计数"""
	var all_character_ids: Array = [
		"wandering_swordsman", "shadow_assassin", "holy_knight",
		"elemental_mage", "berserker", "mechanic", "time_walker", "void_hunter",
		"void_reaper", "arcane_warlock", "dragon_sage", "frost_witch",
		"holy_paladin", "mech_engineer", "night_ranger", "thunder_lord"
	]

	for char_id in all_character_ids:
		if not character_clear_counts.has(char_id):
			character_clear_counts[char_id] = 0

# =============================================================================
# 公共方法 - 统计追踪
# =============================================================================

## 记录击杀
func record_kill(is_elite: bool = false) -> void:
	"""
	记录敌人击杀
	@param is_elite: 是否为精英敌人
	"""
	session_kills += 1
	total_kills += 1

	if is_elite:
		session_elite_kills += 1
		total_elite_kills += 1

	stats_updated.emit("kills", total_kills)
	_check_all_unlock_conditions()


## 记录伤害
func record_damage_dealt(damage: float) -> void:
	"""
	记录造成的伤害
	@param damage: 伤害值
	"""
	session_damage_dealt += damage
	total_damage_dealt += damage
	stats_updated.emit("damage_dealt", total_damage_dealt)
	_check_all_unlock_conditions()


## 记录承受伤害
func record_damage_taken(damage: float) -> void:
	"""
	记录承受的伤害
	@param damage: 伤害值
	"""
	session_damage_taken += damage


## 记录玩家死亡
func record_death() -> void:
	"""记录玩家死亡"""
	session_has_died = true


## 记录收集技能
func record_skill_collected(skill_id: String) -> void:
	"""
	记录收集的技能
	@param skill_id: 技能ID
	"""
	# 本局技能
	if skill_id not in session_skills_collected:
		session_skills_collected.append(skill_id)

	# 累计技能
	if skill_id not in all_skills_ever_collected:
		all_skills_ever_collected.append(skill_id)

	stats_updated.emit("skills_collected", all_skills_ever_collected.size())
	_check_all_unlock_conditions()


## 记录到达层数
func record_level_reached(level: int) -> void:
	"""
	记录到达的层数
	@param level: 层数
	"""
	session_max_level = maxi(session_max_level, level)

	if level > max_level_reached:
		max_level_reached = level
		stats_updated.emit("max_level", max_level_reached)

	_check_all_unlock_conditions()


## 记录游戏通关
func record_game_clear(character_id: String) -> void:
	"""
	记录游戏通关
	@param character_id: 使用的角色ID
	"""
	total_clears += 1

	# 更新角色通关计数
	if character_clear_counts.has(character_id):
		character_clear_counts[character_id] += 1
	else:
		character_clear_counts[character_id] = 1

	# 更新最长生存时间
	if session_survive_time > longest_survive_time:
		longest_survive_time = session_survive_time

	stats_updated.emit("clears", total_clears)
	_check_all_unlock_conditions()


## 设置当前角色
func set_current_character(character_id: String) -> void:
	"""
	设置当前使用的角色
	@param character_id: 角色ID
	"""
	current_character_id = character_id


## 获取角色通关次数
func get_character_clear_count(character_id: String) -> int:
	"""
	获取指定角色的通关次数
	@param character_id: 角色ID
	@return: 通关次数
	"""
	return character_clear_counts.get(character_id, 0)


## 获取使用不同角色通关的数量
func get_characters_cleared_count() -> int:
	"""
	获取使用不同角色通关的数量
	@return: 角色数量
	"""
	var count: int = 0
	for char_id in character_clear_counts:
		if character_clear_counts[char_id] > 0:
			count += 1
	return count

# =============================================================================
# 公共方法 - 解锁检测
# =============================================================================

## 检查所有解锁条件
func _check_all_unlock_conditions() -> void:
	"""检查所有角色的解锁条件"""
	for char_id in _characters:
		var character: CharacterBase = _characters[char_id]
		if character and not character.is_unlocked:
			_check_character_unlock(char_id, character)


## 检查单个角色解锁
func _check_character_unlock(char_id: String, character: CharacterBase) -> void:
	"""
	检查单个角色的解锁条件
	@param char_id: 角色ID
	@param character: 角色对象
	"""
	var stats: Dictionary = _get_unlock_stats_for_character(character)

	if character.check_unlock_condition(stats):
		_unlock_character(char_id, character)


## 获取角色解锁所需的统计数据
func _get_unlock_stats_for_character(character: CharacterBase) -> Dictionary:
	"""
	根据角色的解锁条件类型获取相应的统计数据
	@param character: 角色对象
	@return: 统计数据字典
	"""
	var stats: Dictionary = {}

	match character.unlock_condition:
		CharacterBase.UnlockCondition.KILL_ENEMIES:
			stats["session_kills"] = session_kills

		CharacterBase.UnlockCondition.SURVIVE_TIME:
			stats["survive_time"] = session_survive_time
			stats["survived_without_death"] = not session_has_died

		CharacterBase.UnlockCondition.COLLECT_SKILLS:
			stats["unique_skills_collected"] = session_skills_collected.size()

		CharacterBase.UnlockCondition.DEAL_DAMAGE:
			stats["session_damage_dealt"] = session_damage_dealt

		CharacterBase.UnlockCondition.KILL_ELITES:
			stats["total_elite_kills"] = total_elite_kills

		CharacterBase.UnlockCondition.REACH_VOID_LEVEL:
			stats["max_level_reached"] = max_level_reached

		CharacterBase.UnlockCondition.CLEAR_WITH_ALL:
			stats["characters_cleared"] = get_characters_cleared_count()

	return stats


## 解锁角色
func _unlock_character(char_id: String, character: CharacterBase) -> void:
	"""
	解锁角色
	@param char_id: 角色ID
	@param character: 角色对象
	"""
	if char_id not in unlocked_characters:
		unlocked_characters.append(char_id)

	character_unlocked.emit(char_id, character.character_name)
	print("[ChallengeSystem] 解锁角色: %s" % character.character_name)

	# 保存进度
	_save_progress()


## 强制解锁角色
func force_unlock_character(char_id: String) -> void:
	"""
	强制解锁指定角色
	@param char_id: 角色ID
	"""
	if _characters.has(char_id):
		var character: CharacterBase = _characters[char_id]
		_unlock_character(char_id, character)


## 检查角色是否已解锁
func is_character_unlocked(char_id: String) -> bool:
	"""
	检查角色是否已解锁
	@param char_id: 角色ID
	@return: 是否已解锁
	"""
	return char_id in unlocked_characters


## 获取角色解锁进度
func get_character_unlock_progress(char_id: String) -> float:
	"""
	获取角色解锁进度
	@param char_id: 角色ID
	@return: 进度（0-1）
	"""
	if _characters.has(char_id):
		var character: CharacterBase = _characters[char_id]
		return character.unlock_progress
	return 0.0

# =============================================================================
# 公共方法 - 角色获取
# =============================================================================

## 获取角色对象
func get_character(char_id: String) -> CharacterBase:
	"""
	获取角色对象
	@param char_id: 角色ID
	@return: 角色对象
	"""
	return _characters.get(char_id)


## 获取所有角色列表
func get_all_characters() -> Array:
	"""
	获取所有角色列表
	@return: 角色ID数组
	"""
	return character_data.keys()


## 获取已解锁角色列表
func get_unlocked_characters() -> Array:
	"""
	获取已解锁的角色列表
	@return: 已解锁角色ID数组
	"""
	return unlocked_characters.duplicate()


## 获取当前角色
func get_current_character() -> CharacterBase:
	"""
	获取当前使用的角色
	@return: 当前角色对象
	"""
	return _characters.get(current_character_id)

# =============================================================================
# 公共方法 - 会话管理
# =============================================================================

## 开始新游戏会话
func start_session(character_id: String) -> void:
	"""
	开始新的游戏会话
	@param character_id: 使用的角色ID
	"""
	# 重置本局统计
	session_kills = 0
	session_damage_dealt = 0.0
	session_damage_taken = 0.0
	session_survive_time = 0.0
	session_has_died = false
	session_skills_collected.clear()
	session_elite_kills = 0
	session_max_level = 1

	# 设置当前角色
	current_character_id = character_id

	# 重置角色被动状态
	if _characters.has(character_id):
		_characters[character_id].reset()

	print("[ChallengeSystem] 开始新会话，角色: %s" % character_id)


## 结束游戏会话
func end_session(is_clear: bool) -> void:
	"""
	结束游戏会话
	@param is_clear: 是否通关
	"""
	# 更新累计统计
	total_play_time += session_survive_time

	if is_clear:
		record_game_clear(current_character_id)

	# 更新角色数据
	if _characters.has(current_character_id):
		var character: CharacterBase = _characters[current_character_id]
		character.total_kills += session_kills
		character.total_play_time += session_survive_time
		if is_clear:
			character.clear_count += 1

	# 保存进度
	_save_progress()


## 重置会话统计
func reset_session_stats() -> void:
	"""重置本局统计数据"""
	session_kills = 0
	session_damage_dealt = 0.0
	session_damage_taken = 0.0
	session_survive_time = 0.0
	session_has_died = false
	session_skills_collected.clear()
	session_elite_kills = 0
	session_max_level = 1

# =============================================================================
# 公共方法 - 被动技能触发
# =============================================================================

## 触发角色攻击被动
func trigger_attack_passive(attack_data: Dictionary) -> Dictionary:
	"""
	触发角色攻击时的被动效果
	@param attack_data: 攻击数据
	@return: 修改后的攻击数据
	"""
	if _characters.has(current_character_id):
		return _characters[current_character_id].on_attack(attack_data)
	return attack_data


## 触发角色受伤被动
func trigger_damage_passive(damage_data: Dictionary) -> Dictionary:
	"""
	触发角色受伤时的被动效果
	@param damage_data: 伤害数据
	@return: 修改后的伤害数据
	"""
	if _characters.has(current_character_id):
		return _characters[current_character_id].on_damage_taken(damage_data)
	return damage_data


## 触发角色帧更新被动
func trigger_process_passive(delta: float, player_stats: Dictionary) -> Dictionary:
	"""
	触发角色每帧更新的被动效果
	@param delta: 帧间隔
	@param player_stats: 玩家属性
	@return: 效果数据
	"""
	if _characters.has(current_character_id):
		return _characters[current_character_id].on_process(delta, player_stats)
	return {}


## 触发角色死亡被动
func trigger_death_passive() -> Dictionary:
	"""
	触发角色死亡时的被动效果
	@return: 效果数据
	"""
	if _characters.has(current_character_id):
		return _characters[current_character_id].on_death()
	return {}


## 触发游戏开始被动
func trigger_game_start_passive() -> Dictionary:
	"""
	触发游戏开始时的被动效果
	@return: 效果数据
	"""
	if _characters.has(current_character_id):
		return _characters[current_character_id].on_game_start()
	return {}

# =============================================================================
# 公共方法 - 属性获取
# =============================================================================

## 获取当前角色的修改后属性
func get_current_character_stats(base_stats: Dictionary) -> Dictionary:
	"""
	获取当前角色修改后的属性
	@param base_stats: 基础属性
	@return: 修改后的属性
	"""
	if _characters.has(current_character_id):
		return _characters[current_character_id].get_modified_stats(base_stats)
	return base_stats


## 获取当前角色基础属性
func get_current_character_base_stats() -> Dictionary:
	"""
	获取当前角色的基础属性
	@return: 基础属性字典
	"""
	if _characters.has(current_character_id):
		var char: CharacterBase = _characters[current_character_id]
		return {
			"health": char.base_health,
			"attack": char.base_attack,
			"defense": char.base_defense,
			"speed": char.base_speed,
			"mana": char.base_mana,
			"critical_chance": char.base_critical_chance,
			"critical_damage": char.base_critical_damage
		}
	return {}

# =============================================================================
# 公共方法 - 数据保存/加载
# =============================================================================

## 保存进度
func _save_progress() -> void:
	"""保存挑战进度到存档"""
	var save_data: Dictionary = {
		"total_kills": total_kills,
		"total_play_time": total_play_time,
		"total_elite_kills": total_elite_kills,
		"total_damage_dealt": total_damage_dealt,
		"max_level_reached": max_level_reached,
		"longest_survive_time": longest_survive_time,
		"total_clears": total_clears,
		"all_skills_collected": all_skills_ever_collected,
		"unlocked_characters": unlocked_characters,
		"character_clear_counts": character_clear_counts,
		"unlocked_achievements": unlocked_achievements,
		"character_data": _get_all_character_save_data()
	}

	SaveManager.save_unlock_data(save_data)


## 自动保存
func _auto_save_progress() -> void:
	"""自动保存进度"""
	if GameManager and GameManager.current_state == GameManager.GameState.PLAYING:
		_save_progress()


## 加载进度
func _load_progress() -> void:
	"""从存档加载挑战进度"""
	var save_data: Dictionary = SaveManager.load_unlock_data()

	if save_data.is_empty():
		return

	total_kills = save_data.get("total_kills", 0)
	total_play_time = save_data.get("total_play_time", 0.0)
	total_elite_kills = save_data.get("total_elite_kills", 0)
	total_damage_dealt = save_data.get("total_damage_dealt", 0.0)
	max_level_reached = save_data.get("max_level_reached", 1)
	longest_survive_time = save_data.get("longest_survive_time", 0.0)
	total_clears = save_data.get("total_clears", 0)
	all_skills_ever_collected = save_data.get("all_skills_collected", [])
	unlocked_characters = save_data.get("unlocked_characters", ["wandering_swordsman"])
	character_clear_counts = save_data.get("character_clear_counts", {})
	unlocked_achievements = save_data.get("unlocked_achievements", [])

	# 加载角色数据
	var saved_char_data: Dictionary = save_data.get("character_data", {})
	for char_id in saved_char_data:
		if _characters.has(char_id):
			_characters[char_id].from_dictionary(saved_char_data[char_id])
			if _characters[char_id].is_unlocked and char_id not in unlocked_characters:
				unlocked_characters.append(char_id)


## 获取所有角色保存数据
func _get_all_character_save_data() -> Dictionary:
	"""获取所有角色的保存数据"""
	var data: Dictionary = {}
	for char_id in _characters:
		data[char_id] = _characters[char_id].to_dictionary()
	return data


## 获取统计摘要
func get_stats_summary() -> Dictionary:
	"""
	获取统计摘要
	@return: 统计摘要字典
	"""
	return {
		"total_kills": total_kills,
		"total_play_time": total_play_time,
		"total_elite_kills": total_elite_kills,
		"total_damage_dealt": total_damage_dealt,
		"max_level_reached": max_level_reached,
		"longest_survive_time": longest_survive_time,
		"total_clears": total_clears,
		"unlocked_characters_count": unlocked_characters.size(),
		"skills_collected_count": all_skills_ever_collected.size()
	}


## 重置所有进度（调试用）
func reset_all_progress() -> void:
	"""重置所有进度数据"""
	total_kills = 0
	total_play_time = 0.0
	total_elite_kills = 0
	total_damage_dealt = 0.0
	max_level_reached = 1
	longest_survive_time = 0.0
	total_clears = 0
	all_skills_ever_collected.clear()
	unlocked_characters = ["wandering_swordsman"]
	character_clear_counts.clear()
	unlocked_achievements.clear()

	# 重置角色数据
	for char_id in _characters:
		_characters[char_id].reset_unlock()
		_characters[char_id].character_level = 1
		_characters[char_id].character_experience = 0
		_characters[char_id].total_kills = 0
		_characters[char_id].total_play_time = 0.0
		_characters[char_id].clear_count = 0

	_initialize_character_clear_counts()
	_save_progress()

	print("[ChallengeSystem] 所有进度已重置")
