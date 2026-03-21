## theme_generator.gd - 主题特征生成器
## 根据不同主题生成具有特色的地形特征
## 支持5种主题：森林、荒漠、洞穴、遗迹、虚空

class_name ThemeGenerator
extends RefCounted

# ==================== 枚举定义 ====================
## 关卡主题类型
enum ThemeType {
	FOREST,    ## 森林：密集树木+草地，开阔空间
	DESERT,    ## 荒漠：沙丘+岩石，稀疏障碍
	CAVE,      ## 洞穴：狭窄通道+开阔洞穴
	RUINS,     ## 遗迹：规则房间+柱子
	VOID       ## 虚空：浮动平台+危险区域
}

## 地形单元格类型
enum TerrainType {
	GROUND,        ## 普通地面
	WALL,          ## 墙壁
	WATER,         ## 水域
	LAVA,          ## 岩浆
	VOID_PIT,      ## 虚空深渊
	TREES,         ## 树木/植被
	ROCK,          ## 岩石
	SAND,          ## 沙地
	PILLAR,        ## 柱子
	PLATFORM,      ## 浮动平台
	CRYSTAL,       ## 水晶
	ALTAR,         ## 祭坛
	DOORWAY        ## 门道
}

# ==================== 主题配置 ====================
## 各主题的特征配置
const THEME_CONFIGS: Dictionary = {
	ThemeType.FOREST: {
		"ground_ratio": 0.6,           ## 地面占比
		"tree_density": 0.15,          ## 树木密度
		"water_probability": 0.05,     ## 水域概率
		"clearing_size_range": [5, 15], ## 开阔空地大小范围
		"path_width_range": [2, 4],    ## 路径宽度范围
		"ambient_color": Color(0.2, 0.5, 0.2, 1.0),
		"feature_types": [TerrainType.TREES, TerrainType.WATER, TerrainType.GROUND]
	},
	ThemeType.DESERT: {
		"ground_ratio": 0.7,
		"rock_density": 0.08,
		"dune_probability": 0.2,
		"oasis_probability": 0.03,
		"clearing_size_range": [8, 20],
		"path_width_range": [3, 5],
		"ambient_color": Color(0.9, 0.8, 0.5, 1.0),
		"feature_types": [TerrainType.SAND, TerrainType.ROCK, TerrainType.WATER]
	},
	ThemeType.CAVE: {
		"ground_ratio": 0.4,
		"passage_width_range": [2, 4],
		"cave_size_range": [10, 25],
		"crystal_probability": 0.05,
		"water_probability": 0.1,
		"lava_probability": 0.05,
		"ambient_color": Color(0.15, 0.15, 0.2, 1.0),
		"feature_types": [TerrainType.WALL, TerrainType.CRYSTAL, TerrainType.WATER, TerrainType.LAVA]
	},
	ThemeType.RUINS: {
		"ground_ratio": 0.65,
		"room_count_range": [5, 12],
		"room_size_range": [8, 16],
		"pillar_density": 0.1,
		"corridor_width": 3,
		"door_probability": 0.3,
		"ambient_color": Color(0.4, 0.35, 0.3, 1.0),
		"feature_types": [TerrainType.PILLAR, TerrainType.DOORWAY, TerrainType.ALTAR]
	},
	ThemeType.VOID: {
		"ground_ratio": 0.25,
		"platform_size_range": [4, 12],
		"platform_density": 0.3,
		"void_pit_probability": 0.5,
		"hazard_probability": 0.15,
		"bridge_probability": 0.2,
		"ambient_color": Color(0.1, 0.05, 0.15, 1.0),
		"feature_types": [TerrainType.PLATFORM, TerrainType.VOID_PIT, TerrainType.LAVA]
	}
}

# ==================== 成员变量 ====================
## 当前主题
var _current_theme: ThemeType = ThemeType.FOREST
## 网格宽度
var _width: int = 128
## 网格高度
var _height: int = 128
## 地形网格
var _terrain_grid: Array = []
## 特征位置记录
var _feature_positions: Dictionary = {}
## 随机数生成器
var _rng: RandomNumberGenerator
## Perlin噪声生成器
var _noise: TerrainNoise

# ==================== 初始化函数 ====================

## 初始化主题生成器
## @param width: 网格宽度
## @param height: 网格高度
## @param seed: 随机种子
func _init(width: int = 128, height: int = 128, seed: int = 0) -> void:
	_width = width
	_height = height
	_rng = RandomNumberGenerator.new()
	_rng.seed = seed
	_noise = TerrainNoise.new(seed, 50.0, 4, 0.5, 2.0)
	_initialize_grid()


## 初始化网格
func _initialize_grid() -> void:
	_terrain_grid = []
	_terrain_grid.resize(_height)
	for y in range(_height):
		_terrain_grid[y] = []
		_terrain_grid[y].resize(_width)
		for x in range(_width):
			_terrain_grid[y][x] = TerrainType.GROUND
	
	_feature_positions.clear()

# ==================== 主题生成函数 ====================

## 生成指定主题的地形
## @param theme: 主题类型
## @param base_grid: 基础地形网格（可选）
## @return: 地形网格
func generate_theme(theme: ThemeType, base_grid: Array = []) -> Array:
	_current_theme = theme
	_initialize_grid()
	
	# 如果提供了基础网格，先复制
	if base_grid.size() > 0:
		_copy_base_grid(base_grid)
	
	# 根据主题应用特征生成器
	match theme:
		ThemeType.FOREST:
			_generate_forest_features()
		ThemeType.DESERT:
			_generate_desert_features()
		ThemeType.CAVE:
			_generate_cave_features()
		ThemeType.RUINS:
			_generate_ruins_features()
		ThemeType.VOID:
			_generate_void_features()
	
	return _terrain_grid

# ==================== 森林主题生成 ====================

## 生成森林特征
func _generate_forest_features() -> void:
	var config: Dictionary = THEME_CONFIGS[ThemeType.FOREST]
	
	# 生成基础草地
	_generate_ground_with_noise(0.3)
	
	# 生成树木群
	var tree_density: float = config.tree_density
	var cluster_count: int = int(_width * _height * tree_density / 100)
	
	for i in range(cluster_count):
		var center_x: int = _rng.randi_range(10, _width - 10)
		var center_y: int = _rng.randi_range(10, _height - 10)
		var cluster_size: int = _rng.randi_range(3, 8)
		_generate_tree_cluster(center_x, center_y, cluster_size)
	
	# 生成开阔空地
	var clearing_count: int = _rng.randi_range(3, 6)
	for i in range(clearing_count):
		var size_range: Array = config.clearing_size_range
		var size: int = _rng.randi_range(size_range[0], size_range[1])
		var cx: int = _rng.randi_range(size, _width - size)
		var cy: int = _rng.randi_range(size, _height - size)
		_generate_clearing(cx, cy, size)
	
	# 生成水域
	if _rng.randf() < config.water_probability * 2:
		_generate_water_feature()


## 生成树木群
func _generate_tree_cluster(center_x: int, center_y: int, size: int) -> void:
	for i in range(size):
		var angle: float = _rng.randf() * TAU
		var radius: float = _rng.randf() * size
		var x: int = int(center_x + cos(angle) * radius)
		var y: int = int(center_y + sin(angle) * radius)
		
		if _is_valid_position(x, y):
			_terrain_grid[y][x] = TerrainType.TREES
			_record_feature("trees", Vector2i(x, y))


## 生成开阔空地
func _generate_clearing(center_x: int, center_y: int, radius: int) -> void:
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var x: int = center_x + dx
			var y: int = center_y + dy
			
			if _is_valid_position(x, y):
				var dist: float = sqrt(dx * dx + dy * dy)
				if dist <= radius:
					_terrain_grid[y][x] = TerrainType.GROUND


## 生成水域特征
func _generate_water_feature() -> void:
	var cx: int = _rng.randi_range(20, _width - 20)
	var cy: int = _rng.randi_range(20, _height - 20)
	var size: int = _rng.randi_range(5, 15)
	
	for dy in range(-size, size + 1):
		for dx in range(-size, size + 1):
			var x: int = cx + dx
			var y: int = cy + dy
			if _is_valid_position(x, y):
				var dist: float = sqrt(dx * dx + dy * dy)
				if dist <= size + _rng.randf_range(-1, 1):
					_terrain_grid[y][x] = TerrainType.WATER
					_record_feature("water", Vector2i(x, y))

# ==================== 荒漠主题生成 ====================

## 生成荒漠特征
func _generate_desert_features() -> void:
	var config: Dictionary = THEME_CONFIGS[ThemeType.DESERT]
	
	# 生成基础沙地
	_generate_sand_dunes()
	
	# 散布岩石
	var rock_count: int = int(_width * _height * config.rock_density / 100)
	for i in range(rock_count):
		var x: int = _rng.randi_range(5, _width - 5)
		var y: int = _rng.randi_range(5, _height - 5)
		_generate_rock_cluster(x, y, _rng.randi_range(1, 3))
	
	# 生成绿洲
	if _rng.randf() < config.oasis_probability * 3:
		_generate_oasis()
	
	# 生成开阔区域
	var clearing_count: int = _rng.randi_range(2, 4)
	for i in range(clearing_count):
		var size_range: Array = config.clearing_size_range
		_generate_clearing(
			_rng.randi_range(size_range[0], _width - size_range[0]),
			_rng.randi_range(size_range[0], _height - size_range[0]),
			_rng.randi_range(size_range[0], size_range[1])
		)


## 生成沙丘
func _generate_sand_dunes() -> void:
	var noise_grid: Array = _noise.generate_terrain_grid(_width, _height)
	
	for y in range(_height):
		for x in range(_width):
			var noise_val: float = noise_grid[y][x]
			if noise_val > 0.55:
				_terrain_grid[y][x] = TerrainType.ROCK
			else:
				_terrain_grid[y][x] = TerrainType.SAND


## 生成岩石群
func _generate_rock_cluster(center_x: int, center_y: int, size: int) -> void:
	for i in range(size):
		var offset_x: int = _rng.randi_range(-2, 2)
		var offset_y: int = _rng.randi_range(-2, 2)
		var x: int = center_x + offset_x
		var y: int = center_y + offset_y
		
		if _is_valid_position(x, y):
			_terrain_grid[y][x] = TerrainType.ROCK
			_record_feature("rocks", Vector2i(x, y))


## 生成绿洲
func _generate_oasis() -> void:
	var cx: int = _rng.randi_range(30, _width - 30)
	var cy: int = _rng.randi_range(30, _height - 30)
	var size: int = _rng.randi_range(6, 12)
	
	# 水域
	for dy in range(-size / 2, size / 2 + 1):
		for dx in range(-size / 2, size / 2 + 1):
			var x: int = cx + dx
			var y: int = cy + dy
			if _is_valid_position(x, y):
				var dist: float = sqrt(dx * dx + dy * dy)
				if dist <= size / 2:
					_terrain_grid[y][x] = TerrainType.WATER
	
	# 周围树木
	for i in range(size * 2):
		var angle: float = _rng.randf() * TAU
		var radius: float = size / 2.0 + _rng.randf_range(1, 4)
		var x: int = int(cx + cos(angle) * radius)
		var y: int = int(cy + sin(angle) * radius)
		if _is_valid_position(x, y):
			_terrain_grid[y][x] = TerrainType.TREES
	
	_record_feature("oasis", Vector2i(cx, cy))

# ==================== 洞穴主题生成 ====================

## 生成洞穴特征
func _generate_cave_features() -> void:
	var config: Dictionary = THEME_CONFIGS[ThemeType.CAVE]
	
	# 使用细胞自动机生成基础洞穴结构
	var ca: CellularAutomata = CellularAutomata.new(_width, _height, _rng.seed)
	var cave_grid: Array = ca.generate_with_preset(CellularAutomata.RulePreset.CAVE_SMOOTH)
	
	# 转换为地形网格
	for y in range(_height):
		for x in range(_width):
			if cave_grid[y][x] == CellularAutomata.CellState.WALL:
				_terrain_grid[y][x] = TerrainType.WALL
			else:
				_terrain_grid[y][x] = TerrainType.GROUND
	
	# 添加水晶
	_add_crystals(config.crystal_probability)
	
	# 添加地下水域
	if _rng.randf() < config.water_probability * 2:
		_add_underground_water()
	
	# 添加岩浆
	if _rng.randf() < config.lava_probability * 2:
		_add_lava_pools()


## 添加水晶
func _add_crystals(probability: float) -> void:
	for y in range(5, _height - 5):
		for x in range(5, _width - 5):
			if _terrain_grid[y][x] == TerrainType.WALL:
				# 检查是否靠近空地
				if _has_adjacent_ground(x, y) and _rng.randf() < probability:
					_terrain_grid[y][x] = TerrainType.CRYSTAL
					_record_feature("crystals", Vector2i(x, y))


## 检查是否有相邻地面
func _has_adjacent_ground(x: int, y: int) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx: int = x + dx
			var ny: int = y + dy
			if _is_valid_position(nx, ny):
				if _terrain_grid[ny][nx] == TerrainType.GROUND:
					return true
	return false


## 添加地下水域
func _add_underground_water() -> void:
	var pool_count: int = _rng.randi_range(2, 5)
	for i in range(pool_count):
		var pos: Vector2i = _find_empty_ground()
		if pos.x >= 0:
			_fill_area(pos.x, pos.y, _rng.randi_range(3, 6), TerrainType.WATER)


## 添加岩浆池
func _add_lava_pools() -> void:
	var pool_count: int = _rng.randi_range(1, 3)
	for i in range(pool_count):
		var pos: Vector2i = _find_empty_ground()
		if pos.x >= 0:
			_fill_area(pos.x, pos.y, _rng.randi_range(2, 5), TerrainType.LAVA)


## 填充区域
func _fill_area(center_x: int, center_y: int, radius: int, terrain_type: TerrainType) -> void:
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var x: int = center_x + dx
			var y: int = center_y + dy
			if _is_valid_position(x, y):
				var dist: float = sqrt(dx * dx + dy * dy)
				if dist <= radius and _terrain_grid[y][x] == TerrainType.GROUND:
					_terrain_grid[y][x] = terrain_type
					_record_feature("lava" if terrain_type == TerrainType.LAVA else "water", Vector2i(x, y))

# ==================== 遗迹主题生成 ====================

## 生成遗迹特征
func _generate_ruins_features() -> void:
	var config: Dictionary = THEME_CONFIGS[ThemeType.RUINS]
	
	# 初始化为墙壁
	for y in range(_height):
		for x in range(_width):
			_terrain_grid[y][x] = TerrainType.WALL
	
	# 生成房间
	var room_count: int = _rng.randi_range(config.room_count_range[0], config.room_count_range[1])
	var rooms: Array = []
	
	for i in range(room_count):
		var room: Dictionary = _generate_room()
		if not room.is_empty():
			rooms.append(room)
	
	# 连接房间
	_connect_rooms(rooms, config.corridor_width)
	
	# 添加柱子
	_add_pillars(config.pillar_density)
	
	# 添加祭坛
	if rooms.size() > 0:
		var main_room: Dictionary = rooms[_rng.randi_range(0, rooms.size() - 1)]
		_add_altar_to_room(main_room)


## 生成单个房间
func _generate_room() -> Dictionary:
	var config: Dictionary = THEME_CONFIGS[ThemeType.RUINS]
	var size_range: Array = config.room_size_range
	
	var room_width: int = _rng.randi_range(size_range[0], size_range[1])
	var room_height: int = _rng.randi_range(size_range[0], size_range[1])
	var room_x: int = _rng.randi_range(5, _width - room_width - 5)
	var room_y: int = _rng.randi_range(5, _height - room_height - 5)
	
	# 检查是否与其他房间重叠
	if _check_room_overlap(room_x, room_y, room_width, room_height):
		return {}
	
	# 挖掘房间
	for y in range(room_y, room_y + room_height):
		for x in range(room_x, room_x + room_width):
			if _is_valid_position(x, y):
				_terrain_grid[y][x] = TerrainType.GROUND
	
	return {
		"x": room_x,
		"y": room_y,
		"width": room_width,
		"height": room_height,
		"center": Vector2i(room_x + room_width / 2, room_y + room_height / 2)
	}


## 检查房间是否重叠
func _check_room_overlap(x: int, y: int, width: int, height: int) -> bool:
	var margin: int = 3
	for dy in range(y - margin, y + height + margin):
		for dx in range(x - margin, x + width + margin):
			if _is_valid_position(dx, dy):
				if _terrain_grid[dy][dx] == TerrainType.GROUND:
					return true
	return false


## 连接房间
func _connect_rooms(rooms: Array, corridor_width: int) -> void:
	if rooms.size() < 2:
		return
	
	# 按位置排序房间
	rooms.sort_custom(func(a, b): return a.center.x < b.center.x)
	
	# 连接相邻房间
	for i in range(rooms.size() - 1):
		var room1: Dictionary = rooms[i]
		var room2: Dictionary = rooms[i + 1]
		_carve_corridor_between(room1.center, room2.center, corridor_width)


## 在两点间挖掘走廊
func _carve_corridor_between(start: Vector2i, end: Vector2i, width: int) -> void:
	var x: int = start.x
	var y: int = start.y
	
	# 先水平后垂直
	while x != end.x:
		_carve_corridor_segment(x, y, width, true)
		if x < end.x:
			x += 1
		else:
			x -= 1
	
	while y != end.y:
		_carve_corridor_segment(x, y, width, false)
		if y < end.y:
			y += 1
		else:
			y -= 1


## 挖掘走廊段
func _carve_corridor_segment(x: int, y: int, width: int, horizontal: bool) -> void:
	var half_width: int = width / 2
	
	if horizontal:
		for dy in range(-half_width, half_width + 1):
			var ny: int = y + dy
			if _is_valid_position(x, ny):
				_terrain_grid[ny][x] = TerrainType.GROUND
	else:
		for dx in range(-half_width, half_width + 1):
			var nx: int = x + dx
			if _is_valid_position(nx, y):
				_terrain_grid[y][nx] = TerrainType.GROUND


## 添加柱子
func _add_pillars(density: float) -> void:
	var pillar_count: int = int(_width * _height * density / 200)
	
	for i in range(pillar_count):
		var pos: Vector2i = _find_empty_ground()
		if pos.x >= 0:
			_terrain_grid[pos.y][pos.x] = TerrainType.PILLAR
			_record_feature("pillars", pos)


## 在房间中添加祭坛
func _add_altar_to_room(room: Dictionary) -> void:
	var center: Vector2i = room.center
	_terrain_grid[center.y][center.x] = TerrainType.ALTAR
	_record_feature("altars", center)

# ==================== 虚空主题生成 ====================

## 生成虚空特征
func _generate_void_features() -> void:
	var config: Dictionary = THEME_CONFIGS[ThemeType.VOID]
	
	# 初始化为虚空深渊
	for y in range(_height):
		for x in range(_width):
			_terrain_grid[y][x] = TerrainType.VOID_PIT
	
	# 生成浮动平台
	_generate_floating_platforms(config)
	
	# 添加危险区域
	_add_void_hazards(config.hazard_probability)
	
	# 添加桥梁
	_add_bridges_between_platforms(config.bridge_probability)


## 生成浮动平台
func _generate_floating_platforms(config: Dictionary) -> void:
	var platform_count: int = int(_width * _height * config.platform_density / 500)
	var platforms: Array = []
	
	for i in range(platform_count):
		var size_range: Array = config.platform_size_range
		var size: int = _rng.randi_range(size_range[0], size_range[1])
		var cx: int = _rng.randi_range(size, _width - size)
		var cy: int = _rng.randi_range(size, _height - size)
		
		var platform: Array = _generate_platform(cx, cy, size)
		if platform.size() > 0:
			platforms.append({"center": Vector2i(cx, cy), "positions": platform})
	
	_feature_positions["platforms"] = platforms


## 生成单个平台
func _generate_platform(center_x: int, center_y: int, size: int) -> Array:
	var positions: Array = []
	
	for dy in range(-size / 2, size / 2 + 1):
		for dx in range(-size / 2, size / 2 + 1):
			var x: int = center_x + dx
			var y: int = center_y + dy
			if _is_valid_position(x, y):
				var dist: float = sqrt(dx * dx + dy * dy)
				# 添加一些不规则性
				if dist <= size / 2.0 + _rng.randf_range(-1, 1):
					_terrain_grid[y][x] = TerrainType.PLATFORM
					positions.append(Vector2i(x, y))
	
	return positions


## 添加虚空危险
func _add_void_hazards(probability: float) -> void:
	for y in range(_height):
		for x in range(_width):
			if _terrain_grid[y][x] == TerrainType.PLATFORM:
				if _rng.randf() < probability:
					# 在平台边缘添加危险
					if _has_adjacent_void(x, y):
						_terrain_grid[y][x] = TerrainType.LAVA
						_record_feature("hazards", Vector2i(x, y))


## 检查是否有相邻虚空
func _has_adjacent_void(x: int, y: int) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx: int = x + dx
			var ny: int = y + dy
			if _is_valid_position(nx, ny):
				if _terrain_grid[ny][nx] == TerrainType.VOID_PIT:
					return true
	return false


## 在平台间添加桥梁
func _add_bridges_between_platforms(probability: float) -> void:
	var platforms: Array = _feature_positions.get("platforms", [])
	
	if platforms.size() < 2:
		return
	
	# 找到最近的对并可能添加桥梁
	for i in range(platforms.size()):
		for j in range(i + 1, platforms.size()):
			var dist: float = platforms[i].center.distance_to(platforms[j].center)
			if dist < 25 and _rng.randf() < probability:
				_create_bridge(platforms[i].center, platforms[j].center)


## 创建桥梁
func _create_bridge(start: Vector2i, end: Vector2i) -> void:
	var x: int = start.x
	var y: int = start.y
	var width: int = 2
	
	while x != end.x or y != end.y:
		# 挖掘桥梁
		for dx in range(-width / 2, width / 2 + 1):
			for dy in range(-width / 2, width / 2 + 1):
				var nx: int = x + dx
				var ny: int = y + dy
				if _is_valid_position(nx, ny):
					_terrain_grid[ny][nx] = TerrainType.PLATFORM
		
		# 移向目标
		if x < end.x:
			x += 1
		elif x > end.x:
			x -= 1
		elif y < end.y:
			y += 1
		elif y > end.y:
			y -= 1
	
	_record_feature("bridges", start)

# ==================== 辅助函数 ====================

## 使用噪声生成地面
func _generate_ground_with_noise(threshold: float) -> void:
	var noise_grid: Array = _noise.generate_terrain_grid(_width, _height)
	
	for y in range(_height):
		for x in range(_width):
			if noise_grid[y][x] > threshold:
				_terrain_grid[y][x] = TerrainType.WALL
			else:
				_terrain_grid[y][x] = TerrainType.GROUND


## 复制基础网格
func _copy_base_grid(base_grid: Array) -> void:
	var base_height: int = mini(base_grid.size(), _height)
	for y in range(base_height):
		var base_width: int = mini(base_grid[y].size(), _width)
		for x in range(base_width):
			_terrain_grid[y][x] = base_grid[y][x]


## 检查位置是否有效
func _is_valid_position(x: int, y: int) -> bool:
	return x >= 0 and x < _width and y >= 0 and y < _height


## 记录特征位置
func _record_feature(feature_type: String, position: Vector2i) -> void:
	if not _feature_positions.has(feature_type):
		_feature_positions[feature_type] = []
	_feature_positions[feature_type].append(position)


## 找到空白地面
func _find_empty_ground() -> Vector2i:
	var attempts: int = 500
	while attempts > 0:
		var x: int = _rng.randi_range(5, _width - 5)
		var y: int = _rng.randi_range(5, _height - 5)
		if _terrain_grid[y][x] == TerrainType.GROUND:
			return Vector2i(x, y)
		attempts -= 1
	return Vector2i(-1, -1)

# ==================== 获取器函数 ====================

## 获取地形网格
func get_terrain_grid() -> Array:
	return _terrain_grid


## 获取指定位置的地形类型
func get_terrain_at(x: int, y: int) -> int:
	if _is_valid_position(x, y):
		return _terrain_grid[y][x]
	return TerrainType.WALL


## 获取所有特征位置
func get_feature_positions() -> Dictionary:
	return _feature_positions


## 获取指定类型的特征位置
func get_features_by_type(feature_type: String) -> Array:
	return _feature_positions.get(feature_type, [])


## 获取当前主题配置
func get_current_theme_config() -> Dictionary:
	return THEME_CONFIGS.get(_current_theme, {})


## 获取主题环境颜色
func get_theme_ambient_color(theme: ThemeType) -> Color:
	var config: Dictionary = THEME_CONFIGS.get(theme, {})
	return config.get("ambient_color", Color.WHITE)


## 设置随机种子
func set_seed(new_seed: int) -> void:
	_rng.seed = new_seed
	_noise.set_seed(new_seed)
