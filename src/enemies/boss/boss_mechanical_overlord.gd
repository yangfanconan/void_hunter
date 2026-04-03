## Void Hunter - 机械霸主Boss
## @description: 机械城主题Boss，科技与火力的结合
## @version: 1.0.0

extends "res://src/enemies/boss/boss_base.gd"

# =============================================================================
# 配置
# =============================================================================

const BOSS_NAME := "机械霸主"

## 专属技能配置
const SKILLS := [
	{
		"id": "gatling_gun",
		"type": 3,  # BossSkillType.PROJECTILE
		"count": 20,
		"damage": 10.0,
		"speed": 400.0,
		"pattern": "targeted",
		"spread": 15.0,
		"cooldown": 4.0,
		"min_phase": 0
	},
	{
		"id": "laser_sweep",
		"type": 4,  # BossSkillType.BEAM
		"damage": 30.0,
		"duration": 3.0,
		"width": 25.0,
		"cooldown": 10.0,
		"min_phase": 0
	},
	{
		"id": "rocket_barrage",
		"type": 3,  # BossSkillType.PROJECTILE
		"count": 6,
		"damage": 40.0,
		"speed": 200.0,
		"pattern": "circular",
		"cooldown": 8.0,
		"min_phase": 1
	},
	{
		"id": "shield_bash",
		"type": 0,  # BossSkillType.CHARGE
		"damage": 50.0,
		"speed": 450.0,
		"distance": 300.0,
		"hit_area": 70.0,
		"cooldown": 12.0,
		"min_phase": 1
	},
	{
		"id": "overcharge",
		"type": 1,  # BossSkillType.AOE
		"damage": 70.0,
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
		{"item_id": "weapon_thunder_hammer", "chance": 0.3},
		{"item_id": "accessory_lucky_charm", "chance": 0.4},
		{"item_id": "special_exp_gem", "chance": 0.8},
		{"item_id": "consumable_elixir", "chance": 0.5},
	]

# =============================================================================
# 阶段变化效果
# =============================================================================

func _modify_arena(phase: int) -> void:
	match phase:
		1:
			_activate_turrets(2)
		2:
			_activate_turrets(2)
			_activate_lasers()

func _activate_turrets(count: int) -> void:
	for i in range(count):
		var angle: float = (TAU / count) * i + PI / 4
		var distance: float = 250.0
		var pos: Vector2 = global_position + Vector2(cos(angle), sin(angle)) * distance

		var turret := Node2D.new()
		turret.global_position = pos
		turret.name = "Turret"

		var sprite := Sprite2D.new()
		var tex := ImageTexture.new()
		var img := Image.create(30, 30, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.4, 0.4, 0.5))
		tex.set_image(img)
		sprite.texture = tex
		turret.add_child(sprite)

		# 简单炮塔脚本
		turret.set_script(_create_turret_script())

		get_tree().current_scene.add_child(turret)
		_arena_hazards.append(turret)

func _create_turret_script() -> GDScript:
	var script := GDScript.new()
	script.source_code = """
extends Node2D
var fire_rate: float = 2.0
var bullet_speed: float = 300.0
var bullet_damage: float = 15.0
var _timer: float = 0.0

func _process(delta):
	_timer += delta
	if _timer >= fire_rate:
		_timer = 0.0
		_fire()

func _fire():
	var players = get_tree().get_nodes_in_group("players")
	if players.is_empty():
		return
	var target = players[0]
	var dir = (target.global_position - global_position).normalized()
	_spawn_bullet(dir)

func _spawn_bullet(dir: Vector2):
	var bullet = Area2D.new()
	bullet.collision_layer = 4
	bullet.collision_mask = 1
	bullet.global_position = global_position

	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 5.0
	col.shape = shape
	bullet.add_child(col)

	var spr = Sprite2D.new()
	var tex = ImageTexture.new()
	var img = Image.create(10, 10, false, Image.FORMAT_RGBA8)
	img.fill(Color.YELLOW)
	tex.set_image(img)
	spr.texture = tex
	bullet.add_child(spr)

	bullet.set_script(_create_bullet_script(dir))
	get_tree().current_scene.add_child(bullet)

func _create_bullet_script(dir: Vector2) -> GDScript:
	var s = GDScript.new()
	s.source_code = \"""
extends Area2D
var direction: Vector2 = Vector2.RIGHT
var speed: float = 300.0
var damage: float = 15.0
var lifetime: float = 3.0

func _ready():
	direction = _get_dir()

func _get_dir():
	var script = get_script()
	if script and script.has_meta('direction'):
		return script.get_meta('direction')
	return Vector2.RIGHT

func _physics_process(delta):
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
	position += direction * speed * delta

func _on_body_entered(body):
	if body.has_method('take_damage'):
		body.take_damage(damage, null)
	queue_free()
\"""
	s.reload()
	s.set_meta('direction', dir)
	return s
"""
	script.reload()
	return script

func _activate_lasers() -> void:
	# 激活定时激光
	var laser_system := Node2D.new()
	laser_system.name = "LaserSystem"
	laser_system.set_script(_create_laser_system_script())

	get_tree().current_scene.add_child(laser_system)
	_arena_hazards.append(laser_system)

func _create_laser_system_script() -> GDScript:
	var script := GDScript.new()
	script.source_code = """
extends Node2D
var laser_interval: float = 5.0
var _timer: float = 0.0

func _process(delta):
	_timer += delta
	if _timer >= laser_interval:
		_timer = 0.0
		_fire_laser()

func _fire_laser():
	var laser = Line2D.new()
	laser.add_point(Vector2(0, -1000))
	laser.add_point(Vector2(0, 1000))
	laser.width = 10.0
	laser.default_color = Color(1, 0, 0, 0.7)
	laser.z_index = 10
	laser.global_position = Vector2(randf_range(200, 900), 320)
	get_tree().current_scene.add_child(laser)

	var tween = laser.create_tween()
	tween.tween_interval(0.5)
	tween.tween_property(laser, "modulate:a", 0.0, 0.3)
	tween.tween_callback(laser.queue_free)
"""
	script.reload()
	return script