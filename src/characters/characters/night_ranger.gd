## Void Hunter - 夜行者
## @description: 敏捷型角色，极速高闪避，闪避时反击敌人
## 初始技能：暗影步
## @author: Void Hunter Team
## @version: 2.0.0

extends "res://src/characters/character_base.gd"
class_name NightRanger

# =============================================================================
# 私有变量
# =============================================================================

## 连续闪避计数
var _consecutive_dodges: int = 0

## 闪避冷却（避免过于频繁）
var _dodge_cooldown: float = 0.0

## 暗影步充能层数
var _shadow_step_charges: int = 2

## 暗影步充能恢复计时
var _shadow_step_recharge_timer: float = 0.0

## 暗夜之力激活状态（连续闪避触发）
var _night_power_active: bool = false

## 暗夜之力剩余时间
var _night_power_timer: float = 0.0

## 累计闪避伤害（用于触发暗影爆发）
var _dodge_damage_accumulated: float = 0.0

# =============================================================================
# 初始化
# =============================================================================

func _init() -> void:
	character_id = "night_ranger"
	character_name = "夜行者"
	description = "行走在黑暗边缘的刺客，以极速和闪避著称。每次闪避成功时自动反击周围敌人，连续闪避可触发暗夜之力。"
	character_type = CharacterBase.CharacterType.HIGH_DPS
	icon = load("res://assets/icons/characters/night_ranger.png")
	portrait = load("res://assets/icons/characters/night_ranger.png")

	# 基础属性 - 高速度高暴击，低生命低防御
	base_health = 70.0
	base_attack = 10.0
	base_defense = 3.0
	base_speed = 200.0
	base_mana = 50.0
	base_critical_chance = 0.15
	base_critical_damage = 2.0

	# 被动技能
	passive_name = "暗影闪避"
	passive_description = "闪避率+15%。每次成功闪避时自动反击，造成攻击力150%的伤害。连续闪避3次触发暗夜之力：移动速度+30%，暴击率+20%，持续5秒。"
	passive_params = {
		"dodge_chance": 0.15,
		"counter_damage_mult": 1.5,
		"counter_range": 60.0,
		"dodge_cooldown": 0.3,
		"night_power_dodge_required": 3,
		"night_power_duration": 5.0,
		"night_power_speed_bonus": 0.3,
		"night_power_crit_bonus": 0.2,
		"shadow_step_max_charges": 2,
		"shadow_step_recharge_time": 8.0,
		"shadow_step_invulnerable_time": 0.5
	}

	# 解锁条件 - 单局击杀100敌人
	unlock_condition = CharacterBase.UnlockCondition.KILL_ENEMIES
	unlock_value = 100
	is_default_unlocked = false
	is_hidden = false

# =============================================================================
# 重写被动技能方法
# =============================================================================

## 受伤时触发闪避判定
func on_damage_taken(damage_data: Dictionary) -> Dictionary:
	var result: Dictionary = super.on_damage_taken(damage_data)

	# 闪避冷却检查
	if _dodge_cooldown > 0:
		return result

	# 闪避判定
	var dodge_chance: float = passive_params.get("dodge_chance", 0.15)

	# 暗夜之力额外闪避加成
	if _night_power_active:
		dodge_chance += 0.1  # 暗夜之力期间额外+10%闪避

	if randf() < dodge_chance:
		# 闪避成功
		var original_damage: float = result.get("damage", 0)
		result["evaded"] = true
		result["damage"] = 0
		result["dodged_amount"] = original_damage
		_dodge_cooldown = passive_params.get("dodge_cooldown", 0.3)

		# 累计闪避伤害
		_dodge_damage_accumulated += original_damage

		# 触发反击
		var counter_damage: float = base_attack * passive_params.get("counter_damage_mult", 1.5)
		result["counter_attack"] = true
		result["counter_damage"] = counter_damage
		result["counter_range"] = passive_params.get("counter_range", 60.0)

		# 连续闪避计数
		_consecutive_dodges += 1

		# 检查暗夜之力触发
		var required_dodges: int = passive_params.get("night_power_dodge_required", 3)
		if _consecutive_dodges >= required_dodges and not _night_power_active:
			_activate_night_power()

		passive_triggered.emit(passive_name, {
			"evaded": true,
			"counter_damage": counter_damage,
			"consecutive_dodges": _consecutive_dodges
		})
	else:
		# 闪避失败，重置连续闪避计数
		_consecutive_dodges = 0

	return result


## 每帧更新 - 冷却和暗夜之力计时
func on_process(delta: float, player_stats: Dictionary) -> Dictionary:
	var effects: Dictionary = super.on_process(delta, player_stats)

	# 闪避冷却
	if _dodge_cooldown > 0:
		_dodge_cooldown -= delta

	# 暗夜之力计时
	if _night_power_active:
		_night_power_timer -= delta
		if _night_power_timer <= 0:
			_night_power_active = false
			_consecutive_dodges = 0
			passive_triggered.emit(passive_name, {"night_power_end": true})
		else:
			effects["night_power_active"] = true
			effects["speed_bonus"] = passive_params.get("night_power_speed_bonus", 0.3)
			effects["crit_bonus"] = passive_params.get("night_power_crit_bonus", 0.2)

	# 暗影步充能恢复
	if _shadow_step_charges < passive_params.get("shadow_step_max_charges", 2):
		_shadow_step_recharge_timer += delta
		if _shadow_step_recharge_timer >= passive_params.get("shadow_step_recharge_time", 8.0):
			_shadow_step_charges += 1
			_shadow_step_recharge_timer = 0.0
			passive_triggered.emit(passive_name, {"shadow_step_recharged": _shadow_step_charges})

	return effects


## 攻击时暗夜之力加成
func on_attack(attack_data: Dictionary) -> Dictionary:
	var result: Dictionary = super.on_attack(attack_data)

	# 暗夜之力状态下的攻击加成
	if _night_power_active:
		# 额外暴击率
		var crit_bonus: float = passive_params.get("night_power_crit_bonus", 0.2)
		result["bonus_crit_chance"] = crit_bonus
		# 攻击速度提升
		result["attack_speed_bonus"] = 0.2

	return result


## 获取修改后的属性
func get_modified_stats(base_stats: Dictionary) -> Dictionary:
	var modified: Dictionary = super.get_modified_stats(base_stats)

	# 基础闪避率
	modified["dodge_chance"] = passive_params.get("dodge_chance", 0.15)

	# 暗夜之力加成
	if _night_power_active:
		modified["speed"] = modified.get("speed", 0) * (1.0 + passive_params.get("night_power_speed_bonus", 0.3))
		modified["critical_chance"] = modified.get("critical_chance", 0) + passive_params.get("night_power_crit_bonus", 0.2)

	return modified


## 使用暗影步（由外部技能系统调用）
func use_shadow_step() -> Dictionary:
	"""
	使用暗影步（瞬移闪避）
	@return: 暗影步效果数据
	"""
	if _shadow_step_charges <= 0:
		return {}

	_shadow_step_charges -= 1

	var effect: Dictionary = {
		"shadow_step": true,
		"invulnerable_time": passive_params.get("shadow_step_invulnerable_time", 0.5),
		"speed_boost": 0.5,
		"speed_boost_duration": 1.0
	}

	# 暗影步也算作一次闪避，触发反击
	_consecutive_dodges += 1
	effect["counter_attack"] = true
	effect["counter_damage"] = base_attack * passive_params.get("counter_damage_mult", 1.5) * 1.5  # 暗影步反击1.5倍
	effect["counter_range"] = passive_params.get("counter_range", 60.0) * 1.5

	# 检查暗夜之力触发
	var required_dodges: int = passive_params.get("night_power_dodge_required", 3)
	if _consecutive_dodges >= required_dodges and not _night_power_active:
		_activate_night_power()

	passive_triggered.emit(passive_name, {"shadow_step": true, "charges_left": _shadow_step_charges})

	return effect


## 获取暗影步充能数
func get_shadow_step_charges() -> int:
	"""获取当前暗影步充能数"""
	return _shadow_step_charges


## 获取暗影步充能进度
func get_shadow_step_recharge_progress() -> float:
	"""获取暗影步充能进度（0-1）"""
	if _shadow_step_charges >= passive_params.get("shadow_step_max_charges", 2):
		return 1.0
	var recharge_time: float = passive_params.get("shadow_step_recharge_time", 8.0)
	return _shadow_step_recharge_timer / recharge_time


## 检查暗夜之力是否激活
func is_night_power_active() -> bool:
	"""检查暗夜之力是否激活"""
	return _night_power_active


## 获取连续闪避次数
func get_consecutive_dodges() -> int:
	"""获取当前连续闪避次数"""
	return _consecutive_dodges


## 激活暗夜之力
func _activate_night_power() -> void:
	"""激活暗夜之力"""
	_night_power_active = true
	_night_power_timer = passive_params.get("night_power_duration", 5.0)
	_consecutive_dodges = 0
	passive_triggered.emit(passive_name, {"night_power_start": true})


## 重置状态
func reset() -> void:
	super.reset()
	_consecutive_dodges = 0
	_dodge_cooldown = 0.0
	_shadow_step_charges = passive_params.get("shadow_step_max_charges", 2)
	_shadow_step_recharge_timer = 0.0
	_night_power_active = false
	_night_power_timer = 0.0
	_dodge_damage_accumulated = 0.0
