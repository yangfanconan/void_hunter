## Void Hunter - 道具掉落系统
## @description: 管理道具掉落概率、稀有度分配和掉落生成
## @author: Void Hunter Team
## @version: 0.2.0

extends Node
class_name DropSystem

# =============================================================================
# 信号定义
# =============================================================================

## 道具掉落时触发
signal item_dropped(item: Node, position: Vector2)

## 道具被收集时触发
signal item_collected(item: Node, collector: Node)

# =============================================================================
# 常量定义
# =============================================================================

## 稀有度概率配置（基础概率）
const RARITY_WEIGHTS: Dictionary = {
	ItemBase.ItemRarity.COMMON: 55,      # 55%
	ItemBase.ItemRarity.UNCOMMON: 25,    # 25%
	ItemBase.ItemRarity.RARE: 12,        # 12%
	ItemBase.ItemRarity.EPIC: 6,         # 6%
	ItemBase.ItemRarity.LEGENDARY: 2     # 2%
}

## 精英怪稀有度加成
const ELITE_RARITY_BONUS: Dictionary = {
	ItemBase.ItemRarity.COMMON: -15,
	ItemBase.ItemRarity.UNCOMMON: 5,
	ItemBase.ItemRarity.RARE: 6,
	ItemBase.ItemRarity.EPIC: 4,
	ItemBase.ItemRarity.LEGENDARY: 1
}

## Boss稀有度加成
const BOSS_RARITY_BONUS: Dictionary = {
	ItemBase.ItemRarity.COMMON: -30,
	ItemBase.ItemRarity.UNCOMMON: -5,
	ItemBase.ItemRarity.RARE: 15,
	ItemBase.ItemRarity.EPIC: 15,
	ItemBase.ItemRarity.LEGENDARY: 10
}

## 幸运值影响系数
const LUCK_SCALE: float = 0.5

## 掉落扩散半径
const DROP_SPREAD_RADIUS: float = 50.0

## 掉落初始速度
const DROP_INITIAL_SPEED: float = 100.0

# =============================================================================
# 导出变量
# =============================================================================

## 是否启用掉落
@export var drops_enabled: bool = true

## 基础掉落率
@export_range(0.0, 1.0) var base_drop_chance: float = 0.3

## 幸运值对掉落率的影响
@export_range(0.0, 1.0) var luck_drop_modifier: float = 0.1

# =============================================================================
# 公共变量
# =============================================================================

## 当前玩家的幸运值
var player_luck: float = 0.0

## 额外掉落率加成
var bonus_drop_rate: float = 0.0

## 道具磁铁范围
var magnet_range: float = 100.0

# =============================================================================
# 私有变量
# =============================================================================

var _item_pool: Array[Dictionary] = []
var _dropped_items: Array[Node] = []

# 道具注册表
var _item_registry: Dictionary = {
	# 武器类
	"weapon_novice_sword": {"script": "res://src/items/items/weapon_novice_sword.gd", "rarity": ItemBase.ItemRarity.COMMON},
	"weapon_steel_sword": {"script": "res://src/items/items/weapon_steel_sword.gd", "rarity": ItemBase.ItemRarity.UNCOMMON},
	"weapon_shadow_dagger": {"script": "res://src/items/items/weapon_shadow_dagger.gd", "rarity": ItemBase.ItemRarity.EPIC},
	"weapon_dragon_breath": {"script": "res://src/items/items/weapon_dragon_breath.gd", "rarity": ItemBase.ItemRarity.LEGENDARY},
	"weapon_void_blade": {"script": "res://src/items/items/weapon_void_blade.gd", "rarity": ItemBase.ItemRarity.LEGENDARY},

	# 防具类
	"armor_cloth": {"script": "res://src/items/items/armor_cloth.gd", "rarity": ItemBase.ItemRarity.COMMON},
	"armor_iron": {"script": "res://src/items/items/armor_iron.gd", "rarity": ItemBase.ItemRarity.UNCOMMON},
	"armor_holy_light": {"script": "res://src/items/items/armor_holy_light.gd", "rarity": ItemBase.ItemRarity.EPIC},
	"armor_shadow_cloak": {"script": "res://src/items/items/armor_shadow_cloak.gd", "rarity": ItemBase.ItemRarity.LEGENDARY},
	"armor_void_shield": {"script": "res://src/items/items/armor_void_shield.gd", "rarity": ItemBase.ItemRarity.LEGENDARY},

	# 饰品类
	"accessory_ring_of_power": {"script": "res://src/items/items/accessory_ring_of_power.gd", "rarity": ItemBase.ItemRarity.UNCOMMON},
	"accessory_necklace_of_agility": {"script": "res://src/items/items/accessory_necklace_of_agility.gd", "rarity": ItemBase.ItemRarity.UNCOMMON},
	"accessory_gem_of_wisdom": {"script": "res://src/items/items/accessory_gem_of_wisdom.gd", "rarity": ItemBase.ItemRarity.EPIC},
	"accessory_lucky_charm": {"script": "res://src/items/items/accessory_lucky_charm.gd", "rarity": ItemBase.ItemRarity.EPIC},
	"accessory_hourglass_of_time": {"script": "res://src/items/items/accessory_hourglass_of_time.gd", "rarity": ItemBase.ItemRarity.LEGENDARY},

	# 消耗品类
	"consumable_health_potion": {"script": "res://src/items/items/consumable_health_potion.gd", "rarity": ItemBase.ItemRarity.COMMON},
	"consumable_mana_potion": {"script": "res://src/items/items/consumable_mana_potion.gd", "rarity": ItemBase.ItemRarity.COMMON},
	"consumable_elixir": {"script": "res://src/items/items/consumable_elixir.gd", "rarity": ItemBase.ItemRarity.EPIC},

	# 特殊道具
	"special_exp_gem": {"script": "res://src/items/items/special_exp_gem.gd", "rarity": ItemBase.ItemRarity.UNCOMMON},
	"special_revive_cross": {"script": "res://src/items/items/special_revive_cross.gd", "rarity": ItemBase.ItemRarity.LEGENDARY}
}

# =============================================================================
# 生命周期
# =============================================================================

func _ready() -> void:
	_initialize_drop_system()


func _initialize_drop_system() -> void:
	"""初始化掉落系统"""
	_build_item_pool()


# =============================================================================
# 公共方法 - 掉落生成
# =============================================================================

## 生成掉落
func spawn_drop(drop_position: Vector2, enemy_type: String = "normal", is_elite: bool = false, is_boss: bool = false) -> Array[Node]:
	"""
	在指定位置生成道具掉落
	@param drop_position: 掉落位置
	@param enemy_type: 敌人类型
	@param is_elite: 是否精英怪
	@param is_boss: 是否Boss
	@return: 生成的道具节点数组
	"""
	if not drops_enabled:
		return []

	var dropped_items: Array[Node] = []

	# 计算实际掉落率
	var actual_drop_chance: float = _calculate_drop_chance(is_elite, is_boss)

	# 检查是否触发掉落
	if randf() > actual_drop_chance:
		return []

	# 确定掉落数量
	var drop_count: int = _calculate_drop_count(is_elite, is_boss)

	for i in range(drop_count):
		# 选择要掉落的道具
		var item_data: Dictionary = _select_item_to_drop(is_elite, is_boss)

		if item_data.is_empty():
			continue

		# 计算掉落位置（带扩散）
		var spread_offset: Vector2 = Vector2.ZERO
		if drop_count > 1:
			spread_offset = Vector2(
				randf_range(-DROP_SPREAD_RADIUS, DROP_SPREAD_RADIUS),
				randf_range(-DROP_SPREAD_RADIUS, DROP_SPREAD_RADIUS)
			)

		var final_position: Vector2 = drop_position + spread_offset

		# 生成道具
		var item_node: Node = _create_item_node(item_data, final_position)

		if item_node != null:
			dropped_items.append(item_node)
			_dropped_items.append(item_node)
			item_dropped.emit(item_node, final_position)

	return dropped_items


## 生成指定道具
func spawn_specific_item(item_id: String, position: Vector2, count: int = 1) -> Node:
	"""
	生成指定的道具
	@param item_id: 道具ID
	@param position: 生成位置
	@param count: 数量
	@return: 生成的道具节点
	"""
	if not _item_registry.has(item_id):
		push_warning("未知的道具ID: " + item_id)
		return null

	var item_data: Dictionary = _item_registry[item_id]
	var item_node: Node = _create_item_node(item_data, position)

	if item_node != null and count > 1:
		if "current_stack" in item_node:
			item_node.current_stack = mini(count, item_node.max_stack)

	if item_node != null:
		_dropped_items.append(item_node)
		item_dropped.emit(item_node, position)

	return item_node


## 清除所有掉落
func clear_all_drops() -> void:
	"""清除场景中所有掉落的道具"""
	for item in _dropped_items:
		if is_instance_valid(item):
			item.queue_free()

	_dropped_items.clear()


## 从掉落列表中移除已拾取的道具
func remove_dropped_item(item: Node) -> void:
	"""从追踪列表中移除已拾取的道具"""
	_dropped_items.erase(item)


# =============================================================================
# 公共方法 - 掉落率控制
# =============================================================================

## 设置玩家幸运值
func set_player_luck(luck: float) -> void:
	"""设置玩家幸运值"""
	player_luck = maxf(0.0, luck)


## 增加掉落率
func add_drop_rate_bonus(bonus: float) -> void:
	"""增加额外掉落率"""
	bonus_drop_rate += bonus


## 移除掉落率加成
func remove_drop_rate_bonus(bonus: float) -> void:
	"""移除额外掉落率"""
	bonus_drop_rate = maxf(0.0, bonus_drop_rate - bonus)


## 设置磁铁范围
func set_magnet_range(range: float) -> void:
	"""设置道具磁铁范围"""
	magnet_range = range


## 获取当前总掉落率
func get_total_drop_rate() -> float:
	"""获取当前总掉落率"""
	return clampf(base_drop_chance + bonus_drop_rate + player_luck * luck_drop_modifier, 0.0, 1.0)


# =============================================================================
# 私有方法
# =============================================================================

func _build_item_pool() -> void:
	"""构建道具池"""
	_item_pool.clear()

	for item_id in _item_registry:
		var item_data: Dictionary = _item_registry[item_id]
		_item_pool.append({
			"id": item_id,
			"script": item_data.script,
			"rarity": item_data.rarity
		})


func _calculate_drop_chance(is_elite: bool, is_boss: bool) -> float:
	"""计算实际掉落率"""
	var chance: float = base_drop_chance

	# 应用额外掉落率
	chance += bonus_drop_rate

	# 应用幸运值影响
	chance += player_luck * luck_drop_modifier

	# 精英怪加成
	if is_elite:
		chance += 0.2

	# Boss加成
	if is_boss:
		chance += 0.5

	return clampf(chance, 0.0, 1.0)


func _calculate_drop_count(is_elite: bool, is_boss: bool) -> int:
	"""计算掉落数量"""
	var count: int = 1

	if is_elite:
		count += randi_range(0, 1)  # 1-2个

	if is_boss:
		count += randi_range(2, 4)  # 3-5个

	return count


func _select_item_to_drop(is_elite: bool, is_boss: bool) -> Dictionary:
	"""选择要掉落的道具"""
	# 确定稀有度
	var rarity: int = _roll_rarity(is_elite, is_boss)

	# 从该稀有度中随机选择一个道具
	var eligible_items: Array[Dictionary] = []

	for item_data in _item_pool:
		if item_data.rarity == rarity:
			eligible_items.append(item_data)

	# 如果该稀有度没有道具，降级到低一级稀有度
	if eligible_items.is_empty():
		var fallback_rarity: int = _get_fallback_rarity(rarity)
		for item_data in _item_pool:
			if item_data.rarity == fallback_rarity:
				eligible_items.append(item_data)

	if eligible_items.is_empty():
		return {}

	return eligible_items.pick_random()


## 获取降级后的稀有度（当目标稀有度没有道具时使用）
func _get_fallback_rarity(rarity: int) -> int:
	"""获取降级稀有度"""
	match rarity:
		ItemBase.ItemRarity.LEGENDARY:
			return ItemBase.ItemRarity.EPIC
		ItemBase.ItemRarity.EPIC:
			return ItemBase.ItemRarity.RARE
		ItemBase.ItemRarity.RARE:
			return ItemBase.ItemRarity.UNCOMMON
		ItemBase.ItemRarity.UNCOMMON:
			return ItemBase.ItemRarity.COMMON
		_:
			return ItemBase.ItemRarity.COMMON


func _roll_rarity(is_elite: bool, is_boss: bool) -> int:
	"""掷骰确定稀有度"""
	# 计算调整后的权重
	var adjusted_weights: Dictionary = RARITY_WEIGHTS.duplicate()

	# 应用精英加成
	if is_elite:
		for rarity in ELITE_RARITY_BONUS:
			adjusted_weights[rarity] = maxi(0, adjusted_weights.get(rarity, 0) + ELITE_RARITY_BONUS[rarity])

	# 应用Boss加成
	if is_boss:
		for rarity in BOSS_RARITY_BONUS:
			adjusted_weights[rarity] = maxi(0, adjusted_weights.get(rarity, 0) + BOSS_RARITY_BONUS[rarity])

	# 应用幸运值影响（提高高稀有度概率）
	if player_luck > 0:
		var luck_bonus: float = player_luck * LUCK_SCALE
		adjusted_weights[ItemBase.ItemRarity.RARE] += luck_bonus * 0.5
		adjusted_weights[ItemBase.ItemRarity.EPIC] += luck_bonus
		adjusted_weights[ItemBase.ItemRarity.LEGENDARY] += luck_bonus * 0.5

	# 计算总权重
	var total_weight: float = 0.0
	for weight in adjusted_weights.values():
		total_weight += weight

	# 掷骰
	var roll: float = randf() * total_weight
	var cumulative: float = 0.0

	# 按稀有度从高到低检查
	var rarities: Array = [
		ItemBase.ItemRarity.LEGENDARY,
		ItemBase.ItemRarity.EPIC,
		ItemBase.ItemRarity.RARE,
		ItemBase.ItemRarity.UNCOMMON,
		ItemBase.ItemRarity.COMMON
	]

	for rarity in rarities:
		cumulative += adjusted_weights.get(rarity, 0)
		if roll < cumulative:
			return rarity

	return ItemBase.ItemRarity.COMMON


func _create_item_node(item_data: Dictionary, position: Vector2) -> Node:
	"""创建道具节点"""
	var script_path: String = item_data.get("script", "")

	if script_path.is_empty():
		return null

	# 加载脚本
	var script: Script = load(script_path)
	if script == null:
		push_warning("无法加载道具脚本: " + script_path)
		return null

	# 创建节点
	var item_node: Area2D = Area2D.new()
	item_node.set_script(script)

	# 添加碰撞形状
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 16.0
	collision.shape = shape
	item_node.add_child(collision)

	# 添加占位精灵（带稀有度颜色）
	var sprite: Sprite2D = Sprite2D.new()
	sprite.modulate = ItemBase.RARITY_COLORS.get(item_data.rarity, Color.WHITE)
	item_node.add_child(sprite)

	# 设置位置
	item_node.global_position = position

	# 添加到场景树
	get_tree().current_scene.add_child(item_node)

	# 应用初始速度（弹出效果）
	_apply_drop_velocity(item_node)

	return item_node


func _apply_drop_velocity(item_node: Node) -> void:
	"""应用掉落初始速度"""
	# 随机方向弹出
	var angle: float = randf() * TAU
	var velocity: Vector2 = Vector2(cos(angle), sin(angle)) * DROP_INITIAL_SPEED

	# 使用Tween实现弹出效果
	var tween: Tween = item_node.create_tween()
	var start_pos: Vector2 = item_node.global_position
	var end_pos: Vector2 = start_pos + velocity * 0.3

	tween.tween_property(item_node, "global_position", end_pos, 0.2).set_ease(Tween.EASE_OUT)
	tween.tween_property(item_node, "global_position", start_pos, 0.1).set_ease(Tween.EASE_IN)


# =============================================================================
# 工具方法
# =============================================================================

## 获取道具信息
func get_item_info_by_id(item_id: String) -> Dictionary:
	"""通过ID获取道具信息"""
	return _item_registry.get(item_id, {})


## 获取所有道具ID
func get_all_item_ids() -> Array:
	"""获取所有道具ID"""
	return _item_registry.keys()


## 获取指定稀有度的道具列表
func get_items_by_rarity(rarity: int) -> Array[Dictionary]:
	"""获取指定稀有度的所有道具"""
	var result: Array[Dictionary] = []

	for item_id in _item_registry:
		var item_data: Dictionary = _item_registry[item_id]
		if item_data.rarity == rarity:
			result.append({
				"id": item_id,
				"data": item_data
			})

	return result


## 获取掉落统计信息
func get_drop_stats() -> Dictionary:
	"""获取掉落系统统计信息"""
	return {
		"total_dropped": _dropped_items.size(),
		"drop_rate": get_total_drop_rate(),
		"player_luck": player_luck,
		"bonus_drop_rate": bonus_drop_rate,
		"pool_size": _item_pool.size()
	}
