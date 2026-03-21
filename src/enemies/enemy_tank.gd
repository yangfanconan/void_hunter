## Void Hunter - 坦克敌人
## @description: 高血量、慢速、高防御的重型敌人
## @author: Void Hunter Team
## @version: 1.0.0

extends EnemyBase
class_name EnemyTank

# =============================================================================
# 导出变量
# =============================================================================

## 伤害减免百分比
@export_range(0.0, 0.8) var damage_reduction: float = 0.3

## 冲击波范围
@export var shockwave_range: float = 80.0

## 冲击波伤害
@export var shockwave_damage: float = 15.0

## 冲击波冷却
@export var shockwave_cooldown: float = 5.0

## 冲击波击退力度
@export var shockwave_knockback: float = 200.0

# =============================================================================
# 私有变量
# =============================================================================

var _shockwave_timer: float = 0.0

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""
	节点就绪时初始化
	"""
	# 设置坦克敌人属性
	enemy_type = EnemyType.TANK
	enemy_name = "坦克"
	
	# 高血量
	max_health = 150.0
	current_health = max_health
	
	# 慢速移动
	move_speed = 40.0
	
	# 高伤害
	attack_damage = 20.0
	attack_cooldown = 2.0
	
	# 近战范围
	attack_range = 50.0
	detection_range = 200.0
	
	# 不受击退影响
	can_be_knocked_back = false
	knockback_multiplier = 0.0
	
	# 掉落
	experience_reward = 30
	gold_reward = 15
	drop_chance = 0.3
	
	super._ready()


func _physics_process(delta: float) -> void:
	"""
	物理帧更新
	@param delta: 帧间隔时间
	"""
	# 更新冲击波冷却
	if _shockwave_timer > 0:
		_shockwave_timer -= delta
	
	super._physics_process(delta)

# =============================================================================
# 重写方法
# =============================================================================

func take_damage(amount: float, source: Node = null) -> void:
	"""
	受到伤害 - 应用伤害减免
	"""
	if is_dead:
		return
	
	# 应用伤害减免
	var reduced_damage: float = amount * (1.0 - damage_reduction)
	
	# 调用基类
	super.take_damage(reduced_damage, source)
	
	# 播放护甲效果
	_play_armor_effect()


func _perform_attack() -> void:
	"""
	执行攻击 - 普通攻击或冲击波
	"""
	_is_attacking = true
	_attack_timer = attack_cooldown
	
	# 检查是否使用冲击波
	if _shockwave_timer <= 0 and current_target != null:
		var distance: float = global_position.distance_to(current_target.global_position)
		if distance <= shockwave_range * 1.5:
			_perform_shockwave()
			_shockwave_timer = shockwave_cooldown
		else:
			await _perform_normal_attack()
	else:
		await _perform_normal_attack()
	
	_is_attacking = false


func _perform_normal_attack() -> void:
	"""
	执行普通攻击
	"""
	# 播放攻击动画
	_play_attack_animation()
	
	await get_tree().create_timer(0.3).timeout
	
	# 检查目标是否仍在范围内
	if current_target != null and is_instance_valid(current_target):
		var distance: float = global_position.distance_to(current_target.global_position)
		if distance <= attack_range:
			_deal_damage_to_target(current_target)

# =============================================================================
# 私有方法 - 冲击波
# =============================================================================

func _perform_shockwave() -> void:
	"""
	执行冲击波攻击
	"""
	# 播放冲击波动画
	_play_shockwave_animation()
	
	# 播放音效
	AudioManager.play_sfx("tank_shockwave", 0.8)
	
	await get_tree().create_timer(0.3).timeout
	
	# 对范围内所有目标造成伤害
	var targets: Array[Node] = get_tree().get_nodes_in_group("players")
	for target in targets:
		if not is_instance_valid(target):
			continue
		
		var distance: float = global_position.distance_to(target.global_position)
		if distance <= shockwave_range:
			# 造成伤害
			if target.has_method("take_damage"):
				target.take_damage(shockwave_damage, self)
			
			# 应用击退
			if "velocity" in target:
				var knockback_dir: Vector2 = (target.global_position - global_position).normalized()
				target.velocity += knockback_dir * shockwave_knockback


func _play_shockwave_animation() -> void:
	"""
	播放冲击波动画
	"""
	# 创建冲击波视觉效果
	var shockwave: Node2D = Node2D.new()
	shockwave.global_position = global_position
	
	var sprite: Sprite2D = Sprite2D.new()
	var texture: ImageTexture = ImageTexture.new()
	var image: Image = Image.create(4, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color.ORANGE)
	texture.set_image(image)
	sprite.texture = texture
	sprite.modulate = Color(1, 0.5, 0, 0.5)
	shockwave.add_child(sprite)
	
	get_tree().current_scene.add_child(shockwave)
	
	# 扩散动画
	var tween: Tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(shockwave_range / 2, shockwave_range / 2), 0.3)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.3)
	tween.tween_callback(shockwave.queue_free)


func _play_armor_effect() -> void:
	"""
	播放护甲效果
	"""
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate", Color(0.7, 0.7, 0.8), 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)

# =============================================================================
# 对象池接口
# =============================================================================

func on_spawn() -> void:
	"""
	从对象池取出时的初始化
	"""
	super.on_spawn()
	_shockwave_timer = 0.0
