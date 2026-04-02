## Void Hunter - 圣光骑士
## @description: 坦克型角色，高生命高防御，初始技能：神圣之光

extends "res://src/characters/character_base.gd"
class_name HolyPaladin

func _init() -> void:
	character_id = "holy_paladin"
	character_name = "圣光骑士"
	description = "虔诚的骑士，誓以圣光守护同伴。高生命、高防御，自带减伤。"
	character_type = CharacterBase.CharacterType.DEFENSIVE

	base_health = 130.0
	base_attack = 8.0
	base_defense = 12.0
	base_speed = 120.0
	base_mana = 40.0
	base_critical_chance = 0.03
	base_critical_damage = 1.5

	passive_name = "圣光庇护"
	passive_description = "生命高于50%时减伤20%，低于30%时攻击力+40%。"
	passive_params = {
		"defense_bonus": 0.2,
		"attack_bonus": 0.4,
		"threshold_high": 0.5,
		"threshold_low": 0.3
	}

	unlock_condition = CharacterBase.UnlockCondition.NONE
	unlock_value = 500
	is_default_unlocked = false
	is_hidden = false

func take_damage(amount: float, source: Node = null) -> void:
	var hp_percent := current_health / max_health
	var modified_amount := amount

	if hp_percent > passive_params.threshold_high:
		modified_amount *= (1.0 - passive_params.defense_bonus)
	elif hp_percent < passive_params.threshold_low:
		attack_bonus_percent += passive_params.attack_bonus * 0.1  # 篡每次判定

	super.take_damage(modified_amount, source)
