## Void Hunter - 吸血光环
## @description: 被动技能，攻击时回复一定比例伤害值的生命
## @version: 1.0.0

extends "res://src/skills/skill_base.gd"

# =============================================================================
# 导出变量
# =============================================================================

## 基础吸血比例
@export var base_life_steal: float = 0.03

## 最大吸血比例（等级3）
@export var max_life_steal: float = 0.08

## 光环范围（对附近队友也有效）
@export var aura_range: float = 150.0

# =============================================================================
# 私有变量
# =============================================================================

var _aura_visual: Node2D = null

# =============================================================================
# 初始化
# =============================================================================

func _init() -> void:
	skill_id = "vampiric_aura"
	skill_name = "吸血光环"
	description = "攻击时回复伤害值一定比例的生命，附近队友也获得效果"
	skill_type = SkillBase.SkillType.PASSIVE
	skill_category = SkillBase.SkillCategory.SUPPORT
	element = SkillBase.SkillElement.SHADOW
	base_cooldown = 0.0
	base_mana_cost = 0.0

# =============================================================================
# 被动技能激活
# =============================================================================

func _on_passive_activate() -> void:
	"""被动激活时连接攻击信号"""
	if owner_node == null:
		return

	# 监听攻击命中
	if owner_node.has_signal("attack_hit"):
		owner_node.attack_hit.connect(_on_attack_hit)
	elif owner_node.has_signal("damage_dealt"):
		owner_node.damage_dealt.connect(_on_damage_dealt)

	# 创建光环视觉
	_create_aura_visual()

func _on_passive_deactivate() -> void:
	"""被动停用时移除光环"""
	if _aura_visual:
		_aura_visual.queue_free()
		_aura_visual = null

# =============================================================================
# 吸血逻辑
# =============================================================================

func _on_attack_hit(target: Node, damage: float) -> void:
	"""攻击命中时触发吸血"""
	_apply_life_steal(damage)

func _on_damage_dealt(target: Node, damage: float) -> void:
	"""造成伤害时触发吸血"""
	_apply_life_steal(damage)

func _apply_life_steal(damage: float) -> void:
	"""应用吸血效果"""
	if owner_node == null or damage <= 0:
		return

	var stats = _get_stats()
	if stats == null:
		return

	# 计算吸血量
	var steal_ratio: float = _get_life_steal_ratio()
	var heal_amount: float = damage * steal_ratio

	# 回复生命
	if stats.has_method("heal"):
		stats.heal(heal_amount)
	elif "current_health" in stats:
		stats.current_health = minf(stats.current_health + heal_amount, stats.max_health)

	# 触发吸血特效
	_show_life_steal_effect(heal_amount)

func _get_life_steal_ratio() -> float:
	"""获取当前等级的吸血比例"""
	var level_ratio: float = float(current_level - 1) / float(MAX_SKILL_LEVEL - 1)
	return base_life_steal + (max_life_steal - base_life_steal) * level_ratio

# =============================================================================
# 光环范围效果
# =============================================================================

func get_aura_bonus_for_nearby() -> float:
	"""获取光环对附近队友的吸血加成（一半效果）"""
	return _get_life_steal_ratio() * 0.5

func _create_aura_visual() -> void:
	"""创建光环视觉效果"""
	if owner_node == null:
		return

	_aura_visual = Node2D.new()
	_aura_visual.name = "VampiricAuraVisual"
	owner_node.add_child(_aura_visual)

	# 创建光环圆圈
	var circle = _create_aura_circle()
	_aura_visual.add_child(circle)

func _create_aura_circle() -> Node2D:
	"""创建光环圆圈"""
	var circle = Node2D.new()

	# 使用Line2D绘制圆圈
	var line = Line2D.new()
	line.width = 2.0
	line.default_color = Color(0.8, 0.2, 0.3, 0.4)

	var points: Array[Vector2] = []
	var radius: float = aura_range
	var segments: int = 32

	for i in range(segments + 1):
		var angle: float = TAU * i / segments
		points.append(Vector2(cos(angle) * radius, sin(angle) * radius))

	line.points = points
	circle.add_child(line)

	return circle

func _show_life_steal_effect(amount: float) -> void:
	"""显示吸血特效"""
	if owner_node == null:
		return

	# 绿色闪光
	var tween = owner_node.create_tween()
	tween.tween_property(owner_node, "modulate:g", 1.5, 0.1)
	tween.tween_property(owner_node, "modulate:g", 1.0, 0.2)

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
	"""升级时更新光环视觉"""
	if _aura_visual:
		# 更新光环大小
		var new_range: float = aura_range * (1.0 + (new_level - 1) * 0.15)
		for child in _aura_visual.get_children():
			if child is Node2D:
				for sub_child in child.get_children():
					if sub_child is Line2D:
						# 重绘光环
						var points: Array[Vector2] = []
						var segments: int = 32
						for i in range(segments + 1):
							var angle: float = TAU * i / segments
							points.append(Vector2(cos(angle) * new_range, sin(angle) * new_range))
						sub_child.points = points