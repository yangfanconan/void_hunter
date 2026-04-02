## Void Hunter - 敌人数据库 V2
## @description: 15+新敌人、6+精英怪、8+主题BOSS数据定义
## @version: 2.0.0

extends Resource
class_name EnemyDatabaseV2

# =============================================================================
# 枚举
# =============================================================================

enum EnemyCategory { MELEE, RANGED, TANK, SUPPORT, FLYING, ELITE, BOSS }
enum EnemyElement { PHYSICAL, FIRE, ICE, LIGHTNING, SHADOW, HOLY, VOID, POISON }

# =============================================================================
# 敌人数据注册
# =============================================================================

var enemies: Dictionary = {}
var elites: Dictionary = {}
var bosses: Dictionary = {}
var _is_loaded: bool = false

func load_database() -> void:
	if _is_loaded:
		return
	_register_enemies()
	_register_elites()
	_register_bosses()
	_is_loaded = true

func get_enemy(id: String) -> Dictionary:
	if not _is_loaded:
		load_database()
	return enemies.get(id, {})

func get_elite(id: String) -> Dictionary:
	if not _is_loaded:
		load_database()
	return elites.get(id, {})

func get_boss(id: String) -> Dictionary:
	if not _is_loaded:
		load_database()
	return bosses.get(id, {})

func get_enemies_for_theme(theme_name: String) -> Array[Dictionary]:
	if not _is_loaded:
		load_database()
	var result: Array[Dictionary] = []
	for id in enemies.keys():
		if enemies[id].get("theme", "") == theme_name or enemies[id].get("theme", "") == "any":
			result.append(enemies[id])
	return result

func get_random_enemy(theme: String = "", category: int = -1) -> Dictionary:
	if not _is_loaded:
		load_database()
	var candidates: Array[Dictionary] = []
	for id in enemies.keys():
		var e: Dictionary = enemies[id]
		if theme != "" and e.get("theme", "") != theme and e.get("theme", "") != "any":
			continue
		if category >= 0 and e.get("category", -1) != category:
			continue
		candidates.append(e)
	if candidates.is_empty():
		return {}
	return candidates[randi() % candidates.size()]

# =============================================================================
# 普通敌人 (18种)
# =============================================================================

func _register_enemies() -> void:
	# --- 森林主题 ---
	enemies["forest_slime"] = {
		"id": "forest_slime", "name": "森林史莱姆", "category": EnemyCategory.MELEE,
		"element": EnemyElement.POISON, "theme": "forest",
		"health": 30, "damage": 8, "speed": 60, "attack_range": 30,
		"attack_cooldown": 1.2, "exp_reward": 15, "gold_reward": 5,
		"color": Color(0.3, 0.7, 0.2), "size": Vector2(20, 20),
		"behavior": "hop_towards", "special": "splits_on_death"
	}
	enemies["wolf"] = {
		"id": "wolf", "name": "暗影狼", "category": EnemyCategory.MELEE,
		"element": EnemyElement.PHYSICAL, "theme": "forest",
		"health": 45, "damage": 12, "speed": 120, "attack_range": 35,
		"attack_cooldown": 0.8, "exp_reward": 20, "gold_reward": 8,
		"color": Color(0.4, 0.4, 0.45), "size": Vector2(28, 22),
		"behavior": "lunge_attack", "special": "pack_bonus"
	}
	enemies["mushroom"] = {
		"id": "mushroom", "name": "毒蘑菇", "category": EnemyCategory.RANGED,
		"element": EnemyElement.POISON, "theme": "forest",
		"health": 25, "damage": 6, "speed": 20, "attack_range": 200,
		"attack_cooldown": 2.0, "exp_reward": 18, "gold_reward": 7,
		"color": Color(0.6, 0.3, 0.5), "size": Vector2(18, 24),
		"behavior": "stationary_shoot", "special": "poison_cloud_on_death"
	}

	# --- 沙漠主题 ---
	enemies["scorpion"] = {
		"id": "scorpion", "name": "沙蝎", "category": EnemyCategory.MELEE,
		"element": EnemyElement.PHYSICAL, "theme": "desert",
		"health": 50, "damage": 15, "speed": 90, "attack_range": 40,
		"attack_cooldown": 1.5, "exp_reward": 22, "gold_reward": 10,
		"color": Color(0.7, 0.6, 0.3), "size": Vector2(30, 20),
		"behavior": "charge_attack", "special": "poison_sting"
	}
	enemies["mummy"] = {
		"id": "mummy", "name": "沙漠木乃伊", "category": EnemyCategory.TANK,
		"element": EnemyElement.SHADOW, "theme": "desert",
		"health": 80, "damage": 10, "speed": 40, "attack_range": 30,
		"attack_cooldown": 2.0, "exp_reward": 25, "gold_reward": 12,
		"color": Color(0.8, 0.7, 0.5), "size": Vector2(24, 32),
		"behavior": "slow_advance", "special": "curse_on_hit"
	}
	enemies["sand_beetle"] = {
		"id": "sand_beetle", "name": "沙甲虫", "category": EnemyCategory.MELEE,
		"element": EnemyElement.PHYSICAL, "theme": "desert",
		"health": 35, "damage": 8, "speed": 100, "attack_range": 25,
		"attack_cooldown": 0.6, "exp_reward": 15, "gold_reward": 6,
		"color": Color(0.6, 0.5, 0.2), "size": Vector2(16, 14),
		"behavior": "swarm_attack", "special": "armor_shell"
	}

	# --- 雪地主题 ---
	enemies["ice_slime"] = {
		"id": "ice_slime", "name": "冰霜史莱姆", "category": EnemyCategory.MELEE,
		"element": EnemyElement.ICE, "theme": "snow",
		"health": 40, "damage": 10, "speed": 50, "attack_range": 30,
		"attack_cooldown": 1.5, "exp_reward": 18, "gold_reward": 7,
		"color": Color(0.5, 0.8, 1.0), "size": Vector2(22, 22),
		"behavior": "hop_towards", "special": "freeze_on_hit"
	}
	enemies["frost_wolf"] = {
		"id": "frost_wolf", "name": "霜狼", "category": EnemyCategory.MELEE,
		"element": EnemyElement.ICE, "theme": "snow",
		"health": 55, "damage": 14, "speed": 130, "attack_range": 35,
		"attack_cooldown": 0.9, "exp_reward": 25, "gold_reward": 10,
		"color": Color(0.7, 0.85, 1.0), "size": Vector2(30, 24),
		"behavior": "lunge_attack", "special": "ice_breath"
	}

	# --- 熔岩主题 ---
	enemies["fire_imp"] = {
		"id": "fire_imp", "name": "火焰小鬼", "category": EnemyCategory.FLYING,
		"element": EnemyElement.FIRE, "theme": "lava",
		"health": 25, "damage": 12, "speed": 110, "attack_range": 150,
		"attack_cooldown": 1.0, "exp_reward": 20, "gold_reward": 8,
		"color": Color(1.0, 0.4, 0.1), "size": Vector2(16, 18),
		"behavior": "circle_and_shoot", "special": "fire_trail"
	}
	enemies["lava_golem"] = {
		"id": "lava_golem", "name": "熔岩魔像", "category": EnemyCategory.TANK,
		"element": EnemyElement.FIRE, "theme": "lava",
		"health": 120, "damage": 20, "speed": 35, "attack_range": 40,
		"attack_cooldown": 2.5, "exp_reward": 35, "gold_reward": 15,
		"color": Color(0.8, 0.3, 0.1), "size": Vector2(36, 36),
		"behavior": "slow_advance", "special": "lava_pool_on_death"
	}

	# --- 机械城主题 ---
	enemies["clockwork_soldier"] = {
		"id": "clockwork_soldier", "name": "发条士兵", "category": EnemyCategory.MELEE,
		"element": EnemyElement.PHYSICAL, "theme": "mechanical",
		"health": 55, "damage": 14, "speed": 80, "attack_range": 35,
		"attack_cooldown": 1.0, "exp_reward": 22, "gold_reward": 10,
		"color": Color(0.6, 0.6, 0.65), "size": Vector2(24, 28),
		"behavior": "patrol_and_attack", "special": "self_destruct_low_hp"
	}
	enemies["laser_drone"] = {
		"id": "laser_drone", "name": "激光无人机", "category": EnemyCategory.RANGED,
		"element": EnemyElement.LIGHTNING, "theme": "mechanical",
		"health": 30, "damage": 18, "speed": 90, "attack_range": 250,
		"attack_cooldown": 2.0, "exp_reward": 25, "gold_reward": 12,
		"color": Color(0.3, 0.8, 0.9), "size": Vector2(18, 18),
		"behavior": "hover_and_snipe", "special": "overcharge"
	}

	# --- 深渊主题 ---
	enemies["shadow_crawler"] = {
		"id": "shadow_crawler", "name": "暗影爬行者", "category": EnemyCategory.MELEE,
		"element": EnemyElement.SHADOW, "theme": "abyss",
		"health": 40, "damage": 16, "speed": 140, "attack_range": 30,
		"attack_cooldown": 0.7, "exp_reward": 25, "gold_reward": 10,
		"color": Color(0.2, 0.1, 0.3), "size": Vector2(22, 16),
		"behavior": "stealth_attack", "special": "phase_through"
	}
	enemies["void_tendril"] = {
		"id": "void_tendril", "name": "虚空触须", "category": EnemyCategory.RANGED,
		"element": EnemyElement.VOID, "theme": "abyss",
		"health": 60, "damage": 8, "speed": 0, "attack_range": 180,
		"attack_cooldown": 1.5, "exp_reward": 20, "gold_reward": 8,
		"color": Color(0.4, 0.2, 0.6), "size": Vector2(20, 40),
		"behavior": "stationary_shoot", "special": "pull_target"
	}

	# --- 墓地主题 ---
	enemies["skeleton"] = {
		"id": "skeleton", "name": "亡灵骷髅", "category": EnemyCategory.MELEE,
		"element": EnemyElement.SHADOW, "theme": "cemetery",
		"health": 35, "damage": 10, "speed": 70, "attack_range": 30,
		"attack_cooldown": 1.0, "exp_reward": 16, "gold_reward": 6,
		"color": Color(0.8, 0.8, 0.7), "size": Vector2(22, 28),
		"behavior": "shamble_towards", "special": "rise_again"
	}
	enemies["ghost"] = {
		"id": "ghost", "name": "怨灵", "category": EnemyCategory.FLYING,
		"element": EnemyElement.SHADOW, "theme": "cemetery",
		"health": 20, "damage": 14, "speed": 80, "attack_range": 25,
		"attack_cooldown": 1.5, "exp_reward": 22, "gold_reward": 10,
		"color": Color(0.7, 0.7, 1.0, 0.5), "size": Vector2(20, 26),
		"behavior": "float_through", "special": "phase_immunity"
	}
	enemies["bone_dragon"] = {
		"id": "bone_dragon", "name": "骨龙", "category": EnemyCategory.RANGED,
		"element": EnemyElement.SHADOW, "theme": "cemetery",
		"health": 70, "damage": 16, "speed": 60, "attack_range": 200,
		"attack_cooldown": 2.0, "exp_reward": 30, "gold_reward": 15,
		"color": Color(0.85, 0.85, 0.8), "size": Vector2(40, 24),
		"behavior": "circle_and_shoot", "special": "bone_barrage"
	}

	# --- 通用 ---
	enemies["cave_bat"] = {
		"id": "cave_bat", "name": "洞穴蝙蝠", "category": EnemyCategory.FLYING,
		"element": EnemyElement.PHYSICAL, "theme": "any",
		"health": 15, "damage": 6, "speed": 130, "attack_range": 20,
		"attack_cooldown": 0.5, "exp_reward": 10, "gold_reward": 3,
		"color": Color(0.4, 0.3, 0.4), "size": Vector2(14, 12),
		"behavior": "swarm_attack", "special": "evasive"
	}

# =============================================================================
# 精英敌人 (8种)
# =============================================================================

func _register_elites() -> void:
	elites["elite_guardian"] = {
		"id": "elite_guardian", "name": "精英守卫", "category": EnemyCategory.ELITE,
		"element": EnemyElement.PHYSICAL,
		"health": 200, "damage": 25, "speed": 70, "attack_range": 45,
		"attack_cooldown": 1.5, "exp_reward": 80, "gold_reward": 30,
		"color": Color(0.9, 0.7, 0.2), "size": Vector2(32, 32),
		"abilities": ["shield_bash", "ground_slam", "war_cry"],
		"special": "enrage_at_50hp"
	}
	elites["elite_mage"] = {
		"id": "elite_mage", "name": "精英法师", "category": EnemyCategory.ELITE,
		"element": EnemyElement.LIGHTNING,
		"health": 120, "damage": 30, "speed": 60, "attack_range": 300,
		"attack_cooldown": 1.8, "exp_reward": 90, "gold_reward": 35,
		"color": Color(0.5, 0.3, 0.8), "size": Vector2(24, 30),
		"abilities": ["teleport", "chain_lightning", "summon_minions"],
		"special": "teleport_when_damaged"
	}
	elites["elite_assassin"] = {
		"id": "elite_assassin", "name": "精英刺客", "category": EnemyCategory.ELITE,
		"element": EnemyElement.SHADOW,
		"health": 100, "damage": 35, "speed": 180, "attack_range": 35,
		"attack_cooldown": 0.6, "exp_reward": 85, "gold_reward": 32,
		"color": Color(0.3, 0.1, 0.4), "size": Vector2(22, 26),
		"abilities": ["stealth", "backstab", "shadow_step"],
		"special": "stealth_reengage"
	}
	elites["elite_berserker"] = {
		"id": "elite_berserker", "name": "精英狂战士", "category": EnemyCategory.ELITE,
		"element": EnemyElement.FIRE,
		"health": 180, "damage": 28, "speed": 140, "attack_range": 40,
		"attack_cooldown": 0.5, "exp_reward": 95, "gold_reward": 40,
		"color": Color(0.9, 0.2, 0.1), "size": Vector2(34, 30),
		"abilities": ["frenzy", "whirlwind", "blood_rage"],
		"special": "faster_when_hurt"
	}
	elites["elite_necromancer"] = {
		"id": "elite_necromancer", "name": "精英死灵法师", "category": EnemyCategory.ELITE,
		"element": EnemyElement.SHADOW,
		"health": 130, "damage": 20, "speed": 50, "attack_range": 250,
		"attack_cooldown": 2.5, "exp_reward": 100, "gold_reward": 45,
		"color": Color(0.3, 0.4, 0.2), "size": Vector2(26, 32),
		"abilities": ["raise_dead", "death_bolt", "soul_drain"],
		"special": "summon_skeletons"
	}
	elites["elite_titan"] = {
		"id": "elite_titan", "name": "精英泰坦", "category": EnemyCategory.ELITE,
		"element": EnemyElement.PHYSICAL,
		"health": 350, "damage": 22, "speed": 40, "attack_range": 50,
		"attack_cooldown": 2.0, "exp_reward": 120, "gold_reward": 50,
		"color": Color(0.5, 0.5, 0.55), "size": Vector2(44, 44),
		"abilities": ["earthquake", "boulder_throw", "iron_skin"],
		"special": "damage_reduction"
	}
	elites["elite_phantom"] = {
		"id": "elite_phantom", "name": "精英幻影", "category": EnemyCategory.ELITE,
		"element": EnemyElement.VOID,
		"health": 90, "damage": 25, "speed": 160, "attack_range": 200,
		"attack_cooldown": 1.2, "exp_reward": 110, "gold_reward": 48,
		"color": Color(0.4, 0.2, 0.7, 0.7), "size": Vector2(24, 28),
		"abilities": ["phase_shift", "void_bolt", "dimensional_rift"],
		"special": "phase_immunity"
	}
	elites["elite_dragon_knight"] = {
		"id": "elite_dragon_knight", "name": "精英龙骑士", "category": EnemyCategory.ELITE,
		"element": EnemyElement.FIRE,
		"health": 250, "damage": 30, "speed": 100, "attack_range": 45,
		"attack_cooldown": 1.2, "exp_reward": 130, "gold_reward": 55,
		"color": Color(0.8, 0.3, 0.1), "size": Vector2(36, 34),
		"abilities": ["dragon_breath", "lance_charge", "fire_shield"],
		"special": "fire_aura"
	}

# =============================================================================
# 主题BOSS (8种)
# =============================================================================

func _register_bosses() -> void:
	# 森林守护者
	bosses["forest_guardian"] = {
		"id": "forest_guardian", "name": "远古树灵", "title": "森林守护者",
		"theme": "forest", "health": 800,
		"color": Color(0.2, 0.5, 0.15), "size": Vector2(60, 70),
		"phases": [
			{
				"health_threshold": 1.0, "name": "苏醒",
				"speed": 40, "damage": 20,
				"attacks": [
					{"name": "根须缠绕", "type": "ground_target", "damage": 15, "radius": 100, "cooldown": 3.0, "effect": "root"},
					{"name": "种子弹幕", "type": "spread_shot", "damage": 10, "count": 8, "cooldown": 2.0},
					{"name": "召唤蘑菇", "type": "summon", "enemy": "mushroom", "count": 3, "cooldown": 8.0}
				]
			},
			{
				"health_threshold": 0.5, "name": "愤怒",
				"speed": 60, "damage": 28,
				"attacks": [
					{"name": "荆棘之墙", "type": "wall", "damage": 20, "width": 400, "cooldown": 4.0},
					{"name": "毒雾弥漫", "type": "aoe", "damage": 8, "radius": 200, "cooldown": 5.0, "effect": "poison"},
					{"name": "生命汲取", "type": "beam", "damage": 12, "duration": 3.0, "cooldown": 6.0, "heal_percent": 0.3}
				]
			}
		],
		"rewards": {"gold": 200, "exp": 300, "items": ["forest_ring", "nature_staff"]}
	}

	# 沙漠法老
	bosses["pharaoh"] = {
		"id": "pharaoh", "name": "沙漠法老", "title": "永眠之主",
		"theme": "desert", "health": 1000,
		"color": Color(0.9, 0.8, 0.4), "size": Vector2(40, 50),
		"phases": [
			{
				"health_threshold": 1.0, "name": "觉醒",
				"speed": 50, "damage": 22,
				"attacks": [
					{"name": "沙暴", "type": "aoe", "damage": 12, "radius": 150, "cooldown": 3.0, "effect": "blind"},
					{"name": "诅咒之矛", "type": "projectile", "damage": 25, "speed": 400, "cooldown": 2.0, "effect": "curse"},
					{"name": "召唤木乃伊", "type": "summon", "enemy": "mummy", "count": 2, "cooldown": 10.0}
				]
			},
			{
				"health_threshold": 0.4, "name": "永眠",
				"speed": 30, "damage": 35,
				"attacks": [
					{"name": "金字塔镇压", "type": "ground_target", "damage": 40, "radius": 200, "cooldown": 5.0},
					{"name": "沙暴连击", "type": "multi_aoe", "damage": 15, "count": 5, "interval": 0.5, "cooldown": 6.0},
					{"name": "灵魂收割", "type": "homing", "damage": 30, "count": 4, "cooldown": 4.0}
				]
			}
		],
		"rewards": {"gold": 300, "exp": 400, "items": ["pharaoh_scepter", "sun_stone"]}
	}

	# 霜巨人
	bosses["frost_giant"] = {
		"id": "frost_giant", "name": "冰霜巨人", "title": "凛冬之主",
		"theme": "snow", "health": 1200,
		"color": Color(0.6, 0.8, 1.0), "size": Vector2(70, 70),
		"phases": [
			{
				"health_threshold": 1.0, "name": "寒冬",
				"speed": 35, "damage": 30,
				"attacks": [
					{"name": "冰霜重击", "type": "melee_aoe", "damage": 25, "radius": 80, "cooldown": 2.5, "effect": "freeze"},
					{"name": "冰刺投射", "type": "spread_shot", "damage": 15, "count": 12, "cooldown": 3.0, "effect": "slow"},
					{"name": "暴风雪", "type": "aoe", "damage": 8, "radius": 300, "cooldown": 8.0, "effect": "slow", "duration": 5.0}
				]
			},
			{
				"health_threshold": 0.3, "name": "绝对零度",
				"speed": 50, "damage": 40,
				"attacks": [
					{"name": "冰封大地", "type": "ground_target", "damage": 50, "radius": 250, "cooldown": 4.0, "effect": "freeze"},
					{"name": "冰川碎裂", "type": "multi_projectile", "damage": 20, "count": 20, "cooldown": 3.0},
					{"name": "召唤冰元素", "type": "summon", "enemy": "ice_slime", "count": 5, "cooldown": 8.0}
				]
			}
		],
		"rewards": {"gold": 350, "exp": 500, "items": ["frost_crown", "glacial_shard"]}
	}

	# 炎魔领主
	bosses["inferno_lord"] = {
		"id": "inferno_lord", "name": "炎魔领主", "title": "熔岩之心",
		"theme": "lava", "health": 1400,
		"color": Color(1.0, 0.3, 0.1), "size": Vector2(55, 60),
		"phases": [
			{
				"health_threshold": 1.0, "name": "灼热",
				"speed": 45, "damage": 28,
				"attacks": [
					{"name": "火焰吐息", "type": "cone", "damage": 20, "angle": 60, "range": 200, "cooldown": 3.0, "effect": "burn"},
					{"name": "熔岩弹", "type": "projectile", "damage": 25, "speed": 300, "cooldown": 2.0, "effect": "burn", "aoe": 60},
					{"name": "召唤火元素", "type": "summon", "enemy": "fire_imp", "count": 4, "cooldown": 8.0}
				]
			},
			{
				"health_threshold": 0.5, "name": "熔化",
				"speed": 55, "damage": 35,
				"attacks": [
					{"name": "火山爆发", "type": "multi_aoe", "damage": 30, "count": 8, "interval": 0.3, "cooldown": 5.0, "effect": "burn"},
					{"name": "熔岩洪流", "type": "wall", "damage": 15, "width": 600, "cooldown": 4.0, "effect": "burn"},
					{"name": "自爆小鬼", "type": "summon", "enemy": "fire_imp", "count": 6, "cooldown": 6.0, "special": "exploding"}
				]
			}
		],
		"rewards": {"gold": 400, "exp": 600, "items": ["inferno_blade", "magma_heart"]}
	}

	# 机械领主
	bosses["mech_overlord"] = {
		"id": "mech_overlord", "name": "机械领主", "title": "钢铁意志",
		"theme": "mechanical", "health": 1600,
		"color": Color(0.5, 0.5, 0.6), "size": Vector2(65, 65),
		"phases": [
			{
				"health_threshold": 1.0, "name": "启动",
				"speed": 40, "damage": 25,
				"attacks": [
					{"name": "激光扫射", "type": "beam_sweep", "damage": 15, "range": 400, "cooldown": 3.0, "duration": 2.0},
					{"name": "导弹齐射", "type": "homing", "damage": 20, "count": 6, "cooldown": 4.0},
					{"name": "部署炮塔", "type": "summon", "enemy": "laser_drone", "count": 2, "cooldown": 10.0}
				]
			},
			{
				"health_threshold": 0.6, "name": "过载",
				"speed": 60, "damage": 35,
				"attacks": [
					{"name": "电磁脉冲", "type": "aoe", "damage": 25, "radius": 200, "cooldown": 5.0, "effect": "stun"},
					{"name": "锯片风暴", "type": "multi_projectile", "damage": 18, "count": 16, "cooldown": 3.0},
					{"name": "自我修复", "type": "heal", "amount": 100, "cooldown": 15.0}
				]
			},
			{
				"health_threshold": 0.2, "name": "自毁程序",
				"speed": 80, "damage": 50,
				"attacks": [
					{"name": "全力轰击", "type": "multi_aoe", "damage": 35, "count": 12, "interval": 0.2, "cooldown": 4.0},
					{"name": "紧急部署", "type": "summon", "enemy": "clockwork_soldier", "count": 4, "cooldown": 6.0},
					{"name": "自毁倒计时", "type": "enrage", "timer": 30.0}
				]
			}
		],
		"rewards": {"gold": 500, "exp": 700, "items": ["mech_core", "gear_sword"]}
	}

	# 虚空巨兽
	bosses["void_leviathan"] = {
		"id": "void_leviathan", "name": "虚空巨兽", "title": "深渊之主",
		"theme": "abyss", "health": 1800,
		"color": Color(0.3, 0.1, 0.5), "size": Vector2(80, 60),
		"phases": [
			{
				"health_threshold": 1.0, "name": "暗涌",
				"speed": 50, "damage": 30,
				"attacks": [
					{"name": "虚空触手", "type": "homing", "damage": 20, "count": 8, "cooldown": 3.0, "effect": "pull"},
					{"name": "黑暗侵蚀", "type": "aoe", "damage": 15, "radius": 180, "cooldown": 4.0, "effect": "weaken"},
					{"name": "召唤暗影", "type": "summon", "enemy": "shadow_crawler", "count": 3, "cooldown": 8.0}
				]
			},
			{
				"health_threshold": 0.4, "name": "虚空吞噬",
				"speed": 65, "damage": 40,
				"attacks": [
					{"name": "黑洞", "type": "ground_target", "damage": 25, "radius": 150, "cooldown": 5.0, "effect": "pull", "duration": 3.0},
					{"name": "次元裂缝", "type": "wall", "damage": 30, "width": 500, "cooldown": 4.0},
					{"name": "湮灭之光", "type": "beam", "damage": 20, "duration": 4.0, "cooldown": 6.0}
				]
			}
		],
		"rewards": {"gold": 600, "exp": 800, "items": ["void_crystal", "abyss_cloak"]}
	}

	# 风暴巨龙
	bosses["storm_dragon"] = {
		"id": "storm_dragon", "name": "风暴巨龙", "title": "天空之王",
		"theme": "sky_island", "health": 2000,
		"color": Color(0.4, 0.6, 0.9), "size": Vector2(90, 60),
		"phases": [
			{
				"health_threshold": 1.0, "name": "翱翔",
				"speed": 120, "damage": 28,
				"attacks": [
					{"name": "闪电吐息", "type": "cone", "damage": 22, "angle": 45, "range": 300, "cooldown": 2.5, "effect": "stun"},
					{"name": "风暴之翼", "type": "aoe", "damage": 15, "radius": 250, "cooldown": 4.0, "effect": "knockback"},
					{"name": "召唤雷鸟", "type": "summon", "enemy": "cave_bat", "count": 5, "cooldown": 7.0}
				]
			},
			{
				"health_threshold": 0.5, "name": "风暴降临",
				"speed": 150, "damage": 38,
				"attacks": [
					{"name": "天降雷霆", "type": "multi_aoe", "damage": 35, "count": 10, "interval": 0.2, "cooldown": 5.0, "effect": "stun"},
					{"name": "龙卷风", "type": "ground_target", "damage": 20, "radius": 100, "cooldown": 4.0, "effect": "launch", "duration": 3.0},
					{"name": "狂风暴雨", "type": "aoe", "damage": 10, "radius": 500, "cooldown": 8.0, "effect": "slow", "duration": 5.0}
				]
			}
		],
		"rewards": {"gold": 700, "exp": 900, "items": ["dragon_wing", "storm_amulet"]}
	}

	# 巫妖王
	bosses["lich_king"] = {
		"id": "lich_king", "name": "巫妖王", "title": "亡者之主",
		"theme": "cemetery", "health": 1500,
		"color": Color(0.3, 0.4, 0.6), "size": Vector2(45, 55),
		"phases": [
			{
				"health_threshold": 1.0, "name": "复苏",
				"speed": 50, "damage": 24,
				"attacks": [
					{"name": "亡灵弹幕", "type": "spread_shot", "damage": 12, "count": 10, "cooldown": 2.0, "effect": "slow"},
					{"name": "召唤亡灵", "type": "summon", "enemy": "skeleton", "count": 4, "cooldown": 6.0},
					{"name": "灵魂虹吸", "type": "beam", "damage": 15, "duration": 3.0, "cooldown": 5.0, "heal_percent": 0.5}
				]
			},
			{
				"health_threshold": 0.5, "name": "亡灵大军",
				"speed": 40, "damage": 32,
				"attacks": [
					{"name": "亡者苏醒", "type": "summon", "enemy": "skeleton", "count": 8, "cooldown": 8.0},
					{"name": "死亡凋零", "type": "aoe", "damage": 20, "radius": 300, "cooldown": 5.0, "effect": "weaken"},
					{"name": "灵魂风暴", "type": "multi_aoe", "damage": 18, "count": 6, "interval": 0.5, "cooldown": 6.0}
				]
			},
			{
				"health_threshold": 0.2, "name": "不朽形态",
				"speed": 60, "damage": 40,
				"attacks": [
					{"name": "死亡之触", "type": "melee_aoe", "damage": 50, "radius": 100, "cooldown": 3.0},
					{"name": "亡灵大军", "type": "summon", "enemy": "ghost", "count": 5, "cooldown": 5.0},
					{"name": "灵魂容器", "type": "heal", "amount": 200, "cooldown": 15.0}
				]
			}
		],
		"rewards": {"gold": 500, "exp": 750, "items": ["lich_crown", "death_scythe"]}
	}
