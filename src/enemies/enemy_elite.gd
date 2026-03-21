## Void Hunter - 精英敌人
## @description: 强化的精英敌人，具有更高的属性和特殊能力
## @author: Void Hunter Team
## @version: 1.0.0

extends "res://src/enemies/enemy_base.gd"

# =============================================================================
# 信号定义
# =============================================================================

## 技能使用时触发
signal skill_used(skill_name: String)

# =============================================================================
# 常量定义
# =============================================================================

## 默认精英速度
const ELITE_SPEED: float = 90.0

## 默认精英生命值
const ELITE_HEALTH: float = 120.0

## 默认精英伤害
const ELITE_DAMAGE: float = 20.0

## 默认精英攻击范围
const ELITE_ATTACK_RANGE: float = 50.0

## 默认精英攻击冷却
const ELITE_ATTACK_COOLDOWN: float = 1.5

## 技能冷却时间
const SKILL_COOLDOWN: float = 8.0

# =============================================================================
# 枚举定义
# =============================================================================

## 精英技能类型
enum EliteSkill {
	DASH_ATTACK,	## 冲刺攻击
	WHIRLWIND,		## 旋风斩
	SUMMON,			## 召唤小怪
	HEAL			## 自我治疗
}

# =============================================================================
# 导出变量
# =============================================================================

## 精英技能
@export var elite_skill: EliteSkill = EliteSkill.DASH_ATTACK

## 技能冷却时间
@export_range(5.0, 15.0) var skill_cooldown: float = SKILL_COOLDOWN

## 冲刺速度倍率
@export_range(2.0, 4.0) var dash_speed_multiplier: float = 3.0

## 旋风斩范围
@export_range(50.0, 150.0) var whirlwind_range: float = 80.0

## 旋风斩伤害
@export var whirlwind_damage: float = 15.0

## 治疗量
@export var heal_amount: float = 30.0

# =============================================================================
# 私有变量
# =============================================================================

var _skill_cooldown_timer: float = 0.0
var _is_using_skill: bool = false
var _is_dashing: bool = false
var _dash_direction: Vector2 = Vector2.ZERO
var _dash_timer: float = 0.0
var _whirlwind_timer: float = 0.0

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""节点就绪时初始化"""
	_setup_elite_stats()
	super._ready()


func _physics_process(delta: float) -> void:
	"""物理帧更新"""
	# 更新技能冷却
	if _skill_cooldown_timer > 0:
		_skill_cooldown_timer -= delta
	
	# 处理冲刺
	if _is_dashing:
		_update_dash(delta)
		return
	
	# 处理旋风斩
	if _whirlwind_timer > 0:
		_update_whirlwind(delta)
		return
	
	# 调用父类处理
	super._physics_process(delta)

# =============================================================================
# 公共方法
# =============================================================================

## 使用技能
func use_skill() -> void:
	"""使用精英技能"""
	if _is_using_skill or _skill_cooldown_timer > 0:
		return
	
	_is_using_skill = true
	
	match elite_skill:
		EliteSkill.DASH_ATTACK:
			_perform_dash_attack()
		EliteSkill.WHIRLWIND:
			_perform_whirlwind()
		EliteSkill.SUMMON:
			_perform_summon()
		EliteSkill.HEAL:
			_perform_heal()


## 设置精英属性
func setup_elite(speed: float, health: float, damage: float) -> void:
	"""设置精英敌人属性"""
	move_speed = speed
	max_health = health
	attack_damage = damage
	current_health = max_health

# =============================================================================
# 私有方法 - 初始化
# =============================================================================

func _setup_elite_stats() -> void:
	"""设置精英敌人属性"""
	# 如果使用默认值，则设置精英专用属性
	if move_speed == DEFAULT_SPEED:
		move_speed = ELITE_SPEED
	if max_health == DEFAULT_MAX_HEALTH:
		max_health = ELITE_HEALTH
	if attack_damage == DEFAULT_ATTACK_DAMAGE:
		attack_damage = ELITE_DAMAGE
	if attack_range == DEFAULT_ATTACK_RANGE:
		attack_range = ELITE_ATTACK_RANGE
	if attack_cooldown == 1.0:
		attack_cooldown = ELITE_ATTACK_COOLDOWN
	
	# 设置敌人类型
	enemy_type = EnemyType.ELITE
	
	# 设置经验值和金币奖励
	experience_reward = 50
	gold_reward = 30
	
	# 旋风斩伤害
	whirlwind_damage = attack_damage * 0.75
	
	print("[EnemyElite] 初始化完成，技能: %d" % elite_skill)

# =============================================================================
# 私有方法 - 技能实现
# =============================================================================

func _perform_dash_attack() -> void:
	"""执行冲刺攻击"""
	if target == null or not is_instance_valid(target):
		_is_using_skill = false
		return
	
	_is_dashing = true
	_dash_direction = (target.global_position - global_position).normalized()
	_dash_timer = 0.5
	
	skill_used.emit("dash_attack")
	print("[EnemyElite] 使用冲刺攻击")


func _perform_whirlwind() -> void:
	"""执行旋风斩"""
	_whirlwind_timer = 1.0
	velocity = Vector2.ZERO
	
	skill_used.emit("whirlwind")
	print("[EnemyElite] 使用旋风斩")
	
	# 旋风斩期间持续造成伤害
	# 在 _update_whirlwind 中处理


func _perform_summon() -> void:
	"""执行召唤"""
	skill_used.emit("summon")
	print("[EnemyElite] 使用召唤")
	
	# 召唤2个小怪
	for i in range(2):
		_spawn_minion()
	
	_skill_cooldown_timer = skill_cooldown
	_is_using_skill = false


func _perform_heal() -> void:
	"""执行自我治疗"""
	skill_used.emit("heal")
	print("[EnemyElite] 使用治疗")
	
	heal(heal_amount)
	
	# 治疗特效
	modulate = Color(0.5, 1.0, 0.5)
	await get_tree().create_timer(0.3).timeout
	modulate = Color.WHITE
	
	_skill_cooldown_timer = skill_cooldown
	_is_using_skill = false

# =============================================================================
# 私有方法 - 更新
# =============================================================================

func _update_dash(delta: float) -> void:
	"""更新冲刺"""
	_dash_timer -= delta
	velocity = _dash_direction * move_speed * dash_speed_multiplier
	move_and_slide()
	
	# 检测碰撞
	var collision: KinematicCollision2D = get_last_slide_collision()
	if collision:
		var collider: Node = collision.get_collider()
		if collider and collider.is_in_group("players"):
			if collider.has_method("take_damage"):
				collider.take_damage(attack_damage * 1.5, self)
	
	if _dash_timer <= 0:
		_is_dashing = false
		_is_using_skill = false
		_skill_cooldown_timer = skill_cooldown


func _update_whirlwind(delta: float) -> void:
	"""更新旋风斩"""
	_whirlwind_timer -= delta
	
	# 旋转动画
	rotation += delta * 10.0
	
	# 每隔一段时间造成伤害
	if int(_whirlwind_timer * 10) % 3 == 0:
		_deal_whirlwind_damage()
	
	if _whirlwind_timer <= 0:
		rotation = 0
		_is_using_skill = false
		_skill_cooldown_timer = skill_cooldown


func _deal_whirlwind_damage() -> void:
	"""造成旋风斩伤害"""
	var players: Array[Node] = get_tree().get_nodes_in_group("players")
	for player_node in players:
		if player_node and is_instance_valid(player_node):
			var dist: float = global_position.distance_to(player_node.global_position)
			if dist <= whirlwind_range:
				if player_node.has_method("take_damage"):
					player_node.take_damage(whirlwind_damage, self)


func _spawn_minion() -> void:
	"""召唤小怪"""
	var minion: CharacterBody2D = CharacterBody2D.new()
	minion.set_script(preload("res://src/enemies/enemy_melee.gd"))
	minion.name = "EliteMinion"
	
	# 在精英周围随机位置生成
	var angle: float = randf() * TAU
	var dist: float = randf_range(50.0, 100.0)
	minion.global_position = global_position + Vector2(cos(angle), sin(angle)) * dist
	
	# 降低小怪属性
	minion.set("max_health", 15.0)
	minion.set("move_speed", 70.0)
	minion.set("attack_damage", 5.0)
	
	# 添加碰撞形状
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 10.0
	collision.shape = shape
	minion.add_child(collision)
	
	# 添加视觉表现
	var sprite: Sprite2D = Sprite2D.new()
	var texture: ImageTexture = ImageTexture.new()
	var image: Image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.6, 0.3, 0.1))
	texture.set_image(image)
	sprite.texture = texture
	minion.add_child(sprite)
	
	# 添加到场景
	var entities_container: Node = get_tree().current_scene.get_node_or_null("GameWorld/Entities")
	if entities_container:
		entities_container.add_child(minion)
	else:
		get_tree().current_scene.add_child(minion)

# =============================================================================
# 重写父类方法
# =============================================================================

func _update_chase(delta: float) -> void:
	"""更新追击状态"""
	# 检查是否可以使用技能
	if _skill_cooldown_timer <= 0 and target and is_instance_valid(target):
		var dist: float = global_position.distance_to(target.global_position)
		# 在合适距离使用技能
		if dist <= 150.0 and dist >= 50.0:
			use_skill()
			return
	
	# 调用父类处理
	super._update_chase(delta)

# =============================================================================
# 视觉效果
# =============================================================================

func _update_visuals() -> void:
	"""更新视觉效果"""
	super._update_visuals()
	
	# 精英有金色光环
	if not _is_using_skill:
		modulate = Color(1.0, 0.9, 0.7)
	else:
		modulate = Color.WHITE
