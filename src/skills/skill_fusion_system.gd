## Void Hunter - 技能融合系统 V2
## @description: 25+种技能融合配方，元素组合、弹幕融合、终极组合
## @version: 2.0.0

extends Node

# =============================================================================
# 信号
# =============================================================================

signal fusion_available(fusion_id: String, fusion_data: Dictionary)
signal fusion_lost(fusion_id: String)
signal fusion_executed(fusion_id: String, damage: float)
signal fusion_list_changed(fusions: Array[Dictionary])

# =============================================================================
# 融合配方数据
# =============================================================================

class FusionRecipe:
	var id: String
	var name: String
	var description: String
	var required_skills: Array[String] = []
	var cooldown: float = 10.0
	var mana_cost: float = 30.0
	var damage: float = 30.0
	var rarity: int = 0  ## 0=普通, 1=稀有, 2=史诗, 3=传说
	var bonuses: Dictionary = {}
	var category: String = "element"  ## element, bullet, defense, control, ultimate

	func _init(p_id: String, p_name: String) -> void:
		id = p_id
		name = p_name

# =============================================================================
# 公共变量
# =============================================================================

var recipes: Dictionary = {}
var active_fusions: Array[String] = []
var player_skills: Array[String] = []
var _owner: Node = null

# =============================================================================
# 初始化
# =============================================================================

func initialize(owner: Node) -> void:
	_owner = owner
	_register_all_fusions()

# =============================================================================
# 公共方法
# =============================================================================

## 更新玩家技能列表
func update_skills(skills: Array[String]) -> void:
	player_skills = skills
	_check_fusions()

## 检查融合是否可用
func is_fusion_available(fusion_id: String) -> bool:
	return fusion_id in active_fusions

## 获取所有可用融合
func get_available_fusions() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for fusion_id in active_fusions:
		var recipe: FusionRecipe = recipes[fusion_id]
		result.append({
			"id": recipe.id,
			"name": recipe.name,
			"description": recipe.description,
			"cooldown": recipe.cooldown,
			"mana_cost": recipe.mana_cost,
			"damage": recipe.damage,
			"rarity": recipe.rarity,
			"category": recipe.category
		})
	return result

## 获取融合加成总计
func get_fusion_bonuses() -> Dictionary:
	var bonuses := {
		"damage_multiplier": 1.0,
		"defense_multiplier": 1.0,
		"speed_multiplier": 1.0,
		"cooldown_reduction": 0.0,
		"critical_chance_bonus": 0.0,
	}
	for fusion_id in active_fusions:
		var recipe: FusionRecipe = recipes[fusion_id]
		for key in recipe.bonuses.keys():
			if bonuses.has(key):
				bonuses[key] += recipe.bonuses[key]
	return bonuses

## 执行融合技能
func execute_fusion(fusion_id: String, target_pos: Vector2 = Vector2.ZERO) -> bool:
	if not fusion_id in active_fusions:
		return false
	if _owner == null:
		return false

	var recipe: FusionRecipe = recipes[fusion_id]

	# 检查法力
	if _owner.has_method("consume_mana"):
		if not _owner.consume_mana(recipe.mana_cost):
			return false

	# 执行效果
	_execute_fusion_effect(fusion_id, recipe, target_pos)
	fusion_executed.emit(fusion_id, recipe.damage)
	return true

# =============================================================================
# 融合检测
# =============================================================================

func _check_fusions() -> void:
	var new_fusions: Array[String] = []

	for fusion_id in recipes.keys():
		var recipe: FusionRecipe = recipes[fusion_id]
		var satisfied := true
		for skill_id in recipe.required_skills:
			if skill_id not in player_skills:
				satisfied = false
				break

		if satisfied:
			new_fusions.append(fusion_id)
			if fusion_id not in active_fusions:
				fusion_available.emit(fusion_id, {
					"name": recipe.name,
					"description": recipe.description
				})

	# 检查失去的融合
	for old_fusion in active_fusions:
		if old_fusion not in new_fusions:
			fusion_lost.emit(old_fusion)

	active_fusions = new_fusions
	fusion_list_changed.emit(get_available_fusions())

# =============================================================================
# 融合效果执行
# =============================================================================

func _execute_fusion_effect(fusion_id: String, recipe: FusionRecipe, target_pos: Vector2) -> void:
	if _owner == null:
		return

	var center: Variant = target_pos if target_pos != Vector2.ZERO else _owner.global_position

	match fusion_id:
		# === 元素融合 ===
		"fusion_frostfire":
			_aoe_damage(center, 150.0, recipe.damage, Color(0.5, 0.3, 1.0))
			_apply_aoe_status(center, 150.0, "burn", 3.0, 5.0)
			_apply_aoe_status(center, 150.0, "freeze", 0.5, 2.0)
		"fusion_plasma_storm":
			_multi_projectile(center, 12, recipe.damage, Color(1.0, 0.7, 0.3), 400.0)
		"fusion_shadow_flame":
			_piercing_beam(center, recipe.damage, Color(0.8, 0.2, 0.5), 500.0)
		"fusion_ice_lightning":
			_chain_lightning(center, recipe.damage, 6, Color(0.5, 0.8, 1.0))
			_apply_aoe_status(center, 200.0, "freeze", 0.3, 1.5)
		"fusion_holy_shadow":
			_aoe_damage(center, 200.0, recipe.damage, Color(0.7, 0.3, 0.9))
			_heal_owner(recipe.damage * 0.3)
		"fusion_void_fire":
			_black_hole(center, 180.0, recipe.damage, 3.0)
		"fusion_chaos_bolt":
			_chaos_barrage(center, 8, recipe.damage)
		"fusion_elemental_storm":
			_elemental_rain(center, 300.0, recipe.damage, 5.0)
		"fusion_nature_curse":
			_apply_aoe_status(center, 200.0, "poison", 5.0, 8.0)
			_apply_aoe_status(center, 200.0, "slow", 0.4, 4.0)

		# === 弹幕融合 ===
		"fusion_homing_fan":
			_fan_homing(center, 9, recipe.damage, 60.0)
		"fusion_circular_storm":
			_circular_barrage(center, 20, recipe.damage, Color(0.5, 0.8, 1.0))
		"fusion_destruction_ray":
			_destruction_beam(center, recipe.damage, 8, 2.0)
		"fusion_pierce_bounce":
			_pierce_bounce_shot(center, recipe.damage)
		"fusion_explosive_spiral":
			_spiral_explosive(center, recipe.damage)
		"fusion_void_volley":
			_void_volley(center, 12, recipe.damage)

		# === 防御融合 ===
		"fusion_mirror_shield":
			_apply_owner_buff("invincible", 3.0)
			_apply_owner_buff("shield", 100.0)
		"fusion_iron_blink":
			_blink_with_damage(center, recipe.damage)
		"fusion_reflect_aura":
			_apply_owner_buff("reflect", 5.0)
		"fusion_stealth_strike":
			_apply_owner_buff("invincible", 2.0)
			_aoe_damage(center, 120.0, recipe.damage * 1.5, Color(0.5, 0.2, 0.8))

		# === 控制融合 ===
		"fusion_space_hole":
			_black_hole(center, 200.0, recipe.damage, 4.0)
		"fusion_gravity_bomb":
			_gravity_bomb(center, recipe.damage, 3.0)
		"fusion_divine_blessing":
			_heal_owner(_owner.max_health * 0.3 if "max_health" in _owner else 50.0)
			_apply_owner_buff("haste", 0.3)
			_apply_owner_buff("power_up", 0.3)

		# === 终极融合 ===
		"fusion_ultimate_judgment":
			_ultimate_judgment(center, recipe.damage)
		"fusion_apocalypse":
			_apocalypse(center, recipe.damage)
		"fusion_void_collapse":
			_void_collapse(center, recipe.damage)

# =============================================================================
# 效果实现
# =============================================================================

func _aoe_damage(center: Vector2, radius: float, damage: float, color: Color) -> void:
	var enemies := _get_enemies_in_radius(center, radius)
	for enemy in enemies:
		if enemy.has_method("take_damage"):
			enemy.take_damage(damage, _owner)
	_spawn_aoe_visual(center, radius, color)

func _multi_projectile(center: Vector2, count: int, damage: float, color: Color, speed: float) -> void:
	for i in range(count):
		var angle := (TAU / count) * i
		_spawn_bullet(center, Vector2(cos(angle), sin(angle)), damage, speed, color)

func _piercing_beam(origin: Vector2, damage: float, color: Color, length: float) -> void:
	var dir := Vector2.RIGHT
	if _owner and "aim_direction" in _owner:
		dir = _owner.aim_direction
	var end := origin + dir * length
	var enemies := _get_enemies_in_line(origin, end, 20.0)
	for enemy in enemies:
		if enemy.has_method("take_damage"):
			enemy.take_damage(damage, _owner)
	_spawn_beam_visual(origin, end, color)

func _chain_lightning(center: Vector2, damage: float, chains: int, color: Color) -> void:
	var enemies := _get_enemies_in_radius(center, 250.0)
	var hit: Array[Node] = []
	var current_source: Node = null
	var remaining := chains
	while remaining > 0 and enemies.size() > hit.size():
		var target: Node = null
		var best_dist: float = 999.0
		for enemy in enemies:
			if enemy in hit:
				continue
			var dist: Variant = center.distance_to(enemy.global_position) if current_source == null else current_source.global_position.distance_to(enemy.global_position)
			if dist < best_dist:
				best_dist = dist
				target = enemy
		if target == null:
			break
		if target.has_method("take_damage"):
			target.take_damage(damage * (0.8 ** (chains - remaining)), _owner)
		hit.append(target)
		current_source = target
		remaining -= 1

func _black_hole(center: Vector2, radius: float, damage: float, duration: float) -> void:
	# 创建黑洞节点
	var bh := Node2D.new()
	bh.global_position = center
	bh.name = "BlackHole"

	var sprite := Sprite2D.new()
	var tex := ImageTexture.new()
	var img := Image.create(40, 40, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.2, 0.1, 0.4, 0.8))
	tex.set_image(img)
	sprite.texture = tex
	bh.add_child(sprite)

	get_tree().current_scene.add_child(bh)

	# 持续吸引和伤害
	var timer := 0.0
	while timer < duration:
		await get_tree().create_timer(0.1).timeout
		timer += 0.1
		var enemies := _get_enemies_in_radius(center, radius)
		for enemy in enemies:
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage * 0.1, _owner)
			# 拉向中心
			if "velocity" in enemy:
				var pull_dir: Variant = (center - enemy.global_position).normalized()
				enemy.velocity += pull_dir * 50.0

	# 淡出
	var tween := bh.create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
	tween.tween_callback(bh.queue_free)

func _fan_homing(center: Vector2, count: int, damage: float, spread: float) -> void:
	for i in range(count):
		var angle := deg_to_rad(-spread / 2.0 + (spread / (count - 1)) * i)
		_spawn_homing_bullet(center, Vector2(cos(angle), sin(angle)), damage, 400.0)

func _circular_barrage(center: Vector2, count: int, damage: float, color: Color) -> void:
	for i in range(count):
		var angle := (TAU / count) * i
		_spawn_bullet(center, Vector2(cos(angle), sin(angle)), damage, 350.0, color)

func _destruction_beam(center: Vector2, damage: float, beam_count: int, duration: float) -> void:
	for i in range(beam_count):
		var angle := (TAU / beam_count) * i
		var end := center + Vector2(cos(angle), sin(angle)) * 500.0
		_spawn_beam_visual(center, end, Color(1.0, 0.3, 0.3, 0.6))

	var enemies := _get_enemies_in_radius(center, 500.0)
	for enemy in enemies:
		if enemy.has_method("take_damage"):
			enemy.take_damage(damage, _owner)

func _heal_owner(amount: float) -> void:
	if _owner and _owner.has_method("heal"):
		_owner.heal(amount)

func _apply_aoe_status(center: Vector2, radius: float, status_type: String, value: float, duration: float) -> void:
	var status_mgr := _get_status_manager()
	if status_mgr == null:
		return
	var enemies := _get_enemies_in_radius(center, radius)
	for enemy in enemies:
		match status_type:
			"burn":
				status_mgr.apply_burn(enemy, value, duration, _owner)
			"freeze":
				status_mgr.apply_freeze(enemy, value, duration, _owner)
			"slow":
				status_mgr.apply_slow(enemy, value, duration, _owner)
			"poison":
				status_mgr.apply_poison(enemy, value, duration, _owner)
			"stun":
				status_mgr.apply_stun(enemy, duration, _owner)

func _apply_owner_buff(buff_type: String, value: float) -> void:
	var status_mgr := _get_status_manager()
	if status_mgr == null:
		return
	match buff_type:
		"invincible":
			status_mgr.apply_invincible(_owner, 3.0, _owner)
		"shield":
			status_mgr.apply_shield(_owner, value, _owner)
		"reflect":
			status_mgr.apply_status(_owner, 0, 5.0, 0.0, 0.0, 1, _owner)  # custom reflect
		"haste":
			status_mgr.apply_haste(_owner, value, 8.0, _owner)
		"power_up":
			status_mgr.apply_power_up(_owner, value, 8.0, _owner)

func _blink_with_damage(center: Vector2, damage: float) -> void:
	if _owner:
		var dir := Vector2.RIGHT
		if "aim_direction" in _owner:
			dir = _owner.aim_direction
		_owner.global_position += dir * 200.0
		_aoe_damage(_owner.global_position, 80.0, damage, Color(0.3, 0.6, 1.0))

func _chaos_barrage(center: Vector2, count: int, damage: float) -> void:
	var colors := [Color(1.0, 0.4, 0.1), Color(0.5, 0.8, 1.0), Color(1.0, 1.0, 0.4), Color(0.5, 0.3, 0.8)]
	for i in range(count):
		var angle := randf() * TAU
		_spawn_bullet(center, Vector2(cos(angle), sin(angle)), damage, 350.0, colors[i % colors.size()])

func _elemental_rain(center: Vector2, radius: float, damage: float, duration: float) -> void:
	var timer := 0.0
	while timer < duration:
		await get_tree().create_timer(0.3).timeout
		timer += 0.3
		var pos := center + Vector2(randf_range(-radius, radius), randf_range(-radius, radius))
		_aoe_damage(pos, 40.0, damage, Color(randf(), randf(), randf()))

func _gravity_bomb(center: Vector2, damage: float, duration: float) -> void:
	_black_hole(center, 120.0, damage * 0.5, duration)

func _ultimate_judgment(center: Vector2, damage: float) -> void:
	# 全屏闪白
	var flash := ColorRect.new()
	flash.color = Color(1, 1, 1, 0.8)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.z_index = 100
	get_tree().current_scene.add_child(flash)
	var tween := flash.create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.5)
	tween.tween_callback(flash.queue_free)

	# 全屏伤害
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.has_method("take_damage"):
			enemy.take_damage(damage, _owner)

func _apocalypse(center: Vector2, damage: float) -> void:
	# 多波AOE
	for wave in range(5):
		var radius := 100.0 + wave * 80.0
		_aoe_damage(center, radius, damage * (0.7 ** wave), Color(1.0, 0.3 + wave * 0.1, 0.1))
		await get_tree().create_timer(0.3).timeout

func _void_collapse(center: Vector2, damage: float) -> void:
	# 吸入 -> 爆炸
	_black_hole(center, 200.0, damage * 0.3, 2.0)
	await get_tree().create_timer(2.0).timeout
	_aoe_damage(center, 300.0, damage, Color(0.5, 0.2, 0.8))

func _pierce_bounce_shot(center: Vector2, damage: float) -> void:
	for i in range(3):
		var angle := randf() * TAU
		_spawn_bullet(center, Vector2(cos(angle), sin(angle)), damage, 500.0, Color(1.0, 1.0, 0.5))

func _spiral_explosive(center: Vector2, damage: float) -> void:
	for i in range(16):
		var angle := (TAU / 16.0) * i + Time.get_ticks_msec() * 0.001
		var bullet := _spawn_bullet(center, Vector2(cos(angle), sin(angle)), damage * 0.5, 300.0, Color(1.0, 0.5, 0.2))
		await get_tree().create_timer(0.05).timeout

func _void_volley(center: Vector2, count: int, damage: float) -> void:
	for i in range(count):
		var angle := (TAU / count) * i
		_spawn_bullet(center, Vector2(cos(angle), sin(angle)), damage, 450.0, Color(0.4, 0.2, 0.7))

# =============================================================================
# 视觉/工具
# =============================================================================

func _spawn_aoe_visual(center: Vector2, radius: float, color: Color) -> void:
	var visual := Node2D.new()
	visual.global_position = center
	var sprite := Sprite2D.new()
	var tex := ImageTexture.new()
	var img := Image.create(int(radius * 2), int(radius * 2), false, Image.FORMAT_RGBA8)
	img.fill(Color(color.r, color.g, color.b, 0.4))
	tex.set_image(img)
	sprite.texture = tex
	visual.add_child(sprite)
	get_tree().current_scene.add_child(visual)
	var tween := visual.create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
	tween.tween_callback(visual.queue_free)

func _spawn_beam_visual(start: Vector2, end: Vector2, color: Color) -> void:
	var line := Line2D.new()
	line.add_point(start)
	line.add_point(end)
	line.width = 8.0
	line.default_color = color
	line.z_index = 10
	get_tree().current_scene.add_child(line)
	var tween := line.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.3)
	tween.tween_callback(line.queue_free)

func _spawn_bullet(origin: Vector2, direction: Vector2, damage: float, speed: float, color: Color) -> Node:
	var bullet := Area2D.new()
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 6.0
	collision.shape = shape
	bullet.add_child(collision)

	var sprite := Sprite2D.new()
	var tex := ImageTexture.new()
	var img := Image.create(12, 12, false, Image.FORMAT_RGBA8)
	img.fill(color)
	tex.set_image(img)
	sprite.texture = tex
	bullet.add_child(sprite)

	bullet.global_position = origin
	bullet.collision_layer = 4
	bullet.collision_mask = 2 | 16

	# 简单移动脚本
	var script := GDScript.new()
	script.source_code = """
extends Area2D
var direction: Vector2 = Vector2.RIGHT
var speed: float = 400.0
var damage: float = 20.0
var owner_node: Node = null
var lifetime: float = 3.0
func _ready():
	body_entered.connect(_on_hit)
	area_entered.connect(_on_area_hit)
func _physics_process(delta):
	lifetime -= delta
	if lifetime <= 0: queue_free()
	position += direction * speed * delta
func _on_hit(body):
	if body.has_method("take_damage") and body != owner_node:
		body.take_damage(damage, owner_node)
	queue_free()
func _on_area_hit(area):
	var p = area.get_parent()
	if p and p.has_method("take_damage") and p != owner_node:
		p.take_damage(damage, owner_node)
	queue_free()
"""
	script.reload()
	bullet.set_script(script)
	bullet.set("direction", direction)
	bullet.set("speed", speed)
	bullet.set("damage", damage)
	bullet.set("owner_node", _owner)
	bullet.set("lifetime", 3.0)

	get_tree().current_scene.add_child(bullet)
	return bullet

func _spawn_homing_bullet(origin: Vector2, direction: Vector2, damage: float, speed: float) -> void:
	_spawn_bullet(origin, direction, damage, speed, Color(1.0, 0.7, 0.3))

func _get_enemies_in_radius(center: Vector2, radius: float) -> Array[Node]:
	var result: Array[Node] = []
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.global_position.distance_to(center) <= radius:
			result.append(enemy)
	return result

func _get_enemies_in_line(start: Vector2, end: Vector2, width: float) -> Array[Node]:
	var result: Array[Node] = []
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist := _point_line_distance(enemy.global_position, start, end)
		if dist <= width:
			result.append(enemy)
	return result

func _point_line_distance(point: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var ap := point - a
	var len_sq := ab.length_squared()
	if len_sq == 0:
		return ap.length()
	var t := clampf(ap.dot(ab) / len_sq, 0.0, 1.0)
	return point.distance_to(a + t * ab)

func _get_status_manager() -> Node:
	if _owner:
		var scene := _owner.get_tree().current_scene
		if scene:
			return scene.get_node_or_null("StatusEffectManager")
	return null

# =============================================================================
# 融合注册 (25+种)
# =============================================================================

func _register_all_fusions() -> void:
	# === 元素融合 (10种) ===
	_reg("fusion_frostfire", "霜火爆破", "火焰+冰霜=霜冻爆炸，燃烧+减速双重效果",
		["fire_bullet", "frost_arrow"], 12.0, 25.0, 35.0, 1, {"damage_multiplier": 0.15}, "element")
	_reg("fusion_plasma_storm", "等离子风暴", "火焰+闪电=等离子风暴，圆形弹幕",
		["fire_bullet", "lightning_chain"], 10.0, 30.0, 28.0, 2, {"damage_multiplier": 0.2}, "element")
	_reg("fusion_shadow_flame", "暗影烈焰", "暗影+火焰=穿透暗影火线",
		["shadow_slash", "fire_bullet"], 8.0, 20.0, 40.0, 1, {"critical_chance_bonus": 0.1}, "element")
	_reg("fusion_ice_lightning", "冰雷冲击", "冰霜+闪电=冰雷链，连锁+冻结",
		["frost_arrow", "lightning_chain"], 11.0, 28.0, 32.0, 1, {"damage_multiplier": 0.12}, "element")
	_reg("fusion_holy_shadow", "圣暗裁决", "神圣+暗影=圣暗之光，伤害+自我治疗",
		["holy_bullet", "shadow_bullet"], 15.0, 35.0, 45.0, 2, {"defense_multiplier": 0.15}, "element")
	_reg("fusion_void_fire", "虚空熔毁", "虚空+火焰=黑洞火焰，吸引+燃烧",
		["void_bullet", "fire_bullet"], 18.0, 40.0, 50.0, 2, {"damage_multiplier": 0.25}, "element")
	_reg("fusion_chaos_bolt", "混沌弹幕", "混沌元素=随机彩虹弹幕",
		["chaos_bullet", "rainbow_bullet"], 14.0, 35.0, 55.0, 3, {"damage_multiplier": 0.3}, "element")
	_reg("fusion_elemental_storm", "元素风暴", "多元素=持续范围元素雨",
		["fire_bullet", "frost_arrow", "lightning_chain"], 25.0, 50.0, 60.0, 3, {"damage_multiplier": 0.35}, "element")
	_reg("fusion_nature_curse", "自然诅咒", "毒素+奥术=大范围毒素减速",
		["poison_bullet", "arcane_bullet"], 10.0, 22.0, 25.0, 1, {"cooldown_reduction": 0.08}, "element")
	_reg("fusion_ice_shadow", "冰暗之握", "冰霜+暗影=冰暗陷阱",
		["frost_arrow", "shadow_bullet"], 12.0, 25.0, 38.0, 1, {"critical_chance_bonus": 0.12}, "element")

	# === 弹幕融合 (6种) ===
	_reg("fusion_homing_fan", "追踪扇形", "扇形弹幕+追踪=全追踪扇形",
		["fan_shot", "homing_missile"], 8.0, 25.0, 25.0, 1, {"damage_multiplier": 0.15}, "bullet")
	_reg("fusion_circular_storm", "雷电风暴", "圆形弹幕+闪电=雷电圆形弹幕",
		["circular_burst", "lightning_storm"], 10.0, 30.0, 22.0, 1, {"critical_chance_bonus": 0.1}, "bullet")
	_reg("fusion_destruction_ray", "毁灭光线", "激光+全屏=旋转毁灭激光",
		["laser_beam", "screen_nuke"], 30.0, 80.0, 50.0, 3, {"damage_multiplier": 0.35}, "bullet")
	_reg("fusion_pierce_bounce", "穿跳弹", "穿透+反弹=超级子弹",
		["pierce_shot", "bounce_shot"], 6.0, 18.0, 30.0, 1, {"damage_multiplier": 0.12}, "bullet")
	_reg("fusion_explosive_spiral", "螺旋爆破", "螺旋+爆炸弹=螺旋爆炸弹幕",
		["spiral_shot", "explosive_shot"], 12.0, 30.0, 35.0, 2, {"damage_multiplier": 0.18}, "bullet")
	_reg("fusion_void_volley", "虚空齐射", "虚空弹+散射=虚空散射",
		["void_bullet", "spread_shot"], 8.0, 22.0, 28.0, 1, {"damage_multiplier": 0.1}, "bullet")

	# === 防御融合 (4种) ===
	_reg("fusion_mirror_shield", "镜像护盾", "护盾+反射=无敌护盾",
		["shield", "reflect"], 15.0, 30.0, 0.0, 2, {"defense_multiplier": 0.25}, "defense")
	_reg("fusion_iron_blink", "铁壁闪现", "铁壁+闪现=冲撞伤害",
		["iron_wall", "blink"], 10.0, 25.0, 35.0, 1, {"speed_multiplier": 0.1}, "defense")
	_reg("fusion_reflect_aura", "荆棘光环", "反射+护盾=持续反弹光环",
		["reflect", "shield"], 18.0, 35.0, 0.0, 2, {"defense_multiplier": 0.2}, "defense")
	_reg("fusion_stealth_strike", "暗影突袭", "隐身+冲撞=无敌突袭",
		["invisibility", "dash_attack"], 12.0, 30.0, 45.0, 2, {"critical_chance_bonus": 0.2}, "defense")

	# === 控制融合 (3种) ===
	_reg("fusion_space_hole", "时空黑洞", "时间减缓+引力场=时空黑洞",
		["time_slow", "gravity_field"], 20.0, 45.0, 15.0, 2, {"cooldown_reduction": 0.1}, "control")
	_reg("fusion_gravity_bomb", "引力炸弹", "引力场+黑洞=引力脉冲",
		["gravity_field", "black_hole"], 16.0, 35.0, 30.0, 2, {"cooldown_reduction": 0.08}, "control")
	_reg("fusion_divine_blessing", "神圣祝福", "治愈光环+加速光环=全属性增益",
		["healing_aura", "speed_aura"], 20.0, 40.0, 0.0, 2, {"speed_multiplier": 0.15}, "control")

	# === 终极融合 (3种) ===
	_reg("fusion_ultimate_judgment", "终极裁决", "三种弹幕=全屏毁灭",
		["fan_shot", "circular_burst", "laser_beam"], 60.0, 100.0, 100.0, 3, {"damage_multiplier": 0.5}, "ultimate")
	_reg("fusion_apocalypse", "天启", "终极攻击组合=毁灭波",
		["screen_nuke", "lightning_storm", "homing_missile"], 60.0, 100.0, 80.0, 3, {"damage_multiplier": 0.45}, "ultimate")
	_reg("fusion_void_collapse", "虚空崩塌", "虚空+混沌=吸入+爆炸",
		["void_bullet", "chaos_bullet", "time_stop"], 60.0, 100.0, 120.0, 3, {"damage_multiplier": 0.55}, "ultimate")

func _reg(id: String, name: String, desc: String, skills: Array[String], \
		cd: float, mana: float, dmg: float, rarity: int, bonuses: Dictionary, cat: String) -> void:
	var recipe := FusionRecipe.new(id, name)
	recipe.description = desc
	recipe.required_skills = skills
	recipe.cooldown = cd
	recipe.mana_cost = mana
	recipe.damage = dmg
	recipe.rarity = rarity
	recipe.bonuses = bonuses
	recipe.category = cat
	recipes[id] = recipe
