## Void Hunter - 波次管理器
## @description: 管理无尽波次递增、敌人生成和精英出现
## @author: Void Hunter Team
## @version: 1.0.0

extends Node

# =============================================================================
# 信号定义
# =============================================================================

## 波次开始时触发
signal wave_started(wave_number: int)

## 波次完成时触发
signal wave_completed(wave_number: int)

## 敌人生成时触发
signal enemy_spawned(enemy: Node)

## 精英出现时触发
signal elite_spawned(enemy: Node)

## 休息时间开始时触发
signal break_started(duration: float)

## 休息时间结束时触发
signal break_ended()

## 所有敌人都被清除时触发
signal all_enemies_cleared()

# =============================================================================
# 常量定义
# =============================================================================

## 基础敌人数量
const BASE_ENEMY_COUNT: int = 15

## 每波敌人增加数量
const ENEMY_INCREMENT: int = 5

## 精英出现间隔（每N波出现精英）
const ELITE_INTERVAL: int = 3

## 休息时间（秒）
const BREAK_DURATION: float = 5.0

## 最大同时存在敌人数量
const MAX_ACTIVE_ENEMIES: int = 100

## 生成范围
const SPAWN_MIN_DISTANCE: float = 250.0
const SPAWN_MAX_DISTANCE: float = 450.0

# =============================================================================
# 敌人属性缩放配置
# =============================================================================

## 每波生命值增加比例（10%）
const HEALTH_SCALING_PER_WAVE: float = 0.1

## 每波伤害增加比例（5%）
const DAMAGE_SCALING_PER_WAVE: float = 0.05

## 每波移动速度增加比例（2%）
const SPEED_SCALING_PER_WAVE: float = 0.02

## 每波奖励增加比例（5%）
const REWARD_SCALING_PER_WAVE: float = 0.05

# =============================================================================
# 敌人类型解锁波次配置
# =============================================================================

## 远程敌人开始出现的波次
const RANGED_UNLOCK_WAVE: int = 4

## 精英敌人开始出现的波次
const ELITE_UNLOCK_WAVE: int = 7

## Boss开始出现的波次
const BOSS_UNLOCK_WAVE: int = 11

## Boss出现概率基础值（从第11波开始）
const BOSS_SPAWN_BASE_CHANCE: float = 0.1

## 每波Boss出现概率增加
const BOSS_SPAWN_CHANCE_INCREMENT: float = 0.05

## Boss出现间隔（每N波必有Boss）
const BOSS_GUARANTEE_INTERVAL: int = 5

# =============================================================================
# 枚举定义
# =============================================================================

## 波次状态
enum WaveState {
	IDLE,		## 空闲
	SPAWNING,	## 生成中
	ACTIVE,		## 进行中
	BREAK,		## 休息
	BOSS		## Boss战
}

# =============================================================================
# 导出变量
# =============================================================================

## 是否启用波次系统
@export var enabled: bool = true

## 是否无尽模式
@export var endless_mode: bool = true

## 最大波次（非无尽模式）
@export var max_wave: int = 100

## 休息时间
@export var break_duration: float = BREAK_DURATION

## 是否生成精英
@export var spawn_elites: bool = true

## 精英出现间隔
@export var elite_interval: int = ELITE_INTERVAL

## 生成区域中心（自动设置为玩家位置）
@export var spawn_center: Vector2 = Vector2.ZERO

## 生成区域大小
@export var spawn_area_size: Vector2 = Vector2(800, 600)

# =============================================================================
# 公共变量
# =============================================================================

## 当前波次
var current_wave: int = 0

## 当前状态
var current_state: WaveState = WaveState.IDLE

## 当前波次敌人总数
var wave_enemy_count: int = 0

## 已击杀敌人数量
var enemies_killed_this_wave: int = 0

## 活跃敌人列表
var active_enemies: Array[Node] = []

## 是否暂停
var is_paused: bool = false

## 玩家引用
var player: Node = null

## 敌人容器（由 game.gd 设置）
var entities_container: Node = null

# =============================================================================
# 私有变量
# =============================================================================

var _spawn_timer: float = 0.0
var _spawn_interval: float = 0.15
var _enemies_to_spawn: int = 0
var _break_timer: float = 0.0
var _spawn_queue: Array[Dictionary] = []

# 敌人脚本引用
var _enemy_scripts: Dictionary = {}

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""节点就绪时初始化"""
	_initialize_manager()


func _process(delta: float) -> void:
	"""每帧更新"""
	if is_paused or not enabled:
		return
	
	# 根据状态更新
	match current_state:
		WaveState.SPAWNING:
			_update_spawning(delta)
		WaveState.BREAK:
			_update_break(delta)
		WaveState.ACTIVE:
			_update_active(delta)

# =============================================================================
# 公共方法 - 初始化
# =============================================================================

## 初始化管理器
func initialize() -> void:
	"""手动初始化波次管理器"""
	_initialize_manager()


## 设置玩家引用
func set_player(player_node: Node) -> void:
	"""设置玩家引用"""
	player = player_node
	print("[WaveManager] 玩家引用已设置")


## 设置敌人容器
func set_entities_container(container: Node) -> void:
	"""设置敌人容器"""
	entities_container = container


## 开始游戏
func start_game() -> void:
	"""开始游戏，启动第一波"""
	if not enabled:
		return
	
	current_wave = 0
	enemies_killed_this_wave = 0
	_clear_all_enemies()
	_start_next_wave()

# =============================================================================
# 公共方法 - 波次控制
# =============================================================================

## 开始下一波
func start_next_wave() -> void:
	"""开始下一波"""
	_start_next_wave()


## 跳过休息
func skip_break() -> void:
	"""跳过休息时间"""
	if current_state == WaveState.BREAK:
		_break_timer = 0
		_end_break()


## 暂停波次
func pause_wave() -> void:
	"""暂停波次"""
	is_paused = true


## 恢复波次
func resume_wave() -> void:
	"""恢复波次"""
	is_paused = false


## 强制完成当前波次
func force_complete_wave() -> void:
	"""强制完成当前波次（清除所有敌人）"""
	_clear_all_enemies()
	_complete_wave()


## 获取剩余敌人数量
func get_remaining_enemies() -> int:
	"""获取当前波次剩余敌人数量"""
	return active_enemies.size()

# =============================================================================
# 公共方法 - 敌人管理
# =============================================================================

## 敌人死亡通知
func on_enemy_died(enemy: Node) -> void:
	"""敌人死亡时调用"""
	enemies_killed_this_wave += 1
	
	# 从活跃列表移除
	if enemy in active_enemies:
		active_enemies.erase(enemy)
	
	# 检查波次是否完成
	_check_wave_completion()


## 生成特定敌人
func spawn_specific_enemy(enemy_type: String, position: Vector2) -> Node:
	"""在指定位置生成特定类型的敌人"""
	return _spawn_enemy(enemy_type, position)


## 生成精英
func spawn_elite() -> Node:
	"""生成精英敌人"""
	var spawn_pos: Vector2 = _get_spawn_position()
	var elite: Node = _spawn_enemy("elite", spawn_pos)
	
	if elite:
		elite_spawned.emit(elite)
	
	return elite

# =============================================================================
# 公共方法 - 信息获取
# =============================================================================

## 获取波次信息
func get_wave_info() -> Dictionary:
	"""获取当前波次信息"""
	return {
		"wave": current_wave,
		"state": WaveState.keys()[current_state],
		"total_enemies": wave_enemy_count,
		"killed": enemies_killed_this_wave,
		"remaining": active_enemies.size(),
		"is_break": current_state == WaveState.BREAK,
		"break_remaining": _break_timer if current_state == WaveState.BREAK else 0.0
	}


## 获取难度系数
func get_difficulty_multiplier() -> float:
	"""获取当前难度系数"""
	return 1.0 + (current_wave - 1) * 0.05

# =============================================================================
# 私有方法 - 初始化
# =============================================================================

func _initialize_manager() -> void:
	"""初始化管理器内部状态"""
	current_state = WaveState.IDLE
	current_wave = 0
	enemies_killed_this_wave = 0
	active_enemies.clear()
	_spawn_queue.clear()
	
	# 查找玩家
	_find_player()
	
	# 加载敌人脚本
	_load_enemy_scripts()
	
	# 查找敌人容器
	_find_entities_container()
	
	print("[WaveManager] 初始化完成")


func _find_player() -> void:
	"""查找玩家节点"""
	# 尝试从组中获取
	var players: Array[Node] = get_tree().get_nodes_in_group("players")
	if not players.is_empty():
		player = players[0]
		print("[WaveManager] 找到玩家")


func _find_entities_container() -> void:
	"""查找敌人容器"""
	# 尝试从场景中查找
	var main = get_tree().current_scene
	if main:
		entities_container = main.get_node_or_null("GameWorld/Entities")
		if entities_container == null:
			entities_container = main.get_node_or_null("Entities")


func _load_enemy_scripts() -> void:
	"""加载敌人脚本"""
	_enemy_scripts = {
		"melee": preload("res://src/enemies/enemy_melee.gd"),
		"ranged": preload("res://src/enemies/enemy_ranged.gd"),
		"tank": preload("res://src/enemies/enemy_tank.gd"),
		"elite": preload("res://src/enemies/enemy_elite.gd"),
		"boss": preload("res://src/enemies/enemy_elite.gd")  # Boss暂时使用精英脚本（后续可创建专用Boss脚本）
	}
	print("[WaveManager] 敌人脚本已加载")

# =============================================================================
# 私有方法 - 波次控制
# =============================================================================

func _start_next_wave() -> void:
	"""开始下一波"""
	current_wave += 1
	enemies_killed_this_wave = 0
	
	# 计算敌人数量
	wave_enemy_count = _calculate_enemy_count()
	
	# 设置状态
	current_state = WaveState.SPAWNING
	
	# 准备生成队列
	_prepare_spawn_queue()
	
	_enemies_to_spawn = _spawn_queue.size()
	_spawn_timer = 0.0
	
	# 触发信号
	wave_started.emit(current_wave)
	
	# 更新游戏管理器
	GameManager.set_wave(current_wave)
	
	# 播放音效
	AudioManager.play_sfx("wave_start", 0.8)
	
	print("[WaveManager] 第 %d 波开始，敌人数量: %d" % [current_wave, wave_enemy_count])


func _calculate_enemy_count() -> int:
	"""计算当前波次的敌人数量"""
	return BASE_ENEMY_COUNT + (current_wave - 1) * ENEMY_INCREMENT


func _prepare_spawn_queue() -> void:
	"""准备生成队列，根据波次解锁不同敌人类型"""
	_spawn_queue.clear()
	
	var enemy_count: int = wave_enemy_count
	
	# 根据波次计算各类型敌人数量
	var melee_count: int = 0
	var ranged_count: int = 0
	var tank_count: int = 0
	var elite_count: int = 0
	var boss_count: int = 0
	
	# 波次 1-3: 只有近战敌人
	if current_wave <= 3:
		melee_count = enemy_count
	# 波次 4-6: 加入远程敌人
	elif current_wave <= 6:
		melee_count = int(enemy_count * 0.7)  # 70% 近战
		ranged_count = int(enemy_count * 0.3)  # 30% 远程
	# 波次 7-10: 加入精英敌人
	elif current_wave <= 10:
		melee_count = int(enemy_count * 0.5)  # 50% 近战
		ranged_count = int(enemy_count * 0.3)  # 30% 远程
		elite_count = int(enemy_count * 0.15)  # 15% 精英
		tank_count = int(enemy_count * 0.05)   # 5% 坦克
	# 波次 11+: 有几率生成Boss
	else:
		melee_count = int(enemy_count * 0.4)  # 40% 近战
		ranged_count = int(enemy_count * 0.25)  # 25% 远程
		elite_count = int(enemy_count * 0.2)  # 20% 精英
		tank_count = int(enemy_count * 0.1)   # 10% 坦克
		
		# 检查是否生成Boss
		if _should_spawn_boss():
			boss_count = 1
			# Boss占用精英名额
			if elite_count > 0:
				elite_count -= 1
	
	# 补足差额（给近战敌人）
	var total: int = melee_count + ranged_count + tank_count + elite_count + boss_count
	if total < enemy_count:
		melee_count += enemy_count - total
	
	# 添加到队列
	for i in range(melee_count):
		_spawn_queue.append({"type": "melee", "wave": current_wave})
	
	for i in range(ranged_count):
		_spawn_queue.append({"type": "ranged", "wave": current_wave})
	
	for i in range(tank_count):
		_spawn_queue.append({"type": "tank", "wave": current_wave})
	
	for i in range(elite_count):
		_spawn_queue.append({"type": "elite", "wave": current_wave})
	
	for i in range(boss_count):
		_spawn_queue.append({"type": "boss", "wave": current_wave})
	
	# 随机打乱顺序
	_shuffle_spawn_queue()
	
	print("[WaveManager] 生成队列准备完成: 近战=%d, 远程=%d, 坦克=%d, 精英=%d, Boss=%d" % [melee_count, ranged_count, tank_count, elite_count, boss_count])


## 检查是否应该生成Boss
func _should_spawn_boss() -> bool:
	"""检查当前波次是否应该生成Boss"""
	# 波次未达到解锁条件
	if current_wave < BOSS_UNLOCK_WAVE:
		return false
	
	# 检查是否是必定生成Boss的波次（每N波必有Boss）
	if (current_wave - BOSS_UNLOCK_WAVE) % BOSS_GUARANTEE_INTERVAL == 0:
		return true
	
	# 计算Boss出现概率
	var boss_chance: float = BOSS_SPAWN_BASE_CHANCE + (current_wave - BOSS_UNLOCK_WAVE) * BOSS_SPAWN_CHANCE_INCREMENT
	boss_chance = minf(boss_chance, 0.5)  # 最高50%概率
	
	return randf() < boss_chance


func _shuffle_spawn_queue() -> void:
	"""随机打乱生成队列"""
	var shuffled: Array[Dictionary] = []
	while _spawn_queue.size() > 0:
		var index: int = randi() % _spawn_queue.size()
		shuffled.append(_spawn_queue[index])
		_spawn_queue.remove_at(index)
	_spawn_queue = shuffled

# =============================================================================
# 私有方法 - 更新
# =============================================================================

func _update_spawning(delta: float) -> void:
	"""更新生成状态"""
	_spawn_timer -= delta
	
	if _spawn_timer <= 0 and _spawn_queue.size() > 0:
		# 检查最大活跃敌人数量
		if active_enemies.size() >= MAX_ACTIVE_ENEMIES:
			_spawn_timer = 0.5
			return
		
		# 生成下一个敌人
		var spawn_data: Dictionary = _spawn_queue.pop_front()
		_spawn_single_enemy(spawn_data)
		
		_spawn_timer = _spawn_interval
		_enemies_to_spawn -= 1
	
	# 检查是否生成完毕
	if _spawn_queue.is_empty() and active_enemies.size() > 0:
		current_state = WaveState.ACTIVE


func _update_break(delta: float) -> void:
	"""更新休息状态"""
	_break_timer -= delta
	
	if _break_timer <= 0:
		_end_break()


func _update_active(_delta: float) -> void:
	"""更新活跃状态"""
	# 检查波次完成
	_check_wave_completion()


func _check_wave_completion() -> void:
	"""检查波次是否完成"""
	if current_state == WaveState.SPAWNING and _spawn_queue.is_empty() and active_enemies.is_empty():
		_complete_wave()
	elif current_state == WaveState.ACTIVE and active_enemies.is_empty():
		_complete_wave()


func _complete_wave() -> void:
	"""完成当前波次"""
	current_state = WaveState.BREAK
	_break_timer = break_duration
	
	# 触发信号
	wave_completed.emit(current_wave)
	break_started.emit(_break_timer)
	
	# 播放音效
	AudioManager.play_sfx("wave_complete", 0.8)
	
	print("[WaveManager] 第 %d 波完成" % current_wave)
	
	# 检查是否达到最大波次
	if not endless_mode and current_wave >= max_wave:
		# 游戏胜利
		GameManager.handle_game_victory()
		return


func _end_break() -> void:
	"""结束休息"""
	current_state = WaveState.IDLE
	break_ended.emit()
	_start_next_wave()

# =============================================================================
# 私有方法 - 敌人生成
# =============================================================================

func _spawn_single_enemy(spawn_data: Dictionary) -> Node:
	"""生成单个敌人"""
	var enemy_type: String = spawn_data.get("type", "melee")
	var wave_number: int = spawn_data.get("wave", current_wave)
	var spawn_pos: Vector2 = _get_spawn_position()
	
	var enemy: Node = _spawn_enemy(enemy_type, spawn_pos)
	
	if enemy:
		# 应用波次缩放（使用新的波次缩放方法）
		enemy.apply_wave_scaling(wave_number)
		active_enemies.append(enemy)
		enemy_spawned.emit(enemy)
		
		# 如果是精英或Boss
		if enemy_type == "elite" or enemy_type == "boss":
			elite_spawned.emit(enemy)
	
	return enemy


func _spawn_enemy(enemy_type: String, position: Vector2) -> Node:
	"""生成敌人"""
	var enemy_script: GDScript = _enemy_scripts.get(enemy_type)
	if enemy_script == null:
		enemy_script = _enemy_scripts["melee"]
	
	# 创建敌人节点
	var enemy: CharacterBody2D = CharacterBody2D.new()
	enemy.set_script(enemy_script)
	enemy.global_position = position
	enemy.name = "Enemy_%s_%d" % [enemy_type, randi() % 10000]
	
	# 添加碰撞形状
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 12.0
	collision.shape = shape
	enemy.add_child(collision)
	
	# 添加视觉效果（根据类型）
	var sprite: Sprite2D = Sprite2D.new()
	sprite.name = "Sprite"
	var texture: ImageTexture = ImageTexture.new()
	var image: Image
	
	# 根据类型设置颜色和大小
	var color: Color = Color.RED
	match enemy_type:
		"melee":
			color = Color(0.8, 0.2, 0.2)
			image = Image.create(24, 24, false, Image.FORMAT_RGBA8)
		"ranged":
			color = Color(0.2, 0.6, 0.8)
			image = Image.create(20, 20, false, Image.FORMAT_RGBA8)
		"tank":
			color = Color(0.5, 0.5, 0.5)
			image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
		"elite":
			color = Color(0.8, 0.5, 0.1)
			image = Image.create(36, 36, false, Image.FORMAT_RGBA8)
		"boss":
			color = Color(0.6, 0.1, 0.8)  # 紫色表示Boss
			image = Image.create(48, 48, false, Image.FORMAT_RGBA8)  # Boss最大
		_:
			image = Image.create(24, 24, false, Image.FORMAT_RGBA8)
	
	image.fill(color)
	texture.set_image(image)
	sprite.texture = texture
	enemy.add_child(sprite)
	
	# 为Boss设置特殊基础属性（在波次缩放之前）
	if enemy_type == "boss":
		enemy.set("max_health", 300.0)  # Boss基础生命值更高
		enemy.set("attack_damage", 35.0)  # Boss基础伤害更高
		enemy.set("move_speed", 70.0)  # Boss移动速度稍慢
		enemy.set("experience_reward", 200)  # Boss经验值奖励更高
		enemy.set("gold_reward", 150)  # Boss金币奖励更高
		enemy.set("enemy_type", 4)  # 设置为Boss类型（枚举值4）
		# 设置更大的碰撞半径
		shape.radius = 24.0
	elif enemy_type == "tank":
		shape.radius = 16.0
	elif enemy_type == "elite":
		shape.radius = 18.0
	
	# 确定添加到哪个容器
	var container: Node = entities_container
	if container == null:
		# 查找容器
		var main = get_tree().current_scene
		if main:
			container = main.get_node_or_null("GameWorld/Entities")
			if container == null:
				container = main
	
	if container:
		container.add_child(enemy)
	else:
		get_tree().current_scene.add_child(enemy)
	
	print("[WaveManager] 生成敌人: %s 于 %s" % [enemy_type, position])
	
	return enemy


func _get_spawn_position() -> Vector2:
	"""获取生成位置"""
	var center: Vector2 = Vector2(576, 320)  # 默认屏幕中心
	
	# 以玩家为中心
	if player and is_instance_valid(player):
		center = player.global_position
	else:
		_find_player()
		if player and is_instance_valid(player):
			center = player.global_position
	
	# 在玩家周围的环形区域随机生成
	var angle: float = randf() * TAU
	var distance: float = randf_range(SPAWN_MIN_DISTANCE, SPAWN_MAX_DISTANCE)
	
	var spawn_pos: Vector2 = center + Vector2(cos(angle), sin(angle)) * distance
	
	return spawn_pos


func _clear_all_enemies() -> void:
	"""清除所有活跃敌人"""
	for enemy in active_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	
	active_enemies.clear()
	all_enemies_cleared.emit()
