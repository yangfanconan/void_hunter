## Void Hunter - 狂暴之力
## @description: 被动技能，低血量时大幅提升攻击力和攻击速度
## @version: 1.0.0

extends "res://src/skills/skill_base.gd"

# =============================================================================
# 导出变量
# =============================================================================

## 触发血量阈值（百分比）
@export var health_threshold: float = 0.3

## 基础攻击力加成
@export var base_attack_bonus: float = 0.25

## 基础攻击速度加成
@export var base_speed_bonus: float = 0.20

## 最大加成（等级3时）
@export var max_attack_bonus: float = 0.50
@export var max_speed_bonus: float = 0.40

# =============================================================================
# 私有变量
# =============================================================================

var _is_active: bool = false
var _original_attack: float = 0.0
var _original_speed: float = 0.0

# =============================================================================
# 初始化
# =============================================================================

func _init() -> void:
	skill_id = "berserker_rage"
	skill_name = "狂暴之力"
	description = "当生命值低于30%时，攻击力和攻击速度大幅提升"
	skill_type = SkillBase.SkillType.PASSIVE
	skill_category = SkillBase.SkillCategory.OFFENSIVE
	element = SkillBase.SkillElement.PHYSICAL
	base_cooldown = 0.0
	base_mana_cost = 0.0

# =============================================================================
# 被动技能激活
# =============================================================================

func _on_passive_activate() -> void:
	"""被动激活时连接血量监控"""
	if owner_node == null:
		return

	# 监听血量变化
	if owner_node.has_signal("health_changed"):
		owner_node.health_changed.connect(_on_health_changed)

	# 初始检查
	_check_health_threshold()

func _on_passive_deactivate() -> void:
	"""被动停用时移除加成"""
	_remove_bonuses()

# =============================================================================
# 血量监控
# =============================================================================

func _on_health_changed(current: float, max_health: float) -> void:
	"""血量变化时检查阈值"""
	var health_percent: float = current / max_health

	if health_percent <= health_threshold and not _is_active:
		_apply_bonuses()
	elif health_percent > health_threshold and _is_active:
		_remove_bonuses()

func _check_health_threshold() -> void:
	"""检查当前血量是否需要激活"""
	if owner_node == null:
		return

	var stats = _get_stats()
	if stats == null:
		return

	var health_percent: float = stats.current_health / stats.max_health
	if health_percent <= health_threshold:
		_apply_bonuses()

# =============================================================================
# 加成应用
# =============================================================================

func _apply_bonuses() -> void:
	"""应用狂暴加成"""
	if _is_active or owner_node == null:
		return

	_is_active = true

	var stats = _get_stats()
	if stats == null:
		return

	# 记录原始值
	_original_attack = stats.attack_bonus
	_original_speed = stats.attack_speed_bonus

	# 计算加成（根据等级）
	var attack_bonus: float = _get_attack_bonus()
	var speed_bonus: float = _get_speed_bonus()

	# 应用加成
	stats.add_attack_bonus(attack_bonus)
	stats.add_attack_speed_bonus(speed_bonus)

	# 触发视觉效果
	_trigger_visual_effect()

func _remove_bonuses() -> void:
	"""移除狂暴加成"""
	if not _is_active or owner_node == null:
		return

	_is_active = false

	var stats = _get_stats()
	if stats == null:
		return

	# 移除加成
	stats.add_attack_bonus(-_get_attack_bonus())
	stats.add_attack_speed_bonus(-_get_speed_bonus())

	# 移除视觉效果
	_remove_visual_effect()

func _get_attack_bonus() -> float:
	"""获取当前等级的攻击力加成"""
	var level_ratio: float = float(current_level - 1) / float(MAX_SKILL_LEVEL - 1)
	return base_attack_bonus + (max_attack_bonus - base_attack_bonus) * level_ratio

func _get_speed_bonus() -> float:
	"""获取当前等级的攻击速度加成"""
	var level_ratio: float = float(current_level - 1) / float(MAX_SKILL_LEVEL - 1)
	return base_speed_bonus + (max_speed_bonus - base_speed_bonus) * level_ratio

# =============================================================================
# 视觉效果
# =============================================================================

func _trigger_visual_effect() -> void:
	"""触发狂暴视觉效果"""
	if owner_node == null:
		return

	# 红色脉冲效果
	var tween = owner_node.create_tween()
	tween.tween_property(owner_node, "modulate", Color(1.2, 0.8, 0.8), 0.2)

	# 持续脉冲
	_start_pulse_effect()

func _remove_visual_effect() -> void:
	"""移除狂暴视觉效果"""
	if owner_node == null:
		return

	# 恢复原色
	var tween = owner_node.create_tween()
	tween.tween_property(owner_node, "modulate", Color.WHITE, 0.3)

func _start_pulse_effect() -> void:
	"""开始脉冲效果"""
	if not _is_active or owner_node == null:
		return

	var tween = owner_node.create_tween()
	tween.tween_property(owner_node, "modulate:v", 0.6, 0.3)
	tween.tween_property(owner_node, "modulate:v", 1.0, 0.3)
	tween.tween_callback(_start_pulse_effect)

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
	if _is_active:
		# 先移除旧加成，再应用新加成
		var stats = _get_stats()
		if stats:
			stats.add_attack_bonus(-_get_attack_bonus())
			stats.add_attack_speed_bonus(-_get_speed_bonus())

		# 使用新等级计算加成
		stats.add_attack_bonus(_get_attack_bonus())
		stats.add_attack_speed_bonus(_get_speed_bonus())