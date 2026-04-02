## Void Hunter - 天赋树系统
## @description: 局外永久天赋树，死亡不丢失，跨局成长
## @version: 2.1.0

extends Node

# =============================================================================
# 信号定义
# =============================================================================

signal talent_points_changed(points: int)
signal talent_upgraded(talent_id: String, new_level: int)
signal talent_reset()
signal talent_tree_loaded()

# =============================================================================
# 枚举定义
# =============================================================================

enum Branch {
	OFFENSE,	## 攻击天赋树
	DEFENSE,	## 防御天赋树
	UTILITY		## 辅助天赋树
}

# =============================================================================
# 天赋数据类
# =============================================================================

class Talent:
	var id: String
	var name: String
	var description: String
	var branch: Branch
	var max_level: int
	var current_level: int = 0
	var cost_per_level: int = 1
	var row: int = 0
	var column: int = 0
	var prerequisites: Array[String] = []
	var effects: Array[float] = []  ## 每级的效果值

	func _init(p_id: String, p_name: String, p_desc: String, p_branch: Branch, p_max: int, p_row: int, p_col: int) -> void:
		id = p_id
		name = p_name
		description = p_desc
		branch = p_branch
		max_level = p_max
		row = p_row
		column = p_col

	func is_maxed() -> bool:
		return current_level >= max_level

	func can_unlock(available_points: int, unlocked_talents: Dictionary) -> bool:
		if is_maxed():
			return false
		if available_points < cost_per_level:
			return false
		for prereq in prerequisites:
			if not unlocked_talents.has(prereq) or unlocked_talents[prereq] <= 0:
				return false
		return true

	func get_effect_at_level(level: int) -> float:
		if level <= 0 or effects.is_empty():
			return 0.0
		var idx := mini(level - 1, effects.size() - 1)
		return effects[idx]

	func get_current_effect() -> float:
		return get_effect_at_level(current_level)

	## 获取下一级的效果预览
	func get_next_level_effect() -> float:
		if is_maxed():
			return get_current_effect()
		return get_effect_at_level(current_level + 1)

# =============================================================================
# 公共变量
# =============================================================================

var talent_points: int = 0
var total_points_earned: int = 0
var talents: Dictionary = {}  ## id -> Talent
var _save_path: String = "user://talent_tree_save.dat"
var _save_version: int = 2    ## 存档版本号，用于兼容性检查

# =============================================================================
# 初始化
# =============================================================================

func _ready() -> void:
	_register_all_talents()
	_load_talent_data()

## 注册所有天赋
func _register_all_talents() -> void:
	# ========== 攻击天赋树 (10个) ==========
	_register_talent("atk_power_1", "锋利之刃", "攻击力+5%", Branch.OFFENSE, 5, 0, 0,
		[0.05, 0.10, 0.15, 0.20, 0.25], [])
	_register_talent("atk_speed_1", "疾风之速", "攻击速度+4%", Branch.OFFENSE, 5, 0, 1,
		[0.04, 0.08, 0.12, 0.16, 0.20], [])
	_register_talent("crit_chance_1", "致命直觉", "暴击率+3%", Branch.OFFENSE, 5, 1, 0,
		[0.03, 0.06, 0.09, 0.12, 0.15], ["atk_power_1"])
	_register_talent("crit_damage_1", "暴击精通", "暴击伤害+15%", Branch.OFFENSE, 5, 1, 1,
		[0.15, 0.30, 0.45, 0.60, 0.75], ["atk_speed_1"])
	_register_talent("element_dmg_1", "元素亲和", "元素伤害+5%", Branch.OFFENSE, 5, 2, 0,
		[0.05, 0.10, 0.15, 0.20, 0.25], ["crit_chance_1"])
	_register_talent("penetration_1", "破甲之力", "护甲穿透+5%", Branch.OFFENSE, 3, 2, 1,
		[0.05, 0.10, 0.15], ["crit_damage_1"])
	_register_talent("aoe_bonus_1", "范围扩展", "范围技能效果+8%", Branch.OFFENSE, 3, 3, 0,
		[0.08, 0.16, 0.24], ["element_dmg_1"])
	_register_talent("multi_hit_1", "多重打击", "攻击有5%概率触发额外一次", Branch.OFFENSE, 3, 3, 1,
		[0.05, 0.10, 0.15], ["penetration_1"])
	_register_talent("execute_1", "处决专家", "对低于20%血量敌人伤害+15%", Branch.OFFENSE, 3, 4, 0,
		[0.15, 0.25, 0.35], ["aoe_bonus_1"])
	_register_talent("berserk_1", "狂战之魂", "血量越低攻击越高（最多+30%）", Branch.OFFENSE, 3, 4, 1,
		[0.10, 0.20, 0.30], ["multi_hit_1"])

	# ========== 防御天赋树 (10个) ==========
	_register_talent("def_hp_1", "强壮体魄", "最大生命值+5%", Branch.DEFENSE, 5, 0, 0,
		[0.05, 0.10, 0.15, 0.20, 0.25], [])
	_register_talent("def_armor_1", "铁壁防御", "防御力+5%", Branch.DEFENSE, 5, 0, 1,
		[0.05, 0.10, 0.15, 0.20, 0.25], [])
	_register_talent("def_dodge_1", "灵巧身法", "闪避率+2%", Branch.DEFENSE, 5, 1, 0,
		[0.02, 0.04, 0.06, 0.08, 0.10], ["def_hp_1"])
	_register_talent("def_shield_1", "能量屏障", "每波开始获得护盾", Branch.DEFENSE, 3, 1, 1,
		[10.0, 20.0, 30.0], ["def_armor_1"])
	_register_talent("def_regen_1", "生命涌泉", "生命回复速度+5%", Branch.DEFENSE, 5, 2, 0,
		[0.05, 0.10, 0.15, 0.20, 0.25], ["def_dodge_1"])
	_register_talent("def_resist_1", "元素抗性", "元素伤害减免+5%", Branch.DEFENSE, 3, 2, 1,
		[0.05, 0.10, 0.15], ["def_shield_1"])
	_register_talent("def_revive_1", "不屈意志", "每局可复活1次（50%血量）", Branch.DEFENSE, 1, 3, 0,
		[1.0], ["def_regen_1"])
	_register_talent("def_damage_red_1", "伤害减免", "受到的所有伤害-3%", Branch.DEFENSE, 5, 3, 1,
		[0.03, 0.06, 0.09, 0.12, 0.15], ["def_resist_1"])
	_register_talent("def_counter_1", "以牙还牙", "受击时反弹5%伤害", Branch.DEFENSE, 3, 4, 0,
		[0.05, 0.10, 0.15], ["def_revive_1"])
	_register_talent("def_immune_1", "钢铁之躯", "每60秒获得2秒无敌", Branch.DEFENSE, 1, 4, 1,
		[1.0], ["def_damage_red_1"])

	# ========== 辅助天赋树 (10个) ==========
	_register_talent("util_speed_1", "迅捷步伐", "移动速度+3%", Branch.UTILITY, 5, 0, 0,
		[0.03, 0.06, 0.09, 0.12, 0.15], [])
	_register_talent("util_exp_1", "学者之心", "经验获取+5%", Branch.UTILITY, 5, 0, 1,
		[0.05, 0.10, 0.15, 0.20, 0.25], [])
	_register_talent("util_gold_1", "聚宝之术", "金币获取+5%", Branch.UTILITY, 5, 1, 0,
		[0.05, 0.10, 0.15, 0.20, 0.25], ["util_speed_1"])
	_register_talent("util_drop_1", "幸运之星", "道具掉落率+5%", Branch.UTILITY, 5, 1, 1,
		[0.05, 0.10, 0.15, 0.20, 0.25], ["util_exp_1"])
	_register_talent("util_mana_1", "法力涌动", "最大法力+5%", Branch.UTILITY, 5, 2, 0,
		[0.05, 0.10, 0.15, 0.20, 0.25], ["util_gold_1"])
	_register_talent("util_cd_1", "急速施法", "技能冷却-3%", Branch.UTILITY, 5, 2, 1,
		[0.03, 0.06, 0.09, 0.12, 0.15], ["util_drop_1"])
	_register_talent("util_steal_1", "嗜血本能", "吸血+1%", Branch.UTILITY, 3, 3, 0,
		[0.01, 0.02, 0.03], ["util_mana_1"])
	_register_talent("util_stamina_1", "耐力充沛", "耐力恢复+10%", Branch.UTILITY, 3, 3, 1,
		[0.10, 0.20, 0.30], ["util_cd_1"])
	_register_talent("util_reroll_1", "命运之轮", "技能选择时可刷新1次", Branch.UTILITY, 1, 4, 0,
		[1.0], ["util_steal_1"])
	_register_talent("util_luck_1", "命运女神", "传说道具掉落率+2%", Branch.UTILITY, 3, 4, 1,
		[0.02, 0.04, 0.06], ["util_stamina_1"])

func _register_talent(t_id: String, t_name: String, t_desc: String, t_branch: Branch, \
		t_max: int, t_row: int, t_col: int, t_effects: Array[float], t_prereqs: Array[String]) -> void:
	var talent := Talent.new(t_id, t_name, t_desc, t_branch, t_max, t_row, t_col)
	talent.effects = t_effects
	talent.prerequisites = t_prereqs
	talents[t_id] = talent

# =============================================================================
# 公共方法 - 天赋操作
# =============================================================================

## 获取天赋
func get_talent(talent_id: String) -> Talent:
	return talents.get(talent_id, null)

## 检查天赋是否可以升级
func can_upgrade_talent(talent_id: String) -> bool:
	var talent: Talent = talents.get(talent_id, null)
	if talent == null:
		return false
	var unlocked := _get_unlocked_talents()
	return talent.can_unlock(talent_points, unlocked)

## 升级天赋
func upgrade_talent(talent_id: String) -> bool:
	var talent: Talent = talents.get(talent_id, null)
	if talent == null:
		push_warning("[TalentTree] 天赋不存在: %s" % talent_id)
		return false

	# 获取已解锁天赋列表（用于前置检查）
	var unlocked := _get_unlocked_talents()
	if not talent.can_unlock(talent_points, unlocked):
		push_warning("[TalentTree] 无法升级天赋: %s (点数不足或前置未满足)" % talent_id)
		return false

	# 消耗天赋点
	talent_points -= talent.cost_per_level
	talent.current_level += 1

	talent_upgraded.emit(talent_id, talent.current_level)
	talent_points_changed.emit(talent_points)
	_save_talent_data()

	print("[TalentTree] 天赋升级: %s -> Lv.%d" % [talent.name, talent.current_level])
	return true

## 重置所有天赋
func reset_all_talents() -> void:
	var refunded_points: int = 0
	for talent_id in talents.keys():
		var talent: Talent = talents[talent_id]
		refunded_points += talent.current_level * talent.cost_per_level
		talent.current_level = 0

	talent_points += refunded_points
	talent_reset.emit()
	talent_points_changed.emit(talent_points)
	_save_talent_data()
	print("[TalentTree] 天赋已全部重置，返还 %d 天赋点" % refunded_points)

## 重置指定分支的天赋
func reset_branch(branch: Branch) -> void:
	var refunded_points: int = 0
	for talent_id in talents.keys():
		var talent: Talent = talents[talent_id]
		if talent.branch == branch:
			refunded_points += talent.current_level * talent.cost_per_level
			talent.current_level = 0

	talent_points += refunded_points
	talent_reset.emit()
	talent_points_changed.emit(talent_points)
	_save_talent_data()
	print("[TalentTree] 分支 %s 天赋已重置，返还 %d 天赋点" % [Branch.keys()[branch], refunded_points])

## 增加天赋点
func add_talent_points(amount: int) -> void:
	talent_points += amount
	total_points_earned += amount
	talent_points_changed.emit(talent_points)
	print("[TalentTree] 获得 %d 天赋点 (当前: %d)" % [amount, talent_points])

## 获取某个分支的所有天赋
func get_talents_by_branch(branch: Branch) -> Array[Talent]:
	var result: Array[Talent] = []
	for talent_id in talents.keys():
		var talent: Talent = talents[talent_id]
		if talent.branch == branch:
			result.append(talent)
	# 按 row, column 排序，方便 UI 显示
	result.sort_custom(func(a: Talent, b: Talent) -> bool:
		if a.row != b.row:
			return a.row < b.row
		return a.column < b.column
	)
	return result

## 获取某个分支的已投入点数
func get_branch_invested_points(branch: Branch) -> int:
	var total := 0
	for talent_id in talents.keys():
		var talent: Talent = talents[talent_id]
		if talent.branch == branch:
			total += talent.current_level * talent.cost_per_level
	return total

## 获取所有已投入的天赋点总数
func get_total_invested_points() -> int:
	var total := 0
	for talent_id in talents.keys():
		var talent: Talent = talents[talent_id]
		total += talent.current_level * talent.cost_per_level
	return total

## 获取某个分支的进度 (0.0 ~ 1.0)
func get_branch_progress(branch: Branch) -> float:
	var total_max := 0
	var total_current := 0
	for talent_id in talents.keys():
		var talent: Talent = talents[talent_id]
		if talent.branch == branch:
			total_max += talent.max_level
			total_current += talent.current_level
	if total_max == 0:
		return 0.0
	return float(total_current) / float(total_max)

## 获取总进度 (0.0 ~ 1.0)
func get_total_progress() -> float:
	var total_max := 0
	var total_current := 0
	for talent_id in talents.keys():
		var talent: Talent = talents[talent_id]
		total_max += talent.max_level
		total_current += talent.current_level
	if total_max == 0:
		return 0.0
	return float(total_current) / float(total_max)

## 获取指定分支可解锁的最大行数（需前置行有投入点）
func get_max_unlockable_row(branch: Branch) -> int:
	var branch_talents := get_talents_by_branch(branch)
	var max_row_with_points := -1
	for talent in branch_talents:
		if talent.current_level > 0 and talent.row > max_row_with_points:
			max_row_with_points = talent.row
	# 可解锁的行 = 当前有投入点的最高行 + 1
	return mini(max_row_with_points + 1, 4)

# =============================================================================
# 公共方法 - 加成计算
# =============================================================================

## 计算所有天赋加成
func calculate_all_bonuses() -> Dictionary:
	var bonuses := {
		"attack_percent": 0.0,
		"attack_speed_percent": 0.0,
		"crit_chance": 0.0,
		"crit_damage": 0.0,
		"element_damage": 0.0,
		"penetration": 0.0,
		"aoe_bonus": 0.0,
		"multi_hit_chance": 0.0,
		"execute_bonus": 0.0,
		"berserk_bonus": 0.0,
		"max_health_percent": 0.0,
		"defense_percent": 0.0,
		"dodge_chance": 0.0,
		"shield_amount": 0.0,
		"health_regen_percent": 0.0,
		"element_resist": 0.0,
		"revive_count": 0,
		"damage_reduction": 0.0,
		"damage_reflect": 0.0,
		"auto_invincible": 0,
		"move_speed_percent": 0.0,
		"exp_bonus": 0.0,
		"gold_bonus": 0.0,
		"drop_rate_bonus": 0.0,
		"max_mana_percent": 0.0,
		"cooldown_reduction": 0.0,
		"life_steal": 0.0,
		"stamina_regen_percent": 0.0,
		"skill_reroll": 0,
		"legendary_drop_bonus": 0.0,
	}

	# 攻击天赋加成
	_add_bonus(bonuses, "attack_percent", "atk_power_1")
	_add_bonus(bonuses, "attack_speed_percent", "atk_speed_1")
	_add_bonus(bonuses, "crit_chance", "crit_chance_1")
	_add_bonus(bonuses, "crit_damage", "crit_damage_1")
	_add_bonus(bonuses, "element_damage", "element_dmg_1")
	_add_bonus(bonuses, "penetration", "penetration_1")
	_add_bonus(bonuses, "aoe_bonus", "aoe_bonus_1")
	_add_bonus(bonuses, "multi_hit_chance", "multi_hit_1")
	_add_bonus(bonuses, "execute_bonus", "execute_1")
	_add_bonus(bonuses, "berserk_bonus", "berserk_1")

	# 防御天赋加成
	_add_bonus(bonuses, "max_health_percent", "def_hp_1")
	_add_bonus(bonuses, "defense_percent", "def_armor_1")
	_add_bonus(bonuses, "dodge_chance", "def_dodge_1")
	_add_bonus(bonuses, "shield_amount", "def_shield_1")
	_add_bonus(bonuses, "health_regen_percent", "def_regen_1")
	_add_bonus(bonuses, "element_resist", "def_resist_1")
	_add_bonus_int(bonuses, "revive_count", "def_revive_1")
	_add_bonus(bonuses, "damage_reduction", "def_damage_red_1")
	_add_bonus(bonuses, "damage_reflect", "def_counter_1")
	_add_bonus_int(bonuses, "auto_invincible", "def_immune_1")

	# 辅助天赋加成
	_add_bonus(bonuses, "move_speed_percent", "util_speed_1")
	_add_bonus(bonuses, "exp_bonus", "util_exp_1")
	_add_bonus(bonuses, "gold_bonus", "util_gold_1")
	_add_bonus(bonuses, "drop_rate_bonus", "util_drop_1")
	_add_bonus(bonuses, "max_mana_percent", "util_mana_1")
	_add_bonus(bonuses, "cooldown_reduction", "util_cd_1")
	_add_bonus(bonuses, "life_steal", "util_steal_1")
	_add_bonus(bonuses, "stamina_regen_percent", "util_stamina_1")
	_add_bonus_int(bonuses, "skill_reroll", "util_reroll_1")
	_add_bonus(bonuses, "legendary_drop_bonus", "util_luck_1")

	return bonuses

## 获取指定分支的加成（只计算该分支）
func calculate_branch_bonuses(branch: Branch) -> Dictionary:
	var all_bonuses := calculate_all_bonuses()

	# 定义每个分支对应的加成键
	var branch_keys := {
		Branch.OFFENSE: [
			"attack_percent", "attack_speed_percent", "crit_chance", "crit_damage",
			"element_damage", "penetration", "aoe_bonus", "multi_hit_chance",
			"execute_bonus", "berserk_bonus"
		],
		Branch.DEFENSE: [
			"max_health_percent", "defense_percent", "dodge_chance", "shield_amount",
			"health_regen_percent", "element_resist", "revive_count", "damage_reduction",
			"damage_reflect", "auto_invincible"
		],
		Branch.UTILITY: [
			"move_speed_percent", "exp_bonus", "gold_bonus", "drop_rate_bonus",
			"max_mana_percent", "cooldown_reduction", "life_steal", "stamina_regen_percent",
			"skill_reroll", "legendary_drop_bonus"
		],
	}

	var result := {}
	var keys: Array = branch_keys.get(branch, [])
	for key in keys:
		var value = all_bonuses.get(key, 0.0)
		if value != 0.0 and value != 0:
			result[key] = value
	return result

func _add_bonus(bonuses: Dictionary, key: String, talent_id: String) -> void:
	var talent: Talent = talents.get(talent_id, null)
	if talent and talent.current_level > 0:
		bonuses[key] += talent.get_current_effect()

func _add_bonus_int(bonuses: Dictionary, key: String, talent_id: String) -> void:
	var talent: Talent = talents.get(talent_id, null)
	if talent and talent.current_level > 0:
		bonuses[key] += int(talent.get_current_effect())

# =============================================================================
# 存档系统
# =============================================================================

func _save_talent_data() -> void:
	var save_data := {
		"version": _save_version,
		"talent_points": talent_points,
		"total_points_earned": total_points_earned,
		"talents": {}
	}
	for talent_id in talents.keys():
		var talent: Talent = talents[talent_id]
		if talent.current_level > 0:
			save_data["talents"][talent_id] = talent.current_level

	var file := FileAccess.open(_save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
	else:
		push_warning("[TalentTree] 天赋存档保存失败")

func _load_talent_data() -> void:
	if not FileAccess.file_exists(_save_path):
		talent_tree_loaded.emit()
		return

	var file := FileAccess.open(_save_path, FileAccess.READ)
	if file:
		var json_text: String = file.get_as_text()
		file.close()

		var json := JSON.new()
		if json.parse(json_text) == OK:
			var data: Dictionary = json.data

			# 版本兼容检查
			var save_ver: int = data.get("version", 1)
			if save_ver != _save_version:
				print("[TalentTree] 存档版本 %d -> %d，执行兼容迁移" % [save_ver, _save_version])
				_migrate_save_data(data, save_ver)

			talent_points = int(data.get("talent_points", 0))
			total_points_earned = int(data.get("total_points_earned", 0))
			var saved_talents: Dictionary = data.get("talents", {})

			for talent_id in saved_talents.keys():
				if talents.has(talent_id):
					var level: int = int(saved_talents[talent_id])
					var talent: Talent = talents[talent_id]
					# 防止存档中的等级超过最大等级
					talent.current_level = mini(level, talent.max_level)
				else:
					push_warning("[TalentTree] 存档中包含未知天赋: %s，已忽略" % talent_id)
		else:
			push_warning("[TalentTree] 天赋存档解析失败: %s" % json.get_error_message())

	talent_tree_loaded.emit()
	print("[TalentTree] 天赋数据加载完成，可用点数: %d" % talent_points)

## 存档迁移（用于版本升级时兼容旧存档）
func _migrate_save_data(data: Dictionary, old_version: int) -> void:
	# 版本1到版本2: 无需特殊迁移，旧字段仍然兼容
	if old_version < 2:
		# 确保所有新天赋都有初始值（默认为0）
		pass

# =============================================================================
# 辅助方法
# =============================================================================

func _get_unlocked_talents() -> Dictionary:
	var result: Dictionary = {}
	for talent_id in talents.keys():
		var talent: Talent = talents[talent_id]
		if talent.current_level > 0:
			result[talent_id] = talent.current_level
	return result

## 获取天赋树状态（用于UI显示）
func get_talent_tree_state() -> Dictionary:
	var state := {
		"talent_points": talent_points,
		"total_points_earned": total_points_earned,
		"total_invested": get_total_invested_points(),
		"total_progress": get_total_progress(),
		"branches": {
			Branch.OFFENSE: {
				"progress": get_branch_progress(Branch.OFFENSE),
				"invested": get_branch_invested_points(Branch.OFFENSE),
				"talents": []
			},
			Branch.DEFENSE: {
				"progress": get_branch_progress(Branch.DEFENSE),
				"invested": get_branch_invested_points(Branch.DEFENSE),
				"talents": []
			},
			Branch.UTILITY: {
				"progress": get_branch_progress(Branch.UTILITY),
				"invested": get_branch_invested_points(Branch.UTILITY),
				"talents": []
			}
		}
	}
	for talent_id in talents.keys():
		var talent: Talent = talents[talent_id]
		var unlocked := _get_unlocked_talents()
		state["branches"][talent.branch]["talents"].append({
			"id": talent.id,
			"name": talent.name,
			"description": talent.description,
			"current_level": talent.current_level,
			"max_level": talent.max_level,
			"row": talent.row,
			"column": talent.column,
			"effect": talent.get_current_effect(),
			"next_effect": talent.get_next_level_effect(),
			"is_maxed": talent.is_maxed(),
			"can_upgrade": talent.can_unlock(talent_points, unlocked),
		})
	return state
