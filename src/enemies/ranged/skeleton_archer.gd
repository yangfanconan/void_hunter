## Void Hunter - 骷髅弓手敌人
## @description: 远程敌人，发射箭矢
## @version: 1.0.0

extends "res://src/enemies/enemy_base.gd"

const ARROW_SCENE = preload("res://src/projectiles/bullet_base.gd")

func _ready() -> void:
	enemy_type = EnemyType.RANGED
	move_speed = 60.0
	max_health = 30.0
	attack_damage = 12.0
	attack_range = 200.0  # 远程攻击范围
	attack_cooldown = 1.5
	detection_range = 300.0
	experience_reward = 30
	gold_reward = 18
	super._ready()

func _get_animation_id() -> String:
	return "skeleton_archer"

func _perform_attack() -> void:
	if target == null or not is_instance_valid(target):
		return

	# 发射箭矢
	var arrow := Area2D.new()
	arrow.collision_layer = 4
	arrow.collision_mask = 1

	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 5.0
	collision.shape = shape
	arrow.add_child(collision)

	var sprite := Sprite2D.new()
	var tex := ImageTexture.new()
	var img := Image.create(10, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.6, 0.4, 0.2))
	tex.set_image(img)
	sprite.texture = tex
	arrow.add_child(sprite)

	arrow.global_position = global_position
	var direction := (target.global_position - global_position).normalized()

	# 箭矢脚本
	arrow.set_script(_create_arrow_script(direction, attack_damage))

	get_tree().current_scene.add_child(arrow)

func _create_arrow_script(dir: Vector2, dmg: float) -> GDScript:
	var script := GDScript.new()
	script.source_code = """
extends Area2D
var direction: Vector2 = Vector2.RIGHT
var speed: float = 250.0
var damage: float = 10.0
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
	queue_free()
"""
	script.reload()
	script.set_meta("direction", dir)
	script.set_meta("damage", dmg)
	return script