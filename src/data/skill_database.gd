## Void Hunter - 技能数据库
## @description: 管理所有技能数据的全局数据库，包含50+种技能
## @author: Void Hunter Team
## @version: 1.0.0

extends Resource
class_name SkillDatabase

# =============================================================================
# 枚举定义
# =============================================================================

## 技能类型
enum SkillType {
	ACTIVE,			## 主动技能
	PASSIVE,		## 被动技能
	TRIGGER			## 触发技能
}

## 技能类别
enum SkillCategory {
	OFFENSIVE,		## 攻击类
	DEFENSIVE,		## 防御类
	CONTROL,		## 控制类
	SUPPORT,		## 辅助类
	PASSIVE			## 属性加成类
}

## 技能元素
enum SkillElement {
	FIRE,			## 火焰
	ICE,			## 冰霜
	LIGHTNING,		## 闪电
	SHADOW,			## 暗影
	HOLY,			## 神圣
	ARCANE,			## 奥术
	VOID,			## 虚空
	CHAOS,			## 混沌
	PHYSICAL,		## 物理
	NONE			## 无元素
}

## 稀有度
enum SkillRarity {
	COMMON,			## 普通
	UNCOMMON,		## 稀有
	RARE,			## 精良
	EPIC,			## 史诗
	LEGENDARY		## 传说
}

# =============================================================================
# 公共变量
# =============================================================================

## 所有技能数据
var skills: Dictionary = {}

## 按类型分组的技能
var skills_by_type: Dictionary = {}

## 按类别分组的技能
var skills_by_category: Dictionary = {}

## 按稀有度分组的技能
var skills_by_rarity: Dictionary = {}

## 是否已加载
var _is_loaded: bool = false

# =============================================================================
# 公共方法
# =============================================================================

## 加载数据库
func load_database() -> bool:
	if _is_loaded:
		return true
	
	_load_default_skills()
	_is_loaded = true
	return true


## 获取技能数据
func get_skill(skill_id: String) -> Dictionary:
	if not _is_loaded:
		load_database()
	return skills.get(skill_id, {})


## 获取所有技能
func get_all_skills() -> Dictionary:
	if not _is_loaded:
		load_database()
	return skills.duplicate()


## 获取指定类别的技能
func get_skills_by_category(category: int) -> Array[Dictionary]:
	if not _is_loaded:
		load_database()
	return skills_by_category.get(category, [])


## 获取指定稀有度的技能
func get_skills_by_rarity(rarity: int) -> Array[Dictionary]:
	if not _is_loaded:
		load_database()
	return skills_by_rarity.get(rarity, [])


## 随机获取技能
func get_random_skill(rarity_weights: Dictionary = {}) -> Dictionary:
	if not _is_loaded:
		load_database()
	
	if rarity_weights.is_empty():
		rarity_weights = {
			SkillRarity.COMMON: 50,
			SkillRarity.UNCOMMON: 30,
			SkillRarity.RARE: 15,
			SkillRarity.EPIC: 4,
			SkillRarity.LEGENDARY: 1
		}
	
	var total_weight: float = 0.0
	for weight in rarity_weights.values():
		total_weight += weight
	
	var random_value: float = randf() * total_weight
	var current_weight: float = 0.0
	var selected_rarity: int = 0
	
	for rarity in rarity_weights.keys():
		current_weight += rarity_weights[rarity]
		if random_value <= current_weight:
			selected_rarity = rarity
			break
	
	var rarity_skills: Array[Dictionary] = get_skills_by_rarity(selected_rarity)
	if rarity_skills.is_empty():
		return {}
	
	return rarity_skills[randi() % rarity_skills.size()]


## 获取随机技能选项（用于升级选择）
func get_random_skill_options(count: int = 3, exclude_ids: Array = []) -> Array[Dictionary]:
	if not _is_loaded:
		load_database()
	
	var available: Array[Dictionary] = []
	for skill_id in skills.keys():
		if skill_id not in exclude_ids:
			available.append(skills[skill_id])
	
	available.shuffle()
	var result: Array[Dictionary] = []
	for i in range(mini(count, available.size())):
		result.append(available[i])
	
	return result


# =============================================================================
# 私有方法 - 数据加载
# =============================================================================

func _load_default_skills() -> void:
	skills.clear()
	skills_by_type.clear()
	skills_by_category.clear()
	skills_by_rarity.clear()
	
	# 属性加成类 (15种)
	_register_stat_boost_skills()
	
	# 弹幕类 (15种)
	_register_bullet_skills()
	
	# 元素类 (10种)
	_register_element_skills()
	
	# 特殊技能 (10种)
	_register_special_skills()
	
	# 辅助技能 (15种)
	_register_support_skills()
	
	# 按类别和稀有度分组
	for skill_id in skills.keys():
		var skill_data: Dictionary = skills[skill_id]
		
		var category: int = skill_data.get("category", 0)
		if not skills_by_category.has(category):
			skills_by_category[category] = []
		skills_by_category[category].append(skill_data)
		
		var rarity: int = skill_data.get("rarity", 0)
		if not skills_by_rarity.has(rarity):
			skills_by_rarity[rarity] = []
		skills_by_rarity[rarity].append(skill_data)
		
		var type: int = skill_data.get("type", 0)
		if not skills_by_type.has(type):
			skills_by_type[type] = []
		skills_by_type[type].append(skill_data)


# =============================================================================
# 属性加成类技能 (15种)
# =============================================================================

func _register_stat_boost_skills() -> void:
	# 攻击强化
	skills["attack_boost_1"] = {
		"id": "attack_boost_1",
		"name": "攻击强化 I",
		"description": "提升攻击力5%",
		"type": SkillType.PASSIVE,
		"category": SkillCategory.PASSIVE,
		"element": SkillElement.NONE,
		"rarity": SkillRarity.COMMON,
		"stats": {"attack_percent": 0.05},
		"max_level": 1,
		"icon": "res://assets/skills/attack_boost.png"
	}
	
	skills["attack_boost_2"] = {
		"id": "attack_boost_2",
		"name": "攻击强化 II",
		"description": "提升攻击力10%",
		"type": SkillType.PASSIVE,
		"category": SkillCategory.PASSIVE,
		"element": SkillElement.NONE,
		"rarity": SkillRarity.UNCOMMON,
		"stats": {"attack_percent": 0.10},
		"max_level": 1,
		"icon": "res://assets/skills/attack_boost.png"
	}
	
	skills["attack_boost_3"] = {
		"id": "attack_boost_3",
		"name": "攻击强化 III",
		"description": "提升攻击力15%",
		"type": SkillType.PASSIVE,
		"category": SkillCategory.PASSIVE,
		"element": SkillElement.NONE,
		"rarity": SkillRarity.RARE,
		"stats": {"attack_percent": 0.15},
		"max_level": 1,
		"icon": "res://assets/skills/attack_boost.png"
	}
	
	# 生命强化
	skills["health_boost_1"] = {
		"id": "health_boost_1",
		"name": "生命强化 I",
		"description": "提升最大生命值10点",
		"type": SkillType.PASSIVE,
		"category": SkillCategory.PASSIVE,
		"element": SkillElement.NONE,
		"rarity": SkillRarity.COMMON,
		"stats": {"max_health": 10},
		"max_level": 1,
		"icon": "res://assets/skills/health_boost.png"
	}
	
	skills["health_boost_2"] = {
		"id": "health_boost_2",
		"name": "生命强化 II",
		"description": "提升最大生命值20点",
		"type": SkillType.PASSIVE,
		"category": SkillCategory.PASSIVE,
		"element": SkillElement.NONE,
		"rarity": SkillRarity.UNCOMMON,
		"stats": {"max_health": 20},
		"max_level": 1,
		"icon": "res://assets/skills/health_boost.png"
	}
	
	skills["health_boost_3"] = {
		"id": "health_boost_3",
		"name": "生命强化 III",
		"description": "提升最大生命值30点",
		"type": SkillType.PASSIVE,
		"category": SkillCategory.PASSIVE,
		"element": SkillElement.NONE,
		"rarity": SkillRarity.RARE,
		"stats": {"max_health": 30},
		"max_level": 1,
		"icon": "res://assets/skills/health_boost.png"
	}
	
	# 速度强化
	skills["speed_boost_1"] = {
		"id": "speed_boost_1",
		"name": "速度强化 I",
		"description": "提升移动速度3%",
		"type": SkillType.PASSIVE,
		"category": SkillCategory.PASSIVE,
		"element": SkillElement.NONE,
		"rarity": SkillRarity.COMMON,
		"stats": {"move_speed_percent": 0.03},
		"max_level": 1,
		"icon": "res://assets/skills/speed_boost.png"
	}
	
	skills["speed_boost_2"] = {
		"id": "speed_boost_2",
		"name": "速度强化 II",
		"description": "提升移动速度5%",
		"type": SkillType.PASSIVE,
		"category": SkillCategory.PASSIVE,
		"element": SkillElement.NONE,
		"rarity": SkillRarity.UNCOMMON,
		"stats": {"move_speed_percent": 0.05},
		"max_level": 1,
		"icon": "res://assets/skills/speed_boost.png"
	}
	
	skills["speed_boost_3"] = {
		"id": "speed_boost_3",
		"name": "速度强化 III",
		"description": "提升移动速度8%",
		"type": SkillType.PASSIVE,
		"category": SkillCategory.PASSIVE,
		"element": SkillElement.NONE,
		"rarity": SkillRarity.RARE,
		"stats": {"move_speed_percent": 0.08},
		"max_level": 1,
		"icon": "res://assets/skills/speed_boost.png"
	}
	
	# 暴击强化
	skills["crit_boost_1"] = {
		"id": "crit_boost_1",
		"name": "暴击强化 I",
		"description": "提升暴击率3%",
		"type": SkillType.PASSIVE,
		"category": SkillCategory.PASSIVE,
		"element": SkillElement.NONE,
		"rarity": SkillRarity.COMMON,
		"stats": {"crit_chance": 0.03},
		"max_level": 1,
		"icon": "res://assets/skills/crit_boost.png"
	}
	
	skills["crit_boost_2"] = {
		"id": "crit_boost_2",
		"name": "暴击强化 II",
		"description": "提升暴击率5%",
		"type": SkillType.PASSIVE,
		"category": SkillCategory.PASSIVE,
		"element": SkillElement.NONE,
		"rarity": SkillRarity.UNCOMMON,
		"stats": {"crit_chance": 0.05},
		"max_level": 1,
		"icon": "res://assets/skills/crit_boost.png"
	}
	
	skills["crit_boost_3"] = {
		"id": "crit_boost_3",
		"name": "暴击强化 III",
		"description": "提升暴击率8%",
		"type": SkillType.PASSIVE,
		"category": SkillCategory.PASSIVE,
		"element": SkillElement.NONE,
		"rarity": SkillRarity.RARE,
		"stats": {"crit_chance": 0.08},
		"max_level": 1,
		"icon": "res://assets/skills/crit_boost.png"
	}
	
	# 吸血强化
	skills["life_steal_1"] = {
		"id": "life_steal_1",
		"name": "生命汲取 I",
		"description": "攻击时吸取2%伤害值的生命",
		"type": SkillType.PASSIVE,
		"category": SkillCategory.PASSIVE,
		"element": SkillElement.NONE,
		"rarity": SkillRarity.UNCOMMON,
		"stats": {"life_steal": 0.02},
		"max_level": 1,
		"icon": "res://assets/skills/life_steal.png"
	}
	
	skills["life_steal_2"] = {
		"id": "life_steal_2",
		"name": "生命汲取 II",
		"description": "攻击时吸取4%伤害值的生命",
		"type": SkillType.PASSIVE,
		"category": SkillCategory.PASSIVE,
		"element": SkillElement.NONE,
		"rarity": SkillRarity.RARE,
		"stats": {"life_steal": 0.04},
		"max_level": 1,
		"icon": "res://assets/skills/life_steal.png"
	}
	
	skills["life_steal_3"] = {
		"id": "life_steal_3",
		"name": "生命汲取 III",
		"description": "攻击时吸取6%伤害值的生命",
		"type": SkillType.PASSIVE,
		"category": SkillCategory.PASSIVE,
		"element": SkillElement.NONE,
		"rarity": SkillRarity.EPIC,
		"stats": {"life_steal": 0.06},
		"max_level": 1,
		"icon": "res://assets/skills/life_steal.png"
	}


# =============================================================================
# 弹幕类技能 (15种)
# =============================================================================

func _register_bullet_skills() -> void:
	# 基础弹幕
	skills["single_shot"] = {
		"id": "single_shot",
		"name": "单发射击",
		"description": "发射一发子弹攻击敌人",
		"type": SkillType.ACTIVE,
		"category": SkillCategory.OFFENSIVE,
		"element": SkillElement.PHYSICAL,
		"rarity": SkillRarity.COMMON,
		"damage": 10.0,
		"cooldown": 0.5,
		"mana_cost": 5,
		"bullet_count": 1,
		"projectile_speed": 400.0,
		"max_level": 3,
		"icon": "res://assets/skills/single_shot.png"
	}
	
	skills["double_shot"] = {
		"id": "double_shot",
		"name": "双发射击",
		"description": "同时发射两发子弹",
		"type": SkillType.ACTIVE,
		"category": SkillCategory.OFFENSIVE,
		"element": SkillElement.PHYSICAL,
		"rarity": SkillRarity.UNCOMMON,
		"damage": 8.0,
		"cooldown": 0.6,
		"mana_cost": 8,
		"bullet_count": 2,
		"projectile_speed": 420.0,
		"max_level": 3,
		"icon": "res://assets/skills/double_shot.png"
	}
	
	skills["triple_shot"] = {
		"id": "triple_shot",
		"name": "三连射击",
		"description": "同时发射三发子弹",
		"type": SkillType.ACTIVE,
		"category": SkillCategory.OFFENSIVE,
		"element": SkillElement.PHYSICAL,
		"rarity": SkillRarity.RARE,
		"damage": 7.0,
		"cooldown": 0.7,
		"mana_cost": 12,
		"bullet_count": 3,
		"projectile_speed": 450.0,
		"max_level": 3,
		"icon": "res://assets/skills/triple_shot.png"
	}
	
	# 扇形弹幕
	skills["fan_shot_1"] = {
		"id": "fan_shot_1",
		"name": "扇形弹幕 I",
		"description": "发射5发子弹形成扇形攻击",
		"type": SkillType.ACTIVE,
		"category": SkillCategory.OFFENSIVE,
		"element": SkillElement.PHYSICAL,
		"rarity": SkillRarity.UNCOMMON,
		"damage": 6.0,
		"cooldown": 1.2,
		"mana_cost": 15,
		"bullet_count": 5,
		"spread_angle": 60.0,
		"projectile_speed": 380.0,
		"max_level": 3,
		"icon": "res://assets/skills/fan_shot.png"
	}
	
	skills["fan_shot_2"] = {
		"id": "fan_shot_2",
		"name": "扇形弹幕 II",
		"description": "发射7发子弹形成扇形攻击",
		"type": SkillType.ACTIVE,
		"category": SkillCategory.OFFENSIVE,
		"element": SkillElement.PHYSICAL,
		"rarity": SkillRarity.RARE,
		"damage": 6.0,
		"cooldown": 1.4,
		"mana_cost": 20,
		"bullet_count": 7,
		"spread_angle": 75.0,
		"projectile_speed": 400.0,
		"max_level": 3,
		"icon": "res://assets/skills/fan_shot.png"
	}
	
	skills["fan_shot_3"] = {
		"id": "fan_shot_3",
		"name": "扇形弹幕 III",
		"description": "发射9发子弹形成扇形攻击",
		"type": SkillType.ACTIVE,
		"category": SkillCategory.OFFENSIVE,
		"element": SkillElement.PHYSICAL,
		"rarity": SkillRarity.EPIC,
		"damage": 6.0,
		"cooldown": 1.6,
		"mana_cost": 25,
		"bullet_count": 9,
		"spread_angle": 90.0,
		"projectile_speed": 420.0,
		"max_level": 3,
		"icon": "res://assets/skills/fan_shot.png"
	}
	
	# 圆形弹幕
	skills["circular_burst_1"] = {
		"id": "circular_burst_1",
		"name": "圆形弹幕 I",
		"description": "向四周发射12发子弹",
		"type": SkillType.ACTIVE,
		"category": SkillCategory.OFFENSIVE,
		"element": SkillElement.PHYSICAL,
		"rarity": SkillRarity.RARE,
		"damage": 5.0,
		"cooldown": 2.0,
		"mana_cost": 25,
		"bullet_count": 12,
		"projectile_speed": 350.0,
		"max_level": 3,
		"icon": "res://assets/skills/circular_burst.png"
	}
	
	skills["circular_burst_2"] = {
		"id": "circular_burst_2",
		"name": "圆形弹幕 II",
		"description": "向四周发射16发子弹",
		"type": SkillType.ACTIVE,
		"category": SkillCategory.OFFENSIVE,
		"element": SkillElement.PHYSICAL,
		"rarity": SkillRarity.EPIC,
		"damage": 5.0,
		"cooldown": 2.5,
		"mana_cost": 35,
		"bullet_count": 16,
		"projectile_speed": 380.0,
		"max_level": 3,
		"icon": "res://assets/skills/circular_burst.png"
	}
	
	skills["circular_burst_3"] = {
		"id": "circular_burst_3",
		"name": "圆形弹幕 III",
		"description": "向四周发射20发子弹",
		"type": SkillType.ACTIVE,
		"category": SkillCategory.OFFENSIVE,
		"element": SkillElement.PHYSICAL,
		"rarity": SkillRarity.LEGENDARY,
		"damage": 5.0,
		"cooldown": 3.0,
		"mana_cost": 45,
		"bullet_count": 20,
		"projectile_speed": 400.0,
		"max_level": 3,
		"icon": "res://assets/skills/circular_burst.png"
	}
	
	# 特殊弹幕
	skills["spiral_shot"] = {
		"id": "spiral_shot",
		"name": "螺旋弹幕",
		"description": "发射螺旋状弹幕，持续旋转攻击",
		"type": SkillType.ACTIVE,
		"category": SkillCategory.OFFENSIVE,
		"element": SkillElement.ARCANE,
		"rarity": SkillRarity.EPIC,
		"damage": 4.0,
		"cooldown": 3.5,
		"mana_cost": 40,
		"duration": 3.0,
		"bullet_count": 24,
		"projectile_speed": 300.0,
		"max_level": 3,
		"icon": "res://assets/skills/spiral_shot.png"
	}
	
	skills["spread_shot"] = {
		"id": "spread_shot",
		"name": "散射弹幕",
		"description": "发射大量散开的子弹",
		"type": SkillType.ACTIVE,
		"category": SkillCategory.OFFENSIVE,
		"element": SkillElement.PHYSICAL,
		"rarity": SkillRarity.UNCOMMON,
		"damage": 3.0,
		"cooldown": 1.5,
		"mana_cost": 18,
		"bullet_count": 8,
		"spread_range": 120.0,
		"projectile_speed": 350.0,
		"max_level": 3,
		"icon": "res://assets/skills/spread_shot.png"
	}
	
	skills["pierce_shot"] = {
		"id": "pierce_shot",
		"name": "穿透弹",
		"description": "发射可穿透敌人的子弹",
		"type": SkillType.ACTIVE,
		"category": SkillCategory.OFFENSIVE,
		"element": SkillElement.PHYSICAL,
		"rarity": SkillRarity.RARE,
		"damage": 15.0,
		"cooldown": 1.8,
		"mana_cost": 20,
		"pierce_count": 3,
		"projectile_speed": 500.0,
		"max_level": 3,
		"icon": "res://assets/skills/pierce_shot.png"
	}
	
	skills["bounce_shot"] = {
		"id": "bounce_shot",
		"name": "反弹弹",
		"description": "发射可反弹的子弹，最多反弹3次",
		"type": SkillType.ACTIVE,
		"category": SkillCategory.OFFENSIVE,
		"element": SkillElement.PHYSICAL,
		"rarity": SkillRarity.RARE,
		"damage": 12.0,
		"cooldown": 2.0,
		"mana_cost": 22,
		"bounce_count": 3,
		"projectile_speed": 450.0,
		"max_level": 3,
		"icon": "res://assets/skills/bounce_shot.png"
	}
	
	skills["explosive_shot"] = {
		"id": "explosive_shot",
		"name": "爆炸弹",
		"description": "发射爆炸子弹，命中时造成范围伤害",
		"type": SkillType.ACTIVE,
		"category": SkillCategory.OFFENSIVE,
		"element": SkillElement.FIRE,
		"rarity": SkillRarity.EPIC,
		"damage": 20.0,
		"cooldown": 2.5,
		"mana_cost": 35,
		"explosion_radius": 80.0,
		"projectile_speed": 350.0,
		"max_level": 3,
		"icon": "res://assets/skills/explosive_shot.png"
	}


# =============================================================================
# 元素类技能 (10种)
# =============================================================================

func _register_element_skills() -> void:
	skills["fire_bullet"] = {
		"id": "fire_bullet",
		"name": "火焰弹",
		"description": "发射火焰子弹，造成燃烧伤害",
		"type": SkillType.ACTIVE,
		"category": SkillCategory.OFFENSIVE,
		"element": SkillElement.FIRE,
		"rarity": SkillRarity.UNCOMMON,
		"damage": 12.0,
		"cooldown": 1.0,
		"mana_cost": 15,
		"burn_damage": 3.0,
		"burn_duration": 3.0,
		"projectile_speed": 400.0,
		"max_level": 3,
		"icon": "res://assets/skills/fire_bullet.png"
	}
	
	skills["ice_bullet"] = {
		"id": "ice_bullet",
		"name": "冰霜弹",
		"description": "发射冰霜子弹，减速敌人",
		"type": SkillType.ACTIVE,
		"category": SkillCategory.OFFENSIVE,
		"element": SkillElement.ICE,
		"rarity": SkillRarity.UNCOMMON,
		"damage": 10.0,
		"cooldown": 1.0,
		"mana_cost": 15,
		"slow_amount": 0.4,
		"slow_duration": 2.5,
		"projectile_speed": 380.0,
		"max_level": 3,
		"icon": "res://assets/skills/ice_bullet.png"
	}
	
	skills["lightning_bullet"] = {
		"id": "lightning_bullet",
		"name": "闪电弹",
		"description": "发射闪电子弹，可连锁攻击附近敌人",
		"type": SkillType.ACTIVE,
		"category": SkillCategory.OFFENSIVE,
		"element": SkillElement.LIGHTNING,
		"rarity": SkillRarity.RARE,
		"damage": 8.0,
		"cooldown": 1.2,
		"mana_cost": 20,
		"chain_count": 3,
		"chain_range": 150.0,
		"projectile_speed": 600.0,
		"max_level": 3,
		"icon": "res://assets/skills/lightning_bullet.png"
	}
	
	skills["poison_bullet"] = {
		"id": "poison_bullet",
		"name": "毒素弹",
		"description": "发射毒素子弹，造成持续伤害",
		"type": SkillType.ACTIVE,
		"category": SkillCategory.OFFENSIVE,
		"element": SkillElement.SHADOW,
		"rarity": SkillRarity.UNCOMMON,
		"damage": 6.0,
		"cooldown": 0.8,
		"mana_cost": 12,
		"poison_damage": 2.5,
		"poison_duration": 5.0,
		"projectile_speed": 400.0,
		"max_level": 3,
		"icon": "res://assets/skills/poison_bullet.png"
	}
	
	skills["holy_bullet"] = {
		"id": "holy_bullet",
		"name": "神圣弹",
		"description": "发射神圣子弹，对亡灵敌人造成额外伤害",
		"type": SkillType.ACTIVE,
		"category": SkillCategory.OFFENSIVE,
		"element": SkillElement.HOLY,
		"rarity": SkillRarity.RARE,
		"damage": 10.0,
		"cooldown": 1.0,
		"mana_cost": 18,
		"undead_bonus": 0.5,
		"projectile_speed": 450.0,
		"max_level": 3,
		"icon": "res://assets/skills/holy_bullet.png"
	}
	
	skills["shadow_bullet"] = {
		"id": "shadow_bullet",
		"name": "暗影弹",
		"description": "发射暗影子弹，可穿透敌人",
		"type": SkillType.ACTIVE,
		"category": SkillCategory.OFFENSIVE,
		"element": SkillElement.SHADOW,
		"rarity": SkillRarity.RARE,
		"damage": 14.0,
		"cooldown": 1.5,
		"mana_cost": 22,
		"pierce_count": 2,
		"projectile_speed": 480.0,
		"max_level": 3,
		"icon": "res://assets/skills/shadow_bullet.png"
	}
	
	skills["arcane_bullet"] = {
		"id": "arcane_bullet",
		"name": "奥术弹",
		"description": "发射奥术子弹，命中时造成溅射伤害",
		"type": SkillType.ACTIVE,
		"category": SkillCategory.OFFENSIVE,
		"element": SkillElement.ARCANE,
		"rarity": SkillRarity.RARE,
		"damage": 15.0,
		"cooldown": 1.8,
		"mana_cost": 25,
		"splash_radius": 60.0,
		"splash_damage_percent": 0.5,
		"projectile_speed": 420.0,
		"max_level": 3,
		"icon": "res://assets/skills/arcane_bullet.png"
	}
	
	skills["void_bullet"] = {
		"id": "void_bullet",
		"name": "虚空弹",
		"description": "发射虚空子弹，无视敌人防御",
		"type": SkillType.ACTIVE,
		"category": SkillCategory.OFFENSIVE,
		"element": SkillElement.VOID,
		"rarity": SkillRarity.EPIC,
		"damage": 18.0,
		"cooldown": 2.0,
		"mana_cost": 30,
		"ignore_defense": true,
		"projectile_speed": 500.0,
		"max_level": 3,
		"icon": "res://assets/skills/void_bullet.png"
	}
	
	skills["chaos_bullet"] = {
		"id": "chaos_bullet",
		"name": "混沌弹",
		"description": "发射混沌子弹，随机触发元素效果",
		"type": SkillType.ACTIVE,
		"category": SkillCategory.OFFENSIVE,
		"element": SkillElement.CHAOS,
		"rarity": SkillRarity.EPIC,
		"damage": 12.0,
		"cooldown": 1.5,
		"mana_cost": 28,
		"random_effects": ["fire", "ice", "lightning", "poison", "arcane"],
		"projectile_speed": 400.0,
		"max_level": 3,
		"icon": "res://assets/skills/chaos_bullet.png"
	}
	
	skills["rainbow_bullet"] = {
		"id": "rainbow_bullet",
		"name": "彩虹弹",
		"description": "发射彩虹子弹，同时拥有多种元素效果",
		"type": SkillType.ACTIVE,
		"category": SkillCategory.OFFENSIVE,
		"element": SkillElement.ARCANE,
		"rarity": SkillRarity.LEGENDARY,
		"damage": 20.0,
		"cooldown": 2.5,
		"mana_cost": 50,
		"elements": ["fire", "ice", "lightning", "holy"],
		"projectile_speed": 450.0,
		"max_level": 3,
		"icon": "res://assets/skills/rainbow_bullet.png"
	}


# =============================================================================
# 特殊技能 (10种)
# =============================================================================

func _register_special_skills() -> void:
	skills["laser_beam"] = {
		"id": "laser_beam",
		"name": "激光束",
		"description": "发射一道持续激光，对直线上敌人造成伤害",
		"type": SkillType.ACTIVE,
		"category": SkillCategory.OFFENSIVE,
		"element": SkillElement.ARCANE,
		"rarity": SkillRarity.EPIC,
		"damage": 5.0,
		"cooldown": 4.0,
		"mana_cost": 40,
		"duration": 2.0,
		"beam_width": 30.0,
		"beam_range": 500.0,
		"max_level": 3,
		"icon": "res://assets/skills/laser_beam.png"
	}
	
	skills["screen_nuke"] = {
		"id": "screen_nuke",
		"name": "全屏轰炸",
		"description": "对屏幕内所有敌人造成大量伤害",
		"type": SkillType.ACTIVE,
		"category": SkillCategory.OFFENSIVE,
		"element": SkillElement.ARCANE,
		"rarity": SkillRarity.LEGENDARY,
		"damage": 100.0,
		"cooldown": 30.0,
		"mana_cost": 100,
		"max_level": 3,
		"icon": "res://assets/skills/screen_nuke.png"
	}
	
	skills["homing_missile"] = {
		"id": "homing_missile",
		"name": "追踪导弹",
		"description": "发射自动追踪敌人的导弹",
		"type": SkillType.ACTIVE,
		"category": SkillCategory.OFFENSIVE,
		"element": SkillElement.FIRE,
		"rarity": SkillRarity.RARE,
		"damage": 25.0,
		"cooldown": 3.0,
		"mana_cost": 30,
		"missile_count": 3,
		"homing_speed": 350.0,
		"explosion_radius": 50.0,
		"max_level": 3,
		"icon": "res://assets/skills/homing_missile.png"
	}
	
	skills["lightning_storm"] = {
		"id": "lightning_storm",
		"name": "闪电风暴",
		"description": "召唤闪电风暴，随机攻击范围内敌人",
		"type": SkillType.ACTIVE,
		"category": SkillCategory.OFFENSIVE,
		"element": SkillElement.LIGHTNING,
		"rarity": SkillRarity.EPIC,
		"damage": 15.0,
		"cooldown": 5.0,
		"mana_cost": 45,
		"duration": 4.0,
		"strike_interval": 0.5,
		"storm_radius": 300.0,
		"max_level": 3,
		"icon": "res://assets/skills/lightning_storm.png"
	}
	
	skills["black_hole"] = {
		"id": "black_hole",
		"name": "黑洞吸引",
		"description": "创建黑洞，吸引并伤害周围敌人",
		"type": SkillType.ACTIVE,
		"category": SkillCategory.CONTROL,
		"element": SkillElement.VOID,
		"rarity": SkillRarity.LEGENDARY,
		"damage": 8.0,
		"cooldown": 8.0,
		"mana_cost": 60,
		"duration": 3.0,
		"pull_radius": 200.0,
		"pull_strength": 300.0,
		"max_level": 3,
		"icon": "res://assets/skills/black_hole.png"
	}
	
	skills["time_stop"] = {
		"id": "time_stop",
		"name": "时间停止",
		"description": "停止所有敌人的时间，持续短暂时间",
		"type": SkillType.ACTIVE,
		"category": SkillCategory.CONTROL,
		"element": SkillElement.ARCANE,
		"rarity": SkillRarity.LEGENDARY,
		"damage": 0.0,
		"cooldown": 20.0,
		"mana_cost": 80,
		"duration": 2.0,
		"max_level": 3,
		"icon": "res://assets/skills/time_stop.png"
	}
	
	skills["mirror_image"] = {
		"id": "mirror_image",
		"name": "镜像分身",
		"description": "创建分身协助战斗",
		"type": SkillType.ACTIVE,
		"category": SkillCategory.SUPPORT,
		"element": SkillElement.ARCANE,
		"rarity": SkillRarity.EPIC,
		"damage": 0.0,
		"cooldown": 15.0,
		"mana_cost": 50,
		"duration": 8.0,
		"clone_count": 2,
		"clone_damage_percent": 0.5,
		"max_level": 3,
		"icon": "res://assets/skills/mirror_image.png"
	}
	
	skills["dash_attack"] = {
		"id": "dash_attack",
		"name": "冲刺攻击",
		"description": "快速冲刺并对路径上敌人造成伤害",
		"type": SkillType.ACTIVE,
		"category": SkillCategory.OFFENSIVE,
		"element": SkillElement.PHYSICAL,
		"rarity": SkillRarity.UNCOMMON,
		"damage": 20.0,
		"cooldown": 3.0,
		"mana_cost": 20,
		"dash_distance": 200.0,
		"dash_speed": 800.0,
		"invincible": true,
		"max_level": 3,
		"icon": "res://assets/skills/dash_attack.png"
	}
	
	skills["teleport_strike"] = {
		"id": "teleport_strike",
		"name": "传送斩击",
		"description": "传送到目标位置并造成范围伤害",
		"type": SkillType.ACTIVE,
		"category": SkillCategory.OFFENSIVE,
		"element": SkillElement.SHADOW,
		"rarity": SkillRarity.RARE,
		"damage": 35.0,
		"cooldown": 5.0,
		"mana_cost": 35,
		"teleport_range": 300.0,
		"strike_radius": 80.0,
		"max_level": 3,
		"icon": "res://assets/skills/teleport_strike.png"
	}
	
	skills["aura_of_doom"] = {
		"id": "aura_of_doom",
		"name": "末日光环",
		"description": "释放毁灭光环，持续伤害周围敌人",
		"type": SkillType.ACTIVE,
		"category": SkillCategory.OFFENSIVE,
		"element": SkillElement.SHADOW,
		"rarity": SkillRarity.LEGENDARY,
		"damage": 10.0,
		"cooldown": 0.5,
		"mana_cost": 5,
		"aura_radius": 150.0,
		"tick_interval": 0.5,
		"max_level": 3,
		"icon": "res://assets/skills/aura_of_doom.png"
	}


# =============================================================================
# 辅助技能 (15种)
# =============================================================================

func _register_support_skills() -> void:
	skills["shield"] = {
		"id": "shield",
		"name": "能量护盾",
		"description": "生成护盾抵挡伤害",
		"type": SkillType.ACTIVE,
		"category": SkillCategory.DEFENSIVE,
		"element": SkillElement.ARCANE,
		"rarity": SkillRarity.UNCOMMON,
		"damage": 0.0,
		"cooldown": 8.0,
		"mana_cost": 25,
		"shield_amount": 50.0,
		"duration": 5.0,
		"max_level": 3,
		"icon": "res://assets/skills/shield.png"
	}
	
	skills["blink"] = {
		"id": "blink",
		"name": "闪现",
		"description": "瞬间传送到指定位置",
		"type": SkillType.ACTIVE,
		"category": SkillCategory.DEFENSIVE,
		"element": SkillElement.ARCANE,
		"rarity": SkillRarity.UNCOMMON,
		"damage": 0.0,
		"cooldown": 5.0,
		"mana_cost": 20,
		"blink_range": 200.0,
		"max_level": 3,
		"icon": "res://assets/skills/blink.png"
	}
	
	skills["heal"] = {
		"id": "heal",
		"name": "治愈",
		"description": "恢复自身生命值",
		"type": SkillType.ACTIVE,
		"category": SkillCategory.SUPPORT,
		"element": SkillElement.HOLY,
		"rarity": SkillRarity.UNCOMMON,
		"damage": 0.0,
		"cooldown": 10.0,
		"mana_cost": 30,
		"heal_amount": 40.0,
		"max_level": 3,
		"icon": "res://assets/skills/heal.png"
	}
	
	skills["mana_regen"] = {
		"id": "mana_regen",
		"name": "法力恢复",
		"description": "提升法力恢复速度",
		"type": SkillType.PASSIVE,
		"category": SkillCategory.PASSIVE,
		"element": SkillElement.ARCANE,
		"rarity": SkillRarity.UNCOMMON,
		"stats": {"mana_regen_percent": 0.3},
		"max_level": 1,
		"icon": "res://assets/skills/mana_regen.png"
	}
	
	skills["iron_wall"] = {
		"id": "iron_wall",
		"name": "铁壁",
		"description": "短时间内大幅提升防御力",
		"type": SkillType.ACTIVE,
		"category": SkillCategory.DEFENSIVE,
		"element": SkillElement.PHYSICAL,
		"rarity": SkillRarity.RARE,
		"damage": 0.0,
		"cooldown": 12.0,
		"mana_cost": 35,
		"defense_bonus": 0.5,
		"duration": 4.0,
		"max_level": 3,
		"icon": "res://assets/skills/iron_wall.png"
	}
	
	skills["reflect"] = {
		"id": "reflect",
		"name": "伤害反射",
		"description": "反射受到的伤害给攻击者",
		"type": SkillType.ACTIVE,
		"category": SkillCategory.DEFENSIVE,
		"element": SkillElement.ARCANE,
		"rarity": SkillRarity.RARE,
		"damage": 0.0,
		"cooldown": 15.0,
		"mana_cost": 40,
		"reflect_percent": 0.3,
		"duration": 5.0,
		"max_level": 3,
		"icon": "res://assets/skills/reflect.png"
	}
	
	skills["invisibility"] = {
		"id": "invisibility",
		"name": "隐身",
		"description": "进入隐身状态，敌人无法发现",
		"type": SkillType.ACTIVE,
		"category": SkillCategory.DEFENSIVE,
		"element": SkillElement.SHADOW,
		"rarity": SkillRarity.EPIC,
		"damage": 0.0,
		"cooldown": 20.0,
		"mana_cost": 50,
		"duration": 3.0,
		"max_level": 3,
		"icon": "res://assets/skills/invisibility.png"
	}
	
	skills["taunt"] = {
		"id": "taunt",
		"name": "嘲讽",
		"description": "嘲讽周围敌人，使其攻击自己",
		"type": SkillType.ACTIVE,
		"category": SkillCategory.DEFENSIVE,
		"element": SkillElement.PHYSICAL,
		"rarity": SkillRarity.UNCOMMON,
		"damage": 0.0,
		"cooldown": 10.0,
		"mana_cost": 20,
		"taunt_radius": 200.0,
		"duration": 3.0,
		"max_level": 3,
		"icon": "res://assets/skills/taunt.png"
	}
	
	skills["speed_aura"] = {
		"id": "speed_aura",
		"name": "加速光环",
		"description": "提升自身移动速度",
		"type": SkillType.PASSIVE,
		"category": SkillCategory.SUPPORT,
		"element": SkillElement.NONE,
		"rarity": SkillRarity.UNCOMMON,
		"stats": {"move_speed_percent": 0.1},
		"aura_radius": 150.0,
		"max_level": 1,
		"icon": "res://assets/skills/speed_aura.png"
	}
	
	skills["healing_aura"] = {
		"id": "healing_aura",
		"name": "治愈光环",
		"description": "持续恢复生命值",
		"type": SkillType.PASSIVE,
		"category": SkillCategory.SUPPORT,
		"element": SkillElement.HOLY,
		"rarity": SkillRarity.RARE,
		"heal_per_second": 2.0,
		"aura_radius": 150.0,
		"max_level": 1,
		"icon": "res://assets/skills/healing_aura.png"
	}
	
	skills["damage_aura"] = {
		"id": "damage_aura",
		"name": "伤害光环",
		"description": "对周围敌人造成持续伤害",
		"type": SkillType.PASSIVE,
		"category": SkillCategory.OFFENSIVE,
		"element": SkillElement.FIRE,
		"rarity": SkillRarity.RARE,
		"damage_per_second": 5.0,
		"aura_radius": 120.0,
		"max_level": 1,
		"icon": "res://assets/skills/damage_aura.png"
	}
	
	skills["slow_aura"] = {
		"id": "slow_aura",
		"name": "减速光环",
		"description": "减速周围敌人",
		"type": SkillType.PASSIVE,
		"category": SkillCategory.CONTROL,
		"element": SkillElement.ICE,
		"rarity": SkillRarity.UNCOMMON,
		"slow_amount": 0.2,
		"aura_radius": 150.0,
		"max_level": 1,
		"icon": "res://assets/skills/slow_aura.png"
	}
	
	skills["critical_aura"] = {
		"id": "critical_aura",
		"name": "暴击光环",
		"description": "提升暴击率",
		"type": SkillType.PASSIVE,
		"category": SkillCategory.PASSIVE,
		"element": SkillElement.NONE,
		"rarity": SkillRarity.RARE,
		"stats": {"crit_chance": 0.1},
		"max_level": 1,
		"icon": "res://assets/skills/critical_aura.png"
	}
	
	skills["vampire_aura"] = {
		"id": "vampire_aura",
		"name": "吸血光环",
		"description": "攻击时吸取生命",
		"type": SkillType.PASSIVE,
		"category": SkillCategory.PASSIVE,
		"element": SkillElement.SHADOW,
		"rarity": SkillRarity.EPIC,
		"stats": {"life_steal": 0.05},
		"max_level": 1,
		"icon": "res://assets/skills/vampire_aura.png"
	}
	
	skills["luck_boost"] = {
		"id": "luck_boost",
		"name": "幸运加成",
		"description": "提升道具掉落率和稀有度",
		"type": SkillType.PASSIVE,
		"category": SkillCategory.PASSIVE,
		"element": SkillElement.NONE,
		"rarity": SkillRarity.RARE,
		"stats": {"luck": 0.2, "drop_rate": 0.15},
		"max_level": 1,
		"icon": "res://assets/skills/luck_boost.png"
	}
