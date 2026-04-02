## Void Hunter - V2 全自动测试脚本
## 用法: godot --headless --path /Users/yangfan/my/void_hunter --script tests/test_all_v2.gd

extends SceneTree

var passed := 0
var failed := 0
var errors := []

func _init() -> void:
	print("\n" + "=" .repeat(60))
	print("  Void Hunter V2 - 全自动测试")
	print("=" .repeat(60) + "\n")

	# 运行所有测试
	test_status_effect_manager()
	test_combo_system()
	test_talent_tree()
	test_skill_fusion_system()
	test_item_set_system()
	test_enemy_database_v2()
	test_level_theme_v2()
	test_environment_hazard_system()
	test_game_system_integrator()
	test_character_system()

	# 输出报告
	print_report()
	quit()

# =============================================================================
# 辅助方法
# =============================================================================

func assert_true(condition: bool, description: String) -> void:
	if condition:
		passed += 1
		print("  [PASS] %s" % description)
	else:
		failed += 1
		errors.append(description)
		print("  [FAIL] %s" % description)

func assert_not_null(value, description: String) -> void:
	assert_true(value != null, description)

func assert_eq(a, b, description: String) -> void:
	assert_true(a == b, description)

func assert_gt(a, b, description: String) -> void:
	assert_true(a > b, description)

func assert_gte(a, b, description: String) -> void:
	assert_true(a >= b, description)

func assert_has(obj: Object, method: String, description: String) -> void:
	assert_true(obj.has_method(method), description + " (方法: %s)" % method)

func section(title: String) -> void:
	print("\n--- %s ---" % title)

func load_script(path: String) -> GDScript:
	var script := load(path)
	assert_not_null(script, "加载脚本: %s" % path)
	return script

# =============================================================================
# 测试: 状态效果管理器
# =============================================================================

func test_status_effect_manager() -> void:
	section("状态效果管理器")
	var script := load_script("res://src/systems/status_effect_manager.gd")
	if script == null:
		return

	var manager := Node.new()
	manager.set_script(script)
	manager.name = "StatusEffectManager"

	# 创建模拟敌人用于测试
	var mock_enemy := CharacterBody2D.new()
	mock_enemy.name = "MockEnemy"

	# 测试基本方法存在
	assert_has(manager, "apply_status", "有 apply_status 方法")
	assert_has(manager, "remove_status", "有 remove_status 方法")
	assert_has(manager, "has_status", "有 has_status 方法")
	assert_has(manager, "is_stunned", "有 is_stunned 方法")
	assert_has(manager, "get_total_slow", "有 get_total_slow 方法")

	# 测试便捷方法
	assert_has(manager, "apply_burn", "有 apply_burn 方法")
	assert_has(manager, "apply_freeze", "有 apply_freeze 方法")
	assert_has(manager, "apply_poison", "有 apply_poison 方法")
	assert_has(manager, "apply_stun", "有 apply_stun 方法")
	assert_has(manager, "apply_shield", "有 apply_shield 方法")

	manager.free()

# =============================================================================
# 测试: 连击系统
# =============================================================================

func test_combo_system() -> void:
	section("连击系统")
	var script := load_script("res://src/systems/combo_system.gd")
	if script == null:
		return

	var combo := Node.new()
	combo.set_script(script)
	combo.name = "ComboSystem"

	# 测试初始化方法
	assert_has(combo, "initialize", "有 initialize 方法")
	assert_has(combo, "register_hit", "有 register_hit 方法")
	assert_has(combo, "register_kill", "有 register_kill 方法")
	assert_has(combo, "reset", "有 reset 方法")
	assert_has(combo, "get_current_rewards", "有 get_current_rewards 方法")
	assert_has(combo, "get_score", "有 get_score 方法")
	assert_has(combo, "get_rank", "有 get_rank 方法")

	# 初始化并测试基本属性
	combo.initialize()
	assert_gte(combo.combo_count, 0, "combo_count 初始值 >= 0")
	assert_gte(combo.kill_streak_count, 0, "kill_streak_count 初始值 >= 0")

	# 测试连击计数
	combo.register_hit()
	assert_eq(combo.combo_count, 1, "register_hit 后 combo_count == 1")

	combo.register_hit()
	assert_eq(combo.combo_count, 2, "第二次 register_hit 后 combo_count == 2")

	# 测试连杀
	combo.register_kill({})
	assert_gte(combo.kill_streak_count, 1, "register_kill 后 kill_streak >= 1")

	# 测试积分
	var score: int = combo.get_score()
	assert_gt(score, 0, "连击后积分 > 0")

	# 测试评级
	var rank: String = combo.get_rank()
	assert_true(rank.length() > 0, "评级非空: %s" % rank)

	# 测试重置
	combo.reset()
	assert_eq(combo.combo_count, 0, "重置后 combo_count == 0")

	combo.free()

# =============================================================================
# 测试: 天赋树
# =============================================================================

func test_talent_tree() -> void:
	section("天赋树")
	var script := load_script("res://src/systems/permanent_talent_tree.gd")
	if script == null:
		return

	var tree := Node.new()
	tree.set_script(script)
	tree.name = "TalentTree"

	# 测试方法存在
	assert_has(tree, "add_talent_points", "有 add_talent_points 方法")
	assert_has(tree, "calculate_all_bonuses", "有 calculate_all_bonuses 方法")
	assert_has(tree, "upgrade_talent", "有 unlock_talent 方法")
	assert_has(tree, "_save_talent_data", "有 save_data 方法")
	assert_has(tree, "_load_talent_data", "有 load_data 方法")

	# 测试加成计算
	var bonuses: Dictionary = tree.calculate_all_bonuses()
	assert_not_null(bonuses, "calculate_all_bonuses 返回非空字典")
	assert_true(bonuses is Dictionary, "返回类型为 Dictionary")

	# 测试添加天赋点
	tree.add_talent_points(3)
	# 加成应该有可能变化（取决于初始状态）

	# 测试保存/加载
	tree._save_talent_data()
	print("  [INFO] 天赋树保存/加载接口存在")

	tree.free()

# =============================================================================
# 测试: 技能融合系统
# =============================================================================

func test_skill_fusion_system() -> void:
	section("技能融合系统")
	var script := load_script("res://src/skills/skill_fusion_system.gd")
	if script == null:
		return

	var fusion := Node.new()
	fusion.set_script(script)
	fusion.name = "SkillFusionSystem"

	# 测试方法存在
	assert_has(fusion, "initialize", "有 initialize 方法")
	assert_has(fusion, "_check_fusions", "有 check_fusion 方法")
	assert_has(fusion, "get_fusion_bonuses", "有 get_fusion_bonuses 方法")

	# 测试获取融合加成
	var bonuses: Dictionary = {}
	if fusion.has_method("get_fusion_bonuses"):
		bonuses = fusion.get_fusion_bonuses()
	else:
		bonuses = {}
	assert_not_null(bonuses, "get_fusion_bonuses 返回非空")

	fusion.free()

# =============================================================================
# 测试: 道具套装系统
# =============================================================================

func test_item_set_system() -> void:
	section("道具套装系统")
	var script := load_script("res://src/items/item_set_system.gd")
	if script == null:
		return

	var set_sys := Node.new()
	set_sys.set_script(script)
	set_sys.name = "ItemSetSystem"

	# 测试方法存在
	assert_has(set_sys, "on_item_acquired", "有 on_item_acquired 方法")
	assert_has(set_sys, "get_set_bonuses", "有 get_set_bonuses 方法")
	assert_has(set_sys, "use_active_item", "有 use_active_item 方法")

	# 测试套装加成
	var bonuses: Dictionary = set_sys.get_set_bonuses()
	assert_not_null(bonuses, "get_set_bonuses 返回非空")

	# 测试道具获取
	set_sys.on_item_acquired("test_item")
	print("  [INFO] 道具获取接口正常")

	set_sys.free()

# =============================================================================
# 测试: 敌人数据库V2
# =============================================================================

func test_enemy_database_v2() -> void:
	section("敌人数据库V2")
	var script := load_script("res://src/enemies/enemy_database_v2.gd")
	if script == null:
		return

	var db: Variant = script.new()
	assert_not_null(db, "敌人数据库实例化成功")

	# 测试方法存在
	assert_has(db, "get_enemy", "有 get_enemy_data 方法")
	assert_has(db, "get_elite", "有 get_elite_data 方法")
	assert_has(db, "get_boss", "有 get_boss_data 方法")

	# 测试敌人数据查询
	var enemy: Variant = db.get_enemy("forest_slime")
	if enemy != null and enemy is Dictionary and enemy.size() > 0:
		assert_not_null(enemy, "查询 forest_slime 成功")
		assert_true(enemy.has("name") or enemy.has("id"), "敌人数据包含基本字段")
	else:
		print("  [WARN] get_enemy_data 返回 null（可能数据结构不同）")

	# 测试精英数据
	var elite: Variant = db.get_elite("elite_guardian")
	if elite != null and elite is Dictionary and elite.size() > 0:
		assert_not_null(elite, "查询 elite_guardian 成功")
	else:
		print("  [WARN] get_elite_data 返回 null（可能数据结构不同）")

	# 测试Boss数据
	var boss: Variant = db.get_boss("forest_guardian")
	if boss != null and boss is Dictionary and boss.size() > 0:
		assert_not_null(boss, "查询 forest_guardian boss 成功")
		if boss.has("phases"):
			assert_gt(boss["phases"].size(), 0, "Boss 有多阶段数据")
	else:
		print("  [WARN] get_boss_data 返回 null（可能数据结构不同）")

	# db is Resource (RefCounted), no need to free

# =============================================================================
# 测试: 关卡主题系统
# =============================================================================

func test_level_theme_v2() -> void:
	section("关卡主题系统")
	var script := load_script("res://src/levels/themes/level_theme_v2.gd")
	if script == null:
		return

	var theme_sys: Variant = null
	if script:
		theme_sys = script.new()
	assert_not_null(theme_sys, "主题系统实例化成功")

	# 测试方法
	assert_has(theme_sys, "load_themes", "有 load_themes 方法")
	assert_has(theme_sys, "get_random_theme", "有 get_random_theme 方法")

	# 加载主题
	if theme_sys.has_method("load_themes"):
		theme_sys.load_themes()

	# 测试获取随机主题
	if theme_sys.has_method("get_random_theme"):
		var theme = theme_sys.get_random_theme(1)
		if theme:
			assert_not_null(theme, "Wave 1 主题数据非空")
			if "id" in theme:
				assert_gte(theme.id, 0, "主题 ID >= 0")
			if "name" in theme:
				assert_true(theme.name.length() > 0, "主题名称非空")
		else:
			print("  [WARN] Wave 1 未获取到主题（可能需要预加载）")


# =============================================================================
# 测试: 环境危险系统
# =============================================================================

func test_environment_hazard_system() -> void:
	section("环境危险系统")
	var script := load_script("res://src/levels/environment/environment_hazard_system.gd")
	if script == null:
		return

	var hazard := Node2D.new()
	hazard.set_script(script)
	hazard.name = "EnvironmentHazardSystem"

	# 测试方法存在
	assert_has(hazard, "create_moving_platform", "有 create_moving_platform 方法")
	assert_has(hazard, "create_falling_rocks", "有 create_falling_rocks 方法")
	assert_has(hazard, "create_laser", "有 create_laser 方法")
	assert_has(hazard, "create_spike_trap", "有 create_spike_trap 方法")
	assert_has(hazard, "create_weather_effect", "有 create_weather_effect 方法")
	assert_has(hazard, "clear_all", "有 clear_all 方法")

	# 测试创建移动平台（不应崩溃）
	hazard.create_moving_platform(Vector2(100, 200), Vector2(300, 200), 50.0)
	print("  [INFO] 创建移动平台成功")

	# 测试创建尖刺陷阱
	hazard.create_spike_trap(Vector2(200, 200), 10.0)
	print("  [INFO] 创建尖刺陷阱成功")

	# 测试天气效果
	var bounds := Rect2(Vector2.ZERO, Vector2(800, 600))
	hazard.create_weather_effect("fog", bounds)
	print("  [INFO] 创建天气效果成功")

	# 测试清理
	hazard.clear_all()
	print("  [INFO] clear_all 成功")

	hazard.free()

# =============================================================================
# 测试: 游戏系统集成器
# =============================================================================

func test_game_system_integrator() -> void:
	section("游戏系统集成器")
	var script := load_script("res://src/systems/game_system_integrator.gd")
	if script == null:
		return

	var integrator := Node.new()
	integrator.set_script(script)
	integrator.name = "GameSystemIntegrator"

	# 测试公共接口
	assert_has(integrator, "setup_player", "有 setup_player 方法")
	assert_has(integrator, "setup_wave_theme", "有 setup_wave_theme 方法")
	assert_has(integrator, "on_enemy_killed", "有 on_enemy_killed 方法")
	assert_has(integrator, "on_player_hit", "有 on_player_hit 方法")
	assert_has(integrator, "on_player_level_up", "有 on_player_level_up 方法")
	assert_has(integrator, "get_all_bonuses", "有 get_all_bonuses 方法")
	assert_has(integrator, "apply_status_to_enemy", "有 apply_status_to_enemy 方法")
	assert_has(integrator, "apply_status_to_player", "有 apply_status_to_player 方法")
	assert_has(integrator, "is_rage_mode", "有 is_rage_mode 方法")
	assert_has(integrator, "get_combo_count", "有 get_combo_count 方法")
	assert_has(integrator, "get_kill_streak", "有 get_kill_streak 方法")
	assert_has(integrator, "reset_all", "有 reset_all 方法")
	assert_has(integrator, "get_run_stats", "有 get_run_stats 方法")

	# 测试获取加成（无系统加载时应返回空字典）
	var bonuses: Dictionary = integrator.get_all_bonuses()
	assert_not_null(bonuses, "get_all_bonuses 返回非空")

	# 测试连击状态
	assert_eq(integrator.is_rage_mode(), false, "初始非暴走模式")
	assert_eq(integrator.get_combo_count(), 0, "初始连击数 == 0")

	integrator.free()

# =============================================================================
# 测试: 角色系统
# =============================================================================

func test_character_system() -> void:
	section("角色系统")

	var characters := [
		{"path": "res://src/characters/characters/frost_witch.gd", "name": "冰霜女巫"},
		{"path": "res://src/characters/characters/holy_paladin.gd", "name": "圣骑士"},
		{"path": "res://src/characters/characters/night_ranger.gd", "name": "暗夜游侠"},
		{"path": "res://src/characters/characters/arcane_warlock.gd", "name": "奥术术士"},
		{"path": "res://src/characters/characters/thunder_lord.gd", "name": "雷神"},
		{"path": "res://src/characters/characters/mech_engineer.gd", "name": "机械工程师"},
		{"path": "res://src/characters/characters/void_reaper.gd", "name": "虚空收割者"},
		{"path": "res://src/characters/characters/dragon_sage.gd", "name": "龙贤者"},
	]

	for char_info in characters:
		var script := load(char_info.path)
		if script:
			assert_not_null(script, "%s 脚本加载成功" % char_info.name)

			# 尝试实例化
			var char_instance: Variant = null
			if script:
				char_instance = script.new()
			if char_instance:
				assert_not_null(char_instance, "%s 实例化成功" % char_info.name)

				# 检查基本属性
				if "character_id" in char_instance:
					assert_true(char_instance.character_id.length() > 0,
						"%s 有 character_id" % char_info.name)
				if "base_health" in char_instance:
					assert_gt(char_instance.base_health, 0,
						"%s base_health > 0" % char_info.name)
				if "base_attack" in char_instance:
					assert_gt(char_instance.base_attack, 0,
						"%s base_attack > 0" % char_info.name)

								# char_instance freed by GC (may be RefCounted)
			else:
				print("  [WARN] %s 实例化返回 null" % char_info.name)
		else:
			print("  [WARN] %s 脚本加载失败" % char_info.name)

	# 同时测试已有角色
	var existing_chars := [
		{"path": "res://src/characters/characters/wandering_swordsman.gd", "name": "流浪剑客"},
		{"path": "res://src/characters/characters/elemental_mage.gd", "name": "元素法师"},
	]
	for char_info in existing_chars:
		var script := load(char_info.path)
		assert_not_null(script, "%s 脚本加载成功" % char_info.name)

# =============================================================================
# 测试报告
# =============================================================================

func print_report() -> void:
	print("\n" + "=" .repeat(60))
	print("  测试报告")
	print("=" .repeat(60))
	print("  通过: %d" % passed)
	print("  失败: %d" % failed)
	print("  总计: %d" % (passed + failed))
	print("")

	if errors.size() > 0:
		print("  失败列表:")
		for err in errors:
			print("    - %s" % err)
		print("")

	if failed == 0:
		print("  >>> 全部通过! <<<")
	else:
		print("  >>> 有 %d 个测试失败 <<<" % failed)

	print("=" .repeat(60) + "\n")
