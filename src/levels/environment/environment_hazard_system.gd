## Void Hunter - 动态环境危险系统
## @description: 管理关卡中的环境危险：移动平台、落石、激光、尖刺、天气效果
## @version: 2.0.0

extends Node2D

# =============================================================================
# 信号
# =============================================================================

signal hazard_triggered(hazard_type: String, position: Vector2)
signal hazard_damage_dealt(hazard_type: String, target: Node, damage: float)
signal weather_changed(weather_type: String)

# =============================================================================
# 危险类型配置
# =============================================================================

## 移动平台
class MovingPlatform:
	var node: Node2D
	var start_pos: Vector2
	var end_pos: Vector2
	var speed: float
	var is_active: bool = true
	var direction: int = 1
	var move_toward_target: bool = true

	func _init(p_start: Vector2, p_end: Vector2, p_speed: float) -> void:
		start_pos = p_start
		end_pos = p_end
		speed = p_speed

## 落石
class FallingRock:
	var node: Node2D
	var spawn_pos: Vector2
	var fall_speed: float
	var damage: float
	var radius: float
	var warning_time: float
	var is_falling: bool = false

	func _init(p_pos: Vector2, p_damage: float) -> void:
		spawn_pos = p_pos
		damage = p_damage
		fall_speed = 300.0
		radius = 25.0
		warning_time = 1.0

## 激光
class LaserBeam:
	var node: Node2D
	var start_pos: Vector2
	var end_pos: Vector2
	var damage: float
	var width: float
	var on_time: float
	var off_time: float
	var is_active: bool = false
	var timer: float = 0.0

	func _init(p_start: Vector2, p_end: Vector2, p_damage: float) -> void:
		start_pos = p_start
		end_pos = p_end
		damage = p_damage
		width = 10.0
		on_time = 2.0
		off_time = 1.5

## 尖刺陷阱
class SpikeTrap:
	var node: Node2D
	var position: Vector2
	var damage: float
	var is_extended: bool = false
	var extend_duration: float
	var retract_duration: float
	var timer: float = 0.0

	func _init(p_pos: Vector2, p_damage: float) -> void:
		position = p_pos
		damage = p_damage
		extend_duration = 2.0
		retract_duration = 1.5

# =============================================================================
# 公共变量
# =============================================================================

var platforms: Array[MovingPlatform] = []
var rocks: Array[FallingRock] = []
var lasers: Array[LaserBeam] = []
var spikes: Array[SpikeTrap] = []
var weather_particles: Node2D = null

var _rock_spawn_timer: float = 0.0
var _rock_spawn_interval: float = 3.0
var _is_active: bool = true

# =============================================================================
# 初始化
# =============================================================================

func _ready() -> void:
	weather_particles = Node2D.new()
	weather_particles.name = "WeatherParticles"
	add_child(weather_particles)

# =============================================================================
# 公共方法 - 创建危险
# =============================================================================

## 创建移动平台
func create_moving_platform(start: Vector2, end: Vector2, speed: float = 80.0) -> Node2D:
	var platform_data := MovingPlatform.new(start, end, speed)

	# 创建平台视觉
	var platform_node := StaticBody2D.new()
	platform_node.position = start

	var sprite := ColorRect.new()
	sprite.color = Color(0.5, 0.5, 0.6)
	sprite.size = Vector2(80, 12)
	sprite.position = Vector2(-40, -6)
	platform_node.add_child(sprite)

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(80, 12)
	collision.shape = shape
	platform_node.add_child(collision)

	add_child(platform_node)
	platform_data.node = platform_node
	platforms.append(platform_data)

	return platform_node

## 创建落石区域
func create_falling_rocks(area_center: Vector2, area_radius: float, count: int = 5, damage: float = 20.0) -> void:
	for i in range(count):
		var offset := Vector2(randf_range(-area_radius, area_radius), -300.0)
		var rock := FallingRock.new(area_center + Vector2(offset.x, 0), damage)
		rocks.append(rock)

## 创建激光
func create_laser(start: Vector2, end: Vector2, damage: float = 15.0) -> Node2D:
	var laser_data := LaserBeam.new(start, end, damage)

	var laser_node := Node2D.new()
	laser_node.name = "Laser"

	var line := Line2D.new()
	line.width = laser_data.width
	line.default_color = Color(1.0, 0.2, 0.2, 0.8)
	line.add_point(start)
	line.add_point(end)
	line.z_index = 5
	laser_node.add_child(line)

	# 激光核心
	var core := Line2D.new()
	core.width = laser_data.width * 0.3
	core.default_color = Color(1.0, 1.0, 1.0, 0.9)
	core.add_point(start)
	core.add_point(end)
	core.z_index = 6
	laser_node.add_child(core)

	add_child(laser_node)
	laser_data.node = laser_node
	laser_data.is_active = true
	lasers.append(laser_data)

	return laser_node

## 创建尖刺陷阱
func create_spike_trap(pos: Vector2, damage: float = 10.0) -> Node2D:
	var spike_data := SpikeTrap.new(pos, damage)

	var spike_node := Node2D.new()
	spike_node.position = pos

	var area := Area2D.new()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(32, 16)
	collision.shape = shape
	area.add_child(collision)

	# 尖刺视觉
	var sprite := ColorRect.new()
	sprite.color = Color(0.6, 0.6, 0.6)
	sprite.size = Vector2(32, 16)
	sprite.position = Vector2(-16, -8)
	spike_node.add_child(sprite)
	spike_node.add_child(area)

	add_child(spike_node)
	spike_data.node = spike_node
	spikes.append(spike_data)

	# 连接碰撞信号
	area.body_entered.connect(_on_spike_body_entered.bind(spike_data))

	return spike_node

## 创建天气效果
func create_weather_effect(weather_type: String, bounds: Rect2) -> void:
	# 确保天气粒子容器存在
	if weather_particles == null:
		weather_particles = Node2D.new()
		weather_particles.name = "WeatherParticles"
		add_child(weather_particles)
	# 清除旧天气
	if weather_particles:
		for child in weather_particles.get_children():
			child.queue_free()

	weather_changed.emit(weather_type)

	match weather_type:
		"rain":
			_create_rain(bounds)
		"snow":
			_create_snow(bounds)
		"sandstorm":
			_create_sandstorm(bounds)
		"fog":
			_create_fog(bounds)
		"lava_rain":
			_create_lava_rain(bounds)

# =============================================================================
# 公共方法 - 控制
# =============================================================================

## 激活/停用所有危险
func set_active(active: bool) -> void:
	_is_active = active

## 清除所有危险
func clear_all() -> void:
	for platform in platforms:
		if platform.node and is_instance_valid(platform.node):
			platform.node.queue_free()
	platforms.clear()

	for rock in rocks:
		if rock.node and is_instance_valid(rock.node):
			rock.node.queue_free()
	rocks.clear()

	for laser in lasers:
		if laser.node and is_instance_valid(laser.node):
			laser.node.queue_free()
	lasers.clear()

	for spike in spikes:
		if spike.node and is_instance_valid(spike.node):
			spike.node.queue_free()
	spikes.clear()

	if weather_particles:
		for child in weather_particles.get_children():
			child.queue_free()

# =============================================================================
# 生命周期
# =============================================================================

func _physics_process(delta: float) -> void:
	if not _is_active:
		return

	_update_platforms(delta)
	_update_lasers(delta)
	_update_spikes(delta)

# =============================================================================
# 更新方法
# =============================================================================

func _update_platforms(delta: float) -> void:
	for platform in platforms:
		if not platform.is_active or not is_instance_valid(platform.node):
			continue

		platform.node.position = platform.node.position.move_toward(
			platform.end_pos if platform.direction == 1 else platform.start_pos,
			platform.speed * delta
		)

		if platform.node.position.distance_to(platform.end_pos) < 2.0:
			platform.direction = -1
		elif platform.node.position.distance_to(platform.start_pos) < 2.0:
			platform.direction = 1

func _update_lasers(delta: float) -> void:
	for laser in lasers:
		if not is_instance_valid(laser.node):
			continue

		laser.timer += delta

		if laser.is_active:
			if laser.timer >= laser.on_time:
				laser.is_active = false
				laser.timer = 0.0
				laser.node.visible = false
		else:
			if laser.timer >= laser.off_time:
				laser.is_active = true
				laser.timer = 0.0
				laser.node.visible = true
				hazard_triggered.emit("laser", laser.start_pos)

		# 激光伤害检测
		if laser.is_active:
			_check_laser_collision(laser)

func _update_spikes(delta: float) -> void:
	for spike in spikes:
		if not is_instance_valid(spike.node):
			continue

		spike.timer += delta
		if spike.is_extended:
			if spike.timer >= spike.extend_duration:
				spike.is_extended = false
				spike.timer = 0.0
				spike.node.modulate.a = 0.3
		else:
			if spike.timer >= spike.retract_duration:
				spike.is_extended = true
				spike.timer = 0.0
				spike.node.modulate.a = 1.0

# =============================================================================
# 碰撞处理
# =============================================================================

func _check_laser_collision(laser: LaserBeam) -> void:
	# 简化版激光碰撞检测 - 检查玩家是否在激光路径附近
	var players := get_tree().get_nodes_in_group("players")
	for player in players:
		if not is_instance_valid(player):
			continue
		var distance := _point_to_line_distance(player.global_position, laser.start_pos, laser.end_pos)
		if distance < laser.width + 10.0:
			if player.has_method("take_damage"):
				player.take_damage(laser.damage * get_process_delta_time())
				hazard_damage_dealt.emit("laser", player, laser.damage)

func _on_spike_body_entered(body: Node, spike_data: SpikeTrap) -> void:
	if spike_data.is_extended and body.is_in_group("players"):
		if body.has_method("take_damage"):
			body.take_damage(spike_data.damage)
			hazard_damage_dealt.emit("spike", body, spike_data.damage)
	elif spike_data.is_extended and body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			body.take_damage(spike_data.damage * 0.5)

func _point_to_line_distance(point: Vector2, line_start: Vector2, line_end: Vector2) -> float:
	var line_vec := line_end - line_start
	var point_vec := point - line_start
	var line_len := line_vec.length()
	if line_len == 0:
		return point_vec.length()
	var t := clampf(point_vec.dot(line_vec) / (line_len * line_len), 0.0, 1.0)
	var projection := line_start + t * line_vec
	return point.distance_to(projection)

# =============================================================================
# 天气效果创建
# =============================================================================

func _create_rain(bounds: Rect2) -> void:
	for i in range(80):
		var drop := ColorRect.new()
		drop.color = Color(0.5, 0.6, 0.9, 0.4)
		drop.size = Vector2(2, 8)
		drop.position = Vector2(
			randf_range(bounds.position.x, bounds.end.x),
			randf_range(bounds.position.y, bounds.end.y)
		)
		weather_particles.add_child(drop)

		var tween := create_tween().set_loops()
		tween.tween_property(drop, "position:y", drop.position.y + bounds.size.y, randf_range(0.5, 1.5))
		tween.tween_callback(drop.queue_free)

func _create_snow(bounds: Rect2) -> void:
	for i in range(60):
		var flake := ColorRect.new()
		flake.color = Color(1.0, 1.0, 1.0, 0.5)
		flake.size = Vector2(3, 3)
		flake.position = Vector2(
			randf_range(bounds.position.x, bounds.end.x),
			randf_range(bounds.position.y, bounds.end.y)
		)
		weather_particles.add_child(flake)

		var tween := create_tween().set_loops()
		tween.tween_property(flake, "position:y", flake.position.y + bounds.size.y, randf_range(2.0, 4.0))
		tween.parallel().tween_property(flake, "position:x", flake.position.x + randf_range(-30, 30), 3.0)
		tween.tween_callback(flake.queue_free)

func _create_sandstorm(bounds: Rect2) -> void:
	for i in range(40):
		var particle := ColorRect.new()
		particle.color = Color(0.8, 0.7, 0.5, 0.3)
		particle.size = Vector2(randf_range(2, 6), randf_range(2, 6))
		particle.position = Vector2(
			randf_range(bounds.position.x, bounds.end.x),
			randf_range(bounds.position.y, bounds.end.y)
		)
		weather_particles.add_child(particle)

		var tween := create_tween().set_loops()
		tween.tween_property(particle, "position:x", particle.position.x + bounds.size.x, randf_range(1.0, 3.0))
		tween.tween_callback(particle.queue_free)

func _create_fog(bounds: Rect2) -> void:
	for i in range(8):
		var fog := ColorRect.new()
		fog.color = Color(0.7, 0.7, 0.7, 0.15)
		fog.size = Vector2(randf_range(200, 400), randf_range(100, 200))
		fog.position = Vector2(
			randf_range(bounds.position.x, bounds.end.x - 200),
			randf_range(bounds.position.y, bounds.end.y - 100)
		)
		weather_particles.add_child(fog)

		var tween := create_tween().set_loops()
		tween.tween_property(fog, "position:x", fog.position.x + randf_range(-100, 100), randf_range(5, 10))
		tween.tween_property(fog, "position:x", fog.position.x, randf_range(5, 10))

func _create_lava_rain(bounds: Rect2) -> void:
	for i in range(30):
		var drop := ColorRect.new()
		drop.color = Color(1.0, 0.4, 0.1, 0.5)
		drop.size = Vector2(3, 6)
		drop.position = Vector2(
			randf_range(bounds.position.x, bounds.end.x),
			randf_range(bounds.position.y, bounds.end.y)
		)
		weather_particles.add_child(drop)

		var tween := create_tween().set_loops()
		tween.tween_property(drop, "position:y", drop.position.y + bounds.size.y, randf_range(0.5, 1.0))
		tween.tween_callback(drop.queue_free)
