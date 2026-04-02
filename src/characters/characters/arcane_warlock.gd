## Void Hunter - 灵术士
## @description: 法术型角色，高法力高技能伤害
初始技能：奥术弹

extends "res://src/characters/character_base.gd"
class_name ArcaneWarlock

func _init() -> void:
	character_id = "arcane_warlock"
	character_name = "灵术士"
	description = "掌握奥术奥秘的术士，以强大的魔法摧毁敌人。法力恢复快，技能伤害极高。"
	character_type = CharacterBase.CharacterType.MAGIC

	base_health = 60.0
	base_attack = 6.0
	base_defense = 2.0
	base_speed = 130.0
	base_mana = 100.0
	base_critical_chance = 0.1
	base_critical_damage = 1.5

	passive_name = "法力涌泉"
	passive_description = "法力恢复速度+50%。技能伤害+20%。使用技能时法力消耗-20%。"
	passive_params = {
		"mana_regen_bonus": 0.5,
		"skill_damage_bonus": 0.2,
		"mana_cost_reduction": 0.2
	}

	unlock_condition = CharacterBase.UnlockCondition.SURVIVE_TIME
	unlock_value = 10
	is_default_unlocked = false
	is_hidden = false

func get_mana_regen_rate() -> float:
	return base_mana * 0.02 * (1.0 + passive_params.mana_regen_bonus)
