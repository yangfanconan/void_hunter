## Void Hunter - 虚空猎手
## @description: 隐藏全能型角色，拥有虚空之力被动技能
## @author: Void Hunter Team
## @version: 1.0.0

extends "res://src/characters/character_base.gd"
class_name VoidHunter

# =============================================================================
# 私有变量
# =============================================================================

var _void_power_stacks: int = 0
var _max_void_stacks: int = 10

# =============================================================================
# 初始化
# =============================================================================

func _init() -> void:
	# 基础信息
	character_id = "void_hunter"
	character_name = "虚空猎手"
	description = "从虚空深处归来的神秘存在，融合了所有英雄的力量，是真正的终极猎手。"
	character_type = CharacterBase.CharacterType.ALL_ROUNDER

	# 基础属性 - 全面强大
	base_health = 110.0
	base_attack = 14.0
	base_defense = 8.0
	base_speed = 155.0
	base_mana = 80.0
	base_critical_chance = 0.08
	base_critical_damage = 1.8

	# 被动技能
	passive_name = "虚空之力"
	passive_description = "融合虚空能量，所有技能效果提升20%，每次击杀获得虚空层数，每层提供1%全属性加成，最多10层。"
	passive_params = {
		"skill_effect_bonus": 0.2,		# 技能效果加成
		"stack_per_kill": 1,			# 每次击杀获得层数
		"max_stacks": 10,				# 最大层数
		"stat_bonus_per_stack": 0.01,	# 每层属性加成
		"all_skill_unlock": true		# 可以使用所有类型技能
	}

	# 解锁条件 - 使用其他7个角色各通关一次
	unlock_condition = CharacterBase.UnlockCondition.CLEAR_WITH_ALL
	unlock_value = 7
	is_default_unlocked = false
	is_hidden = true  # 隐藏角色

# =============================================================================
# 重写被动技能方法
# =============================================================================

## 获取技能效果加成
func get_skill_effect_multiplier() -> float:
	"""获取技能效果倍率"""
	var base_bonus: float = passive_params.get("skill_effect_bonus", 0.2)
	return 1.0 + base_bonus


## 击杀时获得虚空层数
func on_kill(kill_data: Dictionary) -> void:
	super.on_kill(kill_data)

	# 增加虚空层数
	if _void_power_stacks < _max_void_stacks:
		_void_power_stacks += 1
		passive_triggered.emit(passive_name, {
			"stacks": _void_power_stacks,
			"bonus": _void_power_stacks * passive_params.get("stat_bonus_per_stack", 0.01)
		})


## 获取修改后的属性
func get_modified_stats(base_stats: Dictionary) -> Dictionary:
	var modified: Dictionary = super.get_modified_stats(base_stats)

	# 虚空层数加成
	var stack_bonus: float = _void_power_stacks * passive_params.get("stat_bonus_per_stack", 0.01)

	# 全属性加成
	for stat in ["health", "attack", "defense", "speed"]:
		if modified.has(stat):
			modified[stat] = modified[stat] * (1.0 + stack_bonus)

	return modified


## 获取当前虚空层数
func get_void_stacks() -> int:
	"""获取当前虚空层数"""
	return _void_power_stacks


## 获取虚空层数加成
func get_void_stack_bonus() -> float:
	"""获取当前虚空层数提供的属性加成"""
	return _void_power_stacks * passive_params.get("stat_bonus_per_stack", 0.01)


## 重置虚空层数
func reset_void_stacks() -> void:
	"""重置虚空层数（新游戏开始时）"""
	_void_power_stacks = 0


## 检查是否可以使用所有技能
func can_use_all_skills() -> bool:
	"""检查是否可以使用所有类型技能"""
	return passive_params.get("all_skill_unlock", true)


## 获取虚空能量爆发
func trigger_void_burst() -> Dictionary:
	"""
	触发虚空能量爆发（消耗所有层数）
	@return: 爆发效果数据
	"""
	if _void_power_stacks <= 0:
		return {}

	var burst_damage: float = base_attack * _void_power_stacks * 2.0
	var burst_heal: float = base_health * _void_power_stacks * 0.05

	var effect: Dictionary = {
		"damage": burst_damage,
		"heal": burst_heal,
		"radius": 200.0 + _void_power_stacks * 20.0,
		"stacks_consumed": _void_power_stacks
	}

	_void_power_stacks = 0
	passive_triggered.emit(passive_name, {"void_burst": effect})

	return effect


## 重置状态
func reset() -> void:
	super.reset()
	_void_power_stacks = 0
