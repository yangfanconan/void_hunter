## Void Hunter - 虚空收割者
## @description: 隐藏角色
吸血+AOE组合

extends "res://src/characters/character_base.gd"
class_name VoidReaper

func _init() -> void:
	character_id = "void_reaper"
	character_name = "虚空收割者"
	description = "虚空中的神秘存在，每次击杀恢复生命，范围攻击吸血。高攻击但低防御。"
	character_type = CharacterBase.CharacterType.BURST

	base_health = 65.0
	base_attack = 15.0
	base_defense = 2.0
	base_speed = 170.0
	base_mana = 50.0
	base_critical_chance = 0.2
	base_critical_damage = 2.2

	passive_name = "虚空吞噬"
	passive_description = "击杀敌人时恢复10%最大生命值。周围有敌人死亡时自动吸取灵魂，获得+5%攻击力(可叠加)。"
	passive_params = {
		"kill_heal_percent": 0.1,
		"soul_damage_bonus": 0.05,
		"soul_range": 150.0,
		"max_soul_stacks": 20
	}

	unlock_condition = CharacterBase.UnlockCondition.REACH_VOID_LEVEL
	unlock_value = 0
	is_default_unlocked = false
	is_hidden = true

var _soul_stacks: int = 0

func on_enemy_killed(enemy: Node) -> void:
	# 击杀回血
	heal(max_health * passive_params.kill_heal_percent)
	# 吸取灵魂
	if _soul_stacks < passive_params.max_soul_stacks:
		_soul_stacks += 1
		attack_bonus_percent += passive_params.soul_damage_bonus
