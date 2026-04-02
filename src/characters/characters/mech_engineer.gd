## Void Hunter - 机械工程师
## @description: 召唤型角色
可部署炮台和召唤物

extends "res://src/characters/character_base.gd"
class_name MechEngineer

func _init() -> void:
	character_id = "mech_engineer"
	character_name = "机械工程师"
	description = "天才发明家，可部署炮台和召唤机械宠物辅助战斗。"
	character_type = CharacterBase.CharacterType.SUMMONER

	base_health = 75.0
	base_attack = 7.0
	base_defense = 4.0
	base_speed = 140.0
	base_mana = 70.0
	base_critical_chance = 0.05
	base_critical_damage = 1.5

	passive_name = "机械伙伴"
	passive_description = "开局自带2个炮台。每30秒可额外召唤一个机械蜘蛛。最多同时存在5个召唤物。"
	passive_params = {
		"turret_count": 2,
		"spider_cooldown": 30.0,
		"max_summons": 5,
		"turret_damage": 8.0,
		"spider_damage": 5.0
	}

	unlock_condition = CharacterBase.UnlockCondition.NONE
	unlock_value = 2000
	is_default_unlocked = false
	is_hidden = false
