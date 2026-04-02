## Void Hunter - 冰霜女巫
## @description: 攻击型角色，远程攻击为主，初始技能：冰霜新星

extends "res://src/characters/character_base.gd"
class_name FrostWitch

func _init() -> void:
	character_id = "frost_witch"
	character_name = "冰霜女巫"
	description = "来自北方的神秘女巫，精通冰霜魔法，可冻结一切敌人。"
	character_type = CharacterBase.CharacterType.BURST

	base_health = 80.0
	base_attack = 12.0
	base_defense = 3.0
	base_speed = 140.0
	base_mana = 80.0
	base_critical_chance = 0.08
	base_critical_damage = 1.8

	passive_name = "冰霜之心"
	passive_description = "攻击有20%概率冻结敌人1秒，冻结的敌人受到额外30%伤害。"
	passive_params = {
		"freeze_chance": 0.2,
		"freeze_duration": 1.0,
		"freeze_bonus_damage": 0.3
	}

	unlock_condition = CharacterBase.UnlockCondition.NONE
	unlock_value = 0
	is_default_unlocked = true
	is_hidden = false

func on_attack(attack_data: Dictionary) -> Dictionary:
	var result := super.on_attack(attack_data)
	if randf() < passive_params.freeze_chance:
		if "target" in result and is_instance_valid(result.target):
			result.target.take_damage(result.damage * passive_params.freeze_bonus_damage, self)
			# TODO: 应用冻结状态效果
	return result
