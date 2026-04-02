## Void Hunter - 游戏系统集成器 V2
## @description: 整合所有V2新系统到游戏中
## @version: 2.0.0

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
# 生命周期
# =============================================================================

func _ready() -> void:
	name = "GameSystemIntegrator"
	_initialize_systems()
	print("[GameSystemV2] 所有V2系统初始化完成")

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

# =============================================================================
# 公共接口
# =============================================================================

## 初始化玩家相关系统
func setup_player(player: Node) -> void:
	if skill_fusion and skill_fusion.has_method("initialize"):
		skill_fusion.initialize(player)
	if item_set_system and item_set_system.has_method("set_player"):
		item_set_system.set_player(player)

## 当波次开始时设置场景
func setup_wave_theme(wave: int) -> void:
	if theme_system and theme_system.has_method("get_random_theme"):
		var theme_data = theme_system.get_random_theme(wave)
		if theme_data and environment_hazard:
			_setup_environment_for_theme(theme_data, wave)

## 当敌人被击杀时
func on_enemy_killed(enemy: Node, kill_data: Dictionary = {}) -> void:
	if combo_system:
		combo_system.register_kill(kill_data)

## 当玩家攻击命中时
func on_player_hit() -> void:
	if combo_system:
		combo_system.register_hit()

## 当玩家升级时
func on_player_level_up(new_level: int) -> void:
	if talent_tree:
		talent_tree.add_talent_points(1)

## 获取所有加成
func get_all_bonuses() -> Dictionary:
	var bonuses := {}

	# 天赋加成
	if talent_tree and talent_tree.has_method("calculate_all_bonuses"):
		var talent_bonuses: Variant = talent_tree.calculate_all_bonuses()
		bonuses.merge(talent_bonuses)

	# 连击加成
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

## 应用状态效果到敌人
func apply_status_to_enemy(enemy: Node, status_type: int, duration: float, damage: float = 0.0, magnitude: float = 0.0) -> void:
	if status_effect_manager:
		status_effect_manager.apply_status(enemy, status_type, duration, damage, magnitude, _player_node())

## 应用状态效果到玩家
func apply_status_to_player(status_type: int, duration: float, magnitude: float = 0.0) -> void:
	if status_effect_manager:
		var player := _get_player()
		if player:
			status_effect_manager.apply_status(player, status_type, duration, 0.0, magnitude, _player_node())

## 进取连击/暴走状态
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

## 重置所有系统（新游戏开始）
func reset_all() -> void:
	"""重置所有系统（新游戏开始时调用）"""
	if combo_system and combo_system.has_method("reset"):
		combo_system.reset()
	if status_effect_manager:
		status_effect_manager.remove_all_status(_get_player())
	if item_set_system and item_set_system.has_method("reset"):
		item_set_system.reset()
	if talent_tree and talent_tree.has_method("reset"):
		talent_tree.reset()

## 获取结算数据
func get_run_stats() -> Dictionary:
	var stats := {}
	if combo_system:
		stats.merge(combo_system.get_stats())
	return stats

# =============================================================================
# 私有方法
# =============================================================================

func _setup_environment_for_theme(theme_data: Variant, wave: int) -> void:
	if environment_hazard == null:
		return

	environment_hazard.clear_all()

	# 根据主题创建环境危险
	var hazard_freq: Variant = theme_data.hazard_frequency
	var bounds := Rect2(Vector2.ZERO, Vector2(1200, 800))

	match theme_data.id:
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
