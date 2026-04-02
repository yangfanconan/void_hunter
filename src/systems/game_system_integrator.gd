## Void Hunter - 游戏系统集成器 V2
## @description: 整合所有V2新系统到游戏中
## @version: 2.1.0

extends Node

# =============================================================================
# 模块引用
# =============================================================================

var status_effect_manager: Node = null
var combo_system: Node = null
var talent_tree: Node = null
var skill_fusion: Node = null
var item_set_system: Node = null
var environment_hazard: Node2D = null
var theme_system: Resource = null

# =============================================================================
# 状态追踪
# =============================================================================

var _is_initialized: bool = false
var _current_wave: int = 0
var _player_ref: Node = null

# =============================================================================
# 生命周期
# =============================================================================

func _ready() -> void:
	name = "GameSystemIntegrator"
	_initialize_systems()
	_connect_internal_signals()
	_is_initialized = true
	print("[GameSystemV2] 所有V2系统初始化完成")

func _process(_delta: float) -> void:
	# 持续检查玩家引用（懒加载）
	if _player_ref == null or not is_instance_valid(_player_ref):
		_player_ref = _get_player()

# =============================================================================
# 系统初始化
# =============================================================================

func _initialize_systems() -> void:
	# 状态效果管理器
	var status_script := load("res://src/systems/status_effect_manager.gd")
	if status_script:
		status_effect_manager = Node.new()
		status_effect_manager.set_script(status_script)
		status_effect_manager.name = "StatusEffectManager"
		add_child(status_effect_manager)

	# 连击系统
	var combo_script := load("res://src/systems/combo_system.gd")
	if combo_script:
		combo_system = Node.new()
		combo_system.set_script(combo_script)
		combo_system.name = "ComboSystem"
		add_child(combo_system)
		combo_system.initialize()

	# 天赋树
	var talent_script := load("res://src/systems/permanent_talent_tree.gd")
	if talent_script:
		talent_tree = Node.new()
		talent_tree.set_script(talent_script)
		talent_tree.name = "TalentTree"
		add_child(talent_tree)

	# 技能融合
	var fusion_script := load("res://src/skills/skill_fusion_system.gd")
	if fusion_script:
		skill_fusion = Node.new()
		skill_fusion.set_script(fusion_script)
		skill_fusion.name = "SkillFusionSystem"
		add_child(skill_fusion)

	# 道具套装系统
	var set_script := load("res://src/items/item_set_system.gd")
	if set_script:
		item_set_system = Node.new()
		item_set_system.set_script(set_script)
		item_set_system.name = "ItemSetSystem"
		add_child(item_set_system)

	# 环境危险系统
	var hazard_script := load("res://src/levels/environment/environment_hazard_system.gd")
	if hazard_script:
		environment_hazard = Node2D.new()
		environment_hazard.set_script(hazard_script)
		environment_hazard.name = "EnvironmentHazardSystem"
		add_child(environment_hazard)

	# 主题系统
	var theme_script := load("res://src/levels/themes/level_theme_v2.gd")
	if theme_script:
		theme_system = theme_script.new()
		if theme_system and theme_system.has_method("load_themes"):
			theme_system.load_themes()

## 连接子系统内部信号，用于联动逻辑
func _connect_internal_signals() -> void:
	# 连击系统信号 -> 转发给外部
	if combo_system:
		if combo_system.has_signal("rage_mode_activated"):
			combo_system.rage_mode_activated.connect(_on_rage_mode_activated)
		if combo_system.has_signal("rage_mode_deactivated"):
			combo_system.rage_mode_deactivated.connect(_on_rage_mode_deactivated)
		if combo_system.has_signal("combo_milestone"):
			combo_system.combo_milestone.connect(_on_combo_milestone)
		if combo_system.has_signal("massacre_triggered"):
			combo_system.massacre_triggered.connect(_on_massacre_triggered)

# =============================================================================
# 信号回调 - 内部联动
# =============================================================================

func _on_rage_mode_activated(duration: float) -> void:
	# 暴走时为玩家施加暴走状态效果
	if status_effect_manager and _player_ref:
		status_effect_manager.apply_power_up(_player_ref, 0.5, duration)
		status_effect_manager.apply_haste(_player_ref, 0.2, duration)

func _on_rage_mode_deactivated() -> void:
	# 暴走结束时移除增益（由状态效果自动过期处理）
	pass

func _on_combo_milestone(milestone: int) -> void:
	# 里程碑奖励：给予少量治疗
	if _player_ref and _player_ref.has_method("heal"):
		var heal_amount: float = milestone * 0.5
		_player_ref.heal(heal_amount)

func _on_massacre_triggered() -> void:
	# 大屠杀奖励：恢复部分生命和法力
	if _player_ref:
		if _player_ref.has_method("heal"):
			_player_ref.heal(20.0)
		if _player_ref.has_method("restore_mana"):
			_player_ref.restore_mana(20.0)

# =============================================================================
# 公共接口 - 玩家/游戏生命周期
# =============================================================================

## 初始化玩家相关系统
func setup_player(player: Node) -> void:
	_player_ref = player

	if skill_fusion and skill_fusion.has_method("initialize"):
		skill_fusion.initialize(player)
	if item_set_system and item_set_system.has_method("set_player"):
		item_set_system.set_player(player)

	# 将天赋加成应用给玩家（如果玩家有 apply_talent_bonuses 方法）
	if talent_tree and player.has_method("apply_talent_bonuses"):
		var bonuses := talent_tree.calculate_all_bonuses()
		player.apply_talent_bonuses(bonuses)

	print("[GameSystemV2] 玩家系统初始化完成")

## 当波次开始时设置场景
func setup_wave_theme(wave: int) -> void:
	_current_wave = wave

	if theme_system and theme_system.has_method("get_random_theme"):
		var theme_data = theme_system.get_random_theme(wave)
		if theme_data and environment_hazard:
			_setup_environment_for_theme(theme_data, wave)

	# 防御天赋：每波开始给予护盾
	if talent_tree and _player_ref:
		var bonuses := talent_tree.calculate_all_bonuses()
		var shield_amount: float = bonuses.get("shield_amount", 0.0)
		if shield_amount > 0.0 and status_effect_manager:
			status_effect_manager.apply_shield(_player_ref, shield_amount)

## 当敌人被击杀时
func on_enemy_killed(enemy: Node, kill_data: Dictionary = {}) -> void:
	if combo_system:
		# 将连击倍率注入击杀数据
		kill_data["combo_multiplier"] = get_combo_multiplier()
		combo_system.register_kill(kill_data)

## 当玩家攻击命中时
func on_player_hit() -> void:
	if combo_system:
		combo_system.register_hit()

## 当玩家升级时
func on_player_level_up(new_level: int) -> void:
	if talent_tree:
		talent_tree.add_talent_points(1)

	# 升级时恢复部分生命
	if _player_ref and _player_ref.has_method("heal"):
		_player_ref.heal(10.0)

## 当玩家获得新道具时
func on_item_acquired(item_id: String) -> void:
	if item_set_system:
		item_set_system.on_item_acquired(item_id)

## 当玩家失去道具时
func on_item_removed(item_id: String) -> void:
	if item_set_system:
		item_set_system.on_item_removed(item_id)

## 当玩家技能列表变化时
func on_skills_changed(skills: Array[String]) -> void:
	if skill_fusion:
		skill_fusion.update_skills(skills)

## 当游戏结束时（结算界面）
func on_game_over(is_victory: bool) -> void:
	# 中断所有连击
	if combo_system:
		combo_system.break_combo()
		combo_system.break_kill_streak()

	# 清除所有状态效果
	if status_effect_manager and _player_ref:
		status_effect_manager.remove_all_status(_player_ref)

	# 游戏胜利给予额外天赋点
	if is_victory and talent_tree:
		var bonus_points := 2
		talent_tree.add_talent_points(bonus_points)
		print("[GameSystemV2] 胜利奖励: +%d 天赋点" % bonus_points)

# =============================================================================
# 公共接口 - 加成查询
# =============================================================================

## 获取所有加成（合并天赋、连击、套装、融合）
func get_all_bonuses() -> Dictionary:
	var bonuses := {}

	# 天赋加成（基础）
	if talent_tree and talent_tree.has_method("calculate_all_bonuses"):
		var talent_bonuses: Variant = talent_tree.calculate_all_bonuses()
		bonuses.merge(talent_bonuses)

	# 连击加成（战斗时动态）
	if combo_system and combo_system.has_method("get_current_rewards"):
		var combo_bonuses: Variant = combo_system.get_current_rewards()
		if bonuses.has("attack_percent"):
			bonuses["attack_percent"] += combo_bonuses.get("attack_bonus", 0.0)
		else:
			bonuses["attack_percent"] = combo_bonuses.get("attack_bonus", 0.0)
		if bonuses.has("crit_chance"):
			bonuses["crit_chance"] += combo_bonuses.get("crit_bonus", 0.0)
		else:
			bonuses["crit_chance"] = combo_bonuses.get("crit_bonus", 0.0)
		if bonuses.has("exp_bonus"):
			bonuses["exp_bonus"] += combo_bonuses.get("exp_bonus", 0.0)
		else:
			bonuses["exp_bonus"] = combo_bonuses.get("exp_bonus", 0.0)
		if bonuses.has("gold_bonus"):
			bonuses["gold_bonus"] += combo_bonuses.get("gold_bonus", 0.0)
		else:
			bonuses["gold_bonus"] = combo_bonuses.get("gold_bonus", 0.0)

	# 套装加成
	if item_set_system and item_set_system.has_method("get_set_bonuses"):
		var set_bonuses: Variant = item_set_system.get_set_bonuses()
		for key in set_bonuses.keys():
			if bonuses.has(key):
				bonuses[key] += set_bonuses[key]
			else:
				bonuses[key] = set_bonuses[key]

	# 技能融合加成
	if skill_fusion and skill_fusion.has_method("get_fusion_bonuses"):
		var fusion_bonuses: Variant = skill_fusion.get_fusion_bonuses()
		for key in fusion_bonuses.keys():
			if bonuses.has(key):
				bonuses[key] += fusion_bonuses[key]
			else:
				bonuses[key] = fusion_bonuses[key]

	return bonuses

## 获取连击倍率
func get_combo_multiplier() -> float:
	if combo_system and combo_system.has_method("get_combo_multiplier"):
		return combo_system.get_combo_multiplier()
	return 1.0

# =============================================================================
# 公共接口 - 状态效果
# =============================================================================

## 应用状态效果到敌人
func apply_status_to_enemy(enemy: Node, status_type: int, duration: float, damage: float = 0.0, magnitude: float = 0.0) -> void:
	if status_effect_manager:
		status_effect_manager.apply_status(enemy, status_type, duration, damage, magnitude, _player_ref)

## 应用状态效果到玩家
func apply_status_to_player(status_type: int, duration: float, magnitude: float = 0.0) -> void:
	if status_effect_manager:
		var player := _get_player()
		if player:
			status_effect_manager.apply_status(player, status_type, duration, 0.0, magnitude, player)

## 清除玩家所有状态效果
func clear_player_status() -> void:
	if status_effect_manager and _player_ref:
		status_effect_manager.remove_all_status(_player_ref)

## 清除敌人所有状态效果
func clear_enemy_status(enemy: Node) -> void:
	if status_effect_manager and is_instance_valid(enemy):
		status_effect_manager.remove_all_status(enemy)

# =============================================================================
# 公共接口 - 状态查询
# =============================================================================

## 获取暴走模式状态
func is_rage_mode() -> bool:
	if combo_system:
		return combo_system.is_rage_mode
	return false

func get_combo_count() -> int:
	if combo_system:
		return combo_system.combo_count
	return 0

func get_kill_streak() -> int:
	if combo_system:
		return combo_system.kill_streak_count
	return 0

## 获取连击系统剩余时间
func get_combo_timer() -> float:
	if combo_system and combo_system.has_method("get_combo_remaining_time"):
		return combo_system.get_combo_remaining_time()
	return 0.0

## 获取暴走模式时间比例
func get_rage_time_ratio() -> float:
	if combo_system and combo_system.has_method("get_rage_time_ratio"):
		return combo_system.get_rage_time_ratio()
	return 0.0

# =============================================================================
# 公共接口 - 重置
# =============================================================================

## 重置所有系统（新游戏开始）
func reset_all() -> void:
	# 连击系统重置
	if combo_system and combo_system.has_method("reset"):
		combo_system.reset()

	# 状态效果管理器：清除所有效果
	if status_effect_manager:
		var player := _get_player()
		if player and is_instance_valid(player):
			status_effect_manager.remove_all_status(player)
		# 清除所有敌人的状态效果
		var enemies := get_tree().get_nodes_in_group("enemies")
		for enemy in enemies:
			if is_instance_valid(enemy):
				status_effect_manager.remove_all_status(enemy)

	# 道具套装系统重置
	if item_set_system:
		if "player_items" in item_set_system:
			item_set_system.player_items.clear()
		if "active_sets" in item_set_system:
			item_set_system.active_sets.clear()
		if "equipped_active_item" in item_set_system:
			item_set_system.equipped_active_item = null

	# 技能融合系统重置
	if skill_fusion:
		if "player_skills" in skill_fusion:
			skill_fusion.player_skills.clear()
		if "active_fusions" in skill_fusion:
			skill_fusion.active_fusions.clear()

	# 清除玩家引用和波次
	_player_ref = null
	_current_wave = 0

	print("[GameSystemV2] 所有系统已重置")

## 获取结算数据
func get_run_stats() -> Dictionary:
	var stats := {}

	# 连击系统统计
	if combo_system and combo_system.has_method("get_stats"):
		stats.merge(combo_system.get_stats())

	# 天赋系统信息
	if talent_tree:
		stats["talent_points_remaining"] = talent_tree.talent_points
		stats["talent_total_invested"] = talent_tree.get_total_invested_points()
		stats["talent_total_progress"] = talent_tree.get_total_progress()

	# 套装信息
	if item_set_system and item_set_system.has_method("get_active_sets_info"):
		stats["active_sets"] = item_set_system.get_active_sets_info()

	return stats

# =============================================================================
# 私有方法
# =============================================================================

func _setup_environment_for_theme(theme_data: Variant, wave: int) -> void:
	if environment_hazard == null:
		return

	environment_hazard.clear_all()

	# 检查 theme_data 是否有效
	if theme_data == null:
		return

	# 安全获取主题 ID
	var theme_id: int = 0
	if "id" in theme_data:
		theme_id = int(theme_data.id)

	# 根据主题创建环境危险
	var bounds := Rect2(Vector2.ZERO, Vector2(1200, 800))

	match theme_id:
		0:  # FOREST
			environment_hazard.create_spike_trap(Vector2(400, 400), 10.0)
			environment_hazard.create_spike_trap(Vector2(600, 300), 10.0)
			environment_hazard.create_weather_effect("fog", bounds)
		1:  # DESERT
			environment_hazard.create_moving_platform(Vector2(200, 400), Vector2(600, 400), 80.0)
			environment_hazard.create_weather_effect("sandstorm", bounds)
		2:  # SNOW
			environment_hazard.create_weather_effect("snow", bounds)
			environment_hazard.create_spike_trap(Vector2(500, 500), 12.0)
		3:  # LAVA
			environment_hazard.create_weather_effect("lava_rain", bounds)
			environment_hazard.create_laser(Vector2(100, 200), Vector2(100, 600), 15.0)
		4:  # MECHANICAL
			for i in range(3):
				environment_hazard.create_moving_platform(
					Vector2(200 + i * 300, 300), Vector2(200 + i * 300, 500), 100.0)
			environment_hazard.create_laser(Vector2(400, 100), Vector2(400, 700), 20.0)
		5:  # ABYSS
			environment_hazard.create_weather_effect("fog", bounds)
		6:  # SKY_ISLAND
			for i in range(4):
				environment_hazard.create_moving_platform(
					Vector2(150 + i * 250, 400), Vector2(150 + i * 250, 200), 120.0)
			environment_hazard.create_weather_effect("wind", bounds)
		7:  # CEMETERY
			environment_hazard.create_weather_effect("fog", bounds)
			environment_hazard.create_spike_trap(Vector2(300, 300), 15.0)

func _get_player() -> Node:
	var players := get_tree().get_nodes_in_group("players")
	if players.size() > 0:
		return players[0]
	return null

func _player_node() -> Node:
	return _get_player()
