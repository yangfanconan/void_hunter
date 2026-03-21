## cellular_automata.gd - 细胞自动机洞穴生成器
## 使用类Conway生命游戏规则生成洞穴和通道
## 支持多种预设规则和自定义参数

class_name CellularAutomata
extends RefCounted

# ==================== 枚举定义 ====================
## 单元格状态
enum CellState {
	EMPTY = 0,      ## 空白/可行走
	WALL = 1,       ## 墙壁/障碍
	WATER = 2,      ## 水域
	LAVA = 3        ## 岩浆
}

## 预设规则类型
enum RulePreset {
	CAVE_BASIC,     ## 基础洞穴生成
	CAVE_SMOOTH,    ## 平滑洞穴
	MAZE,           ## 迷宫生成
	ISLANDS,        ## 岛屿分布
	CUSTOM          ## 自定义规则
}

# ==================== 成员变量 ====================
## 网格宽度
var _width: int = 128
## 网格高度
var _height: int = 128
## 初始填充概率（墙壁）
var _fill_probability: float = 0.45
## 生存规则：邻居数量范围
var _survival_range: Array[int] = [4, 5, 6, 7, 8]
## 出生规则：邻居数量范围
var _birth_range: Array[int] = [5, 6, 7, 8]
## 迭代次数
var _iterations: int = 5
## 当前网格
var _grid: Array = []
## 随机数生成器
var _rng: RandomNumberGenerator

# ==================== 初始化函数 ====================

## 初始化细胞自动机
## @param width: 网格宽度
## @param height: 网格高度
## @param seed: 随机种子
func _init(width: int = 128, height: int = 128, seed: int = 0) -> void:
	_width = width
	_height = height
	_rng = RandomNumberGenerator.new()
	_rng.seed = seed
	_initialize_grid()


## 初始化空网格
func _initialize_grid() -> void:
	_grid = []
	_grid.resize(_height)
	for y in range(_height):
		_grid[y] = []
		_grid[y].resize(_width)
		for x in range(_width):
			_grid[y][x] = CellState.EMPTY

# ==================== 生成函数 ====================

## 使用预设规则生成洞穴
## @param preset: 预设规则类型
## @param custom_params: 自定义参数（可选）
## @return: 生成的网格
func generate_with_preset(preset: RulePreset, custom_params: Dictionary = {}) -> Array:
	_apply_preset(preset, custom_params)
	return generate()


## 生成洞穴网格
## @return: 生成的网格（2D数组）
func generate() -> Array:
	# 步骤1：随机初始化
	_random_fill()
	
	# 步骤2：应用细胞自动机规则迭代
	for i in range(_iterations):
		_simulate_step()
	
	# 步骤3：后处理（连接孤立区域、清理小洞穴）
	_post_process()
	
	return _grid


## 生成通道迷宫
## @param corridor_width: 通道宽度
## @param branch_probability: 分支概率
## @return: 生成的网格
func generate_maze(corridor_width: int = 2, branch_probability: float = 0.3) -> Array:
	# 初始化全部为墙
	_fill_all(CellState.WALL)
	
	# 使用递归分割法生成迷宫
	_carve_maze(1, 1, corridor_width, branch_probability)
	
	return _grid


## 基于噪声生成混合地形
## @param noise_grid: 噪声网格
## @param threshold: 墙壁阈值
## @return: 生成的网格
func generate_from_noise(noise_grid: Array, threshold: float = 0.5) -> Array:
	_height = noise_grid.size()
	if _height == 0:
		return []
	_width = noise_grid[0].size()
	_initialize_grid()
	
	# 根据噪声值设置单元格
	for y in range(_height):
		for x in range(_width):
			if noise_grid[y][x] > threshold:
				_grid[y][x] = CellState.WALL
			else:
				_grid[y][x] = CellState.EMPTY
	
	# 平滑边缘
	for i in range(3):
		_simulate_step()
	
	return _grid

# ==================== 核心算法 ====================

## 随机填充网格
func _random_fill() -> void:
	for y in range(_height):
		for x in range(_width):
			# 边界始终是墙
			if x == 0 or x == _width - 1 or y == 0 or y == _height - 1:
				_grid[y][x] = CellState.WALL
			else:
				# 根据概率填充
				if _rng.randf() < _fill_probability:
					_grid[y][x] = CellState.WALL
				else:
					_grid[y][x] = CellState.EMPTY


## 模拟一步细胞自动机
func _simulate_step() -> void:
	var new_grid: Array = []
	new_grid.resize(_height)
	
	for y in range(_height):
		new_grid[y] = []
		new_grid[y].resize(_width)
		for x in range(_width):
			# 边界始终是墙
			if x == 0 or x == _width - 1 or y == 0 or y == _height - 1:
				new_grid[y][x] = CellState.WALL
			else:
				# 计算墙壁邻居数量
				var wall_count: int = _count_wall_neighbors(x, y)
				
				# 应用规则
				if _grid[y][x] == CellState.WALL:
					# 墙壁的生存规则
					if wall_count in _survival_range:
						new_grid[y][x] = CellState.WALL
					else:
						new_grid[y][x] = CellState.EMPTY
				else:
					# 空白的出生规则
					if wall_count in _birth_range:
						new_grid[y][x] = CellState.WALL
					else:
						new_grid[y][x] = CellState.EMPTY
	
	_grid = new_grid


## 计算周围的墙壁邻居数量（Moore邻域，8方向）
func _count_wall_neighbors(x: int, y: int) -> int:
	var count: int = 0
	
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			
			var nx: int = x + dx
			var ny: int = y + dy
			
			# 边界外视为墙
			if nx < 0 or nx >= _width or ny < 0 or ny >= _height:
				count += 1
			elif _grid[ny][nx] == CellState.WALL:
				count += 1
	
	return count


## 后处理：连接区域并清理
func _post_process() -> void:
	# 连接孤立区域
	_connect_isolated_regions()
	
	# 移除小洞穴
	_remove_small_caves(20)
	
	# 平滑边缘
	_smooth_edges()

# ==================== 区域处理 ====================

## 使用洪水填充算法识别连通区域
## @return: 区域列表，每个区域包含坐标数组
func find_connected_regions() -> Array:
	var visited: Array = []
	visited.resize(_height)
	for y in range(_height):
		visited[y] = []
		visited[y].resize(_width)
		for x in range(_width):
			visited[y][x] = false
	
	var regions: Array = []
	
	for y in range(_height):
		for x in range(_width):
			if not visited[y][x] and _grid[y][x] == CellState.EMPTY:
				var region: Array = _flood_fill(x, y, visited)
				regions.append(region)
	
	return regions


## 洪水填充算法
func _flood_fill(start_x: int, start_y: int, visited: Array) -> Array:
	var region: Array = []
	var stack: Array = [[start_x, start_y]]
	
	while stack.size() > 0:
		var pos: Array = stack.pop_back()
		var x: int = pos[0]
		var y: int = pos[1]
		
		if x < 0 or x >= _width or y < 0 or y >= _height:
			continue
		if visited[y][x]:
			continue
		if _grid[y][x] != CellState.EMPTY:
			continue
		
		visited[y][x] = true
		region.append(Vector2i(x, y))
		
		# 4方向扩展
		stack.append([x + 1, y])
		stack.append([x - 1, y])
		stack.append([x, y + 1])
		stack.append([x, y - 1])
	
	return region


## 连接孤立区域
func _connect_isolated_regions() -> void:
	var regions: Array = find_connected_regions()
	
	if regions.size() <= 1:
		return
	
	# 按大小排序，保留最大区域
	regions.sort_custom(func(a, b): return a.size() > b.size())
	
	# 连接其他区域到最大区域
	var main_region: Array = regions[0]
	
	for i in range(1, regions.size()):
		var region: Array = regions[i]
		if region.size() < 10:  # 忽略太小的区域
			continue
		
		# 找到两个区域最近的点
		var connection: Array = _find_closest_points(main_region, region)
		if connection.size() == 2:
			# 挖通通道
			_carve_corridor(connection[0], connection[1])
			# 合并区域
			main_region.append_array(region)


## 找到两个区域之间最近的点对
func _find_closest_points(region1: Array, region2: Array) -> Array:
	var min_dist: float = INF
	var closest: Array = []
	
	# 使用采样减少计算量
	var sample_size: int = mini(50, region1.size())
	var sample1: Array = region1.duplicate()
	sample1.resize(sample_size)
	
	sample_size = mini(50, region2.size())
	var sample2: Array = region2.duplicate()
	sample2.resize(sample_size)
	
	for p1 in sample1:
		for p2 in sample2:
			var dist: float = p1.distance_squared_to(p2)
			if dist < min_dist:
				min_dist = dist
				closest = [p1, p2]
	
	return closest


## 挖通两点之间的通道
func _carve_corridor(start: Vector2i, end: Vector2i) -> void:
	var x: int = start.x
	var y: int = start.y
	
	while x != end.x or y != end.y:
		# 设置通道
		_grid[y][x] = CellState.EMPTY
		
		# 宽通道
		if x > 0:
			_grid[y][x - 1] = CellState.EMPTY
		if x < _width - 1:
			_grid[y][x + 1] = CellState.EMPTY
		
		# 移动到下一个位置
		if x < end.x:
			x += 1
		elif x > end.x:
			x -= 1
		elif y < end.y:
			y += 1
		elif y > end.y:
			y -= 1
	
	_grid[end.y][end.x] = CellState.EMPTY


## 移除小于指定大小的洞穴
func _remove_small_caves(min_size: int) -> void:
	var regions: Array = find_connected_regions()
	
	for region in regions:
		if region.size() < min_size:
			for pos in region:
				_grid[pos.y][pos.x] = CellState.WALL


## 平滑边缘
func _smooth_edges() -> void:
	for i in range(2):
		var new_grid: Array = _grid.duplicate(true)
		for y in range(1, _height - 1):
			for x in range(1, _width - 1):
				var walls: int = _count_wall_neighbors(x, y)
				if walls > 4:
					new_grid[y][x] = CellState.WALL
				elif walls < 4:
					new_grid[y][x] = CellState.EMPTY
		_grid = new_grid

# ==================== 迷宫生成 ====================

## 填充整个网格为指定状态
func _fill_all(state: CellState) -> void:
	for y in range(_height):
		for x in range(_width):
			_grid[y][x] = state


## 递归挖掘迷宫
func _carve_maze(x: int, y: int, corridor_width: int, branch_prob: float) -> void:
	# 挖掘当前位置
	for dy in range(corridor_width):
		for dx in range(corridor_width):
			if x + dx < _width and y + dy < _height:
				_grid[y + dy][x + dx] = CellState.EMPTY
	
	# 随机方向
	var directions: Array = [
		Vector2i(0, -corridor_width - 1),  # 上
		Vector2i(0, corridor_width + 1),   # 下
		Vector2i(-corridor_width - 1, 0),  # 左
		Vector2i(corridor_width + 1, 0)    # 右
	]
	
	# 随机打乱方向
	directions.shuffle()
	
	for dir in directions:
		var nx: int = x + dir.x
		var ny: int = y + dir.y
		
		# 检查是否在边界内且未访问
		if nx > 0 and nx < _width - corridor_width and \
		   ny > 0 and ny < _height - corridor_width:
			var all_walls: bool = true
			for dy in range(corridor_width):
				for dx in range(corridor_width):
					if _grid[ny + dy][nx + dx] != CellState.WALL:
						all_walls = false
						break
				if not all_walls:
					break
			
			if all_walls:
				# 挖通连接
				var mid_x: int = x + dir.x / 2
				var mid_y: int = y + dir.y / 2
				for dy in range(corridor_width):
					for dx in range(corridor_width):
						if mid_x + dx >= 0 and mid_x + dx < _width and \
						   mid_y + dy >= 0 and mid_y + dy < _height:
							_grid[mid_y + dy][mid_x + dx] = CellState.EMPTY
				
				# 递归挖掘
				_carve_maze(nx, ny, corridor_width, branch_prob)
				
				# 根据概率创建分支
				if _rng.randf() < branch_prob:
					continue

# ==================== 规则预设 ====================

## 应用预设规则
func _apply_preset(preset: RulePreset, custom_params: Dictionary = {}) -> void:
	match preset:
		RulePreset.CAVE_BASIC:
			_fill_probability = 0.5
			_survival_range = [4, 5, 6, 7, 8]
			_birth_range = [5, 6, 7, 8]
			_iterations = 5
		
		RulePreset.CAVE_SMOOTH:
			_fill_probability = 0.45
			_survival_range = [5, 6, 7, 8]
			_birth_range = [5, 6, 7, 8]
			_iterations = 8
		
		RulePreset.MAZE:
			_fill_probability = 0.7
			_survival_range = [0, 1, 2, 3, 4, 5]
			_birth_range = [3]
			_iterations = 10
		
		RulePreset.ISLANDS:
			_fill_probability = 0.35
			_survival_range = [5, 6, 7, 8]
			_birth_range = [6, 7, 8]
			_iterations = 4
		
		RulePreset.CUSTOM:
			if custom_params.has("fill_probability"):
				_fill_probability = custom_params.fill_probability
			if custom_params.has("survival_range"):
				_survival_range = custom_params.survival_range
			if custom_params.has("birth_range"):
				_birth_range = custom_params.birth_range
			if custom_params.has("iterations"):
				_iterations = custom_params.iterations

# ==================== 工具函数 ====================

## 设置随机种子
func set_seed(new_seed: int) -> void:
	_rng.seed = new_seed


## 获取当前网格
func get_grid() -> Array:
	return _grid


## 获取网格尺寸
func get_size() -> Vector2i:
	return Vector2i(_width, _height)


## 获取指定位置的单元格状态
func get_cell(x: int, y: int) -> int:
	if x < 0 or x >= _width or y < 0 or y >= _height:
		return CellState.WALL
	return _grid[y][x]


## 设置指定位置的单元格状态
func set_cell(x: int, y: int, state: CellState) -> void:
	if x >= 0 and x < _width and y >= 0 and y < _height:
		_grid[y][x] = state


## 检查位置是否可行走
func is_walkable(x: int, y: int) -> bool:
	return get_cell(x, y) == CellState.EMPTY


## 找到随机空白位置
func find_random_empty_position() -> Vector2i:
	var attempts: int = 1000
	while attempts > 0:
		var x: int = _rng.randi_range(1, _width - 2)
		var y: int = _rng.randi_range(1, _height - 2)
		if _grid[y][x] == CellState.EMPTY:
			return Vector2i(x, y)
		attempts -= 1
	return Vector2i(-1, -1)
