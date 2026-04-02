## Void Hunter - 机械工程师
## @description: 召唤型角色，可部署炮台和召唤机械宠物辅助战斗
## @author: Void Hunter Team
## @version: 2.0.0

extends "res://src/characters/character_base.gd"
class_name MechEngineer

# =============================================================================
# 私有变量
# =============================================================================

## 当前炮台数量
var _turret_count: int = 0

## 当前机械蜘蛛数量
var _spider_count: int = 0

## 蜘蛛召唤冷却
var _spider_cooldown: float = 0.0

## 无人机数量
var _drone_count: int = 0

## 过载模式激活状态
var _overload_active: bool = false

## 过载模式剩余时间
var _overload_timer: float = 0.0

## 累计召唤物造成的伤害（用于触发过载）
var _summon_damage_accumulated: float = 0.0

# =============================================================================
# 初始化
# =============================================================================

func _init() -> void:
	character_id = "mech_engineer"
	character_name = "机械工程师"
	description = "天才发明家，可部署炮台和召唤机械宠物辅助战斗。召唤物越多，自身越强。"
	character_type = CharacterBase.CharacterType.SUMMONER

	# 基础属性 - 较低个人战斗力
	base_health = 75.0
	base_attack = 7.0
	base_defense = 4.0
	base_speed = 140.0
	base_mana = 70.0
	base_critical_chance = 0.05
	base_critical_damage = 1.5

	# 被动技能
	passive_name = "机械伙伴"
	passive_description = "开局自带2个炮台。每30秒可额外召唤一个机械蜘蛛。最多同时存在5个召唤物。召唤物数量越多，自身伤害越高。"
	passive_params = {
		"turret_count": 2,
		"spider_cooldown": 30.0,
		"max_summons": 5,
		"turret_damage": 8.0,
		"spider_damage": 5.0,
		"summon_damage_bonus_per_unit": 0.05,
		"overload_threshold": 200.0,
		"overload_duration": 8.0,
		"overload_damage_bonus": 0.5,
		"overload_speed_bonus": 0.3,
		"drone_heal_per_second": 2.0
	}

	# 解锁条件 - 无特殊条件
	unlock_condition = CharacterBase.UnlockCondition.NONE
	unlock_value = 0
	is_default_unlocked = false
	is_hidden = false

# =============================================================================
# 重写被动技能方法
# =============================================================================

## 游戏开始时生成初始炮台
func on_game_start() -> Dictionary:
	var effects: Dictionary = super.on_game_start()

	# 开局生成炮台
	var initial_turrets: int = passive_params.get("turret_count", 2)
	for i in range(initial_turrets):
		_turret_count += 1
		effects["spawn_turret_%d" % i] = true

	effects["spawn_turret"] = true
	effects["turret_count"] = initial_turrets
	effects["turret_damage"] = passive_params.get("turret_damage", 8.0)

	# 初始蜘蛛冷却
	_spider_cooldown = passive_params.get("spider_cooldown", 30.0)

	passive_triggered.emit(passive_name, {"initial_turrets": initial_turrets})

	return effects


## 每帧更新 - 蜘蛛召唤冷却和过载模式
func on_process(delta: float, player_stats: Dictionary) -> Dictionary:
	var effects: Dictionary = super.on_process(delta, player_stats)

	# 蜘蛛召唤冷却
	if _spider_cooldown > 0:
		_spider_cooldown -= delta
	elif get_total_summon_count() < passive_params.get("max_summons", 5):
		# 冷却完毕且未达到上限，可召唤蜘蛛
		effects["can_spawn_spider"] = true
		effects["spider_damage"] = passive_params.get("spider_damage", 5.0)

	# 过载模式计时
	if _overload_active:
		_overload_timer -= delta
		if _overload_timer <= 0:
			_overload_active = false
			passive_triggered.emit(passive_name, {"overload_end": true})
		else:
			effects["overload_active"] = true
			effects["overload_damage_bonus"] = passive_params.get("overload_damage_bonus", 0.5)
			effects["overload_speed_bonus"] = passive_params.get("overload_speed_bonus", 0.3)

	# 检查过载触发
	if not _overload_active and _summon_damage_accumulated >= passive_params.get("overload_threshold", 200.0):
		_activate_overload()

	# 召唤物数量加成
	var summon_count: int = get_total_summon_count()
	if summon_count > 0:
		var bonus: float = summon_count * passive_params.get("summon_damage_bonus_per_unit", 0.05)
		effects["summon_damage_bonus"] = bonus

	# 无人机持续回血
	if _drone_count > 0:
		effects["passive_heal"] = _drone_count * passive_params.get("drone_heal_per_second", 2.0) * delta

	return effects


## 攻击时附带召唤物协同攻击
func on_attack(attack_data: Dictionary) -> Dictionary:
	var result: Dictionary = super.on_attack(attack_data)

	# 召唤物协同：每个炮台额外附加伤害
	if _turret_count > 0:
		var turret_damage: float = passive_params.get("turret_damage", 8.0)
		var synergy_damage: float = turret_damage * _turret_count * 0.3  # 每个炮台30%协同伤害
		result["summon_synergy_damage"] = synergy_damage

	# 过载模式下额外伤害
	if _overload_active:
		var overload_bonus: float = passive_params.get("overload_damage_bonus", 0.5)
		result["damage_multiplier"] = result.get("damage_multiplier", 1.0) * (1.0 + overload_bonus)

	return result


## 击杀时召唤物获得临时强化
func on_kill(kill_data: Dictionary) -> void:
	super.on_kill(kill_data)

	# 击杀时所有召唤物短暂强化
	if get_total_summon_count() > 0:
		passive_triggered.emit(passive_name, {
			"summon_buff": true,
			"buff_duration": 3.0,
			"buff_damage_mult": 1.3
		})


## 获取修改后的属性
func get_modified_stats(base_stats: Dictionary) -> Dictionary:
	var modified: Dictionary = super.get_modified_stats(base_stats)

	# 召唤物数量加成自身伤害
	var summon_count: int = get_total_summon_count()
	if summon_count > 0:
		var bonus: float = summon_count * passive_params.get("summon_damage_bonus_per_unit", 0.05)
		modified["attack"] = modified.get("attack", 0) * (1.0 + bonus)

	# 过载模式加成
	if _overload_active:
		modified["attack"] = modified.get("attack", 0) * (1.0 + passive_params.get("overload_damage_bonus", 0.5))
		modified["speed"] = modified.get("speed", 0) * (1.0 + passive_params.get("overload_speed_bonus", 0.3))

	return modified


## 召唤蜘蛛（由外部调用确认召唤）
func spawn_spider() -> Dictionary:
	"""
	召唤机械蜘蛛
	@return: 蜘蛛数据，空字典表示无法召唤
	"""
	if _spider_cooldown > 0 or get_total_summon_count() >= passive_params.get("max_summons", 5):
		return {}

	_spider_count += 1
	_spider_cooldown = passive_params.get("spider_cooldown", 30.0)

	var spider_data: Dictionary = {
		"damage": passive_params.get("spider_damage", 5.0),
		"attack_rate": 1.0,
		"move_speed": 120.0,
		"owner_id": character_id
	}

	passive_triggered.emit(passive_name, {"spider_spawned": _spider_count})
	return spider_data


## 炮台被摧毁
func on_turret_destroyed() -> void:
	"""炮台被摧毁时调用"""
	if _turret_count > 0:
		_turret_count -= 1


## 蜘蛛被摧毁
func on_spider_destroyed() -> void:
	"""蜘蛛被摧毁时调用"""
	if _spider_count > 0:
		_spider_count -= 1


## 无人机被摧毁
func on_drone_destroyed() -> void:
	"""无人机被摧毁时调用"""
	if _drone_count > 0:
		_drone_count -= 1


## 召唤无人机（特殊技能触发）
func spawn_drone() -> Dictionary:
	"""
	召唤维修无人机
	@return: 无人机数据
	"""
	if get_total_summon_count() >= passive_params.get("max_summons", 5):
		return {}

	_drone_count += 1
	var drone_data: Dictionary = {
		"heal_per_second": passive_params.get("drone_heal_per_second", 2.0),
		"follow_range": 50.0,
		"owner_id": character_id
	}

	passive_triggered.emit(passive_name, {"drone_spawned": _drone_count})
	return drone_data


## 记录召唤物造成的伤害
func record_summon_damage(damage: float) -> void:
	"""
	记录召唤物造成的伤害（用于触发过载）
	@param damage: 召唤物造成的伤害
	"""
	_summon_damage_accumulated += damage


## 激活过载模式
func _activate_overload() -> void:
	"""激活过载模式"""
	_overload_active = true
	_overload_timer = passive_params.get("overload_duration", 8.0)
	_summon_damage_accumulated = 0.0
	passive_triggered.emit(passive_name, {"overload_start": true})


## 获取总召唤物数量
func get_total_summon_count() -> int:
	"""获取当前所有召唤物总数"""
	return _turret_count + _spider_count + _drone_count


## 获取炮台数量
func get_turret_count() -> int:
	"""获取当前炮台数量"""
	return _turret_count


## 获取蜘蛛数量
func get_spider_count() -> int:
	"""获取当前蜘蛛数量"""
	return _spider_count


## 获取无人机数量
func get_drone_count() -> int:
	"""获取当前无人机数量"""
	return _drone_count


## 获取蜘蛛召唤冷却进度
func get_spider_cooldown_progress() -> float:
	"""获取蜘蛛召唤冷却进度（0-1）"""
	if _spider_cooldown <= 0:
		return 1.0
	return 1.0 - (_spider_cooldown / passive_params.get("spider_cooldown", 30.0))


## 升级所有召唤物
func upgrade_summons(damage_bonus: float) -> void:
	"""
	升级所有召唤物的伤害
	@param damage_bonus: 额外伤害加成
	"""
	passive_params["turret_damage"] = passive_params.get("turret_damage", 8.0) + damage_bonus
	passive_params["spider_damage"] = passive_params.get("spider_damage", 5.0) + damage_bonus * 0.6
	passive_triggered.emit(passive_name, {"summons_upgraded": damage_bonus})


## 重置状态
func reset() -> void:
	super.reset()
	_turret_count = 0
	_spider_count = 0
	_spider_cooldown = 0.0
	_drone_count = 0
	_overload_active = false
	_overload_timer = 0.0
	_summon_damage_accumulated = 0.0
