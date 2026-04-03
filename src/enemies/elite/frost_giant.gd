## Void Hunter - 霜巨人精英
## @description: 精英敌人，冰冻和减速
## @version: 1.0.0

extends "res://src/enemies/enemy_base.gd"

func _ready() -> void:
	enemy_type = EnemyType.ELITE
	move_speed = 55.0
	max_health = 180.0
	attack_damage = 35.0
	attack_range = 70.0
	attack_cooldown = 2.5
	experience_reward = 140
	gold_reward = 75
	super._ready()

func _get_animation_id() -> String:
	return "ice_slime"

func _perform_attack() -> void:
	if target == null or not is_instance_valid(target):
		return

	super._perform_attack()

	# 冰冻效果
	if target.has_method("apply_freeze"):
		target.apply_freeze(1.5, self)
	elif target.has_method("apply_slow"):
		target.apply_slow(0.4, 3.0, self)

func _update_chase(_delta: float) -> void:
	super._update_chase(_delta)

	# 冰霜光环，减速附近玩家
	if player and is_instance_valid(player):
		if player.global_position.distance_to(global_position) <= 80.0:
			if player.has_method("apply_slow"):
				player.apply_slow(0.2, 0.5, self)