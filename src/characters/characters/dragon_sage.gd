## Void Hunter - 龙智者
## @description: 平衡型角色，经验加成+全属性提升+龙息反击
## @author: Void Hunter Team
## @version: 2.0.0

extends "res://src/characters/character_base.gd"
class_name DragonSage

# =============================================================================
# 私有变量
# =============================================================================

## 龙息冷却计时器
var _breath_cooldown: float = 0.0

## 龙息冷却时间（秒）
var _breath_base_cooldown: float = 5.0

## 龙族血统激活层数（每次升级+1）
var _dragon_blood_stacks: int = 0

## 经验获取累计（用于追踪加成效果）
var _exp_bonus_active: bool = true

## 龙鳞护甲激活状态（受伤后临时增加防御）
var _scale_armor_active: bool = false

## 龙鳞护甲剩余时间
var _scale_armor_timer: float = 0.0

# =============================================================================
# 初始化
# =============================================================================

func _init() -> void:
	character_id = "dragon_sage"
	character_name = "龙智者"
	description = "远古龙族的贤者，拥有均衡的全属性和强力的成长潜力。升级时全属性 +8%，被击中时有概率释放龙息。"
	character_type = CharacterBase.CharacterType.BALANCED
	icon = load("res://assets/icons/characters/dragon_sage.png")
	portrait = load("res://assets/icons/characters/dragon_sage.png")

	# 基础属性 - 均衡偏防御
	base_health = 100.0
	base_attack = 10.0
	base_defense = 7.0
	base_speed = 150.0
	base_mana = 60.0
	base_critical_chance = 0.08
	base_critical_damage = 1.6

	# 被动技能
	passive_name = "龙族天赋"
	passive_description = "经验获取+30%。升级时全属性+8%。被击中时有10%概率释放龙息(小范围AOE)，造成额外伤害。"
	passive_params = {
		"exp_bonus": 0.3,
		"level_up_bonus": 0.08,
		"dragon_breath_chance": 0.1,
		"breath_damage_mult": 2.5,
		"breath_range": 80.0,
		"breath_cooldown": 5.0,
		"scale_armor_defense": 3.0,
		"scale_armor_duration": 4.0
	}

	# 解锁条件 - 无条件解锁
	unlock_condition = CharacterBase.UnlockCondition.NONE
	unlock_value = 0
	is_default_unlocked = false
	is_hidden = false

# =============================================================================
# 重写被动技能方法
# =============================================================================

## 获取经验加成倍率
func get_experience_multiplier() -> float:
	"""获取经验获取加成"""
	return 1.0 + passive_params.get("exp_bonus", 0.3)


## 受伤时触发龙息和龙鳞效果
func on_damage_taken(damage_data: Dictionary) -> Dictionary:
	var result: Dictionary = super.on_damage_taken(damage_data)

	# 龙息反击判定
	if _breath_cooldown <= 0:
		var breath_chance: float = passive_params.get("dragon_breath_chance", 0.1)
		if randf() < breath_chance:
			result["dragon_breath"] = true
			result["breath_damage"] = base_attack * passive_params.get("breath_damage_mult", 2.5)
			result["breath_range"] = passive_params.get("breath_range", 80.0)
			_breath_cooldown = passive_params.get("breath_cooldown", 5.0)
			passive_triggered.emit(passive_name, {
				"dragon_breath": true,
				"damage": result["breath_damage"],
				"range": result["breath_range"]
			})

	# 龙鳞护甲 - 受伤后临时增加防御
	if not _scale_armor_active:
		_scale_armor_active = true
		_scale_armor_timer = passive_params.get("scale_armor_duration", 4.0)
		passive_triggered.emit(passive_name, {"scale_armor": true})

	return result


## 每帧更新 - 冷却计时
func on_process(delta: float, player_stats: Dictionary) -> Dictionary:
	var effects: Dictionary = super.on_process(delta, player_stats)

	# 更新龙息冷却
	if _breath_cooldown > 0:
		_breath_cooldown -= delta

	# 更新龙鳞护甲计时
	if _scale_armor_active:
		_scale_armor_timer -= delta
		if _scale_armor_timer <= 0:
			_scale_armor_active = false
		else:
			effects["bonus_defense"] = passive_params.get("scale_armor_defense", 3.0)

	# 提供龙族血统层数信息
	if _dragon_blood_stacks > 0:
		effects["dragon_blood_stacks"] = _dragon_blood_stacks
		effects["all_stat_bonus"] = _dragon_blood_stacks * passive_params.get("level_up_bonus", 0.08)

	return effects


## 获取修改后的属性 - 应用龙族血统加成
func get_modified_stats(base_stats: Dictionary) -> Dictionary:
	var modified: Dictionary = super.get_modified_stats(base_stats)

	# 龙族血统：每层全属性+8%
	var stack_bonus: float = _dragon_blood_stacks * passive_params.get("level_up_bonus", 0.08)
	for stat in ["health", "attack", "defense", "speed", "mana"]:
		if modified.has(stat):
			modified[stat] = modified[stat] * (1.0 + stack_bonus)

	# 龙鳞护甲额外防御
	if _scale_armor_active:
		modified["defense"] = modified.get("defense", 0) + passive_params.get("scale_armor_defense", 3.0)

	return modified


## 角色升级时调用（由外部升级系统调用）
func notify_level_up() -> void:
	"""通知角色升级，增加龙族血统层数"""
	_dragon_blood_stacks += 1
	passive_triggered.emit(passive_name, {
		"level_up": true,
		"blood_stacks": _dragon_blood_stacks,
		"bonus": passive_params.get("level_up_bonus", 0.08)
	})


## 获取龙族血统层数
func get_dragon_blood_stacks() -> int:
	"""获取当前龙族血统层数"""
	return _dragon_blood_stacks


## 检查龙息是否就绪
func is_breath_ready() -> bool:
	"""检查龙息是否已冷却完毕"""
	return _breath_cooldown <= 0


## 获取龙息冷却进度
func get_breath_cooldown_progress() -> float:
	"""获取龙息冷却进度（0-1）"""
	if _breath_cooldown <= 0:
		return 1.0
	return 1.0 - (_breath_cooldown / passive_params.get("breath_cooldown", 5.0))


## 手动触发龙息（特殊技能使用）
func trigger_dragon_breath() -> Dictionary:
	"""
	手动触发龙息攻击
	@return: 龙息效果数据
	"""
	if _breath_cooldown > 0:
		return {}

	_breath_cooldown = passive_params.get("breath_cooldown", 5.0)
	var breath_damage: float = base_attack * passive_params.get("breath_damage_mult", 2.5) * (1.0 + _dragon_blood_stacks * 0.05)
	var effect: Dictionary = {
		"dragon_breath": true,
		"damage": breath_damage,
		"range": passive_params.get("breath_range", 80.0) + _dragon_blood_stacks * 5.0
	}
	passive_triggered.emit(passive_name, effect)
	return effect


## 重置状态
func reset() -> void:
	super.reset()
	_breath_cooldown = 0.0
	_dragon_blood_stacks = 0
	_exp_bonus_active = true
	_scale_armor_active = false
	_scale_armor_timer = 0.0
