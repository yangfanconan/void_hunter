## Void Hunter - 关卡生成器
## @description: 程序化生成关卡，包含房间布局、敌人配置和战利品放置
## @author: Void Hunter Team
## @version: 0.1.0

extends Node2D
class_name LevelGenerator

# =============================================================================
# 信号定义
# =============================================================================

## 关卡生成完成时触发
signal level_generated(level_data: Dictionary)

## 房间生成完成时触发
signal room_generated(room_index: int, room_data: Dictionary)

## 所有房间清理完成时触发
signal rooms_cleared()

## Boss房间激活时触发
signal boss_room_activated()

# =============================================================================
# 常量定义
# =============================================================================

## 默认房间数量
const DEFAULT_ROOM_COUNT: int = 5

## 房间最小尺寸
const MIN_ROOM_SIZE: Vector2i = Vector2i(10, 10)

## 房间最大尺寸
const MAX_ROOM_SIZE: Vector2i = Vector2i(20, 20)

## 瓦片大小
const TILE_SIZE: int = 32

## 默认房间间距
const ROOM_SPACING: int = 3

# =============================================================================
# 枚举定义
# =============================================================================

## 房间类型
enum RoomType {
	START,			## 起始房间
	STANDARD,		## 标准房间
	ELITE,			## 精英房间
	SHOP,			## 商店房间
	REST,			## 休息房间
	BOSS,			## Boss房间
	SECRET			## 秘密房间
}

## 房间连接方向
enum ConnectionDirection {
	NORTH,
	SOUTH,
	EAST,
	WEST
}

## 生成算法类型
enum GenerationAlgorithm {
	RANDOM,			## 随机生成
	BSP,			## 二叉空间分割
	CELLULAR,		## 元胞自动机
	PREDEFINED		## 预定义布局
}

# =============================================================================
# 导出变量
# =============================================================================

## 当前关卡索引
@export var current_level: int = 1

## 房间数量
@export_range(3, 15) var room_count: int = DEFAULT_ROOM_COUNT

## 生成算法
@export var generation_algorithm: GenerationAlgorithm = GenerationAlgorithm.RANDOM

## 是否包含Boss房间
@export var include_boss_room: bool = true

## 是否包含商店
@export var include_shop: bool = true

## 是否包含休息房间
@export var include_rest_room: bool = true

## 敌人密度（0.0 - 1.0）
@export_range(0.0, 1.0) var enemy_density: float = 0.3

## 道具密度（0.0 - 1.0）
@export_range(0.0, 1.0) var item_density: float = 0.1

## 关卡主题
@export var level_theme: String = "dungeon"

# =============================================================================
# 公共变量
# =============================================================================

## 生成的房间列表
var rooms: Array[Dictionary] = []

## 当前房间索引
var current_room_index: int = 0

## 房间连接图
var room_connections: Dictionary = {}

## 关卡网格
var level_grid: Dictionary = {}

## 是否已生成
var is_generated: bool = false

# =============================================================================
# 私有变量
# =============================================================================

var _tile_map: TileMap
var _enemy_spawns: Array[Vector2] = []
var _item_spawns: Array[Vector2] = []
var _used_positions: Array[Vector2i] = []
var _rng: RandomNumberGenerator

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""
	节点就绪时初始化关卡生成器
	"""
	_initialize_generator()


# =============================================================================
# 公共方法 - 初始化
# =============================================================================

## 初始化生成器
func initialize() -> void:
	"""
	手动初始化关卡生成器
	"""
	_initialize_generator()


# =============================================================================
# 公共方法 - 关卡生成
# =============================================================================

## 生成关卡
func generate_level(level_index: int = 1, seed_value: int = -1) -> void:
	"""
	生成新关卡
	@param level_index: 关卡索引
	@param seed_value: 随机种子（-1表示随机）
	"""
	current_level = level_index
	is_generated = false
	
	# 初始化随机数生成器
	_setup_rng(seed_value)
	
	# 清理旧关卡
	clear_level()
	
	# 根据难度调整参数
	_adjust_for_difficulty()
	
	# 生成房间布局
	match generation_algorithm:
		GenerationAlgorithm.RANDOM:
			_generate_random_layout()
		GenerationAlgorithm.BSP:
			_generate_bsp_layout()
		GenerationAlgorithm.CELLULAR:
			_generate_cellular_layout()
		GenerationAlgorithm.PREDEFINED:
			_generate_predefined_layout()
	
	# 连接房间
	_connect_rooms()
	
	# 生成瓦片地图
	_generate_tilemap()
	
	# 放置敌人和道具
	_populate_rooms()
	
	# 放置玩家
	_place_player()
	
	is_generated = true
	
	# 发送完成信号
	var level_data: Dictionary = _collect_level_data()
	level_generated.emit(level_data)


## 清理关卡
func clear_level() -> void:
	"""
	清理当前关卡
	"""
	rooms.clear()
	room_connections.clear()
	level_grid.clear()
	_used_positions.clear()
	_enemy_spawns.clear()
	_item_spawns.clear()
	current_room_index = 0
	is_generated = false
	
	# 清理瓦片地图
	if _tile_map:
		_tile_map.clear()
	
	# 清理所有动态生成的节点
	for child in get_children():
		if child.is_in_group("dynamic_level_content"):
			child.queue_free()


## 进入下一房间
func advance_to_next_room() -> void:
	"""
	进入下一个房间
	"""
	if current_room_index >= rooms.size() - 1:
		push_warning("已经是最后一个房间")
		return
	
	current_room_index += 1
	_on_room_enter(rooms[current_room_index])


## 获取当前房间
func get_current_room() -> Dictionary:
	"""
	获取当前房间数据
	@return: 当前房间数据
	"""
	if current_room_index >= 0 and current_room_index < rooms.size():
		return rooms[current_room_index]
	return {}


## 获取房间数量
func get_room_count() -> int:
	"""
	获取总房间数量
	@return: 房间数量
	"""
	return rooms.size()


## 检查房间是否已清理
func is_room_cleared(room_index: int) -> bool:
	"""
	检查指定房间是否已清理
	@param room_index: 房间索引
	@return: 是否已清理
	"""
	if room_index < 0 or room_index >= rooms.size():
		return false
	
	return rooms[room_index].get("is_cleared", false)


## 标记房间已清理
func mark_room_cleared(room_index: int) -> void:
	"""
	标记房间为已清理
	@param room_index: 房间索引
	"""
	if room_index >= 0 and room_index < rooms.size():
		rooms[room_index]["is_cleared"] = true
		
		# 检查是否所有房间都已清理
		_check_all_rooms_cleared()


# =============================================================================
# 公共方法 - 房间查询
# =============================================================================

## 获取指定位置的房间
func get_room_at_position(world_position: Vector2) -> Dictionary:
	"""
	获取指定世界位置的房间
	@param world_position: 世界坐标
	@return: 房间数据
	"""
	for room in rooms:
		var room_rect: Rect2 = room.get("world_rect", Rect2())
		if room_rect.has_point(world_position):
			return room
	return {}


## 获取连接的房间
func get_connected_rooms(room_index: int) -> Array[int]:
	"""
	获取与指定房间连接的所有房间
	@param room_index: 房间索引
	@return: 连接的房间索引数组
	"""
	return room_connections.get(room_index, [])


# =============================================================================
# 私有方法 - 初始化
# =============================================================================

func _initialize_generator() -> void:
	"""
	初始化生成器
	"""
	_rng = RandomNumberGenerator.new()
	_rng.randomize()
	
	# 创建或获取瓦片地图
	_tile_map = get_node_or_null("TileMap")
	if _tile_map == null:
		_tile_map = TileMap.new()
		add_child(_tile_map)


func _setup_rng(seed_value: int) -> void:
	"""
	设置随机数生成器
	@param seed_value: 种子值
	"""
	if seed_value >= 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()


func _adjust_for_difficulty() -> void:
	"""
	根据关卡难度调整参数
	"""
	var difficulty: float = GameManager.difficulty_multiplier
	
	# 增加敌人密度
	enemy_density = minf(0.6, enemy_density + (difficulty - 1.0) * 0.1)
	
	# 减少道具密度
	item_density = maxf(0.05, item_density - (difficulty - 1.0) * 0.02)
	
	# 高级关卡可能增加房间数
	if current_level >= 5:
		room_count += 1


# =============================================================================
# 私有方法 - 房间生成
# =============================================================================

func _generate_random_layout() -> void:
	"""
	生成随机房间布局
	"""
	# 创建起始房间
	_create_start_room()
	
	# 创建标准房间
	var standard_room_count: int = room_count - 1
	if include_boss_room:
		standard_room_count -= 1
	if include_shop:
		standard_room_count -= 1
	if include_rest_room:
		standard_room_count -= 1
	
	for i in range(standard_room_count):
		_create_room(RoomType.STANDARD)
	
	# 创建特殊房间
	if include_shop:
		_create_room(RoomType.SHOP)
	if include_rest_room:
		_create_room(RoomType.REST)
	if include_boss_room:
		_create_room(RoomType.BOSS)


func _generate_bsp_layout() -> void:
	"""
	使用二叉空间分割生成布局
	"""
	# TODO: 实现BSP算法
	_generate_random_layout()


func _generate_cellular_layout() -> void:
	"""
	使用元胞自动机生成布局
	"""
	# TODO: 实现元胞自动机算法
	_generate_random_layout()


func _generate_predefined_layout() -> void:
	"""
	使用预定义布局
	"""
	# TODO: 加载预定义的关卡布局
	_generate_random_layout()


func _create_start_room() -> void:
	"""
	创建起始房间
	"""
	var room_size: Vector2i = _get_random_room_size()
	var room_data: Dictionary = {
		"index": 0,
		"type": RoomType.START,
		"size": room_size,
		"position": Vector2i.ZERO,
		"world_rect": Rect2(Vector2.ZERO, Vector2(room_size * TILE_SIZE)),
		"enemy_count": 0,
		"item_count": 0,
		"is_cleared": true
	}
	
	rooms.append(room_data)
	_used_positions.append(Vector2i.ZERO)
	room_generated.emit(0, room_data)


func _create_room(room_type: RoomType) -> void:
	"""
	创建指定类型的房间
	@param room_type: 房间类型
	"""
	var room_size: Vector2i = _get_random_room_size()
	var position: Vector2i = _find_valid_room_position(room_size)
	
	if position == Vector2i.MIN:
		push_warning("无法找到有效的房间位置")
		return
	
	var room_index: int = rooms.size()
	var world_position: Vector2 = Vector2(position * (room_size + Vector2i.ONE * ROOM_SPACING) * TILE_SIZE)
	
	var enemy_count: int = 0
	var item_count: int = 0
	
	# 根据房间类型设置敌人和道具数量
	match room_type:
		RoomType.STANDARD:
			enemy_count = _rng.randi_range(2, 5)
			item_count = _rng.randi_range(0, 2)
		RoomType.ELITE:
			enemy_count = _rng.randi_range(1, 2)
			item_count = _rng.randi_range(2, 4)
		RoomType.BOSS:
			enemy_count = 1
			item_count = _rng.randi_range(3, 5)
		RoomType.SHOP, RoomType.REST:
			enemy_count = 0
			item_count = _rng.randi_range(1, 3)
	
	# 应用密度
	enemy_count = int(enemy_count * enemy_density)
	item_count = int(item_count * item_density)
	
	var room_data: Dictionary = {
		"index": room_index,
		"type": room_type,
		"size": room_size,
		"position": position,
		"world_rect": Rect2(world_position, Vector2(room_size * TILE_SIZE)),
		"enemy_count": enemy_count,
		"item_count": item_count,
		"is_cleared": false
	}
	
	rooms.append(room_data)
	_used_positions.append(position)
	room_generated.emit(room_index, room_data)


func _get_random_room_size() -> Vector2i:
	"""
	获取随机房间尺寸
	@return: 房间尺寸
	"""
	var width: int = _rng.randi_range(MIN_ROOM_SIZE.x, MAX_ROOM_SIZE.x)
	var height: int = _rng.randi_range(MIN_ROOM_SIZE.y, MAX_ROOM_SIZE.y)
	return Vector2i(width, height)


func _find_valid_room_position(room_size: Vector2i) -> Vector2i:
	"""
	查找有效的房间位置
	@param room_size: 房间尺寸
	@return: 有效位置（如果找不到返回Vector2i.MIN）
	"""
	# 从现有房间旁边寻找位置
	for _attempt in range(100):
		# 随机选择一个已存在的房间
		var existing_room: Dictionary = rooms[_rng.randi() % rooms.size()]
		var existing_pos: Vector2i = existing_room.get("position", Vector2i.ZERO)
		
		# 随机选择方向
		var directions: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
		var direction: Vector2i = directions[_rng.randi() % directions.size()]
		
		var new_pos: Vector2i = existing_pos + direction * (room_size + Vector2i.ONE * ROOM_SPACING)
		
		# 检查位置是否有效
		if _is_position_valid(new_pos, room_size):
			return new_pos
	
	return Vector2i.MIN


func _is_position_valid(position: Vector2i, room_size: Vector2i) -> bool:
	"""
	检查位置是否有效
	@param position: 位置
	@param room_size: 房间尺寸
	@return: 是否有效
	"""
	for used_pos in _used_positions:
		# 检查是否与现有房间重叠
		var distance: Vector2i = (position - used_pos).abs()
		if distance.x < room_size.x + ROOM_SPACING and distance.y < room_size.y + ROOM_SPACING:
			return false
	
	return true


func _connect_rooms() -> void:
	"""
	连接所有房间
	"""
	# 简单的线性连接
	for i in range(rooms.size() - 1):
		_create_connection(i, i + 1)
	
	# 添加一些额外的连接（分支路径）
	var extra_connections: int = _rng.randi_range(0, rooms.size() / 3)
	for _i in range(extra_connections):
		var room_a: int = _rng.randi_range(0, rooms.size() - 1)
		var room_b: int = _rng.randi_range(0, rooms.size() - 1)
		if room_a != room_b:
			_create_connection(room_a, room_b)


func _create_connection(room_a: int, room_b: int) -> void:
	"""
	创建两个房间之间的连接
	@param room_a: 房间A索引
	@param room_b: 房间B索引
	"""
	if not room_connections.has(room_a):
		room_connections[room_a] = []
	if not room_connections.has(room_b):
		room_connections[room_b] = []
	
	if room_b not in room_connections[room_a]:
		room_connections[room_a].append(room_b)
	if room_a not in room_connections[room_b]:
		room_connections[room_b].append(room_a)


# =============================================================================
# 私有方法 - 瓦片地图生成
# =============================================================================

func _generate_tilemap() -> void:
	"""
	生成瓦片地图
	"""
	# TODO: 实现瓦片地图生成
	# 这里应该根据房间数据生成实际的瓦片地图
	pass


func _populate_rooms() -> void:
	"""
	填充房间内容（敌人和道具）
	"""
	# TODO: 实现敌人和道具的放置
	# 这里应该根据房间配置生成敌人和道具
	pass


func _place_player() -> void:
	"""
	放置玩家
	"""
	if rooms.is_empty():
		return
	
	var start_room: Dictionary = rooms[0]
	var spawn_position: Vector2 = start_room.get("world_rect", Rect2()).position
	spawn_position += Vector2(start_room.get("size", Vector2i.ONE) * TILE_SIZE) / 2
	
	# 通知游戏管理器
	# 实际的玩家放置在主场景中处理
	pass


func _on_room_enter(room_data: Dictionary) -> void:
	"""
	进入房间时的处理
	@param room_data: 房间数据
	"""
	var room_type: RoomType = room_data.get("type", RoomType.STANDARD)
	
	# 特殊房间处理
	match room_type:
		RoomType.SHOP:
			# 打开商店界面
			GameManager.set_game_state(GameManager.GameState.INVENTORY)
		RoomType.BOSS:
			boss_room_activated.emit()


func _check_all_rooms_cleared() -> void:
	"""
	检查是否所有房间都已清理
	"""
	for room in rooms:
		if not room.get("is_cleared", false):
			return
	
	rooms_cleared.emit()
	
	# 如果包含Boss房间且已清理，触发胜利
	if include_boss_room and rooms[-1].get("is_cleared", false):
		GameManager.trigger_game_over(true)


func _collect_level_data() -> Dictionary:
	"""
	收集关卡数据
	@return: 关卡数据字典
	"""
	return {
		"level_index": current_level,
		"room_count": rooms.size(),
		"rooms": rooms.duplicate(),
		"connections": room_connections.duplicate(),
		"difficulty": GameManager.difficulty_multiplier,
		"theme": level_theme
	}
