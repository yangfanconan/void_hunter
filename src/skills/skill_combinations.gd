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
	PASSIVE			## 被动型组合
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
		var required_skills: Array = data.get("required_skills", [])
		
		var is_satisfied: bool = true
		for skill_id in required_skills:
			if skill_id not in owned_skills:
				is_satisfied = false
				break
		
		var was_active: bool = combination_id in active_combinations
		
		if is_satisfied and not was_active:
			# 激活组合
			active_combinations.append(combination_id)
			combination_activated.emit(combination_id, data)
			
			# 如果是技能型组合，添加到组合技能列表
			if data.get("type", "buff") == "skill":
				combination_skills.append(data)
		elif not is_satisfied and was_active:
			# 取消组合
			active_combinations.erase(combination_id)
			combination_deactivated.emit(combination_id)
			
			# 从组合技能列表移除
			for i in range(combination_skills.size() - 1, -1, -1):
				if combination_skills[i].get("combination_id", "") == combination_id:
					combination_skills.remove_at(i)


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
	创建暗影闪电投射物
	"""
	# 实现投射物创建逻辑
	pass


func _create_mirror_shield_visual(duration: float) -> void:
	"""
	创建镜像护盾视觉效果
	"""
	# 实现护盾视觉效果
	pass


func _create_space_time_hole(pos: Vector2, radius: float, pull_force: float, damage: float, duration: float) -> void:
	"""
	创建时空黑洞
	"""
	# 实现黑洞创建逻辑
	pass


func _apply_divine_blessing_buff(speed_bonus: float, attack_bonus: float, duration: float) -> void:
	"""
	应用神圣祝福增益
	"""
	# 实现增益应用逻辑
	pass


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
}
