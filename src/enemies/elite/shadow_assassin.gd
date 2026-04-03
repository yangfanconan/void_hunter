## Void Hunter - 暗影刺客精英
## @description: 精英敌人，高速高伤害
## @version: 1.0.0

extends "res://src/enemies/enemy_base.gd"

var _is_stealthed: bool = false

func _ready() -> void:
	enemy_type = EnemyType.ELITE
	move_speed = 150.0  # 非常快
	max_health = 80.0
	attack_damage = 35.0
	attack_range = 40.0
	attack_cooldown = 0.8
	experience_reward = 100
	gold_reward = 60
	super._ready()

func _get_animation_id() -> String:
	return "shadow_crawler"

func _update_chase(_delta: float) -> void:
	super._update_chase(_delta)

	# 追击时有几率进入隐身
	if not _is_stealthed and randf() < 0.01:
		_enter_stealth()

func _enter_stealth() -> void:
	_is_stealthed = true
	modulate.a = 0.3

	await get_tree().create_timer(2.0).timeout

	_is_stealthed = false
	modulate.a = 1.0

func _perform_attack() -> void:
	var damage_mult := 1.5 if _is_stealthed else 1.0

	if target and is_instance_valid(target) and target.has_method("take_damage"):
		target.take_damage(attack_damage * damage_mult, self)

	# 隐身攻击后显形
	if _is_stealthed:
		_is_stealthed = false
		modulate.a = 1.0