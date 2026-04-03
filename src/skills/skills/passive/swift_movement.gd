## Void Hunter - 迅捷移动
## @description: 被动技能，提升移动速度和闪避能力
## @version: 1.0.0

extends "res://src/skills/skill_base.gd"

# =============================================================================
# 导出变量
# =============================================================================

## 基础移动速度加成
@export var base_speed_bonus: float = 0.08

## 最大移动速度加成（等级3）
@export var max_speed_bonus: float = 0.20

## 基础闪避率加成
@export var base_dodge_chance: float = 0.03

## 最大闪避率加成（等级3）
@export var max_dodge_chance: float = 0.10

## 冲刺冷却缩减
@export var dash_cooldown_reduction: float = 0.25

# =============================================================================
# 私有变量
# =============================================================================

var _applied_speed: float = 0.0
var _applied_dodge: float = 0.0
var _trail_particles: Node2D = null

# =============================================================================
# 初始化
# =============================================================================

func _init() -> void:
	skill_id = "swift_movement"
	skill_name = "迅捷移动"
	description = "提升移动速度和闪避率，缩短冲刺冷却"
	skill_type = SkillBase.SkillType.PASSIVE
	skill_category = SkillBase.SkillCategory.DEFENSIVE
	element = SkillBase.SkillElement.NONE
	base_cooldown = 0.0
	base_mana_cost = 0.0

# =============================================================================
# 被动技能激活
# =============================================================================

func _on_passive_activate() -> void:
	"""被动激活时应用速度加成"""
	_apply_speed_bonuses()

	# 创建移动轨迹粒子
	if current_level >= 2:
		_create_trail_particles()

func _on_passive_deactivate() -> void:
	"""被动停用时移除速度加成"""
	_remove_speed_bonuses()

	if _trail_particles:
		_trail_particles.queue_free()
		_trail_particles = null

# =============================================================================
# 速度加成应用
# =============================================================================

func _apply_speed_bonuses() -> void:
	"""应用速度加成"""
	if owner_node == null:
		return

	var stats = _get_stats()
	if stats == null:
		return

	_applied_speed = _get_speed_bonus()
	_applied_dodge = _get_dodge_bonus()

	# 应用移动速度
	if stats.has_method("add_speed_bonus"):
		stats.add_speed_bonus(_applied_speed)
	elif "move_speed_multiplier" in stats:
		stats.move_speed_multiplier += _applied_speed

	# 应用闪避率
	if stats.has_method("add_dodge_chance"):
		stats.add_dodge_chance(_applied_dodge)
	elif "dodge_chance" in stats:
		stats.dodge_chance += _applied_dodge

	# 应用冲刺冷却缩减
	if stats.has_method("add_dash_cooldown_reduction"):
		stats.add_dash_cooldown_reduction(dash_cooldown_reduction)

func _remove_speed_bonuses() -> void:
	"""移除速度加成"""
	if owner_node == null:
		return

	var stats = _get_stats()
	if stats == null:
		return

	# 移除移动速度
	if stats.has_method("add_speed_bonus"):
		stats.add_speed_bonus(-_applied_speed)
	elif "move_speed_multiplier" in stats:
		stats.move_speed_multiplier -= _applied_speed

	# 移除闪避率
	if stats.has_method("add_dodge_chance"):
		stats.add_dodge_chance(-_applied_dodge)
	elif "dodge_chance" in stats:
		stats.dodge_chance -= _applied_dodge

	_applied_speed = 0.0
	_applied_dodge = 0.0

func _get_speed_bonus() -> float:
	"""获取当前等级的速度加成"""
	var level_ratio: float = float(current_level - 1) / float(MAX_SKILL_LEVEL - 1)
	return base_speed_bonus + (max_speed_bonus - base_speed_bonus) * level_ratio

func _get_dodge_bonus() -> float:
	"""获取当前等级的闪避加成"""
	var level_ratio: float = float(current_level - 1) / float(MAX_SKILL_LEVEL - 1)
	return base_dodge_chance + (max_dodge_chance - base_dodge_chance) * level_ratio

# =============================================================================
# 移动轨迹粒子
# =============================================================================

func _create_trail_particles() -> void:
	"""创建移动轨迹粒子效果"""
	if owner_node == null:
		return

	_trail_particles = Node2D.new()
	_trail_particles.name = "SwiftTrail"
	owner_node.add_child(_trail_particles)

	# 监听移动
	if owner_node.has_signal("moved"):
		owner_node.moved.connect(_on_owner_moved)

func _on_owner_moved(new_position: Vector2) -> void:
	"""移动时产生粒子"""
	if _trail_particles == null or owner_node == null:
		return

	# 创建拖尾粒子
	var particle = _create_trail_particle()
	particle.global_position = owner_node.global_position
	_trail_particles.add_child(particle)

func _create_trail_particle() -> Node2D:
	"""创建单个拖尾粒子"""
	var particle = Sprite2D.new()

	# 简单的圆形粒子
	var tex = ImageTexture.new()
	var img = Image.create(4, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.7, 0.9, 1.0, 0.5))
	tex.set_image(img)
	particle.texture = tex
	particle.centered = true

	# 消失动画
	var tween = particle.create_tween()
	tween.tween_property(particle, "modulate:a", 0.0, 0.3)
	tween.tween_callback(particle.queue_free)

	return particle

# =============================================================================
# 辅助方法
# =============================================================================

func _get_stats() -> Variant:
	"""获取持有者的属性组件"""
	if owner_node == null:
		return null

	if "stats" in owner_node:
		return owner_node.stats
	elif owner_node.has_node("Stats"):
		return owner_node.get_node("Stats")

	return null

func _on_level_up(new_level: int) -> void:
	"""升级时更新加成"""
	_remove_speed_bonuses()
	_apply_speed_bonuses()

	# 等级2时创建轨迹粒子
	if new_level >= 2 and _trail_particles == null:
		_create_trail_particles()