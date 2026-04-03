## Void Hunter - 暴击精通
## @description: 被动技能，提升暴击率和暴击伤害
## @version: 1.0.0

extends "res://src/skills/skill_base.gd"

# =============================================================================
# 导出变量
# =============================================================================

## 基础暴击率加成
@export var base_crit_chance: float = 0.05

## 最大暴击率加成（等级3）
@export var max_crit_chance: float = 0.15

## 基础暴击伤害加成
@export var base_crit_damage: float = 0.25

## 最大暴击伤害加成（等级3）
@export var max_crit_damage: float = 0.50

# =============================================================================
# 私有变量
# =============================================================================

var _applied_crit_chance: float = 0.0
var _applied_crit_damage: float = 0.0

# =============================================================================
# 初始化
# =============================================================================

func _init() -> void:
	skill_id = "critical_mastery"
	skill_name = "暴击精通"
	description = "永久提升暴击率和暴击伤害"
	skill_type = SkillBase.SkillType.PASSIVE
	skill_category = SkillBase.SkillCategory.OFFENSIVE
	element = SkillBase.SkillElement.PHYSICAL
	base_cooldown = 0.0
	base_mana_cost = 0.0

# =============================================================================
# 被动技能激活
# =============================================================================

func _on_passive_activate() -> void:
	"""被动激活时应用暴击加成"""
	_apply_crit_bonuses()

func _on_passive_deactivate() -> void:
	"""被动停用时移除暴击加成"""
	_remove_crit_bonuses()

# =============================================================================
# 暴击加成应用
# =============================================================================

func _apply_crit_bonuses() -> void:
	"""应用暴击加成"""
	if owner_node == null:
		return

	var stats = _get_stats()
	if stats == null:
		return

	# 计算加成
	_applied_crit_chance = _get_crit_chance_bonus()
	_applied_crit_damage = _get_crit_damage_bonus()

	# 应用暴击率
	if "critical_chance" in stats:
		stats.critical_chance += _applied_crit_chance
	elif stats.has_method("add_crit_chance"):
		stats.add_crit_chance(_applied_crit_chance)

	# 应用暴击伤害
	if "critical_damage" in stats:
		stats.critical_damage += _applied_crit_damage
	elif stats.has_method("add_crit_damage"):
		stats.add_crit_damage(_applied_crit_damage)

func _remove_crit_bonuses() -> void:
	"""移除暴击加成"""
	if owner_node == null:
		return

	var stats = _get_stats()
	if stats == null:
		return

	# 移除暴击率
	if "critical_chance" in stats:
		stats.critical_chance -= _applied_crit_chance
	elif stats.has_method("add_crit_chance"):
		stats.add_crit_chance(-_applied_crit_chance)

	# 移除暴击伤害
	if "critical_damage" in stats:
		stats.critical_damage -= _applied_crit_damage
	elif stats.has_method("add_crit_damage"):
		stats.add_crit_damage(-_applied_crit_damage)

	_applied_crit_chance = 0.0
	_applied_crit_damage = 0.0

func _get_crit_chance_bonus() -> float:
	"""获取当前等级的暴击率加成"""
	var level_ratio: float = float(current_level - 1) / float(MAX_SKILL_LEVEL - 1)
	return base_crit_chance + (max_crit_chance - base_crit_chance) * level_ratio

func _get_crit_damage_bonus() -> float:
	"""获取当前等级的暴击伤害加成"""
	var level_ratio: float = float(current_level - 1) / float(MAX_SKILL_LEVEL - 1)
	return base_crit_damage + (max_crit_damage - base_crit_damage) * level_ratio

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
	# 移除旧加成
	_remove_crit_bonuses()
	# 应用新加成
	_apply_crit_bonuses()