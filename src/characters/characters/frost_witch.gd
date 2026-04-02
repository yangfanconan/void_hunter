## Void Hunter - 冰霜女巫
## @description: 控制型角色，远程攻击为主，擅长冻结和减速敌人
## 初始技能：冰霜新星
## @author: Void Hunter Team
## @version: 2.0.0

extends "res://src/characters/character_base.gd"
class_name FrostWitch

# =============================================================================
# 私有变量
# =============================================================================

## 冰冻层数（连续攻击同一目标叠加）
var _freeze_stacks: Dictionary = {}

## 寒冰屏障冷却
var _ice_barrier_cooldown: float = 0.0

## 寒冰屏障是否激活
var _ice_barrier_active: bool = false

## 寒冰屏障剩余值
var _ice_barrier_value: float = 0.0

## 连续冻结计数（用于强化冰冻效果）
var _consecutive_freezes: int = 0

# =============================================================================
# 初始化
# =============================================================================

func _init() -> void:
	character_id = "frost_witch"
	character_name = "冰霜女巫"
	description = "来自北方的神秘女巫，精通冰霜魔法，可冻结一切敌人。攻击有概率冻结敌人，冻结的敌人受到额外伤害。"
	character_type = CharacterBase.CharacterType.BURST

	# 基础属性 - 中等偏低血量，高法力
	base_health = 80.0
	base_attack = 12.0
	base_defense = 3.0
	base_speed = 140.0
	base_mana = 80.0
	base_critical_chance = 0.08
	base_critical_damage = 1.8

	# 被动技能
	passive_name = "冰霜之心"
	passive_description = "攻击有20%概率冻结敌人1秒，冻结的敌人受到额外30%伤害。连续冻结同一敌人可延长冰冻时间。生命低于30%时自动生成寒冰屏障。"
	passive_params = {
		"freeze_chance": 0.2,
		"freeze_duration": 1.0,
		"freeze_bonus_damage": 0.3,
		"freeze_stack_max": 3,
		"freeze_stack_duration_bonus": 0.5,
		"ice_barrier_threshold": 0.3,
		"ice_barrier_value": 25.0,
		"ice_barrier_cooldown": 45.0,
		"slow_aura_percent": 0.1,
		"slow_aura_range": 100.0
	}

	# 解锁条件 - 默认解锁
	unlock_condition = CharacterBase.UnlockCondition.NONE
	unlock_value = 0
	is_default_unlocked = true
	is_hidden = false

# =============================================================================
# 重写被动技能方法
# =============================================================================

## 攻击时触发冻结效果
func on_attack(attack_data: Dictionary) -> Dictionary:
	var result: Dictionary = super.on_attack(attack_data)

	var freeze_chance: float = passive_params.get("freeze_chance", 0.2)

	# 连续冻结加成：每次连续冻结提高5%概率
	var effective_chance: float = freeze_chance + _consecutive_freezes * 0.05
	effective_chance = minf(effective_chance, 0.5)  # 最高50%

	if randf() < effective_chance:
		# 触发冻结
		result["freeze"] = true
		result["freeze_duration"] = passive_params.get("freeze_duration", 1.0)
		result["freeze_bonus_damage"] = passive_params.get("freeze_bonus_damage", 0.3)

		# 对冻结目标额外伤害
		var bonus_damage: float = passive_params.get("freeze_bonus_damage", 0.3)
		result["damage_multiplier"] = result.get("damage_multiplier", 1.0) * (1.0 + bonus_damage)

		# 记录冻结层数
		var target_id: String = str(attack_data.get("target_id", ""))
		if target_id != "":
			if not _freeze_stacks.has(target_id):
				_freeze_stacks[target_id] = 0
			_freeze_stacks[target_id] = mini(
				_freeze_stacks[target_id] + 1,
				passive_params.get("freeze_stack_max", 3)
			)
			# 叠加冰冻时间延长
			var stacks: int = _freeze_stacks[target_id]
			result["freeze_duration"] += stacks * passive_params.get("freeze_stack_duration_bonus", 0.5)

		_consecutive_freezes += 1
		passive_triggered.emit(passive_name, {
			"frozen": true,
			"duration": result["freeze_duration"],
			"consecutive": _consecutive_freezes
		})
	else:
		# 未触发冻结，重置连续计数
		_consecutive_freezes = 0

	return result


## 每帧更新 - 寒冰屏障冷却和减速光环
func on_process(delta: float, player_stats: Dictionary) -> Dictionary:
	var effects: Dictionary = super.on_process(delta, player_stats)

	# 寒冰屏障冷却
	if _ice_barrier_cooldown > 0:
		_ice_barrier_cooldown -= delta

	# 低血量自动生成寒冰屏障
	var health_percent: float = player_stats.get("health_percent", 1.0)
	if health_percent <= passive_params.get("ice_barrier_threshold", 0.3) and not _ice_barrier_active and _ice_barrier_cooldown <= 0:
		_ice_barrier_active = true
		_ice_barrier_value = passive_params.get("ice_barrier_value", 25.0)
		_ice_barrier_cooldown = passive_params.get("ice_barrier_cooldown", 45.0)
		effects["ice_barrier"] = _ice_barrier_value
		passive_triggered.emit(passive_name, {"ice_barrier": _ice_barrier_value})

	# 提供寒冰屏障状态
	if _ice_barrier_active:
		effects["ice_barrier_active"] = true
		effects["ice_barrier_value"] = _ice_barrier_value

	# 减速光环（被动减速周围敌人）
	effects["enemy_slow_aura"] = true
	effects["slow_percent"] = passive_params.get("slow_aura_percent", 0.1)
	effects["slow_range"] = passive_params.get("slow_aura_range", 100.0)

	return effects


## 受伤时消耗寒冰屏障
func on_damage_taken(damage_data: Dictionary) -> Dictionary:
	var result: Dictionary = super.on_damage_taken(damage_data)

	if _ice_barrier_active and _ice_barrier_value > 0:
		var damage: float = result.get("damage", 0)
		if damage <= _ice_barrier_value:
			_ice_barrier_value -= damage
			result["damage"] = 0
			result["ice_barrier_absorbed"] = damage
		else:
			result["damage"] = damage - _ice_barrier_value
			result["ice_barrier_absorbed"] = _ice_barrier_value
			_ice_barrier_value = 0
			_ice_barrier_active = false

		# 被攻击时对攻击者施加减速效果
		result["attacker_slow"] = true
		result["attacker_slow_percent"] = 0.3  # 攻击者被减速30%
		result["attacker_slow_duration"] = 2.0

	return result


## 击杀时冰冻爆发（击杀冻结敌人时有范围冰冻效果）
func on_kill(kill_data: Dictionary) -> void:
	super.on_kill(kill_data)

	# 如果击杀的是冻结状态的敌人，触发冰冻爆发
	if kill_data.get("target_frozen", false):
		passive_triggered.emit(passive_name, {
			"frost_burst": true,
			"damage": base_attack * 0.8,
			"range": 100.0,
			"freeze_chance": 0.5
		})


## 获取修改后的属性
func get_modified_stats(base_stats: Dictionary) -> Dictionary:
	var modified: Dictionary = super.get_modified_stats(base_stats)

	# 冰霜之心：法力恢复小幅加成
	var base_mana_regen: float = modified.get("mana_regen", 2.0)
	modified["mana_regen"] = base_mana_regen * 1.2

	return modified


## 获取当前寒冰屏障值
func get_ice_barrier_value() -> float:
	"""获取当前寒冰屏障剩余值"""
	return _ice_barrier_value


## 检查寒冰屏障是否激活
func is_ice_barrier_active() -> bool:
	"""检查寒冰屏障是否激活"""
	return _ice_barrier_active


## 获取寒冰屏障冷却进度
func get_ice_barrier_cooldown_progress() -> float:
	"""获取寒冰屏障冷却进度（0-1）"""
	if _ice_barrier_active:
		return 1.0
	if _ice_barrier_cooldown <= 0:
		return 1.0
	return 1.0 - (_ice_barrier_cooldown / passive_params.get("ice_barrier_cooldown", 45.0))


## 获取冻结层数
func get_freeze_stacks(target_id: String) -> int:
	"""获取对指定目标的冻结层数"""
	return _freeze_stacks.get(target_id, 0)


## 清除目标的冻结层数
func clear_freeze_stacks(target_id: String) -> void:
	"""清除指定目标的冻结层数"""
	_freeze_stacks.erase(target_id)


## 重置状态
func reset() -> void:
	super.reset()
	_freeze_stacks.clear()
	_ice_barrier_cooldown = 0.0
	_ice_barrier_active = false
	_ice_barrier_value = 0.0
	_consecutive_freezes = 0
