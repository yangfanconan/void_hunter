## Void Hunter - 圣骑士
## @description: 坦克型角色，高生命高防御，自带减伤和低血量反击
## 初始技能：神圣之光
## @author: Void Hunter Team
## @version: 2.0.0

extends "res://src/characters/character_base.gd"
class_name HolyPaladin

# =============================================================================
# 私有变量
# =============================================================================

## 当前攻击力加成百分比（低血量时累积）
var _current_attack_bonus: float = 0.0

## 圣光治愈冷却
var _holy_heal_cooldown: float = 0.0

## 净化效果可用次数
var _purify_available: int = 1

## 神圣之怒激活状态（低血量触发）
var _holy_wrath_active: bool = false

## 受到伤害累计（触发复仇效果）
var _damage_taken_accumulated: float = 0.0

# =============================================================================
# 初始化
# =============================================================================

func _init() -> void:
	character_id = "holy_paladin"
	character_name = "圣骑士"
	description = "虔诚的骑士，誓以圣光守护同伴。高生命、高防御，生命高时减伤，生命低时攻击力暴增。"
	character_type = CharacterBase.CharacterType.DEFENSIVE

	# 基础属性 - 高生命高防御
	base_health = 130.0
	base_attack = 8.0
	base_defense = 12.0
	base_speed = 120.0
	base_mana = 40.0
	base_critical_chance = 0.03
	base_critical_damage = 1.5

	# 被动技能
	passive_name = "圣光庇护"
	passive_description = "生命高于50%时减伤20%，低于30%时攻击力+40%并获得圣光治愈。每60秒可净化一次负面效果。"
	passive_params = {
		"defense_bonus": 0.2,
		"attack_bonus": 0.4,
		"threshold_high": 0.5,
		"threshold_low": 0.3,
		"holy_heal_percent": 0.15,
		"holy_heal_cooldown": 20.0,
		"purify_cooldown": 60.0,
		"wrath_damage_return": 0.2,
		"damage_accumulate_threshold": 50.0
	}

	# 解锁条件 - 无特殊条件
	unlock_condition = CharacterBase.UnlockCondition.NONE
	unlock_value = 0
	is_default_unlocked = false
	is_hidden = false

# =============================================================================
# 重写被动技能方法
# =============================================================================

## 受伤时根据血量触发减伤或反击
func on_damage_taken(damage_data: Dictionary) -> Dictionary:
	var result: Dictionary = super.on_damage_taken(damage_data)

	# 注意：这里使用调用者提供的health_percent，因为角色是Resource不含current_health
	var health_percent: float = damage_data.get("health_percent", 1.0)

	# 生命高于50%时减伤20%
	if health_percent > passive_params.get("threshold_high", 0.5):
		var reduction: float = passive_params.get("defense_bonus", 0.2)
		var original_damage: float = result.get("damage", 0)
		result["damage"] = original_damage * (1.0 - reduction)
		result["damage_reduced"] = original_damage * reduction
		result["holy_shield_active"] = true

	# 累计受伤（用于复仇效果）
	_damage_taken_accumulated += result.get("damage", 0)

	# 生命低于30%时激活神圣之怒
	if health_percent < passive_params.get("threshold_low", 0.3):
		if not _holy_wrath_active:
			_holy_wrath_active = true
			_current_attack_bonus = passive_params.get("attack_bonus", 0.4)
			passive_triggered.emit(passive_name, {"holy_wrath": true, "attack_bonus": _current_attack_bonus})

		# 反伤效果
		var return_damage: float = result.get("damage", 0) * passive_params.get("wrath_damage_return", 0.2)
		result["damage_return"] = return_damage
		result["damage_return_range"] = 80.0
	else:
		if _holy_wrath_active:
			_holy_wrath_active = false
			_current_attack_bonus = 0.0
			passive_triggered.emit(passive_name, {"holy_wrath": false})

	return result


## 攻击时附加神圣伤害
func on_attack(attack_data: Dictionary) -> Dictionary:
	var result: Dictionary = super.on_attack(attack_data)

	# 神圣之怒状态下的攻击加成
	if _holy_wrath_active and _current_attack_bonus > 0:
		result["damage_multiplier"] = result.get("damage_multiplier", 1.0) * (1.0 + _current_attack_bonus)
		# 神圣伤害无视部分防御
		result["holy_damage"] = true
		result["armor_penetration"] = 0.3

	return result


## 每帧更新 - 圣光治愈冷却和复仇检查
func on_process(delta: float, player_stats: Dictionary) -> Dictionary:
	var effects: Dictionary = super.on_process(delta, player_stats)

	# 圣光治愈冷却
	if _holy_heal_cooldown > 0:
		_holy_heal_cooldown -= delta

	# 低血量时自动触发圣光治愈
	var health_percent: float = player_stats.get("health_percent", 1.0)
	if health_percent < passive_params.get("threshold_low", 0.3) and _holy_heal_cooldown <= 0:
		var heal_percent: float = passive_params.get("holy_heal_percent", 0.15)
		effects["holy_heal"] = true
		effects["heal_percent"] = heal_percent
		_holy_heal_cooldown = passive_params.get("holy_heal_cooldown", 20.0)
		passive_triggered.emit(passive_name, {"holy_heal": heal_percent})

	# 复仇效果：累计受伤达到阈值时释放范围伤害
	if _damage_taken_accumulated >= passive_params.get("damage_accumulate_threshold", 50.0):
		effects["revenge_damage"] = true
		effects["revenge_damage_amount"] = _damage_taken_accumulated * 0.5
		effects["revenge_range"] = 100.0
		passive_triggered.emit(passive_name, {"revenge": effects["revenge_damage_amount"]})
		_damage_taken_accumulated = 0.0

	# 提供当前状态
	effects["holy_wrath_active"] = _holy_wrath_active
	effects["attack_bonus"] = _current_attack_bonus

	return effects


## 获取修改后的属性
func get_modified_stats(base_stats: Dictionary) -> Dictionary:
	var modified: Dictionary = super.get_modified_stats(base_stats)

	# 高血量时额外防御加成
	# 注意：由于Resource无法直接获取current_health，防御加成在on_damage_taken中通过减伤实现

	# 神圣之怒状态下的攻击加成
	if _holy_wrath_active:
		modified["attack"] = modified.get("attack", 0) * (1.0 + _current_attack_bonus)

	return modified


## 净化负面效果（由外部调用）
func try_purify() -> bool:
	"""
	尝试净化负面效果
	@return: 是否成功净化
	"""
	if _purify_available > 0:
		_purify_available -= 1
		passive_triggered.emit(passive_name, {"purify": true})
		return true
	return false


## 检查是否可以净化
func can_purify() -> bool:
	"""检查是否可以净化"""
	return _purify_available > 0


## 获取圣光治愈冷却进度
func get_holy_heal_cooldown_progress() -> float:
	"""获取圣光治愈冷却进度（0-1）"""
	if _holy_heal_cooldown <= 0:
		return 1.0
	return 1.0 - (_holy_heal_cooldown / passive_params.get("holy_heal_cooldown", 20.0))


## 检查是否处于神圣之怒状态
func is_holy_wrath_active() -> bool:
	"""检查是否处于神圣之怒状态"""
	return _holy_wrath_active


## 重置状态
func reset() -> void:
	super.reset()
	_current_attack_bonus = 0.0
	_holy_heal_cooldown = 0.0
	_purify_available = 1
	_holy_wrath_active = false
	_damage_taken_accumulated = 0.0
