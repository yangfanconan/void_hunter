## Void Hunter - 火焰大帝Boss
## @description: 熔岩洞穴主题Boss，掌控火焰力量
## @version: 1.0.0

extends "res://src/enemies/boss/boss_base.gd"

# =============================================================================
# 配置
# =============================================================================

const BOSS_NAME := "火焰大帝"

## 专属技能配置
const SKILLS := [
	{
		"id": "fire_breath",
		"type": 4,  # BossSkillType.BEAM
		"damage": 25.0,
		"duration": 2.5,
		"width": 40.0,
		"cooldown": 8.0,
		"min_phase": 0
	},
	{
		"id": "lava_pool",
		"type": 1,  # BossSkillType.AOE
		"damage": 20.0,
		"radius": 120.0,
		"delay": 0.8,
		"cooldown": 5.0,
		"min_phase": 0
	},
	{
		"id": "meteor_strike",
		"type": 3,  # BossSkillType.PROJECTILE
		"count": 5,
		"damage": 35.0,
		"speed": 200.0,
		"pattern": "targeted",
		"spread": 20.0,
		"cooldown": 10.0,
		"min_phase": 1
	},
	{
		"id": "flame_wave",
		"type": 5,  # BossSkillType.SHOCKWAVE
		"damage": 40.0,
		"max_radius": 350.0,
		"speed": 180.0,
		"cooldown": 12.0,
		"min_phase": 1
	},
	{
		"id": "inferno_nova",
		"type": 1,  # BossSkillType.AOE
		"damage": 60.0,
		"radius": 250.0,
		"delay": 2.0,
		"cooldown": 20.0,
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
		{"item_id": "weapon_dragon_breath", "chance": 0.4},
		{"item_id": "weapon_inferno_blade", "chance": 0.3},
		{"item_id": "armor_dragon_scale", "chance": 0.25},
		{"item_id": "consumable_berserk_potion", "chance": 0.6},
	]

# =============================================================================
# 阶段变化效果
# =============================================================================

func _modify_arena(phase: int) -> void:
	match phase:
		1:
			_spawn_lava_pools(3)
		2:
			_spawn_lava_pools(4)
			_ignite_arena()

func _spawn_lava_pools(count: int) -> void:
	for i in range(count):
		var angle: float = (TAU / count) * i + randf() * 0.5
		var distance: float = randf_range(150.0, 300.0)
		var pos: Vector2 = global_position + Vector2(cos(angle), sin(angle)) * distance

		# 创建岩浆池
		var pool := Area2D.new()
		pool.global_position = pos
		pool.collision_layer = 0
		pool.collision_mask = 1  # 检测玩家

		var collision := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = 50.0
		collision.shape = shape
		pool.add_child(collision)

		var sprite := Sprite2D.new()
		var tex := ImageTexture.new()
		var img := Image.create(100, 100, false, Image.FORMAT_RGBA8)
		img.fill(Color(1.0, 0.4, 0.1, 0.7))
		tex.set_image(img)
		sprite.texture = tex
		sprite.offset = Vector2(-50, -50)
		pool.add_child(sprite)

		# 伤害脚本
		pool.set_script(_create_lava_pool_script())

		get_tree().current_scene.add_child(pool)
		_arena_hazards.append(pool)

func _create_lava_pool_script() -> GDScript:
	var script := GDScript.new()
	script.source_code = """
extends Area2D
var damage: float = 10.0
var damage_interval: float = 1.0
var _timer: float = 0.0

func _process(delta):
	_timer += delta
	if _timer >= damage_interval:
		_timer = 0.0
		for body in get_overlapping_bodies():
			if body.has_method("take_damage"):
				body.take_damage(damage, null)
"""
	script.reload()
	return script

func _ignite_arena() -> void:
	# 点燃效果
	var fire_particles := Node2D.new()
	fire_particles.name = "FireParticles"
	fire_particles.z_index = -1

	for i in range(20):
		var particle := Sprite2D.new()
		var tex := ImageTexture.new()
		var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
		img.fill(Color(1.0, 0.5 + randf() * 0.3, 0.0, 0.6))
		tex.set_image(img)
		particle.texture = tex
		particle.global_position = global_position + Vector2(randf_range(-300, 300), randf_range(-300, 300))
		fire_particles.add_child(particle)

	get_tree().current_scene.add_child(fire_particles)
	_arena_hazards.append(fire_particles)