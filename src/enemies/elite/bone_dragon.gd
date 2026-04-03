## Void Hunter - 骨龙精英
## @description: 精英敌人，飞行和骨火攻击
## @version: 1.0.0

extends "res://src/enemies/enemy_base.gd"

func _ready() -> void:
	enemy_type = EnemyType.ELITE
	move_speed = 100.0
	max_health = 160.0
	attack_damage = 32.0
	attack_range = 120.0
	attack_cooldown = 1.5
	experience_reward = 160
	gold_reward = 85
	super._ready()

func _get_animation_id() -> String:
	return "bone_dragon"

func _perform_attack() -> void:
	if target == null or not is_instance_valid(target):
		return

	# 骨火喷射（多方向）
	for i in range(5):
		var angle := (target.global_position - global_position).angle() + (i - 2) * 0.2
		_spawn_bone_fire(angle)

func _spawn_bone_fire(angle: float) -> void:
	var bullet := Area2D.new()
	bullet.collision_layer = 4
	bullet.collision_mask = 1

	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 8.0
	collision.shape = shape
	bullet.add_child(collision)

	var sprite := Sprite2D.new()
	var tex := ImageTexture.new()
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.8, 0.8, 0.9))  # 苍白骨火
	tex.set_image(img)
	sprite.texture = tex
	bullet.add_child(sprite)

	bullet.global_position = global_position
	bullet.set_script(_create_bone_fire_script(Vector2(cos(angle), sin(angle)), attack_damage * 0.6))
	get_tree().current_scene.add_child(bullet)

func _create_bone_fire_script(dir: Vector2, dmg: float) -> GDScript:
	var script := GDScript.new()
	script.source_code = """
extends Area2D
var direction: Vector2 = Vector2.RIGHT
var speed: float = 280.0
var damage: float = 15.0
var lifetime: float = 2.0

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
	queue_free()
"""
	script.reload()
	script.set_meta("direction", dir)
	script.set_meta("damage", dmg)
	return script