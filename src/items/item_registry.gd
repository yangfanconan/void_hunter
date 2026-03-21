## Void Hunter - 道具注册表
## @description: 统一管理所有道具的注册、创建和查询
## @author: Void Hunter Team
## @version: 0.1.0

extends Node
class_name ItemRegistry

# =============================================================================
# 信号定义
# =============================================================================

## 道具注册成功
signal item_registered(item_id: String)

## 道具创建成功
signal item_created(item_id: String, item_node: Node)

# =============================================================================
# 单例
# =============================================================================

static var _instance: ItemRegistry = null

static func get_instance() -> ItemRegistry:
	"""
	获取单例实例
	@return: ItemRegistry实例
	"""
	return _instance

# =============================================================================
# 常量定义
# =============================================================================

## 道具脚本路径映射
const ITEM_SCRIPTS: Dictionary = {
	# 武器类
	"weapon_novice_sword": "res://src/items/items/weapon_novice_sword.gd",
	"weapon_steel_sword": "res://src/items/items/weapon_steel_sword.gd",
	"weapon_shadow_dagger": "res://src/items/items/weapon_shadow_dagger.gd",
	"weapon_dragon_breath": "res://src/items/items/weapon_dragon_breath.gd",
	"weapon_void_blade": "res://src/items/items/weapon_void_blade.gd",
	
	# 防具类
	"armor_cloth": "res://src/items/items/armor_cloth.gd",
	"armor_iron": "res://src/items/items/armor_iron.gd",
	"armor_holy_light": "res://src/items/items/armor_holy_light.gd",
	"armor_shadow_cloak": "res://src/items/items/armor_shadow_cloak.gd",
	"armor_void_shield": "res://src/items/items/armor_void_shield.gd",
	
	# 饰品类
	"accessory_ring_of_power": "res://src/items/items/accessory_ring_of_power.gd",
	"accessory_necklace_of_agility": "res://src/items/items/accessory_necklace_of_agility.gd",
	"accessory_gem_of_wisdom": "res://src/items/items/accessory_gem_of_wisdom.gd",
	"accessory_lucky_charm": "res://src/items/items/accessory_lucky_charm.gd",
	"accessory_hourglass_of_time": "res://src/items/items/accessory_hourglass_of_time.gd",
	
	# 消耗品类
	"consumable_health_potion": "res://src/items/items/consumable_health_potion.gd",
	"consumable_mana_potion": "res://src/items/items/consumable_mana_potion.gd",
	"consumable_elixir": "res://src/items/items/consumable_elixir.gd",
	
	# 特殊道具
	"special_exp_gem": "res://src/items/items/special_exp_gem.gd",
	"special_revive_cross": "res://src/items/items/special_revive_cross.gd"
}

# =============================================================================
# 公共变量
# =============================================================================

## 已加载的道具脚本缓存
var _loaded_scripts: Dictionary = {}

## 道具元数据缓存
var _item_metadata: Dictionary = {}

# =============================================================================
# 生命周期
# =============================================================================

func _ready() -> void:
	_instance = self
	_preload_item_scripts()


func _exit_tree() -> void:
	if _instance == self:
		_instance = null

# =============================================================================
# 公共方法 - 道具创建
# =============================================================================

## 创建道具实例
func create_item(item_id: String, stack_count: int = 1) -> Node:
	"""
	创建道具实例
	@param item_id: 道具ID
	@param stack_count: 堆叠数量
	@return: 道具节点
	"""
	if not ITEM_SCRIPTS.has(item_id):
		push_error("未知的道具ID: " + item_id)
		return null
	
	var script_path: String = ITEM_SCRIPTS[item_id]
	var script: Script = _get_or_load_script(script_path)
	
	if script == null:
		push_error("无法加载道具脚本: " + script_path)
		return null
	
	# 创建节点
	var item_node: Node = _create_item_node_from_script(script)
	
	if item_node == null:
		return null
	
	# 设置堆叠数量
	if "current_stack" in item_node:
		item_node.current_stack = mini(stack_count, item_node.max_stack)
	
	item_created.emit(item_id, item_node)
	
	return item_node


## 创建道具数据字典
func create_item_data(item_id: String, stack_count: int = 1) -> Dictionary:
	"""
	创建道具数据字典（用于背包系统）
	@param item_id: 道具ID
	@param stack_count: 堆叠数量
	@return: 道具数据字典
	"""
	if not ITEM_SCRIPTS.has(item_id):
		return {}
	
	# 从元数据获取信息
	var metadata: Dictionary = get_item_metadata(item_id)
	
	if metadata.is_empty():
		return {}
	
	return {
		"id": item_id,
		"name": metadata.get("name", "Unknown"),
		"description": metadata.get("description", ""),
		"type": metadata.get("type", ItemBase.ItemType.KEY_ITEM),
		"rarity": metadata.get("rarity", ItemBase.ItemRarity.COMMON),
		"rarity_name": ItemBase.RARITY_NAMES.get(metadata.get("rarity", 0), "普通"),
		"rarity_color": ItemBase.RARITY_COLORS.get(metadata.get("rarity", 0), Color.WHITE),
		"stack": stack_count,
		"max_stack": metadata.get("max_stack", 1),
		"sell_price": metadata.get("sell_price", 0),
		"buy_price": metadata.get("buy_price", 0),
		"equip_slot": metadata.get("equip_slot", ItemBase.EquipSlot.NONE),
		"can_drop": metadata.get("can_drop", true),
		"stat_bonuses": metadata.get("stat_bonuses", {}),
		"icon": metadata.get("icon", null)
	}

# =============================================================================
# 公共方法 - 道具查询
# =============================================================================

## 获取所有道具ID
func get_all_item_ids() -> Array:
	"""
	获取所有已注册的道具ID
	@return: 道具ID数组
	"""
	return ITEM_SCRIPTS.keys()


## 检查道具是否存在
func has_item(item_id: String) -> bool:
	"""
	检查道具是否已注册
	@param item_id: 道具ID
	@return: 是否存在
	"""
	return ITEM_SCRIPTS.has(item_id)


## 获取道具元数据
func get_item_metadata(item_id: String) -> Dictionary:
	"""
	获取道具元数据
	@param item_id: 道具ID
	@return: 元数据字典
	"""
	if _item_metadata.has(item_id):
		return _item_metadata[item_id]
	
	# 尝试从脚本加载元数据
	var item_node: Node = create_item(item_id)
	if item_node == null:
		return {}
	
	var metadata: Dictionary = _extract_metadata_from_node(item_node)
	_item_metadata[item_id] = metadata
	
	item_node.queue_free()
	
	return metadata


## 获取指定稀有度的道具列表
func get_items_by_rarity(rarity: int) -> Array[String]:
	"""
	获取指定稀有度的所有道具ID
	@param rarity: 稀有度
	@return: 道具ID数组
	"""
	var result: Array[String] = []
	
	for item_id in ITEM_SCRIPTS:
		var metadata: Dictionary = get_item_metadata(item_id)
		if metadata.get("rarity", -1) == rarity:
			result.append(item_id)
	
	return result


## 获取指定类型的道具列表
func get_items_by_type(type: int) -> Array[String]:
	"""
	获取指定类型的所有道具ID
	@param type: 道具类型
	@return: 道具ID数组
	"""
	var result: Array[String] = []
	
	for item_id in ITEM_SCRIPTS:
		var metadata: Dictionary = get_item_metadata(item_id)
		if metadata.get("type", -1) == type:
			result.append(item_id)
	
	return result


## 获取指定装备槽的道具列表
func get_items_by_equip_slot(slot: int) -> Array[String]:
	"""
	获取指定装备槽的所有道具ID
	@param slot: 装备槽类型
	@return: 道具ID数组
	"""
	var result: Array[String] = []
	
	for item_id in ITEM_SCRIPTS:
		var metadata: Dictionary = get_item_metadata(item_id)
		if metadata.get("equip_slot", ItemBase.EquipSlot.NONE) == slot:
			result.append(item_id)
	
	return result

# =============================================================================
# 公共方法 - 统计
# =============================================================================

## 获取道具总数
func get_total_item_count() -> int:
	"""
	获取已注册的道具总数
	@return: 道具总数
	"""
	return ITEM_SCRIPTS.size()


## 获取各稀有度道具数量
func get_rarity_counts() -> Dictionary:
	"""
	获取各稀有度的道具数量
	@return: 稀有度数量字典
	"""
	var counts: Dictionary = {}
	
	for rarity in ItemBase.ItemRarity.values():
		counts[rarity] = get_items_by_rarity(rarity).size()
	
	return counts

# =============================================================================
# 私有方法
# =============================================================================

func _preload_item_scripts() -> void:
	"""预加载所有道具脚本"""
	for item_id in ITEM_SCRIPTS:
		var script_path: String = ITEM_SCRIPTS[item_id]
		_get_or_load_script(script_path)


func _get_or_load_script(script_path: String) -> Script:
	"""
	获取或加载脚本
	@param script_path: 脚本路径
	@return: 脚本对象
	"""
	if _loaded_scripts.has(script_path):
		return _loaded_scripts[script_path]
	
	var script: Script = load(script_path)
	if script != null:
		_loaded_scripts[script_path] = script
	
	return script


func _create_item_node_from_script(script: Script) -> Node:
	"""
	从脚本创建道具节点
	@param script: 脚本对象
	@return: 道具节点
	"""
	var item_node: Node = Node.new()
	item_node.set_script(script)
	
	# 调用_ready初始化
	item_node._ready()
	
	return item_node


func _extract_metadata_from_node(item_node: Node) -> Dictionary:
	"""
	从道具节点提取元数据
	@param item_node: 道具节点
	@return: 元数据字典
	"""
	var metadata: Dictionary = {}
	
	# 提取基本属性
	if "item_id" in item_node:
		metadata["id"] = item_node.item_id
	if "item_name" in item_node:
		metadata["name"] = item_node.item_name
	if "description" in item_node:
		metadata["description"] = item_node.description
	if "item_type" in item_node:
		metadata["type"] = item_node.item_type
	if "rarity" in item_node:
		metadata["rarity"] = item_node.rarity
	if "max_stack" in item_node:
		metadata["max_stack"] = item_node.max_stack
	if "sell_price" in item_node:
		metadata["sell_price"] = item_node.sell_price
	if "buy_price" in item_node:
		metadata["buy_price"] = item_node.buy_price
	if "equip_slot" in item_node:
		metadata["equip_slot"] = item_node.equip_slot
	if "can_drop" in item_node:
		metadata["can_drop"] = item_node.can_drop
	if "stat_bonuses" in item_node:
		metadata["stat_bonuses"] = item_node.stat_bonuses
	if "icon" in item_node:
		metadata["icon"] = item_node.icon
	
	return metadata
