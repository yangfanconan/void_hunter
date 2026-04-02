## Void Hunter - 闪现技能
## @description: 瞬移到目标位置
## @author: Void Hunter Team
## @version: 1.0.0

extends SkillBase
class_name SkillBlink

# =============================================================================
# 配置参数
# =============================================================================

## 闪现最大距离
@export var max_distance: float = 250.0

## 闪现后无敌时间
@export var invincibility_time: float = 0.5

## 是否留下残影
@export var leave_afterimage: bool = true

## 残影持续时间
@export var afterimage_duration: float = 1.0

## 是否造成落点伤害
@export var arrival_damage: bool = false

## 落点伤害范围
@export var arrival_damage_range: float = 60.0

# =============================================================================
# 初始化
# =============================================================================

func _init() -> void:
	skill_id = "blink"
	skill_name = "闪现"
	description = "瞬间传送到目标位置，并获得短暂无敌。"
	skill_type = SkillType.ACTIVE
	skill_category = SkillCategory.DEFENSIVE
	target_type = TargetType.POSITION
	element = SkillElement.ARCANE
	hotkey_slot = 3

	base_damage = 15.0
	base_cooldown = 8.0
	base_mana_cost = 20.0
	effect_range = max_distance


# =============================================================================
# 技能效果
# =============================================================================

func _execute_position_effect(target_position: Variant) -> void:
	"""
	执行闪现
	"""
	if owner_node == null or target_position == null:
		return

	var target_pos: Vector2 = target_position if target_position is Vector2 else Vector2.ZERO
	var current_pos: Vector2 = owner_node.global_position

	# 限制距离
	var direction: Vector2 = target_pos - current_pos
	var distance: float = direction.length()

	if distance > get_max_distance():
		direction = direction.normalized() * get_max_distance()
		target_pos = current_pos + direction

	# 创建残影
	if leave_afterimage:
		_create_afterimage(current_pos)

	# 执行闪现
	_perform_blink(target_pos)


func _perform_blink(target_pos: Vector2) -> void:
	"""
	执行闪现传送
	"""
	# VFX: 闪现冲刺拖尾
	if VFXManager:
		VFXManager.spawn_dash_trail(owner_node.global_position)

	# 闪现前效果
	_create_blink_effect(owner_node.global_position, true)

	# 传送
	owner_node.global_position = target_pos

	# 闪现后效果
	_create_blink_effect(target_pos, false)

	# 落点伤害
	if arrival_damage:
		_apply_arrival_damage(target_pos)

	# 无敌时间
	if owner_node.has_method("start_invincibility"):
		owner_node.start_invincibility(get_invincibility_time())


# =============================================================================
# 视觉效果
# =============================================================================

func _create_afterimage(pos: Vector2) -> void:
	"""
	创建残影效果
	"""
	var afterimage: Node2D = Node2D.new()
	afterimage.global_position = pos
	afterimage.modulate = Color(0.5, 0.3, 0.8, 0.7)

	# 添加到场景
	owner_node.get_tree().current_scene.add_child(afterimage)

	# 淡出效果
	var tween: Tween = owner_node.create_tween()
	tween.tween_property(afterimage, "modulate:a", 0.0, afterimage_duration)
	tween.tween_callback(afterimage.queue_free)


func _create_blink_effect(pos: Vector2, is_start: bool) -> void:
	"""
	创建闪现效果
	"""
	var effect: Node2D = Node2D.new()
	effect.global_position = pos

	# 闪烁效果
	var color: Color = Color(0.6, 0.3, 0.9) if is_start else Color(0.3, 0.6, 0.9)
	effect.modulate = color

	owner_node.get_tree().current_scene.add_child(effect)

	# 快速扩散并消失
	var tween: Tween = owner_node.create_tween()
	tween.tween_property(effect, "modulate:a", 0.0, 0.2)
	tween.tween_callback(effect.queue_free)


# =============================================================================
# 伤害效果
# =============================================================================

func _apply_arrival_damage(pos: Vector2) -> void:
	"""
	应用落点伤害
	"""
	var targets: Array[Node] = _get_targets_in_area(pos, arrival_damage_range)

	for target in targets:
		if target.has_method("take_damage"):
			target.take_damage(get_damage(), owner_node)


# =============================================================================
# 属性获取
# =============================================================================

func get_max_distance() -> float:
	"""
	获取最大闪现距离（受等级影响）
	"""
	return max_distance * (1.0 + (current_level - 1) * 0.2)


func get_invincibility_time() -> float:
	"""
	获取无敌时间（受等级影响）
	"""
	return invincibility_time + (current_level - 1) * 0.25


# =============================================================================
# 升级效果
# =============================================================================

func _on_level_up(new_level: int) -> void:
	"""
	升级时增强闪现
	"""
	match new_level:
		2:
			max_distance = 300.0
			invincibility_time = 0.75
		3:
			max_distance = 350.0
			invincibility_time = 1.0
			arrival_damage = true
			base_damage = 25.0
