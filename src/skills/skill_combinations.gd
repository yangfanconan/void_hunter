## Void Hunter - 技能组合系统
## @description: 管理技能的组合和协同效果
## @author: Void Hunter Team
## @version: 1.0.0

extends Resource
class_name SkillCombinations

# =============================================================================
# 信号定义
# =============================================================================

## 组合激活时触发
signal combination_activated(combination_id: String, combination_data: Dictionary)

## 组合取消时触发
signal combination_deactivated(combination_id: String)

## 组合技能使用时触发
signal combination_skill_used(combination_id: String, skill_data: Dictionary)

# =============================================================================
# 常量定义
# =============================================================================

## 组合配置文件路径
const COMBINATIONS_PATH: String = "res://data/skill_combinations.json"

## 组合触发时间窗口（秒）
const COMBO_WINDOW: float = 2.0

# =============================================================================
# 枚举定义
# =============================================================================

## 组合类型
enum CombinationType {
	BUFF,			## 增益型组合
	SKILL,			## 新技能型组合
	PASSIVE,		## 被动型组合
	ULTIMATE		## 终极技能型组合
}

## 组合技能稀有度
enum CombinationRarity {
	COMMON,			## 普通组合
	RARE,			## 稀有组合
	EPIC,			## 史诗组合
	LEGENDARY		## 传说组合
}

# =============================================================================
# 公共变量
# =============================================================================

## 所有组合数据
var combinations: Dictionary = {}

## 当前激活的组合
var active_combinations: Array[String] = []

## 玩家拥有的技能列表
var owned_skills: Array[String] = []

## 组合技能列表（激活后可用的组合技能）
var combination_skills: Array[Dictionary] = []

# =============================================================================
# 私有变量
# =============================================================================

var _is_loaded: bool = false
var _last_skill_used: String = ""
var _last_skill_time: float = 0.0
var _owner_node: Node = null

# =============================================================================
# 初始化
# =============================================================================

## 初始化组合系统
func initialize(owner: Node) -> void:
	"""
	初始化技能组合系统
	@param owner: 技能持有者
	"""
	_owner_node = owner
	load_combinations()


# =============================================================================
# 公共方法 - 加载
# =============================================================================

## 加载组合数据
func load_combinations() -> bool:
	"""
	加载技能组合配置
	@return: 是否成功加载
	"""
	if _is_loaded:
		return true
	
	# 直接加载默认组合配置
	_load_default_combinations()
	_is_loaded = true
	
	return true


## 添加技能
func add_skill(skill_id: String) -> void:
	"""
	添加技能到已拥有列表
	@param skill_id: 技能ID
	"""
	if skill_id in owned_skills:
		return
	
	owned_skills.append(skill_id)
	_check_combinations()


## 移除技能
func remove_skill(skill_id: String) -> void:
	"""
	从已拥有列表移除技能
	@param skill_id: 技能ID
	"""
	if skill_id not in owned_skills:
		return
	
	owned_skills.erase(skill_id)
	_check_combinations()


## 记录技能使用（用于检测连续技能组合）
func record_skill_use(skill_id: String) -> void:
	"""
	记录技能使用
	@param skill_id: 使用的技能ID
	"""
	var current_time: float = Time.get_ticks_msec() / 1000.0
	
	# 检查是否在组合窗口内
	if current_time - _last_skill_time <= COMBO_WINDOW:
		# 检查是否有组合
		_check_instant_combination(_last_skill_used, skill_id)
	
	_last_skill_used = skill_id
	_last_skill_time = current_time


# =============================================================================
# 公共方法 - 查询
# =============================================================================

## 检查组合是否激活
func is_combination_active(combination_id: String) -> bool:
	"""
	检查指定组合是否激活
	@param combination_id: 组合ID
	@return: 是否激活
	"""
	return combination_id in active_combinations


## 获取组合数据
func get_combination(combination_id: String) -> Dictionary:
	"""
	获取组合数据
	@param combination_id: 组合ID
	@return: 组合数据
	"""
	if not _is_loaded:
		load_combinations()
	
	return combinations.get(combination_id, {})


## 获取所有激活的组合
func get_active_combinations() -> Array[Dictionary]:
	"""
	获取所有激活的组合数据
	@return: 组合数据数组
	"""
	var result: Array[Dictionary] = []
	
	for combination_id in active_combinations:
		var data: Dictionary = get_combination(combination_id)
		if not data.is_empty():
			result.append(data)
	
	return result


## 获取可用组合技能列表
func get_available_combination_skills() -> Array[Dictionary]:
	"""
	获取当前可用的组合技能
	@return: 组合技能数组
	"""
	return combination_skills.duplicate()


## 计算组合加成
func calculate_combination_bonuses() -> Dictionary:
	"""
	计算所有激活组合的加成
	@return: 加成字典
	"""
	var bonuses: Dictionary = {
		"damage_multiplier": 1.0,
		"defense_multiplier": 1.0,
		"speed_multiplier": 1.0,
		"cooldown_reduction": 0.0,
		"critical_chance_bonus": 0.0,
		"critical_damage_bonus": 0.0,
		"heal_bonus": 0.0
	}
	
	for combination_id in active_combinations:
		var data: Dictionary = get_combination(combination_id)
		var combination_bonuses: Dictionary = data.get("bonuses", {})
		
		for stat_name in combination_bonuses.keys():
			if bonuses.has(stat_name):
				bonuses[stat_name] += combination_bonuses[stat_name]
	
	return bonuses


## 获取可能的组合提示
func get_combination_hints() -> Array[Dictionary]:
	"""
	获取可能的组合提示（用于UI显示）
	@return: 组合提示数组
	"""
	var hints: Array[Dictionary] = []
	
	for combination_id in combinations.keys():
		var data: Dictionary = combinations[combination_id]
		var required: Array = data.get("required_skills", [])
		
		# 检查是否已经拥有部分所需技能
		var owned_count: int = 0
		for skill_id in required:
			if skill_id in owned_skills:
				owned_count += 1
		
		if owned_count > 0 and owned_count < required.size():
			hints.append({
				"combination_id": combination_id,
				"name": data.get("name", ""),
				"description": data.get("description", ""),
				"owned_count": owned_count,
				"required_count": required.size(),
				"missing_skills": _get_missing_skills(required)
			})
	
	return hints


# =============================================================================
# 组合技能执行
# =============================================================================

## 执行组合技能
func execute_combination_skill(combination_id: String, target_position: Vector2 = Vector2.ZERO) -> bool:
	"""
	执行组合技能
	@param combination_id: 组合ID
	@param target_position: 目标位置
	@return: 是否成功执行
	"""
	if not is_combination_active(combination_id):
		return false
	
	var data: Dictionary = get_combination(combination_id)
	if data.is_empty():
		return false
	
	# 根据组合类型执行效果
	match combination_id:
		"fire_ice_combo":
			_execute_frost_fire(data, target_position)
		"lightning_shadow_combo":
			_execute_shadow_lightning(data, target_position)
		"shield_reflect_combo":
			_execute_mirror_shield(data)
		"time_gravity_combo":
			_execute_space_time_hole(data, target_position)
		"heal_speed_combo":
			_execute_divine_blessing(data)
		"fire_lightning_combo":
			_execute_storm_fire(data, target_position)
		# 新增弹幕组合技能
		"fan_homing_combo":
			_execute_homing_fan(data, target_position)
		"circular_lightning_combo":
			_execute_lightning_circular(data, target_position)
		"laser_nuke_combo":
			_execute_destruction_ray(data, target_position)
		"ultimate_trinity":
			_execute_ultimate_trinity(data, target_position)
		_:
			return false
	
	combination_skill_used.emit(combination_id, data)
	return true


# =============================================================================
# 组合技能实现
# =============================================================================

func _execute_frost_fire(data: Dictionary, target_pos: Vector2) -> void:
	"""
	执行冰霜火焰组合技能
	效果：范围减速 + 持续火焰伤害
	"""
	if _owner_node == null:
		return
	
	var radius: float = data.get("effect_range", 150.0)
	var damage: float = data.get("damage", 30.0)
	var slow_percent: float = data.get("slow_percent", 0.5)
	var burn_damage: float = data.get("burn_damage", 10.0)
	var duration: float = data.get("duration", 4.0)
	
	# 获取范围内的敌人
	var space_state: PhysicsDirectSpaceState2D = _owner_node.get_world_2d().direct_space_state
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = radius
	query.shape = shape
	query.transform = Transform2D(0, target_pos if target_pos != Vector2.ZERO else _owner_node.global_position)
	query.collision_mask = 2  # Enemy layer
	
	var results: Array[Dictionary] = space_state.intersect_shape(query, 32)
	
	for result in results:
		var enemy: Node = result.get("collider")
		if enemy and enemy.has_method("take_damage"):
			# 造成伤害
			enemy.take_damage(damage, _owner_node)
			
			# 应用减速
			if "speed_modifier" in enemy:
				enemy.speed_modifier = 1.0 - slow_percent
			
			# 应用燃烧
			if enemy.has_method("apply_burn"):
				enemy.apply_burn(burn_damage, duration, _owner_node)
	
	# 创建视觉效果
	_create_combo_visual("frost_fire", target_pos if target_pos != Vector2.ZERO else _owner_node.global_position, radius)


func _execute_shadow_lightning(data: Dictionary, target_pos: Vector2) -> void:
	"""
	执行暗影闪电组合技能
	效果：穿透 + 连锁攻击
	"""
	if _owner_node == null:
		return
	
	var damage: float = data.get("damage", 40.0)
	var chain_count: int = data.get("chain_count", 5)
	var pierce: bool = data.get("pierce", true)
	var stun_chance: float = data.get("stun_chance", 0.4)
	
	var origin: Vector2 = _owner_node.global_position
	var direction: Vector2 = (target_pos - origin).normalized() if target_pos != Vector2.ZERO else Vector2.RIGHT
	
	# 创建暗影闪电投射物
	_create_shadow_lightning_projectile(origin, direction, damage, chain_count, stun_chance)


func _execute_mirror_shield(data: Dictionary) -> void:
	"""
	执行镜像护盾组合技能
	效果：护盾 + 反弹
	"""
	if _owner_node == null:
		return
	
	var shield_health: float = data.get("shield_health", 100.0)
	var reflect_percent: float = data.get("reflect_percent", 0.5)
	var duration: float = data.get("duration", 6.0)
	
	# 应用护盾和反射效果
	if "stats" in _owner_node:
		var stats: PlayerStats = _owner_node.stats
		if stats:
			# 添加临时护盾
			stats.add_flat_bonus("health", shield_health)
	
	# 创建镜像护盾视觉效果
	_create_mirror_shield_visual(duration)


func _execute_space_time_hole(data: Dictionary, target_pos: Vector2) -> void:
	"""
	执行时空黑洞组合技能
	效果：强控制 + 聚怪
	"""
	if _owner_node == null:
		return
	
	var radius: float = data.get("effect_range", 180.0)
	var pull_force: float = data.get("pull_force", 300.0)
	var damage: float = data.get("damage", 15.0)
	var duration: float = data.get("duration", 5.0)
	
	# 创建时空黑洞
	_create_space_time_hole(
		target_pos if target_pos != Vector2.ZERO else _owner_node.global_position,
		radius,
		pull_force,
		damage,
		duration
	)


func _execute_divine_blessing(data: Dictionary) -> void:
	"""
	执行神圣祝福组合技能
	效果：双重增益（治疗 + 加速）
	"""
	if _owner_node == null:
		return
	
	var heal_amount: float = data.get("heal_amount", 50.0)
	var speed_bonus: float = data.get("speed_bonus", 0.3)
	var attack_bonus: float = data.get("attack_bonus", 0.2)
	var duration: float = data.get("duration", 8.0)
	
	# 立即治疗
	if _owner_node.has_method("heal"):
		_owner_node.heal(heal_amount)
	elif "stats" in _owner_node:
		var stats: PlayerStats = _owner_node.stats
		if stats:
			stats.heal(heal_amount)
	
	# 应用增益
	_apply_divine_blessing_buff(speed_bonus, attack_bonus, duration)


func _execute_storm_fire(data: Dictionary, target_pos: Vector2) -> void:
	"""
	执行雷火风暴组合技能
	效果：AOE爆发伤害
	"""
	if _owner_node == null:
		return
	
	var radius: float = data.get("effect_range", 200.0)
	var damage: float = data.get("damage", 60.0)
	var chain_damage: float = data.get("chain_damage", 20.0)
	var burn_damage: float = data.get("burn_damage", 15.0)
	
	var center: Vector2 = target_pos if target_pos != Vector2.ZERO else _owner_node.global_position
	
	# 获取范围内的敌人
	var space_state: PhysicsDirectSpaceState2D = _owner_node.get_world_2d().direct_space_state
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = radius
	query.shape = shape
	query.transform = Transform2D(0, center)
	query.collision_mask = 2  # Enemy layer
	
	var results: Array[Dictionary] = space_state.intersect_shape(query, 32)
	
	for result in results:
		var enemy: Node = result.get("collider")
		if enemy and enemy.has_method("take_damage"):
			# 造成主伤害
			enemy.take_damage(damage, _owner_node)
			
			# 应用燃烧
			if enemy.has_method("apply_burn"):
				enemy.apply_burn(burn_damage, 3.0, _owner_node)
			
			# 随机连锁到其他敌人
			if randf() < 0.5:
				_chain_storm_damage(enemy, chain_damage, 2)
	
	# 创建雷火风暴视觉效果
	_create_storm_fire_visual(center, radius)


# =============================================================================
# 私有方法 - 组合检测
# =============================================================================

func _check_combinations() -> void:
	"""
	检查所有组合是否满足条件
	"""
	if not _is_loaded:
		load_combinations()
	
	for combination_id in combinations.keys():
		var data: Dictionary = combinations[combination_id]
		
		# 检查主组合条件
		var is_satisfied: bool = _check_required_skills(data.get("required_skills", []))
		
		# 如果主条件不满足，检查替代组合条件
		if not is_satisfied and data.has("alternative_skills"):
			for alt_skills in data.get("alternative_skills", []):
				if _check_required_skills(alt_skills):
					is_satisfied = true
					break
		
		var was_active: bool = combination_id in active_combinations
		
		if is_satisfied and not was_active:
			# 激活组合
			active_combinations.append(combination_id)
			combination_activated.emit(combination_id, data)
			
			# 如果是技能型或终极技能型组合，添加到组合技能列表
			var combo_type: String = data.get("type", "buff")
			if combo_type == "skill" or combo_type == "ultimate":
				combination_skills.append(data)
		elif not is_satisfied and was_active:
			# 取消组合
			active_combinations.erase(combination_id)
			combination_deactivated.emit(combination_id)
			
			# 从组合技能列表移除
			for i in range(combination_skills.size() - 1, -1, -1):
				if combination_skills[i].get("combination_id", "") == combination_id:
					combination_skills.remove_at(i)


func _check_required_skills(required_skills: Array) -> bool:
	"""
	检查一组技能是否全部拥有
	"""
	for skill_id in required_skills:
		if skill_id not in owned_skills:
			return false
	return true


func _check_instant_combination(skill1: String, skill2: String) -> void:
	"""
	检查即时组合（连续使用两个技能触发）
	@param skill1: 第一个技能ID
	@param skill2: 第二个技能ID
	"""
	# 检查是否满足任何即时组合条件
	# 例如：火焰弹 -> 冰霜箭 = 冰霜火焰
	var combo_key: String = skill1 + "_" + skill2
	var reverse_key: String = skill2 + "_" + skill1
	
	# 触发对应的组合效果
	# 这里可以添加更多的即时组合逻辑


func _get_missing_skills(required: Array) -> Array[String]:
	"""
	获取缺失的技能列表
	@param required: 需要的技能列表
	@return: 缺失的技能列表
	"""
	var missing: Array[String] = []
	for skill_id in required:
		if skill_id not in owned_skills:
			missing.append(skill_id)
	return missing


# =============================================================================
# 私有方法 - 辅助效果
# =============================================================================

func _create_combo_visual(combo_type: String, pos: Vector2, radius: float) -> void:
	"""
	创建组合技能视觉效果
	"""
	if _owner_node == null:
		return
	
	var visual: Node2D = Node2D.new()
	visual.global_position = pos
	
	match combo_type:
		"frost_fire":
			visual.modulate = Color(0.5, 0.3, 1.0, 0.6)
		"storm_fire":
			visual.modulate = Color(1.0, 0.5, 0.2, 0.7)
		_:
			visual.modulate = Color(1.0, 1.0, 1.0, 0.5)
	
	_owner_node.get_tree().current_scene.add_child(visual)
	
	# 淡出效果
	var tween: Tween = _owner_node.create_tween()
	tween.tween_property(visual, "modulate:a", 0.0, 1.0)
	tween.tween_callback(visual.queue_free)


func _create_shadow_lightning_projectile(origin: Vector2, direction: Vector2, damage: float, chain_count: int, stun_chance: float) -> void:
	"""
	创建暗影闪电投射物：穿透敌人并连锁攻击
	"""
	if _owner_node == null:
		return
	
	var projectile: Area2D = Area2D.new()
	projectile.name = "ShadowLightning"
	
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 10.0
	collision.shape = shape
	projectile.add_child(collision)
	
	var sprite: Sprite2D = Sprite2D.new()
	var texture: ImageTexture = ImageTexture.new()
	var image: Image = Image.create(20, 20, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.4, 0.2, 0.8))  # 暗影紫色
	texture.set_image(image)
	sprite.texture = texture
	projectile.add_child(sprite)
	
	var script: GDScript = GDScript.new()
	script.source_code = """
extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 500.0
var damage: float = 40.0
var chain_count: int = 5
var stun_chance: float = 0.4
var owner_node: Node = null
var lifetime: float = 3.0
var hit_enemies: Array = []
var pierce_remaining: int = -1

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
	position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	if body == owner_node:
		return
	if body in hit_enemies:
		return
	_apply_hit(body)

func _on_area_entered(area: Node) -> void:
	if area.get_parent() == owner_node:
		return
	var parent = area.get_parent()
	if parent in hit_enemies:
		return
	_apply_hit(parent)

func _apply_hit(target: Node) -> void:
	hit_enemies.append(target)
	if target.has_method("take_damage"):
		target.take_damage(damage, owner_node)
	
	# 眩晕
	if randf() < stun_chance and target.has_method("apply_stun"):
		target.apply_stun(0.5)
	
	# 连锁闪电
	_execute_chain(target)
	
	# 穿透：不销毁
	if pierce_remaining == 0:
		queue_free()
	elif pierce_remaining > 0:
		pierce_remaining -= 1

func _execute_chain(source: Node) -> void:
	var remaining: int = chain_count
	var current: Node = source
	while remaining > 0:
		var enemies: Array = get_tree().get_nodes_in_group("enemies")
		var closest: Node = null
		var closest_dist: float = 150.0
		for enemy in enemies:
			if enemy in hit_enemies or not is_instance_valid(enemy):
				continue
			var dist: float = current.global_position.distance_to(enemy.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest = enemy
		if closest == null:
			break
		closest.take_damage(damage * 0.5, owner_node)
		hit_enemies.append(closest)
		_create_chain_visual(current.global_position, closest.global_position)
		current = closest
		remaining -= 1

func _create_chain_visual(from: Vector2, to: Vector2) -> void:
	var line: Line2D = Line2D.new()
	line.add_point(from)
	line.add_point(to)
	line.width = 2.0
	line.default_color = Color(0.5, 0.3, 0.9, 0.8)
	get_tree().current_scene.add_child(line)
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.2)
	tween.tween_callback(line.queue_free)
"""
	script.reload()
	projectile.set_script(script)
	
	projectile.set("direction", direction)
	projectile.set("speed", 500.0)
	projectile.set("damage", damage)
	projectile.set("chain_count", chain_count)
	projectile.set("stun_chance", stun_chance)
	projectile.set("owner_node", _owner_node)
	projectile.set("lifetime", 3.0)
	projectile.set("pierce_remaining", -1)  # 无限穿透
	
	projectile.global_position = origin
	projectile.collision_layer = 4
	projectile.collision_mask = 2 | 16
	
	_owner_node.get_tree().current_scene.add_child(projectile)


func _create_mirror_shield_visual(duration: float) -> void:
	"""
	创建镜像护盾视觉效果：环绕玩家的反射护盾
	"""
	if _owner_node == null:
		return
	
	var shield_container: Node2D = Node2D.new()
	shield_container.name = "MirrorShieldVisual"
	
	# 创建多个镜像护盾碎片环绕玩家
	var shard_count: int = 6
	for i in range(shard_count):
		var shard: Sprite2D = Sprite2D.new()
		var texture: ImageTexture = ImageTexture.new()
		var image: Image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
		image.fill(Color(0.3, 0.6, 1.0, 0.8))
		texture.set_image(image)
		shard.texture = texture
		var angle: float = (TAU / shard_count) * i
		shard.position = Vector2(cos(angle), sin(angle)) * 40.0
		shard.modulate = Color(0.3, 0.7, 1.0, 0.7)
		shield_container.add_child(shard)
	
	_owner_node.add_child(shield_container)
	
	# 旋转动画
	var rotate_tween: Tween = _owner_node.create_tween()
	rotate_tween.set_loops()
	rotate_tween.tween_property(shield_container, "rotation", TAU, 3.0)
	
	# 持续时间后移除
	await _owner_node.get_tree().create_timer(duration).timeout
	
	if is_instance_valid(shield_container):
		var fade_tween: Tween = _owner_node.create_tween()
		fade_tween.tween_property(shield_container, "modulate:a", 0.0, 0.3)
		fade_tween.tween_callback(shield_container.queue_free)


func _create_space_time_hole(pos: Vector2, radius: float, pull_force: float, damage: float, duration: float) -> void:
	"""
	创建时空黑洞：持续拉扯并伤害范围内的敌人
	"""
	if _owner_node == null:
		return
	
	var blackhole: Node2D = Node2D.new()
	blackhole.name = "SpaceTimeHole"
	blackhole.global_position = pos
	
	# 黑洞视觉效果 - 多层圆环
	for layer in range(3):
		var ring: Sprite2D = Sprite2D.new()
		var texture: ImageTexture = ImageTexture.new()
		var size: int = int(radius * 2 * (0.4 + layer * 0.3))
		var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
		var color: Color = Color(0.2, 0.1, 0.5, 0.6 - layer * 0.15)
		image.fill(color)
		texture.set_image(image)
		ring.texture = texture
		blackhole.add_child(ring)
	
	_owner_node.get_tree().current_scene.add_child(blackhole)
	
	# 旋转动画
	var rotate_tween: Tween = _owner_node.create_tween()
	rotate_tween.set_loops()
	rotate_tween.tween_property(blackhole, "rotation", TAU, 1.5)
	
	# 创建伤害区域
	var damage_area: Area2D = Area2D.new()
	damage_area.collision_layer = 0
	damage_area.collision_mask = 2
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = radius
	collision.shape = shape
	damage_area.add_child(collision)
	_owner_node.get_tree().current_scene.add_child(damage_area)
	damage_area.global_position = pos
	
	# 持续效果
	var elapsed: float = 0.0
	var tick_interval: float = 0.5
	var tick_timer: float = 0.0
	var affected: Array[WeakRef] = []
	
	while elapsed < duration:
		await _owner_node.get_tree().create_timer(0.1).timeout
		elapsed += 0.1
		tick_timer += 0.1
		
		# 拉扯和伤害
		var bodies: Array[Node2D] = []
		var space_state: PhysicsDirectSpaceState2D = _owner_node.get_world_2d().direct_space_state
		var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
		query.shape = shape
		query.transform = Transform2D(0, pos)
		query.collision_mask = 2
		var results: Array[Dictionary] = space_state.intersect_shape(query, 32)
		
		for result in results:
			var enemy: Node = result.get("collider")
			if enemy and is_instance_valid(enemy):
				# 拉扯向中心
				var to_center: Vector2 = pos - enemy.global_position
				var dist: float = to_center.length()
				if dist > 5.0:
					var pull_dir: Vector2 = to_center.normalized()
					var pull_mult: float = clampf(dist / radius, 0.3, 1.0)
					enemy.global_position += pull_dir * pull_force * pull_mult * 0.1
				
				# 定时伤害
				if tick_timer >= tick_interval and enemy.has_method("take_damage"):
					enemy.take_damage(damage * tick_interval, _owner_node)
			
		tick_timer = fmod(tick_timer, tick_interval)
	
	# 消失效果
	if is_instance_valid(blackhole):
		var fade_tween: Tween = _owner_node.create_tween()
		fade_tween.tween_property(blackhole, "modulate:a", 0.0, 0.5)
		fade_tween.tween_callback(blackhole.queue_free)
	
	if is_instance_valid(damage_area):
		damage_area.queue_free()


func _apply_divine_blessing_buff(speed_bonus: float, attack_bonus: float, duration: float) -> void:
	"""
	应用神圣祝福增益：速度和攻击力提升
	"""
	if _owner_node == null:
		return
	
	# 应用速度加成
	if "stats" in _owner_node:
		var stats: PlayerStats = _owner_node.stats
		if stats:
			# 临时增加速度和攻击
			stats.add_flat_bonus("speed", stats.base_speed * speed_bonus)
			stats.add_flat_bonus("attack", stats.base_attack * attack_bonus)
	
	# 创建增益光环视觉
	var aura: Node2D = Node2D.new()
	aura.name = "DivineBlessingAura"
	aura.modulate = Color(1.0, 0.9, 0.3, 0.4)
	aura.z_index = -1
	
	var aura_sprite: Sprite2D = Sprite2D.new()
	var texture: ImageTexture = ImageTexture.new()
	var image: Image = Image.create(80, 80, false, Image.FORMAT_RGBA8)
	image.fill(Color(1.0, 0.85, 0.2, 0.3))
	texture.set_image(image)
	aura_sprite.texture = texture
	aura.add_child(aura_sprite)
	
	_owner_node.add_child(aura)
	
	# 脉冲动画
	var pulse_tween: Tween = _owner_node.create_tween()
	pulse_tween.set_loops()
	pulse_tween.tween_property(aura, "modulate:a", 0.2, 0.4)
	pulse_tween.tween_property(aura, "modulate:a", 0.5, 0.4)
	
	# 持续时间后移除增益和视觉
	await _owner_node.get_tree().create_timer(duration).timeout
	
	# 移除增益
	if "stats" in _owner_node:
		var stats: PlayerStats = _owner_node.stats
		if stats:
			stats.remove_flat_bonus("speed", stats.base_speed * speed_bonus)
			stats.remove_flat_bonus("attack", stats.base_attack * attack_bonus)
	
	# 移除视觉
	if is_instance_valid(aura):
		var fade_tween: Tween = _owner_node.create_tween()
		fade_tween.tween_property(aura, "modulate:a", 0.0, 0.3)
		fade_tween.tween_callback(aura.queue_free)


func _chain_storm_damage(source: Node, damage: float, remaining_chains: int) -> void:
	"""
	连锁雷火伤害
	"""
	if remaining_chains <= 0 or _owner_node == null:
		return
	
	# 寻找附近的敌人
	var targets: Array[Node] = _get_targets_in_area(source.global_position, 150.0)
	
	for target in targets:
		if target != source and target.has_method("take_damage"):
			target.take_damage(damage, _owner_node)
			_chain_storm_damage(target, damage * 0.7, remaining_chains - 1)
			break


func _get_targets_in_area(center: Vector2, radius: float) -> Array[Node]:
	"""
	获取区域内的目标
	"""
	var targets: Array[Node] = []
	
	if _owner_node == null:
		return targets
	
	var space_state: PhysicsDirectSpaceState2D = _owner_node.get_world_2d().direct_space_state
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = radius
	query.shape = shape
	query.transform = Transform2D(0, center)
	query.collision_mask = 2  # Enemy layer
	
	var results: Array[Dictionary] = space_state.intersect_shape(query, 32)
	
	for result in results:
		var collider: Node = result.get("collider")
		if collider and collider.has_method("take_damage"):
			targets.append(collider)
	
	return targets


func _create_storm_fire_visual(pos: Vector2, radius: float) -> void:
	"""
	创建雷火风暴视觉效果
	"""
	_create_combo_visual("storm_fire", pos, radius)


# =============================================================================
# 新增弹幕组合技能实现
# =============================================================================

func _execute_homing_fan(data: Dictionary, target_pos: Vector2) -> void:
	"""
	执行追踪扇形组合技能
	效果：扇形弹幕全部追踪敌人
	"""
	if _owner_node == null:
		return

	var bullet_count: int = data.get("bullet_count", 7)
	var spread_angle: float = deg_to_rad(data.get("spread_angle", 60.0))
	var damage: float = data.get("damage", 25.0)
	var homing_strength: float = data.get("homing_strength", 3.0)

	var direction: Vector2 = Vector2.RIGHT
	if target_pos != Vector2.ZERO:
		direction = (target_pos - _owner_node.global_position).normalized()

	var base_angle: float = direction.angle() - spread_angle / 2.0
	var angle_step: float = spread_angle / (bullet_count - 1) if bullet_count > 1 else 0.0

	for i in range(bullet_count):
		var angle: float = base_angle + angle_step * i
		var bullet_dir: Vector2 = Vector2(cos(angle), sin(angle))
		_create_homing_fan_bullet(bullet_dir, damage, homing_strength)

	_create_combo_visual("homing_fan", _owner_node.global_position, 100.0)
	AudioManager.play_sfx("fan_shot")


func _create_homing_fan_bullet(direction: Vector2, damage: float, homing_strength: float) -> void:
	"""
	创建追踪扇形子弹
	"""
	if _owner_node == null:
		return

	var bullet: Area2D = Area2D.new()
	bullet.name = "HomingFanBullet"

	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 6.0
	collision.shape = shape
	bullet.add_child(collision)

	var sprite: Sprite2D = Sprite2D.new()
	var texture: ImageTexture = ImageTexture.new()
	var image: Image = Image.create(12, 12, false, Image.FORMAT_RGBA8)
	image.fill(Color(1.0, 0.7, 0.3))  # 金橙色
	texture.set_image(image)
	sprite.texture = texture
	bullet.add_child(sprite)

	var script: GDScript = GDScript.new()
	script.source_code = """
extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 400.0
var damage: float = 25.0
var owner_node: Node = null
var lifetime: float = 3.0
var homing_strength: float = 3.0
var current_target: Node = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	find_target()

func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

	if current_target and is_instance_valid(current_target):
		var target_dir: Vector2 = (current_target.global_position - global_position).normalized()
		direction = direction.lerp(target_dir, homing_strength * delta).normalized()

	position += direction * speed * delta
	rotation = direction.angle()

func find_target() -> void:
	var enemies: Array = get_tree().get_nodes_in_group("enemies")
	var closest: Node = null
	var closest_dist: float = INF
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist: float = global_position.distance_to(enemy.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = enemy
	current_target = closest

func _on_body_entered(body: Node) -> void:
	if body == owner_node:
		return
	if body.has_method("take_damage"):
		body.take_damage(damage, owner_node)
	queue_free()

func _on_area_entered(area: Node) -> void:
	if area.get_parent() == owner_node:
		return
	var parent = area.get_parent()
	if parent.has_method("take_damage"):
		parent.take_damage(damage, owner_node)
	queue_free()
"""
	script.reload()
	bullet.set_script(script)

	bullet.set("direction", direction)
	bullet.set("speed", 400.0)
	bullet.set("damage", damage)
	bullet.set("owner_node", _owner_node)
	bullet.set("lifetime", 3.0)
	bullet.set("homing_strength", homing_strength)

	bullet.global_position = _owner_node.global_position + direction * 20.0
	bullet.collision_layer = 4
	bullet.collision_mask = 2 | 16

	_owner_node.get_tree().current_scene.add_child(bullet)


func _execute_lightning_circular(data: Dictionary, target_pos: Vector2) -> void:
	"""
	执行雷电风暴组合技能
	效果：圆形弹幕附带闪电链
	"""
	if _owner_node == null:
		return

	var bullet_count: int = data.get("bullet_count", 16)
	var damage: float = data.get("damage", 20.0)
	var chain_count: int = data.get("chain_count", 3)
	var chain_damage: float = data.get("chain_damage", 10.0)

	var angle_step: float = TAU / bullet_count

	for i in range(bullet_count):
		var angle: float = i * angle_step
		var direction: Vector2 = Vector2(cos(angle), sin(angle))
		_create_lightning_circular_bullet(direction, damage, chain_count, chain_damage)

	_create_combo_visual("lightning_circular", _owner_node.global_position, 150.0)
	AudioManager.play_sfx("circular_burst")


func _create_lightning_circular_bullet(direction: Vector2, damage: float, chain_count: int, chain_damage: float) -> void:
	"""
	创建雷电圆形子弹
	"""
	if _owner_node == null:
		return

	var bullet: Area2D = Area2D.new()
	bullet.name = "LightningCircularBullet"

	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 7.0
	collision.shape = shape
	bullet.add_child(collision)

	var sprite: Sprite2D = Sprite2D.new()
	var texture: ImageTexture = ImageTexture.new()
	var image: Image = Image.create(14, 14, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.5, 0.7, 1.0))  # 闪电蓝色
	texture.set_image(image)
	sprite.texture = texture
	bullet.add_child(sprite)

	var script: GDScript = GDScript.new()
	script.source_code = """
extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 350.0
var damage: float = 20.0
var chain_count: int = 3
var chain_damage: float = 10.0
var owner_node: Node = null
var lifetime: float = 3.0
var hit_enemies: Array = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
	position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	if body == owner_node:
		return
	if body.has_method("take_damage"):
		body.take_damage(damage, owner_node)
		hit_enemies.append(body)
		execute_chain(body)
	queue_free()

func _on_area_entered(area: Node) -> void:
	if area.get_parent() == owner_node:
		return
	var parent = area.get_parent()
	if parent.has_method("take_damage"):
		parent.take_damage(damage, owner_node)
		hit_enemies.append(parent)
		execute_chain(parent)
	queue_free()

func execute_chain(source: Node) -> void:
	var remaining: int = chain_count
	var current_source: Node = source
	while remaining > 0:
		var enemies: Array = get_tree().get_nodes_in_group("enemies")
		var closest: Node = null
		var closest_dist: float = 150.0
		for enemy in enemies:
			if enemy in hit_enemies or not is_instance_valid(enemy):
				continue
			var dist: float = current_source.global_position.distance_to(enemy.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest = enemy
		if closest == null:
			break
		closest.take_damage(chain_damage, owner_node)
		hit_enemies.append(closest)
		_create_chain_visual(current_source.global_position, closest.global_position)
		current_source = closest
		remaining -= 1

func _create_chain_visual(from: Vector2, to: Vector2) -> void:
	var line: Line2D = Line2D.new()
	line.add_point(from)
	line.add_point(to)
	line.width = 2.0
	line.default_color = Color(0.7, 0.8, 1.0, 0.8)
	get_tree().current_scene.add_child(line)
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.2)
	tween.tween_callback(line.queue_free)
"""
	script.reload()
	bullet.set_script(script)

	bullet.set("direction", direction)
	bullet.set("speed", 350.0)
	bullet.set("damage", damage)
	bullet.set("chain_count", chain_count)
	bullet.set("chain_damage", chain_damage)
	bullet.set("owner_node", _owner_node)
	bullet.set("lifetime", 3.0)

	bullet.global_position = _owner_node.global_position + direction * 15.0
	bullet.collision_layer = 4
	bullet.collision_mask = 2 | 16

	_owner_node.get_tree().current_scene.add_child(bullet)


func _execute_destruction_ray(data: Dictionary, target_pos: Vector2) -> void:
	"""
	执行毁灭光线组合技能
	效果：全屏激光扫射
	"""
	if _owner_node == null:
		return

	var damage: float = data.get("damage", 50.0)
	var beam_count: int = data.get("beam_count", 8)
	var duration: float = data.get("duration", 2.0)

	# 创建多条旋转激光
	for i in range(beam_count):
		var angle: float = (TAU / beam_count) * i
		_create_destruction_beam(angle, damage, duration)

	_create_combo_visual("destruction_ray", _owner_node.global_position, 500.0)
	AudioManager.play_sfx("laser_beam")


func _create_destruction_beam(angle: float, damage: float, duration: float) -> void:
	"""
	创建毁灭光线
	"""
	if _owner_node == null:
		return

	var beam: Node2D = Node2D.new()
	beam.name = "DestructionBeam"

	var line: Line2D = Line2D.new()
	line.width = 20.0
	line.default_color = Color(1.0, 0.3, 0.3, 0.6)
	line.z_index = 15
	line.add_point(Vector2.ZERO)
	line.add_point(Vector2(800, 0))
	beam.add_child(line)

	var core: Line2D = Line2D.new()
	core.width = 8.0
	core.default_color = Color(1.0, 1.0, 1.0, 0.9)
	core.z_index = 16
	core.add_point(Vector2.ZERO)
	core.add_point(Vector2(800, 0))
	beam.add_child(core)

	beam.global_position = _owner_node.global_position
	beam.rotation = angle

	_owner_node.get_tree().current_scene.add_child(beam)

	# 伤害检测
	var damage_timer: float = 0.0
	var damage_interval: float = 0.1

	while damage_timer < duration:
		await _owner_node.get_tree().create_timer(0.1).timeout
		damage_timer += 0.1

		# 持续伤害
		var dir: Vector2 = Vector2(cos(angle), sin(angle))
		var targets: Array[Node] = _get_targets_in_beam_path(dir, 800.0, 20.0)
		for target in targets:
			if target.has_method("take_damage"):
				target.take_damage(damage * 0.2, _owner_node)

	# 淡出
	var tween: Tween = _owner_node.create_tween()
	tween.tween_property(beam, "modulate:a", 0.0, 0.3)
	tween.tween_callback(beam.queue_free)


func _get_targets_in_beam_path(direction: Vector2, length: float, width: float) -> Array[Node]:
	"""
	获取激光路径上的目标
	"""
	var targets: Array[Node] = []

	if _owner_node == null:
		return targets

	var space_state: PhysicsDirectSpaceState2D = _owner_node.get_world_2d().direct_space_state
	var shape_query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(length, width)
	shape_query.shape = shape

	var rect_center: Vector2 = _owner_node.global_position + direction * length / 2
	shape_query.transform = Transform2D(direction.angle(), rect_center)
	shape_query.collision_mask = 2

	var results: Array[Dictionary] = space_state.intersect_shape(shape_query, 32)

	for result in results:
		var collider: Node = result.get("collider")
		if collider and collider.has_method("take_damage"):
			targets.append(collider)

	return targets


func _execute_ultimate_trinity(data: Dictionary, target_pos: Vector2) -> void:
	"""
	执行终极三合一技能
	效果：最强组合技，全屏毁灭
	"""
	if _owner_node == null:
		return

	var damage: float = data.get("damage", 100.0)
	var effect_duration: float = data.get("effect_duration", 3.0)

	# 播放音效
	AudioManager.play_sfx("nuke_explosion")

	# 全屏闪光
	var flash: ColorRect = ColorRect.new()
	flash.color = Color(1.0, 1.0, 1.0, 0.8)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.z_index = 100
	_owner_node.get_tree().current_scene.add_child(flash)

	var tween: Tween = _owner_node.create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.5)
	tween.tween_callback(flash.queue_free)

	# 对所有敌人造成伤害
	var enemies: Array[Node] = _owner_node.get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.has_method("take_damage"):
			enemy.take_damage(damage, _owner_node)
			# 创建爆炸效果
			_create_ultimate_explosion(enemy.global_position)

	# 创建终极视觉效果
	_create_ultimate_visual(effect_duration)


func _create_ultimate_explosion(pos: Vector2) -> void:
	"""
	创建终极爆炸效果
	"""
	if _owner_node == null:
		return

	var explosion: Node2D = Node2D.new()
	explosion.global_position = pos

	var sprite: Sprite2D = Sprite2D.new()
	var texture: ImageTexture = ImageTexture.new()
	var image: Image = Image.create(80, 80, false, Image.FORMAT_RGBA8)
	image.fill(Color(1.0, 0.6, 0.2, 0.8))
	texture.set_image(image)
	sprite.texture = texture
	sprite.modulate = Color(1.0, 0.5, 0.1)
	explosion.add_child(sprite)

	_owner_node.get_tree().current_scene.add_child(explosion)

	var tween: Tween = _owner_node.create_tween()
	tween.tween_property(sprite, "scale", Vector2(2.5, 2.5), 0.4)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.4)
	tween.tween_callback(explosion.queue_free)


func _create_ultimate_visual(duration: float) -> void:
	"""
	创建终极技能视觉效果
	"""
	if _owner_node == null:
		return

	# 创建能量环
	for i in range(5):
		await _owner_node.get_tree().create_timer(0.2).timeout
		var ring: Node2D = Node2D.new()
		ring.global_position = _owner_node.global_position

		var ring_sprite: Sprite2D = Sprite2D.new()
		var ring_texture: ImageTexture = ImageTexture.new()
		var ring_image: Image = Image.create(200, 200, false, Image.FORMAT_RGBA8)
		ring_image.fill(Color(0.5, 0.3, 1.0, 0.5))
		ring_texture.set_image(ring_image)
		ring_sprite.texture = ring_texture
		ring.add_child(ring_sprite)

		_owner_node.get_tree().current_scene.add_child(ring)

		var ring_tween: Tween = _owner_node.create_tween()
		ring_tween.tween_property(ring_sprite, "scale", Vector2(4.0, 4.0), 0.8)
		ring_tween.parallel().tween_property(ring_sprite, "modulate:a", 0.0, 0.8)
		ring_tween.tween_callback(ring.queue_free)


# =============================================================================
# 私有方法 - 加载配置
# =============================================================================

func _load_default_combinations() -> void:
	"""
	加载默认组合配置
	"""
	combinations = {
		# 火焰 + 冰霜 = 冰霜火焰
		"fire_ice_combo": {
			"name": "冰霜火焰",
			"description": "融合火焰与冰霜之力，造成范围减速和持续燃烧伤害。",
			"required_skills": ["fire_bullet", "frost_arrow"],
			"type": "skill",
			"effect_range": 150.0,
			"damage": 30.0,
			"slow_percent": 0.5,
			"burn_damage": 10.0,
			"duration": 4.0,
			"cooldown": 15.0,
			"bonuses": {
				"damage_multiplier": 0.15
			}
		},
		
		# 闪电 + 暗影 = 暗影闪电
		"lightning_shadow_combo": {
			"name": "暗影闪电",
			"description": "暗影与闪电的结合，攻击可穿透敌人并连锁攻击多个目标。",
			"required_skills": ["lightning_chain", "shadow_slash"],
			"type": "skill",
			"damage": 40.0,
			"chain_count": 5,
			"pierce": true,
			"stun_chance": 0.4,
			"cooldown": 12.0,
			"bonuses": {
				"critical_chance_bonus": 0.15
			}
		},
		
		# 护盾 + 反射 = 镜像护盾
		"shield_reflect_combo": {
			"name": "镜像护盾",
			"description": "强化护盾，同时获得反弹敌人攻击的能力。",
			"required_skills": ["shield", "reflect"],
			"type": "buff",
			"shield_health": 100.0,
			"reflect_percent": 0.5,
			"duration": 6.0,
			"bonuses": {
				"defense_multiplier": 0.25
			}
		},
		
		# 时间减缓 + 引力场 = 时空黑洞
		"time_gravity_combo": {
			"name": "时空黑洞",
			"description": "创造时空扭曲区域，将敌人强力拉向中心并造成持续伤害。",
			"required_skills": ["time_slow", "gravity_field"],
			"type": "skill",
			"effect_range": 180.0,
			"pull_force": 300.0,
			"damage": 15.0,
			"duration": 5.0,
			"cooldown": 20.0,
			"bonuses": {
				"cooldown_reduction": 0.1
			}
		},
		
		# 治愈 + 加速 = 神圣祝福
		"heal_speed_combo": {
			"name": "神圣祝福",
			"description": "获得神圣祝福，同时恢复生命和提升战斗能力。",
			"required_skills": ["healing_aura", "speed_aura"],
			"type": "buff",
			"heal_amount": 50.0,
			"speed_bonus": 0.3,
			"attack_bonus": 0.2,
			"duration": 8.0,
			"bonuses": {
				"heal_bonus": 0.3,
				"speed_multiplier": 0.15
			}
		},
		
		# 火焰 + 闪电 = 雷火风暴
		"fire_lightning_combo": {
			"name": "雷火风暴",
			"description": "召唤毁灭性的雷火风暴，对范围内敌人造成巨大伤害。",
			"required_skills": ["fire_bullet", "lightning_chain"],
			"type": "skill",
			"effect_range": 200.0,
			"damage": 60.0,
			"chain_damage": 20.0,
			"burn_damage": 15.0,
			"cooldown": 25.0,
			"bonuses": {
				"damage_multiplier": 0.25,
				"critical_damage_bonus": 0.3
			}
		},

		# ================== 新增弹幕组合 ==================

		# 扇形弹幕 + 追踪导弹 = 追踪扇形
		"fan_homing_combo": {
			"name": "追踪扇形",
			"description": "扇形弹幕全部获得追踪能力，自动锁定敌人。",
			"required_skills": ["fan_shot", "homing_missile"],
			"required_level": 2,
			"type": "skill",
			"bullet_count": 7,
			"spread_angle": 60.0,
			"damage": 25.0,
			"homing_strength": 3.0,
			"cooldown": 8.0,
			"rarity": "RARE",
			"bonuses": {
				"damage_multiplier": 0.2
			}
		},

		# 圆形弹幕 + 闪电风暴 = 雷电风暴
		"circular_lightning_combo": {
			"name": "雷电风暴",
			"description": "圆形弹幕附带闪电链效果，命中后连锁攻击附近敌人。",
			"required_skills": ["circular_burst", "lightning_storm"],
			"required_level": 2,
			"type": "skill",
			"bullet_count": 16,
			"damage": 20.0,
			"chain_count": 3,
			"chain_damage": 10.0,
			"cooldown": 10.0,
			"rarity": "RARE",
			"bonuses": {
				"critical_chance_bonus": 0.15
			}
		},

		# 激光束 + 全屏攻击 = 毁灭光线
		"laser_nuke_combo": {
			"name": "毁灭光线",
			"description": "释放全屏旋转激光，对路径上所有敌人造成毁灭性伤害。",
			"required_skills": ["laser_beam", "screen_nuke"],
			"required_level": 3,
			"type": "skill",
			"damage": 50.0,
			"beam_count": 8,
			"duration": 2.0,
			"cooldown": 30.0,
			"rarity": "EPIC",
			"bonuses": {
				"damage_multiplier": 0.35,
				"critical_damage_bonus": 0.4
			}
		},


		# ================== 终极技能 ==================

		# 任意三个弹幕技能 = 终极技能
		"ultimate_trinity": {
			"name": "终极裁决",
			"description": "融合三种弹幕力量，释放毁天灭地的终极攻击，对全屏敌人造成毁灭性伤害。",
			"required_skills": ["fan_shot", "circular_burst", "laser_beam"],
			"alternative_skills": [  # 替代组合
				["fan_shot", "homing_missile", "screen_nuke"],
				["circular_burst", "lightning_storm", "laser_beam"],
				["homing_missile", "lightning_storm", "screen_nuke"]
			],
			"required_level": 3,
			"type": "ultimate",
			"damage": 100.0,
			"effect_duration": 3.0,
			"cooldown": 60.0,
			"mana_cost": 100.0,
			"rarity": "LEGENDARY",
			"bonuses": {
				"damage_multiplier": 0.5,
				"critical_chance_bonus": 0.25,
				"critical_damage_bonus": 0.5
			}
		}
	}


# =============================================================================
# 序列化
# =============================================================================

## 序列化为字典
func to_dictionary() -> Dictionary:
	"""
	序列化技能组合状态
	@return: 数据字典
	"""
	return {
		"owned_skills": owned_skills,
		"active_combinations": active_combinations
	}


## 从字典加载
func from_dictionary(data: Dictionary) -> void:
	"""
	从字典加载技能组合状态
	@param data: 数据字典
	"""
	owned_skills = data.get("owned_skills", [])
	active_combinations = data.get("active_combinations", [])
