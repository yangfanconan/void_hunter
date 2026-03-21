## Void Hunter - 玩家属性
## @description: 管理玩家的各项属性、等级、体力和成长系统
## @author: Void Hunter Team
## @version: 1.0.0

extends Resource
class_name PlayerStats

# =============================================================================
# 信号定义
# =============================================================================

## 生命值改变时触发
signal health_changed(current: float, maximum: float)

## 法力值改变时触发
signal mana_changed(current: float, maximum: float)

## 体力值改变时触发
signal stamina_changed(current: float, maximum: float)

## 经验值改变时触发
signal experience_changed(current: float, required: float)

## 等级提升时触发
signal leveled_up(new_level: int)

## 属性改变时触发
signal stats_changed()

# =============================================================================
# 常量定义
# =============================================================================

## 基础经验值需求
const BASE_EXPERIENCE_REQUIRED: int = 100

## 经验值增长系数
const EXPERIENCE_GROWTH_RATE: float = 1.5

## 基础生命值
const BASE_MAX_HEALTH: float = 100.0

## 每级生命值增长
const HEALTH_PER_LEVEL: float = 10.0

## 基础法力值
const BASE_MAX_MANA: float = 50.0

## 每级法力值增长
const MANA_PER_LEVEL: float = 5.0

## 基础体力值
const BASE_MAX_STAMINA: float = 100.0

## 每级体力值增长
const STAMINA_PER_LEVEL: float = 5.0

## 基础攻击力
const BASE_ATTACK: float = 10.0

## 基础防御力
const BASE_DEFENSE: float = 5.0

## 基础速度
const BASE_SPEED: float = 150.0

## 基础暴击率
const BASE_CRITICAL_CHANCE: float = 0.05

## 基础暴击伤害
const BASE_CRITICAL_DAMAGE: float = 1.5

## 基础射速倍率
const BASE_FIRE_RATE_MULTIPLIER: float = 1.0

# =============================================================================
# 导出变量 - 基础属性
# =============================================================================

## 当前等级
@export var level: int = 1

## 当前经验值
@export var current_experience: int = 0

## 当前生命值
@export var current_health: float = BASE_MAX_HEALTH

## 当前法力值
@export var current_mana: float = BASE_MAX_MANA

## 当前体力值
@export var current_stamina: float = BASE_MAX_STAMINA

## 最大生命值（加成后）
@export var max_health: float = BASE_MAX_HEALTH

## 最大法力值（加成后）
@export var max_mana: float = BASE_MAX_MANA

## 最大体力值（加成后）
@export var max_stamina: float = BASE_MAX_STAMINA

## 攻击力（加成后）
@export var attack: float = BASE_ATTACK

## 防御力（加成后）
@export var defense: float = BASE_DEFENSE

## 移动速度（加成后）
@export var speed: float = BASE_SPEED

## 暴击率（加成后）
@export_range(0.0, 1.0) var critical_chance: float = BASE_CRITICAL_CHANCE

## 暴击伤害倍率（加成后）
@export var critical_damage: float = BASE_CRITICAL_DAMAGE

# =============================================================================
# 导出变量 - 加成
# =============================================================================

## 生命值加成百分比
@export var health_bonus_percent: float = 0.0

## 法力值加成百分比
@export var mana_bonus_percent: float = 0.0

## 体力值加成百分比
@export var stamina_bonus_percent: float = 0.0

## 攻击力加成百分比
@export var attack_bonus_percent: float = 0.0

## 防御力加成百分比
@export var defense_bonus_percent: float = 0.0

## 速度加成百分比
@export var speed_bonus_percent: float = 0.0

## 暴击率加成
@export var critical_chance_bonus: float = 0.0

## 暴击伤害加成
@export var critical_damage_bonus: float = 0.0

## 射速加成
@export var fire_rate_bonus: float = 0.0

# =============================================================================
# 导出变量 - 恢复
# =============================================================================

## 生命回复速度（每秒恢复最大生命值的百分比）
@export var health_regen: float = 1.0

## 法力回复速度（每秒）
@export var mana_regen: float = 2.0

## 体力回复速度（每0.1秒）
@export var stamina_regen: float = 5.0

# =============================================================================
# 导出变量 - 其他
# =============================================================================

## 吸血百分比
@export_range(0.0, 1.0) var life_steal: float = 0.0

## 伤害减免百分比
@export_range(0.0, 1.0) var damage_reduction: float = 0.0

# =============================================================================
# 公共变量
# =============================================================================

## 是否死亡
var is_dead: bool = false

## 速度倍率（包含所有加成）
var speed_multiplier: float = 1.0

## 射速倍率（包含所有加成）
var fire_rate_multiplier: float = 1.0

## 升级所需经验值
var experience_required: int = BASE_EXPERIENCE_REQUIRED

# =============================================================================
# 私有变量
# =============================================================================

var _flat_health_bonus: float = 0.0
var _flat_mana_bonus: float = 0.0
var _flat_stamina_bonus: float = 0.0
var _flat_attack_bonus: float = 0.0
var _flat_defense_bonus: float = 0.0
var _flat_speed_bonus: float = 0.0

# =============================================================================
# 公共方法 - 初始化
# =============================================================================

## 初始化属性
func initialize() -> void:
	"""
	初始化玩家属性，计算所有加成
	"""
	_recalculate_stats()
	current_health = max_health
	current_mana = max_mana
	current_stamina = max_stamina
	is_dead = false


## 重置为默认值
func reset() -> void:
	"""
	重置所有属性到默认值
	"""
	level = 1
	current_experience = 0
	
	# 重置加成
	health_bonus_percent = 0.0
	mana_bonus_percent = 0.0
	stamina_bonus_percent = 0.0
	attack_bonus_percent = 0.0
	defense_bonus_percent = 0.0
	speed_bonus_percent = 0.0
	critical_chance_bonus = 0.0
	critical_damage_bonus = 0.0
	fire_rate_bonus = 0.0
	
	_flat_health_bonus = 0.0
	_flat_mana_bonus = 0.0
	_flat_stamina_bonus = 0.0
	_flat_attack_bonus = 0.0
	_flat_defense_bonus = 0.0
	_flat_speed_bonus = 0.0
	
	life_steal = 0.0
	damage_reduction = 0.0
	health_regen = 1.0
	mana_regen = 2.0
	stamina_regen = 5.0
	
	initialize()

# =============================================================================
# 公共方法 - 属性修改
# =============================================================================

## 应用伤害
func apply_damage(amount: float) -> float:
	"""
	应用伤害，考虑防御力和减伤
	@param amount: 原始伤害值
	@return: 实际伤害值
	"""
	if is_dead:
		return 0.0
	
	# 计算防御减免
	var defense_reduction: float = defense / (defense + 100.0)
	var actual_damage: float = amount * (1.0 - defense_reduction)
	
	# 应用百分比减伤
	actual_damage *= (1.0 - damage_reduction)
	
	# 应用伤害
	current_health = maxf(0.0, current_health - actual_damage)
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		is_dead = true
	
	return actual_damage


## 治疗
func heal(amount: float) -> float:
	"""
	治疗生命值
	@param amount: 治疗量
	@return: 实际治疗量
	"""
	if is_dead:
		return 0.0
	
	var old_health: float = current_health
	current_health = minf(max_health, current_health + amount)
	var actual_heal: float = current_health - old_health
	
	health_changed.emit(current_health, max_health)
	return actual_heal


## 恢复法力
func restore_mana(amount: float) -> float:
	"""
	恢复法力值
	@param amount: 恢复量
	@return: 实际恢复量
	"""
	var old_mana: float = current_mana
	current_mana = minf(max_mana, current_mana + amount)
	var actual_restore: float = current_mana - old_mana
	
	mana_changed.emit(current_mana, max_mana)
	return actual_restore


## 消耗法力
func consume_mana(amount: float) -> bool:
	"""
	消耗法力值
	@param amount: 消耗量
	@return: 是否成功消耗
	"""
	if current_mana < amount:
		return false
	
	current_mana -= amount
	mana_changed.emit(current_mana, max_mana)
	return true


## 恢复体力
func restore_stamina(amount: float) -> float:
	"""
	恢复体力值
	@param amount: 恢复量
	@return: 实际恢复量
	"""
	var old_stamina: float = current_stamina
	current_stamina = minf(max_stamina, current_stamina + amount)
	var actual_restore: float = current_stamina - old_stamina
	
	stamina_changed.emit(current_stamina, max_stamina)
	return actual_restore


## 消耗体力
func consume_stamina(amount: float) -> bool:
	"""
	消耗体力值
	@param amount: 消耗量
	@return: 是否成功消耗
	"""
	if current_stamina < amount:
		return false
	
	current_stamina -= amount
	stamina_changed.emit(current_stamina, max_stamina)
	return true


## 增加经验值
func add_experience(amount: int) -> void:
	"""
	增加经验值
	@param amount: 经验值数量
	"""
	current_experience += amount
	experience_changed.emit(current_experience, experience_required)
	
	# 检查升级
	while current_experience >= experience_required:
		_level_up()


## 添加固定属性加成
func add_flat_bonus(stat_type: String, amount: float) -> void:
	"""
	添加固定属性加成
	@param stat_type: 属性类型
	@param amount: 加成数值
	"""
	match stat_type:
		"health":
			_flat_health_bonus += amount
		"mana":
			_flat_mana_bonus += amount
		"stamina":
			_flat_stamina_bonus += amount
		"attack":
			_flat_attack_bonus += amount
		"defense":
			_flat_defense_bonus += amount
		"speed":
			_flat_speed_bonus += amount
	
	_recalculate_stats()
	stats_changed.emit()


## 添加百分比属性加成
func add_percent_bonus(stat_type: String, percent: float) -> void:
	"""
	添加百分比属性加成
	@param stat_type: 属性类型
	@param percent: 加成百分比（0.1 = 10%）
	"""
	match stat_type:
		"health":
			health_bonus_percent += percent
		"mana":
			mana_bonus_percent += percent
		"stamina":
			stamina_bonus_percent += percent
		"attack":
			attack_bonus_percent += percent
		"defense":
			defense_bonus_percent += percent
		"speed":
			speed_bonus_percent += percent
		"critical_chance":
			critical_chance_bonus += percent
		"critical_damage":
			critical_damage_bonus += percent
		"fire_rate":
			fire_rate_bonus += percent
	
	_recalculate_stats()
	stats_changed.emit()


## 移除固定属性加成
func remove_flat_bonus(stat_type: String, amount: float) -> void:
	"""
	移除固定属性加成
	@param stat_type: 属性类型
	@param amount: 加成数值
	"""
	add_flat_bonus(stat_type, -amount)


## 移除百分比属性加成
func remove_percent_bonus(stat_type: String, percent: float) -> void:
	"""
	移除百分比属性加成
	@param stat_type: 属性类型
	@param percent: 加成百分比
	"""
	add_percent_bonus(stat_type, -percent)

# =============================================================================
# 公共方法 - 计算
# =============================================================================

## 计算最终伤害
func calculate_final_damage(base_damage: float) -> Dictionary:
	"""
	计算最终伤害，包含暴击判定
	@param base_damage: 基础伤害值
	@return: 包含伤害信息的字典
	"""
	var final_damage: float = base_damage + attack
	var is_critical: bool = randf() < (critical_chance + critical_chance_bonus)
	
	if is_critical:
		final_damage *= (critical_damage + critical_damage_bonus)
	
	return {
		"damage": final_damage,
		"is_critical": is_critical
	}


## 获取属性字典
func to_dictionary() -> Dictionary:
	"""
	将属性转换为字典
	@return: 属性字典
	"""
	return {
		"level": level,
		"experience": current_experience,
		"health": current_health,
		"max_health": max_health,
		"mana": current_mana,
		"max_mana": max_mana,
		"stamina": current_stamina,
		"max_stamina": max_stamina,
		"attack": attack,
		"defense": defense,
		"speed": speed,
		"critical_chance": critical_chance + critical_chance_bonus,
		"critical_damage": critical_damage + critical_damage_bonus,
		"life_steal": life_steal,
		"damage_reduction": damage_reduction,
		"health_regen": health_regen,
		"mana_regen": mana_regen,
		"stamina_regen": stamina_regen
	}


## 从字典加载属性
func from_dictionary(data: Dictionary) -> void:
	"""
	从字典加载属性
	@param data: 属性字典
	"""
	level = data.get("level", 1)
	current_experience = data.get("experience", 0)
	current_health = data.get("health", BASE_MAX_HEALTH)
	current_mana = data.get("mana", BASE_MAX_MANA)
	current_stamina = data.get("stamina", BASE_MAX_STAMINA)
	
	_recalculate_stats()
	
	# 确保当前值不超过最大值
	current_health = minf(current_health, max_health)
	current_mana = minf(current_mana, max_mana)
	current_stamina = minf(current_stamina, max_stamina)

# =============================================================================
# 私有方法
# =============================================================================

func _recalculate_stats() -> void:
	"""
	重新计算所有属性（应用加成和等级成长）
	"""
	# 计算等级成长
	var level_health_bonus: float = (level - 1) * HEALTH_PER_LEVEL
	var level_mana_bonus: float = (level - 1) * MANA_PER_LEVEL
	var level_stamina_bonus: float = (level - 1) * STAMINA_PER_LEVEL
	var level_multiplier: float = 1.0 + (level - 1) * 0.05
	
	# 计算生命值
	max_health = (BASE_MAX_HEALTH + level_health_bonus + _flat_health_bonus) * (1.0 + health_bonus_percent)
	
	# 计算法力值
	max_mana = (BASE_MAX_MANA + level_mana_bonus + _flat_mana_bonus) * (1.0 + mana_bonus_percent)
	
	# 计算体力值
	max_stamina = (BASE_MAX_STAMINA + level_stamina_bonus + _flat_stamina_bonus) * (1.0 + stamina_bonus_percent)
	
	# 计算攻击力
	attack = (BASE_ATTACK * level_multiplier + _flat_attack_bonus) * (1.0 + attack_bonus_percent)
	
	# 计算防御力
	defense = (BASE_DEFENSE * level_multiplier + _flat_defense_bonus) * (1.0 + defense_bonus_percent)
	
	# 计算速度
	speed = (BASE_SPEED + _flat_speed_bonus) * (1.0 + speed_bonus_percent)
	speed_multiplier = speed / BASE_SPEED
	
	# 计算暴击率
	critical_chance = clamp(BASE_CRITICAL_CHANCE + critical_chance_bonus, 0.0, 1.0)
	
	# 计算暴击伤害
	critical_damage = BASE_CRITICAL_DAMAGE + critical_damage_bonus
	
	# 计算射速倍率
	fire_rate_multiplier = BASE_FIRE_RATE_MULTIPLIER * (1.0 + fire_rate_bonus)
	
	# 计算升级所需经验值
	experience_required = int(BASE_EXPERIENCE_REQUIRED * pow(EXPERIENCE_GROWTH_RATE, level - 1))


func _level_up() -> void:
	"""
	升级处理
	"""
	current_experience -= experience_required
	level += 1
	
	# 重新计算属性
	_recalculate_stats()
	
	# 恢复生命值、法力值和体力到最大
	current_health = max_health
	current_mana = max_mana
	current_stamina = max_stamina
	
	# 触发信号
	leveled_up.emit(level)
	health_changed.emit(current_health, max_health)
	mana_changed.emit(current_mana, max_mana)
	stamina_changed.emit(current_stamina, max_stamina)
	experience_changed.emit(current_experience, experience_required)


## 应用吸血效果
func apply_life_steal(damage_dealt: float) -> float:
	"""
	应用吸血效果
	@param damage_dealt: 造成的伤害
	@return: 实际恢复的生命值
	"""
	if life_steal <= 0:
		return 0.0
	
	var heal_amount: float = damage_dealt * life_steal
	return heal(heal_amount)
