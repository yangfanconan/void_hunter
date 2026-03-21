## terrain_noise.gd - Perlin噪声地形生成器
## 使用经典Perlin噪声算法生成自然地形
## 支持多层噪声叠加(分形噪声)以获得更自然的效果

class_name TerrainNoise
extends RefCounted

# ==================== 常量定义 ====================
## 排列表，用于哈希计算
const PERMUTATION: Array[int] = [
	151, 160, 137, 91, 90, 15, 131, 13, 201, 95, 96, 53, 194, 233, 7, 225,
	140, 36, 103, 30, 69, 142, 8, 99, 37, 240, 21, 10, 23, 190, 6, 148,
	247, 120, 234, 75, 0, 26, 197, 62, 94, 252, 219, 203, 117, 35, 11, 32,
	57, 177, 33, 88, 237, 149, 56, 87, 174, 20, 125, 136, 171, 168, 68, 175,
	74, 165, 71, 134, 139, 48, 27, 166, 77, 146, 158, 231, 83, 111, 229, 122,
	60, 211, 133, 230, 220, 105, 92, 41, 55, 46, 245, 40, 244, 102, 143, 54,
	65, 25, 63, 161, 1, 216, 80, 73, 209, 76, 132, 187, 208, 89, 18, 169,
	200, 196, 135, 130, 116, 188, 159, 86, 164, 100, 109, 198, 173, 186, 3, 64,
	52, 217, 226, 250, 124, 123, 5, 202, 38, 147, 118, 126, 255, 82, 85, 212,
	207, 206, 59, 227, 47, 16, 58, 17, 182, 189, 28, 42, 223, 183, 170, 213,
	119, 248, 152, 2, 44, 154, 163, 70, 221, 153, 101, 155, 167, 43, 172, 9,
	129, 22, 39, 253, 19, 98, 108, 110, 79, 113, 224, 232, 178, 185, 112, 104,
	218, 246, 97, 228, 251, 34, 242, 193, 238, 210, 144, 12, 191, 179, 162, 241,
	81, 51, 145, 235, 249, 14, 239, 107, 49, 192, 214, 31, 181, 199, 106, 157,
	184, 84, 204, 176, 115, 121, 50, 45, 127, 4, 150, 254, 138, 236, 205, 93,
	222, 114, 67, 29, 24, 72, 243, 141, 128, 195, 78, 66, 215, 61, 156, 180
]

# ==================== 成员变量 ====================
## 排列表副本（重复以避免模运算）
var _permutation: Array[int] = []
## 随机种子
var _seed: int = 0
## 噪声缩放因子
var _scale: float = 100.0
## 八度数（分形层数）
var _octaves: int = 4
## 持久度（每层振幅衰减）
var _persistence: float = 0.5
## 间隙度（每层频率增长）
var _lacunarity: float = 2.0

# ==================== 初始化函数 ====================

## 初始化噪声生成器
## @param seed: 随机种子，用于生成可复现的地形
## @param scale: 噪声缩放因子，值越大地形越平缓
## @param octaves: 分形层数，增加细节
## @param persistence: 振幅衰减率
## @param lacunarity: 频率增长率
func _init(
	seed: int = 0,
	scale: float = 100.0,
	octaves: int = 4,
	persistence: float = 0.5,
	lacunarity: float = 2.0
) -> void:
	_seed = seed
	_scale = scale
	_octaves = octaves
	_persistence = persistence
	_lacunarity = lacunarity
	_initialize_permutation()


## 初始化排列表，应用种子打乱
func _initialize_permutation() -> void:
	# 复制原始排列表
	_permutation = PERMUTATION.duplicate()
	
	# 使用种子打乱排列表
	var rng = RandomNumberGenerator.new()
	rng.seed = _seed
	
	for i in range(255, 0, -1):
		var j: int = rng.randi_range(0, i)
		var temp: int = _permutation[i]
		_permutation[i] = _permutation[j]
		_permutation[j] = temp
	
	# 重复排列表以避免边界检查
	for i in range(256):
		_permutation.append(_permutation[i])

# ==================== 噪声计算函数 ====================

## 计算2D Perlin噪声值
## @param x: X坐标
## @param y: Y坐标
## @return: 噪声值，范围[-1, 1]
func noise_2d(x: float, y: float) -> float:
	# 找到单位方格的坐标
	var xi: int = int(floor(x)) & 255
	var yi: int = int(floor(y)) & 255
	
	# 计算方格内的相对位置
	var xf: float = x - floor(x)
	var yf: float = y - floor(y)
	
	# 计算缓动曲线值（改进的Perlin噪声使用6t^5-15t^4+10t^3）
	var u: float = _fade(xf)
	var v: float = _fade(yf)
	
	# 哈希四个角的梯度索引
	var aa: int = _hash(xi, yi)
	var ab: int = _hash(xi, yi + 1)
	var ba: int = _hash(xi + 1, yi)
	var bb: int = _hash(xi + 1, yi + 1)
	
	# 计算四个角的梯度贡献
	var x1: float = _lerp(_grad(aa, xf, yf), _grad(ba, xf - 1, yf), u)
	var x2: float = _lerp(_grad(ab, xf, yf - 1), _grad(bb, xf - 1, yf - 1), u)
	
	return _lerp(x1, x2, v)


## 计算分形噪声（FBM - 分形布朗运动）
## @param x: X坐标
## @param y: Y坐标
## @return: 噪声值，范围约[-1, 1]
func fractal_noise_2d(x: float, y: float) -> float:
	var total: float = 0.0
	var frequency: float = 1.0
	var amplitude: float = 1.0
	var max_value: float = 0.0
	
	for i in range(_octaves):
		# 累加每层噪声
		total += amplitude * noise_2d(x * frequency, y * frequency)
		
		# 更新最大值用于归一化
		max_value += amplitude
		
		# 更新频率和振幅
		frequency *= _lacunarity
		amplitude *= _persistence
	
	# 归一化到[-1, 1]范围
	return total / max_value


## 生成地形网格
## @param width: 网格宽度
## @param height: 网格高度
## @param offset_x: X偏移（用于生成不同区域）
## @param offset_y: Y偏移
## @return: 2D数组，包含每个位置的地形高度值[0, 1]
func generate_terrain_grid(width: int, height: int, offset_x: float = 0.0, offset_y: float = 0.0) -> Array:
	var grid: Array = []
	grid.resize(height)
	
	for y in range(height):
		grid[y] = []
		grid[y].resize(width)
		for x in range(width):
			# 计算归一化的噪声值
			var noise_value: float = fractal_noise_2d(
				(x + offset_x) / _scale,
				(y + offset_y) / _scale
			)
			# 将[-1, 1]映射到[0, 1]
			grid[y][x] = (noise_value + 1.0) * 0.5
	
	return grid


## 生成多层噪声网格（用于不同地形类型）
## @param width: 网格宽度
## @param height: 网格高度
## @param layers: 层数
## @return: 3D数组，每层一个噪声网格
func generate_multi_layer_noise(width: int, height: int, layers: int) -> Array:
	var result: Array = []
	result.resize(layers)
	
	for layer in range(layers):
		# 每层使用不同的偏移以获得不同的噪声
		var offset: float = layer * 1000.0 + _seed
		result[layer] = generate_terrain_grid(width, height, offset, offset + 500.0)
	
	return result

# ==================== 辅助函数 ====================

## 缓动函数：6t^5 - 15t^4 + 10t^3
## 使噪声在网格边界处更平滑
func _fade(t: float) -> float:
	return t * t * t * (t * (t * 6.0 - 15.0) + 10.0)


## 线性插值
func _lerp(a: float, b: float, t: float) -> float:
	return a + t * (b - a)


## 哈希函数：获取梯度表索引
func _hash(x: int, y: int) -> int:
	return _permutation[_permutation[x] + y]


## 梯度函数：计算梯度向量的点积
func _grad(hash_value: int, x: float, y: float) -> float:
	# 使用低3位确定梯度方向（8个方向）
	var h: int = hash_value & 7
	
	# 8个预定义的2D梯度向量
	var grad_x: float
	var grad_y: float
	
	match h:
		0: grad_x = 1.0; grad_y = 0.0
		1: grad_x = -1.0; grad_y = 0.0
		2: grad_x = 0.0; grad_y = 1.0
		3: grad_x = 0.0; grad_y = -1.0
		4: grad_x = 1.0; grad_y = 1.0
		5: grad_x = -1.0; grad_y = 1.0
		6: grad_x = 1.0; grad_y = -1.0
		_: grad_x = -1.0; grad_y = -1.0
	
	# 返回梯度与距离向量的点积
	return grad_x * x + grad_y * y

# ==================== 工具函数 ====================

## 设置噪声参数
func set_parameters(scale: float, octaves: int, persistence: float, lacunarity: float) -> void:
	_scale = scale
	_octaves = octaves
	_persistence = persistence
	_lacunarity = lacunarity


## 重新设置种子
func set_seed(new_seed: int) -> void:
	_seed = new_seed
	_initialize_permutation()


## 获取当前参数
func get_parameters() -> Dictionary:
	return {
		"seed": _seed,
		"scale": _scale,
		"octaves": _octaves,
		"persistence": _persistence,
		"lacunarity": _lacunarity
	}
