## Void Hunter - 圣光骑士
## @description: 防御型角色，拥有护盾被动技能
## @author: Void Hunter Team
## @version: 1.0.0

extends "res://src/characters/character_base.gd"
class_name HolyKnight

# =============================================================================
# 私有变量
# =============================================================================

var _current_shield_value: float = 0.0

# =============================================================================
# 初始化
# =============================================================================

func _init() -> void:
	# 基础信息
	character_id = "holy_knight"
	character_name = "圣光骑士"
	description = "圣光教团的守护骑士，身披神圣铠甲，誓死保护同伴。"
	character_type = CharacterBase.CharacterType.DEFENSIVE
	icon = load("res://assets/icons/characters/holy_knight.png")
	portrait = load("res://assets/icons/characters/holy_knight.png")

	# 基础属性 - 高生命、高防御、低速度
	base_health = 150.0
	base_attack = 8.0
	base_defense = 12.0
	base_speed = 120.0
	base_mana = 60.0
	base_critical_chance = 0.03
	base_critical_damage = 1.3

	# 被动技能
	passive_name = "圣盾"
	passive_description = "每30秒获得一个圣光护盾，可吸收30点伤害。护盾被击破后进入冷却。"
	passive_params = {
		"shield_value": 30.0,	# 护盾值
		"cooldown": 30.0,		# 冷却时间（秒）
		"visual_effect": true	# 是否显示视觉效果
	}

	# 解锁条件 - 生存30分钟不死
	unlock_condition = CharacterBase.UnlockCondition.SURVIVE_TIME
	unlock_value = 1800  # 30分钟 = 1800秒
	is_default_unlocked = false
	is_hidden = false

# =============================================================================
# 重写被动技能方法
# =============================================================================

## 每帧更新护盾状态
func on_process(delta: float, player_stats: Dictionary) -> Dictionary:
	var effects: Dictionary = super.on_process(delta, player_stats)

	# 护盾逻辑在基类中处理
	# 添加当前护盾状态
	effects["current_shield"] = _current_shield_value
	effects["shield_active"] = _has_temporary_shield

	return effects


## 受伤时优先消耗护盾
func on_damage_taken(damage_data: Dictionary) -> Dictionary:
	var result: Dictionary = super.on_damage_taken(damage_data)

	if _has_temporary_shield and _current_shield_value > 0:
		var damage: float = result.get("damage", 0)

		if damage <= _current_shield_value:
			# 护盾完全吸收伤害
			_current_shield_value -= damage
			result["damage"] = 0
			result["shield_absorbed"] = damage
			passive_triggered.emit(passive_name, {"shield_absorbed": damage})
		else:
			# 护盾被击破
			var absorbed: float = _current_shield_value
			result["damage"] = damage - absorbed
			result["shield_absorbed"] = absorbed
			_current_shield_value = 0
			_has_temporary_shield = false
			passive_triggered.emit(passive_name, {"shield_broken": true})

	return result


## 激活护盾
func activate_shield() -> void:
	"""手动激活护盾（用于特殊技能）"""
	var shield_value: float = passive_params.get("shield_value", 30.0)
	_current_shield_value = shield_value
	_has_temporary_shield = true
	passive_triggered.emit(passive_name, {"shield_activated": shield_value})


## 获取当前护盾值
func get_current_shield() -> float:
	"""获取当前护盾剩余值"""
	return _current_shield_value


## 获取护盾冷却进度
func get_shield_cooldown_progress() -> float:
	"""
	获取护盾冷却进度（0-1）
	@return: 冷却进度
	"""
	if _has_temporary_shield:
		return 1.0

	var cooldown: float = passive_params.get("cooldown", 30.0)
	return 1.0 - (_shield_cooldown / cooldown)


## 重置护盾状态
func reset() -> void:
	super.reset()
	_current_shield_value = 0.0
