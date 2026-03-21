## dynamic_elements.gd - 动态元素生成器
## 生成关卡中的动态元素：可破坏物体、隐藏通道、环境陷阱、互动元素
## 支持基于地形类型的智能放置

class_name DynamicElements
extends RefCounted

# ==================== 枚举定义 ====================
## 可破坏物体类型
enum DestructibleType {
	CRATE,        ## 木箱 - 普通掉落
	BARREL,       ## 木桶 - 可能爆炸
	CRYSTAL,      ## 水晶 - 高价值掉落
	VASE,         ## 花瓶 - 小量金币
	SKULL,        ## 骷髅 - 可能是敌人
	EGG           ## 蛋 - 可能孵化怪物
}

## 陷阱类型
enum TrapType {
	SPIKE,        ## 地刺 - 持续伤害
	FLAME,        ## 火焰喷射 - 间歇伤害
	POISON,       ## 毒雾 - 持续DOT
	BLADE,        ## 旋转刀刃 - 高伤害
	ARROW,        ## 箭矢陷阱 - 远程攻击
	SAW_BLADE,    ## 电锯 - 移动陷阱
	LAVA_Geyser   ## 岩浆喷泉 - 周期性喷发
}

## 互动元素类型
enum InteractiveType {
	ALTAR,        ## 祭坛 - 献祭获得增益
	SHOP,         ## 商店 - 购买道具
	PORTAL,       ## 传送门 - 快速移动
	CHEST,        ## 宝箱 - 打开获得奖励
	SHRINE,       ## 神龛 - 祈祷获得祝福
	LEVER,        ## 拉杆 - 触发机关
	SWITCH,       ## 开关 - 开启通道
	TELEPORTER,   ## 传送点 - 成对出现
	HEALING_POOL  ## 治愈池 - 恢复生命
}

## 隐藏通道类型
enum SecretType {
	BREAKABLE_WALL,   ## 可破坏墙壁
	FAKE_FLOOR,       ## 假地板
	HIDDEN_DOOR,      ## 隐藏门
	SECRET_PASSAGE    ## 秘密通道
}

## 道具类型
enum ItemType {
	HEALTH_POTION,    ## 生命药水
	MANA_POTION,      ## 法力药水
	KEY,              ## 钥匙
	BOMB,             ## 炸弹
	SCROLL,           ## 卷轴
	GEM,              ## 宝石
	GOLD,             ## 金币
	SKILL_GEM         ## 技能宝石
}

# ==================== 配置常量 ====================
## 可破坏物体配置
const DESTRUCTIBLE_CONFIGS: Dictionary = {
	DestructibleType.CRATE: {
		"health": 30,
		"drop_chance": 0.6,
		"possible_drops": [ItemType.HEALTH_POTION, ItemType.GOLD, ItemType.KEY],
		"weight": 1.0
	},
	DestructibleType.BARREL: {
		"health": 20,
		"drop_chance": 0.4,
		"explosion_chance": 0.3,
		"possible_drops": [ItemType.BOMB, ItemType.GOLD],
		"weight": 0.8
	},
	DestructibleType.CRYSTAL: {
		"health": 50,
		"drop_chance": 0.9,
		"possible_drops": [ItemType.GEM, ItemType.SKILL_GEM, ItemType.MANA_POTION],
		"weight": 0.3
	},
	DestructibleType.VASE: {
		"health": 10,
		"drop_chance": 0.7,
		"possible_drops": [ItemType.GOLD, ItemType.SCROLL],
		"weight": 0.6
	},
	DestructibleType.SKULL: {
		"health": 15,
		"drop_chance": 0.5,
		"enemy_spawn_chance": 0.4,
		"possible_drops": [ItemType.GOLD, ItemType.SCROLL],
		"weight": 0.4
	},
	DestructibleType.EGG: {
		"health": 25,
		"drop_chance": 0.3,
		"enemy_spawn_chance": 0.6,
		"possible_drops": [ItemType.HEALTH_POTION],
		"weight": 0.3
	}
}

## 陷阱配置
const TRAP_CONFIGS: Dictionary = {
	TrapType.SPIKE: {
		"damage": 15,
		"trigger_delay": 0.0,
		"cooldown": 1.0,
		"weight": 1.0
	},
	TrapType.FLAME: {
		"damage": 25,
		"trigger_delay": 0.5,
		"active_duration": 2.0,
		"cooldown": 3.0,
		"weight": 0.7
	},
	TrapType.POISON: {
		"damage": 5,
		"dot_duration": 5.0,
		"trigger_delay": 0.0,
		"weight": 0.6
	},
	TrapType.BLADE: {
		"damage": 35,
		"rotation_speed": 2.0,
		"weight": 0.5
	},
	TrapType.ARROW: {
		"damage": 20,
		"range": 10.0,
		"trigger_radius": 3.0,
		"cooldown": 2.0,
		"weight": 0.4
	},
	TrapType.SAW_BLADE: {
		"damage": 40,
		"move_speed": 3.0,
		"patrol_distance": 8.0,
		"weight": 0.3
	},
	TrapType.LAVA_Geyser: {
		"damage": 30,
		"eruption_interval": 4.0,
		"warning_time": 1.0,
		"weight": 0.2
	}
}

# ==================== 成员变量 ====================
## 网格宽度
var _width: int = 128
## 网格高度
var _height: int = 128
## 地形网格引用
var _terrain_grid: Array = []
## 可行走区域
var _walkable_positions: Array = []
## 已放置元素位置（避免重叠）
var _occupied_positions: Dictionary = {}
## 随机数生成器
var _rng: RandomNumberGenerator
## 生成的元素数据
var _generated_elements: Dictionary = {}

# ==================== 初始化函数 ====================

## 初始化动态元素生成器
## @param width: 网格宽度
## @param height: 网格高度
## @param seed: 随机种子
func _init(width: int = 128, height: int = 128, seed: int = 0) -> void:
	_width = width
	_height = height
	_rng = RandomNumberGenerator.new()
	_rng.seed = seed
	_generated_elements = {
		"destructibles": [],
		"traps": [],
		"interactives": [],
		"secrets": [],
		"items": [],
		"enemy_spawns": []
	}


## 设置地形网格
func set_terrain_grid(grid: Array) -> void:
	_terrain_grid = grid
	_update_walkable_positions()

# ==================== 主要生成函数 ====================

## 生成所有动态元素
## @param terrain_grid: 地形网格
## @param config: 生成配置
## @return: 生成的元素数据
func generate_all(terrain_grid: Array, config: Dictionary = {}) -> Dictionary:
	set_terrain_grid(terrain_grid)
	_occupied_positions.clear()
	
	# 合并默认配置
	var final_config: Dictionary = _get_default_config().merged(config, true)
	
	# 按顺序生成各类元素
	_generate_destructibles(final_config.destructible_density)
	_generate_traps(final_config.trap_density)
	_generate_interactives(final_config.interactive_config)
	_generate_secrets(final_config.secret_count)
	_generate_items(final_config.item_density)
	_generate_enemy_spawns(final_config.enemy_spawn_config)
	
	return _generated_elements


## 获取默认配置
func _get_default_config() -> Dictionary:
	return {
		"destructible_density": 0.02,
		"trap_density": 0.01,
		"interactive_config": {
			"altars": 2,
			"shops": 1,
			"portals": 2,
			"chests": 5,
			"healing_pools": 1
		},
		"secret_count": 3,
		"item_density": 0.005,
		"enemy_spawn_config": {
			"min_spawns": 5,
			"max_spawns": 15,
			"min_distance_from_start": 15
		}
	}

# ==================== 可破坏物体生成 ====================

## 生成可破坏物体
func _generate_destructibles(density: float) -> void:
	var count: int = int(_walkable_positions.size() * density)
	count = clampi(count, 5, 100)
	
	for i in range(count):
		var pos: Vector2i = _get_random_walkable_position(3.0)
		if pos.x >= 0:
			var destructible_type: int = _select_destructible_type()
			var element_data: Dictionary = _create_destructible_data(pos, destructible_type)
			_generated_elements.destructibles.append(element_data)
			_occupied_positions[pos] = "destructible"


## 选择可破坏物体类型（基于权重）
func _select_destructible_type() -> int:
	var total_weight: float = 0.0
	var weights: Array = []
	
	for type in DESTRUCTIBLE_CONFIGS.keys():
		var weight: float = DESTRUCTIBLE_CONFIGS[type].get("weight", 1.0)
		weights.append({"type": type, "weight": weight})
		total_weight += weight
	
	var roll: float = _rng.randf() * total_weight
	var cumulative: float = 0.0
	
	for w in weights:
		cumulative += w.weight
		if roll <= cumulative:
			return w.type
	
	return DestructibleType.CRATE


## 创建可破坏物体数据
func _create_destructible_data(pos: Vector2i, type: int) -> Dictionary:
	var config: Dictionary = DESTRUCTIBLE_CONFIGS.get(type, {})
	
	var data: Dictionary = {
		"position": pos,
		"type": type,
		"health": config.get("health", 30),
		"drop_chance": config.get("drop_chance", 0.5),
		"possible_drops": config.get("possible_drops", []),
		"explosion_chance": config.get("explosion_chance", 0.0),
		"enemy_spawn_chance": config.get("enemy_spawn_chance", 0.0)
	}
	
	# 决定掉落物
	if _rng.randf() < data.drop_chance:
		data["actual_drop"] = _select_random_drop(data.possible_drops)
	
	return data


## 随机选择掉落物
func _select_random_drop(possible_drops: Array) -> Dictionary:
	if possible_drops.is_empty():
		return {}
	
	var item_type: int = possible_drops[_rng.randi_range(0, possible_drops.size() - 1)]
	return {
		"item_type": item_type,
		"quantity": _rng.randi_range(1, 3)
	}

# ==================== 陷阱生成 ====================

## 生成陷阱
func _generate_traps(density: float) -> void:
	var count: int = int(_walkable_positions.size() * density)
	count = clampi(count, 3, 50)
	
	for i in range(count):
		# 陷阱需要放置在特定位置（走廊、狭窄通道等）
		var pos: Vector2i = _find_trap_position()
		if pos.x >= 0:
			var trap_type: int = _select_trap_type()
			var element_data: Dictionary = _create_trap_data(pos, trap_type)
			_generated_elements.traps.append(element_data)
			_occupied_positions[pos] = "trap"


## 寻找适合放置陷阱的位置
func _find_trap_position() -> Vector2i:
	var attempts: int = 50
	
	while attempts > 0:
		var pos: Vector2i = _get_random_walkable_position(2.0)
		if pos.x < 0:
			attempts -= 1
			continue
		
		# 检查是否是走廊或狭窄区域
		if _is_corridor_position(pos) or _rng.randf() < 0.3:
			return pos
		
		attempts -= 1
	
	return Vector2i(-1, -1)


## 检查是否是走廊位置
func _is_corridor_position(pos: Vector2i) -> bool:
	# 检查水平和垂直方向的墙壁
	var horizontal_walls: int = 0
	var vertical_walls: int = 0
	
	# 水平检查
	for dx in range(-2, 3):
		if dx == 0:
			continue
		var check_pos: Vector2i = Vector2i(pos.x + dx, pos.y)
		if not _is_position_walkable(check_pos):
			horizontal_walls += 1
	
	# 垂直检查
	for dy in range(-2, 3):
		if dy == 0:
			continue
		var check_pos: Vector2i = Vector2i(pos.x, pos.y + dy)
		if not _is_position_walkable(check_pos):
			vertical_walls += 1
	
	# 如果一侧有墙，适合放陷阱
	return horizontal_walls >= 2 or vertical_walls >= 2


## 选择陷阱类型
func _select_trap_type() -> int:
	var total_weight: float = 0.0
	var weights: Array = []
	
	for type in TRAP_CONFIGS.keys():
		var weight: float = TRAP_CONFIGS[type].get("weight", 1.0)
		weights.append({"type": type, "weight": weight})
		total_weight += weight
	
	var roll: float = _rng.randf() * total_weight
	var cumulative: float = 0.0
	
	for w in weights:
		cumulative += w.weight
		if roll <= cumulative:
			return w.type
	
	return TrapType.SPIKE


## 创建陷阱数据
func _create_trap_data(pos: Vector2i, type: int) -> Dictionary:
	var config: Dictionary = TRAP_CONFIGS.get(type, {})
	
	return {
		"position": pos,
		"type": type,
		"damage": config.get("damage", 10),
		"trigger_delay": config.get("trigger_delay", 0.0),
		"cooldown": config.get("cooldown", 1.0),
		"active_duration": config.get("active_duration", 0.0),
		"direction": _determine_trap_direction(pos)
	}


## 确定陷阱朝向
func _determine_trap_direction(pos: Vector2i) -> Vector2i:
	# 检查哪个方向有更多空间
	var horizontal_space: int = 0
	var vertical_space: int = 0
	
	# 水平空间
	for dx in range(-5, 6):
		if _is_position_walkable(Vector2i(pos.x + dx, pos.y)):
			horizontal_space += 1
	
	# 垂直空间
	for dy in range(-5, 6):
		if _is_position_walkable(Vector2i(pos.x, pos.y + dy)):
			vertical_space += 1
	
	if horizontal_space > vertical_space:
		return Vector2i(1, 0)  # 水平
	else:
		return Vector2i(0, 1)  # 垂直

# ==================== 互动元素生成 ====================

## 生成互动元素
func _generate_interactives(config: Dictionary) -> void:
	# 生成祭坛
	for i in range(config.get("altars", 2)):
		_spawn_interactive(InteractiveType.ALTAR)
	
	# 生成商店
	for i in range(config.get("shops", 1)):
		_spawn_interactive(InteractiveType.SHOP)
	
	# 生成传送门（成对）
	var portal_count: int = config.get("portals", 2)
	if portal_count >= 2:
		_spawn_portal_pair()
	
	# 生成宝箱
	for i in range(config.get("chests", 5)):
		_spawn_interactive(InteractiveType.CHEST)
	
	# 生成治愈池
	for i in range(config.get("healing_pools", 1)):
		_spawn_interactive(InteractiveType.HEALING_POOL)


## 生成互动元素
func _spawn_interactive(type: int) -> void:
	var pos: Vector2i = _find_interactive_position(type)
	if pos.x >= 0:
		var element_data: Dictionary = {
			"position": pos,
			"type": type,
			"activated": false
		}
		
		# 添加类型特定数据
		match type:
			InteractiveType.ALTAR:
				element_data["offering_type"] = _rng.randi_range(0, 3)
				element_data["blessing"] = _generate_blessing()
			
			InteractiveType.SHOP:
				element_data["shop_items"] = _generate_shop_items()
			
			InteractiveType.CHEST:
				element_data["chest_tier"] = _rng.randi_range(0, 2)
				element_data["contents"] = _generate_chest_contents()
			
			InteractiveType.HEALING_POOL:
				element_data["heal_amount"] = _rng.randi_range(20, 50)
				element_data["uses_remaining"] = _rng.randi_range(1, 3)
		
		_generated_elements.interactives.append(element_data)
		_occupied_positions[pos] = "interactive"
		
		# 标记周围区域为已占用
		_mark_area_occupied(pos, 2)


## 生成传送门对
func _spawn_portal_pair() -> void:
	var pos1: Vector2i = _find_interactive_position(InteractiveType.PORTAL)
	if pos1.x < 0:
		return
	
	# 寻找第二个位置（需要一定距离）
	var pos2: Vector2i = _find_distant_position(pos1, 30)
	if pos2.x < 0:
		pos2 = _find_interactive_position(InteractiveType.PORTAL)
	
	if pos2.x >= 0:
		var portal_id: int = _rng.randi()
		
		_generated_elements.interactives.append({
			"position": pos1,
			"type": InteractiveType.PORTAL,
			"portal_id": portal_id,
			"paired_position": pos2
		})
		
		_generated_elements.interactives.append({
			"position": pos2,
			"type": InteractiveType.PORTAL,
			"portal_id": portal_id,
			"paired_position": pos1
		})
		
		_occupied_positions[pos1] = "interactive"
		_occupied_positions[pos2] = "interactive"


## 寻找互动元素位置
func _find_interactive_position(type: int) -> Vector2i:
	var min_space: int = 3  # 最小周围空间
	
	# 某些类型需要更大的空间
	match type:
		InteractiveType.SHOP, InteractiveType.HEALING_POOL:
			min_space = 5
	
	var attempts: int = 100
	while attempts > 0:
		var pos: Vector2i = _get_random_walkable_position(5.0)
		if pos.x >= 0 and _has_space_around(pos, min_space):
			return pos
		attempts -= 1
	
	return Vector2i(-1, -1)


## 寻找距离指定位置足够远的位置
func _find_distant_position(from_pos: Vector2i, min_distance: float) -> Vector2i:
	var best_pos: Vector2i = Vector2i(-1, -1)
	var max_dist: float = 0.0
	
	for i in range(50):
		var pos: Vector2i = _get_random_walkable_position(5.0)
		if pos.x >= 0:
			var dist: float = pos.distance_to(from_pos)
			if dist > min_distance and dist > max_dist:
				best_pos = pos
				max_dist = dist
	
	return best_pos


## 检查周围是否有足够空间
func _has_space_around(pos: Vector2i, radius: int) -> bool:
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			if dx == 0 and dy == 0:
				continue
			var check_pos: Vector2i = Vector2i(pos.x + dx, pos.y + dy)
			if not _is_position_walkable(check_pos):
				return false
	return true


## 生成祝福效果
func _generate_blessing() -> Dictionary:
	var blessing_types: Array = [
		{"type": "damage_boost", "value": _rng.randf_range(0.1, 0.3)},
		{"type": "speed_boost", "value": _rng.randf_range(0.1, 0.2)},
		{"type": "health_regen", "value": _rng.randf_range(1, 5)},
		{"type": "critical_chance", "value": _rng.randf_range(0.05, 0.15)}
	]
	return blessing_types[_rng.randi_range(0, blessing_types.size() - 1)]


## 生成商店物品
func _generate_shop_items() -> Array:
	var items: Array = []
	var item_count: int = _rng.randi_range(3, 6)
	
	for i in range(item_count):
		items.append({
			"item_type": _rng.randi_range(0, 6),  # 随机道具类型
			"price": _rng.randi_range(50, 200),
			"quantity": 1
		})
	
	return items


## 生成宝箱内容
func _generate_chest_contents() -> Array:
	var contents: Array = []
	var item_count: int = _rng.randi_range(1, 4)
	
	for i in range(item_count):
		contents.append({
			"item_type": _rng.randi_range(0, 7),
			"quantity": _rng.randi_range(1, 5)
		})
	
	return contents

# ==================== 隐藏通道生成 ====================

## 生成隐藏通道
func _generate_secrets(count: int) -> void:
	for i in range(count):
		var secret_type: int = _select_secret_type()
		var pos: Vector2i = _find_secret_position(secret_type)
		
		if pos.x >= 0:
			var element_data: Dictionary = {
				"position": pos,
				"type": secret_type,
				"discovered": false,
				"required_skill": _get_required_skill(secret_type)
			}
			
			# 生成秘密区域
			element_data["secret_area"] = _generate_secret_area(pos)
			element_data["reward"] = _generate_secret_reward()
			
			_generated_elements.secrets.append(element_data)


## 选择隐藏通道类型
func _select_secret_type() -> int:
	var types: Array = [
		SecretType.BREAKABLE_WALL,
		SecretType.FAKE_FLOOR,
		SecretType.HIDDEN_DOOR,
		SecretType.SECRET_PASSAGE
	]
	return types[_rng.randi_range(0, types.size() - 1)]


## 寻找隐藏通道位置
func _find_secret_position(secret_type: int) -> Vector2i:
	var attempts: int = 50
	
	while attempts > 0:
		# 秘密通道通常在墙壁附近
		var pos: Vector2i = _get_random_walkable_position(3.0)
		if pos.x >= 0:
			# 检查是否靠近墙壁
			if _is_adjacent_to_wall(pos):
				return pos
		attempts -= 1
	
	return Vector2i(-1, -1)


## 检查是否靠近墙壁
func _is_adjacent_to_wall(pos: Vector2i) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var check_pos: Vector2i = Vector2i(pos.x + dx, pos.y + dy)
			if not _is_position_walkable(check_pos):
				return true
	return false


## 获取解锁所需技能
func _get_required_skill(secret_type: int) -> String:
	match secret_type:
		SecretType.BREAKABLE_WALL:
			return "bomb" if _rng.randf() < 0.5 else "heavy_attack"
		SecretType.FAKE_FLOOR:
			return "detect_traps"
		SecretType.HIDDEN_DOOR:
			return "detect_secrets"
		SecretType.SECRET_PASSAGE:
			return "teleport"
	return "none"


## 生成秘密区域
func _generate_secret_area(entrance: Vector2i) -> Array:
	var area: Array = []
	var size: int = _rng.randi_range(3, 6)
	var direction: Vector2i = _find_wall_direction(entrance)
	
	for i in range(size):
		var offset: Vector2i = Vector2i(
			entrance.x + direction.x * (i + 1),
			entrance.y + direction.y * (i + 1)
		)
		area.append(offset)
		
		# 扩展宽度
		if i > 1:
			var perp: Vector2i = Vector2i(-direction.y, direction.x)
			area.append(Vector2i(offset.x + perp.x, offset.y + perp.y))
			area.append(Vector2i(offset.x - perp.x, offset.y - perp.y))
	
	return area


## 找到墙壁方向
func _find_wall_direction(pos: Vector2i) -> Vector2i:
	# 检查四个方向
	var directions: Array = [
		Vector2i(1, 0), Vector2i(-1, 0),
		Vector2i(0, 1), Vector2i(0, -1)
	]
	
	for dir in directions:
		var check_pos: Vector2i = Vector2i(pos.x + dir.x, pos.y + dir.y)
		if not _is_position_walkable(check_pos):
			return dir
	
	return Vector2i(1, 0)


## 生成秘密奖励
func _generate_secret_reward() -> Dictionary:
	return {
		"gold": _rng.randi_range(50, 200),
		"items": [
			{"item_type": ItemType.GEM, "quantity": _rng.randi_range(1, 3)}
		],
		"skill_gem_chance": 0.3
	}

# ==================== 道具生成 ====================

## 生成散落道具
func _generate_items(density: float) -> void:
	var count: int = int(_walkable_positions.size() * density)
	count = clampi(count, 3, 30)
	
	for i in range(count):
		var pos: Vector2i = _get_random_walkable_position(2.0)
		if pos.x >= 0:
			var item_type: int = _select_item_type()
			var element_data: Dictionary = {
				"position": pos,
				"item_type": item_type,
				"quantity": _rng.randi_range(1, 3)
			}
			_generated_elements.items.append(element_data)


## 选择道具类型
func _select_item_type() -> int:
	var weights: Array = [
		{"type": ItemType.HEALTH_POTION, "weight": 3.0},
		{"type": ItemType.MANA_POTION, "weight": 2.0},
		{"type": ItemType.KEY, "weight": 1.0},
		{"type": ItemType.BOMB, "weight": 1.5},
		{"type": ItemType.SCROLL, "weight": 2.0},
		{"type": ItemType.GOLD, "weight": 4.0},
		{"type": ItemType.GEM, "weight": 0.5},
		{"type": ItemType.SKILL_GEM, "weight": 0.2}
	]
	
	var total_weight: float = 0.0
	for w in weights:
		total_weight += w.weight
	
	var roll: float = _rng.randf() * total_weight
	var cumulative: float = 0.0
	
	for w in weights:
		cumulative += w.weight
		if roll <= cumulative:
			return w.type
	
	return ItemType.GOLD

# ==================== 敌人生成点 ====================

## 生成敌人刷新点
func _generate_enemy_spawns(config: Dictionary) -> void:
	var min_spawns: int = config.get("min_spawns", 5)
	var max_spawns: int = config.get("max_spawns", 15)
	var min_distance: int = config.get("min_distance_from_start", 15)
	
	var spawn_count: int = _rng.randi_range(min_spawns, max_spawns)
	
	for i in range(spawn_count):
		var pos: Vector2i = _find_enemy_spawn_position(min_distance)
		if pos.x >= 0:
			var spawn_data: Dictionary = {
				"position": pos,
				"enemy_types": _select_enemy_types(),
				"spawn_count": _rng.randi_range(1, 4),
				"trigger_radius": _rng.randf_range(5, 10),
				"is_boss_spawn": (i == 0 and _rng.randf() < 0.1)
			}
			_generated_elements.enemy_spawns.append(spawn_data)
			_mark_area_occupied(pos, 3)


## 寻找敌人生成位置
func _find_enemy_spawn_position(min_distance: int) -> Vector2i:
	var attempts: int = 50
	
	while attempts > 0:
		var pos: Vector2i = _get_random_walkable_position(5.0)
		if pos.x >= 0:
			# 确保远离起点
			if pos.x > min_distance or pos.y > min_distance:
				# 确保有足够的空间
				if _has_space_around(pos, 2):
					return pos
		attempts -= 1
	
	return Vector2i(-1, -1)


## 选择敌人类型
func _select_enemy_types() -> Array:
	var types: Array = []
	var type_count: int = _rng.randi_range(1, 3)
	
	for i in range(type_count):
		types.append(_rng.randi_range(0, 10))  # 假设有10种敌人类型
	
	return types

# ==================== 辅助函数 ====================

## 更新可行走位置列表
func _update_walkable_positions() -> void:
	_walkable_positions.clear()
	
	for y in range(_height):
		for x in range(_width):
			if _is_position_walkable(Vector2i(x, y)):
				_walkable_positions.append(Vector2i(x, y))


## 检查位置是否可行走
func _is_position_walkable(pos: Vector2i) -> bool:
	if pos.x < 0 or pos.x >= _width or pos.y < 0 or pos.y >= _height:
		return false
	
	if _terrain_grid.is_empty() or _terrain_grid.size() <= pos.y:
		return false
	if _terrain_grid[pos.y].is_empty() or _terrain_grid[pos.y].size() <= pos.x:
		return false
	
	# 假设 0 = GROUND, 其他为障碍
	var terrain: int = _terrain_grid[pos.y][pos.x]
	return terrain == 0  # TerrainType.GROUND


## 获取随机可行走位置
func _get_random_walkable_position(margin: float = 0.0) -> Vector2i:
	if _walkable_positions.is_empty():
		return Vector2i(-1, -1)
	
	var attempts: int = 50
	while attempts > 0:
		var index: int = _rng.randi_range(0, _walkable_positions.size() - 1)
		var pos: Vector2i = _walkable_positions[index]
		
		# 检查是否已被占用
		if _occupied_positions.has(pos):
			attempts -= 1
			continue
		
		# 检查边距
		if margin > 0:
			var too_close: bool = false
			for occupied_pos in _occupied_positions.keys():
				if pos.distance_to(occupied_pos) < margin:
					too_close = true
					break
			if too_close:
				attempts -= 1
				continue
		
		return pos
	
	return Vector2i(-1, -1)


## 标记区域为已占用
func _mark_area_occupied(center: Vector2i, radius: int) -> void:
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var pos: Vector2i = Vector2i(center.x + dx, center.y + dy)
			if _is_valid_position(pos):
				_occupied_positions[pos] = "area"


## 检查位置是否有效
func _is_valid_position(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < _width and pos.y >= 0 and pos.y < _height

# ==================== 获取器函数 ====================

## 获取所有生成的元素
func get_generated_elements() -> Dictionary:
	return _generated_elements


## 获取指定类型的元素
func get_elements_by_type(element_type: String) -> Array:
	return _generated_elements.get(element_type, [])


## 设置随机种子
func set_seed(new_seed: int) -> void:
	_rng.seed = new_seed


## 获取可行走位置数量
func get_walkable_count() -> int:
	return _walkable_positions.size()
