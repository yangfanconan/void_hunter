## Void Hunter - 玩家属性
## @description: 玩家属性系统，管理生命值、法力值、体力、经验等
## @author: Void Hunter Team
## @version: 1.0.0

extends Resource

# =============================================================================
# 信号定义
# =============================================================================

## 生命值变化时触发
signal health_changed(current: float, maximum: float)

## 法力值变化时触发
signal mana_changed(current: float, maximum: float)

## 体力值变化时触发
signal stamina_changed(current: float, maximum: float)

## 经验值变化时触发
signal experience_changed(current: float, required: float)

## 升级时触发
signal leveled_up(new_level: int)

## 属性变化时触发
signal attributes_changed()

# =============================================================================
# 常量定义
# =============================================================================

## 基础生命值
const BASE_HEALTH: float = 100.0

## 基础法力值
const BASE_MANA: float = 50.0

## 基础体力值
const BASE_STAMINA: float = 100.0

## 基础经验需求
const BASE_EXP_REQUIRED: int = 100

## 体力恢复速率
const STAMINA_REGEN_RATE: float = 15.0

## 法力恢复速率
const MANA_REGEN_RATE: float = 5.0

# =============================================================================
# 导出变量 - 基础属性
# =============================================================================

## 当前等级
@export var level: int = 1

## 当前生命值
@export var current_health: float = BASE_HEALTH

## 最大生命值
@export var max_health: float = BASE_HEALTH

## 当前法力值
@export var current_mana: float = BASE_MANA

## 最大法力值
@export var max_mana: float = BASE_MANA

## 当前体力值
@export var current_stamina: float = BASE_STAMINA

## 最大体力值
@export var max_stamina: float = BASE_STAMINA

## 当前经验值
@export var current_experience: int = 0

## 升级所需经验
@export var experience_required: int = BASE_EXP_REQUIRED

# =============================================================================
# 导出变量 - 战斗属性
# =============================================================================

## 基础攻击力
@export_range(1.0, 100.0) var base_attack: float = 10.0

## 基础防御力
@export_range(0.0, 50.0) var base_defense: float = 5.0

## 暴击率
@export_range(0.0, 1.0) var crit_chance: float = 0.05

## 暴击伤害倍率
@export_range(1.0, 3.0) var crit_multiplier: float = 1.5

## 攻击速度加成
@export_range(0.0, 2.0) var attack_speed_bonus: float = 0.0

## 移动速度加成
@export_range(0.0, 1.0) var move_speed_bonus: float = 0.0

# =============================================================================
# 导出变量 - 属性点
# =============================================================================

## 力量
@export_range(0, 100) var strength: int = 0

## 敏捷
@export_range(0, 100) var agility: int = 0

## 体质
@export_range(0, 100) var constitution: int = 0

## 智力
@export_range(0, 100) var intelligence: int = 0

## 可用属性点
@export var available_points: int = 0

# =============================================================================
# 私有变量
# =============================================================================

var _is_initialized: bool = false

# =============================================================================
# 生命周期方法
# =============================================================================

func _init() -> void:
	"""资源初始化"""
	# 设置默认值
	if max_health <= 0:
		max_health = BASE_HEALTH
	if max_mana <= 0:
		max_mana = BASE_MANA
	if max_stamina <= 0:
		max_stamina = BASE_STAMINA
	if experience_required <= 0:
		experience_required = BASE_EXP_REQUIRED

# =============================================================================
# 公共方法 - 初始化
# =============================================================================

## 初始化属性
func initialize() -> void:
	"""初始化玩家属性"""
	if _is_initialized:
		return
	
	# 设置初始值
	current_health = max_health
	current_mana = max_mana
	current_stamina = max_stamina
	current_experience = 0
	level = 1
	experience_required = BASE_EXP_REQUIRED
	
	# 计算属性加成
	_recalculate_stats()
	
	_is_initialized = true
	print("[PlayerStats] 属性初始化完成")


## 重置属性
func reset() -> void:
	"""重置所有属性到初始状态"""
	level = 1
	max_health = BASE_HEALTH
	max_mana = BASE_MANA
	max_stamina = BASE_STAMINA
	current_health = max_health
	current_mana = max_mana
	current_stamina = max_stamina
	current_experience = 0
	experience_required = BASE_EXP_REQUIRED
	
	strength = 0
	agility = 0
	constitution = 0
	intelligence = 0
	available_points = 0
	
	_is_initialized = false
	initialize()

# =============================================================================
# 公共方法 - 生命值
# =============================================================================

## 受到伤害
func take_damage(amount: float) -> void:
	"""受到伤害"""
	var actual_damage: float = amount * (1.0 - get_damage_reduction())
	current_health = max(0, current_health - actual_damage)
	health_changed.emit(current_health, max_health)


## 治疗
func heal(amount: float) -> void:
	"""治疗"""
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)


## 恢复全部生命值
func restore_health() -> void:
	"""恢复全部生命值"""
	current_health = max_health
	health_changed.emit(current_health, max_health)


## 设置生命值
func set_health(value: float) -> void:
	"""设置当前生命值"""
	current_health = clamp(value, 0, max_health)
	health_changed.emit(current_health, max_health)


## 获取生命值百分比
func get_health_percent() -> float:
	"""获取生命值百分比"""
	if max_health <= 0:
		return 0.0
	return current_health / max_health

# =============================================================================
# 公共方法 - 法力值
# =============================================================================

## 消耗法力
func use_mana(amount: float) -> bool:
	"""消耗法力，返回是否成功"""
	if current_mana < amount:
		return false
	current_mana -= amount
	mana_changed.emit(current_mana, max_mana)
	return true


## 恢复法力
func restore_mana(amount: float) -> void:
	"""恢复法力"""
	current_mana = min(max_mana, current_mana + amount)
	mana_changed.emit(current_mana, max_mana)


## 恢复全部法力
func restore_full_mana() -> void:
	"""恢复全部法力"""
	current_mana = max_mana
	mana_changed.emit(current_mana, max_mana)


## 获取法力值百分比
func get_mana_percent() -> float:
	"""获取法力值百分比"""
	if max_mana <= 0:
		return 0.0
	return current_mana / max_mana

# =============================================================================
# 公共方法 - 体力
# =============================================================================

## 消耗体力
func use_stamina(amount: float) -> bool:
	"""消耗体力，返回是否成功"""
	if current_stamina < amount:
		return false
	current_stamina -= amount
	stamina_changed.emit(current_stamina, max_stamina)
	return true


## 恢复体力
func restore_stamina(amount: float) -> void:
	"""恢复体力"""
	current_stamina = min(max_stamina, current_stamina + amount)
	stamina_changed.emit(current_stamina, max_stamina)


## 恢复全部体力
func restore_full_stamina() -> void:
	"""恢复全部体力"""
	current_stamina = max_stamina
	stamina_changed.emit(current_stamina, max_stamina)


## 自然恢复体力
func natural_stamina_regen(delta: float) -> void:
	"""自然恢复体力"""
	if current_stamina < max_stamina:
		restore_stamina(STAMINA_REGEN_RATE * delta)

# =============================================================================
# 公共方法 - 经验值
# =============================================================================

## 添加经验值
func add_experience(amount: int) -> void:
	"""添加经验值"""
	current_experience += amount
	experience_changed.emit(current_experience, experience_required)
	
	# 检查升级
	while current_experience >= experience_required:
		_level_up()


## 设置经验值
func set_experience(amount: int) -> void:
	"""设置当前经验值"""
	current_experience = amount
	experience_changed.emit(current_experience, experience_required)

# =============================================================================
# 公共方法 - 属性点
# =============================================================================

## 增加力量
func add_strength() -> bool:
	"""增加力量"""
	if available_points <= 0:
		return false
	strength += 1
	available_points -= 1
	_on_attribute_changed()
	return true


## 增加敏捷
func add_agility() -> bool:
	"""增加敏捷"""
	if available_points <= 0:
		return false
	agility += 1
	available_points -= 1
	_on_attribute_changed()
	return true


## 增加体质
func add_constitution() -> bool:
	"""增加体质"""
	if available_points <= 0:
		return false
	constitution += 1
	available_points -= 1
	_on_attribute_changed()
	return true


## 增加智力
func add_intelligence() -> bool:
	"""增加智力"""
	if available_points <= 0:
		return false
	intelligence += 1
	available_points -= 1
	_on_attribute_changed()
	return true

# =============================================================================
# 公共方法 - 战斗计算
# =============================================================================

## 获取攻击力
func get_attack() -> float:
	"""获取总攻击力"""
	var total: float = base_attack
	total += strength * 2.0  # 每点力量+2攻击
	total += agility * 0.5   # 每点敏捷+0.5攻击
	return total


## 获取防御力
func get_defense() -> float:
	"""获取总防御力"""
	var total: float = base_defense
	total += constitution * 1.5  # 每点体质+1.5防御
	return total


## 获取伤害减免
func get_damage_reduction() -> float:
	"""获取伤害减免百分比"""
	var defense: float = get_defense()
	# 防御力转换为伤害减免，最高50%
	return min(0.5, defense / (defense + 100.0))


## 获取暴击率
func get_crit_chance() -> float:
	"""获取总暴击率"""
	var total: float = crit_chance
	total += agility * 0.005  # 每点敏捷+0.5%暴击率
	return min(1.0, total)


## 获取暴击伤害
func get_crit_damage() -> float:
	"""获取暴击伤害倍率"""
	return crit_multiplier


## 获取移动速度
func get_move_speed() -> float:
	"""获取移动速度加成"""
	var total: float = move_speed_bonus
	total += agility * 0.01  # 每点敏捷+1%移动速度
	return total

# =============================================================================
# 私有方法 - 升级
# =============================================================================

func _level_up() -> void:
	"""升级"""
	current_experience -= experience_required
	level += 1
	
	# 增加经验需求
	experience_required = int(float(experience_required) * 1.5)
	
	# 增加基础属性
	max_health += 10
	max_mana += 5
	max_stamina += 5
	
	# 恢复生命值和资源
	current_health = max_health
	current_mana = max_mana
	current_stamina = max_stamina
	
	# 获得属性点
	available_points += 3
	
	# 触发信号
	leveled_up.emit(level)
	health_changed.emit(current_health, max_health)
	mana_changed.emit(current_mana, max_mana)
	stamina_changed.emit(current_stamina, max_stamina)
	experience_changed.emit(current_experience, experience_required)
	
	print("[PlayerStats] 升级到 %d" % level)


func _recalculate_stats() -> void:
	"""重新计算属性"""
	# 根据属性点重新计算
	var health_bonus: float = constitution * 5.0
	var mana_bonus: float = intelligence * 3.0
	var stamina_bonus: float = constitution * 2.0
	
	max_health = BASE_HEALTH + health_bonus
	max_mana = BASE_MANA + mana_bonus
	max_stamina = BASE_STAMINA + stamina_bonus


func _on_attribute_changed() -> void:
	"""属性变化时调用"""
	_recalculate_stats()
	attributes_changed.emit()
