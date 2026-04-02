## Void Hunter - 道具图鉴系统
## @description: 记录玩家收集的道具，显示收集进度，提供解锁奖励
## @author: Void Hunter Team
## @version: 0.1.0

extends Node
class_name ItemCodex

# =============================================================================
# 信号定义
# =============================================================================

## 新道具被发现时触发
signal item_discovered(item_id: String, item_data: Dictionary)

## 收集里程碑达成时触发
signal milestone_reached(milestone_id: String, reward: Dictionary)

## 全部收集完成时触发
signal collection_completed()

# =============================================================================
# 常量定义
# =============================================================================

## 图鉴版本（用于数据迁移）
const CODEX_VERSION: int = 1

## 收集里程碑配置
const MILESTONES: Array[Dictionary] = [
	{"id": "collector_bronze", "count": 5, "reward": {"gold": 100, "title": "青铜收藏家"}},
	{"id": "collector_silver", "count": 10, "reward": {"gold": 300, "title": "白银收藏家"}},
	{"id": "collector_gold", "count": 15, "reward": {"gold": 600, "title": "黄金收藏家"}},
	{"id": "collector_platinum", "count": 18, "reward": {"gold": 1000, "title": "白金收藏家"}},
	{"id": "collector_diamond", "count": 20, "reward": {"gold": 2000, "title": "钻石收藏家"}}
]

# =============================================================================
# 公共变量
# =============================================================================

## 已发现的道具ID集合
var discovered_items: Dictionary = {}

## 已获得的里程碑
var achieved_milestones: Array[String] = []

## 总道具数量
var total_items: int = 20

## 当前收集进度
var current_progress: int = 0

# =============================================================================
# 私有变量
# =============================================================================

var _item_database: Dictionary = {}

# =============================================================================
# 生命周期
# =============================================================================

func _ready() -> void:
	"""初始化图鉴系统"""
	add_to_group("item_codex")
	_initialize_codex()


func _initialize_codex() -> void:
	"""初始化图鉴系统"""
	_build_item_database()
	total_items = _item_database.size()

# =============================================================================
# 公共方法 - 道具发现
# =============================================================================

## 发现道具
func discover_item(item_id: String) -> bool:
	"""
	记录道具发现
	@param item_id: 道具ID
	@return: 是否是新发现的道具
	"""
	if _item_database.is_empty():
		_build_item_database()
	
	if not _item_database.has(item_id):
		push_warning("未知的道具ID: " + item_id)
		return false
	
	# 检查是否已经发现
	if discovered_items.has(item_id):
		return false
	
	# 记录发现
	var item_data: Dictionary = _item_database[item_id]
	discovered_items[item_id] = {
		"id": item_id,
		"name": item_data.get("name", "Unknown"),
		"rarity": item_data.get("rarity", ItemBase.ItemRarity.COMMON),
		"discovered_at": Time.get_unix_time_from_system(),
		"count": 1
	}
	
	current_progress = discovered_items.size()
	
	# 触发发现信号
	item_discovered.emit(item_id, discovered_items[item_id])
	
	# 检查里程碑
	_check_milestones()
	
	# 检查是否完成全部收集
	if current_progress >= total_items:
		collection_completed.emit()
	
	return true


## 记录道具获取（增加计数）
func record_item_acquisition(item_id: String) -> void:
	"""
	记录道具获取（已发现的道具增加获取计数）
	@param item_id: 道具ID
	"""
	if not discovered_items.has(item_id):
		discover_item(item_id)
	else:
		discovered_items[item_id]["count"] += 1


## 检查道具是否已发现
func is_item_discovered(item_id: String) -> bool:
	"""
	检查道具是否已发现
	@param item_id: 道具ID
	@return: 是否已发现
	"""
	return discovered_items.has(item_id)


## 获取道具发现次数
func get_item_discovery_count(item_id: String) -> int:
	"""
	获取道具发现次数
	@param item_id: 道具ID
	@return: 发现次数
	"""
	if discovered_items.has(item_id):
		return discovered_items[item_id].get("count", 0)
	return 0

# =============================================================================
# 公共方法 - 进度查询
# =============================================================================

## 获取收集进度百分比
func get_progress_percentage() -> float:
	"""
	获取收集进度百分比
	@return: 进度百分比（0-100）
	"""
	if total_items <= 0:
		return 0.0
	return (float(current_progress) / float(total_items)) * 100.0


## 获取指定稀有度的收集进度
func get_rarity_progress(rarity: int) -> Dictionary:
	"""
	获取指定稀有度的收集进度
	@param rarity: 稀有度
	@return: 进度信息 {"discovered": int, "total": int, "percentage": float}
	"""
	var total_rarity: int = 0
	var discovered_rarity: int = 0
	
	for item_id in _item_database:
		var item_data: Dictionary = _item_database[item_id]
		if item_data.get("rarity", -1) == rarity:
			total_rarity += 1
			if discovered_items.has(item_id):
				discovered_rarity += 1
	
	var percentage: float = 0.0
	if total_rarity > 0:
		percentage = (float(discovered_rarity) / float(total_rarity)) * 100.0
	
	return {
		"discovered": discovered_rarity,
		"total": total_rarity,
		"percentage": percentage
	}


## 获取所有稀有度的进度
func get_all_rarity_progress() -> Dictionary:
	"""
	获取所有稀有度的收集进度
	@return: 稀有度进度字典
	"""
	var result: Dictionary = {}
	
	for rarity in ItemBase.ItemRarity.values():
		var rarity_name: String = ItemBase.RARITY_NAMES.get(rarity, "未知")
		result[rarity_name] = get_rarity_progress(rarity)
	
	return result


## 获取未发现的道具列表
func get_undiscovered_items() -> Array[Dictionary]:
	"""
	获取未发现的道具列表
	@return: 未发现道具信息数组
	"""
	var result: Array[Dictionary] = []
	
	for item_id in _item_database:
		if not discovered_items.has(item_id):
			var item_data: Dictionary = _item_database[item_id]
			result.append({
				"id": item_id,
				"rarity": item_data.get("rarity", ItemBase.ItemRarity.COMMON),
				"type": item_data.get("type", "unknown")
			})
	
	return result


## 获取已发现的道具列表
func get_discovered_items() -> Array[Dictionary]:
	"""
	获取已发现的道具列表
	@return: 已发现道具数组
	"""
	var result: Array[Dictionary] = []
	
	for item_id in discovered_items:
		result.append(discovered_items[item_id])
	
	# 按稀有度排序
	result.sort_custom(func(a, b): return a.get("rarity", 0) > b.get("rarity", 0))
	
	return result

# =============================================================================
# 公共方法 - 里程碑
# =============================================================================

## 检查里程碑达成
func _check_milestones() -> void:
	"""检查并触发里程碑奖励"""
	for milestone in MILESTONES:
		var milestone_id: String = milestone.get("id", "")
		var required_count: int = milestone.get("count", 0)
		
		# 跳过已获得的里程碑
		if milestone_id in achieved_milestones:
			continue
		
		# 检查是否达成
		if current_progress >= required_count:
			achieved_milestones.append(milestone_id)
			var reward: Dictionary = milestone.get("reward", {})
			milestone_reached.emit(milestone_id, reward)


## 获取下一个里程碑
func get_next_milestone() -> Dictionary:
	"""
	获取下一个未达成的里程碑
	@return: 里程碑信息
	"""
	for milestone in MILESTONES:
		var milestone_id: String = milestone.get("id", "")
		if milestone_id not in achieved_milestones:
			return {
				"id": milestone_id,
				"count": milestone.get("count", 0),
				"reward": milestone.get("reward", {}),
				"remaining": milestone.get("count", 0) - current_progress
			}
	
	return {}


## 获取所有里程碑状态
func get_all_milestones_status() -> Array[Dictionary]:
	"""
	获取所有里程碑的状态
	@return: 里程碑状态数组
	"""
	var result: Array[Dictionary] = []
	
	for milestone in MILESTONES:
		var milestone_id: String = milestone.get("id", "")
		var achieved: bool = milestone_id in achieved_milestones
		
		result.append({
			"id": milestone_id,
			"count": milestone.get("count", 0),
			"reward": milestone.get("reward", {}),
			"achieved": achieved,
			"current_progress": current_progress
		})
	
	return result

# =============================================================================
# 公共方法 - 图鉴展示
# =============================================================================

## 获取图鉴展示数据
func get_codex_display_data() -> Dictionary:
	"""
	获取完整的图鉴展示数据
	@return: 图鉴数据
	"""
	return {
		"version": CODEX_VERSION,
		"total_items": total_items,
		"discovered_count": current_progress,
		"progress_percentage": get_progress_percentage(),
		"rarity_progress": get_all_rarity_progress(),
		"discovered_items": get_discovered_items(),
		"milestones": get_all_milestones_status(),
		"next_milestone": get_next_milestone()
	}


## 获取道具详情
func get_item_detail(item_id: String) -> Dictionary:
	"""
	获取道具详细信息
	@param item_id: 道具ID
	@return: 道具详情
	"""
	if not _item_database.has(item_id):
		return {}
	
	var item_data: Dictionary = _item_database[item_id]
	var discovered: bool = discovered_items.has(item_id)
	
	var result: Dictionary = {
		"id": item_id,
		"discovered": discovered
	}
	
	if discovered:
		result["name"] = item_data.get("name", "Unknown")
		result["description"] = item_data.get("description", "")
		result["rarity"] = item_data.get("rarity", ItemBase.ItemRarity.COMMON)
		result["rarity_name"] = ItemBase.RARITY_NAMES.get(result["rarity"], "未知")
		result["rarity_color"] = ItemBase.RARITY_COLORS.get(result["rarity"], Color.WHITE)
		result["type"] = item_data.get("type", "unknown")
		result["stat_bonuses"] = item_data.get("stat_bonuses", {})
		result["acquisition_count"] = discovered_items[item_id].get("count", 0)
		result["discovered_at"] = discovered_items[item_id].get("discovered_at", 0)
	else:
		result["name"] = "???"
		result["description"] = "尚未发现的道具"
		result["rarity"] = item_data.get("rarity", ItemBase.ItemRarity.COMMON)
		result["rarity_name"] = ItemBase.RARITY_NAMES.get(result["rarity"], "未知")
		result["rarity_color"] = ItemBase.RARITY_COLORS.get(result["rarity"], Color.WHITE)
	
	return result

# =============================================================================
# 数据序列化
# =============================================================================

## 获取保存数据
func get_save_data() -> Dictionary:
	"""
	获取图鉴保存数据
	@return: 保存数据字典
	"""
	return {
		"version": CODEX_VERSION,
		"discovered_items": discovered_items.duplicate(),
		"achieved_milestones": achieved_milestones.duplicate(),
		"current_progress": current_progress
	}


## 加载保存数据
func load_save_data(data: Dictionary) -> void:
	"""
	加载图鉴保存数据
	@param data: 保存数据
	"""
	var version: int = data.get("version", 0)
	
	# 版本检查和数据迁移
	if version < CODEX_VERSION:
		data = _migrate_data(data, version)
	
	discovered_items = data.get("discovered_items", {})
	achieved_milestones = data.get("achieved_milestones", [])
	current_progress = data.get("current_progress", 0)


func _migrate_data(data: Dictionary, old_version: int) -> Dictionary:
	"""
	数据迁移
	@param data: 旧数据
	@param old_version: 旧版本号
	@return: 迁移后的数据
	"""
	# 目前是第一版，无需迁移
	return data

# =============================================================================
# 私有方法
# =============================================================================

func _build_item_database() -> void:
	"""构建道具数据库"""
	_item_database = {
		# 武器类
		"weapon_novice_sword": {
			"name": "新手短剑",
			"description": "一把简单的短剑，适合初学者使用。\n攻击力 +5",
			"rarity": ItemBase.ItemRarity.COMMON,
			"type": "weapon",
			"stat_bonuses": {"attack": 5}
		},
		"weapon_steel_sword": {
			"name": "精钢长剑",
			"description": "由精钢锻造的长剑，锋利无比。\n攻击力 +15\n暴击率 +5%",
			"rarity": ItemBase.ItemRarity.UNCOMMON,
			"type": "weapon",
			"stat_bonuses": {"attack": 15, "critical_chance": 0.05}
		},
		"weapon_shadow_dagger": {
			"name": "暗影匕首",
			"description": "蕴含暗影之力的匕首，攻击时带有黑暗气息。\n攻击力 +25\n暴击伤害 +30%",
			"rarity": ItemBase.ItemRarity.EPIC,
			"type": "weapon",
			"stat_bonuses": {"attack": 25, "critical_damage": 0.30}
		},
		"weapon_dragon_breath": {
			"name": "龙息巨剑",
			"description": "传说中由龙鳞锻造的巨剑，挥舞时喷射火焰。\n攻击力 +50\n攻击附带火焰伤害（额外20%）",
			"rarity": ItemBase.ItemRarity.LEGENDARY,
			"type": "weapon",
			"stat_bonuses": {"attack": 50, "fire_damage_percent": 0.20}
		},
		"weapon_void_blade": {
			"name": "虚空之刃",
			"description": "由虚空能量凝聚而成的利刃，可以穿透一切防御。\n攻击力 +40\n攻击穿透敌人（无视50%防御）",
			"rarity": ItemBase.ItemRarity.LEGENDARY,
			"type": "weapon",
			"stat_bonuses": {"attack": 40, "armor_penetration": 0.50}
		},
		
		# 防具类
		"armor_cloth": {
			"name": "布甲",
			"description": "简单的布制护甲，提供基础防护。\n防御力 +3",
			"rarity": ItemBase.ItemRarity.COMMON,
			"type": "armor",
			"stat_bonuses": {"defense": 3}
		},
		"armor_iron": {
			"name": "铁甲",
			"description": "由铁板锻造的护甲，坚固耐用。\n防御力 +10\n最大生命值 +20",
			"rarity": ItemBase.ItemRarity.UNCOMMON,
			"type": "armor",
			"stat_bonuses": {"defense": 10, "health": 20}
		},
		"armor_holy_light": {
			"name": "圣光铠甲",
			"description": "蕴含圣洁之力的铠甲，受到伤害时恢复少量生命。\n防御力 +20\n受伤恢复（回复伤害的10%）",
			"rarity": ItemBase.ItemRarity.EPIC,
			"type": "armor",
			"stat_bonuses": {"defense": 20, "heal_on_damage": 0.10}
		},
		"armor_shadow_cloak": {
			"name": "暗影披风",
			"description": "由暗影编织的披风，穿戴者如幽灵般难以捕捉。\n防御力 +15\n闪避率 +20%",
			"rarity": ItemBase.ItemRarity.LEGENDARY,
			"type": "armor",
			"stat_bonuses": {"defense": 15, "dodge_chance": 0.20}
		},
		"armor_void_shield": {
			"name": "虚空护盾",
			"description": "由虚空能量构成的护盾，定期自动恢复。\n防御力 +30\n每10秒生成护盾（吸收20点伤害）",
			"rarity": ItemBase.ItemRarity.LEGENDARY,
			"type": "armor",
			"stat_bonuses": {"defense": 30, "auto_shield": 20}
		},
		
		# 饰品类
		"accessory_ring_of_power": {
			"name": "力量戒指",
			"description": "蕴含力量的神秘戒指，提升攻击能力。\n攻击力 +10%",
			"rarity": ItemBase.ItemRarity.UNCOMMON,
			"type": "accessory",
			"stat_bonuses": {"attack_percent": 0.10}
		},
		"accessory_necklace_of_agility": {
			"name": "敏捷项链",
			"description": "轻巧的项链，让穿戴者身手矫健。\n移动速度 +15%",
			"rarity": ItemBase.ItemRarity.UNCOMMON,
			"type": "accessory",
			"stat_bonuses": {"speed_percent": 0.15}
		},
		"accessory_gem_of_wisdom": {
			"name": "智慧宝石",
			"description": "蕴含古老智慧的宝石，增强魔力。\n最大法力值 +50%\n法力恢复 +2/秒",
			"rarity": ItemBase.ItemRarity.EPIC,
			"type": "accessory",
			"stat_bonuses": {"mana_percent": 0.50, "mana_regen": 2.0}
		},
		"accessory_lucky_charm": {
			"name": "幸运护符",
			"description": "带来好运的护符，增加暴击和掉落概率。\n暴击率 +10%\n道具掉落率 +20%",
			"rarity": ItemBase.ItemRarity.EPIC,
			"type": "accessory",
			"stat_bonuses": {"critical_chance": 0.10, "drop_rate": 0.20}
		},
		"accessory_hourglass_of_time": {
			"name": "时间沙漏",
			"description": "操控时间流动的神秘沙漏。\n技能冷却时间 -20%\n技能持续时间 +30%",
			"rarity": ItemBase.ItemRarity.LEGENDARY,
			"type": "accessory",
			"stat_bonuses": {"cooldown_reduction": 0.20, "duration_bonus": 0.30}
		},
		
		# 消耗品类
		"consumable_health_potion": {
			"name": "生命药水",
			"description": "红色的药水，散发着生命气息。\n恢复30%最大生命值",
			"rarity": ItemBase.ItemRarity.COMMON,
			"type": "consumable",
			"stat_bonuses": {"heal_percent": 0.30}
		},
		"consumable_mana_potion": {
			"name": "法力药水",
			"description": "蓝色的药水，蕴含魔力。\n恢复50%最大法力值",
			"rarity": ItemBase.ItemRarity.COMMON,
			"type": "consumable",
			"stat_bonuses": {"mana_percent": 0.50}
		},
		"consumable_elixir": {
			"name": "全能药剂",
			"description": "金色的神秘药剂，蕴含强大力量。\n恢复全部生命值和法力值\n攻击力+20%（持续60秒）",
			"rarity": ItemBase.ItemRarity.EPIC,
			"type": "consumable",
			"stat_bonuses": {"full_restore": true, "attack_buff": 0.20}
		},
		
		# 特殊道具
		"special_exp_gem": {
			"name": "经验宝石",
			"description": "蕴含纯净经验能量的宝石。\n使用后获得100点经验值",
			"rarity": ItemBase.ItemRarity.UNCOMMON,
			"type": "special",
			"stat_bonuses": {"exp_amount": 100}
		},
		"special_revive_cross": {
			"name": "复活十字",
			"description": "神圣的十字架，在死亡时自动复活一次。\n死亡时恢复50%生命值复活",
			"rarity": ItemBase.ItemRarity.LEGENDARY,
			"type": "special",
			"stat_bonuses": {"revive_health_percent": 0.50}
		}
	}
