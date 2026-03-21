## Void Hunter - 敌人基类
## @description: 所有敌人的基类，包含通用行为、属性、AI和掉落系统
## @author: Void Hunter Team
## @version: 1.0.0

extends CharacterBody2D
class_name EnemyBase

# =============================================================================
# 信号定义
# =============================================================================

## 敌人受到伤害时触发
signal damaged(amount: float, source: Node)

## 敌人死亡时触发
signal died(killer: Node)

## 敌人发现目标时触发
signal target_found(target: Node)

## 敌人丢失目标时触发
signal target_lost()

## 敌人状态改变时触发
signal state_changed(old_state: String, new_state: String)

## 敌人掉落物品时触发
signal dropped_item(item: Node)

# =============================================================================
# 常量定义
# =============================================================================

## 闪烁持续时间
const FLASH_DURATION: float = 0.1

## 击退阻力
const KNOCKBACK_RESISTANCE: float = 0.5

## 默认检测范围
const DEFAULT_DETECTION_RANGE: float = 300.0

## 默认攻击范围
const DEFAULT_ATTACK_RANGE: float = 50.0

# =============================================================================
# 枚举定义
# =============================================================================

## 敌人类型
enum EnemyType {
	MELEE,		## 近战
	RANGED,		## 远程
	TANK,		## 坦克
	ELITE,		## 精英
	BOSS		## Boss
}

## 敌人状态
enum EnemyState {
	IDLE,		## 空闲
	PATROL,		## 巡逻
	CHASE,		## 追逐
	ATTACK,		## 攻击
	STUNNED,	## 眩晕
	HURT,		## 受伤
	DEAD		## 死亡
}

# =============================================================================
# 导出变量 - 基础属性
# =============================================================================

## 敌人类型
@export var enemy_type: EnemyType = EnemyType.MELEE

## 敌人名称
@export var enemy_name: String = "Enemy"

## 最大生命值
@export var max_health: float = 50.0

## 当前生命值
@export var current_health: float = 50.0

## 移动速度
@export_range(30.0, 400.0) var move_speed: float = 80.0

## 攻击伤害
@export var attack_damage: float = 10.0

## 攻击冷却时间
@export var attack_cooldown: float = 1.0

## 检测范围
@export var detection_range: float = DEFAULT_DETECTION_RANGE

## 攻击范围
@export var attack_range: float = DEFAULT_ATTACK_RANGE

## 掉落经验值
@export var experience_reward: int = 10

## 掉落金币
@export var gold_reward: int = 5

## 掉落物品概率
@export_range(0.0, 1.0) var drop_chance: float = 0.1

# =============================================================================
# 导出变量 - AI设置
# =============================================================================

## 是否启用AI
@export var ai_enabled: bool = true

## 是否启用巡逻
@export var patrol_enabled: bool = false

## 巡逻范围
@export var patrol_range: float = 100.0

## 追击距离限制（超出则放弃）
@export var chase_limit: float = 500.0

## 追踪精度（更新频率）
@export var track_precision: float = 0.1

# =============================================================================
# 导出变量 - 掉落设置
# =============================================================================

## 可能掉落的物品列表
@export var possible_drops: Array[String] = []

## 掉落数量范围
@export var drop_count_range: Vector2i = Vector2i(1, 2)

# =============================================================================
# 公共变量
# =============================================================================

## 当前状态
var current_state: EnemyState = EnemyState.IDLE

## 当前目标
var current_target: Node = null

## 是否已死亡
var is_dead: bool = false

## 当前朝向
var facing_direction: Vector2 = Vector2.RIGHT

## 难度系数
var difficulty_multiplier: float = 1.0

## 是否受击退影响
var can_be_knocked_back: bool = true

## 击退力度倍率
var knockback_multiplier: float = 1.0

# =============================================================================
# 私有变量
# =============================================================================

var _attack_timer: float = 0.0
var _stun_timer: float = 0.0
var _hurt_timer: float = 0.0
var _patrol_start_position: Vector2 = Vector2.ZERO
var _patrol_target_position: Vector2 = Vector2.ZERO
var _is_attacking: bool = false
var _track_timer: float = 0.0
var _last_known_target_position: Vector2 = Vector2.ZERO
var _hit_flash_tween: Tween = null

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""
	节点就绪时初始化敌人
	"""
	_initialize_enemy()


func _physics_process(delta: float) -> void:
	"""
	物理帧更新
	@param delta: 帧间隔时间
	"""
	if is_dead:
		return
	
	# 更新计时器
	_update_timers(delta)
	
	# 更新AI
	if ai_enabled:
		_update_ai(delta)
	
	# 应用移动
	move_and_slide()
	
	# 更新动画
	_update_animation()

# =============================================================================
# 公共方法 - 初始化
# =============================================================================

## 初始化敌人
func initialize() -> void:
	"""
	手动初始化敌人
	"""
	_initialize_enemy()


## 应用难度系数
func apply_difficulty(multiplier: float) -> void:
	"""
	应用难度系数
	@param multiplier: 难度倍率
	"""
	difficulty_multiplier = multiplier
	
	# 根据难度调整属性
	max_health *= multiplier
	current_health = max_health
	attack_damage *= multiplier
	move_speed *= (1.0 + (multiplier - 1.0) * 0.3)
	experience_reward = int(float(experience_reward) * multiplier)
	gold_reward = int(float(gold_reward) * multiplier)

# =============================================================================
# 公共方法 - 状态控制
# =============================================================================

## 受到伤害
func take_damage(amount: float, source: Node = null) -> void:
	"""
	敌人受到伤害
	@param amount: 伤害值
	@param source: 伤害来源
	"""
	if is_dead:
		return
	
	# 应用伤害
	current_health = maxf(0.0, current_health - amount)
	damaged.emit(amount, source)
	
	# 播放受伤效果
	_play_hurt_effect()
	
	# 设置受伤状态
	if current_state != EnemyState.ATTACK:
		set_state(EnemyState.HURT)
		_hurt_timer = 0.15
	
	# 检查死亡
	if current_health <= 0:
		die(source)
		return
	
	# 设置仇恨目标
	if source != null and current_target == null:
		set_target(source)
	
	# 应用击退
	if source != null and can_be_knocked_back:
		_apply_knockback(source.global_position)


## 死亡
func die(killer: Node = null) -> void:
	"""
	敌人死亡
	@param killer: 击杀者
	"""
	if is_dead:
		return
	
	is_dead = true
	set_state(EnemyState.DEAD)
	
	# 停止移动
	velocity = Vector2.ZERO
	
	# 播放死亡效果
	_play_death_effect()
	
	# 掉落奖励
	_drop_rewards(killer)
	
	# 触发信号
	died.emit(killer)
	
	# 更新游戏统计
	GameManager.enemies_killed += 1
	
	# 安排销毁
	_schedule_despawn()


## 设置目标
func set_target(target: Node) -> void:
	"""
	设置攻击目标
	@param target: 目标节点
	"""
	if current_target == target:
		return
	
	var had_target: bool = current_target != null
	current_target = target
	
	if target != null and not had_target:
		target_found.emit(target)
		set_state(EnemyState.CHASE)
		# 记录目标位置
		if is_instance_valid(target):
			_last_known_target_position = target.global_position
	elif target == null and had_target:
		target_lost.emit()
		set_state(EnemyState.PATROL if patrol_enabled else EnemyState.IDLE)


## 清除目标
func clear_target() -> void:
	"""
	清除当前目标
	"""
	set_target(null)


## 设置状态
func set_state(new_state: EnemyState) -> void:
	"""
	设置敌人状态
	@param new_state: 新状态
	"""
	if current_state == new_state:
		return
	
	var old_state: EnemyState = current_state
	current_state = new_state
	
	# 状态进入处理
	_on_state_enter(new_state)
	
	state_changed.emit(EnemyState.keys()[old_state], EnemyState.keys()[new_state])


## 眩晕
func stun(duration: float) -> void:
	"""
	眩晕敌人
	@param duration: 眩晕持续时间
	"""
	set_state(EnemyState.STUNNED)
	_stun_timer = duration
	velocity = Vector2.ZERO

# =============================================================================
# 公共方法 - AI控制
# =============================================================================

## 强制攻击
func force_attack() -> void:
	"""
	强制执行攻击（忽略冷却）
	"""
	_perform_attack()


## 停止移动
func stop_movement() -> void:
	"""
	停止移动
	"""
	velocity = Vector2.ZERO


## 移动到位置
func move_to_position(target_position: Vector2, speed_multiplier: float = 1.0) -> void:
	"""
	移动到指定位置
	@param target_position: 目标位置
	@param speed_multiplier: 速度倍率
	"""
	var direction: Vector2 = (target_position - global_position).normalized()
	velocity = direction * move_speed * speed_multiplier
	
	# 更新朝向
	if direction != Vector2.ZERO:
		facing_direction = direction

# =============================================================================
# 私有方法 - 初始化
# =============================================================================

func _initialize_enemy() -> void:
	"""
	初始化敌人内部状态
	"""
	# 设置碰撞层
	collision_layer = 2  # Enemy layer
	collision_mask = 1 | 16 | 64  # Player, Player Bullets, Obstacles
	
	# 添加到敌人组
	add_to_group("enemies")
	
	# 记录巡逻起点
	_patrol_start_position = global_position
	_patrol_target_position = _get_new_patrol_point()
	
	# 应用当前难度
	apply_difficulty(GameManager.difficulty_multiplier)
	
	# 初始化生命值
	current_health = max_health

# =============================================================================
# 私有方法 - 更新
# =============================================================================

func _update_timers(delta: float) -> void:
	"""
	更新各种计时器
	@param delta: 帧间隔时间
	"""
	# 攻击冷却
	if _attack_timer > 0:
		_attack_timer -= delta
	
	# 眩晕计时
	if _stun_timer > 0:
		_stun_timer -= delta
		if _stun_timer <= 0:
			set_state(EnemyState.IDLE if current_target == null else EnemyState.CHASE)
	
	# 受伤计时
	if _hurt_timer > 0:
		_hurt_timer -= delta
		if _hurt_timer <= 0 and current_state == EnemyState.HURT:
			set_state(EnemyState.CHASE if current_target != null else EnemyState.IDLE)
	
	# 追踪更新计时
	_track_timer += delta


func _update_ai(delta: float) -> void:
	"""
	更新AI逻辑
	@param delta: 帧间隔时间
	"""
	match current_state:
		EnemyState.IDLE:
			_handle_idle_state(delta)
		EnemyState.PATROL:
			_handle_patrol_state(delta)
		EnemyState.CHASE:
			_handle_chase_state(delta)
		EnemyState.ATTACK:
			_handle_attack_state(delta)
		EnemyState.STUNNED, EnemyState.HURT:
			_handle_stunned_state(delta)


func _handle_idle_state(_delta: float) -> void:
	"""
	处理空闲状态
	"""
	velocity = Vector2.ZERO
	
	# 检测玩家
	_check_for_targets()
	
	# 如果启用巡逻，切换到巡逻状态
	if patrol_enabled and current_target == null:
		set_state(EnemyState.PATROL)


func _handle_patrol_state(_delta: float) -> void:
	"""
	处理巡逻状态
	"""
	# 检测玩家
	_check_for_targets()
	
	if current_target != null:
		return
	
	# 移动到巡逻点
	var distance_to_target: float = global_position.distance_to(_patrol_target_position)
	
	if distance_to_target < 10.0:
		# 到达巡逻点，获取新巡逻点
		_patrol_target_position = _get_new_patrol_point()
		velocity = Vector2.ZERO
	else:
		move_to_position(_patrol_target_position, 0.5)


func _handle_chase_state(_delta: float) -> void:
	"""
	处理追逐状态
	"""
	if current_target == null or not is_instance_valid(current_target):
		clear_target()
		return
	
	# 更新目标位置
	if _track_timer >= track_precision:
		_track_timer = 0.0
		_last_known_target_position = current_target.global_position
	
	var distance_to_target: float = global_position.distance_to(current_target.global_position)
	
	# 检查是否超出追击范围
	if distance_to_target > chase_limit:
		clear_target()
		return
	
	# 检查是否进入攻击范围
	if distance_to_target <= attack_range:
		set_state(EnemyState.ATTACK)
		return
	
	# 追击目标
	move_to_position(current_target.global_position)


func _handle_attack_state(_delta: float) -> void:
	"""
	处理攻击状态
	"""
	velocity = Vector2.ZERO
	
	if current_target == null or not is_instance_valid(current_target):
		clear_target()
		return
	
	var distance_to_target: float = global_position.distance_to(current_target.global_position)
	
	# 目标离开攻击范围
	if distance_to_target > attack_range * 1.5:
		set_state(EnemyState.CHASE)
		return
	
	# 面向目标
	facing_direction = (current_target.global_position - global_position).normalized()
	
	# 执行攻击
	if _attack_timer <= 0 and not _is_attacking:
		_perform_attack()


func _handle_stunned_state(_delta: float) -> void:
	"""
	处理眩晕/受伤状态
	"""
	velocity = Vector2.ZERO


func _check_for_targets() -> void:
	"""
	检测范围内的目标
	"""
	var players: Array[Node] = get_tree().get_nodes_in_group("players")
	
	var closest_player: Node = null
	var closest_distance: float = detection_range
	
	for player in players:
		if not is_instance_valid(player):
			continue
		
		var distance: float = global_position.distance_to(player.global_position)
		if distance <= detection_range and distance < closest_distance:
			closest_distance = distance
			closest_player = player
	
	if closest_player != null:
		set_target(closest_player)

# =============================================================================
# 私有方法 - 攻击
# =============================================================================

func _perform_attack() -> void:
	"""
	执行攻击
	"""
	_is_attacking = true
	_attack_timer = attack_cooldown
	
	# 播放攻击动画
	_play_attack_animation()
	
	# 实际的伤害逻辑由子类实现
	await get_tree().create_timer(0.2).timeout
	
	# 检查目标是否仍在范围内
	if current_target != null and is_instance_valid(current_target):
		var distance: float = global_position.distance_to(current_target.global_position)
		if distance <= attack_range:
			_deal_damage_to_target(current_target)
	
	_is_attacking = false


func _deal_damage_to_target(target: Node) -> void:
	"""
	对目标造成伤害
	@param target: 目标节点
	"""
	if target.has_method("take_damage"):
		target.take_damage(attack_damage, self)
	
	# 播放攻击音效
	AudioManager.play_sfx_variant("enemy_attack", 3, 0.6)

# =============================================================================
# 私有方法 - 击退
# =============================================================================

func _apply_knockback(source_position: Vector2) -> void:
	"""
	应用击退效果
	@param source_position: 伤害来源位置
	"""
	if not can_be_knocked_back:
		return
	
	var knockback_direction: Vector2 = (global_position - source_position).normalized()
	var knockback_force: float = 150.0 * knockback_multiplier * (1.0 - KNOCKBACK_RESISTANCE)
	
	# 应用瞬移击退
	global_position += knockback_direction * knockback_force * 0.1
	
	# 设置速度
	velocity = knockback_direction * knockback_force

# =============================================================================
# 私有方法 - 掉落
# =============================================================================

func _drop_rewards(killer: Node) -> void:
	"""
	掉落奖励
	@param killer: 击杀者
	"""
	# 给予玩家经验值
	if killer and is_instance_valid(killer):
		if killer.has_node("Stats"):
			var stats: PlayerStats = killer.get_node("Stats")
			stats.add_experience(experience_reward)
		elif killer.has_method("get_node") and killer.get_node_or_null("Stats"):
			var stats: PlayerStats = killer.get_node("Stats")
			stats.add_experience(experience_reward)
	
	# 给予金币
	GameManager.gold_collected += gold_reward
	
	# 掉落物品
	_drop_items()


func _drop_items() -> void:
	"""
	掉落物品
	"""
	if possible_drops.is_empty():
		return
	
	if randf() > drop_chance:
		return
	
	var drop_count: int = randi_range(drop_count_range.x, drop_count_range.y)
	
	for i in range(drop_count):
		var item_id: String = possible_drops.pick_random()
		_spawn_drop(item_id)


func _spawn_drop(item_id: String) -> void:
	"""
	生成掉落物
	@param item_id: 物品ID
	"""
	# 创建掉落物节点
	var drop: Area2D = Area2D.new()
	drop.add_to_group("items")
	drop.add_to_group("drops")
	
	# 添加碰撞形状
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 10.0
	collision.shape = shape
	drop.add_child(collision)
	
	# 添加视觉效果
	var sprite: Sprite2D = Sprite2D.new()
	var texture: ImageTexture = ImageTexture.new()
	var image: Image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color.GOLD)
	texture.set_image(image)
	sprite.texture = texture
	drop.add_child(sprite)
	
	# 设置位置（带随机偏移）
	drop.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
	
	# 添加到场景
	get_tree().current_scene.add_child(drop)
	
	dropped_item.emit(drop)

# =============================================================================
# 私有方法 - 视觉效果
# =============================================================================

func _get_new_patrol_point() -> Vector2:
	"""
	获取新的巡逻点
	@return: 巡逻点位置
	"""
	var random_angle: float = randf() * TAU
	var random_distance: float = randf() * patrol_range
	return _patrol_start_position + Vector2(cos(random_angle), sin(random_angle)) * random_distance


func _play_hurt_effect() -> void:
	"""
	播放受伤效果
	"""
	# 停止之前的闪烁
	if _hit_flash_tween and _hit_flash_tween.is_valid():
		_hit_flash_tween.kill()
	
	# 闪烁效果
	_hit_flash_tween = create_tween()
	_hit_flash_tween.tween_property(self, "modulate", Color.RED, FLASH_DURATION)
	_hit_flash_tween.tween_property(self, "modulate", Color.WHITE, FLASH_DURATION)
	
	AudioManager.play_sfx_variant("enemy_hurt", 2, 0.5)


func _play_death_effect() -> void:
	"""
	播放死亡效果
	"""
	# 禁用碰撞
	collision_layer = 0
	collision_mask = 0
	
	# 播放死亡动画
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
	tween.parallel().tween_property(self, "modulate:a", 0.5, 0.2)
	tween.tween_property(self, "scale", Vector2(0.8, 0.8), 0.2)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)
	
	AudioManager.play_sfx("enemy_death", 0.7)


func _play_attack_animation() -> void:
	"""
	播放攻击动画
	"""
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.1)
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)


func _update_animation() -> void:
	"""
	更新动画状态
	"""
	# 根据速度更新朝向
	if velocity.length_squared() > 0:
		pass  # 可以添加行走动画


func _on_state_enter(state: EnemyState) -> void:
	"""
	进入新状态时的处理
	@param state: 新状态
	"""
	match state:
		EnemyState.IDLE, EnemyState.PATROL:
			current_target = null
		EnemyState.DEAD:
			velocity = Vector2.ZERO


func _schedule_despawn() -> void:
	"""
	安排销毁
	"""
	# 延迟销毁，让动画播放完成
	await get_tree().create_timer(0.6).timeout

# =============================================================================
# 对象池接口
# =============================================================================

func on_spawn() -> void:
	"""
	从对象池取出时的初始化
	"""
	is_dead = false
	current_health = max_health
	current_target = null
	set_state(EnemyState.IDLE)
	modulate = Color.WHITE
	scale = Vector2.ONE
	
	# 重新启用碰撞
	collision_layer = 2
	collision_mask = 1 | 16 | 64


func on_despawn() -> void:
	"""
	归还到对象池时的清理
	"""
	is_dead = true
	current_target = null
	velocity = Vector2.ZERO
	_attack_timer = 0.0
	_stun_timer = 0.0
	_is_attacking = false


func reset() -> void:
	"""
	重置敌人状态
	"""
	on_despawn()
	on_spawn()
