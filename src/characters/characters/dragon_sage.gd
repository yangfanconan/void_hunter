## Void Hunter - 龙贤者
## @description: 平衡型角色，经验加成+全属性提升

extends "res://src/characters/character_base.gd"
class_name DragonSage

func _init() -> void:
	character_id = "dragon_sage"
	character_name = "龙贤者"
	description = "远古龙族的贤者，拥有均衡的全属性和强力的成长潜力。升级时全属性+8%。"
	character_type = CharacterBase.CharacterType.BALANCED

	base_health = 100.0
	base_attack = 10.0
	base_defense = 7.0
	base_speed = 150.0
	base_mana = 60.0
	base_critical_chance = 0.08
	base_critical_damage = 1.6

	passive_name = "龙族天赋"
	passive_description = "经验获取+30%。升级时全属性+8%。被击中时有10%概率释放龙息(小范围AOE)。"
	passive_params = {
		"exp_bonus": 0.3,
		"level_up_bonus": 0.08,
		"dragon_breath_chance": 0.1,
		"breath_damage": 25.0,
		"breath_range": 80.0
	}

	unlock_condition = CharacterBase.UnlockCondition.NONE
	unlock_value = 5000
	is_default_unlocked = false
	is_hidden = false

func _on_level_up() -> void:
	# 全属性提升
	max_health *= (1.0 + passive_params.level_up_bonus)
	base_attack *= (1.0 + passive_params.level_up_bonus)
	base_defense *= (1.0 + passive_params.level_up_bonus)
	current_health = max_health
