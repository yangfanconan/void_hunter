## Void Hunter - Boss基类
## @description: 所有Boss的基类，实现多阶段技能、特殊机制
## @version: 1.0.0

extends "res://src/enemies/enemy_base.gd"

# =============================================================================
# 信号定义
# =============================================================================

## 阶段变化时触发
signal phase_changed(new_phase: int)

## 特殊技能使用时触发
signal special_skill_used(skill_id: String)

## Boss被击败时触发
signal boss_defeated()

# =============================================================================
# 常量定义
# =============================================================================

## 默认Boss生命值
const DEFAULT_BOSS_HEALTH: float = 500.0

## 默认Boss伤害
const DEFAULT_BOSS_DAMAGE: float = 25.0

## 阶段转换生命值阈值
const PHASE_THRESHOLDS: Array[float] = [0.75, 0.5, 0.25]

# =============================================================================
# 枚举定义
# =============================================================================

## Boss阶段
enum BossPhase {
	PHASE_1,	## 第一阶段
	PHASE_2,	## 第二阶段
	PHASE_3,	## 第三阶段
	PHASE_4,	## 最终阶段
}

## Boss技能类型
enum BossSkillType {
	CHARGE,		## 冲锋
	AOE,		## 范围攻击
	SUMMON,		## 召唤
	PROJECTILE,	## 弹幕
	BEAM,		## 光束
	SHOCKWAVE,	## 冲击波
}

# =============================================================================
# 导出变量
# =============================================================================

## Boss名称
@export var boss_name: String = "Unknown Boss"

## Boss阶段数
@export var max_phases: int = 3

## 特殊技能冷却
@export var special_skill_cooldown: float = 5.0

## 是否启用场地变化
@export var enable_arena_changes: bool = true

# =============================================================================
# 公共变量
# =============================================================================

## 当前阶段
var current_phase: BossPhase = BossPhase.PHASE_1

## 当前阶段索引
var phase_index: int = 0

## 技能冷却计时器
var skill_timer: float = 0.0

## 是否正在释放技能
var is_casting: bool = false

## Boss专属掉落
var boss_drops: Array[Dictionary] = []

# =============================================================================
# 私有变量
# =============================================================================

var _phase_thresholds: Array[float] = []
var _special_skills: Array[Dictionary] = []
var _current_skill_index: int = 0
var _arena_hazards: Array[Node] = []

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	super._ready()
	_setup_boss()

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return

	# 更新技能冷却
	if not is_casting:
		skill_timer -= delta
		if skill_timer <= 0:
			_try_use_special_skill()

	# 检查阶段转换
	_check_phase_transition()

	# 调用父类物理处理
	super._physics_process(delta)

# =============================================================================
# 公共方法
# =============================================================================

## 初始化Boss
func setup_boss(level: int = 1) -> void:
	_setup_boss()
	apply_wave_scaling(level)

## 强制进入下一阶段
func advance_phase() -> void:
	if phase_index < max_phases - 1:
		_transition_to_phase(phase_index + 1)

## 获取Boss信息
func get_boss_info() -> Dictionary:
	return {
		"name": boss_name,
		"phase": phase_index + 1,
		"max_phases": max_phases,
		"health_percent": get_health_percent(),
		"is_casting": is_casting,
	}

# =============================================================================
# 私有方法 - 初始化
# =============================================================================

func _setup_boss() -> void:
	# 设置Boss基础属性
	enemy_type = EnemyType.BOSS
	max_health = DEFAULT_BOSS_HEALTH
	attack_damage = DEFAULT_BOSS_DAMAGE
	attack_range = 80.0
	detection_range = 1500.0

	# 初始化阶段阈值
	_setup_phase_thresholds()

	# 初始化技能列表
	_setup_special_skills()

	# 初始化掉落
	_setup_boss_drops()

	# 设置更大的碰撞
	_setup_boss_collision()

	print("[Boss] %s 初始化完成" % boss_name)

func _setup_phase_thresholds() -> void:
	_phase_thresholds.clear()
	for i in range(max_phases - 1):
		var threshold: float = 1.0 - (float(i + 1) / float(max_phases))
		_phase_thresholds.append(threshold)

func _setup_special_skills() -> void:
	# 子类重写此方法添加专属技能
	_special_skills.clear()

func _setup_boss_drops() -> void:
	# 子类重写此方法设置专属掉落
	boss_drops.clear()

func _setup_boss_collision() -> void:
	# 确保有碰撞形状
	for child in get_children():
		if child is CollisionShape2D:
			var shape = child.shape
			if shape is CircleShape2D:
				shape.radius = 24.0
			break

# =============================================================================
# 私有方法 - 阶段转换
# =============================================================================

func _check_phase_transition() -> void:
	if phase_index >= max_phases - 1:
		return

	var health_percent: float = get_health_percent()
	var next_threshold: float = _phase_thresholds[phase_index] if phase_index < _phase_thresholds.size() else 0.0

	if health_percent <= next_threshold:
		_transition_to_phase(phase_index + 1)

func _transition_to_phase(new_phase_index: int) -> void:
	var old_phase: BossPhase = current_phase
	phase_index = new_phase_index

	# 更新阶段枚举
	match phase_index:
		0: current_phase = BossPhase.PHASE_1
		1: current_phase = BossPhase.PHASE_2
		2: current_phase = BossPhase.PHASE_3
		3: current_phase = BossPhase.PHASE_4

	# 触发信号
	phase_changed.emit(phase_index + 1)

	# 阶段转换效果
	_play_phase_transition_effect()

	# 场地变化
	if enable_arena_changes:
		_modify_arena(new_phase_index)

	# 属性提升
	_boost_stats_for_phase(new_phase_index)

	print("[Boss] %s 进入第 %d 阶段" % [boss_name, phase_index + 1])

func _play_phase_transition_effect() -> void:
	# 无敌帧
	is_invincible = true

	# 屏幕震动效果
	var main = get_tree().current_scene
	if main:
		var camera = main.get_node_or_null("Camera2D")
		if camera:
			var tween := camera.create_tween()
			tween.tween_property(camera, "offset", Vector2(10, 0), 0.05)
			tween.tween_property(camera, "offset", Vector2(-10, 0), 0.05)
			tween.tween_property(camera, "offset", Vector2(0, 0), 0.05)

	# 闪光效果
	var flash := ColorRect.new()
	flash.color = Color(1, 1, 1, 0.5)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.z_index = 100
	get_tree().current_scene.add_child(flash)

	var tween := flash.create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.3)
	tween.tween_callback(func(): is_invincible = false)
	tween.tween_callback(flash.queue_free)

func _modify_arena(phase: int) -> void:
	# 子类重写此方法实现场地变化
	pass

func _boost_stats_for_phase(phase: int) -> void:
	# 每阶段提升属性
	var attack_boost: float = 1.0 + phase * 0.15
	var speed_boost: float = 1.0 + phase * 0.1

	attack_damage = DEFAULT_BOSS_DAMAGE * attack_boost
	move_speed = DEFAULT_SPEED * speed_boost

# =============================================================================
# 私有方法 - 技能系统
# =============================================================================

func _try_use_special_skill() -> void:
	if _special_skills.is_empty():
		return

	# 选择技能
	var skill: Dictionary = _select_skill()
	if skill.is_empty():
		return

	# 执行技能
	_execute_special_skill(skill)

	# 重置冷却
	skill_timer = special_skill_cooldown

func _select_skill() -> Dictionary:
	if _special_skills.is_empty():
		return {}

	# 根据阶段选择技能池
	var available_skills: Array[Dictionary] = []
	for skill in _special_skills:
		var min_phase: int = skill.get("min_phase", 0)
		if phase_index >= min_phase:
			available_skills.append(skill)

	if available_skills.is_empty():
		return {}

	# 随机选择
	return available_skills[randi() % available_skills.size()]

func _execute_special_skill(skill: Dictionary) -> void:
	is_casting = true

	var skill_type: BossSkillType = skill.get("type", BossSkillType.AOE)
	var skill_id: String = skill.get("id", "unknown")
	var damage: float = skill.get("damage", attack_damage)
	var duration: float = skill.get("duration", 1.0)

	# 播放技能动画
	_play_skill_animation(skill_id)

	# 执行技能效果
	match skill_type:
		BossSkillType.CHARGE:
			await _execute_charge(skill)
		BossSkillType.AOE:
			await _execute_aoe(skill)
		BossSkillType.SUMMON:
			await _execute_summon(skill)
		BossSkillType.PROJECTILE:
			await _execute_projectile(skill)
		BossSkillType.BEAM:
			await _execute_beam(skill)
		BossSkillType.SHOCKWAVE:
			await _execute_shockwave(skill)

	special_skill_used.emit(skill_id)
	is_casting = false

func _play_skill_animation(skill_id: String) -> void:
	_play_animation("skill")
	await get_tree().create_timer(0.5).timeout

# =============================================================================
# 技能执行方法 - 子类可重写
# =============================================================================

func _execute_charge(skill: Dictionary) -> void:
	if player == null or not is_instance_valid(player):
		return

	var direction: Vector2 = (player.global_position - global_position).normalized()
	var charge_speed: float = skill.get("speed", 400.0)
	var charge_distance: float = skill.get("distance", 300.0)

	var start_pos: Vector2 = global_position
	var traveled: float = 0.0

	while traveled < charge_distance:
		var step: float = charge_speed * get_physics_process_delta_time()
		global_position += direction * step
		traveled += step
		await get_tree().physics_frame

	# 冲锋伤害
	var hit_area: float = skill.get("hit_area", 50.0)
	_deal_area_damage(global_position, hit_area, attack_damage * 1.5)

func _execute_aoe(skill: Dictionary) -> void:
	var radius: float = skill.get("radius", 150.0)
	var damage: float = skill.get("damage", attack_damage)
	var delay: float = skill.get("delay", 1.0)

	# 预警区域
	_show_warning_circle(global_position, radius, delay)

	await get_tree().create_timer(delay).timeout

	# 造成伤害
	_deal_area_damage(global_position, radius, damage)

	# 视觉效果
	_spawn_aoe_visual(global_position, radius)

func _execute_summon(skill: Dictionary) -> void:
	var summon_count: int = skill.get("count", 3)
	var summon_type: String = skill.get("enemy_type", "melee")

	for i in range(summon_count):
		var angle: float = (TAU / summon_count) * i
		var distance: float = skill.get("spawn_distance", 100.0)
		var spawn_pos: Vector2 = global_position + Vector2(cos(angle), sin(angle)) * distance

		_spawn_minion(summon_type, spawn_pos)
		await get_tree().create_timer(0.2).timeout

func _execute_projectile(skill: Dictionary) -> void:
	var count: int = skill.get("count", 8)
	var damage: float = skill.get("damage", attack_damage * 0.5)
	var speed: float = skill.get("speed", 300.0)
	var pattern: String = skill.get("pattern", "circular")

	match pattern:
		"circular":
			for i in range(count):
				var angle: float = (TAU / count) * i
				_spawn_boss_projectile(angle, damage, speed)
		"spiral":
			for i in range(count):
				var angle: float = (TAU / count) * i + Time.get_ticks_msec() * 0.003
				_spawn_boss_projectile(angle, damage, speed)
				await get_tree().create_timer(0.1).timeout
		"targeted":
			if player and is_instance_valid(player):
				var base_angle: float = (player.global_position - global_position).angle()
				for i in range(count):
					var spread: float = deg_to_rad(skill.get("spread", 30.0))
					var angle: float = base_angle + randf_range(-spread, spread)
					_spawn_boss_projectile(angle, damage, speed)
					await get_tree().create_timer(0.15).timeout

func _execute_beam(skill: Dictionary) -> void:
	var damage: float = skill.get("damage", attack_damage * 0.3)
	var duration: float = skill.get("duration", 2.0)
	var width: float = skill.get("width", 30.0)

	# 计算方向
	var direction: Vector2 = Vector2.RIGHT
	if player and is_instance_valid(player):
		direction = (player.global_position - global_position).normalized()

	# 创建光束
	var beam := Line2D.new()
	beam.add_point(global_position)
	beam.add_point(global_position + direction * 800)
	beam.width = width
	beam.default_color = Color(1.0, 0.3, 0.3, 0.8)
	beam.z_index = 10
	get_tree().current_scene.add_child(beam)

	# 持续检测伤害
	var elapsed: float = 0.0
	while elapsed < duration:
		# 检测光束路径上的玩家
		if player and is_instance_valid(player):
			var closest_point: Vector2 = _closest_point_on_line(
				player.global_position,
				global_position,
				global_position + direction * 800
			)
			if player.global_position.distance_to(closest_point) < width:
				if player.has_method("take_damage"):
					player.take_damage(damage * get_physics_process_delta_time(), self)

		elapsed += get_physics_process_delta_time()
		await get_tree().physics_frame

	# 移除光束
	beam.queue_free()

func _execute_shockwave(skill: Dictionary) -> void:
	var damage: float = skill.get("damage", attack_damage)
	var max_radius: float = skill.get("max_radius", 400.0)
	var speed: float = skill.get("speed", 200.0)

	var current_radius: float = 0.0

	while current_radius < max_radius:
		current_radius += speed * get_physics_process_delta_time()

		# 检测环上的目标
		if player and is_instance_valid(player):
			var dist: float = player.global_position.distance_to(global_position)
			if absf(dist - current_radius) < 30.0:
				if player.has_method("take_damage"):
					player.take_damage(damage, self)

		# 视觉效果
		_draw_shockwave_ring(global_position, current_radius)

		await get_tree().physics_frame

# =============================================================================
# 辅助方法
# =============================================================================

func _deal_area_damage(center: Vector2, radius: float, damage: float) -> void:
	if player and is_instance_valid(player):
		if player.global_position.distance_to(center) <= radius:
			if player.has_method("take_damage"):
				player.take_damage(damage, self)

func _show_warning_circle(center: Vector2, radius: float, duration: float) -> void:
	var circle := Node2D.new()
	circle.global_position = center
	circle.z_index = 5

	var func_ref = func():
		var scale_mult := 1.0 + sin(Time.get_ticks_msec() * 0.01) * 0.1
		circle.scale = Vector2(scale_mult, scale_mult)

	var tween := create_tween()
	tween.tween_callback(func_ref).set_loops(int(duration * 60))

	get_tree().current_scene.add_child(circle)

	# 绘制圆形
	var line := Line2D.new()
	for i in range(32):
		var angle: float = (TAU / 32) * i
		line.add_point(Vector2(cos(angle), sin(angle)) * radius)
	line.add_point(Vector2(cos(0), sin(0)) * radius)  # 闭合
	line.default_color = Color(1.0, 0.3, 0.3, 0.5)
	line.width = 3.0
	circle.add_child(line)

	await get_tree().create_timer(duration).timeout
	circle.queue_free()

func _spawn_aoe_visual(center: Vector2, radius: float) -> void:
	var visual := Node2D.new()
	visual.global_position = center

	var sprite := Sprite2D.new()
	var tex := ImageTexture.new()
	var img := Image.create(int(radius * 2), int(radius * 2), false, Image.FORMAT_RGBA8)
	img.fill(Color(1.0, 0.3, 0.3, 0.4))
	tex.set_image(img)
	sprite.texture = tex
	sprite.offset = Vector2(-radius, -radius)
	visual.add_child(sprite)

	get_tree().current_scene.add_child(visual)

	var tween := visual.create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
	tween.tween_callback(visual.queue_free)

func _spawn_minion(enemy_type: String, position: Vector2) -> void:
	var wave_mgr = get_tree().current_scene.get_node_or_null("GameWorld/WaveManager")
	if wave_mgr and wave_mgr.has_method("spawn_specific_enemy"):
		wave_mgr.spawn_specific_enemy(enemy_type, position)

func _spawn_boss_projectile(angle: float, damage: float, speed: float) -> void:
	var bullet := Area2D.new()
	bullet.collision_layer = 4
	bullet.collision_mask = 1

	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 8.0
	collision.shape = shape
	bullet.add_child(collision)

	var sprite := Sprite2D.new()
	var tex := ImageTexture.new()
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(1.0, 0.3, 0.3))
	tex.set_image(img)
	sprite.texture = tex
	bullet.add_child(sprite)

	bullet.global_position = global_position
	bullet.set_meta("direction", Vector2(cos(angle), sin(angle)))
	bullet.set_meta("speed", speed)
	bullet.set_meta("damage", damage)
	bullet.set_meta("owner", self)

	# 简单移动脚本
	bullet.set_script(_create_projectile_script())

	get_tree().current_scene.add_child(bullet)

func _create_projectile_script() -> GDScript:
	var script := GDScript.new()
	script.source_code = """
extends Area2D
var direction: Vector2 = Vector2.RIGHT
var speed: float = 300.0
var damage: float = 10.0
var owner_node: Node = null
var lifetime: float = 5.0

func _ready():
	body_entered.connect(_on_hit)

func _physics_process(delta):
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
	position += direction * speed * delta

func _on_hit(body):
	if body.has_method("take_damage") and body != owner_node:
		body.take_damage(damage, owner_node)
	queue_free()
"""
	script.reload()
	return script

func _draw_shockwave_ring(center: Vector2, radius: float) -> void:
	var ring := Line2D.new()
	for i in range(64):
		var angle: float = (TAU / 64) * i
		ring.add_point(center + Vector2(cos(angle), sin(angle)) * radius)
	ring.add_point(center + Vector2(cos(0), sin(0)) * radius)
	ring.default_color = Color(1.0, 0.5, 0.3, 0.5)
	ring.width = 4.0
	ring.z_index = 5
	get_tree().current_scene.add_child(ring)

	var tween := ring.create_tween()
	tween.tween_property(ring, "modulate:a", 0.0, 0.3)
	tween.tween_callback(ring.queue_free)

func _closest_point_on_line(point: Vector2, line_start: Vector2, line_end: Vector2) -> Vector2:
	var line: Vector2 = line_end - line_start
	var len_sq: float = line.length_squared()
	if len_sq == 0:
		return line_start
	var t: float = clampf((point - line_start).dot(line) / len_sq, 0.0, 1.0)
	return line_start + t * line

# =============================================================================
# 重写死亡处理
# =============================================================================

func die(killer: Node = null) -> void:
	boss_defeated.emit()

	# Boss专属掉落
	_spawn_boss_drops()

	super.die(killer)

func _spawn_boss_drops() -> void:
	for drop in boss_drops:
		var item_id: String = drop.get("item_id", "")
		var chance: float = drop.get("chance", 1.0)

		if randf() <= chance:
			print("[Boss] 掉落: %s" % item_id)
			# 使用掉落系统生成