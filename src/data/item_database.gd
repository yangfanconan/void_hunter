## Void Hunter - 道具数据库
## @description: 管理所有道具数据的全局数据库，包含55+种道具
## @author: Void Hunter Team
## @version: 1.0.0

extends Resource
class_name ItemDatabase

# =============================================================================
# 枚举定义
# =============================================================================

## 道具类型
enum ItemType {
	CONSUMABLE,		## 消耗品
	WEAPON,			## 武器
	ARMOR,			## 防具
	ACCESSORY,		## 饰品
	MATERIAL,		## 材料
	KEY_ITEM,		## 关键道具
	CURRENCY		## 货币
}

## 道具稀有度
enum ItemRarity {
	COMMON,			## 普通
	UNCOMMON,		## 稀有
	RARE,			## 精良
	EPIC,			## 史诗
	LEGENDARY		## 传说
}

## 装备槽位
enum EquipSlot {
	NONE,			## 不可装备
	WEAPON,			## 武器槽
	ARMOR,			## 防具槽
	ACCESSORY		## 饰品槽
}

# =============================================================================
# 公共变量
# =============================================================================

## 所有道具数据
var items: Dictionary = {}

## 按类型分组的道具
var items_by_type: Dictionary = {}

## 按稀有度分组的道具
var items_by_rarity: Dictionary = {}

## 是否已加载
var _is_loaded: bool = false

# =============================================================================
# 公共方法
# =============================================================================

## 加载数据库
func load_database() -> bool:
	if _is_loaded:
		return true
	
	_load_default_items()
	_is_loaded = true
	return true


## 获取道具数据
func get_item(item_id: String) -> Dictionary:
	if not _is_loaded:
		load_database()
	return items.get(item_id, {})


## 获取所有道具
func get_all_items() -> Dictionary:
	if not _is_loaded:
		load_database()
	return items.duplicate()


## 获取指定类型的道具
func get_items_by_type(type: int) -> Array[Dictionary]:
	if not _is_loaded:
		load_database()
	return items_by_type.get(type, [])


## 获取指定稀有度的道具
func get_items_by_rarity(rarity: int) -> Array[Dictionary]:
	if not _is_loaded:
		load_database()
	return items_by_rarity.get(rarity, [])


## 随机获取道具
func get_random_item(rarity_weights: Dictionary = {}) -> Dictionary:
	if not _is_loaded:
		load_database()
	
	if rarity_weights.is_empty():
		rarity_weights = {
			ItemRarity.COMMON: 50,
			ItemRarity.UNCOMMON: 30,
			ItemRarity.RARE: 15,
			ItemRarity.EPIC: 4,
			ItemRarity.LEGENDARY: 1
		}
	
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
	
	var rarity_items: Array[Dictionary] = get_items_by_rarity(selected_rarity)
	if rarity_items.is_empty():
		return {}
	
	return rarity_items[randi() % rarity_items.size()]


## 获取随机掉落
func get_random_drop(drop_type: String = "", min_rarity: int = 0) -> Dictionary:
	if not _is_loaded:
		load_database()
	
	var candidates: Array[Dictionary] = []
	for item_id in items.keys():
		var item_data: Dictionary = items[item_id]
		if item_data.get("rarity", 0) >= min_rarity:
			if drop_type.is_empty() or item_data.get("drop_type", "") == drop_type:
				candidates.append(item_data)
	
	if candidates.is_empty():
		return {}
	
	return candidates[randi() % candidates.size()]


# =============================================================================
# 私有方法 - 数据加载
# =============================================================================

func _load_default_items() -> void:
	items.clear()
	items_by_type.clear()
	items_by_rarity.clear()
	
	# 武器类 (15种)
	_register_weapon_items()
	
	# 防具类 (10种)
	_register_armor_items()
	
	# 饰品类 (15种)
	_register_accessory_items()
	
	# 消耗品类 (15种)
	_register_consumable_items()
	
	# 按类型和稀有度分组
	for item_id in items.keys():
		var item_data: Dictionary = items[item_id]
		
		var type: int = item_data.get("type", 0)
		if not items_by_type.has(type):
			items_by_type[type] = []
		items_by_type[type].append(item_data)
		
		var rarity: int = item_data.get("rarity", 0)
		if not items_by_rarity.has(rarity):
			items_by_rarity[rarity] = []
		items_by_rarity[rarity].append(item_data)


# =============================================================================
# 武器类道具 (15种)
# =============================================================================

func _register_weapon_items() -> void:
	items["wood_sword"] = {
		"id": "wood_sword",
		"name": "木剑",
		"description": "普通的木制剑，攻击力+5",
		"type": ItemType.WEAPON,
		"rarity": ItemRarity.COMMON,
		"equip_slot": EquipSlot.WEAPON,
		"stats": {"attack": 5},
		"sell_price": 5,
		"buy_price": 15,
		"max_stack": 1,
		"icon": "res://assets/items/weapons/wood_sword.png"
	}
	
	items["iron_sword"] = {
		"id": "iron_sword",
		"name": "铁剑",
		"description": "坚固的铁制剑，攻击力+10",
		"type": ItemType.WEAPON,
		"rarity": ItemRarity.COMMON,
		"equip_slot": EquipSlot.WEAPON,
		"stats": {"attack": 10},
		"sell_price": 15,
		"buy_price": 40,
		"max_stack": 1,
		"icon": "res://assets/items/weapons/iron_sword.png"
	}
	
	items["steel_sword"] = {
		"id": "steel_sword",
		"name": "钢剑",
		"description": "精钢打造的剑，攻击力+15",
		"type": ItemType.WEAPON,
		"rarity": ItemRarity.UNCOMMON,
		"equip_slot": EquipSlot.WEAPON,
		"stats": {"attack": 15},
		"sell_price": 30,
		"buy_price": 80,
		"max_stack": 1,
		"icon": "res://assets/items/weapons/steel_sword.png"
	}
	
	items["flame_blade"] = {
		"id": "flame_blade",
		"name": "火焰刃",
		"description": "燃烧着火焰的剑，攻击力+12，附带燃烧效果",
		"type": ItemType.WEAPON,
		"rarity": ItemRarity.RARE,
		"equip_slot": EquipSlot.WEAPON,
		"stats": {"attack": 12},
		"effects": {"burn": {"damage": 3.0, "duration": 3.0}},
		"sell_price": 80,
		"buy_price": 200,
		"max_stack": 1,
		"icon": "res://assets/items/weapons/flame_blade.png"
	}
	
	items["frost_blade"] = {
		"id": "frost_blade",
		"name": "冰霜刃",
		"description": "寒冰凝聚的剑，攻击力+12，附带减速效果",
		"type": ItemType.WEAPON,
		"rarity": ItemRarity.RARE,
		"equip_slot": EquipSlot.WEAPON,
		"stats": {"attack": 12},
		"effects": {"slow": {"amount": 0.3, "duration": 2.0}},
		"sell_price": 80,
		"buy_price": 200,
		"max_stack": 1,
		"icon": "res://assets/items/weapons/frost_blade.png"
	}
	
	items["thunder_blade"] = {
		"id": "thunder_blade",
		"name": "雷霆刃",
		"description": "蕴含雷电之力的剑，攻击力+12，攻击可连锁",
		"type": ItemType.WEAPON,
		"rarity": ItemRarity.RARE,
		"equip_slot": EquipSlot.WEAPON,
		"stats": {"attack": 12},
		"effects": {"chain": {"count": 2, "range": 100.0}},
		"sell_price": 80,
		"buy_price": 200,
		"max_stack": 1,
		"icon": "res://assets/items/weapons/thunder_blade.png"
	}
	
	items["shadow_dagger"] = {
		"id": "shadow_dagger",
		"name": "暗影匕首",
		"description": "暗影制成的匕首，攻击力+8，攻击可穿透",
		"type": ItemType.WEAPON,
		"rarity": ItemRarity.RARE,
		"equip_slot": EquipSlot.WEAPON,
		"stats": {"attack": 8, "attack_speed": 0.15},
		"effects": {"pierce": {"count": 1}},
		"sell_price": 70,
		"buy_price": 180,
		"max_stack": 1,
		"icon": "res://assets/items/weapons/shadow_dagger.png"
	}
	
	items["holy_sword"] = {
		"id": "holy_sword",
		"name": "神圣剑",
		"description": "神圣祝福的剑，攻击力+20，对亡灵额外伤害50%",
		"type": ItemType.WEAPON,
		"rarity": ItemRarity.EPIC,
		"equip_slot": EquipSlot.WEAPON,
		"stats": {"attack": 20},
		"effects": {"undead_bonus": {"percent": 0.5}},
		"sell_price": 200,
		"buy_price": 500,
		"max_stack": 1,
		"icon": "res://assets/items/weapons/holy_sword.png"
	}
	
	items["void_sword"] = {
		"id": "void_sword",
		"name": "虚空剑",
		"description": "虚空之力凝聚的剑，攻击力+18，无视敌人防御",
		"type": ItemType.WEAPON,
		"rarity": ItemRarity.EPIC,
		"equip_slot": EquipSlot.WEAPON,
		"stats": {"attack": 18},
		"effects": {"ignore_defense": true},
		"sell_price": 250,
		"buy_price": 600,
		"max_stack": 1,
		"icon": "res://assets/items/weapons/void_sword.png"
	}
	
	items["legendary_blade"] = {
		"id": "legendary_blade",
		"name": "传说之剑",
		"description": "传说中的神剑，攻击力+30，暴击率+10%",
		"type": ItemType.WEAPON,
		"rarity": ItemRarity.LEGENDARY,
		"equip_slot": EquipSlot.WEAPON,
		"stats": {"attack": 30, "crit_chance": 0.1},
		"sell_price": 500,
		"buy_price": 1500,
		"max_stack": 1,
		"icon": "res://assets/items/weapons/legendary_blade.png"
	}
	
	items["wooden_bow"] = {
		"id": "wooden_bow",
		"name": "木弓",
		"description": "简单的木制弓，远程攻击力+5",
		"type": ItemType.WEAPON,
		"rarity": ItemRarity.COMMON,
		"equip_slot": EquipSlot.WEAPON,
		"stats": {"ranged_attack": 5},
		"sell_price": 5,
		"buy_price": 15,
		"max_stack": 1,
		"icon": "res://assets/items/weapons/wooden_bow.png"
	}
	
	items["crossbow"] = {
		"id": "crossbow",
		"name": "十字弩",
		"description": "精准的十字弩，远程攻击力+12",
		"type": ItemType.WEAPON,
		"rarity": ItemRarity.UNCOMMON,
		"equip_slot": EquipSlot.WEAPON,
		"stats": {"ranged_attack": 12},
		"sell_price": 25,
		"buy_price": 70,
		"max_stack": 1,
		"icon": "res://assets/items/weapons/crossbow.png"
	}
	
	items["sniper_bow"] = {
		"id": "sniper_bow",
		"name": "狙击弓",
		"description": "远距离狙击专用弓，远程攻击力+20，暴击率+10%",
		"type": ItemType.WEAPON,
		"rarity": ItemRarity.RARE,
		"equip_slot": EquipSlot.WEAPON,
		"stats": {"ranged_attack": 20, "crit_chance": 0.1},
		"sell_price": 100,
		"buy_price": 280,
		"max_stack": 1,
		"icon": "res://assets/items/weapons/sniper_bow.png"
	}
	
	items["machine_bow"] = {
		"id": "machine_bow",
		"name": "机弩",
		"description": "可连续射击的弩，远程攻击力+8，攻速+30%",
		"type": ItemType.WEAPON,
		"rarity": ItemRarity.RARE,
		"equip_slot": EquipSlot.WEAPON,
		"stats": {"ranged_attack": 8, "attack_speed": 0.3},
		"sell_price": 90,
		"buy_price": 250,
		"max_stack": 1,
		"icon": "res://assets/items/weapons/machine_bow.png"
	}
	
	items["magic_staff"] = {
		"id": "magic_staff",
		"name": "魔法杖",
		"description": "法师专用的魔杖，法术伤害+15，法力+20",
		"type": ItemType.WEAPON,
		"rarity": ItemRarity.RARE,
		"equip_slot": EquipSlot.WEAPON,
		"stats": {"magic_damage": 15, "max_mana": 20},
		"sell_price": 100,
		"buy_price": 300,
		"max_stack": 1,
		"icon": "res://assets/items/weapons/magic_staff.png"
	}


# =============================================================================
# 防具类道具 (10种)
# =============================================================================

func _register_armor_items() -> void:
	items["cloth_armor"] = {
		"id": "cloth_armor",
		"name": "布甲",
		"description": "简单的布制护甲，防御力+5",
		"type": ItemType.ARMOR,
		"rarity": ItemRarity.COMMON,
		"equip_slot": EquipSlot.ARMOR,
		"stats": {"defense": 5},
		"sell_price": 5,
		"buy_price": 15,
		"max_stack": 1,
		"icon": "res://assets/items/armor/cloth_armor.png"
	}
	
	items["leather_armor"] = {
		"id": "leather_armor",
		"name": "皮甲",
		"description": "皮革制成的护甲，防御力+10",
		"type": ItemType.ARMOR,
		"rarity": ItemRarity.COMMON,
		"equip_slot": EquipSlot.ARMOR,
		"stats": {"defense": 10},
		"sell_price": 15,
		"buy_price": 40,
		"max_stack": 1,
		"icon": "res://assets/items/armor/leather_armor.png"
	}
	
	items["iron_armor"] = {
		"id": "iron_armor",
		"name": "铁甲",
		"description": "铁制重型护甲，防御力+20",
		"type": ItemType.ARMOR,
		"rarity": ItemRarity.UNCOMMON,
		"equip_slot": EquipSlot.ARMOR,
		"stats": {"defense": 20, "move_speed_percent": -0.05},
		"sell_price": 40,
		"buy_price": 100,
		"max_stack": 1,
		"icon": "res://assets/items/armor/iron_armor.png"
	}
	
	items["steel_armor"] = {
		"id": "steel_armor",
		"name": "钢甲",
		"description": "精钢制成的重型护甲，防御力+30",
		"type": ItemType.ARMOR,
		"rarity": ItemRarity.RARE,
		"equip_slot": EquipSlot.ARMOR,
		"stats": {"defense": 30, "move_speed_percent": -0.08},
		"sell_price": 100,
		"buy_price": 280,
		"max_stack": 1,
		"icon": "res://assets/items/armor/steel_armor.png"
	}
	
	items["magic_robe"] = {
		"id": "magic_robe",
		"name": "法师长袍",
		"description": "法师专用的长袍，防御力+10，法力+20",
		"type": ItemType.ARMOR,
		"rarity": ItemRarity.UNCOMMON,
		"equip_slot": EquipSlot.ARMOR,
		"stats": {"defense": 10, "max_mana": 20},
		"sell_price": 50,
		"buy_price": 120,
		"max_stack": 1,
		"icon": "res://assets/items/armor/magic_robe.png"
	}
	
	items["shadow_cloak"] = {
		"id": "shadow_cloak",
		"name": "暗影斗篷",
		"description": "暗影编织的斗篷，防御力+15，闪避+10%",
		"type": ItemType.ARMOR,
		"rarity": ItemRarity.RARE,
		"equip_slot": EquipSlot.ARMOR,
		"stats": {"defense": 15, "dodge_chance": 0.1},
		"sell_price": 120,
		"buy_price": 350,
		"max_stack": 1,
		"icon": "res://assets/items/armor/shadow_cloak.png"
	}
	
	items["dragon_scale"] = {
		"id": "dragon_scale",
		"name": "龙鳞甲",
		"description": "龙鳞制成的护甲，防御力+40，火抗+50%",
		"type": ItemType.ARMOR,
		"rarity": ItemRarity.EPIC,
		"equip_slot": EquipSlot.ARMOR,
		"stats": {"defense": 40, "fire_resist": 0.5},
		"sell_price": 300,
		"buy_price": 800,
		"max_stack": 1,
		"icon": "res://assets/items/armor/dragon_scale.png"
	}
	
	items["holy_armor"] = {
		"id": "holy_armor",
		"name": "神圣铠甲",
		"description": "神圣祝福的铠甲，防御力+35，每秒恢复1%生命",
		"type": ItemType.ARMOR,
		"rarity": ItemRarity.EPIC,
		"equip_slot": EquipSlot.ARMOR,
		"stats": {"defense": 35},
		"effects": {"regen": {"percent": 0.01}},
		"sell_price": 350,
		"buy_price": 900,
		"max_stack": 1,
		"icon": "res://assets/items/armor/holy_armor.png"
	}
	
	items["void_armor"] = {
		"id": "void_armor",
		"name": "虚空甲",
		"description": "虚空之力凝聚的护甲，防御力+30，反弹10%伤害",
		"type": ItemType.ARMOR,
		"rarity": ItemRarity.EPIC,
		"equip_slot": EquipSlot.ARMOR,
		"stats": {"defense": 30},
		"effects": {"reflect": {"percent": 0.1}},
		"sell_price": 400,
		"buy_price": 1000,
		"max_stack": 1,
		"icon": "res://assets/items/armor/void_armor.png"
	}
	
	items["legendary_armor"] = {
		"id": "legendary_armor",
		"name": "传说铠甲",
		"description": "传说中的神甲，防御力+50，全属性+5%",
		"type": ItemType.ARMOR,
		"rarity": ItemRarity.LEGENDARY,
		"equip_slot": EquipSlot.ARMOR,
		"stats": {"defense": 50, "all_stats_percent": 0.05},
		"sell_price": 600,
		"buy_price": 2000,
		"max_stack": 1,
		"icon": "res://assets/items/armor/legendary_armor.png"
	}


# =============================================================================
# 饰品类道具 (15种)
# =============================================================================

func _register_accessory_items() -> void:
	items["ring_of_power"] = {
		"id": "ring_of_power",
		"name": "力量戒指",
		"description": "蕴含力量的戒指，攻击力+10%",
		"type": ItemType.ACCESSORY,
		"rarity": ItemRarity.UNCOMMON,
		"equip_slot": EquipSlot.ACCESSORY,
		"stats": {"attack_percent": 0.1},
		"sell_price": 50,
		"buy_price": 150,
		"max_stack": 1,
		"icon": "res://assets/items/accessories/ring_of_power.png"
	}
	
	items["ring_of_wisdom"] = {
		"id": "ring_of_wisdom",
		"name": "智慧戒指",
		"description": "蕴含智慧的戒指，法力+30",
		"type": ItemType.ACCESSORY,
		"rarity": ItemRarity.UNCOMMON,
		"equip_slot": EquipSlot.ACCESSORY,
		"stats": {"max_mana": 30},
		"sell_price": 50,
		"buy_price": 150,
		"max_stack": 1,
		"icon": "res://assets/items/accessories/ring_of_wisdom.png"
	}
	
	items["necklace_of_agility"] = {
		"id": "necklace_of_agility",
		"name": "敏捷项链",
		"description": "提升敏捷的项链，移动速度+10%",
		"type": ItemType.ACCESSORY,
		"rarity": ItemRarity.UNCOMMON,
		"equip_slot": EquipSlot.ACCESSORY,
		"stats": {"move_speed_percent": 0.1},
		"sell_price": 60,
		"buy_price": 180,
		"max_stack": 1,
		"icon": "res://assets/items/accessories/necklace_of_agility.png"
	}
	
	items["lucky_charm"] = {
		"id": "lucky_charm",
		"name": "幸运符",
		"description": "带来好运的护符，暴击率+5%，掉落率+20%",
		"type": ItemType.ACCESSORY,
		"rarity": ItemRarity.RARE,
		"equip_slot": EquipSlot.ACCESSORY,
		"stats": {"crit_chance": 0.05, "drop_rate": 0.2},
		"sell_price": 100,
		"buy_price": 300,
		"max_stack": 1,
		"icon": "res://assets/items/accessories/lucky_charm.png"
	}
	
	items["gem_of_wisdom"] = {
		"id": "gem_of_wisdom",
		"name": "智慧宝石",
		"description": "闪耀着智慧光芒的宝石，经验获取+15%",
		"type": ItemType.ACCESSORY,
		"rarity": ItemRarity.RARE,
		"equip_slot": EquipSlot.ACCESSORY,
		"stats": {"exp_bonus": 0.15},
		"sell_price": 120,
		"buy_price": 350,
		"max_stack": 1,
		"icon": "res://assets/items/accessories/gem_of_wisdom.png"
	}
	
	items["vampire_ring"] = {
		"id": "vampire_ring",
		"name": "吸血戒指",
		"description": "蕴含吸血之力的戒指，攻击时吸取3%伤害值的生命",
		"type": ItemType.ACCESSORY,
		"rarity": ItemRarity.RARE,
		"equip_slot": EquipSlot.ACCESSORY,
		"stats": {"life_steal": 0.03},
		"sell_price": 150,
		"buy_price": 400,
		"max_stack": 1,
		"icon": "res://assets/items/accessories/vampire_ring.png"
	}
	
	items["critical_ring"] = {
		"id": "critical_ring",
		"name": "暴击戒指",
		"description": "提升暴击能力的戒指，暴击率+8%",
		"type": ItemType.ACCESSORY,
		"rarity": ItemRarity.RARE,
		"equip_slot": EquipSlot.ACCESSORY,
		"stats": {"crit_chance": 0.08},
		"sell_price": 130,
		"buy_price": 380,
		"max_stack": 1,
		"icon": "res://assets/items/accessories/critical_ring.png"
	}
	
	items["speed_boots"] = {
		"id": "speed_boots",
		"name": "加速靴",
		"description": "轻盈的靴子，移动速度+15%",
		"type": ItemType.ACCESSORY,
		"rarity": ItemRarity.RARE,
		"equip_slot": EquipSlot.ACCESSORY,
		"stats": {"move_speed_percent": 0.15},
		"sell_price": 100,
		"buy_price": 300,
		"max_stack": 1,
		"icon": "res://assets/items/accessories/speed_boots.png"
	}
	
	items["shield_pendant"] = {
		"id": "shield_pendant",
		"name": "护盾吊坠",
		"description": "可生成护盾的吊坠，护盾值+50",
		"type": ItemType.ACCESSORY,
		"rarity": ItemRarity.RARE,
		"equip_slot": EquipSlot.ACCESSORY,
		"stats": {"shield": 50},
		"sell_price": 150,
		"buy_price": 450,
		"max_stack": 1,
		"icon": "res://assets/items/accessories/shield_pendant.png"
	}
	
	items["regeneration_ring"] = {
		"id": "regeneration_ring",
		"name": "再生戒指",
		"description": "可自动恢复生命的戒指，每秒恢复1%生命",
		"type": ItemType.ACCESSORY,
		"rarity": ItemRarity.EPIC,
		"equip_slot": EquipSlot.ACCESSORY,
		"stats": {"health_regen_percent": 0.01},
		"sell_price": 200,
		"buy_price": 600,
		"max_stack": 1,
		"icon": "res://assets/items/accessories/regeneration_ring.png"
	}
	
	items["mana_crystal"] = {
		"id": "mana_crystal",
		"name": "法力水晶",
		"description": "蕴含魔力的水晶，法力恢复速度+50%",
		"type": ItemType.ACCESSORY,
		"rarity": ItemRarity.RARE,
		"equip_slot": EquipSlot.ACCESSORY,
		"stats": {"mana_regen_percent": 0.5},
		"sell_price": 120,
		"buy_price": 350,
		"max_stack": 1,
		"icon": "res://assets/items/accessories/mana_crystal.png"
	}
	
	items["thorns_amulet"] = {
		"id": "thorns_amulet",
		"name": "荆棘护符",
		"description": "可反弹伤害的护符，反弹15%受到的伤害",
		"type": ItemType.ACCESSORY,
		"rarity": ItemRarity.EPIC,
		"equip_slot": EquipSlot.ACCESSORY,
		"stats": {"damage_reflect": 0.15},
		"sell_price": 250,
		"buy_price": 700,
		"max_stack": 1,
		"icon": "res://assets/items/accessories/thorns_amulet.png"
	}
	
	items["ghost_cloak"] = {
		"id": "ghost_cloak",
		"name": "幽灵斗篷",
		"description": "如幽灵般的斗篷，闪避率+15%",
		"type": ItemType.ACCESSORY,
		"rarity": ItemRarity.EPIC,
		"equip_slot": EquipSlot.ACCESSORY,
		"stats": {"dodge_chance": 0.15},
		"sell_price": 280,
		"buy_price": 800,
		"max_stack": 1,
		"icon": "res://assets/items/accessories/ghost_cloak.png"
	}
	
	items["berserker_emblem"] = {
		"id": "berserker_emblem",
		"name": "狂战士徽章",
		"description": "狂战士的徽章，生命低于30%时攻击力+50%",
		"type": ItemType.ACCESSORY,
		"rarity": ItemRarity.EPIC,
		"equip_slot": EquipSlot.ACCESSORY,
		"stats": {"low_health_attack_bonus": 0.5},
		"sell_price": 300,
		"buy_price": 850,
		"max_stack": 1,
		"icon": "res://assets/items/accessories/berserker_emblem.png"
	}
	
	items["guardian_angel"] = {
		"id": "guardian_angel",
		"name": "守护天使",
		"description": "天使的守护，死亡时自动复活一次",
		"type": ItemType.ACCESSORY,
		"rarity": ItemRarity.LEGENDARY,
		"equip_slot": EquipSlot.ACCESSORY,
		"effects": {"revive": {"health_percent": 0.5}},
		"sell_price": 500,
		"buy_price": 2000,
		"max_stack": 1,
		"icon": "res://assets/items/accessories/guardian_angel.png"
	}


# =============================================================================
# 消耗品类道具 (15种)
# =============================================================================

func _register_consumable_items() -> void:
	# 生命药水
	items["health_potion_small"] = {
		"id": "health_potion_small",
		"name": "小生命药水",
		"description": "恢复25点生命值",
		"type": ItemType.CONSUMABLE,
		"rarity": ItemRarity.COMMON,
		"effects": {"heal": 25},
		"sell_price": 5,
		"buy_price": 15,
		"max_stack": 20,
		"icon": "res://assets/items/consumables/health_potion_small.png"
	}
	
	items["health_potion_medium"] = {
		"id": "health_potion_medium",
		"name": "中生命药水",
		"description": "恢复50点生命值",
		"type": ItemType.CONSUMABLE,
		"rarity": ItemRarity.UNCOMMON,
		"effects": {"heal": 50},
		"sell_price": 15,
		"buy_price": 40,
		"max_stack": 15,
		"icon": "res://assets/items/consumables/health_potion_medium.png"
	}
	
	items["health_potion_large"] = {
		"id": "health_potion_large",
		"name": "大生命药水",
		"description": "恢复100点生命值",
		"type": ItemType.CONSUMABLE,
		"rarity": ItemRarity.RARE,
		"effects": {"heal": 100},
		"sell_price": 40,
		"buy_price": 100,
		"max_stack": 10,
		"icon": "res://assets/items/consumables/health_potion_large.png"
	}
	
	# 法力药水
	items["mana_potion_small"] = {
		"id": "mana_potion_small",
		"name": "小法力药水",
		"description": "恢复15点法力值",
		"type": ItemType.CONSUMABLE,
		"rarity": ItemRarity.COMMON,
		"effects": {"mana": 15},
		"sell_price": 5,
		"buy_price": 15,
		"max_stack": 20,
		"icon": "res://assets/items/consumables/mana_potion_small.png"
	}
	
	items["mana_potion_medium"] = {
		"id": "mana_potion_medium",
		"name": "中法力药水",
		"description": "恢复30点法力值",
		"type": ItemType.CONSUMABLE,
		"rarity": ItemRarity.UNCOMMON,
		"effects": {"mana": 30},
		"sell_price": 15,
		"buy_price": 40,
		"max_stack": 15,
		"icon": "res://assets/items/consumables/mana_potion_medium.png"
	}
	
	items["mana_potion_large"] = {
		"id": "mana_potion_large",
		"name": "大法力药水",
		"description": "恢复60点法力值",
		"type": ItemType.CONSUMABLE,
		"rarity": ItemRarity.RARE,
		"effects": {"mana": 60},
		"sell_price": 40,
		"buy_price": 100,
		"max_stack": 10,
		"icon": "res://assets/items/consumables/mana_potion_large.png"
	}
	
	# 药剂
	items["elixir_of_power"] = {
		"id": "elixir_of_power",
		"name": "力量药剂",
		"description": "攻击力+20%，持续60秒",
		"type": ItemType.CONSUMABLE,
		"rarity": ItemRarity.RARE,
		"effects": {"buff": {"stat": "attack_percent", "value": 0.2, "duration": 60.0}},
		"sell_price": 50,
		"buy_price": 150,
		"max_stack": 10,
		"icon": "res://assets/items/consumables/elixir_of_power.png"
	}
	
	items["elixir_of_speed"] = {
		"id": "elixir_of_speed",
		"name": "速度药剂",
		"description": "移动速度+30%，持续60秒",
		"type": ItemType.CONSUMABLE,
		"rarity": ItemRarity.RARE,
		"effects": {"buff": {"stat": "move_speed_percent", "value": 0.3, "duration": 60.0}},
		"sell_price": 50,
		"buy_price": 150,
		"max_stack": 10,
		"icon": "res://assets/items/consumables/elixir_of_speed.png"
	}
	
	items["elixir_of_defense"] = {
		"id": "elixir_of_defense",
		"name": "防御药剂",
		"description": "防御力+30%，持续60秒",
		"type": ItemType.CONSUMABLE,
		"rarity": ItemRarity.RARE,
		"effects": {"buff": {"stat": "defense_percent", "value": 0.3, "duration": 60.0}},
		"sell_price": 50,
		"buy_price": 150,
		"max_stack": 10,
		"icon": "res://assets/items/consumables/elixir_of_defense.png"
	}
	
	# 特殊消耗品
	items["exp_gem"] = {
		"id": "exp_gem",
		"name": "经验宝石",
		"description": "立即获得50点经验值",
		"type": ItemType.CONSUMABLE,
		"rarity": ItemRarity.UNCOMMON,
		"effects": {"exp": 50},
		"sell_price": 20,
		"buy_price": 60,
		"max_stack": 99,
		"icon": "res://assets/items/consumables/exp_gem.png"
	}
	
	items["gold_coin"] = {
		"id": "gold_coin",
		"name": "金币",
		"description": "获得10金币",
		"type": ItemType.CURRENCY,
		"rarity": ItemRarity.COMMON,
		"effects": {"gold": 10},
		"sell_price": 0,
		"buy_price": 0,
		"max_stack": 999,
		"icon": "res://assets/items/consumables/gold_coin.png"
	}
	
	items["treasure_chest"] = {
		"id": "treasure_chest",
		"name": "宝箱",
		"description": "打开后获得随机道具",
		"type": ItemType.CONSUMABLE,
		"rarity": ItemRarity.RARE,
		"effects": {"random_item": {"min_rarity": 1, "max_rarity": 4}},
		"sell_price": 100,
		"buy_price": 300,
		"max_stack": 5,
		"icon": "res://assets/items/consumables/treasure_chest.png"
	}
	
	items["skill_gem"] = {
		"id": "skill_gem",
		"name": "技能宝石",
		"description": "获得随机技能",
		"type": ItemType.CONSUMABLE,
		"rarity": ItemRarity.EPIC,
		"effects": {"random_skill": true},
		"sell_price": 200,
		"buy_price": 600,
		"max_stack": 5,
		"icon": "res://assets/items/consumables/skill_gem.png"
	}
	
	items["revive_cross"] = {
		"id": "revive_cross",
		"name": "复活十字架",
		"description": "使用后死亡时自动复活",
		"type": ItemType.CONSUMABLE,
		"rarity": ItemRarity.EPIC,
		"effects": {"revive": {"health_percent": 0.5}},
		"sell_price": 300,
		"buy_price": 1000,
		"max_stack": 3,
		"icon": "res://assets/items/consumables/revive_cross.png"
	}
	
	items["bomb"] = {
		"id": "bomb",
		"name": "炸弹",
		"description": "对周围敌人造成50点伤害",
		"type": ItemType.CONSUMABLE,
		"rarity": ItemRarity.UNCOMMON,
		"effects": {"damage_area": {"damage": 50, "radius": 100.0}},
		"sell_price": 30,
		"buy_price": 80,
		"max_stack": 10,
		"icon": "res://assets/items/consumables/bomb.png"
	}
