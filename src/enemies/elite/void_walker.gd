## Void Hunter - 虚空行者精英
## @description: 精英敌人，传送和虚空攻击
## @version: 1.0.0

extends "res://src/enemies/enemy_base.gd"

var _teleport_cooldown: float = 5.0
var _teleport_timer: float = 0.0

func _ready() -> void:
	enemy_type = EnemyType.ELITE
	move_speed = 80.0
	max_health = 100.0
	attack_damage = 30.0
	attack_range = 50.0
	attack_cooldown = 1.5
	experience_reward = 120
	gold_reward = 65
	super._ready()

func _get_animation_id() -> String:
	return "shadow_crawler"

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	_teleport_timer -= delta
	if _teleport_timer <= 0 and current_state == State.CHASE:
		if randf() < 0.3:
			_try_teleport()
			_teleport_timer = _teleport_cooldown

func _try_teleport() -> void:
	if player == null or not is_instance_valid(player):
		return

	# 淡出
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await tween.finished

	# 传送到玩家背后
	var behind := (player.global_position - global_position).normalized() * -100.0
	global_position = player.global_position + behind

	# 淡入
	tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)

func _perform_attack() -> void:
	super._perform_attack()

	# 虚空伤害，无视部分防御
	if target and is_instance_valid(target) and target.has_method("take_damage"):
		var void_damage := attack_damage * 0.3  # 额外虚空伤害
		target.take_damage(void_damage, self)