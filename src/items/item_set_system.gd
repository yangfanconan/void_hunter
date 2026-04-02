## Void Hunter - 道具套装/羁绊系统 + 主动道具
## @description: 套装效果、羁绊加成、主动使用型道具
## @version: 2.0.0

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
	if item_id in player_items:
		return
	player_items.append(item_id)
	_check_all_sets()

## 玩家失去道具时调用
func on_item_removed(item_id: String) -> void:
	player_items.erase(item_id)
	_check_all_sets()

## 获取套装加成总计
func get_set_bonuses() -> Dictionary:
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

# =============================================================================
# 公共方法 - 主动道具
# =============================================================================

## 装备主动道具
func equip_active_item(item_id: String) -> bool:
	var item: ActiveItem = active_items.get(item_id, null)
	if item == null:
		return false
	equipped_active_item = item
	return true

## 使用当前装备的主动道具
func use_active_item(target_pos: Vector2 = Vector2.ZERO) -> bool:
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
	for set_id in item_sets.keys():
		var item_set: ItemSet = item_sets[set_id]
		var count := 0
		for req_item in item_set.required_items:
			if req_item in player_items:
				count += 1

		var was_active: bool = set_id in active_sets
		if count >= 2 and not was_active:
			active_sets[set_id] = count
			set_activated.emit(set_id, count)
		elif count >= 2 and was_active:
			active_sets[set_id] = count
		elif count < 2 and was_active:
			active_sets.erase(set_id)
			set_deactivated.emit(set_id)

# =============================================================================
# 主动道具执行
# =============================================================================

func _execute_active_item(item_id: String, target_pos: Vector2) -> bool:
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
	if _player and _player.has_method("heal"):
		# 获取状态效果管理器
		var status_mgr := _get_status_manager()
		if status_mgr:
			status_mgr.apply_shield(_player, 100.0, _player)
			status_mgr.apply_invincible(_player, 2.0, _player)
			return true
	return false

func _execute_flash_step(target_pos: Vector2) -> bool:
	if _player:
		var direction := Vector2.RIGHT
		if target_pos != Vector2.ZERO:
			direction = (target_pos - _player.global_position).normalized()
		_player.global_position += direction * 200.0
		return true
	return false

func _execute_screen_clear() -> bool:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var damage := 80.0
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.has_method("take_damage"):
			enemy.take_damage(damage, _player)
	return true

func _execute_time_freeze() -> bool:
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.has_method("stun"):
			enemy.stun(3.0)
	return true

func _execute_heal_burst() -> bool:
	if _player:
		if _player.has_method("heal"):
			_player.heal(_player.max_health)
		elif "current_health" in _player and "max_health" in _player:
			_player.current_health = _player.max_health
		return true
	return false

func _execute_magnet() -> bool:
	var drops := get_tree().get_nodes_in_group("drops")
	for drop in drops:
		if is_instance_valid(drop) and drop.has_method("set_target"):
			drop.set_target(_player)
	return true

func _execute_berserk() -> bool:
	var status_mgr := _get_status_manager()
	if status_mgr and _player:
		status_mgr.apply_rage(_player, 0.8, 10.0, _player)
		status_mgr.apply_haste(_player, 0.3, 10.0, _player)
		return true
	return false

func _get_status_manager() -> Node:
	var scene := get_tree().current_scene
	if scene:
		return scene.get_node_or_null("StatusEffectManager")
	return null

# =============================================================================
# 套装注册
# =============================================================================

func _register_all_sets() -> void:
	# 火焰之力套装
	_register_set("fire_power", "火焰之力", "提升火焰伤害和攻击力",
		["flame_blade", "fire_imp"],  # 所需道具ID
		{"attack_percent": 0.1, "crit_chance": 0.05},  # 2件套
		{"attack_percent": 0.2, "life_steal": 0.03})   # 3件套

	# 冰霜之心套装
	_register_set("frost_heart", "冰霜之心", "提升冰霜效果和防御",
		["frost_blade", "ice_slime"],
		{"defense_percent": 0.1, "damage_reduction": 0.05},
		{"defense_percent": 0.2, "max_health_percent": 0.1})

	# 雷霆之怒套装
	_register_set("thunder_wrath", "雷霆之怒", "闪电伤害和暴击",
		["thunder_blade", "lightning_drone"],
		{"crit_chance": 0.1, "attack_percent": 0.08},
		{"crit_chance": 0.18, "attack_percent": 0.15})

	# 暗影之拥套装
	_register_set("shadow_embrace", "暗影之拥", "暗影伤害和闪避",
		["shadow_dagger", "ghost_cloak"],
		{"dodge_chance": 0.08, "attack_percent": 0.06},
		{"dodge_chance": 0.15, "cooldown_reduction": 0.1})

	# 神圣守护套装
	_register_set("holy_guardian", "神圣守护", "防御和回复",
		["holy_sword", "holy_armor"],
		{"defense_percent": 0.12, "max_health_percent": 0.08},
		{"defense_percent": 0.2, "life_steal": 0.05})

	# 虚空猎手套装
	_register_set("void_hunter_set", "虚空猎手", "穿透和忽视防御",
		["void_sword", "void_armor"],
		{"attack_percent": 0.12, "crit_chance": 0.08},
		{"attack_percent": 0.22, "dodge_chance": 0.1})

	# 传说英雄套装
	_register_set("legendary_hero", "传说英雄", "全属性提升",
		["legendary_blade", "legendary_armor"],
		{"attack_percent": 0.1, "defense_percent": 0.1},
		{"attack_percent": 0.15, "defense_percent": 0.15, "crit_chance": 0.1})

	# 幸运之星套装
	_register_set("lucky_star", "幸运之星", "提升掉落和金币",
		["lucky_charm", "gem_of_wisdom"],
		{"gold_bonus": 0.2, "exp_bonus": 0.15},
		{"gold_bonus": 0.4, "exp_bonus": 0.3})

	# 吸血鬼套装
	_register_set("vampire_set", "暗夜贵族", "强大吸血能力",
		["vampire_ring", "berserker_emblem"],
		{"life_steal": 0.05, "attack_percent": 0.08},
		{"life_steal": 0.1, "attack_percent": 0.15})

	# 速度之魂套装
	_register_set("speed_soul", "疾风之魂", "极速移动和攻击",
		["speed_boots", "necklace_of_agility"],
		{"move_speed_percent": 0.15, "cooldown_reduction": 0.08},
		{"move_speed_percent": 0.25, "cooldown_reduction": 0.15})

	# 再生套装
	_register_set("regen_set", "永恒再生", "强力回复能力",
		["regeneration_ring", "holy_armor"],
		{"max_health_percent": 0.1},
		{"max_health_percent": 0.2, "life_steal": 0.04})

	# 法师套装
	_register_set("mage_set", "奥术大师", "法力和技能增强",
		["magic_staff", "mana_crystal"],
		{"cooldown_reduction": 0.1},
		{"cooldown_reduction": 0.18, "crit_chance": 0.08})

	# 守护天使套装
	_register_set("guardian_set", "天使庇护", "复活和防御",
		["guardian_angel", "shield_pendant"],
		{"defense_percent": 0.1, "damage_reduction": 0.05},
		{"defense_percent": 0.18, "damage_reduction": 0.1})

	# 荆棘反伤套装
	_register_set("thorns_set", "荆棘战士", "反弹伤害",
		["thorns_amulet", "iron_armor"],
		{"defense_percent": 0.08},
		{"defense_percent": 0.15, "damage_reduction": 0.08})

	# 远程猎手套装
	_register_set("ranger_set", "远程猎手", "远程攻击增强",
		["sniper_bow", "machine_bow"],
		{"attack_percent": 0.1, "crit_chance": 0.06},
		{"attack_percent": 0.18, "crit_chance": 0.12})

func _register_set(id: String, name: String, desc: String, items: Array[String], b2: Dictionary, b3: Dictionary = {}) -> void:
	var s := ItemSet.new(id, name, desc)
	s.required_items = items
	s.bonus_2piece = b2
	s.bonus_3piece = b3
	item_sets[id] = s

# =============================================================================
# 主动道具注册
# =============================================================================

func _register_all_active_items() -> void:
	_ai("active_shield", "能量护盾", "获得100护盾和2秒无敌", 20.0, 3, Color(0.3, 0.6, 1.0))
	_ai("active_flash", "闪现步", "瞬移200距离", 8.0, 1, Color(0.5, 0.8, 1.0))
	_ai("active_nuke", "毁灭冲击", "对全屏敌人造成80伤害", 30.0, 4, Color(1.0, 0.3, 0.3))
	_ai("active_time_freeze", "时间冻结", "冻结所有敌人3秒", 25.0, 3, Color(0.6, 0.6, 1.0))
	_ai("active_heal", "完全治愈", "完全恢复生命值", 40.0, 4, Color(0.3, 1.0, 0.5))
	_ai("active_magnet", "吸引磁场", "吸引所有掉落物", 10.0, 0, Color(0.9, 0.9, 0.3))
	_ai("active_berserk", "狂暴药剂", "攻击+80%和速度+30%持续10秒", 35.0, 3, Color(1.0, 0.4, 0.2))

func _ai(id: String, name: String, desc: String, cd: float, rarity: int, color: Color) -> void:
	var item := ActiveItem.new(id, name, desc, cd, rarity)
	item.color = color
	active_items[id] = item
