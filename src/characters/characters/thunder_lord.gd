## Void Hunter - 雷霆之主
## @description: 爆发型角色，连锁闪电攻击多个敌人
## @author: Void Hunter Team
## @version: 2.0.0

extends "res://src/characters/character_base.gd"
class_name ThunderLord

# =============================================================================
# 私有变量
# =============================================================================

## 雷电充能层数（连续触发闪电叠加）
var _lightning_charges: int = 0

## 雷暴模式激活状态
var _storm_mode_active: bool = false

## 雷暴模式剩余时间
var _storm_mode_timer: float = 0.0

## 雷暴模式充能（击杀敌人积累）
var _storm_charge: float = 0.0

## 雷霆印记目标（额外伤害的目标）
var _thunder_marks: Dictionary = {}

## 上次闪电触发时间
var _last_lightning_time: float = 0.0

# =============================================================================
# 初始化
# =============================================================================

func _init() -> void:
	character_id = "thunder_lord"
	character_name = "雷霆之主"
	description = "掌控雷电之力的战神，攻击可连锁击中多个敌人。闪电伤害+30%。连续触发闪电可进入雷暴模式。"
	character_type = CharacterBase.CharacterType.BURST

	# 基础属性 - 高攻击高速度
	base_health = 90.0
	base_attack = 11.0
	base_defense = 5.0
	base_speed = 160.0
	base_mana = 60.0
	base_critical_chance = 0.12
	base_critical_damage = 1.8

	# 被动技能
	passive_name = "连锁闪电"
	passive_description = "攻击命中时30%概率触发闪电链，最多弹射3个附近敌人，每个造成60%伤害。连续触发闪电可积累雷电充能，满5层进入雷暴模式。"
	passive_params = {
		"chain_chance": 0.3,
		"chain_count": 3,
		"chain_damage_mult": 0.6,
		"chain_range": 150.0,
		"lightning_damage_bonus": 0.3,
		"storm_charges_required": 5,
		"storm_duration": 6.0,
		"storm_chain_chance_bonus": 0.3,
		"storm_damage_bonus": 0.5,
		"mark_duration": 5.0,
		"mark_damage_bonus": 0.15
	}

	# 解锁条件 - 击败3个精英敌人
	unlock_condition = CharacterBase.UnlockCondition.KILL_ELITES
	unlock_value = 3
	is_default_unlocked = false
	is_hidden = false

# =============================================================================
# 重写被动技能方法
# =============================================================================

## 攻击时触发连锁闪电
func on_attack(attack_data: Dictionary) -> Dictionary:
	var result: Dictionary = super.on_attack(attack_data)

	# 雷霆印记额外伤害
	var target_id: String = str(attack_data.get("target_id", ""))
	if _thunder_marks.has(target_id):
		var mark_bonus: float = passive_params.get("mark_damage_bonus", 0.15)
		result["damage_multiplier"] = result.get("damage_multiplier", 1.0) * (1.0 + mark_bonus)
		result["thunder_mark_consumed"] = true

	# 基础闪电伤害加成
	var lightning_bonus: float = passive_params.get("lightning_damage_bonus", 0.3)
	result["lightning_damage_bonus"] = lightning_bonus

	# 触发连锁闪电
	var chain_chance: float = passive_params.get("chain_chance", 0.3)

	# 雷暴模式增加触发概率
	if _storm_mode_active:
		chain_chance += passive_params.get("storm_chain_chance_bonus", 0.3)

	if randf() < chain_chance:
		result["chain_lightning"] = true
		result["chain_count"] = passive_params.get("chain_count", 3)
		result["chain_damage_mult"] = passive_params.get("chain_damage_mult", 0.6)
		result["chain_range"] = passive_params.get("chain_range", 150.0)

		# 雷暴模式额外连锁伤害
		if _storm_mode_active:
			var storm_bonus: float = passive_params.get("storm_damage_bonus", 0.5)
			result["chain_damage_mult"] *= (1.0 + storm_bonus)

		# 积累雷电充能
		_lightning_charges += 1
		_last_lightning_time = Time.get_ticks_msec() / 1000.0

		# 检查雷暴模式触发
		if _lightning_charges >= passive_params.get("storm_charges_required", 5) and not _storm_mode_active:
			_activate_storm_mode()

		# 给目标施加雷霆印记
		if target_id != "":
			_thunder_marks[target_id] = passive_params.get("mark_duration", 5.0)

		passive_triggered.emit(passive_name, {
			"chain_triggered": true,
			"charges": _lightning_charges,
			"storm_active": _storm_mode_active
		})

	return result


## 每帧更新 - 雷暴模式和印记计时
func on_process(delta: float, player_stats: Dictionary) -> Dictionary:
	var effects: Dictionary = super.on_process(delta, player_stats)

	# 雷暴模式计时
	if _storm_mode_active:
		_storm_mode_timer -= delta
		if _storm_mode_timer <= 0:
			_storm_mode_active = false
			_lightning_charges = 0
			passive_triggered.emit(passive_name, {"storm_end": true})
		else:
			effects["storm_mode_active"] = true
			effects["storm_damage_bonus"] = passive_params.get("storm_damage_bonus", 0.5)
			# 雷暴模式持续伤害周围敌人
			effects["storm_aura_damage"] = base_attack * 0.1  # 每秒10%攻击力的范围伤害
			effects["storm_aura_range"] = 120.0

	# 雷霆印记衰减
	var marks_to_remove: Array[String] = []
	for target_id in _thunder_marks:
		_thunder_marks[target_id] -= delta
		if _thunder_marks[target_id] <= 0:
			marks_to_remove.append(target_id)
	for mark_id in marks_to_remove:
		_thunder_marks.erase(mark_id)

	# 雷电充能超时衰减（3秒未触发闪电则每秒减少1层）
	if not _storm_mode_active and _lightning_charges > 0:
		var current_time: float = Time.get_ticks_msec() / 1000.0
		if current_time - _last_lightning_time > 3.0:
			_lightning_charges = max(0, _lightning_charges - 1)
			_last_lightning_time = current_time

	# 提供当前状态
	effects["lightning_charges"] = _lightning_charges
	effects["marked_targets"] = _thunder_marks.size()

	return effects


## 击杀时恢复雷电充能
func on_kill(kill_data: Dictionary) -> void:
	super.on_kill(kill_data)

	# 击杀增加雷暴充能
	_storm_charge += 1
	_lightning_charges = mini(_lightning_charges + 1, passive_params.get("storm_charges_required", 5))

	# 击杀时产生小型雷击
	passive_triggered.emit(passive_name, {
		"kill_lightning": true,
		"damage": base_attack * 0.5,
		"range": 80.0
	})


## 获取修改后的属性
func get_modified_stats(base_stats: Dictionary) -> Dictionary:
	var modified: Dictionary = super.get_modified_stats(base_stats)

	# 基础闪电伤害加成
	var lightning_bonus: float = passive_params.get("lightning_damage_bonus", 0.3)
	modified["attack"] = modified.get("attack", 0) * (1.0 + lightning_bonus)

	# 雷暴模式额外加成
	if _storm_mode_active:
		var storm_bonus: float = passive_params.get("storm_damage_bonus", 0.5)
		modified["attack"] = modified.get("attack", 0) * (1.0 + storm_bonus)
		modified["speed"] = modified.get("speed", 0) * 1.15  # 雷暴模式移速+15%

	return modified


## 获取闪电链目标（由外部调用）
func get_chain_targets(primary_target_pos: Vector2, chain_count: int, chain_range: float) -> Array:
	"""
	计算闪电链的目标列表（返回相对位置信息，不直接引用场景节点）
	@param primary_target_pos: 主目标位置
	@param chain_count: 弹射次数
	@param chain_range: 弹射范围
	@return: 目标数据列表（包含位置和伤害信息）
	"""
	var targets: Array = []
	# 注意：实际场景中的敌人查找由外部游戏逻辑实现
	# 这里只返回闪电链参数供外部使用
	return targets


## 激活雷暴模式
func _activate_storm_mode() -> void:
	"""激活雷暴模式"""
	_storm_mode_active = true
	_storm_mode_timer = passive_params.get("storm_duration", 6.0)
	_lightning_charges = 0
	_storm_charge = 0.0
	passive_triggered.emit(passive_name, {"storm_start": true})


## 检查雷暴模式是否激活
func is_storm_mode_active() -> bool:
	"""检查雷暴模式是否激活"""
	return _storm_mode_active


## 获取当前雷电充能层数
func get_lightning_charges() -> int:
	"""获取当前雷电充能层数"""
	return _lightning_charges


## 获取雷暴模式剩余时间
func get_storm_mode_timer() -> float:
	"""获取雷暴模式剩余时间"""
	return _storm_mode_timer


## 获取雷霆印记数量
func get_thunder_mark_count() -> int:
	"""获取当前标记的敌人数量"""
	return _thunder_marks.size()


## 重置状态
func reset() -> void:
	super.reset()
	_lightning_charges = 0
	_storm_mode_active = false
	_storm_mode_timer = 0.0
	_storm_charge = 0.0
	_thunder_marks.clear()
	_last_lightning_time = 0.0
