## Void Hunter - 骷髅战士敌人
## @description: 中等近战敌人，攻击力较高
## @version: 1.0.0

extends "res://src/enemies/enemy_base.gd"

func _ready() -> void:
	enemy_type = EnemyType.MELEE
	move_speed = 85.0
	max_health = 40.0
	attack_damage = 15.0
	attack_range = 35.0
	attack_cooldown = 1.2
	experience_reward = 25
	gold_reward = 15
	super._ready()

func _get_animation_id() -> String:
	return "skeleton"

func _perform_attack() -> void:
	# 骷髅战士攻击有几率触发连击
	super._perform_attack()
	if randf() < 0.3:
		await get_tree().create_timer(0.3).timeout
		if target and is_instance_valid(target) and target.has_method("take_damage"):
			target.take_damage(attack_damage * 0.5, self)