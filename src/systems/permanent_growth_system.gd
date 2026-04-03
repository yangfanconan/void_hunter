## Void Hunter - 永久成长系统
## @description: 角色永久属性成长、天赋点、局外强化
## @version: 1.0.0

extends Node

# =============================================================================
# 信号定义
# =============================================================================

signal growth_point_gained(points: int, reason: String)
signal attribute_upgraded(attr_name: String, new_level: int)
signal talent_unlocked(talent_id: String)
signal permanent_stats_changed()

# =============================================================================
# 常量定义
# =============================================================================

## 每升一级所需经验
const EXP_PER_LEVEL: int = 1000

## 每级获得的天赋点
const TALENT_POINTS_PER_LEVEL: int = 1

## 最大属性等级
const MAX_ATTRIBUTE_LEVEL: int = 20

## 属性每级提升值
const ATTRIBUTE_BONUS_PER_LEVEL: Dictionary = {
	"health": 10.0,
	"attack": 2.0,
	"defense": 1.5,
	"speed": 2.0,
	"mana": 5.0,
	"critical_chance": 0.01,
	"critical_damage": 0.05,
}

# =============================================================================
# 公共变量 - 账户等级
# =============================================================================

## 账户等级
var account_level: int = 1

## 账户经验
var account_experience: int = 0

## 可用天赋点
var available_talent_points: int = 0

## 累计获得天赋点
var total_talent_points: int = 0

# =============================================================================
# 公共变量 - 永久属性
# =============================================================================

## 永久属性等级
var attribute_levels: Dictionary = {
	"health": 0,
	"attack": 0,
	"defense": 0,
	"speed": 0,
	"mana": 0,
	"critical_chance": 0,
	"critical_damage": 0,
}

# =============================================================================
# 公共变量 - 天赋树
# =============================================================================

## 已解锁的天赋ID列表
var unlocked_talents: Array[String] = []

## 天赋配置
const TALENT_CONFIG: Dictionary = {
	# 攻击系
	"attack_power_1": {
		"name": "攻击强化 I",
		"description": "攻击力 +5%",
		"cost": 1,
		"requires": [],
		"effects": {"attack_percent": 0.05}
	},
	"attack_power_2": {
		"name": "攻击强化 II",
		"description": "攻击力 +10%",
		"cost": 2,
		"requires": ["attack_power_1"],
		"effects": {"attack_percent": 0.10}
	},
	"attack_power_3": {
		"name": "攻击强化 III",
		"description": "攻击力 +15%",
		"cost": 3,
		"requires": ["attack_power_2"],
		"effects": {"attack_percent": 0.15}
	},
	"critical_master": {
		"name": "暴击大师",
		"description": "暴击率 +5%，暴击伤害 +20%",
		"cost": 2,
		"requires": ["attack_power_1"],
		"effects": {"critical_chance": 0.05, "critical_damage": 0.20}
	},

	# 防御系
	"defense_1": {
		"name": "防御强化 I",
		"description": "生命值 +5%，防御力 +5%",
		"cost": 1,
		"requires": [],
		"effects": {"health_percent": 0.05, "defense_percent": 0.05}
	},
	"defense_2": {
		"name": "防御强化 II",
		"description": "生命值 +10%，防御力 +10%",
		"cost": 2,
		"requires": ["defense_1"],
		"effects": {"health_percent": 0.10, "defense_percent": 0.10}
	},
	"regeneration": {
		"name": "生命回复",
		"description": "每秒回复最大生命值 0.5%",
		"cost": 2,
		"requires": ["defense_1"],
		"effects": {"health_regen_percent": 0.005}
	},
	"shield_mastery": {
		"name": "护盾精通",
		"description": "护盾效果 +30%",
		"cost": 2,
		"requires": ["defense_2"],
		"effects": {"shield_bonus": 0.30}
	},

	# 速度系
	"speed_1": {
		"name": "迅捷 I",
		"description": "移动速度 +5%",
		"cost": 1,
		"requires": [],
		"effects": {"speed_percent": 0.05}
	},
	"speed_2": {
		"name": "迅捷 II",
		"description": "移动速度 +10%",
		"cost": 2,
		"requires": ["speed_1"],
		"effects": {"speed_percent": 0.10}
	},
	"cooldown_reduction": {
		"name": "冷却缩减",
		"description": "技能冷却 -10%",
		"cost": 2,
		"requires": ["speed_1"],
		"effects": {"cooldown_reduction": 0.10}
	},
	"dodge": {
		"name": "闪避本能",
		"description": "闪避率 +8%",
		"cost": 3,
		"requires": ["speed_2"],
		"effects": {"dodge_chance": 0.08}
	},

	# 资源系
	"mana_1": {
		"name": "法力充沛 I",
		"description": "最大法力 +10%",
		"cost": 1,
		"requires": [],
		"effects": {"mana_percent": 0.10}
	},
	"mana_2": {
		"name": "法力充沛 II",
		"description": "最大法力 +20%，法力回复 +50%",
		"cost": 2,
		"requires": ["mana_1"],
		"effects": {"mana_percent": 0.20, "mana_regen": 0.50}
	},
	"exp_bonus": {
		"name": "经验加成",
		"description": "经验获取 +15%",
		"cost": 2,
		"requires": [],
		"effects": {"exp_bonus": 0.15}
	},
	"gold_bonus": {
		"name": "金币加成",
		"description": "金币获取 +20%",
		"cost": 2,
		"requires": ["exp_bonus"],
		"effects": {"gold_bonus": 0.20}
	},

	# 特殊系
	"life_steal": {
		"name": "生命偷取",
		"description": "攻击回复伤害 3% 的生命",
		"cost": 3,
		"requires": ["attack_power_1", "defense_1"],
		"effects": {"life_steal": 0.03}
	},
	"execute": {
		"name": "斩杀",
		"description": "对生命值低于 20% 的敌人伤害 +50%",
		"cost": 3,
		"requires": ["attack_power_2"],
		"effects": {"execute_bonus": 0.50}
	},
	"start_bonus": {
		"name": "开局优势",
		"description": "游戏开始时获得随机增益",
		"cost": 3,
		"requires": ["exp_bonus"],
		"effects": {"start_buff": true}
	},
}

# =============================================================================
# 私有变量
# =============================================================================

var _is_initialized: bool = false

# =============================================================================
# 生命周期
# =============================================================================

func _ready() -> void:
	initialize()

# =============================================================================
# 公共方法
# =============================================================================

func initialize() -> void:
	if _is_initialized:
		return
	_is_initialized = true
	_load_progress()
	print("[PermanentGrowth] 永久成长系统初始化完成")

## 添加账户经验
func add_account_experience(amount: int, reason: String = "game_complete") -> void:
	account_experience += amount

	# 检查升级
	while account_experience >= _get_exp_required_for_level(account_level + 1):
		account_experience -= _get_exp_required_for_level(account_level + 1)
		_level_up()

	growth_point_gained.emit(amount, reason)
	_save_progress()

## 升级属性
func upgrade_attribute(attr_name: String) -> bool:
	if not attribute_levels.has(attr_name):
		return false

	if attribute_levels[attr_name] >= MAX_ATTRIBUTE_LEVEL:
		return false

	if available_talent_points <= 0:
		return false

	available_talent_points -= 1
	attribute_levels[attr_name] += 1

	attribute_upgraded.emit(attr_name, attribute_levels[attr_name])
	permanent_stats_changed.emit()
	_save_progress()

	return true

## 解锁天赋
func unlock_talent(talent_id: String) -> bool:
	if not TALENT_CONFIG.has(talent_id):
		return false

	if talent_id in unlocked_talents:
		return false

	var talent: Dictionary = TALENT_CONFIG[talent_id]
	var cost: int = talent.get("cost", 1)

	if available_talent_points < cost:
		return false

	# 检查前置天赋
	var requires: Array = talent.get("requires", [])
	for req_id in requires:
		if req_id not in unlocked_talents:
			return false

	available_talent_points -= cost
	unlocked_talents.append(talent_id)

	talent_unlocked.emit(talent_id)
	permanent_stats_changed.emit()
	_save_progress()

	return true

## 检查天赋是否可解锁
func can_unlock_talent(talent_id: String) -> bool:
	if not TALENT_CONFIG.has(talent_id):
		return false

	if talent_id in unlocked_talents:
		return false

	var talent: Dictionary = TALENT_CONFIG[talent_id]
	var cost: int = talent.get("cost", 1)

	if available_talent_points < cost:
		return false

	var requires: Array = talent.get("requires", [])
	for req_id in requires:
		if req_id not in unlocked_talents:
			return false

	return true

## 获取永久属性加成
func get_permanent_bonuses() -> Dictionary:
	var bonuses := {
		"health": 0.0,
		"attack": 0.0,
		"defense": 0.0,
		"speed": 0.0,
		"mana": 0.0,
		"critical_chance": 0.0,
		"critical_damage": 0.0,
		"attack_percent": 0.0,
		"defense_percent": 0.0,
		"health_percent": 0.0,
		"speed_percent": 0.0,
		"mana_percent": 0.0,
		"cooldown_reduction": 0.0,
		"dodge_chance": 0.0,
		"life_steal": 0.0,
		"exp_bonus": 0.0,
		"gold_bonus": 0.0,
	}

	# 属性等级加成
	for attr in attribute_levels:
		var level: int = attribute_levels[attr]
		if level > 0 and ATTRIBUTE_BONUS_PER_LEVEL.has(attr):
			bonuses[attr] += ATTRIBUTE_BONUS_PER_LEVEL[attr] * level

	# 天赋加成
	for talent_id in unlocked_talents:
		if TALENT_CONFIG.has(talent_id):
			var effects: Dictionary = TALENT_CONFIG[talent_id].get("effects", {})
			for effect_key in effects:
				if bonuses.has(effect_key):
					bonuses[effect_key] += effects[effect_key]

	return bonuses

## 获取升级到下一级所需经验
func get_exp_to_next_level() -> int:
	return _get_exp_required_for_level(account_level + 1) - account_experience

## 获取当前经验进度 (0-1)
func get_level_progress() -> float:
	var required := _get_exp_required_for_level(account_level + 1)
	return float(account_experience) / float(required)

## 获取系统信息
func get_system_info() -> Dictionary:
	return {
		"account_level": account_level,
		"account_experience": account_experience,
		"available_talent_points": available_talent_points,
		"attribute_levels": attribute_levels.duplicate(),
		"unlocked_talents": unlocked_talents.duplicate(),
		"permanent_bonuses": get_permanent_bonuses(),
	}

# =============================================================================
# 私有方法
# =============================================================================

func _level_up() -> void:
	account_level += 1
	available_talent_points += TALENT_POINTS_PER_LEVEL
	total_talent_points += TALENT_POINTS_PER_LEVEL
	print("[PermanentGrowth] 账户升级到 %d 级！获得 %d 天赋点" % [account_level, TALENT_POINTS_PER_LEVEL])

func _get_exp_required_for_level(level: int) -> int:
	return EXP_PER_LEVEL * level

func _save_progress() -> void:
	var save_data := {
		"account_level": account_level,
		"account_experience": account_experience,
		"available_talent_points": available_talent_points,
		"total_talent_points": total_talent_points,
		"attribute_levels": attribute_levels.duplicate(),
		"unlocked_talents": unlocked_talents.duplicate(),
	}
	if SaveManager:
		SaveManager.save_growth_data(save_data)

func _load_progress() -> void:
	if not SaveManager:
		return

	var save_data: Dictionary = SaveManager.load_growth_data()
	if save_data.is_empty():
		return

	account_level = save_data.get("account_level", 1)
	account_experience = save_data.get("account_experience", 0)
	available_talent_points = save_data.get("available_talent_points", 0)
	total_talent_points = save_data.get("total_talent_points", 0)

	var loaded_attrs: Dictionary = save_data.get("attribute_levels", {})
	for attr in loaded_attrs:
		if attribute_levels.has(attr):
			attribute_levels[attr] = loaded_attrs[attr]

	var loaded_talents: Array = save_data.get("unlocked_talents", [])
	for talent_id in loaded_talents:
		if talent_id is String and TALENT_CONFIG.has(talent_id):
			unlocked_talents.append(talent_id)

## 重置所有进度
func reset_progress() -> void:
	account_level = 1
	account_experience = 0
	available_talent_points = 0
	total_talent_points = 0

	for attr in attribute_levels:
		attribute_levels[attr] = 0

	unlocked_talents.clear()
	_save_progress()