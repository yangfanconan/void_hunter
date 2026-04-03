## Void Hunter - 元素亲和
## @description: 被动技能，提升元素伤害并降低元素技能冷却
## @version: 1.0.0

extends "res://src/skills/skill_base.gd"

# =============================================================================
# 导出变量
# =============================================================================

## 基础元素伤害加成
@export var base_element_bonus: float = 0.10

## 最大元素伤害加成（等级3）
@export var max_element_bonus: float = 0.25

## 基础冷却缩减
@export var base_cooldown_reduction: float = 0.08

## 最大冷却缩减（等级3）
@export var max_cooldown_reduction: float = 0.15

## 生效元素类型
@export var affected_elements: Array[SkillBase.SkillElement] = [
	SkillBase.SkillElement.FIRE,
	SkillBase.SkillElement.ICE,
	SkillBase.SkillElement.LIGHTNING,
	SkillBase.SkillElement.SHADOW,
	SkillBase.SkillElement.HOLY,
	SkillBase.SkillElement.ARCANE
]

# =============================================================================
# 私有变量
# =============================================================================

var _applied_damage_bonus: float = 0.0
var _applied_cooldown_reduction: float = 0.0

# =============================================================================
# 初始化
# =============================================================================

func _init() -> void:
	skill_id = "elemental_affinity"
	skill_name = "元素亲和"
	description = "提升所有元素技能的伤害和冷却缩减"
	skill_type = SkillBase.SkillType.PASSIVE
	skill_category = SkillBase.SkillCategory.SUPPORT
	element = SkillBase.SkillElement.ARCANE
	base_cooldown = 0.0
	base_mana_cost = 0.0

# =============================================================================
# 被动技能激活
# =============================================================================

func _on_passive_activate() -> void:
	"""被动激活时应用元素加成"""
	_apply_element_bonuses()

func _on_passive_deactivate() -> void:
	"""被动停用时移除元素加成"""
	_remove_element_bonuses()

# =============================================================================
# 元素加成应用
# =============================================================================

func _apply_element_bonuses() -> void:
	"""应用元素加成"""
	if owner_node == null:
		return

	var stats = _get_stats()
	if stats == null:
		return

	_applied_damage_bonus = _get_element_damage_bonus()
	_applied_cooldown_reduction = _get_cooldown_reduction()

	# 应用元素伤害加成
	if stats.has_method("add_element_damage_bonus"):
		for element_type in affected_elements:
			stats.add_element_damage_bonus(element_type, _applied_damage_bonus)
	elif "element_damage_multiplier" in stats:
		stats.element_damage_multiplier += _applied_damage_bonus

	# 应用冷却缩减
	if stats.has_method("add_cooldown_reduction"):
		stats.add_cooldown_reduction(_applied_cooldown_reduction)
	elif "cooldown_reduction" in stats:
		stats.cooldown_reduction += _applied_cooldown_reduction

func _remove_element_bonuses() -> void:
	"""移除元素加成"""
	if owner_node == null:
		return

	var stats = _get_stats()
	if stats == null:
		return

	# 移除元素伤害加成
	if stats.has_method("add_element_damage_bonus"):
		for element_type in affected_elements:
			stats.add_element_damage_bonus(element_type, -_applied_damage_bonus)
	elif "element_damage_multiplier" in stats:
		stats.element_damage_multiplier -= _applied_damage_bonus

	# 移除冷却缩减
	if stats.has_method("add_cooldown_reduction"):
		stats.add_cooldown_reduction(-_applied_cooldown_reduction)
	elif "cooldown_reduction" in stats:
		stats.cooldown_reduction -= _applied_cooldown_reduction

	_applied_damage_bonus = 0.0
	_applied_cooldown_reduction = 0.0

func _get_element_damage_bonus() -> float:
	"""获取当前等级的元素伤害加成"""
	var level_ratio: float = float(current_level - 1) / float(MAX_SKILL_LEVEL - 1)
	return base_element_bonus + (max_element_bonus - base_element_bonus) * level_ratio

func _get_cooldown_reduction() -> float:
	"""获取当前等级的冷却缩减"""
	var level_ratio: float = float(current_level - 1) / float(MAX_SKILL_LEVEL - 1)
	return base_cooldown_reduction + (max_cooldown_reduction - base_cooldown_reduction) * level_ratio

# =============================================================================
# 公共方法 - 元素伤害计算
# =============================================================================

## 计算元素技能的实际伤害
func calculate_element_damage(base_damage: float, skill_element: SkillBase.SkillElement) -> float:
	"""计算元素技能的实际伤害（加成后）"""
	if skill_element in affected_elements:
		return base_damage * (1.0 + _applied_damage_bonus)
	return base_damage

## 计算元素技能的实际冷却
func calculate_element_cooldown(base_cooldown: float) -> float:
	"""计算元素技能的实际冷却（缩减后）"""
	return base_cooldown * (1.0 - _applied_cooldown_reduction)

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
	_remove_element_bonuses()
	_apply_element_bonuses()