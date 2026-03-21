## Void Hunter - 流浪剑客
## @description: 平衡型初始角色，拥有连击被动技能
## @author: Void Hunter Team
## @version: 1.0.0

extends "res://src/characters/character_base.gd"
class_name WanderingSwordsman

# =============================================================================
# 初始化
# =============================================================================

func _init() -> void:
	# 基础信息
	character_id = "wandering_swordsman"
	character_name = "流浪剑客"
	description = "一位经验丰富的流浪剑客，在不断的旅途中磨练出了精湛的剑术。"
	character_type = CharacterBase.CharacterType.BALANCED

	# 基础属性
	base_health = 100.0
	base_attack = 10.0
	base_defense = 5.0
	base_speed = 150.0
	base_mana = 50.0
	base_critical_chance = 0.05
	base_critical_damage = 1.5

	# 被动技能
	passive_name = "连击"
	passive_description = "连续攻击时伤害递增10%，最多叠加5层（50%额外伤害）。超过2秒未攻击则重置。"
	passive_params = {
		"damage_bonus": 0.1,	# 每层伤害加成
		"max_stacks": 5,		# 最大叠加层数
		"reset_time": 2.0		# 重置时间（秒）
	}

	# 解锁条件
	unlock_condition = CharacterBase.UnlockCondition.NONE
	unlock_value = 0
	is_default_unlocked = true
	is_hidden = false

# =============================================================================
# 重写被动技能方法
# =============================================================================

## 攻击时触发连击效果
func on_attack(attack_data: Dictionary) -> Dictionary:
	var result: Dictionary = super.on_attack(attack_data)

	# 连击逻辑在基类中处理
	# 这里可以添加额外的视觉效果或音效触发

	return result


## 获取连击层数
func get_combo_stacks() -> int:
	"""获取当前连击层数"""
	return mini(_consecutive_attacks, passive_params.get("max_stacks", 5))


## 获取当前连击伤害加成
func get_combo_damage_bonus() -> float:
	"""获取当前连击伤害加成百分比"""
	var stacks: int = get_combo_stacks()
	var bonus_per_stack: float = passive_params.get("damage_bonus", 0.1)
	return stacks * bonus_per_stack


## 重置连击
func reset_combo() -> void:
	"""手动重置连击层数"""
	_consecutive_attacks = 0
