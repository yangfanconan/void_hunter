## Void Hunter - 火焰小鬼敌人
## @description: 远程敌人，发射火球
## @version: 1.0.0

extends "res://src/enemies/enemy_base.gd"

func _ready() -> void:
	enemy_type = EnemyType.RANGED
	move_speed = 70.0
	max_health = 28.0
	attack_damage = 14.0
	attack_range = 180.0
	attack_cooldown = 1.3
	detection_range = 280.0
	experience_reward = 35
	gold_reward = 20
	super._ready()

func _get_animation_id() -> String:
	return "fire_imp"

func _perform_attack() -> void:
	if target == null or not is_instance_valid(target):
		return

	# 发射火球
	var bullet := Area2D.new()
	bullet.collision_layer = 4
	bullet.collision_mask = 1

	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 10.0
	collision.shape = shape
	bullet.add_child(collision)

	var sprite := Sprite2D.new()
	var tex := ImageTexture.new()
	var img := Image.create(20, 20, false, Image.FORMAT_RGBA8)
	img.fill(Color(1.0, 0.4, 0.1))  # 橙色火焰
	tex.set_image(img)
	sprite.texture = tex
	bullet.add_child(sprite)

	bullet.global_position = global_position
	var direction := (target.global_position - global_position).normalized()
	bullet.set_script(_create_fireball_script(direction, attack_damage))
	get_tree().current_scene.add_child(bullet)

func _create_fireball_script(dir: Vector2, dmg: float) -> GDScript:
	var script := GDScript.new()
	script.source_code = """
extends Area2D
var direction: Vector2 = Vector2.RIGHT
var speed: float = 220.0
var damage: float = 14.0
var lifetime: float = 3.0

func _ready():
	direction = _get_dir()
	body_entered.connect(_on_hit)

func _get_dir():
	var s = get_script()
	if s and s.has_meta('direction'):
		return s.get_meta('direction')
	return Vector2.RIGHT

func _physics_process(delta):
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
	position += direction * speed * delta

func _on_hit(body):
	if body.has_method('take_damage'):
		body.take_damage(damage, null)
		# 灼烧效果
		if body.has_method('apply_burn'):
			body.apply_burn(damage * 0.1, 2.0, null)
	queue_free()
"""
	script.reload()
	script.set_meta("direction", dir)
	script.set_meta("damage", dmg)
	return script