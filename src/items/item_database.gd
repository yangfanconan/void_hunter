## Void Hunter - 道具数据库
## @description: 管理所有道具数据的全局数据库
## @author: Void Hunter Team
## @version: 0.1.0

extends Resource
class_name ItemDatabase

# =============================================================================
# 常量定义
# =============================================================================

## 数据库文件路径
const DATABASE_PATH: String = "res://data/items.json"

# =============================================================================
# 公共变量
# =============================================================================

## 所有道具数据
var items: Dictionary = {}

## 按类型分组的道具
var items_by_type: Dictionary = {}

## 按稀有度分组的道具
var items_by_rarity: Dictionary = {}

# =============================================================================
# 私有变量
# =============================================================================

var _is_loaded: bool = false

# =============================================================================
# 公共方法
# =============================================================================

## 加载数据库
func load_database() -> bool:
	"""
	从文件加载道具数据库
	@return: 是否成功加载
	"""
	if _is_loaded:
		return true
	
	var file: FileAccess = FileAccess.open(DATABASE_PATH, FileAccess.READ)
	
	if file == null:
		push_warning("无法加载道具数据库: " + DATABASE_PATH)
		_load_default_items()
		return false
	
	var json_string: String = file.get_as_text()
	file.close()
	
	var json: JSON = JSON.new()
	var error: int = json.parse(json_string)
	
	if error != OK:
		push_error("道具数据库JSON解析错误")
		_load_default_items()
		return false
	
	var data: Variant = json.get_data()
	
	if not data is Dictionary:
		push_error("道具数据库格式错误")
		_load_default_items()
		return false
	
	# 解析数据
	_parse_database(data)
	_is_loaded = true
	
	return true


## 获取道具数据
func get_item(item_id: String) -> Dictionary:
	"""
	获取指定ID的道具数据
	@param item_id: 道具ID
	@return: 道具数据
	"""
	if not _is_loaded:
		load_database()
	
	return items.get(item_id, {})


## 获取所有道具
func get_all_items() -> Dictionary:
	"""
	获取所有道具数据
	@return: 道具字典
	"""
	if not _is_loaded:
		load_database()
	
	return items.duplicate()


## 获取指定类型的道具
func get_items_by_type(type: int) -> Array[Dictionary]:
	"""
	获取指定类型的所有道具
	@param type: 道具类型（ItemType枚举）
	@return: 道具数组
	"""
	if not _is_loaded:
		load_database()
	
	return items_by_type.get(type, [])


## 获取指定稀有度的道具
func get_items_by_rarity(rarity: int) -> Array[Dictionary]:
	"""
	获取指定稀有度的所有道具
	@param rarity: 稀有度（ItemRarity枚举）
	@return: 道具数组
	"""
	if not _is_loaded:
		load_database()
	
	return items_by_rarity.get(rarity, [])


## 随机获取道具
func get_random_item(rarity_weights: Dictionary = {}) -> Dictionary:
	"""
	随机获取一个道具
	@param rarity_weights: 稀有度权重字典 {rarity: weight}
	@return: 道具数据
	"""
	if not _is_loaded:
		load_database()
	
	# 默认权重
	if rarity_weights.is_empty():
		rarity_weights = {
			0: 50,  # Common
			1: 30,  # Uncommon
			2: 15,  # Rare
			3: 4,   # Epic
			4: 1    # Legendary
		}
	
	# 根据权重选择稀有度
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
	
	# 从该稀有度中随机选择
	var rarity_items: Array[Dictionary] = get_items_by_rarity(selected_rarity)
	
	if rarity_items.is_empty():
		return {}
	
	return rarity_items[randi() % rarity_items.size()]


## 创建道具实例
func create_item_instance(item_id: String) -> ItemBase:
	"""
	创建道具实例
	@param item_id: 道具ID
	@return: 道具实例
	"""
	var item_data: Dictionary = get_item(item_id)
	
	if item_data.is_empty():
		return null
	
	# 创建道具节点
	var item: ItemBase = ItemBase.new()
	
	# 设置属性
	item.item_id = item_data.get("id", "")
	item.item_name = item_data.get("name", "Unknown")
	item.description = item_data.get("description", "")
	item.item_type = item_data.get("type", ItemBase.ItemType.CONSUMABLE)
	item.rarity = item_data.get("rarity", ItemBase.ItemRarity.COMMON)
	item.max_stack = item_data.get("max_stack", 1)
	item.heal_amount = item_data.get("heal_amount", 0.0)
	item.mana_restore = item_data.get("mana_restore", 0.0)
	item.sell_price = item_data.get("sell_price", 0)
	item.buy_price = item_data.get("buy_price", 0)
	
	return item


# =============================================================================
# 私有方法
# =============================================================================

func _parse_database(data: Dictionary) -> void:
	"""
	解析数据库数据
	@param data: 原始数据
	"""
	items.clear()
	items_by_type.clear()
	items_by_rarity.clear()
	
	for item_id in data.keys():
		var item_data: Dictionary = data[item_id]
		item_data["id"] = item_id
		
		items[item_id] = item_data
		
		# 按类型分组
		var type: int = item_data.get("type", 0)
		if not items_by_type.has(type):
			items_by_type[type] = []
		items_by_type[type].append(item_data)
		
		# 按稀有度分组
		var rarity: int = item_data.get("rarity", 0)
		if not items_by_rarity.has(rarity):
			items_by_rarity[rarity] = []
		items_by_rarity[rarity].append(item_data)


func _load_default_items() -> void:
	"""
	加载默认道具数据
	"""
	var default_items: Dictionary = {
		"health_potion": {
			"name": "Health Potion",
			"description": "Restores 50 health points.",
			"type": ItemBase.ItemType.CONSUMABLE,
			"rarity": ItemBase.ItemRarity.COMMON,
			"max_stack": 10,
			"heal_amount": 50.0,
			"sell_price": 10,
			"buy_price": 25
		},
		"mana_potion": {
			"name": "Mana Potion",
			"description": "Restores 30 mana points.",
			"type": ItemBase.ItemType.CONSUMABLE,
			"rarity": ItemBase.ItemRarity.COMMON,
			"max_stack": 10,
			"mana_restore": 30.0,
			"sell_price": 10,
			"buy_price": 25
		},
		"gold_coin": {
			"name": "Gold Coin",
			"description": "Currency used for trading.",
			"type": ItemBase.ItemType.CURRENCY,
			"rarity": ItemBase.ItemRarity.COMMON,
			"max_stack": 999,
			"sell_price": 1,
			"buy_price": 1
		},
		"iron_sword": {
			"name": "Iron Sword",
			"description": "A basic sword. Increases attack by 5.",
			"type": ItemBase.ItemType.EQUIPMENT,
			"rarity": ItemBase.ItemRarity.COMMON,
			"max_stack": 1,
			"stat_bonuses": {"attack": 5.0},
			"sell_price": 50,
			"buy_price": 100
		},
		"magic_ring": {
			"name": "Magic Ring",
			"description": "Increases mana by 20%.",
			"type": ItemBase.ItemType.EQUIPMENT,
			"rarity": ItemBase.ItemRarity.RARE,
			"max_stack": 1,
			"stat_bonuses": {"mana": 0.2},
			"sell_price": 200,
			"buy_price": 500
		}
	}
	
	_parse_database(default_items)
	_is_loaded = true
