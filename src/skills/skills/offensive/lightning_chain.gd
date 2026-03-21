## Void Hunter - 闪电链技能
## @description: 连锁攻击多个敌人
## @author: Void Hunter Team
## @version: 1.0.0

extends SkillBase
class_name SkillLightningChain

# =============================================================================
# 配置参数
# =============================================================================

## 连锁目标数量
@export var chain_targets: int = 3

## 连锁范围
@export var chain_range: float = 150.0

## 连锁伤害衰减（每次连锁减少的比例）
@export var chain_damage_decay: float = 0.2

## 眩晕时间
@export var stun_duration: float = 0.3

## 眩晕概率
@export_range(0.0, 1.0) var stun_chance: float = 0.2

# =============================================================================
# 初始化
# =============================================================================

func _init() -> void:
	skill_id = "lightning_chain"
	skill_name = "闪电链"
	description = "释放闪电链，在多个敌人之间跳跃，每次跳跃伤害递减。"
	skill_type = SkillType.ACTIVE
	skill_category = SkillCategory.OFFENSIVE
	target_type = TargetType.ENEMY
	element = SkillElement.LIGHTNING
	hotkey_slot = 2
	
	base_damage = 30.0
	base_cooldown = 4.0
	base_mana_cost = 25.0
	effect_range = 200.0


# =============================================================================
# 技能效果
# =============================================================================

func _execute_enemy_effect(target: Node) -> void:
	"""
	对目标释放闪电链
	"""
	if target == null:
		return
	
	_execute_chain_lightning(target, get_damage(), [])


func _execute_chain_lightning(current_target: Node, damage: float, hit_list: Array) -> void:
	"""
	执行闪电链效果
	"""
	if current_target == null or not is_instance_valid(current_target):
		return
	
	# 造成伤害
	if current_target.has_method("take_damage"):
		current_target.take_damage(damage, owner_node)
		skill_hit.emit(self, current_target, damage)
	
	# 应用眩晕
	if randf() < get_stun_chance():
		if current_target.has_method("apply_stun"):
			current_target.apply_stun(get_stun_duration())
	
	# 创建闪电视觉效果
	_create_lightning_visual(current_target)
	
	# 添加到已命中列表
	hit_list.append(current_target)
	
	# 检查是否还能继续连锁
	if hit_list.size() >= get_chain_targets():
		return
	
	# 寻找下一个目标
	var next_target: Node = _find_next_chain_target(current_target.global_position, hit_list)
	
	if next_target:
		# 连锁伤害衰减
		var next_damage: float = damage * (1.0 - chain_damage_decay)
		
		# 延迟一小段时间后继续连锁
		await owner_node.get_tree().create_timer(0.1).timeout
		_execute_chain_lightning(next_target, next_damage, hit_list)


func _find_next_chain_target(from_pos: Vector2, exclude_list: Array) -> Node:
	"""
	寻找下一个连锁目标
	"""
	if owner_node == null:
		return null
	
	var targets: Array[Node] = _get_targets_in_area(from_pos, get_chain_range())
	
	# 过滤已命中的目标
	for target in targets:
		if target not in exclude_list:
			return target
	
	return null


func _create_lightning_visual(target: Node) -> void:
	"""
	创建闪电视觉效果
	"""
	if owner_node == null or target == null:
		return
	
	# 创建简单的闪电线条
	var line: Line2D = Line2D.new()
	line.add_point(owner_node.global_position if hit_list.is_empty() else Vector2.ZERO)
	line.add_point(target.global_position)
	line.width = 3.0
	line.default_color = Color(0.5, 0.7, 1.0, 1.0)
	
	owner_node.get_tree().current_scene.add_child(line)
	
	# 短暂显示后移除
	await owner_node.get_tree().create_timer(0.15).timeout
	line.queue_free()


var hit_list: Array = []

# =============================================================================
# 属性获取
# =============================================================================

func get_chain_targets() -> int:
	"""
	获取连锁目标数量（受等级影响）
	"""
	return chain_targets + (current_level - 1)


func get_chain_range() -> float:
	"""
	获取连锁范围（受等级影响）
	"""
	return chain_range * (1.0 + (current_level - 1) * 0.2)


func get_stun_chance() -> float:
	"""
	获取眩晕概率（受等级影响）
	"""
	return stun_chance + (current_level - 1) * 0.1


func get_stun_duration() -> float:
	"""
	获取眩晕时间（受等级影响）
	"""
	return stun_duration * (1.0 + (current_level - 1) * 0.15)


# =============================================================================
# 升级效果
# =============================================================================

func _on_level_up(new_level: int) -> void:
	"""
	升级时增强闪电链
	"""
	match new_level:
		2:
			chain_targets = 4
			chain_damage_decay = 0.15
		3:
			chain_targets = 5
			chain_damage_decay = 0.1
			stun_chance = 0.4
