## Void Hunter - 道具数据库
## @description: 管理所有道具数据的全局数据库
## @author: Void Hunter Team
## @version: 0.2.0

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
	"""从文件加载道具数据库"""
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
	"""获取指定ID的道具数据"""
	if not _is_loaded:
		load_database()

	return items.get(item_id, {})


## 获取所有道具
func get_all_items() -> Dictionary:
	"""获取所有道具数据"""
	if not _is_loaded:
		load_database()

	return items.duplicate()


## 获取指定类型的道具
func get_items_by_type(type: int) -> Array[Dictionary]:
	"""获取指定类型的所有道具"""
	if not _is_loaded:
		load_database()

	var result: Array[Dictionary] = []
	var type_items: Variant = items_by_type.get(type, [])
	if type_items is Array:
		for item in type_items:
			if item is Dictionary:
				result.append(item)
	return result


## 获取指定稀有度的道具
func get_items_by_rarity(rarity: int) -> Array[Dictionary]:
	"""获取指定稀有度的所有道具"""
	if not _is_loaded:
		load_database()

	var result: Array[Dictionary] = []
	var rarity_items: Variant = items_by_rarity.get(rarity, [])
	if rarity_items is Array:
		for item in rarity_items:
			if item is Dictionary:
				result.append(item)
	return result


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
			ItemBase.ItemRarity.COMMON: 50,
			ItemBase.ItemRarity.UNCOMMON: 25,
			ItemBase.ItemRarity.RARE: 15,
			ItemBase.ItemRarity.EPIC: 8,
			ItemBase.ItemRarity.LEGENDARY: 2
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
		# 降级到普通
		rarity_items = get_items_by_rarity(ItemBase.ItemRarity.COMMON)

	if rarity_items.is_empty():
		return {}

	return rarity_items[randi() % rarity_items.size()]


## 创建道具实例
func create_item_instance(item_id: String) -> ItemBase:
	"""创建道具实例"""
	var item_data: Dictionary = get_item(item_id)

	if item_data.is_empty():
		return null

	# 获取脚本路径
	var script_path: String = _get_script_path_for_item(item_id)
	if script_path.is_empty():
		return null

	var script: Script = load(script_path)
	if script == null:
		return null

	# 创建节点
	var item_node: Area2D = Area2D.new()
	item_node.set_script(script)

	# 设置属性
	item_node.item_id = item_id
	item_node.item_name = item_data.get("name", "Unknown")
	item_node.description = item_data.get("description", "")
	item_node.rarity = item_data.get("rarity", ItemBase.ItemRarity.COMMON)
	item_node.max_stack = item_data.get("max_stack", 1)
	item_node.heal_amount = item_data.get("heal_amount", 0.0)
	item_node.mana_restore = item_data.get("mana_restore", 0.0)
	item_node.sell_price = item_data.get("sell_price", 0)
	item_node.buy_price = item_data.get("buy_price", 0)

	var bonuses: Variant = item_data.get("stat_bonuses", {})
	if bonuses is Dictionary:
		item_node.stat_bonuses = bonuses

	return item_node


## 获取道具脚本路径
func _get_script_path_for_item(item_id: String) -> String:
	"""根据道具ID获取对应的脚本路径"""
	var script_map: Dictionary = {
		"weapon_novice_sword": "res://src/items/items/weapon_novice_sword.gd",
		"weapon_steel_sword": "res://src/items/items/weapon_steel_sword.gd",
		"weapon_shadow_dagger": "res://src/items/items/weapon_shadow_dagger.gd",
		"weapon_dragon_breath": "res://src/items/items/weapon_dragon_breath.gd",
		"weapon_void_blade": "res://src/items/items/weapon_void_blade.gd",
		"armor_cloth": "res://src/items/items/armor_cloth.gd",
		"armor_iron": "res://src/items/items/armor_iron.gd",
		"armor_holy_light": "res://src/items/items/armor_holy_light.gd",
		"armor_shadow_cloak": "res://src/items/items/armor_shadow_cloak.gd",
		"armor_void_shield": "res://src/items/items/armor_void_shield.gd",
		"accessory_ring_of_power": "res://src/items/items/accessory_ring_of_power.gd",
		"accessory_necklace_of_agility": "res://src/items/items/accessory_necklace_of_agility.gd",
		"accessory_gem_of_wisdom": "res://src/items/items/accessory_gem_of_wisdom.gd",
		"accessory_lucky_charm": "res://src/items/items/accessory_lucky_charm.gd",
		"accessory_hourglass_of_time": "res://src/items/items/accessory_hourglass_of_time.gd",
		"consumable_health_potion": "res://src/items/items/consumable_health_potion.gd",
		"consumable_mana_potion": "res://src/items/items/consumable_mana_potion.gd",
		"consumable_elixir": "res://src/items/items/consumable_elixir.gd",
		"special_exp_gem": "res://src/items/items/special_exp_gem.gd",
		"special_revive_cross": "res://src/items/items/special_revive_cross.gd",
	}
	return script_map.get(item_id, "")


# =============================================================================
# 私有方法
# =============================================================================

func _parse_database(data: Dictionary) -> void:
	"""解析数据库数据"""
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
	"""加载默认道具数据（包含所有类型和稀有度）"""
	var default_items: Dictionary = {
		# === 武器类 ===
		"weapon_novice_sword": {
			"name": "新手短剑",
			"description": "一把简单的短剑，适合初学者使用。\n攻击力 +5",
			"type": ItemBase.ItemType.EQUIPMENT,
			"rarity": ItemBase.ItemRarity.COMMON,
			"equip_slot": ItemBase.EquipSlot.WEAPON,
			"max_stack": 1,
			"stat_bonuses": {"attack": 5},
			"sell_price": 10,
			"buy_price": 30
		},
		"weapon_steel_sword": {
			"name": "精钢长剑",
			"description": "由精钢锻造的长剑，锋利无比。\n攻击力 +15\n暴击率 +5%",
			"type": ItemBase.ItemType.EQUIPMENT,
			"rarity": ItemBase.ItemRarity.UNCOMMON,
			"equip_slot": ItemBase.EquipSlot.WEAPON,
			"max_stack": 1,
			"stat_bonuses": {"attack": 15, "critical_chance": 0.05},
			"sell_price": 50,
			"buy_price": 150
		},
		"weapon_shadow_dagger": {
			"name": "暗影匕首",
			"description": "蕴含暗影之力的匕首，攻击时带有黑暗气息。\n攻击力 +25\n暴击伤害 +30%",
			"type": ItemBase.ItemType.EQUIPMENT,
			"rarity": ItemBase.ItemRarity.EPIC,
			"equip_slot": ItemBase.EquipSlot.WEAPON,
			"max_stack": 1,
			"stat_bonuses": {"attack": 25, "critical_damage": 0.30},
			"sell_price": 200,
			"buy_price": 600
		},
		"weapon_dragon_breath": {
			"name": "龙息巨剑",
			"description": "传说中由龙鳞锻造的巨剑，挥舞时喷射火焰。\n攻击力 +50\n攻击附带火焰伤害（额外20%）",
			"type": ItemBase.ItemType.EQUIPMENT,
			"rarity": ItemBase.ItemRarity.LEGENDARY,
			"equip_slot": ItemBase.EquipSlot.WEAPON,
			"max_stack": 1,
			"stat_bonuses": {"attack": 50, "fire_damage_percent": 0.20},
			"sell_price": 1000,
			"buy_price": 3000
		},
		"weapon_void_blade": {
			"name": "虚空之刃",
			"description": "由虚空能量凝聚而成的利刃，可以穿透一切防御。\n攻击力 +40\n攻击穿透敌人（无视50%防御）",
			"type": ItemBase.ItemType.EQUIPMENT,
			"rarity": ItemBase.ItemRarity.LEGENDARY,
			"equip_slot": ItemBase.EquipSlot.WEAPON,
			"max_stack": 1,
			"stat_bonuses": {"attack": 40, "armor_penetration": 0.50},
			"sell_price": 1200,
			"buy_price": 3500
		},

		# === 防具类 ===
		"armor_cloth": {
			"name": "布甲",
			"description": "简单的布制护甲，提供基础防护。\n防御力 +3",
			"type": ItemBase.ItemType.EQUIPMENT,
			"rarity": ItemBase.ItemRarity.COMMON,
			"equip_slot": ItemBase.EquipSlot.ARMOR,
			"max_stack": 1,
			"stat_bonuses": {"defense": 3},
			"sell_price": 8,
			"buy_price": 25
		},
		"armor_iron": {
			"name": "铁甲",
			"description": "由铁板锻造的护甲，坚固耐用。\n防御力 +10\n最大生命值 +20",
			"type": ItemBase.ItemType.EQUIPMENT,
			"rarity": ItemBase.ItemRarity.UNCOMMON,
			"equip_slot": ItemBase.EquipSlot.ARMOR,
			"max_stack": 1,
			"stat_bonuses": {"defense": 10, "health": 20},
			"sell_price": 60,
			"buy_price": 180
		},
		"armor_holy_light": {
			"name": "圣光铠甲",
			"description": "蕴含圣洁之力的铠甲，受到伤害时恢复少量生命。\n防御力 +20\n受伤恢复（回复伤害的10%）",
			"type": ItemBase.ItemType.EQUIPMENT,
			"rarity": ItemBase.ItemRarity.EPIC,
			"equip_slot": ItemBase.EquipSlot.ARMOR,
			"max_stack": 1,
			"stat_bonuses": {"defense": 20, "heal_on_damage": 0.10},
			"sell_price": 250,
			"buy_price": 750
		},
		"armor_shadow_cloak": {
			"name": "暗影披风",
			"description": "由暗影编织的披风，穿戴者如幽灵般难以捕捉。\n防御力 +15\n闪避率 +20%",
			"type": ItemBase.ItemType.EQUIPMENT,
			"rarity": ItemBase.ItemRarity.LEGENDARY,
			"equip_slot": ItemBase.EquipSlot.ARMOR,
			"max_stack": 1,
			"stat_bonuses": {"defense": 15, "dodge_chance": 0.20},
			"sell_price": 800,
			"buy_price": 2400
		},
		"armor_void_shield": {
			"name": "虚空护盾",
			"description": "由虚空能量构成的护盾，定期自动恢复。\n防御力 +30\n每10秒生成护盾（吸收20点伤害）",
			"type": ItemBase.ItemType.EQUIPMENT,
			"rarity": ItemBase.ItemRarity.LEGENDARY,
			"equip_slot": ItemBase.EquipSlot.ARMOR,
			"max_stack": 1,
			"stat_bonuses": {"defense": 30, "auto_shield": 20},
			"sell_price": 1500,
			"buy_price": 4500
		},

		# === 饰品类 ===
		"accessory_ring_of_power": {
			"name": "力量戒指",
			"description": "蕴含力量的神秘戒指，提升攻击能力。\n攻击力 +10%",
			"type": ItemBase.ItemType.EQUIPMENT,
			"rarity": ItemBase.ItemRarity.UNCOMMON,
			"equip_slot": ItemBase.EquipSlot.ACCESSORY,
			"max_stack": 1,
			"stat_bonuses": {"attack_percent": 0.10},
			"sell_price": 80,
			"buy_price": 240
		},
		"accessory_necklace_of_agility": {
			"name": "敏捷项链",
			"description": "轻巧的项链，让穿戴者身手矫健。\n移动速度 +15%",
			"type": ItemBase.ItemType.EQUIPMENT,
			"rarity": ItemBase.ItemRarity.UNCOMMON,
			"equip_slot": ItemBase.EquipSlot.ACCESSORY,
			"max_stack": 1,
			"stat_bonuses": {"speed_percent": 0.15},
			"sell_price": 80,
			"buy_price": 240
		},
		"accessory_gem_of_wisdom": {
			"name": "智慧宝石",
			"description": "蕴含古老智慧的宝石，增强魔力。\n最大法力值 +50%\n法力恢复 +2/秒",
			"type": ItemBase.ItemType.EQUIPMENT,
			"rarity": ItemBase.ItemRarity.EPIC,
			"equip_slot": ItemBase.EquipSlot.ACCESSORY,
			"max_stack": 1,
			"stat_bonuses": {"mana_percent": 0.50, "mana_regen": 2.0},
			"sell_price": 300,
			"buy_price": 900
		},
		"accessory_lucky_charm": {
			"name": "幸运护符",
			"description": "带来好运的护符，增加暴击和掉落概率。\n暴击率 +10%\n道具掉落率 +20%",
			"type": ItemBase.ItemType.EQUIPMENT,
			"rarity": ItemBase.ItemRarity.EPIC,
			"equip_slot": ItemBase.EquipSlot.ACCESSORY,
			"max_stack": 1,
			"stat_bonuses": {"critical_chance": 0.10, "drop_rate": 0.20},
			"sell_price": 350,
			"buy_price": 1000
		},
		"accessory_hourglass_of_time": {
			"name": "时间沙漏",
			"description": "操控时间流动的神秘沙漏。\n技能冷却时间 -20%\n技能持续时间 +30%",
			"type": ItemBase.ItemType.EQUIPMENT,
			"rarity": ItemBase.ItemRarity.LEGENDARY,
			"equip_slot": ItemBase.EquipSlot.ACCESSORY,
			"max_stack": 1,
			"stat_bonuses": {"cooldown_reduction": 0.20, "duration_bonus": 0.30},
			"sell_price": 1000,
			"buy_price": 3000
		},

		# === 消耗品类 ===
		"consumable_health_potion": {
			"name": "生命药水",
			"description": "红色的药水，散发着生命气息。\n恢复30%最大生命值",
			"type": ItemBase.ItemType.CONSUMABLE,
			"rarity": ItemBase.ItemRarity.COMMON,
			"max_stack": 99,
			"heal_amount": 0,
			"sell_price": 15,
			"buy_price": 50
		},
		"consumable_mana_potion": {
			"name": "法力药水",
			"description": "蓝色的药水，蕴含魔力。\n恢复50%最大法力值",
			"type": ItemBase.ItemType.CONSUMABLE,
			"rarity": ItemBase.ItemRarity.COMMON,
			"max_stack": 99,
			"mana_restore": 0,
			"sell_price": 20,
			"buy_price": 60
		},
		"consumable_elixir": {
			"name": "全能药剂",
			"description": "金色的神秘药剂，蕴含强大力量。\n恢复全部生命值和法力值\n攻击力+20%（持续60秒）",
			"type": ItemBase.ItemType.CONSUMABLE,
			"rarity": ItemBase.ItemRarity.EPIC,
			"max_stack": 20,
			"stat_bonuses": {"full_restore": true, "attack_buff": 0.20},
			"sell_price": 200,
			"buy_price": 600
		},

		# === 特殊道具 ===
		"special_exp_gem": {
			"name": "经验宝石",
			"description": "蕴含纯净经验能量的宝石。\n使用后获得100点经验值",
			"type": ItemBase.ItemType.CONSUMABLE,
			"rarity": ItemBase.ItemRarity.UNCOMMON,
			"max_stack": 99,
			"stat_bonuses": {"exp_amount": 100},
			"sell_price": 50,
			"buy_price": 150
		},
		"special_revive_cross": {
			"name": "复活十字",
			"description": "神圣的十字架，在死亡时自动复活一次。\n死亡时恢复50%生命值复活",
			"type": ItemBase.ItemType.KEY_ITEM,
			"rarity": ItemBase.ItemRarity.LEGENDARY,
			"equip_slot": ItemBase.EquipSlot.ACCESSORY,
			"max_stack": 1,
			"stat_bonuses": {"revive_health_percent": 0.50},
			"sell_price": 2000,
			"buy_price": 6000
		}
	}

	_parse_database(default_items)
	_is_loaded = true
