## Void Hunter - 铁骑士敌人
## @description: 坦克敌人，高防御和反击能力
## @version: 1.0.0

extends "res://src/enemies/enemy_base.gd"

var _can_counter: bool = true

func _ready() -> void:
	enemy_type = EnemyType.TANK
	move_speed = 50.0
	max_health = 120.0
	attack_damage = 30.0
	attack_range = 50.0
	attack_cooldown = 2.5
	experience_reward = 70
	gold_reward = 40
	super._ready()

func _get_animation_id() -> String:
	return "iron_knight"

func take_damage(amount: float, source: Node = null) -> void:
	super.take_damage(amount, source)

	# 受伤时有几率反击
	if _can_counter and randf() < 0.25 and source and is_instance_valid(source):
		_counter_attack(source)
		_can_counter = false
		await get_tree().create_timer(1.0).timeout
		_can_counter = true

func _counter_attack(target: Node) -> void:
	if target and is_instance_valid(target) and target.has_method("take_damage"):
		target.take_damage(attack_damage * 0.5, self)