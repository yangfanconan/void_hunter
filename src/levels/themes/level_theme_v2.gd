## Void Hunter - 关卡主题系统 V2
## @description: 8种全新主题场景，每种包含独立配色、地形、敌人组合、环境危险
## @version: 2.0.0

extends Resource
class_name LevelThemeV2

# =============================================================================
# 枚举定义
# =============================================================================

enum ThemeId {
	FOREST,			## 森林
	DESERT,			## 沙漠
	SNOW,			## 雪地
	LAVA,			## 熔岩
	MECHANICAL,		## 机械城
	ABYSS,			## 深渊
	SKY_ISLAND,		## 浮空岛
	CEMETERY,		## 墓地
	CAVE,			## 洞穴
	RUINS,			## 废墟
	VOID			## 虚空
}

enum Weather {
	NONE,
	RAIN,
	SNOW,
	SANDSTORM,
	FOG,
	WIND,
	LAVA_RAIN,
	THUNDER
}

enum EnvironmentHazard {
	NONE,
	MOVING_PLATFORM,	## 移动平台
	FALLING_ROCK,		## 落石
	LASER,				## 激光
	SPIKE,				## 尖刺
	LAVA_POOL,			## 熔岩池
	POISON_GAS,			## 毒气
	WIND_GUST,			## 强风
	ICE_PATCH,			## 冰面
	ELECTRIC_FIELD,		## 电场
	SAW_BLADE			## 锯片
}

# =============================================================================
# 主题数据定义
# =============================================================================

## 主题配置数据
class ThemeData:
	var id: ThemeId
	var name: String
	var description: String
	# 颜色配置
	var bg_color: Color
	var floor_color: Color
	var wall_color: Color
	var accent_color: Color
	var fog_color: Color
	var particle_color: Color
	# 环境配置
	var weather: Weather
	var hazards: Array[EnvironmentHazard] = []
	var hazard_frequency: float = 0.3  ## 危险出现频率
	# 敌人权重
	var enemy_weights: Dictionary = {}
	# 地形特征
	var has_water: bool = false
	var has_chasms: bool = false
	var has_elevation: bool = false
	var platform_density: float = 0.2
	# 音乐
	var ambient_sound: String = ""
	var music_track: String = ""
	# 难度修饰
	var difficulty_modifier: float = 1.0
	# Boss
	var boss_id: String = ""
	# 解锁条件
	var unlock_wave: int = 1
	var unlock_description: String = ""

	func _init(p_id: ThemeId) -> void:
		id = p_id

# =============================================================================
# 公共变量
# =============================================================================

var themes: Dictionary = {}
var _is_loaded: bool = false

# =============================================================================
# 公共方法
# =============================================================================

## 加载所有主题
func load_themes() -> void:
	if _is_loaded:
		return

	_register_forest()
	_register_desert()
	_register_snow()
	_register_lava()
	_register_mechanical()
	_register_abyss()
	_register_sky_island()
	_register_cemetery()
	_register_cave()
	_register_ruins()
	_register_void()

	_is_loaded = true

## 获取主题数据
func get_theme(theme_id: ThemeId) -> ThemeData:
	if not _is_loaded:
		load_themes()
	return themes.get(theme_id, null)

## 获取随机主题（根据波数）
func get_random_theme(wave: int = 1) -> ThemeData:
	if not _is_loaded:
		load_themes()

	var available: Array[ThemeData] = []
	for theme_id in themes.keys():
		var theme: ThemeData = themes[theme_id]
		if wave >= theme.unlock_wave:
			available.append(theme)

	if available.is_empty():
		return themes[ThemeId.FOREST]

	return available[randi() % available.size()]

## 获取主题的敌人生成权重
func get_enemy_weights(theme_id: ThemeId) -> Dictionary:
	var theme: ThemeData = get_theme(theme_id)
	if theme:
		return theme.enemy_weights
	return {}

## 获取主题的危险类型列表
func get_hazards(theme_id: ThemeId) -> Array[EnvironmentHazard]:
	var theme: ThemeData = get_theme(theme_id)
	if theme:
		return theme.hazards
	return []

## 获取主题颜色方案
func get_theme_colors(theme_id: ThemeId) -> Dictionary:
	var theme: ThemeData = get_theme(theme_id)
	if theme == null:
		return {
			"bg": Color(0.15, 0.15, 0.2),
			"floor": Color(0.3, 0.3, 0.35),
			"wall": Color(0.2, 0.2, 0.25),
			"accent": Color(0.5, 0.5, 0.6),
			"particle": Color(0.5, 0.5, 0.5)
		}
	return {
		"bg": theme.bg_color,
		"floor": theme.floor_color,
		"wall": theme.wall_color,
		"accent": theme.accent_color,
		"particle": theme.particle_color
	}

## 根据主题获取Boss ID
func get_boss_for_theme(theme_id: ThemeId) -> String:
	var theme: ThemeData = get_theme(theme_id)
	if theme:
		return theme.boss_id
	return ""

# =============================================================================
# 主题注册
# =============================================================================

func _register_forest() -> void:
	var t := ThemeData.new(ThemeId.FOREST)
	t.name = "幽暗森林"
	t.description = "古老的森林，充满了危险的生物和隐藏的陷阱"
	# 颜色
	t.bg_color = Color(0.05, 0.12, 0.05)
	t.floor_color = Color(0.15, 0.25, 0.1)
	t.wall_color = Color(0.1, 0.2, 0.08)
	t.accent_color = Color(0.3, 0.6, 0.2)
	t.fog_color = Color(0.1, 0.2, 0.1, 0.3)
	t.particle_color = Color(0.4, 0.7, 0.3)
	# 环境
	t.weather = Weather.FOG
	t.hazards = [EnvironmentHazard.SPIKE, EnvironmentHazard.POISON_GAS, EnvironmentHazard.FALLING_ROCK]
	t.hazard_frequency = 0.2
	# 敌人权重
	t.enemy_weights = {
		"forest_slime": 30,
		"wolf": 25,
		"mushroom": 20,
		"treant": 15,
		"forest_elite": 10
	}
	# 地形
	t.has_water = true
	t.platform_density = 0.15
	# 其他
	t.ambient_sound = "forest_ambient"
	t.music_track = "forest_theme"
	t.boss_id = "forest_guardian"
	t.unlock_wave = 1
	t.unlock_description = "初始可用"
	themes[ThemeId.FOREST] = t

func _register_desert() -> void:
	var t := ThemeData.new(ThemeId.DESERT)
	t.name = "灼热沙漠"
	t.description = "酷热的沙漠，沙暴席卷，隐藏着远古遗迹"
	t.bg_color = Color(0.6, 0.5, 0.3)
	t.floor_color = Color(0.8, 0.7, 0.5)
	t.wall_color = Color(0.7, 0.6, 0.4)
	t.accent_color = Color(1.0, 0.8, 0.4)
	t.fog_color = Color(0.8, 0.7, 0.5, 0.4)
	t.particle_color = Color(0.9, 0.8, 0.6)
	t.weather = Weather.SANDSTORM
	t.hazards = [EnvironmentHazard.FALLING_ROCK, EnvironmentHazard.SPIKE, EnvironmentHazard.WIND_GUST]
	t.hazard_frequency = 0.3
	t.enemy_weights = {
		"scorpion": 30,
		"mummy": 25,
		"desert_beetle": 20,
		"sand_golem": 15,
		"desert_elite": 10
	}
	t.has_chasms = true
	t.platform_density = 0.1
	t.ambient_sound = "desert_ambient"
	t.music_track = "desert_theme"
	t.boss_id = "pharaoh"
	t.unlock_wave = 3
	t.unlock_description = "通过第3波解锁"
	t.difficulty_modifier = 1.1
	themes[ThemeId.DESERT] = t

func _register_snow() -> void:
	var t := ThemeData.new(ThemeId.SNOW)
	t.name = "冰封雪原"
	t.description = "永恒的冻土，冰晶覆盖一切，凛冬之主统治此处"
	t.bg_color = Color(0.7, 0.8, 0.9)
	t.floor_color = Color(0.85, 0.9, 0.95)
	t.wall_color = Color(0.6, 0.7, 0.8)
	t.accent_color = Color(0.5, 0.7, 1.0)
	t.fog_color = Color(0.8, 0.9, 1.0, 0.3)
	t.particle_color = Color(1.0, 1.0, 1.0)
	t.weather = Weather.SNOW
	t.hazards = [EnvironmentHazard.ICE_PATCH, EnvironmentHazard.FALLING_ROCK, EnvironmentHazard.SPIKE]
	t.hazard_frequency = 0.25
	t.enemy_weights = {
		"ice_slime": 30,
		"frost_wolf": 25,
		"snow_golem": 20,
		"ice_mage": 15,
		"frost_elite": 10
	}
	t.has_water = true
	t.has_elevation = true
	t.platform_density = 0.2
	t.ambient_sound = "snow_ambient"
	t.music_track = "snow_theme"
	t.boss_id = "frost_giant"
	t.unlock_wave = 5
	t.unlock_description = "通过第5波解锁"
	t.difficulty_modifier = 1.15
	themes[ThemeId.SNOW] = t

func _register_lava() -> void:
	var t := ThemeData.new(ThemeId.LAVA)
	t.name = "熔岩地狱"
	t.description = "炽热的地下世界，熔岩河流穿行其间"
	t.bg_color = Color(0.3, 0.1, 0.05)
	t.floor_color = Color(0.5, 0.2, 0.1)
	t.wall_color = Color(0.35, 0.15, 0.08)
	t.accent_color = Color(1.0, 0.4, 0.1)
	t.fog_color = Color(0.5, 0.2, 0.1, 0.4)
	t.particle_color = Color(1.0, 0.5, 0.2)
	t.weather = Weather.LAVA_RAIN
	t.hazards = [EnvironmentHazard.LAVA_POOL, EnvironmentHazard.FALLING_ROCK, EnvironmentHazard.SPIKE]
	t.hazard_frequency = 0.35
	t.enemy_weights = {
		"fire_imp": 30,
		"lava_golem": 25,
		"fire_bat": 20,
		"magma_worm": 15,
		"fire_elite": 10
	}
	t.has_chasms = true
	t.platform_density = 0.3
	t.ambient_sound = "lava_ambient"
	t.music_track = "lava_theme"
	t.boss_id = "inferno_lord"
	t.unlock_wave = 7
	t.unlock_description = "通过第7波解锁"
	t.difficulty_modifier = 1.2
	themes[ThemeId.LAVA] = t

func _register_mechanical() -> void:
	var t := ThemeData.new(ThemeId.MECHANICAL)
	t.name = "蒸汽机械城"
	t.description = "被遗弃的机械城市，齿轮和蒸汽管道构成的危险迷宫"
	t.bg_color = Color(0.2, 0.2, 0.25)
	t.floor_color = Color(0.4, 0.4, 0.45)
	t.wall_color = Color(0.3, 0.3, 0.35)
	t.accent_color = Color(0.8, 0.7, 0.3)
	t.fog_color = Color(0.3, 0.3, 0.35, 0.2)
	t.particle_color = Color(0.7, 0.7, 0.8)
	t.weather = Weather.NONE
	t.hazards = [EnvironmentHazard.LASER, EnvironmentHazard.SAW_BLADE, EnvironmentHazard.ELECTRIC_FIELD, EnvironmentHazard.MOVING_PLATFORM]
	t.hazard_frequency = 0.4
	t.enemy_weights = {
		"clockwork_soldier": 30,
		"steam_spider": 25,
		"gear_golem": 20,
		"laser_drone": 15,
		"mech_elite": 10
	}
	t.has_elevation = true
	t.platform_density = 0.35
	t.ambient_sound = "mechanical_ambient"
	t.music_track = "mechanical_theme"
	t.boss_id = "mech_overlord"
	t.unlock_wave = 10
	t.unlock_description = "通过第10波解锁"
	t.difficulty_modifier = 1.25
	themes[ThemeId.MECHANICAL] = t

func _register_abyss() -> void:
	var t := ThemeData.new(ThemeId.ABYSS)
	t.name = "深渊裂隙"
	t.description = "黑暗笼罩的深渊，扭曲的生物在暗处游荡"
	t.bg_color = Color(0.05, 0.02, 0.1)
	t.floor_color = Color(0.1, 0.05, 0.15)
	t.wall_color = Color(0.08, 0.03, 0.12)
	t.accent_color = Color(0.5, 0.2, 0.8)
	t.fog_color = Color(0.1, 0.05, 0.2, 0.5)
	t.particle_color = Color(0.4, 0.2, 0.7)
	t.weather = Weather.FOG
	t.hazards = [EnvironmentHazard.POISON_GAS, EnvironmentHazard.SPIKE, EnvironmentHazard.FALLING_ROCK]
	t.hazard_frequency = 0.3
	t.enemy_weights = {
		"shadow_crawler": 30,
		"void_tendril": 25,
		"dark_stalker": 20,
		"abyss_horror": 15,
		"abyss_elite": 10
	}
	t.has_chasms = true
	t.has_water = true
	t.platform_density = 0.15
	t.ambient_sound = "abyss_ambient"
	t.music_track = "abyss_theme"
	t.boss_id = "void_leviathan"
	t.unlock_wave = 13
	t.unlock_description = "通过第13波解锁"
	t.difficulty_modifier = 1.3
	themes[ThemeId.ABYSS] = t

func _register_sky_island() -> void:
	var t := ThemeData.new(ThemeId.SKY_ISLAND)
	t.name = "浮空群岛"
	t.description = "悬浮在天空中的破碎岛屿，危险的风暴随时袭来"
	t.bg_color = Color(0.4, 0.6, 0.9)
	t.floor_color = Color(0.6, 0.5, 0.4)
	t.wall_color = Color(0.5, 0.4, 0.3)
	t.accent_color = Color(0.9, 0.8, 0.5)
	t.fog_color = Color(0.5, 0.6, 0.8, 0.3)
	t.particle_color = Color(1.0, 1.0, 0.8)
	t.weather = Weather.WIND
	t.hazards = [EnvironmentHazard.WIND_GUST, EnvironmentHazard.FALLING_ROCK, EnvironmentHazard.MOVING_PLATFORM]
	t.hazard_frequency = 0.35
	t.enemy_weights = {
		"wind_elemental": 30,
		"cloud_golem": 25,
		"sky_serpent": 20,
		"storm_bird": 15,
		"sky_elite": 10
	}
	t.has_chasms = true
	t.has_elevation = true
	t.platform_density = 0.4
	t.ambient_sound = "sky_ambient"
	t.music_track = "sky_theme"
	t.boss_id = "storm_dragon"
	t.unlock_wave = 16
	t.unlock_description = "通过第16波解锁"
	t.difficulty_modifier = 1.35
	themes[ThemeId.SKY_ISLAND] = t

func _register_cemetery() -> void:
	var t := ThemeData.new(ThemeId.CEMETERY)
	t.name = "亡者墓地"
	t.description = "永恒安息之地被打破，亡灵在这里游荡不息"
	t.bg_color = Color(0.1, 0.1, 0.15)
	t.floor_color = Color(0.2, 0.2, 0.25)
	t.wall_color = Color(0.15, 0.15, 0.2)
	t.accent_color = Color(0.4, 0.6, 0.3)
	t.fog_color = Color(0.15, 0.15, 0.2, 0.5)
	t.particle_color = Color(0.5, 0.5, 0.3)
	t.weather = Weather.FOG
	t.hazards = [EnvironmentHazard.SPIKE, EnvironmentHazard.POISON_GAS, EnvironmentHazard.FALLING_ROCK]
	t.hazard_frequency = 0.25
	t.enemy_weights = {
		"skeleton": 30,
		"zombie": 25,
		"ghost": 20,
		"bone_dragon": 15,
		"undead_elite": 10
	}
	t.has_water = false
	t.platform_density = 0.15
	t.ambient_sound = "cemetery_ambient"
	t.music_track = "cemetery_theme"
	t.boss_id = "lich_king"
	t.unlock_wave = 8
	t.unlock_description = "通过第8波解锁"
	t.difficulty_modifier = 1.2
	themes[ThemeId.CEMETERY] = t

func _register_cave() -> void:
	var t := ThemeData.new(ThemeId.CAVE)
	t.name = "幽暗洞穴"
	t.description = "深邃的地下洞穴，钟乳石和暗河构成天然迷宫"
	t.bg_color = Color(0.1, 0.08, 0.12)
	t.floor_color = Color(0.25, 0.22, 0.28)
	t.wall_color = Color(0.18, 0.15, 0.22)
	t.accent_color = Color(0.4, 0.35, 0.5)
	t.fog_color = Color(0.15, 0.12, 0.2, 0.4)
	t.particle_color = Color(0.3, 0.3, 0.4)
	t.weather = Weather.NONE
	t.hazards = [EnvironmentHazard.FALLING_ROCK, EnvironmentHazard.SPIKE, EnvironmentHazard.POISON_GAS]
	t.hazard_frequency = 0.2
	t.enemy_weights = {
		"cave_bat": 30,
		"rock_golem": 25,
		"cave_spider": 20,
		"crystal_elemental": 15,
		"cave_elite": 10
	}
	t.has_water = true
	t.has_elevation = true
	t.platform_density = 0.2
	t.ambient_sound = "cave_ambient"
	t.music_track = "cave_theme"
	t.boss_id = "crystal_titan"
	t.unlock_wave = 2
	t.unlock_description = "通过第2波解锁"
	t.difficulty_modifier = 1.05
	themes[ThemeId.CAVE] = t

func _register_ruins() -> void:
	var t := ThemeData.new(ThemeId.RUINS)
	t.name = "远古废墟"
	t.description = "古代文明的遗迹，到处散落着破碎的雕像和神秘符文"
	t.bg_color = Color(0.15, 0.12, 0.1)
	t.floor_color = Color(0.35, 0.3, 0.25)
	t.wall_color = Color(0.25, 0.22, 0.18)
	t.accent_color = Color(0.6, 0.5, 0.3)
	t.fog_color = Color(0.2, 0.18, 0.15, 0.3)
	t.particle_color = Color(0.5, 0.4, 0.3)
	t.weather = Weather.WIND
	t.hazards = [EnvironmentHazard.FALLING_ROCK, EnvironmentHazard.SPIKE, EnvironmentHazard.LASER]
	t.hazard_frequency = 0.25
	t.enemy_weights = {
		"stone_guardian": 30,
		"ruins_specter": 25,
		"ancient_golem": 20,
		"rune_elemental": 15,
		"ruins_elite": 10
	}
	t.has_elevation = true
	t.platform_density = 0.2
	t.ambient_sound = "ruins_ambient"
	t.music_track = "ruins_theme"
	t.boss_id = "ancient_colossus"
	t.unlock_wave = 4
	t.unlock_description = "通过第4波解锁"
	t.difficulty_modifier = 1.1
	themes[ThemeId.RUINS] = t

func _register_void() -> void:
	var t := ThemeData.new(ThemeId.VOID)
	t.name = "虚空裂隙"
	t.description = "现实与虚无的边界，扭曲的时空带来无尽的恐惧"
	t.bg_color = Color(0.02, 0.01, 0.05)
	t.floor_color = Color(0.08, 0.04, 0.12)
	t.wall_color = Color(0.05, 0.02, 0.08)
	t.accent_color = Color(0.6, 0.3, 1.0)
	t.fog_color = Color(0.1, 0.05, 0.15, 0.6)
	t.particle_color = Color(0.5, 0.3, 0.8)
	t.weather = Weather.THUNDER
	t.hazards = [EnvironmentHazard.ELECTRIC_FIELD, EnvironmentHazard.SPIKE, EnvironmentHazard.FALLING_ROCK, EnvironmentHazard.POISON_GAS]
	t.hazard_frequency = 0.4
	t.enemy_weights = {
		"void_wraith": 30,
		"chaos_elemental": 25,
		"null_stalker": 20,
		"reality_tearer": 15,
		"void_elite": 10
	}
	t.has_chasms = true
	t.has_water = false
	t.platform_density = 0.25
	t.ambient_sound = "void_ambient"
	t.music_track = "void_theme"
	t.boss_id = "void_emperor"
	t.unlock_wave = 20
	t.unlock_description = "通过第20波解锁"
	t.difficulty_modifier = 1.5
	themes[ThemeId.VOID] = t
