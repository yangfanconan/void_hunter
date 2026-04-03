## Void Hunter - 虚空实体Boss
## @description: 腐化深渊主题Boss，虚空力量的化身
## @version: 1.0.0

extends "res://src/enemies/boss/boss_base.gd"

# =============================================================================
# 配置
# =============================================================================

const BOSS_NAME := "虚空实体"

## 专属技能配置
const SKILLS := [
	{
		"id": "void_tear",
		"type": 3,  # BossSkillType.PROJECTILE
		"count": 12,
		"damage": 25.0,
		"speed": 300.0,
		"pattern": "circular",
		"cooldown": 5.0,
		"min_phase": 0
	},
	{
		"id": "gravity_well",
		"type": 1,  # BossSkillType.AOE
		"damage": 15.0,
		"radius": 150.0,
		"delay": 1.2,
		"duration": 3.0,
		"cooldown": 10.0,
		"min_phase": 0
	},
	{
		"id": "void_walk",
		"type": 0,  # BossSkillType.CHARGE (传送)
		"cooldown": 8.0,
		"min_phase": 1
	},
	{
		"id": "dark_pulse",
		"type": 5,  # BossSkillType.SHOCKWAVE
		"damage": 45.0,
		"max_radius": 350.0,
		"speed": 200.0,
		"cooldown": 12.0,
		"min_phase": 1
	},
	{
		"id": "reality_collapse",
		"type": 1,  # BossSkillType.AOE
		"damage": 100.0,
		"radius": 300.0,
		"delay": 4.0,
		"cooldown": 30.0,
		"min_phase": 2
	},
]

# =============================================================================
# 初始化
# =============================================================================

func _ready() -> void:
	boss_name = BOSS_NAME
	max_phases = 3
	super._ready()

func _setup_special_skills() -> void:
	_special_skills.clear()
	for skill in SKILLS:
		_special_skills.append(skill)

func _setup_boss_drops() -> void:
	boss_drops = [
		{"item_id": "weapon_void_blade", "chance": 0.3},
		{"item_id": "armor_void_cloak", "chance": 0.25},
		{"item_id": "special_chaos_orb", "chance": 0.2},
		{"item_id": "accessory_hourglass_of_time", "chance": 0.35},
	]

# =============================================================================
# 特殊技能实现
# =============================================================================

func _execute_charge(skill: Dictionary) -> void:
	# 虚空实体的"冲锋"实际上是传送
	if player == null or not is_instance_valid(player):
		return

	# 淡出
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished

	# 传送到玩家附近随机位置
	var angle: float = randf() * TAU
	var distance: float = randf_range(100.0, 200.0)
	global_position = player.global_position + Vector2(cos(angle), sin(angle)) * distance

	# 淡入
	tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	await tween.finished

	# 传送后释放虚空波动
	_execute_aoe({
		"damage": 30.0,
		"radius": 100.0,
		"delay": 0.3
	})

func _execute_aoe(skill: Dictionary) -> void:
	# 虚空风格的AOE
	var radius: float = skill.get("radius", 150.0)
	var damage: float = skill.get("damage", attack_damage)
	var delay: float = skill.get("delay", 1.0)

	# 紫色预警圈
	_show_warning_circle(global_position, radius, delay)
	_spawn_void_warning(global_position, radius, delay)

	await get_tree().create_timer(delay).timeout

	_deal_area_damage(global_position, radius, damage)
	_spawn_void_explosion(global_position, radius)

func _spawn_void_warning(center: Vector2, radius: float, duration: float) -> void:
	var ring := Line2D.new()
	for i in range(32):
		var angle: float = (TAU / 32) * i
		ring.add_point(center + Vector2(cos(angle), sin(angle)) * radius)
	ring.add_point(center + Vector2(cos(0), sin(0)) * radius)
	ring.default_color = Color(0.5, 0.2, 0.8, 0.7)
	ring.width = 3.0
	ring.z_index = 5
	get_tree().current_scene.add_child(ring)

	var tween := ring.create_tween()
	tween.tween_interval(duration)
	tween.tween_callback(ring.queue_free)

func _spawn_void_explosion(center: Vector2, radius: float) -> void:
	var visual := Node2D.new()
	visual.global_position = center

	var sprite := Sprite2D.new()
	var tex := ImageTexture.new()
	var img := Image.create(int(radius * 2), int(radius * 2), false, Image.FORMAT_RGBA8)
	img.fill(Color(0.5, 0.2, 0.8, 0.5))
	tex.set_image(img)
	sprite.texture = tex
	sprite.offset = Vector2(-radius, -radius)
	visual.add_child(sprite)

	get_tree().current_scene.add_child(visual)

	var tween := visual.create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
	tween.tween_callback(visual.queue_free)

# =============================================================================
# 阶段变化效果
# =============================================================================

func _modify_arena(phase: int) -> void:
	match phase:
		1:
			_create_void_rifts(3)
		2:
			_create_void_rifts(4)
			_darken_reality()

func _create_void_rifts(count: int) -> void:
	for i in range(count):
		var angle: float = (TAU / count) * i
		var distance: float = randf_range(150.0, 250.0)
		var pos: Vector2 = global_position + Vector2(cos(angle), sin(angle)) * distance

		var rift := Area2D.new()
		rift.global_position = pos
		rift.collision_layer = 0
		rift.collision_mask = 1

		var collision := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = 40.0
		collision.shape = shape
		rift.add_child(collision)

		var sprite := Sprite2D.new()
		var tex := ImageTexture.new()
		var img := Image.create(80, 80, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.3, 0.1, 0.5, 0.8))
		tex.set_image(img)
		sprite.texture = tex
		sprite.offset = Vector2(-40, -40)
		rift.add_child(sprite)

		rift.set_script(_create_void_rift_script())

		get_tree().current_scene.add_child(rift)
		_arena_hazards.append(rift)

func _create_void_rift_script() -> GDScript:
	var script := GDScript.new()
	script.source_code = """
extends Area2D
var damage: float = 15.0
var pull_force: float = 100.0
var damage_interval: float = 0.5
var _timer: float = 0.0

func _process(delta):
	_timer += delta
	if _timer >= damage_interval:
		_timer = 0.0
		for body in get_overlapping_bodies():
			if body.has_method("take_damage"):
				body.take_damage(damage, null)
			# 拉向中心
			if "velocity" in body:
				var pull_dir = (global_position - body.global_position).normalized()
				body.velocity += pull_dir * pull_force * delta
"""
	script.reload()
	return script

func _darken_reality() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0.1, 0.0, 0.2, 0.4)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = -1
	overlay.name = "VoidOverlay"
	get_tree().current_scene.add_child(overlay)
	_arena_hazards.append(overlay)