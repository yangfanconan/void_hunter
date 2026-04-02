## Void Hunter - 雷霆之主
## @description: 線电攻击型角色，连锁闪电

extends "res://src/characters/character_base.gd"
class_name ThunderLord

func _init() -> void:
	character_id = "thunder_lord"
	character_name = "雷霆之主"
	description = "掌控雷电之力的战神，攻击可连锁击中多个敌人。闪电伤害+30%。"
	character_type = CharacterBase.CharacterType.BURST

	base_health = 90.0
	base_attack = 11.0
	base_defense = 5.0
	base_speed = 160.0
	base_mana = 60.0
	base_critical_chance = 0.12
	base_critical_damage = 1.8

	passive_name = "连锁闪电"
	passive_description = "攻击命中时30%概率触发闪电链，最多弹射3个附近敌人，每个造成60%伤害。"
	passive_params = {
		"chain_chance": 0.3,
		"chain_count": 3,
		"chain_damage_mult": 0.6,
		"chain_range": 150.0
	}

	unlock_condition = CharacterBase.UnlockCondition.KILL_ELITES
	unlock_value = 3
	is_default_unlocked = false
	is_hidden = false

func on_attack(attack_data: Dictionary) -> Dictionary:
	var result := super.on_attack(attack_data)

	# 触发连锁闪电
	if randf() < passive_params.chain_chance:
		_chain_lightning(result)
	return result

func _chain_lightning(attack_result: Dictionary) -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var hit_enemies: Array[Node] = []
	var source_node: Node = attack_result.get("target", null)
	if source_node and is_instance_valid(source_node):
		hit_enemies.append(source_node)

	for chain in range(passive_params.chain_count):
		var closest: Node = null
		var closest_dist: float = passive_params.chain_range
		var last: Node = hit_enemies[-1]
		for enemy in enemies:
			if enemy in hit_enemies or not is_instance_valid(enemy):
				continue
			var dist := last.global_position.distance_to(enemy.global_position)
			if dist < closest_dist:
				closest = enemy
				closest_dist = dist
		if closest == null:
			break
		closest.take_damage(base_attack * passive_params.chain_damage_mult, self)
		hit_enemies.append(closest)
