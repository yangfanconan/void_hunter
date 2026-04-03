## Void Hunter - 石头人敌人
## @description: 坦克敌人，高生命值和防御
## @version: 1.0.0

extends "res://src/enemies/enemy_base.gd"

func _ready() -> void:
	enemy_type = EnemyType.TANK
	move_speed = 40.0  # 移动缓慢
	max_health = 150.0  # 高生命值
	attack_damage = 25.0
	attack_range = 45.0
	attack_cooldown = 2.0
	experience_reward = 60
	gold_reward = 35
	super._ready()

func _get_animation_id() -> String:
	return "stone_golem"

func take_damage(amount: float, source: Node = null) -> void:
	# 石头人有30%伤害减免
	var reduced_damage := amount * 0.7
	super.take_damage(reduced_damage, source)