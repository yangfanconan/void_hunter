## Void Hunter - 哥布林敌人
## @description: 快速近战敌人，移动速度高
## @version: 1.0.0

extends "res://src/enemies/enemy_base.gd"

func _ready() -> void:
	enemy_type = EnemyType.MELEE
	move_speed = 120.0  # 快速移动
	max_health = 20.0  # 生命值较低
	attack_damage = 10.0
	attack_range = 25.0
	attack_cooldown = 0.8  # 攻击频繁
	experience_reward = 18
	gold_reward = 12
	super._ready()

func _get_animation_id() -> String:
	return "goblin"