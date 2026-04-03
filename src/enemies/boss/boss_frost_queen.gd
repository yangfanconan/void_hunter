## Void Hunter - 冰霜女王Boss
## @description: 冰霜要塞主题Boss，冰冻与减速专家
## @version: 1.0.0

extends "res://src/enemies/boss/boss_base.gd"

# =============================================================================
# 配置
# =============================================================================

const BOSS_NAME := "冰霜女王"

## 专属技能配置
const SKILLS := [
	{
		"id": "frost_nova",
		"type": 1,  # BossSkillType.AOE
		"damage": 25.0,
		"radius": 180.0,
		"delay": 1.0,
		"cooldown": 6.0,
		"min_phase": 0,
		"freeze_duration": 1.5
	},
	{
		"id": "ice_lance",
		"type": 3,  # BossSkillType.PROJECTILE
		"count": 8,
		"damage": 20.0,
		"speed": 350.0,
		"pattern": "spiral",
		"cooldown": 5.0,
		"min_phase": 0
	},
	{
		"id": "blizzard",
		"type": 1,  # BossSkillType.AOE
		"damage": 15.0,
		"radius": 300.0,
		"delay": 0.5,
		"duration": 3.0,
		"cooldown": 15.0,
		"min_phase": 1
	},
	{
		"id": "frozen_ground",
		"type": 5,  # BossSkillType.SHOCKWAVE
		"damage": 30.0,
		"max_radius": 400.0,
		"speed": 100.0,
		"cooldown": 12.0,
		"min_phase": 1
	},
	{
		"id": "absolute_zero",
		"type": 1,  # BossSkillType.AOE
		"damage": 80.0,
		"radius": 200.0,
		"delay": 3.0,
		"cooldown": 25.0,
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
		{"item_id": "weapon_frost_scythe", "chance": 0.35},
		{"item_id": "accessory_gem_of_wisdom", "chance": 0.4},
		{"item_id": "consumable_mana_potion", "chance": 0.7},
		{"item_id": "material_essence_ice", "chance": 0.5},
	]

# =============================================================================
# 技能重写 - 添加冰冻效果
# =============================================================================

func _execute_aoe(skill: Dictionary) -> void:
	await super._execute_aoe(skill)

	# 添加冰冻效果
	var freeze_duration: float = skill.get("freeze_duration", 1.0)
	if freeze_duration > 0:
		var radius: float = skill.get("radius", 150.0)
		_apply_freeze_in_area(global_position, radius, freeze_duration)

func _apply_freeze_in_area(center: Vector2, radius: float, duration: float) -> void:
	# 查找范围内的敌人...不，是玩家
	if player and is_instance_valid(player):
		if player.global_position.distance_to(center) <= radius:
			if player.has_method("apply_freeze"):
				player.apply_freeze(duration)
			elif "stats" in player:
				# 通过状态效果管理器
				var status_mgr = get_tree().current_scene.get_node_or_null("StatusEffectManager")
				if status_mgr and status_mgr.has_method("apply_freeze"):
					status_mgr.apply_freeze(player, 0.5, duration, self)

# =============================================================================
# 阶段变化效果
# =============================================================================

func _modify_arena(phase: int) -> void:
	match phase:
		1:
			_spawn_ice_pillars(6)
		2:
			_create_blizzard_zone()

func _spawn_ice_pillars(count: int) -> void:
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
		shape.size = Vector2(30, 50)
		collision.shape = shape
		pillar.add_child(collision)

		var sprite := Sprite2D.new()
		var tex := ImageTexture.new()
		var img := Image.create(30, 50, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.6, 0.8, 1.0, 0.8))
		tex.set_image(img)
		sprite.texture = tex
		pillar.add_child(sprite)

		get_tree().current_scene.add_child(pillar)
		_arena_hazards.append(pillar)

func _create_blizzard_zone() -> void:
	# 创建全场暴风雪减速区
	var blizzard := Node2D.new()
	blizzard.name = "BlizzardZone"
	blizzard.z_index = -1

	# 视觉效果
	var bg := ColorRect.new()
	bg.color = Color(0.7, 0.85, 1.0, 0.2)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	blizzard.add_child(bg)

	get_tree().current_scene.add_child(blizzard)
	_arena_hazards.append(blizzard)