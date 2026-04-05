## Void Hunter - 机械师
## @description: 召唤型角色，拥有炮台助手被动技能
## @author: Void Hunter Team
## @version: 1.0.0

extends "res://src/characters/character_base.gd"
class_name Mechanic

# =============================================================================
# 私有变量
# =============================================================================

var _turrets_spawned: int = 0
var _max_turrets: int = 3

# =============================================================================
# 初始化
# =============================================================================

func _init() -> void:
	# 基础信息
	character_id = "mechanic"
	character_name = "机械师"
	description = "精通机械工程的天才发明家，能够制造各种自动化装置辅助战斗。"
	character_type = CharacterBase.CharacterType.SUMMONER
	icon = load("res://assets/icons/characters/mechanic.png")
	portrait = load("res://assets/icons/characters/mechanic.png")

	# 基础属性 - 中等属性
	base_health = 90.0
	base_attack = 8.0
	base_defense = 6.0
	base_speed = 130.0
	base_mana = 70.0
	base_critical_chance = 0.05
	base_critical_damage = 1.5

	# 被动技能
	passive_name = "炮台助手"
	passive_description = "开局自带一个自动攻击炮台。炮台每2秒发射一次，造成80%攻击力的伤害。最多同时存在3个炮台。"
	passive_params = {
		"initial_turret": true,		# 开局自带炮台
		"turret_damage": 0.8,		# 炮台伤害倍率
		"turret_fire_rate": 2.0,	# 炮台射击间隔
		"turret_range": 300.0,		# 炮台射程
		"max_turrets": 3			# 最大炮台数量
	}

	# 解锁条件 - 击败100个精英敌人
	unlock_condition = CharacterBase.UnlockCondition.KILL_ELITES
	unlock_value = 100
	is_default_unlocked = false
	is_hidden = false

# =============================================================================
# 重写被动技能方法
# =============================================================================

## 游戏开始时生成初始炮台
func on_game_start() -> Dictionary:
	var effects: Dictionary = super.on_game_start()

	if passive_params.get("initial_turret", true):
		effects["spawn_turret"] = true
		_turrets_spawned = 1

	return effects


## 生成新炮台
func spawn_turret() -> Dictionary:
	"""
	生成新炮台
	@return: 炮台数据
	"""
	if _turrets_spawned >= _max_turrets:
		return {}

	_turrets_spawned += 1

	var turret_data: Dictionary = {
		"damage": base_attack * passive_params.get("turret_damage", 0.8),
		"fire_rate": passive_params.get("turret_fire_rate", 2.0),
		"range": passive_params.get("turret_range", 300.0),
		"owner_id": character_id
	}

	passive_triggered.emit(passive_name, {"turret_spawned": _turrets_spawned})

	return turret_data


## 炮台被摧毁
func on_turret_destroyed() -> void:
	"""炮台被摧毁时调用"""
	if _turrets_spawned > 0:
		_turrets_spawned -= 1


## 获取当前炮台数量
func get_turret_count() -> int:
	"""获取当前炮台数量"""
	return _turrets_spawned


## 获取炮台伤害
func get_turret_damage() -> float:
	"""获取单个炮台的伤害"""
	return base_attack * passive_params.get("turret_damage", 0.8)


## 获取总炮台DPS
func get_total_turret_dps() -> float:
	"""
	计算所有炮台的总DPS
	@return: 总DPS
	"""
	var turret_damage: float = get_turret_damage()
	var fire_rate: float = passive_params.get("turret_fire_rate", 2.0)
	var dps_per_turret: float = turret_damage / fire_rate
	return dps_per_turret * _turrets_spawned


## 升级炮台
func upgrade_turrets(bonus_damage_percent: float) -> void:
	"""
	升级所有炮台
	@param bonus_damage_percent: 额外伤害百分比
	"""
	passive_params["turret_damage"] = passive_params.get("turret_damage", 0.8) + bonus_damage_percent
	passive_triggered.emit(passive_name, {"turret_upgraded": passive_params["turret_damage"]})


## 重置炮台状态
func reset() -> void:
	super.reset()
	_turrets_spawned = 0
