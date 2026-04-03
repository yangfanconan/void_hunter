## Void Hunter - 地牢领主Boss
## @description: 第一个Boss，废弃地牢主题，多阶段战斗
## @version: 1.0.0

extends "res://src/enemies/boss/boss_base.gd"

# =============================================================================
# 配置
# =============================================================================

const BOSS_NAME := "地牢领主"

## 专属技能配置
const SKILLS := [
	{
		"id": "ground_slam",
		"type": 0,  # BossSkillType.SHOCKWAVE
		"damage": 30.0,
		"max_radius": 300.0,
		"speed": 150.0,
		"cooldown": 8.0,
		"min_phase": 0
	},
	{
		"id": "summon_skeletons",
		"type": 2,  # BossSkillType.SUMMON
		"count": 4,
		"enemy_type": "melee",
		"spawn_distance": 150.0,
		"cooldown": 12.0,
		"min_phase": 1
	},
	{
		"id": "dark_charge",
		"type": 0,  # BossSkillType.CHARGE
		"damage": 40.0,
		"speed": 350.0,
		"distance": 400.0,
		"hit_area": 60.0,
		"cooldown": 10.0,
		"min_phase": 1
	},
	{
		"id": "bone_storm",
		"type": 3,  # BossSkillType.PROJECTILE
		"count": 16,
		"damage": 15.0,
		"speed": 250.0,
		"pattern": "circular",
		"cooldown": 6.0,
		"min_phase": 2
	},
	{
		"id": "soul_drain",
		"type": 1,  # BossSkillType.AOE
		"damage": 50.0,
		"radius": 200.0,
		"delay": 1.5,
		"cooldown": 15.0,
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
		{"item_id": "weapon_steel_sword", "chance": 0.5},
		{"item_id": "armor_iron", "chance": 0.4},
		{"item_id": "accessory_ring_of_power", "chance": 0.3},
		{"item_id": "consumable_elixir", "chance": 0.8},
	]

# =============================================================================
# 阶段变化效果
# =============================================================================

func _modify_arena(phase: int) -> void:
	match phase:
		1:
			# 第二阶段：召唤柱子
			_spawn_pillars(4)
		2:
			# 第三阶段：黑暗覆盖
			_darken_arena()

func _spawn_pillars(count: int) -> void:
	for i in range(count):
		var angle: float = (TAU / count) * i
		var distance: float = 200.0
		var pos: Vector2 = global_position + Vector2(cos(angle), sin(angle)) * distance

		var pillar := StaticBody2D.new()
		pillar.global_position = pos
		pillar.collision_layer = 16
		pillar.collision_mask = 0

		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(40, 40)
		collision.shape = shape
		pillar.add_child(collision)

		var sprite := Sprite2D.new()
		var tex := ImageTexture.new()
		var img := Image.create(40, 40, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.3, 0.3, 0.35))
		tex.set_image(img)
		sprite.texture = tex
		pillar.add_child(sprite)

		get_tree().current_scene.add_child(pillar)
		_arena_hazards.append(pillar)

func _darken_arena() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.3)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = -1
	overlay.name = "DarknessOverlay"
	get_tree().current_scene.add_child(overlay)
	_arena_hazards.append(overlay)