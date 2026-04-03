## Void Hunter - 森林史莱姆敌人
## @description: 基础近战敌人，森林主题
## @version: 1.0.0

extends "res://src/enemies/enemy_base.gd"

func _ready() -> void:
	enemy_type = EnemyType.MELEE
	move_speed = 70.0
	max_health = 25.0
	attack_damage = 8.0
	attack_range = 30.0
	experience_reward = 15
	gold_reward = 8
	super._ready()

func _get_animation_id() -> String:
	return "forest_slime"