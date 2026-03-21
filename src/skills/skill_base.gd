## Void Hunter - 技能基类
## @description: 所有技能的基类，定义技能的基本属性和行为接口
## @author: Void Hunter Team
## @version: 1.0.0

extends Resource
class_name SkillBase

# =============================================================================
# 信号定义
# =============================================================================

## 技能使用时触发
signal skill_activated(skill: SkillBase)

## 技能冷却完成时触发
signal cooldown_finished(skill: SkillBase)

## 技能升级时触发
signal skill_upgraded(skill: SkillBase, new_level: int)

## 技能等级达到上限时触发
signal skill_maxed(skill: SkillBase)

## 技能效果触发时（用于触发型技能）
signal effect_triggered(skill: SkillBase, target: Node)

## 技能命中目标时
signal skill_hit(skill: SkillBase, target: Node, damage: float)

# =============================================================================
# 常量定义
# =============================================================================

## 最大技能等级
const MAX_SKILL_LEVEL: int = 3

## 基础冷却时间
const BASE_COOLDOWN: float = 5.0

## 基础法力消耗
const BASE_MANA_COST: float = 20.0

## 每级效果提升百分比
const LEVEL_BONUS_PERCENT: float = 0.5

# =============================================================================
# 枚举定义
# =============================================================================

## 技能类型
enum SkillType {
	ACTIVE,			## 主动技能 - 需要手动激活
	PASSIVE,		## 被动技能 - 自动生效
	TRIGGER			## 触发技能 - 满足条件自动触发
}

## 技能类别
enum SkillCategory {
	OFFENSIVE,		## 攻击类
	DEFENSIVE,		## 防御类
	CONTROL,		## 控制类
	SUPPORT			## 辅助类
}

## 目标类型
enum TargetType {
	SELF,			## 自身
	ENEMY,			## 敌人
	AREA,			## 区域
	DIRECTION,		## 方向
	PROJECTILE,		## 投射物
	POSITION		## 指定位置
}

## 技能元素
enum SkillElement {
	FIRE,			## 火焰
	ICE,			## 冰霜
	LIGHTNING,		## 闪电
	SHADOW,			## 暗影
	HOLY,			## 神圣
	ARCANE,			## 奥术
	PHYSICAL,		## 物理
	NONE			## 无元素
}

## 触发条件（用于触发型技能）
enum TriggerCondition {
	ON_DAMAGE,			## 受到伤害时
	ON_KILL,			## 击杀敌人时
	ON_CRITICAL,		## 暴击时
	ON_LOW_HEALTH,		## 低血量时
	ON_MANA_USE,		## 使用法力时
	ON_SKILL_USE,		## 使用技能时
	ON_ENEMY_NEARBY,	## 敌人靠近时
	ON_TIME_INTERVAL	## 定时触发
}

# =============================================================================
# 导出变量 - 基本信息
# =============================================================================

## 技能ID
@export var skill_id: String = ""

## 技能名称
@export var skill_name: String = "Unnamed Skill"

## 技能描述
@export_multiline var description: String = ""

## 技能图标
@export var icon: Texture2D

## 技能类型
@export var skill_type: SkillType = SkillType.ACTIVE

## 技能类别
@export var skill_category: SkillCategory = SkillCategory.OFFENSIVE

## 目标类型
@export var target_type: TargetType = TargetType.ENEMY

## 技能元素
@export var element: SkillElement = SkillElement.NONE

## 快捷键绑定 (1-4)
@export var hotkey_slot: int = 0

# =============================================================================
# 导出变量 - 数值属性
# =============================================================================

## 当前等级
@export var current_level: int = 1

## 基础冷却时间
@export var base_cooldown: float = BASE_COOLDOWN

## 基础法力消耗
@export var base_mana_cost: float = BASE_MANA_COST

## 基础伤害
@export var base_damage: float = 10.0

## 作用范围
@export var effect_range: float = 100.0

## 持续时间
@export var duration: float = 1.0

## 投射物速度
@export var projectile_speed: float = 400.0

## 投射物预制体路径（如果是投射物技能）
@export var projectile_scene: PackedScene

# =============================================================================
# 导出变量 - 触发条件（用于触发型技能）
# =============================================================================

## 触发条件
@export var trigger_condition: TriggerCondition = TriggerCondition.ON_DAMAGE

## 触发概率
@export_range(0.0, 1.0) var trigger_chance: float = 1.0

## 触发间隔（用于定时触发）
@export var trigger_interval: float = 5.0

## 触发阈值（用于条件判断，如低血量百分比）
@export_range(0.0, 1.0) var trigger_threshold: float = 0.3

# =============================================================================
# 导出变量 - 升级要求
# =============================================================================

## 解锁所需玩家等级
@export var unlock_level: int = 1

## 前置技能ID
@export var prerequisite_skill: String = ""

# =============================================================================
# 公共变量
# =============================================================================

## 当前冷却时间
var current_cooldown: float = 0.0

## 是否正在冷却
var is_on_cooldown: bool = false

## 是否已解锁
var is_unlocked: bool = false

## 是否激活（用于被动/切换技能）
var is_active: bool = false

## 技能持有者
var owner_node: Node = null

## 触发计时器
var _trigger_timer: float = 0.0

# =============================================================================
# 公共方法 - 初始化
# =============================================================================

## 初始化技能
func initialize(owner: Node) -> void:
	"""
	初始化技能
	@param owner: 技能持有者
	"""
	owner_node = owner
	current_cooldown = 0.0
	is_on_cooldown = false
	_trigger_timer = 0.0
	
	# 被动技能自动激活
	if skill_type == SkillType.PASSIVE:
		is_active = true
		_on_passive_activate()


## 每帧更新（需要由技能管理器调用）
func update(delta: float) -> void:
	"""
	更新技能状态
	@param delta: 帧间隔时间
	"""
	# 更新冷却
	update_cooldown(delta)
	
	# 触发型技能的定时检查
	if skill_type == SkillType.TRIGGER and trigger_condition == TriggerCondition.ON_TIME_INTERVAL:
		_trigger_timer += delta
		if _trigger_timer >= trigger_interval:
			_trigger_timer = 0.0
			_try_trigger()


# =============================================================================
# 公共方法 - 技能使用
# =============================================================================

## 激活技能
func activate(target_position: Variant = null, target_node: Variant = null) -> bool:
	"""
	激活技能
	@param target_position: 目标位置（可选）
	@param target_node: 目标节点（可选）
	@return: 是否成功激活
	"""
	# 检查是否可以激活
	if not can_activate():
		return false
	
	# 检查法力消耗
	if not _check_mana_cost():
		return false
	
	# 消耗法力
	_consume_mana()
	
	# 启动冷却
	start_cooldown()
	
	# 根据目标类型执行效果
	match target_type:
		TargetType.SELF:
			_execute_self_effect()
		TargetType.ENEMY:
			_execute_enemy_effect(target_node)
		TargetType.AREA:
			_execute_area_effect(target_position)
		TargetType.DIRECTION:
			_execute_direction_effect(target_position)
		TargetType.PROJECTILE:
			_execute_projectile_effect(target_position)
		TargetType.POSITION:
			_execute_position_effect(target_position)
	
	skill_activated.emit(self)
	
	return true


## 检查是否可以激活
func can_activate() -> bool:
	"""
	检查技能是否可以使用
	@return: 是否可以激活
	"""
	if not is_unlocked:
		return false
	
	if is_on_cooldown:
		return false
	
	if skill_type == SkillType.PASSIVE:
		return false
	
	if owner_node == null:
		return false
	
	return true


## 启动冷却
func start_cooldown() -> void:
	"""
	启动技能冷却
	"""
	current_cooldown = get_cooldown()
	is_on_cooldown = true


## 更新冷却
func update_cooldown(delta: float) -> void:
	"""
	更新冷却时间
	@param delta: 帧间隔时间
	"""
	if not is_on_cooldown:
		return
	
	current_cooldown -= delta
	
	if current_cooldown <= 0:
		current_cooldown = 0.0
		is_on_cooldown = false
		cooldown_finished.emit(self)


## 重置冷却
func reset_cooldown() -> void:
	"""
	重置技能冷却
	"""
	current_cooldown = 0.0
	is_on_cooldown = false


## 解锁技能
func unlock() -> void:
	"""
	解锁技能
	"""
	is_unlocked = true
	current_level = 1
	skill_upgraded.emit(self, current_level)


## 升级技能
func upgrade() -> bool:
	"""
	升级技能
	@return: 是否成功升级
	"""
	if current_level >= MAX_SKILL_LEVEL:
		skill_maxed.emit(self)
		return false
	
	current_level += 1
	
	# 升级效果
	_on_level_up(current_level)
	
	skill_upgraded.emit(self, current_level)
	
	if current_level >= MAX_SKILL_LEVEL:
		skill_maxed.emit(self)
	
	return true


## 尝试触发（用于触发型技能）
func try_trigger(condition: TriggerCondition, context: Dictionary = {}) -> bool:
	"""
	尝试触发技能
	@param condition: 触发条件
	@param context: 触发上下文
	@return: 是否成功触发
	"""
	if skill_type != SkillType.TRIGGER:
		return false
	
	if trigger_condition != condition:
		return false
	
	if is_on_cooldown:
		return false
	
	return _try_trigger(context)


# =============================================================================
# 公共方法 - 属性获取
# =============================================================================

## 获取当前冷却时间
func get_cooldown() -> float:
	"""
	获取冷却时间（受等级影响）
	@return: 冷却时间
	"""
	# 每级减少8%冷却时间
	var cooldown_reduction: float = 1.0 - (current_level - 1) * 0.08
	return base_cooldown * maxf(0.6, cooldown_reduction)


## 获取法力消耗
func get_mana_cost() -> float:
	"""
	获取法力消耗（受等级影响）
	@return: 法力消耗
	"""
	# 每级减少5%法力消耗
	var cost_reduction: float = 1.0 - (current_level - 1) * 0.05
	return base_mana_cost * maxf(0.7, cost_reduction)


## 获取当前伤害（每级提升50%）
func get_damage() -> float:
	"""
	获取当前伤害值（每级提升50%）
	@return: 伤害值
	"""
	# 每级提升50%基础伤害
	var level_multiplier: float = 1.0 + (current_level - 1) * LEVEL_BONUS_PERCENT
	return base_damage * level_multiplier


## 获取效果范围（受等级影响）
func get_effect_range() -> float:
	"""
	获取效果范围（每级提升15%）
	@return: 效果范围
	"""
	var range_multiplier: float = 1.0 + (current_level - 1) * 0.15
	return effect_range * range_multiplier


## 获取持续时间（受等级影响）
func get_duration() -> float:
	"""
	获取持续时间（每级提升20%）
	@return: 持续时间
	"""
	var duration_multiplier: float = 1.0 + (current_level - 1) * 0.2
	return duration * duration_multiplier


## 获取冷却进度
func get_cooldown_progress() -> float:
	"""
	获取冷却进度（0-1）
	@return: 冷却进度
	"""
	if not is_on_cooldown:
		return 1.0
	
	return 1.0 - (current_cooldown / get_cooldown())


## 获取技能信息
func get_skill_info() -> Dictionary:
	"""
	获取技能信息字典
	@return: 技能信息
	"""
	return {
		"id": skill_id,
		"name": skill_name,
		"description": description,
		"level": current_level,
		"max_level": MAX_SKILL_LEVEL,
		"cooldown": get_cooldown(),
		"mana_cost": get_mana_cost(),
		"damage": get_damage(),
		"range": get_effect_range(),
		"duration": get_duration(),
		"is_unlocked": is_unlocked,
		"is_on_cooldown": is_on_cooldown,
		"type": SkillType.keys()[skill_type],
		"category": SkillCategory.keys()[skill_category],
		"element": SkillElement.keys()[element],
		"hotkey_slot": hotkey_slot
	}


## 获取元素标签
func get_element_tag() -> String:
	"""
	获取元素标签字符串
	@return: 元素标签
	"""
	return SkillElement.keys()[element].to_lower()


## 检查是否可以与另一个技能组合
func can_combine_with(other_skill: SkillBase) -> bool:
	"""
	检查是否可以与另一个技能组合
	@param other_skill: 另一个技能
	@return: 是否可以组合
	"""
	if other_skill == null:
		return false
	
	# 只有不同元素的主动技能可以组合
	if skill_type != SkillType.ACTIVE or other_skill.skill_type != SkillType.ACTIVE:
		return false
	
	if element == other_skill.element:
		return false
	
	return true


# =============================================================================
# 私有方法 - 效果执行
# =============================================================================

func _execute_self_effect() -> void:
	"""
	执行自身效果（子类重写）
	"""
	pass


func _execute_enemy_effect(target: Node) -> void:
	"""
	执行敌人目标效果
	@param target: 目标节点
	"""
	if target == null:
		return
	
	# 基础伤害逻辑
	var damage: float = get_damage()
	if target.has_method("take_damage"):
		target.take_damage(damage, owner_node)
		skill_hit.emit(self, target, damage)


func _execute_area_effect(position: Variant) -> void:
	"""
	执行区域效果
	@param position: 目标位置
	"""
	if position == null:
		position = owner_node.global_position if owner_node else Vector2.ZERO
	
	# 查找范围内的敌人
	var targets: Array[Node] = _get_targets_in_area(position, get_effect_range())
	
	for target in targets:
		var damage: float = get_damage()
		if target.has_method("take_damage"):
			target.take_damage(damage, owner_node)
			skill_hit.emit(self, target, damage)


func _execute_direction_effect(direction: Variant) -> void:
	"""
	执行方向效果（子类重写）
	@param direction: 方向向量
	"""
	pass


func _execute_projectile_effect(target_position: Variant) -> void:
	"""
	执行投射物效果
	@param target_position: 目标位置
	"""
	if projectile_scene == null or owner_node == null:
		return
	
	var spawn_position: Vector2 = owner_node.global_position
	var direction: Vector2 = Vector2.RIGHT
	
	if target_position is Vector2:
		direction = (target_position - spawn_position).normalized()
	
	var projectile: Node = projectile_scene.instantiate()
	owner_node.get_tree().current_scene.add_child(projectile)
	projectile.global_position = spawn_position
	
	# 设置投射物属性
	if "direction" in projectile:
		projectile.direction = direction
	if "damage" in projectile:
		projectile.damage = get_damage()
	if "owner" in projectile:
		projectile.owner = owner_node
	if "speed" in projectile:
		projectile.speed = projectile_speed


func _execute_position_effect(target_position: Variant) -> void:
	"""
	执行指定位置效果（子类重写）
	@param target_position: 目标位置
	"""
	_execute_area_effect(target_position)


func _get_targets_in_area(center: Variant, radius: float) -> Array[Node]:
	"""
	获取区域内的目标
	@param center: 中心位置
	@param radius: 半径
	@return: 目标节点数组
	"""
	var targets: Array[Node] = []
	
	if owner_node == null:
		return targets
	
	var space_state: PhysicsDirectSpaceState2D = owner_node.get_world_2d().direct_space_state
	
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


func _check_mana_cost() -> bool:
	"""
	检查是否有足够法力
	@return: 是否足够
	"""
	if owner_node == null:
		return false
	
	# 假设持有者有 stats 或 PlayerStats 组件
	var stats: Variant = null
	if "stats" in owner_node:
		stats = owner_node.stats
	elif owner_node.has_node("Stats"):
		stats = owner_node.get_node("Stats")
	
	if stats == null:
		return true  # 没有法力系统，直接返回true
	
	if stats is PlayerStats:
		return stats.current_mana >= get_mana_cost()
	
	return true


func _consume_mana() -> void:
	"""
	消耗法力
	"""
	if owner_node == null:
		return
	
	var stats: Variant = null
	if "stats" in owner_node:
		stats = owner_node.stats
	elif owner_node.has_node("Stats"):
		stats = owner_node.get_node("Stats")
	
	if stats is PlayerStats:
		stats.consume_mana(get_mana_cost())


func _try_trigger(context: Dictionary = {}) -> bool:
	"""
	尝试触发技能
	@param context: 触发上下文
	@return: 是否成功触发
	"""
	# 检查触发概率
	if randf() > trigger_chance:
		return false
	
	# 检查特殊条件
	match trigger_condition:
		TriggerCondition.ON_LOW_HEALTH:
			if owner_node == null or not "stats" in owner_node:
				return false
			var stats: PlayerStats = owner_node.stats
			if stats.current_health / stats.max_health > trigger_threshold:
				return false
	
	# 触发技能效果
	_execute_self_effect()
	start_cooldown()
	effect_triggered.emit(self, null)
	
	return true


# =============================================================================
# 虚方法 - 子类重写
# =============================================================================

func _on_level_up(new_level: int) -> void:
	"""
	升级时的处理（子类重写）
	@param new_level: 新等级
	"""
	pass


func _on_passive_activate() -> void:
	"""
	被动技能激活时的处理（子类重写）
	"""
	pass


func _on_passive_deactivate() -> void:
	"""
	被动技能停用时的处理（子类重写）
	"""
	pass


# =============================================================================
# 序列化
# =============================================================================

## 序列化为字典
func to_dictionary() -> Dictionary:
	"""
	将技能序列化为字典
	@return: 技能数据字典
	"""
	return {
		"skill_id": skill_id,
		"current_level": current_level,
		"is_unlocked": is_unlocked,
		"is_active": is_active
	}


## 从字典加载
func from_dictionary(data: Dictionary) -> void:
	"""
	从字典加载技能数据
	@param data: 技能数据
	"""
	current_level = data.get("current_level", 1)
	is_unlocked = data.get("is_unlocked", false)
	is_active = data.get("is_active", false)
