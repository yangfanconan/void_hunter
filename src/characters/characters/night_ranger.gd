## Void Hunter - 暗夜游侠
## @description: 敍捷型角色，极速高闪避
初始技能：暗影步

extends "res://src/characters/character_base.gd"
class_name NightRanger

func _init() -> void:
	character_id = "night_ranger"
	character_name = "暗夜游侠"
	description = "行走在黑暗边缘的刺客，以极速和闪避著称。每次闪避成功时反击。"
	character_type = CharacterBase.CharacterType.HIGH_DPS

	base_health = 70.0
	base_attack = 10.0
	base_defense = 3.0
	base_speed = 200.0
	base_mana = 50.0
	base_critical_chance = 0.15
	base_critical_damage = 2.0

	passive_name = "暗影闪避"
	passive_description = "闪避率+15%。每次成功闪避时自动反击，造成攻击力150%的伤害。"
	passive_params = {
		"dodge_chance": 0.15,
		"counter_damage_mult": 1.5,
		"counter_range": 60.0
	}

	unlock_condition = CharacterBase.UnlockCondition.KILL_ENEMIES
	unlock_value = 100
	is_default_unlocked = false
	is_hidden = false

func on_dodge_check() -> bool:
	if randf() < passive_params.dodge_chance:
		# 闪避成功，反击周围敌人
		var enemies := get_tree().get_nodes_in_group("enemies")
		for enemy in enemies:
		if is_instance_valid(enemy) and global_position.distance_to(enemy.global_position) <= passive_params.counter_range:
		enemy.take_damage(base_attack * passive_params.counter_damage_mult, self)
		return true
	return false
