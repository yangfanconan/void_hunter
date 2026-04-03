## Void Hunter - 机械守卫精英
## @description: 精英敌人，激光和护盾
## @version: 1.0.0

extends "res://src/enemies/enemy_base.gd"

var _shield_active: bool = false
var _shield_health: float = 50.0

func _ready() -> void:
	enemy_type = EnemyType.ELITE
	move_speed = 50.0
	max_health = 150.0
	attack_damage = 28.0
	attack_range = 150.0  # 远程攻击
	attack_cooldown = 1.8
	experience_reward = 130
	gold_reward = 70
	super._ready()

func _get_animation_id() -> String:
	return "clockwork_soldier"

func _perform_attack() -> void:
	if target == null or not is_instance_valid(target):
		return

	# 发射激光
	var laser := Line2D.new()
	laser.add_point(global_position)
	laser.add_point(target.global_position)
	laser.width = 5.0
	laser.default_color = Color(1.0, 0.3, 0.3, 0.8)
	laser.z_index = 10
	get_tree().current_scene.add_child(laser)

	# 伤害
	if target.has_method("take_damage"):
		target.take_damage(attack_damage, self)

	# 消失
	await get_tree().create_timer(0.2).timeout
	laser.queue_free()

func take_damage(amount: float, source: Node = null) -> void:
	# 有护盾时吸收伤害
	if _shield_active:
		_shield_health -= amount
		if _shield_health <= 0:
			_shield_active = false
			modulate = Color.WHITE
		return

	super.take_damage(amount, source)

	# 低血量时激活护盾
	if current_health <= max_health * 0.5 and not _shield_active:
		_activate_shield()

func _activate_shield() -> void:
	_shield_active = true
	_shield_health = 50.0
	modulate = Color(0.5, 0.8, 1.0)  # 蓝色表示护盾

	# 护盾视觉效果
	var shield := Sprite2D.new()
	var tex := ImageTexture.new()
	var img := Image.create(60, 60, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.3, 0.6, 1.0, 0.3))
	tex.set_image(img)
	shield.texture = tex
	shield.offset = Vector2(-30, -30)
	shield.name = "ShieldVisual"
	add_child(shield)