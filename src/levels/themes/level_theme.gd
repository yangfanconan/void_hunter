## Void Hunter - 关卡主题配置
## @description: 定义关卡的主题视觉和内容配置
## @author: Void Hunter Team
## @version: 0.1.0

extends Resource
class_name LevelTheme

# =============================================================================
# 枚举定义
# =============================================================================

## 环境类型
enum EnvironmentType {
	DUNGEON,		## 地牢
	FOREST,			## 森林
	DESERT,			## 沙漠
	ICE,			## 冰雪
	VOLCANIC,		## 火山
	VOID,			## 虚空
	CASTLE			## 城堡
}

# =============================================================================
# 导出变量 - 基本信息
# =============================================================================

## 主题ID
@export var theme_id: String = "dungeon"

## 主题名称
@export var theme_name: String = "Dungeon"

## 环境类型
@export var environment_type: EnvironmentType = EnvironmentType.DUNGEON

## 主题描述
@export_multiline var description: String = ""

# =============================================================================
# 导出变量 - 视觉配置
# =============================================================================

## 背景颜色
@export var background_color: Color = Color(0.1, 0.1, 0.15)

## 环境光颜色
@export var ambient_light_color: Color = Color(0.3, 0.3, 0.4)

## 环境光强度
@export_range(0.0, 1.0) var ambient_light_energy: float = 0.5

## 地板瓦片集
@export var floor_tileset: TileSet

## 墙壁瓦片集
@export var wall_tileset: TileSet

## 装饰物瓦片集
@export var decoration_tileset: TileSet

## 背景音乐
@export var bgm: AudioStream

## 环境音效列表
@export var ambient_sounds: Array[AudioStream] = []

# =============================================================================
# 导出变量 - 敌人配置
# =============================================================================

## 可生成的敌人列表
@export var enemy_pool: Array[PackedScene] = []

## Boss列表
@export var boss_pool: Array[PackedScene] = []

## 敌人生成权重
@export var enemy_weights: Dictionary = {}

# =============================================================================
# 导出变量 - 道具配置
# =============================================================================

## 可掉落的道具列表
@export var item_pool: Array[String] = []

## 道具稀有度权重
@export var item_rarity_weights: Dictionary = {
	0: 50,  # Common
	1: 30,  # Uncommon
	2: 15,  # Rare
	3: 4,   # Epic
	4: 1    # Legendary
}

# =============================================================================
# 导出变量 - 难度配置
# =============================================================================

## 基础难度系数
@export var base_difficulty: float = 1.0

## 难度增长率
@export var difficulty_growth: float = 0.1

## 最小关卡
@export var min_level: int = 1

## 最大关卡
@export var max_level: int = 10

# =============================================================================
# 公共方法
# =============================================================================

## 获取随机敌人
func get_random_enemy() -> PackedScene:
	"""
	从敌人池中随机选择一个敌人
	@return: 敌人场景
	"""
	if enemy_pool.is_empty():
		return null
	
	return enemy_pool[randi() % enemy_pool.size()]


## 获取随机Boss
func get_random_boss() -> PackedScene:
	"""
	从Boss池中随机选择一个Boss
	@return: Boss场景
	"""
	if boss_pool.is_empty():
		return null
	
	return boss_pool[randi() % boss_pool.size()]


## 计算关卡难度
func calculate_difficulty(level_index: int) -> float:
	"""
	计算指定关卡的难度系数
	@param level_index: 关卡索引
	@return: 难度系数
	"""
	return base_difficulty * (1.0 + difficulty_growth * (level_index - 1))


## 是否适用于指定关卡
func is_applicable_for_level(level_index: int) -> bool:
	"""
	检查此主题是否适用于指定关卡
	@param level_index: 关卡索引
	@return: 是否适用
	"""
	return level_index >= min_level and level_index <= max_level


## 获取环境音效
func get_random_ambient_sound() -> AudioStream:
	"""
	获取随机环境音效
	@return: 音频流
	"""
	if ambient_sounds.is_empty():
		return null
	
	return ambient_sounds[randi() % ambient_sounds.size()]


## 序列化为字典
func to_dictionary() -> Dictionary:
	"""
	将主题配置序列化为字典
	@return: 配置字典
	"""
	return {
		"theme_id": theme_id,
		"theme_name": theme_name,
		"environment_type": environment_type,
		"background_color": background_color.to_html(),
		"ambient_light_color": ambient_light_color.to_html(),
		"ambient_light_energy": ambient_light_energy,
		"base_difficulty": base_difficulty,
		"difficulty_growth": difficulty_growth,
		"min_level": min_level,
		"max_level": max_level,
		"enemy_weights": enemy_weights,
		"item_rarity_weights": item_rarity_weights
	}
