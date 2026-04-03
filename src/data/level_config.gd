## Void Hunter - 关卡配置数据
## @description: 定义所有关卡的具体配置，包括主题、Boss、解锁条件等
## @author: Void Hunter Team
## @version: 1.0.0

extends Resource
class_name LevelConfigData

# =============================================================================
# 关卡定义
# =============================================================================

## 关卡配置列表 - 对应GDD设计的7关卡
const LEVELS := {
	1: {
		"id": 1,
		"name": "地牢深处",
		"theme": LevelTheme.EnvironmentType.DUNGEON,
		"waves": 5,
		"boss_id": "dungeon_lord",
		"boss_name": "骷髅王",
		"unlock_condition": null,  # 默认解锁
		"background_color": Color(0.1, 0.08, 0.15),
		"enemy_types": ["skeleton_warrior", "skeleton_archer", "slime_forest"],
		"difficulty": 1.0,
		"description": "在阴暗的地牢中，面对不死军团的威胁。",
	},
	2: {
		"id": 2,
		"name": "幽暗森林",
		"theme": LevelTheme.EnvironmentType.FOREST,
		"waves": 7,
		"boss_id": "forest_guardian",
		"boss_name": "森林守护者",
		"unlock_condition": {"type": "complete_level", "level": 1},
		"background_color": Color(0.05, 0.12, 0.08),
		"enemy_types": ["goblin", "wolf", "treant", "forest_spider"],
		"difficulty": 1.2,
		"description": "神秘的森林中隐藏着自然的守护者。",
	},
	3: {
		"id": 3,
		"name": "灼热沙漠",
		"theme": LevelTheme.EnvironmentType.DESERT,
		"waves": 8,
		"boss_id": "sand_worm",
		"boss_name": "沙虫",
		"unlock_condition": {"type": "complete_level", "level": 2},
		"background_color": Color(0.25, 0.2, 0.12),
		"enemy_types": ["scorpion", "sand_golem", "mummy", "desert_raider"],
		"difficulty": 1.4,
		"description": "无尽的沙海中，巨大的沙虫正在等待猎物。",
	},
	4: {
		"id": 4,
		"name": "冰封之地",
		"theme": LevelTheme.EnvironmentType.ICE,
		"waves": 9,
		"boss_id": "frost_giant",
		"boss_name": "冰霜巨人",
		"unlock_condition": {"type": "complete_level", "level": 3},
		"background_color": Color(0.15, 0.2, 0.25),
		"enemy_types": ["ice_slime", "frost_wolf", "ice_elemental", "snow_golem"],
		"difficulty": 1.6,
		"description": "永恒的冰原上，冰霜巨人统治着这片土地。",
	},
	5: {
		"id": 5,
		"name": "熔岩火山",
		"theme": LevelTheme.EnvironmentType.VOLCANIC,
		"waves": 10,
		"boss_id": "flame_emperor",
		"boss_name": "炎魔",
		"unlock_condition": {"type": "complete_level", "level": 4},
		"background_color": Color(0.2, 0.08, 0.05),
		"enemy_types": ["fire_imp", "lava_golem", "phoenix_hatchling", "magma_crawler"],
		"difficulty": 1.8,
		"description": "火山的核心区域，炎魔的领地。",
	},
	6: {
		"id": 6,
		"name": "诅咒城堡",
		"theme": LevelTheme.EnvironmentType.CASTLE,
		"waves": 12,
		"boss_id": "dark_knight",
		"boss_name": "黑暗骑士",
		"unlock_condition": {"type": "complete_level", "level": 5},
		"background_color": Color(0.08, 0.06, 0.12),
		"enemy_types": ["shadow_knight", "ghost", "cursed_armor", "dark_mage"],
		"difficulty": 2.0,
		"description": "被诅咒的城堡中，黑暗骑士等待着挑战者。",
	},
	7: {
		"id": 7,
		"name": "虚空深渊",
		"theme": LevelTheme.EnvironmentType.VOID,
		"waves": 15,
		"boss_id": "void_entity",
		"boss_name": "虚空领主",
		"unlock_condition": {"type": "complete_level", "level": 6},
		"background_color": Color(0.05, 0.02, 0.1),
		"enemy_types": ["void_walker", "shadow_crawler", "void_elemental", "reality_tear"],
		"difficulty": 2.5,
		"description": "虚空的尽头，最终BOSS虚空领主镇守此地。",
	},
}

## Boss配置
const BOSSES := {
	"dungeon_lord": {
		"id": "dungeon_lord",
		"name": "骷髅王",
		"health": 500,
		"damage": 25,
		"skills": ["summon_skeletons", "bone_storm", "crown_slam"],
		"phases": 2,
		"reward_exp": 200,
		"reward_gold": 150,
	},
	"forest_guardian": {
		"id": "forest_guardian",
		"name": "森林守护者",
		"health": 700,
		"damage": 30,
		"skills": ["root_trap", "vine_whip", "nature_rage"],
		"phases": 2,
		"reward_exp": 300,
		"reward_gold": 200,
	},
	"sand_worm": {
		"id": "sand_worm",
		"name": "沙虫",
		"health": 900,
		"damage": 35,
		"skills": ["burrow", "sand_storm", "devour"],
		"phases": 3,
		"reward_exp": 400,
		"reward_gold": 250,
	},
	"frost_giant": {
		"id": "frost_giant",
		"name": "冰霜巨人",
		"health": 1200,
		"damage": 40,
		"skills": ["ice_shield", "frost_breath", "glacial_stomp"],
		"phases": 3,
		"reward_exp": 500,
		"reward_gold": 300,
	},
	"flame_emperor": {
		"id": "flame_emperor",
		"name": "炎魔",
		"health": 1500,
		"damage": 50,
		"skills": ["fire_storm", "lava_pool", "meteor_strike"],
		"phases": 3,
		"reward_exp": 600,
		"reward_gold": 400,
	},
	"dark_knight": {
		"id": "dark_knight",
		"name": "黑暗骑士",
		"health": 2000,
		"damage": 55,
		"skills": ["dark_charge", "shadow_cleave", "soul_drain"],
		"phases": 4,
		"reward_exp": 800,
		"reward_gold": 500,
	},
	"void_entity": {
		"id": "void_entity",
		"name": "虚空领主",
		"health": 3000,
		"damage": 70,
		"skills": ["void_rift", "reality_tear", "dimension_shift", "void_annihilation"],
		"phases": 5,
		"reward_exp": 1500,
		"reward_gold": 1000,
	},
}

# =============================================================================
# 公共方法
# =============================================================================

## 获取关卡配置
static func get_level_config(level_id: int) -> Dictionary:
	return LEVELS.get(level_id, {})


## 获取Boss配置
static func get_boss_config(boss_id: String) -> Dictionary:
	return BOSSES.get(boss_id, {})


## 获取所有关卡列表
static func get_all_levels() -> Dictionary:
	return LEVELS.duplicate()


## 检查关卡是否解锁
static func is_level_unlocked(level_id: int, completed_levels: Array) -> bool:
	var config: Dictionary = LEVELS.get(level_id, {})
	if config.is_empty():
		return false

	var unlock_condition: Dictionary = config.get("unlock_condition", {})
	if unlock_condition.is_empty():
		return true  # 无解锁条件，默认解锁

	var condition_type: String = unlock_condition.get("type", "")
	match condition_type:
		"complete_level":
			var required_level: int = unlock_condition.get("level", 0)
			return required_level in completed_levels
		_:
			return true


## 获取主题的环境类型
static func get_theme_type(level_id: int) -> int:
	var config: Dictionary = LEVELS.get(level_id, {})
	return config.get("theme", LevelTheme.EnvironmentType.DUNGEON)


## 获取关卡的Boss
static func get_level_boss(level_id: int) -> Dictionary:
	var config: Dictionary = LEVELS.get(level_id, {})
	var boss_id: String = config.get("boss_id", "")
	return BOSSES.get(boss_id, {})


## 获取关卡难度系数
static func get_level_difficulty(level_id: int) -> float:
	var config: Dictionary = LEVELS.get(level_id, {})
	return config.get("difficulty", 1.0)


## 获取关卡波次数
static func get_level_waves(level_id: int) -> int:
	var config: Dictionary = LEVELS.get(level_id, {})
	return config.get("waves", 5)


## 获取关卡敌人类型列表
static func get_level_enemy_types(level_id: int) -> Array:
	var config: Dictionary = LEVELS.get(level_id, {})
	return config.get("enemy_types", [])