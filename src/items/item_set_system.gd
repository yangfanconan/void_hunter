## Void Hunter - 道具套装/羁绊系统 + 主动道具
## @description: 套装效果、羁绊加成、主动使用型道具
## @version: 2.1.0

extends Node

# =============================================================================
# 信号
# =============================================================================

signal set_activated(set_id: String, pieces: int)
signal set_deactivated(set_id: String)
signal active_item_used(item_id: String)
signal active_item_cooldown_updated(item_id: String, remaining: float)

# =============================================================================
# 套装数据
# =============================================================================

class ItemSet:
	var id: String
	var name: String
	var description: String
	var required_items: Array[String] = []
	var bonus_2piece: Dictionary = {}
	var bonus_3piece: Dictionary = {}
	var color: Color = Color.WHITE

	func _init(p_id: String, p_name: String, p_desc: String) -> void:
		id = p_id
		name = p_name
		description = p_desc

# =============================================================================
# 主动道具数据
# =============================================================================

class ActiveItem:
	var id: String
	var name: String
	var description: String
	var cooldown: float
	var remaining_cooldown: float = 0.0
	var rarity: int = 0  ## 0=白, 1=蓝, 2=紫, 3=橙, 4=红
	var color: Color = Color.WHITE

	func _init(p_id: String, p_name: String, p_desc: String, p_cd: float, p_rarity: int) -> void:
		id = p_id
		name = p_name
		description = p_desc
		cooldown = p_cd
		rarity = p_rarity

	func is_ready() -> bool:
		return remaining_cooldown <= 0.0

# =============================================================================
# 公共变量
# =============================================================================

var item_sets: Dictionary = {}
var active_items: Dictionary = {}
var player_items: Array[String] = []
var active_sets: Dictionary = {}  ## set_id -> piece_count
var equipped_active_item: ActiveItem = null

var _player: Node = null

# =============================================================================
# 初始化
# =============================================================================

func _ready() -> void:
	# 添加到组，方便其他系统查找
	add_to_group("item_set_system")
	_register_all_sets()
	_register_all_active_items()

# =============================================================================
# 公共方法 - 套装
# =============================================================================

## 设置玩家引用
func set_player(player: Node) -> void:
	_player = player

## 玩家获得道具时调用
func on_item_acquired(item_id: String) -> void:
	"""玩家获得道具，检查套装激活"""
	if item_id in player_items:
		return
	player_items.append(item_id)
	_check_all_sets()

## 玩家失去道具时调用
func on_item_removed(item_id: String) -> void:
	"""玩家失去道具，检查套装失效"""
	player_items.erase(item_id)
	_check_all_sets()

## 获取套装加成总计
func get_set_bonuses() -> Dictionary:
	"""汇总所有激活套装的属性加成"""
	var bonuses := {
		"attack_percent": 0.0,
		"defense_percent": 0.0,
		"max_health_percent": 0.0,
		"crit_chance": 0.0,
		"life_steal": 0.0,
		"move_speed_percent": 0.0,
		"exp_bonus": 0.0,
		"gold_bonus": 0.0,
		"cooldown_reduction": 0.0,
		"damage_reduction": 0.0,
		"dodge_chance": 0.0,
	}
	for set_id in active_sets.keys():
		var pieces: int = active_sets[set_id]
		var item_set: ItemSet = item_sets[set_id]
		var bonus: Dictionary = {}
		if pieces >= 2:
			bonus = item_set.bonus_2piece
		if pieces >= 3 and not item_set.bonus_3piece.is_empty():
			bonus.merge(item_set.bonus_3piece)
		for key in bonus.keys():
			if bonuses.has(key):
				bonuses[key] += bonus[key]
	return bonuses

## 获取当前激活的套装
func get_active_sets_info() -> Array[Dictionary]:
	"""获取当前激活的套装信息列表"""
	var result: Array[Dictionary] = []
	for set_id in active_sets.keys():
		var item_set: ItemSet = item_sets[set_id]
		result.append({
			"id": set_id,
			"name": item_set.name,
			"pieces": active_sets[set_id],
			"max_pieces": item_set.required_items.size()
		})
	return result

## 获取所有套装信息（包括未激活的）
func get_all_sets_info() -> Array[Dictionary]:
	"""获取所有套装的状态信息"""
	var result: Array[Dictionary] = []
	for set_id in item_sets.keys():
		var item_set: ItemSet = item_sets[set_id]
		var pieces: int = 0
		if set_id in active_sets:
			pieces = active_sets[set_id]
		# 计算已拥有的件数
		var owned: int = 0
		for req_item in item_set.required_items:
			if req_item in player_items:
				owned += 1
		result.append({
			"id": set_id,
			"name": item_set.name,
			"description": item_set.description,
			"required_items": item_set.required_items,
			"owned_pieces": owned,
			"max_pieces": item_set.required_items.size(),
			"is_active": set_id in active_sets,
			"bonus_2piece": item_set.bonus_2piece,
			"bonus_3piece": item_set.bonus_3piece
		})
	return result

## 将套装加成应用到玩家属性
func apply_set_bonuses_to_player(player: Node) -> void:
	"""将当前所有激活的套装加成应用到玩家"""
	if player == null:
		return

	var bonuses: Dictionary = get_set_bonuses()

	if "stats" in player and player.stats is PlayerStats:
		for stat_name in bonuses.keys():
			var value: float = bonuses[stat_name]
			if value != 0.0:
				player.stats.add_percent_bonus(stat_name, value)

## 从玩家属性移除所有套装加成
func remove_set_bonuses_from_player(player: Node) -> void:
	"""移除玩家身上的所有套装加成"""
	if player == null:
		return

	var bonuses: Dictionary = get_set_bonuses()

	if "stats" in player and player.stats is PlayerStats:
		for stat_name in bonuses.keys():
			var value: float = bonuses[stat_name]
			if value != 0.0:
				player.stats.remove_percent_bonus(stat_name, value)

# =============================================================================
# 公共方法 - 主动道具
# =============================================================================

## 装备主动道具
func equip_active_item(item_id: String) -> bool:
	"""装备主动道具"""
	var item: ActiveItem = active_items.get(item_id, null)
	if item == null:
		return false
	equipped_active_item = item
	return true

## 使用当前装备的主动道具
func use_active_item(target_pos: Vector2 = Vector2.ZERO) -> bool:
	"""使用当前装备的主动道具"""
	if equipped_active_item == null or not equipped_active_item.is_ready():
		return false
	if _player == null:
		return false

	# 执行道具效果
	var success := _execute_active_item(equipped_active_item.id, target_pos)
	if success:
		equipped_active_item.remaining_cooldown = equipped_active_item.cooldown
		active_item_used.emit(equipped_active_item.id)
		return true
	return false

## 获取主动道具列表
func get_all_active_items() -> Array[Dictionary]:
	"""获取所有主动道具信息"""
	var result: Array[Dictionary] = []
	for id in active_items.keys():
		var item: ActiveItem = active_items[id]
		result.append({
			"id": item.id,
			"name": item.name,
			"description": item.description,
			"cooldown": item.cooldown,
			"remaining": item.remaining_cooldown,
			"rarity": item.rarity,
			"color": item.color
		})
	return result

# =============================================================================
# 生命周期
# =============================================================================

func _process(delta: float) -> void:
	# 更新主动道具冷却
	if equipped_active_item and equipped_active_item.remaining_cooldown > 0:
		equipped_active_item.remaining_cooldown -= delta
		active_item_cooldown_updated.emit(equipped_active_item.id, equipped_active_item.remaining_cooldown)

# =============================================================================
# 套装检测
# =============================================================================

func _check_all_sets() -> void:
	"""检查所有套装的激活状态"""
	for set_id in item_sets.keys():
		var item_set: ItemSet = item_sets[set_id]
		var count := 0
		for req_item in item_set.required_items:
			if req_item in player_items:
				count += 1

		var was_active: bool = set_id in active_sets
		if count >= 2 and not was_active:
			# 新激活套装
			active_sets[set_id] = count
			set_activated.emit(set_id, count)
			# 如果有玩家引用，自动应用加成
			if _player != null:
				_apply_single_set_bonus(item_set, count)
		elif count >= 2 and was_active:
			# 更新件数
			active_sets[set_id] = count
		elif count < 2 and was_active:
			# 失去套装效果
			active_sets.erase(set_id)
			set_deactivated.emit(set_id)
			# 移除加成
			if _player != null:
				_remove_single_set_bonus(item_set)


## 应用单个套装的加成
func _apply_single_set_bonus(item_set: ItemSet, pieces: int) -> void:
	"""应用单个套装的加成到玩家"""
	if _player == null:
		return

	var bonus: Dictionary = {}
	if pieces >= 2:
		bonus = item_set.bonus_2piece.duplicate()
	if pieces >= 3 and not item_set.bonus_3piece.is_empty():
		bonus.merge(item_set.bonus_3piece)

	if "stats" in _player and _player.stats is PlayerStats:
		for stat_name in bonus.keys():
			var value: float = bonus[stat_name]
			if value != 0.0:
				_player.stats.add_percent_bonus(stat_name, value)


## 移除单个套装的加成
func _remove_single_set_bonus(item_set: ItemSet) -> void:
	"""移除单个套装的加成"""
	if _player == null:
		return

	# 需要移除2件和3件套的加成
	var bonus: Dictionary = item_set.bonus_2piece.duplicate()
	if not item_set.bonus_3piece.is_empty():
		bonus.merge(item_set.bonus_3piece)

	if "stats" in _player and _player.stats is PlayerStats:
		for stat_name in bonus.keys():
			var value: float = bonus[stat_name]
			if value != 0.0:
				_player.stats.remove_percent_bonus(stat_name, value)

# =============================================================================
# 主动道具执行
# =============================================================================

func _execute_active_item(item_id: String, target_pos: Vector2) -> bool:
	"""执行主动道具效果"""
	match item_id:
		"active_shield":
			return _execute_shield_burst()
		"active_flash":
			return _execute_flash_step(target_pos)
		"active_nuke":
			return _execute_screen_clear()
		"active_time_freeze":
			return _execute_time_freeze()
		"active_heal":
			return _execute_heal_burst()
		"active_magnet":
			return _execute_magnet()
		"active_berserk":
			return _execute_berserk()
		_:
			return false

func _execute_shield_burst() -> bool:
	"""能量护盾：获得100护盾和2秒无敌"""
	if _player and _player.has_method("heal"):
		var status_mgr := _get_status_manager()
		if status_mgr:
			status_mgr.apply_shield(_player, 100.0, _player)
			status_mgr.apply_invincible(_player, 2.0, _player)
			return true
		else:
			# 后备：直接恢复生命值
			if _player.has_method("heal"):
				_player.heal(100.0)
				return true
	return false

func _execute_flash_step(target_pos: Vector2) -> bool:
	"""闪现步：瞬移200距离"""
	if _player:
		var direction := Vector2.RIGHT
		if target_pos != Vector2.ZERO:
			direction = (target_pos - _player.global_position).normalized()
		_player.global_position += direction * 200.0
		return true
	return false

func _execute_screen_clear() -> bool:
	"""毁灭冲击：对全屏敌人造成80伤害"""
	var enemies := get_tree().get_nodes_in_group("enemies")
	var damage := 80.0
	var hit_count: int = 0
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.has_method("take_damage"):
			enemy.take_damage(damage, _player)
			hit_count += 1
	return hit_count > 0 or enemies.size() == 0

func _execute_time_freeze() -> bool:
	"""时间冻结：冻结所有敌人3秒"""
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.has_method("stun"):
			enemy.stun(3.0)
	return true

func _execute_heal_burst() -> bool:
	"""完全治愈：完全恢复生命值"""
	if _player:
		if _player.has_method("heal"):
			_player.heal(99999.0)
		elif "current_health" in _player and "max_health" in _player:
			_player.current_health = _player.max_health
		return true
	return false

func _execute_magnet() -> bool:
	"""吸引磁场：吸引所有掉落物"""
	var drops := get_tree().get_nodes_in_group("drop_items")
	for drop in drops:
		if is_instance_valid(drop) and drop.has_method("set_target"):
			drop.set_target(_player)
	# 也吸引 drops 组中的掉落物
	var drops_alt := get_tree().get_nodes_in_group("drops")
	for drop in drops_alt:
		if is_instance_valid(drop) and drop.has_method("set_target"):
			drop.set_target(_player)
	return true

func _execute_berserk() -> bool:
	"""狂暴药剂：攻击+80%和速度+30%持续10秒"""
	var status_mgr := _get_status_manager()
	if status_mgr and _player:
		status_mgr.apply_rage(_player, 0.8, 10.0, _player)
		status_mgr.apply_haste(_player, 0.3, 10.0, _player)
		return true
	else:
		# 后备：直接修改属性
		if _player and "stats" in _player and _player.stats is PlayerStats:
			_player.stats.add_percent_bonus("attack", 0.8)
			_player.stats.add_percent_bonus("speed", 0.3)
			# 10秒后移除
			get_tree().create_timer(10.0).timeout.connect(
				func():
					if is_instance_valid(_player) and "stats" in _player and _player.stats is PlayerStats:
						_player.stats.remove_percent_bonus("attack", 0.8)
						_player.stats.remove_percent_bonus("speed", 0.3)
			)
			return true
	return false

func _get_status_manager() -> Node:
	"""获取状态效果管理器"""
	var scene := get_tree().current_scene
	if scene:
		return scene.get_node_or_null("StatusEffectManager")
	return null

# =============================================================================
# 套装注册（使用实际注册的道具ID）
# =============================================================================

func _register_all_sets() -> void:
	"""注册所有套装（使用 items/ 目录中实际存在的道具ID）"""

	# --- 新手套装 ---
	_register_set("beginner_set", "新手冒险者", "基础攻防兼备",
		["weapon_novice_sword", "armor_cloth", "consumable_health_potion"],
		{"attack_percent": 0.05, "defense_percent": 0.05},
		{"max_health_percent": 0.05})

	# --- 精钢之力套装 ---
	_register_set("steel_power", "精钢之力", "提升攻击和防御",
		["weapon_steel_sword", "armor_iron"],
		{"attack_percent": 0.08, "defense_percent": 0.08},
		{})

	# --- 暗影之力套装 ---
	_register_set("shadow_power", "暗影之力", "暗影攻击和暴击",
		["weapon_shadow_dagger", "armor_shadow_cloak"],
		{"crit_chance": 0.1, "attack_percent": 0.08},
		{"dodge_chance": 0.08, "attack_percent": 0.15})

	# --- 龙族传说套装 ---
	_register_set("dragon_legend", "龙族传说", "火焰伤害和生存",
		["weapon_dragon_breath", "armor_void_shield"],
		{"attack_percent": 0.12, "defense_percent": 0.10},
		{"damage_reduction": 0.08, "attack_percent": 0.20})

	# --- 虚空猎手套装 ---
	_register_set("void_hunter_set", "虚空猎手", "穿透和攻击强化",
		["weapon_void_blade", "accessory_hourglass_of_time"],
		{"attack_percent": 0.12, "crit_chance": 0.08},
		{"attack_percent": 0.22, "cooldown_reduction": 0.10})

	# --- 力量配饰套装 ---
	_register_set("power_accessory_set", "力量之路", "提升攻击能力",
		["accessory_ring_of_power", "weapon_steel_sword"],
		{"attack_percent": 0.12},
		{"attack_percent": 0.20, "crit_chance": 0.05})

	# --- 敏捷之风套装 ---
	_register_set("agility_wind_set", "疾风之魂", "极速移动和闪避",
		["accessory_necklace_of_agility", "armor_shadow_cloak"],
		{"move_speed_percent": 0.15, "dodge_chance": 0.05},
		{"move_speed_percent": 0.25, "dodge_chance": 0.12})

	# --- 智慧法力套装 ---
	_register_set("wisdom_mage_set", "奥术大师", "法力和技能增强",
		["accessory_gem_of_wisdom", "consumable_elixir"],
		{"cooldown_reduction": 0.10},
		{"cooldown_reduction": 0.18, "crit_chance": 0.08})

	# --- 幸运之星套装 ---
	_register_set("lucky_star", "幸运之星", "提升掉落和经验",
		["accessory_lucky_charm", "special_exp_gem"],
		{"gold_bonus": 0.20, "exp_bonus": 0.15},
		{"gold_bonus": 0.40, "exp_bonus": 0.30})

	# --- 圣光守护套装 ---
	_register_set("holy_guardian_set", "圣光守护", "防御和回复",
		["armor_holy_light", "consumable_health_potion"],
		{"defense_percent": 0.10, "max_health_percent": 0.08},
		{"defense_percent": 0.18, "life_steal": 0.05})

	# --- 铁壁防御套装 ---
	_register_set("iron_wall_set", "铁壁防御", "坚固的防御",
		["armor_iron", "armor_cloth"],
		{"defense_percent": 0.10},
		{})

	# --- 复活守护套装 ---
	_register_set("revive_guardian_set", "不朽之魂", "复活和护盾",
		["special_revive_cross", "armor_void_shield"],
		{"max_health_percent": 0.15, "defense_percent": 0.10},
		{"max_health_percent": 0.25, "damage_reduction": 0.10})

	# === 新增套装 ===

	# --- 烈焰套装 ---
	_register_set("inferno_set", "烈焰战神", "火焰之力增幅",
		["weapon_inferno_blade", "armor_dragon_scale", "material_essence_fire"],
		{"attack_percent": 0.15, "crit_damage": 0.2},
		{"attack_percent": 0.25, "burn_damage": 5.0})

	# --- 冰霜套装 ---
	_register_set("frost_set", "冰霜领主", "冰霜之力增幅",
		["weapon_frost_scythe", "material_essence_ice"],
		{"attack_percent": 0.12, "cooldown_reduction": 0.08},
		{"freeze_chance": 0.2, "slow_power": 0.3})

	# --- 雷霆套装 ---
	_register_set("thunder_set", "雷霆霸主", "闪电之力增幅",
		["weapon_thunder_hammer", "accessory_gem_of_wisdom"],
		{"attack_percent": 0.18, "chain_lightning": 1},
		{"attack_percent": 0.30, "chain_lightning": 2})

	# --- 虚空套装 ---
	_register_set("void_set", "虚空行者", "虚空之力增幅",
		["weapon_void_blade", "armor_void_cloak", "special_chaos_orb"],
		{"attack_percent": 0.10, "dodge_chance": 0.1},
		{"attack_percent": 0.20, "dodge_chance": 0.2, "void_damage": 10.0})

	# --- 时间套装 ---
	_register_set("time_set", "时间主宰", "掌控时间",
		["accessory_time_loop", "accessory_hourglass_of_time"],
		{"cooldown_reduction": 0.15, "speed_percent": 0.1},
		{"cooldown_reduction": 0.25, "revive_chance": 0.3})

	# --- 黄金套装 ---
	_register_set("golden_set", "黄金帝王", "财富与力量",
		["special_golden_crown", "accessory_lucky_charm"],
		{"gold_bonus": 0.3, "exp_bonus": 0.2},
		{"gold_bonus": 0.5, "exp_bonus": 0.4, "luck": 0.2})

	# --- 贤者套装 ---
	_register_set("sage_set", "大贤者", "全面属性提升",
		["accessory_philosopher_stone", "accessory_gem_of_wisdom", "consumable_elixir"],
		{"all_stats": 0.1, "cooldown_reduction": 0.1},
		{"all_stats": 0.2, "cooldown_reduction": 0.2, "mana_regen": 5.0})

func _register_set(id: String, name: String, desc: String, items: Array[String], b2: Dictionary, b3: Dictionary = {}) -> void:
	"""注册一个套装"""
	var s := ItemSet.new(id, name, desc)
	s.required_items = items
	s.bonus_2piece = b2
	s.bonus_3piece = b3
	item_sets[id] = s

# =============================================================================
# 主动道具注册
# =============================================================================

func _register_all_active_items() -> void:
	"""注册所有主动道具"""
	_ai("active_shield", "能量护盾", "获得100护盾和2秒无敌", 20.0, 3, Color(0.3, 0.6, 1.0))
	_ai("active_flash", "闪现步", "瞬移200距离", 8.0, 1, Color(0.5, 0.8, 1.0))
	_ai("active_nuke", "毁灭冲击", "对全屏敌人造成80伤害", 30.0, 4, Color(1.0, 0.3, 0.3))
	_ai("active_time_freeze", "时间冻结", "冻结所有敌人3秒", 25.0, 3, Color(0.6, 0.6, 1.0))
	_ai("active_heal", "完全治愈", "完全恢复生命值", 40.0, 4, Color(0.3, 1.0, 0.5))
	_ai("active_magnet", "吸引磁场", "吸引所有掉落物", 10.0, 0, Color(0.9, 0.9, 0.3))
	_ai("active_berserk", "狂暴药剂", "攻击+80%和速度+30%持续10秒", 35.0, 3, Color(1.0, 0.4, 0.2))

func _ai(id: String, name: String, desc: String, cd: float, rarity: int, color: Color) -> void:
	"""注册一个主动道具"""
	var item := ActiveItem.new(id, name, desc, cd, rarity)
	item.color = color
	active_items[id] = item
