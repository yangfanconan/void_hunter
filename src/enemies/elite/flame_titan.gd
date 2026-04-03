## Void Hunter - 火焰泰坦精英
## @description: 精英敌人，火焰范围攻击
## @version: 1.0.0

extends "res://src/enemies/enemy_base.gd"

func _ready() -> void:
	enemy_type = EnemyType.ELITE
	move_speed = 60.0
	max_health = 200.0
	attack_damage = 40.0
	attack_range = 60.0
	attack_cooldown = 2.0
	experience_reward = 150
	gold_reward = 80
	super._ready()

func _get_animation_id() -> String:
	return "fire_imp"  # 使用火焰敌人精灵

func _perform_attack() -> void:
	if target == null or not is_instance_valid(target):
		return

	# 火焰范围攻击
	var enemies := get_tree().get_nodes_in_group("players")
	for p in enemies:
		if is_instance_valid(p) and p.global_position.distance_to(global_position) <= 100.0:
			if p.has_method("take_damage"):
				p.take_damage(attack_damage, self)
			# 灼烧效果
			if p.has_method("apply_burn"):
				p.apply_burn(5.0, 3.0, self)

	# 火焰视觉效果
	_spawn_fire_aoe()

func _spawn_fire_aoe() -> void:
	var visual := Node2D.new()
	visual.global_position = global_position

	var sprite := Sprite2D.new()
	var tex := ImageTexture.new()
	var img := Image.create(200, 200, false, Image.FORMAT_RGBA8)
	img.fill(Color(1.0, 0.4, 0.1, 0.5))
	tex.set_image(img)
	sprite.texture = tex
	sprite.offset = Vector2(-100, -100)
	visual.add_child(sprite)

	get_tree().current_scene.add_child(visual)

	var tween := visual.create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
	tween.tween_callback(visual.queue_free)