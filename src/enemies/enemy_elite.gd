## Void Hunter - 精英怪
## @description: 拥有特殊技能、高掉落的精英敌人
## @author: Void Hunter Team
## @version: 1.0.0

extends EnemyBase
class_name EnemyElite

# =============================================================================
# 信号定义
# =============================================================================

## 技能使用时触发
signal skill_used(skill_name: String)

# =============================================================================
# 枚举定义
# =============================================================================

## 精英技能类型
enum EliteSkill {
	DASH_ATTACK,	## 冲刺攻击
	SUMMON,		## 召唤小怪
	TELEPORT,	## 瞬移
	BERSERK		## 狂暴
}

# =============================================================================
# 导出变量
# =============================================================================

## 可用技能列表
@export var available_skills: Array[EliteSkill] = [EliteSkill.DASH_ATTACK]

## 技能冷却
@export var skill_cooldown: float = 5.0

## 冲刺攻击距离
@export var dash_attack_distance: float = 150.0

## 冲刺攻击伤害
@export var dash_attack_damage: float = 25.0

## 召唤数量
@export var summon_count: int = 3

## 狂暴攻击加成
@export var berserk_attack_bonus: float = 0.5

## 狂暴速度加成
@export var berserk_speed_bonus: float = 0.3

## 狂暴触发血量百分比
@export_range(0.0, 1.0) var berserk_health_threshold: float = 0.3

# =============================================================================
# 公共变量
# =============================================================================

## 是否处于狂暴状态
var is_berserking: bool = false

# =============================================================================
# 私有变量
# =============================================================================

var _skill_timer: float = 0.0
var _is_using_skill: bool = false
var _current_skill: EliteSkill = EliteSkill.DASH_ATTACK

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""
	节点就绪时初始化
	"""
	# 设置精英敌人属性
	enemy_type = EnemyType.ELITE
	enemy_name = "精英怪"
	
	# 高血量
	max_health = 100.0
	current_health = max_health
	
	# 中等速度
	move_speed = 90.0
	
	# 高伤害
	attack_damage = 15.0
	attack_cooldown = 1.2
	
	# 攻击范围
	attack_range = 60.0
	detection_range = 300.0
	
	# 高掉落
	experience_reward = 50
	gold_reward = 25
	drop_chance = 0.5
	
	super._ready()


func _physics_process(delta: float) -> void:
	"""
	物理帧更新
	@param delta: 帧间隔时间
	"""
	# 更新技能冷却
	if _skill_timer > 0:
		_skill_timer -= delta
	
	# 检查狂暴
	_check_berserk()
	
	super._physics_process(delta)

# =============================================================================
# 重写方法
# =============================================================================

func take_damage(amount: float, source: Node = null) -> void:
	"""
	受到伤害 - 检查狂暴触发
	"""
	super.take_damage(amount, source)
	
	# 检查狂暴
	_check_berserk()


func _handle_attack_state(_delta: float) -> void:
	"""
	处理攻击状态 - 可能使用技能
	"""
	if current_target == null or not is_instance_valid(current_target):
		clear_target()
		return
	
	var distance_to_target: float = global_position.distance_to(current_target.global_position)
	
	# 目标离开攻击范围
	if distance_to_target > attack_range * 2.0:
		set_state(EnemyState.CHASE)
		return
	
	# 面向目标
	facing_direction = (current_target.global_position - global_position).normalized()
	
	# 检查是否使用技能
	if _skill_timer <= 0 and not _is_using_skill and not _is_attacking:
		var skill: EliteSkill = _choose_skill(distance_to_target)
		if skill != EliteSkill.DASH_ATTACK or distance_to_target <= dash_attack_distance:
			_use_skill(skill)
			return
	
	# 普通攻击
	if _attack_timer <= 0 and not _is_attacking and not _is_using_skill:
		_perform_attack()

# =============================================================================
# 私有方法 - 狂暴
# =============================================================================

func _check_berserk() -> void:
	"""
	检查是否触发狂暴
	"""
	if is_berserking:
		return
	
	var health_percent: float = current_health / max_health
	if health_percent <= berserk_health_threshold:
		_enter_berserk()


func _enter_berserk() -> void:
	"""
	进入狂暴状态
	"""
	is_berserking = true
	
	# 应用加成
	attack_damage *= (1.0 + berserk_attack_bonus)
	move_speed *= (1.0 + berserk_speed_bonus)
	
	# 视觉效果
	_play_berserk_effect()
	
	# 触发信号
	skill_used.emit("berserk")
	
	# 播放音效
	AudioManager.play_sfx("elite_berserk", 0.9)


func _play_berserk_effect() -> void:
	"""
	播放狂暴效果
	"""
	# 身体变红
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate", Color(1.5, 0.5, 0.5), 0.3)
	
	# 放大效果
	tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.2)
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1)

# =============================================================================
# 私有方法 - 技能
# =============================================================================

func _choose_skill(distance: float) -> EliteSkill:
	"""
	根据距离选择技能
	@param distance: 到目标的距离
	@return: 选择的技能
	"""
	if available_skills.is_empty():
		return EliteSkill.DASH_ATTACK
	
	# 根据距离选择合适的技能
	for skill in available_skills:
		match skill:
			EliteSkill.DASH_ATTACK:
				if distance <= dash_attack_distance and distance > attack_range:
					return skill
			EliteSkill.SUMMON:
				if distance <= attack_range * 2:
					return skill
			EliteSkill.TELEPORT:
				if distance > attack_range * 2:
					return skill
			EliteSkill.BERSERK:
				if not is_berserking:
					return skill
	
	# 默认返回第一个可用技能
	return available_skills[0]


func _use_skill(skill: EliteSkill) -> void:
	"""
	使用技能
	@param skill: 技能类型
	"""
	_is_using_skill = true
	_skill_timer = skill_cooldown
	_current_skill = skill
	
	match skill:
		EliteSkill.DASH_ATTACK:
			await _use_dash_attack()
		EliteSkill.SUMMON:
			await _use_summon()
		EliteSkill.TELEPORT:
			await _use_teleport()
		EliteSkill.BERSERK:
			_enter_berserk()
	
	_is_using_skill = false
	skill_used.emit(EliteSkill.keys()[skill])


func _use_dash_attack() -> void:
	"""
	使用冲刺攻击
	"""
	if current_target == null:
		return
	
	# 记录目标位置
	var target_pos: Vector2 = current_target.global_position
	var dash_direction: Vector2 = (target_pos - global_position).normalized()
	
	# 前摇动画
	_play_skill_windup()
	await get_tree().create_timer(0.3).timeout
	
	# 冲刺
	var dash_speed: float = move_speed * 5.0
	var dash_time: float = 0.3
	var elapsed: float = 0.0
	var start_pos: Vector2 = global_position
	
	while elapsed < dash_time:
		elapsed += get_physics_process_delta_time()
		global_position = start_pos + dash_direction * dash_speed * elapsed
		await get_tree().physics_frame
	
	# 对路径上的目标造成伤害
	_deal_dash_damage(target_pos, dash_direction)
	
	# 结束动画
	_play_skill_end()


func _deal_dash_damage(end_pos: Vector2, _direction: Vector2) -> void:
	"""
	对冲刺路径上的目标造成伤害
	"""
	var players: Array[Node] = get_tree().get_nodes_in_group("players")
	for player in players:
		if not is_instance_valid(player):
			continue
		
		var distance: float = global_position.distance_to(player.global_position)
		if distance <= 50.0:
			if player.has_method("take_damage"):
				player.take_damage(dash_attack_damage, self)


func _use_summon() -> void:
	"""
	使用召唤技能
	"""
	# 播放召唤动画
	_play_summon_animation()
	
	await get_tree().create_timer(0.5).timeout
	
	# 召唤小怪
	for i in range(summon_count):
		_spawn_minion()
		await get_tree().create_timer(0.2).timeout


func _spawn_minion() -> void:
	"""
	生成小怪
	"""
	var minion: EnemyMelee = EnemyMelee.new()
	
	# 设置位置（在精英周围）
	var angle: float = randf() * TAU
	var distance: float = randf_range(50.0, 100.0)
	minion.global_position = global_position + Vector2(cos(angle), sin(angle)) * distance
	
	# 设置属性（较弱的小怪）
	minion.max_health = 20.0
	minion.current_health = 20.0
	minion.attack_damage = 5.0
	minion.experience_reward = 3
	
	# 添加碰撞
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 12.0
	collision.shape = shape
	minion.add_child(collision)
	
	# 添加视觉效果
	var sprite: Sprite2D = Sprite2D.new()
	var texture: ImageTexture = ImageTexture.new()
	var image: Image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.6, 0.3, 0.3))
	texture.set_image(image)
	sprite.texture = texture
	minion.add_child(sprite)
	
	# 添加到场景
	get_tree().current_scene.add_child(minion)
	
	# 设置目标
	if current_target != null:
		minion.set_target(current_target)


func _use_teleport() -> void:
	"""
	使用瞬移技能
	"""
	if current_target == null:
		return
	
	# 播放消失动画
	_play_teleport_start()
	await get_tree().create_timer(0.3).timeout
	
	# 瞬移到目标背后
	var target_pos: Vector2 = current_target.global_position
	var behind_direction: Vector2 = -facing_direction
	var teleport_pos: Vector2 = target_pos + behind_direction * 50.0
	
	global_position = teleport_pos
	
	# 播放出现动画
	_play_teleport_end()


func _play_skill_windup() -> void:
	"""
	播放技能前摇动画
	"""
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate", Color(1.5, 1.5, 0), 0.2)
	tween.parallel().tween_property(self, "scale", Vector2(1.15, 1.15), 0.2)


func _play_skill_end() -> void:
	"""
	播放技能结束动画
	"""
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate", Color(1.5, 0.5, 0.5) if is_berserking else Color.WHITE, 0.2)
	tween.parallel().tween_property(self, "scale", Vector2(1.1, 1.1) if is_berserking else Vector2.ONE, 0.2)


func _play_summon_animation() -> void:
	"""
	播放召唤动画
	"""
	modulate = Color(0.8, 0.4, 1.0)
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.2)
	tween.tween_property(self, "scale", Vector2.ONE, 0.3)
	await tween.finished
	modulate = Color(1.5, 0.5, 0.5) if is_berserking else Color.WHITE


func _play_teleport_start() -> void:
	"""
	播放瞬移开始动画
	"""
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.parallel().tween_property(self, "scale", Vector2(0.5, 0.5), 0.2)


func _play_teleport_end() -> void:
	"""
	播放瞬移结束动画
	"""
	scale = Vector2(0.5, 0.5)
	modulate.a = 0.0
	
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	tween.parallel().tween_property(self, "scale", Vector2(1.1, 1.1) if is_berserking else Vector2.ONE, 0.2)

# =============================================================================
# 对象池接口
# =============================================================================

func on_spawn() -> void:
	"""
	从对象池取出时的初始化
	"""
	super.on_spawn()
	_skill_timer = 0.0
	_is_using_skill = false
	is_berserking = false
