## Void Hunter - 奥术术士
## @description: 法术型角色，高法力高技能伤害
## 初始技能：奥术弹
## @author: Void Hunter Team
## @version: 2.0.0

extends "res://src/characters/character_base.gd"
class_name ArcaneWarlock

# =============================================================================
# 私有变量
# =============================================================================

## 奥术充能层数（连续使用技能叠加）
var _arcane_charges: int = 0

## 上次使用技能的时间戳
var _last_skill_time: float = 0.0

## 充能重置时间（秒）
var _charge_reset_time: float = 3.0

## 已使用的元素类型记录（用于元素联动）
var _elements_used: Array[String] = []

## 最大元素记录数
var _max_element_record: int = 5

# =============================================================================
# 初始化
# =============================================================================

func _init() -> void:
	character_id = "arcane_warlock"
	character_name = "奥术术士"
	description = "掌握奥术奥秘的术士，以强大的魔法摧毁敌人。法力恢复快，技能伤害极高。连续施法可获得奥术充能加成。"
	character_type = CharacterBase.CharacterType.MAGIC
	icon = load("res://assets/icons/characters/arcane_warlock.png")
	portrait = load("res://assets/icons/characters/arcane_warlock.png")

	# 基础属性 - 低生命低防御，高法力高暴击
	base_health = 60.0
	base_attack = 6.0
	base_defense = 2.0
	base_speed = 130.0
	base_mana = 100.0
	base_critical_chance = 0.1
	base_critical_damage = 1.5

	# 被动技能
	passive_name = "奥术涌泉"
	passive_description = "法力恢复速度+50%。技能伤害+20%。使用技能时法力消耗-20%。连续施法叠加奥术充能，每层+5%技能伤害，最多5层。"
	passive_params = {
		"mana_regen_bonus": 0.5,
		"skill_damage_bonus": 0.2,
		"mana_cost_reduction": 0.2,
		"charge_per_skill": 1,
		"max_charges": 5,
		"charge_damage_bonus": 0.05,
		"charge_reset_time": 3.0
	}

	# 解锁条件 - 生存10分钟不死
	unlock_condition = CharacterBase.UnlockCondition.SURVIVE_TIME
	unlock_value = 600
	is_default_unlocked = false
	is_hidden = false

# =============================================================================
# 重写被动技能方法
# =============================================================================

## 获取法力恢复加成
func get_mana_regen_bonus() -> float:
	"""获取法力恢复加成百分比"""
	return passive_params.get("mana_regen_bonus", 0.5)


## 获取技能效果加成（含奥术充能）
func get_skill_effect_multiplier() -> float:
	"""获取技能效果倍率，包含基础加成和奥术充能"""
	var base_bonus: float = passive_params.get("skill_damage_bonus", 0.2)
	var charge_bonus: float = _arcane_charges * passive_params.get("charge_damage_bonus", 0.05)
	return 1.0 + base_bonus + charge_bonus


## 获取法力消耗减少比例
func get_mana_cost_reduction() -> float:
	"""获取法力消耗减少百分比"""
	return passive_params.get("mana_cost_reduction", 0.2)


## 攻击时触发奥术效果
func on_attack(attack_data: Dictionary) -> Dictionary:
	var result: Dictionary = super.on_attack(attack_data)

	# 奥术充能增加普通攻击伤害
	if _arcane_charges > 0:
		var charge_bonus: float = _arcane_charges * 0.02  # 每层2%普攻加成
		result["damage_multiplier"] = result.get("damage_multiplier", 1.0) * (1.0 + charge_bonus)
		# 有概率发射小型奥术弹
		if randf() < 0.15:
			result["arcane_bolt"] = true
			result["arcane_bolt_damage"] = base_attack * 0.5 * get_skill_effect_multiplier()
			passive_triggered.emit(passive_name, {"arcane_bolt": true})

	return result


## 每帧更新 - 检查充能超时重置
func on_process(delta: float, player_stats: Dictionary) -> Dictionary:
	var effects: Dictionary = super.on_process(delta, player_stats)

	# 检查奥术充能超时
	if _arcane_charges > 0:
		var current_time: float = Time.get_ticks_msec() / 1000.0
		if current_time - _last_skill_time > passive_params.get("charge_reset_time", 3.0):
			_arcane_charges = 0
			passive_triggered.emit(passive_name, {"charges_reset": true})

	# 提供当前状态
	if _arcane_charges > 0:
		effects["arcane_charges"] = _arcane_charges
		effects["skill_damage_bonus"] = _arcane_charges * passive_params.get("charge_damage_bonus", 0.05)

	return effects


## 击杀时额外恢复法力
func on_kill(kill_data: Dictionary) -> void:
	super.on_kill(kill_data)

	# 奥术术士击杀敌人时恢复法力
	var mana_recover: float = base_mana * 0.03  # 恢复3%最大法力
	passive_triggered.emit(passive_name, {"mana_recover": mana_recover})


## 游戏开始时初始化
func on_game_start() -> Dictionary:
	var effects: Dictionary = super.on_game_start()
	_arcane_charges = 0
	_elements_used.clear()
	# 开局法力全满
	effects["mana_full"] = true
	return effects


## 获取修改后的属性
func get_modified_stats(base_stats: Dictionary) -> Dictionary:
	var modified: Dictionary = super.get_modified_stats(base_stats)

	# 法力恢复加成
	var base_mana_regen: float = modified.get("mana_regen", 2.0)
	modified["mana_regen"] = base_mana_regen * (1.0 + get_mana_regen_bonus())

	# 法力消耗减少
	modified["mana_cost_reduction"] = get_mana_cost_reduction()

	return modified


## 记录技能使用（由外部调用）
func on_skill_used(skill_element: String = "") -> void:
	"""使用技能时调用，增加奥术充能"""
	_arcane_charges = mini(
		_arcane_charges + passive_params.get("charge_per_skill", 1),
		passive_params.get("max_charges", 5)
	)
	_last_skill_time = Time.get_ticks_msec() / 1000.0

	# 记录元素类型
	if skill_element != "" and skill_element not in _elements_used:
		_elements_used.append(skill_element)
		if _elements_used.size() > _max_element_record:
			_elements_used.pop_front()

	passive_triggered.emit(passive_name, {
		"charges": _arcane_charges,
		"element": skill_element
	})


## 计算元素多样性加成
func get_element_diversity_bonus() -> float:
	"""根据使用过的不同元素数量计算加成"""
	var unique_count: int = 0
	var seen: Array[String] = []
	for element in _elements_used:
		if element not in seen:
			seen.append(element)
			unique_count += 1
	return (unique_count - 1) * 0.03  # 每种不同元素+3%，最多约12%


## 获取当前奥术充能层数
func get_arcane_charges() -> int:
	"""获取当前奥术充能层数"""
	return _arcane_charges


## 重置状态
func reset() -> void:
	super.reset()
	_arcane_charges = 0
	_last_skill_time = 0.0
	_elements_used.clear()
