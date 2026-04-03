## Void Hunter - 黑暗法师敌人
## @description: 远程敌人，发射魔法弹
## @version: 1.0.0

extends "res://src/enemies/enemy_base.gd"

func _ready() -> void:
	enemy_type = EnemyType.RANGED
	move_speed = 50.0
	max_health = 35.0
	attack_damage = 18.0
	attack_range = 250.0
	attack_cooldown = 2.0
	detection_range = 350.0
	experience_reward = 40
	gold_reward = 25
	super._ready()

func _get_animation_id() -> String:
	return "dark_mage"

func _perform_attack() -> void:
	if target == null or not is_instance_valid(target):
		return

	# 发射3发魔法弹
	for i in range(3):
		var angle_offset := (i - 1) * 0.3  # 扇形散射
		var base_dir := (target.global_position - global_position).normalized()
		var angle := base_dir.angle() + angle_offset
		var dir := Vector2(cos(angle), sin(angle))

		_spawn_magic_bullet(dir)
		await get_tree().create_timer(0.1).timeout

func _spawn_magic_bullet(direction: Vector2) -> void:
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
	img.fill(Color(0.5, 0.2, 0.8))  # 紫色魔法弹
	tex.set_image(img)
	sprite.texture = tex
	bullet.add_child(sprite)

	bullet.global_position = global_position
	bullet.set_script(_create_bullet_script(direction, attack_damage))
	get_tree().current_scene.add_child(bullet)

func _create_bullet_script(dir: Vector2, dmg: float) -> GDScript:
	var script := GDScript.new()
	script.source_code = """
extends Area2D
var direction: Vector2 = Vector2.RIGHT
var speed: float = 180.0
var damage: float = 15.0
var lifetime: float = 4.0

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