## Void Hunter - 狂战士
## @description: 爆发型角色，拥有狂暴被动技能
## @author: Void Hunter Team
## @version: 1.0.0

extends "res://src/characters/character_base.gd"
class_name Berserker

# =============================================================================
# 私有变量
# =============================================================================

var _is_berserk_mode: bool = false
var _berserk_timer: float = 0.0

# =============================================================================
# 初始化
# =============================================================================

func _init() -> void:
	# 基础信息
	character_id = "berserker"
	character_name = "狂战士"
	description = "来自北方荒原的狂战士，以战斗为荣耀，越是危险越能激发他的战斗本能。"
	character_type = CharacterBase.CharacterType.BURST

	# 基础属性 - 高生命、高攻击、零防御
	base_health = 120.0
	base_attack = 18.0
	base_defense = 0.0		# 无防御
	base_speed = 160.0
	base_mana = 30.0
	base_critical_chance = 0.12  # 高暴击率
	base_critical_damage = 2.2   # 高暴击伤害

	# 被动技能
	passive_name = "狂暴"
	passive_description = "当生命值低于30%时，进入狂暴状态，攻击力提升50%，攻击速度提升20%。"
	passive_params = {
		"health_threshold": 0.3,	# 触发血量阈值
		"attack_bonus": 0.5,		# 攻击力加成
		"attack_speed_bonus": 0.2,	# 攻击速度加成
		"life_steal": 0.05			# 狂暴时获得少量吸血
	}

	# 解锁条件 - 单局造成100000伤害
	unlock_condition = CharacterBase.UnlockCondition.DEAL_DAMAGE
	unlock_value = 100000
	is_default_unlocked = false
	is_hidden = false

# =============================================================================
# 重写被动技能方法
# =============================================================================

## 每帧更新狂暴状态
func on_process(delta: float, player_stats: Dictionary) -> Dictionary:
	var effects: Dictionary = super.on_process(delta, player_stats)

	var health_percent: float = player_stats.get("health_percent", 1.0)
	var threshold: float = passive_params.get("health_threshold", 0.3)

	# 检查是否进入/退出狂暴状态
	if health_percent <= threshold and not _is_berserk_mode:
		_enter_berserk_mode()
	elif health_percent > threshold and _is_berserk_mode:
		_exit_berserk_mode()

	if _is_berserk_mode:
		effects["berserk_mode"] = true
		effects["attack_multiplier"] = 1.0 + passive_params.get("attack_bonus", 0.5)
		effects["attack_speed_multiplier"] = 1.0 + passive_params.get("attack_speed_bonus", 0.2)
		effects["life_steal"] = passive_params.get("life_steal", 0.05)

	return effects


## 获取修改后的属性
func get_modified_stats(base_stats: Dictionary) -> Dictionary:
	var modified: Dictionary = super.get_modified_stats(base_stats)

	if _is_berserk_mode:
		# 狂暴状态下增加攻击力
		var attack_bonus: float = passive_params.get("attack_bonus", 0.5)
		modified["attack"] = modified.get("attack", 0) * (1.0 + attack_bonus)

		# 增加攻击速度
		var speed_bonus: float = passive_params.get("attack_speed_bonus", 0.2)
		modified["attack_speed_multiplier"] = 1.0 + speed_bonus

		# 添加吸血效果
		modified["life_steal"] = modified.get("life_steal", 0) + passive_params.get("life_steal", 0.05)

	return modified


## 进入狂暴模式
func _enter_berserk_mode() -> void:
	"""进入狂暴模式"""
	_is_berserk_mode = true
	passive_triggered.emit(passive_name, {"berserk_entered": true})


## 退出狂暴模式
func _exit_berserk_mode() -> void:
	"""退出狂暴模式"""
	_is_berserk_mode = false
	passive_triggered.emit(passive_name, {"berserk_exited": true})


## 检查是否处于狂暴状态
func is_berserk() -> bool:
	"""检查是否处于狂暴状态"""
	return _is_berserk_mode


## 获取狂暴攻击加成
func get_berserk_attack_bonus() -> float:
	"""获取当前狂暴攻击加成"""
	if _is_berserk_mode:
		return passive_params.get("attack_bonus", 0.5)
	return 0.0


## 重置狂暴状态
func reset() -> void:
	super.reset()
	_is_berserk_mode = false
	_berserk_timer = 0.0
