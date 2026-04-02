## Void Hunter - 闪电风暴技能
## @description: 在随机敌人位置召唤闪电，连锁攻击多个敌人
## @author: Void Hunter Team
## @version: 1.0.0

extends SkillBase
class_name SkillLightningStorm

# =============================================================================
# 配置参数
# =============================================================================

## 闪电攻击次数
@export var strike_count: int = 3

## 连锁目标数量
@export var chain_count: int = 2

## 连锁范围
@export var chain_range: float = 120.0

## 连锁伤害衰减
@export var chain_damage_decay: float = 0.25

## 眩晕概率
@export_range(0.0, 1.0) var stun_chance: float = 0.3

## 眩晕持续时间
@export var stun_duration: float = 0.5

## 闪电间隔
@export var strike_interval: float = 0.2

## 是否优先攻击不同目标
@export var prefer_different_targets: bool = true

# =============================================================================
# 内部变量
# =============================================================================

var _struck_targets: Array[Node] = []

# =============================================================================
# 初始化
# =============================================================================

func _init() -> void:
	skill_id = "lightning_storm"
	skill_name = "闪电风暴"
	description = "召唤闪电风暴，在随机敌人位置降下闪电并连锁攻击多个目标。"
	skill_type = SkillType.ACTIVE
	skill_category = SkillCategory.OFFENSIVE
	target_type = TargetType.AREA
	element = SkillElement.LIGHTNING
	hotkey_slot = 2

	base_damage = 28.0
	base_cooldown = 6.0
	base_mana_cost = 40.0
	effect_range = 150.0
	duration = 2.0


# =============================================================================
# 技能效果
# =============================================================================

func _execute_area_effect(position: Variant) -> void:
	"""
	执行闪电风暴效果
	"""
	if owner_node == null:
		return

	_struck_targets.clear()

	# 获取所有敌人
	var enemies: Array[Node] = owner_node.get_tree().get_nodes_in_group("enemies")
	var valid_enemies: Array[Node] = []

	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.has_method("take_damage"):
			valid_enemies.append(enemy)

	if valid_enemies.is_empty():
		return

	# 播放开始音效
	AudioManager.play_sfx("lightning_storm_start")

	# 执行多次闪电
	for i in range(get_strike_count()):
		await owner_node.get_tree().create_timer(strike_interval).timeout

		# 选择目标
		var target: Node = _select_strike_target(valid_enemies, i)
		if target == null:
			target = valid_enemies.pick_random()

		if target:
			_execute_lightning_strike(target, get_damage())
			_struck_targets.append(target)

			# 移除已攻击的目标（如果优先不同目标）
			if prefer_different_targets and valid_enemies.size() > get_strike_count() - i:
				valid_enemies.erase(target)


func _select_strike_target(enemies: Array[Node], strike_index: int) -> Node:
	"""
	选择闪电攻击目标
	"""
	if enemies.is_empty():
		return null

	# 优先选择未攻击过的目标
	if prefer_different_targets:
		for enemy in enemies:
			if enemy not in _struck_targets:
				return enemy

	# 随机选择
	return enemies.pick_random()


func _execute_lightning_strike(target: Node, damage: float) -> void:
	"""
	执行单次闪电攻击
	"""
	if target == null or owner_node == null:
		return

	# 播放闪电音效
	AudioManager.play_sfx("lightning_strike")

	# 创建闪电视觉效果
	_create_lightning_visual(target.global_position)

	# 造成伤害
	if target.has_method("take_damage"):
		target.take_damage(damage, owner_node)
		skill_hit.emit(self, target, damage)

	# VFX: lightning storm hit spark
	if VFXManager:
		VFXManager.spawn_effect("hit_spark", target.global_position, {"color": Color(0.7, 0.9, 1.0)})

	# 应用眩晕
	if randf() < get_stun_chance():
		if target.has_method("apply_stun"):
			target.apply_stun(get_stun_duration())

	# 连锁攻击
	_execute_chain_lightning(target, damage, 0)


func _execute_chain_lightning(source: Node, damage: float, chain_level: int) -> void:
	"""
	执行连锁闪电
	"""
	if chain_level >= get_chain_count():
		return

	# 寻找附近目标
	var next_targets: Array[Node] = _find_nearby_targets(source.global_position, chain_level + 1)

	if next_targets.is_empty():
		return

	# 选择连锁目标
	var next_target: Node = next_targets[0]

	# 计算连锁伤害
	var chain_damage: float = damage * (1.0 - chain_damage_decay * (chain_level + 1))

	# 延迟一点执行连锁
	await owner_node.get_tree().create_timer(0.08).timeout

	# 创建连锁闪电视觉
	_create_chain_lightning_visual(source.global_position, next_target.global_position)

	# 造成伤害
	if next_target.has_method("take_damage"):
		next_target.take_damage(chain_damage, owner_node)
		skill_hit.emit(self, next_target, chain_damage)

	# 应用眩晕
	if randf() < get_stun_chance() * 0.5:
		if next_target.has_method("apply_stun"):
			next_target.apply_stun(get_stun_duration() * 0.5)

	# 继续连锁
	_execute_chain_lightning(next_target, chain_damage, chain_level + 1)


func _find_nearby_targets(from_pos: Vector2, chain_level: int) -> Array[Node]:
	"""
	寻找附近的连锁目标
	"""
	var targets: Array[Node] = []

	if owner_node == null:
		return targets

	var space_state: PhysicsDirectSpaceState2D = owner_node.get_world_2d().direct_space_state
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = get_chain_range()
	query.shape = shape
	query.transform = Transform2D(0, from_pos)
	query.collision_mask = 2  # Enemy layer

	var results: Array[Dictionary] = space_state.intersect_shape(query, 32)

	for result in results:
		var collider: Node = result.get("collider")
		if collider and collider.has_method("take_damage") and collider not in _struck_targets:
			targets.append(collider)

	return targets


func _create_lightning_visual(pos: Vector2) -> void:
	"""
	创建主闪电视觉效果
	"""
	if owner_node == null:
		return

	# 创建从天而降的闪电
	var lightning_container: Node2D = Node2D.new()
	lightning_container.global_position = pos

	# 主闪电
	var main_bolt: Line2D = Line2D.new()
	main_bolt.width = 4.0
	main_bolt.default_color = Color(1.0, 1.0, 0.5)
	main_bolt.z_index = 20

	# 生成锯齿状闪电
	var start_y: float = -300.0
	var end_y: float = 0.0
	var segments: int = 8
	var bolt_points: Array[Vector2] = []

	for i in range(segments + 1):
		var t: float = float(i) / segments
		var y: float = lerp(start_y, end_y, t)
		var x: float = randf_range(-15, 15) if i > 0 and i < segments else 0.0
		bolt_points.append(Vector2(x, y))

	for point in bolt_points:
		main_bolt.add_point(point)

	lightning_container.add_child(main_bolt)

	# 发光效果
	var glow_bolt: Line2D = main_bolt.duplicate()
	glow_bolt.width = 10.0
	glow_bolt.default_color = Color(0.5, 0.7, 1.0, 0.5)
	glow_bolt.z_index = 19
	lightning_container.add_child(glow_bolt)

	# 击中点光效
	var impact_light: PointLight2D = PointLight2D.new()
	impact_light.color = Color(0.7, 0.8, 1.0)
	impact_light.energy = 2.0
	impact_light.texture = null  # 使用默认
	lightning_container.add_child(impact_light)

	owner_node.get_tree().current_scene.add_child(lightning_container)

	# 闪烁并消失
	var tween: Tween = owner_node.create_tween()
	for i in range(3):
		tween.tween_property(main_bolt, "modulate:a", 0.3, 0.03)
		tween.tween_property(main_bolt, "modulate:a", 1.0, 0.03)
	tween.tween_property(lightning_container, "modulate:a", 0.0, 0.15)
	tween.tween_callback(lightning_container.queue_free)


func _create_chain_lightning_visual(from_pos: Vector2, to_pos: Vector2) -> void:
	"""
	创建连锁闪电视觉效果
	"""
	if owner_node == null:
		return

	var chain: Line2D = Line2D.new()
	chain.width = 2.0
	chain.default_color = Color(0.7, 0.8, 1.0)
	chain.z_index = 18

	# 生成锯齿状路径
	var segments: int = 5
	for i in range(segments + 1):
		var t: float = float(i) / segments
		var point: Vector2 = from_pos.lerp(to_pos, t)
		if i > 0 and i < segments:
			point += Vector2(randf_range(-10, 10), randf_range(-10, 10))
		chain.add_point(point)

	owner_node.get_tree().current_scene.add_child(chain)

	# 快速消失
	var tween: Tween = owner_node.create_tween()
	tween.tween_property(chain, "modulate:a", 0.0, 0.2)
	tween.tween_callback(chain.queue_free)


# =============================================================================
# 属性获取
# =============================================================================

func get_strike_count() -> int:
	"""
	获取闪电攻击次数（受等级影响）
	"""
	return strike_count + (current_level - 1)


func get_chain_count() -> int:
	"""
	获取连锁目标数量（受等级影响）
	"""
	return chain_count + (current_level - 1)


func get_chain_range() -> float:
	"""
	获取连锁范围（受等级影响）
	"""
	return chain_range * (1.0 + (current_level - 1) * 0.15)


func get_stun_chance() -> float:
	"""
	获取眩晕概率（受等级影响）
	"""
	return stun_chance + (current_level - 1) * 0.1


func get_stun_duration() -> float:
	"""
	获取眩晕时间（受等级影响）
	"""
	return stun_duration * (1.0 + (current_level - 1) * 0.2)


# =============================================================================
# 升级效果
# =============================================================================

func _on_level_up(new_level: int) -> void:
	"""
	升级时增强闪电风暴
	"""
	match new_level:
		2:
			strike_count = 4
			chain_count = 3
		3:
			strike_count = 5
			chain_count = 4
			chain_damage_decay = 0.2
			stun_chance = 0.5
