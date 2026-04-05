## Void Hunter - 虚空收割者
## @description: 默认均衡型角色，死亡时有概率复活
## @author: Void Hunter Team
## @version: 2.0.0

extends "res://src/characters/character_base.gd"
class_name VoidReaper

# =============================================================================
# 私有变量
# =============================================================================

var _has_revived: bool = false
var _void_shield_active: bool = false
var _void_shield_value: float = 0.0

# =============================================================================
# 初始化
# =============================================================================

func _init() -> void:
	# 基础信息
	character_id = "void_reaper"
	character_name = "虚空收割者"
	description = "在虚空中游走的灵魂猎手，均衡的全能战士。拥有虚空的庇护，死亡时有概率复活。"
	character_type = CharacterBase.CharacterType.BALANCED
	icon = load("res://assets/icons/characters/void_reaper.png")
	portrait = load("res://assets/icons/characters/void_reaper.png")

	# 基础属性 - 均衡型，无短板
	base_health = 100.0
	base_attack = 10.0
	base_defense = 5.0
	base_speed = 150.0
	base_mana = 50.0
	base_critical_chance = 0.05
	base_critical_damage = 1.5

	# 被动技能
	passive_name = "虚空庇护"
	passive_description = "死亡时有20%概率触发虚空复活，恢复40%生命值。每次游戏仅可触发一次。"
	passive_params = {
		"revive_chance": 0.2,
		"revive_health_percent": 0.4,
		"death_shield_value": 20.0,
		"death_shield_duration": 3.0
	}

	# 解锁条件 - 默认解锁
	unlock_condition = CharacterBase.UnlockCondition.NONE
	unlock_value = 0
	is_default_unlocked = true
	is_hidden = false

# =============================================================================
# 重写被动技能方法
# =============================================================================

## 死亡时触发复活判定
func on_death() -> Dictionary:
	var effects: Dictionary = super.on_death()

	if not _has_revived:
		var revive_chance: float = passive_params.get("revive_chance", 0.2)
		if randf() < revive_chance:
			effects["revive"] = true
			effects["revive_health_percent"] = passive_params.get("revive_health_percent", 0.4)
			_has_revived = true
			# 复活后给予短暂虚空护盾
			_void_shield_active = true
			_void_shield_value = passive_params.get("death_shield_value", 20.0)
			effects["temporary_shield"] = _void_shield_value
			effects["shield_duration"] = passive_params.get("death_shield_duration", 3.0)
			passive_triggered.emit(passive_name, {"revived": true, "shield": _void_shield_value})

	return effects


## 每帧更新虚空护盾
func on_process(delta: float, player_stats: Dictionary) -> Dictionary:
	var effects: Dictionary = super.on_process(delta, player_stats)

	if _void_shield_active:
		effects["void_shield"] = _void_shield_value
		effects["void_shield_active"] = true

	return effects


## 受伤时优先消耗虚空护盾
func on_damage_taken(damage_data: Dictionary) -> Dictionary:
	var result: Dictionary = super.on_damage_taken(damage_data)

	if _void_shield_active and _void_shield_value > 0:
		var damage: float = result.get("damage", 0)
		if damage <= _void_shield_value:
			_void_shield_value -= damage
			result["damage"] = 0
			result["shield_absorbed"] = damage
		else:
			var absorbed: float = _void_shield_value
			result["damage"] = damage - absorbed
			result["shield_absorbed"] = absorbed
			_void_shield_value = 0
			_void_shield_active = false

	return result


## 获取修改后的属性 - 均衡型无额外修正
func get_modified_stats(base_stats: Dictionary) -> Dictionary:
	return super.get_modified_stats(base_stats)


## 检查是否可以复活
func can_revive() -> bool:
	"""检查是否还有复活机会"""
	return not _has_revived


## 检查是否已经复活过
func has_used_revive() -> bool:
	"""检查是否已经使用过复活"""
	return _has_revived


## 消除虚空护盾
func remove_void_shield() -> void:
	"""移除虚空护盾"""
	_void_shield_active = false
	_void_shield_value = 0.0


## 获取当前虚空护盾值
func get_void_shield_value() -> float:
	"""获取当前虚空护盾剩余值"""
	return _void_shield_value


## 重置状态
func reset() -> void:
	super.reset()
	_has_revived = false
	_void_shield_active = false
	_void_shield_value = 0.0
