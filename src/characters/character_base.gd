## Void Hunter - 角色基类
## @description: 定义角色的基础属性、被动技能和解锁条件
## @author: Void Hunter Team
## @version: 2.0.0

extends Resource
class_name CharacterBase

# =============================================================================
# 信号定义
# =============================================================================

## 角色解锁时触发
signal character_unlocked(character_id: String)

## 被动技能触发时发送
signal passive_triggered(passive_name: String, effect_data: Dictionary)

## 角色等级提升时触发
signal character_leveled_up(character_id: String, new_level: int)

# =============================================================================
# 枚举定义
# =============================================================================

## 解锁条件类型
enum UnlockCondition {
	NONE,				## 无条件（默认解锁）
	KILL_ENEMIES,		## 单局击杀指定数量敌人
	SURVIVE_TIME,		## 生存指定时间不死
	COLLECT_SKILLS,		## 收集指定数量不同技能
	DEAL_DAMAGE,		## 单局造成指定伤害
	KILL_ELITES,		## 击败指定数量精英敌人
	REACH_VOID_LEVEL,	## 到达虚空层（第10层）
	CLEAR_WITH_ALL		## 使用其他7个角色各通关一次
}

## 角色类型
enum CharacterType {
	BALANCED,		## 平衡型
	HIGH_DPS,		## 高攻速型
	DEFENSIVE,		## 防御型
	MAGIC,			## 法术型
	BURST,			## 爆发型
	SUMMONER,		## 召唤型
	CONTROL,		## 控制型
	ALL_ROUNDER		## 全能型
}

# =============================================================================
# 导出变量 - 角色基础信息
# =============================================================================

## 角色唯一ID
@export var character_id: String = ""

## 角色显示名称
@export var character_name: String = ""

## 角色描述
@export_multiline var description: String = ""

## 角色类型
@export var character_type: CharacterType = CharacterType.BALANCED

## 角色图标
@export var icon: Texture2D

## 角色立绘
@export var portrait: Texture2D

# =============================================================================
# 导出变量 - 基础属性
# =============================================================================

## 基础生命值
@export var base_health: float = 100.0

## 基础攻击力
@export var base_attack: float = 10.0

## 基础防御力
@export var base_defense: float = 5.0

## 基础移动速度
@export var base_speed: float = 150.0

## 基础法力值
@export var base_mana: float = 50.0

## 基础暴击率
@export_range(0.0, 1.0) var base_critical_chance: float = 0.05

## 基础暴击伤害倍率
@export var base_critical_damage: float = 1.5

# =============================================================================
# 导出变量 - 被动技能
# =============================================================================

## 被动技能名称
@export var passive_name: String = ""

## 被动技能描述
@export_multiline var passive_description: String = ""

## 被动技能参数（用于具体实现）
@export var passive_params: Dictionary = {}

# =============================================================================
# 导出变量 - 解锁条件
# =============================================================================

## 解锁条件类型
@export var unlock_condition: UnlockCondition = UnlockCondition.NONE

## 解锁条件数值
@export var unlock_value: int = 0

## 是否默认解锁
@export var is_default_unlocked: bool = false

## 是否为隐藏角色
@export var is_hidden: bool = false

# =============================================================================
# 公共变量
# =============================================================================

## 是否已解锁
var is_unlocked: bool = false

## 解锁进度 (0.0 - 1.0)
var unlock_progress: float = 0.0

## 角色等级（独立于玩家等级）
var character_level: int = 1

## 角色经验值
var character_experience: int = 0

## 角色总击杀数
var total_kills: int = 0

## 角色总游戏时间
var total_play_time: float = 0.0

## 角色通关次数
var clear_count: int = 0

## 永久属性加成（来自角色等级）
var permanent_bonuses: Dictionary = {}

# =============================================================================
# 私有变量
# =============================================================================

var _consecutive_attacks: int = 0
var _last_damage_time: float = 0.0
var _shield_cooldown: float = 0.0
var _has_temporary_shield: bool = false

# =============================================================================
# 公共方法 - 初始化
# =============================================================================

## 初始化角色
func initialize() -> void:
	"""初始化角色状态"""
	is_unlocked = is_default_unlocked
	unlock_progress = 1.0 if is_default_unlocked else 0.0
	_calculate_permanent_bonuses()


## 重置角色状态
func reset() -> void:
	"""重置角色到初始状态"""
	_consecutive_attacks = 0
	_last_damage_time = 0.0
	_shield_cooldown = 0.0
	_has_temporary_shield = false


# =============================================================================
# 公共方法 - 解锁系统
# =============================================================================

## 检查解锁条件
func check_unlock_condition(game_stats: Dictionary) -> bool:
	"""
	检查是否满足解锁条件
	@param game_stats: 游戏统计数据
	@return: 是否满足条件
	"""
	if is_unlocked:
		return true

	var required_value: int = unlock_value
	var current_value: int = 0

	match unlock_condition:
		UnlockCondition.NONE:
			is_unlocked = is_default_unlocked
			return is_unlocked

		UnlockCondition.KILL_ENEMIES:
			# 单局击杀数
			current_value = game_stats.get("session_kills", 0)

		UnlockCondition.SURVIVE_TIME:
			# 生存时间（秒），需要不死
			var survived_without_death: bool = game_stats.get("survived_without_death", false)
			if survived_without_death:
				current_value = int(game_stats.get("survive_time", 0))

		UnlockCondition.COLLECT_SKILLS:
			# 收集的不同技能数量
			current_value = game_stats.get("unique_skills_collected", 0)

		UnlockCondition.DEAL_DAMAGE:
			# 单局造成的总伤害
			current_value = int(game_stats.get("session_damage_dealt", 0))

		UnlockCondition.KILL_ELITES:
			# 累计击杀精英数
			current_value = game_stats.get("total_elite_kills", 0)

		UnlockCondition.REACH_VOID_LEVEL:
			# 到达的层数
			current_value = game_stats.get("max_level_reached", 0)

		UnlockCondition.CLEAR_WITH_ALL:
			# 使用其他角色通关的计数
			current_value = game_stats.get("characters_cleared", 0)

	# 更新进度
	if required_value > 0:
		unlock_progress = minf(1.0, float(current_value) / float(required_value))
	else:
		unlock_progress = 1.0 if is_default_unlocked else 0.0

	# 检查是否满足
	if current_value >= required_value:
		is_unlocked = true
		unlock_progress = 1.0
		character_unlocked.emit(character_id)
		return true

	return false


## 强制解锁
func force_unlock() -> void:
	"""强制解锁角色"""
	is_unlocked = true
	unlock_progress = 1.0
	character_unlocked.emit(character_id)


## 重置解锁状态
func reset_unlock() -> void:
	"""重置解锁状态"""
	is_unlocked = is_default_unlocked
	unlock_progress = 0.0


## 获取解锁条件文本
func get_unlock_condition_text() -> String:
	"""
	获取解锁条件描述文本
	@return: 条件文本
	"""
	if is_unlocked:
		return "已解锁"

	match unlock_condition:
		UnlockCondition.NONE:
			return "默认解锁"
		UnlockCondition.KILL_ENEMIES:
			return "单局击杀 %d 个敌人" % unlock_value
		UnlockCondition.SURVIVE_TIME:
			var minutes: int = unlock_value / 60
			return "生存 %d 分钟不死" % minutes
		UnlockCondition.COLLECT_SKILLS:
			return "收集 %d 个不同技能" % unlock_value
		UnlockCondition.DEAL_DAMAGE:
			if unlock_value >= 10000:
				return "单局造成 %d 万伤害" % (unlock_value / 10000)
			return "单局造成 %d 伤害" % unlock_value
		UnlockCondition.KILL_ELITES:
			return "击败 %d 个精英敌人" % unlock_value
		UnlockCondition.REACH_VOID_LEVEL:
			return "到达第 %d 层" % unlock_value
		UnlockCondition.CLEAR_WITH_ALL:
			return "使用其他7个角色各通关一次"

	return "未知条件"


## 获取解锁进度文本
func get_unlock_progress_text() -> String:
	"""
	获取解锁进度描述文本
	@return: 进度文本
	"""
	if is_unlocked:
		return "已解锁"

	var progress_percent: int = int(unlock_progress * 100)
	return "%d%%" % progress_percent

# =============================================================================
# 公共方法 - 被动技能系统
# =============================================================================

## 获取应用后的属性
func get_modified_stats(base_stats: Dictionary) -> Dictionary:
	"""
	获取经过角色被动修改后的属性
	@param base_stats: 基础属性字典
	@return: 修改后的属性字典
	"""
	var modified: Dictionary = base_stats.duplicate()

	# 应用永久加成
	for stat_name in permanent_bonuses:
		if modified.has(stat_name):
			modified[stat_name] = modified.get(stat_name, 0) + permanent_bonuses[stat_name]

	return modified


## 触发被动技能 - 攻击时
func on_attack(attack_data: Dictionary) -> Dictionary:
	"""
	攻击时触发的被动效果
	@param attack_data: 攻击数据
	@return: 修改后的攻击数据
	"""
	var result: Dictionary = attack_data.duplicate()

	# 子类可以重写此方法实现特定被动
	match character_id:
		"wandering_swordsman":
			# 流浪剑客：连击伤害递增
			_consecutive_attacks += 1
			var max_stacks: int = passive_params.get("max_stacks", 5)
			var damage_bonus_per_stack: float = passive_params.get("damage_bonus", 0.1)
			var stacks: int = mini(_consecutive_attacks, max_stacks)
			var bonus: float = stacks * damage_bonus_per_stack
			result["damage_multiplier"] = result.get("damage_multiplier", 1.0) * (1.0 + bonus)
			if stacks > 0:
				passive_triggered.emit(passive_name, {"stacks": stacks, "bonus": bonus})

		"berserker":
			# 狂战士：低血量时攻击加成在 get_modified_stats 中处理
			pass

	return result


## 触发被动技能 - 受伤时
func on_damage_taken(damage_data: Dictionary) -> Dictionary:
	"""
	受伤时触发的被动效果
	@param damage_data: 伤害数据
	@return: 修改后的伤害数据
	"""
	var result: Dictionary = damage_data.duplicate()
	_last_damage_time = Time.get_ticks_msec() / 1000.0

	match character_id:
		"shadow_assassin":
			# 暗影刺客：受伤时有概率闪避
			var dodge_chance: float = passive_params.get("dodge_chance", 0.2)
			if randf() < dodge_chance:
				result["evaded"] = true
				result["damage"] = 0
				passive_triggered.emit(passive_name, {"evaded": true})

		"berserker":
			# 狂战士：重置连击
			_consecutive_attacks = 0

	return result


## 触发被动技能 - 击杀时
func on_kill(kill_data: Dictionary) -> void:
	"""
	击杀敌人时触发
	@param kill_data: 击杀数据
	"""
	total_kills += 1

	# 重置连击计时（用于流浪剑客）
	if character_id == "wandering_swordsman":
		pass  # 连击在攻击时处理


## 触发被动技能 - 每帧更新
func on_process(delta: float, player_stats: Dictionary) -> Dictionary:
	"""
	每帧更新时触发的被动效果
	@param delta: 帧间隔
	@param player_stats: 玩家当前属性
	@return: 效果数据字典
	"""
	var effects: Dictionary = {}

	match character_id:
		"holy_knight":
			# 圣光骑士：护盾冷却
			_shield_cooldown -= delta
			if _shield_cooldown <= 0 and not _has_temporary_shield:
				var shield_value: float = passive_params.get("shield_value", 30)
				var cooldown: float = passive_params.get("cooldown", 30.0)
				_shield_cooldown = cooldown
				_has_temporary_shield = true
				effects["temporary_shield"] = shield_value
				passive_triggered.emit(passive_name, {"shield": shield_value})

		"elemental_mage":
			# 元素法师：法力恢复加成在 get_modified_stats 中处理
			pass

		"berserker":
			# 狂战士：检查血量触发狂暴
			var health_percent: float = player_stats.get("health_percent", 1.0)
			var threshold: float = passive_params.get("health_threshold", 0.3)
			if health_percent <= threshold:
				effects["berserk_mode"] = true
				var attack_bonus: float = passive_params.get("attack_bonus", 0.5)
				effects["attack_multiplier"] = 1.0 + attack_bonus

		"void_hunter":
			# 虚空猎手：技能效果加成在技能系统中处理
			pass

	# 流浪剑客：超时重置连击
	if character_id == "wandering_swordsman":
		var time_since_last: float = Time.get_ticks_msec() / 1000.0 - _last_damage_time
		if _consecutive_attacks > 0 and time_since_last > 2.0:
			_consecutive_attacks = 0

	return effects


## 触发被动技能 - 死亡时
func on_death() -> Dictionary:
	"""
	死亡时触发的被动效果
	@return: 效果数据字典
	"""
	var effects: Dictionary = {}

	match character_id:
		"time_walker":
			# 时空行者：死亡时有概率复活
			var revive_chance: float = passive_params.get("revive_chance", 0.1)
			if randf() < revive_chance:
				effects["revive"] = true
				var revive_health_percent: float = passive_params.get("revive_health", 0.5)
				effects["revive_health_percent"] = revive_health_percent
				passive_triggered.emit(passive_name, {"revived": true})

	return effects


## 触发被动技能 - 游戏开始时
func on_game_start() -> Dictionary:
	"""
	游戏开始时触发的被动效果
	@return: 效果数据字典
	"""
	var effects: Dictionary = {}

	match character_id:
		"mechanic":
			# 机械师：开局自带炮台
			effects["spawn_turret"] = true
			passive_triggered.emit(passive_name, {"turret": true})

	return effects


## 获取技能效果加成
func get_skill_effect_multiplier() -> float:
	"""
	获取技能效果加成倍率
	@return: 效果倍率
	"""
	if character_id == "void_hunter":
		return 1.0 + passive_params.get("skill_bonus", 0.2)
	return 1.0


## 获取法力恢复加成
func get_mana_regen_bonus() -> float:
	"""
	获取法力恢复加成百分比
	@return: 加成百分比
	"""
	if character_id == "elemental_mage":
		return passive_params.get("mana_regen_bonus", 0.5)
	return 0.0

# =============================================================================
# 公共方法 - 角色成长系统
# =============================================================================

## 增加角色经验
func add_character_experience(amount: int) -> void:
	"""
	增加角色经验值
	@param amount: 经验值数量
	"""
	character_experience += amount

	# 检查升级
	var required: int = get_experience_required_for_level(character_level)
	while character_experience >= required:
		character_experience -= required
		_level_up_character()


## 角色升级
func _level_up_character() -> void:
	"""角色升级处理"""
	character_level += 1
	_calculate_permanent_bonuses()
	character_leveled_up.emit(character_id, character_level)


## 获取升级所需经验
func get_experience_required_for_level(level: int) -> int:
	"""
	获取指定等级所需经验值
	@param level: 等级
	@return: 所需经验值
	"""
	return int(100 * pow(1.5, level - 1))


## 计算永久属性加成
func _calculate_permanent_bonuses() -> void:
	"""根据角色等级计算永久属性加成"""
	permanent_bonuses.clear()

	# 每级提供少量属性加成
	var level_bonus: float = (character_level - 1) * 0.02  # 每级2%

	permanent_bonuses["health_percent"] = level_bonus
	permanent_bonuses["attack_percent"] = level_bonus
	permanent_bonuses["defense_percent"] = level_bonus

	# 特定等级提供额外加成
	if character_level >= 5:
		permanent_bonuses["critical_chance"] = 0.02
	if character_level >= 10:
		permanent_bonuses["critical_damage"] = 0.1
	if character_level >= 15:
		permanent_bonuses["move_speed_percent"] = 0.05
	if character_level >= 20:
		permanent_bonuses["all_stats_percent"] = 0.05

# =============================================================================
# 公共方法 - 数据序列化
# =============================================================================

## 序列化为字典
func to_dictionary() -> Dictionary:
	"""
	序列化角色数据
	@return: 数据字典
	"""
	return {
		"character_id": character_id,
		"is_unlocked": is_unlocked,
		"unlock_progress": unlock_progress,
		"character_level": character_level,
		"character_experience": character_experience,
		"total_kills": total_kills,
		"total_play_time": total_play_time,
		"clear_count": clear_count
	}


## 从字典加载
func from_dictionary(data: Dictionary) -> void:
	"""
	从字典加载角色数据
	@param data: 数据字典
	"""
	is_unlocked = data.get("is_unlocked", is_default_unlocked)
	unlock_progress = data.get("unlock_progress", 1.0 if is_default_unlocked else 0.0)
	character_level = data.get("character_level", 1)
	character_experience = data.get("character_experience", 0)
	total_kills = data.get("total_kills", 0)
	total_play_time = data.get("total_play_time", 0.0)
	clear_count = data.get("clear_count", 0)

	_calculate_permanent_bonuses()

# =============================================================================
# 公共方法 - 辅助方法
# =============================================================================

## 获取角色类型名称
func get_type_name() -> String:
	"""
	获取角色类型的中文名称
	@return: 类型名称
	"""
	match character_type:
		CharacterType.BALANCED:
			return "平衡型"
		CharacterType.HIGH_DPS:
			return "高攻速型"
		CharacterType.DEFENSIVE:
			return "防御型"
		CharacterType.MAGIC:
			return "法术型"
		CharacterType.BURST:
			return "爆发型"
		CharacterType.SUMMONER:
			return "召唤型"
		CharacterType.CONTROL:
			return "控制型"
		CharacterType.ALL_ROUNDER:
			return "全能型"
	return "未知"


## 获取属性评级
func get_stat_rating(stat_name: String) -> int:
	"""
	获取指定属性的评级（1-5星）
	@param stat_name: 属性名称
	@return: 评级（1-5）
	"""
	var value: float = 0.0

	match stat_name:
		"health":
			value = base_health
		"attack":
			value = base_attack
		"defense":
			value = base_defense
		"speed":
			value = base_speed

	# 根据数值范围计算星级
	var rating: int = 3  # 默认3星

	match stat_name:
		"health":
			if value >= 140:
				rating = 5
			elif value >= 120:
				rating = 4
			elif value >= 100:
				rating = 3
			elif value >= 80:
				rating = 2
			else:
				rating = 1
		"attack":
			if value >= 16:
				rating = 5
			elif value >= 13:
				rating = 4
			elif value >= 10:
				rating = 3
			elif value >= 7:
				rating = 2
			else:
				rating = 1
		"defense":
			if value >= 10:
				rating = 5
			elif value >= 7:
				rating = 4
			elif value >= 4:
				rating = 3
			elif value >= 2:
				rating = 2
			else:
				rating = 1
		"speed":
			if value >= 170:
				rating = 5
			elif value >= 160:
				rating = 4
			elif value >= 145:
				rating = 3
			elif value >= 130:
				rating = 2
			else:
				rating = 1

	return rating
