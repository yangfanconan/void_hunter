## Void Hunter - 玩家控制器
## 玩家移动、射击、冲刺和受伤逻辑

extends CharacterBody2D

signal damaged(amount: float)
signal died()
signal leveled_up(new_level: int)
signal skill_selected(skill_id: String)  ## 技能被选中时触发
signal skill_unlocked(skill_id: String)  ## 技能被解锁时触发
signal skills_changed()  ## 技能列表变化时触发

const BASE_MOVE_SPEED: float = 200.0
const DASH_SPEED: float = 500.0
const DASH_DURATION: float = 0.15
const DASH_COOLDOWN: float = 0.8
const INVINCIBILITY_TIME: float = 0.5
const SHOOT_COOLDOWN: float = 0.2
const AUTO_SHOOT_RANGE: float = 500.0

@export var move_speed: float = BASE_MOVE_SPEED
@export var bullet_damage: float = 15.0
@export var bullet_speed: float = 600.0
@export var auto_shoot: bool = true

var aim_direction: Vector2 = Vector2.RIGHT
var move_direction: Vector2 = Vector2.ZERO
var current_target: Node = null

var current_health: float = 100.0
var max_health: float = 100.0
var current_mana: float = 50.0
var max_mana: float = 50.0
var current_stamina: float = 100.0
var max_stamina: float = 100.0
var current_exp: int = 0
var exp_required: int = 50
var level: int = 1

var _is_dashing: bool = false
var _dash_timer: float = 0.0
var _dash_direction: Vector2 = Vector2.ZERO
var _dash_cooldown_timer: float = 0.0
var _is_invincible: bool = false
var _invincibility_timer: float = 0.0
var _shoot_timer: float = 0.0
var _can_shoot: bool = true
var _projectiles_container: Node = null

# 动画相关
var _anim_sprite: AnimatedSprite2D = null
var _current_anim: String = "idle"

# 升级效果相关
var _level_up_effect: Node2D = null
var _is_leveling_up: bool = false

# 属性加成
var attack_bonus_percent: float = 0.0  ## 攻击力加成百分比
var health_bonus: int = 0  ## 生命值加成
var speed_bonus_percent: float = 0.0  ## 移动速度加成百分比
var crit_chance_bonus: float = 0.0  ## 暴击率加成
var life_steal_percent: float = 0.0  ## 吸血百分比

# =============================================================================
# 技能系统
# =============================================================================

## 已解锁的主动技能ID列表（用于保存/显示）
var unlocked_skills: Array[String] = []

## 技能管理器实例
var skill_manager: Node = null

## 技能快捷键槽位（最多4个）
var skill_hotkeys: Array[String] = ["", "", "", ""]

func _ready() -> void:
	# 设置碰撞层（第1层 = 玩家层）
	collision_layer = 1
	collision_mask = 2 | 16  # 检测敌人(第2层)和障碍物(第5层)
	
	_ensure_collision()
	_ensure_visual()
	_find_projectiles_container()
	_create_level_up_effect()
	_init_skill_manager()  # 初始化技能管理器
	add_to_group("players")
	
	# 激活相机跟随
	_activate_camera()
	
	print("[Player] 初始化完成")

func _physics_process(delta: float) -> void:
	_update_timers(delta)
	
	if _is_dashing:
		_update_dash(delta)
	else:
		_update_movement(delta)
	
	_update_shooting(delta)
	_update_skills(delta)  # 更新技能状态
	move_and_slide()

func _process(_delta: float) -> void:
	_update_aim_direction()
	_update_visuals()
	_handle_skill_input()  # 处理技能快捷键输入

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("dash"):
		_try_dash()
	
	# 调试模式：按 F1 立即升级
	if event is InputEventKey and event.keycode == KEY_F1 and event.pressed:
		_debug_level_up()

func _debug_level_up() -> void:
	"""调试功能：立即升级"""
	print("[Player] 调试升级!")
	gain_experience(exp_required - current_exp + 1)

func _ensure_collision() -> void:
	var has_collision: bool = false
	for child in get_children():
		if child is CollisionShape2D:
			has_collision = true
	if not has_collision:
		var collision := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = 12.0
		collision.shape = shape
		add_child(collision)

func _ensure_visual() -> void:
	# 先检查是否已有 AnimatedSprite2D
	for child in get_children():
		if child is AnimatedSprite2D:
			_anim_sprite = child
			return
	
	# 如果有旧的 Sprite2D，先移除（game.gd 可能已添加）
	var old_sprite: Sprite2D = null
	for child in get_children():
		if child is Sprite2D:
			old_sprite = child
			break
	if old_sprite:
		remove_child(old_sprite)
		old_sprite.queue_free()
		print("[Player] 移除旧 Sprite2D")
	
	# 尝试从 AnimationManager 加载动画
	var anim_mgr := _get_animation_manager()
	if anim_mgr:
		var sf: Variant = anim_mgr.get_entity_sprite_frames("player")
		if sf:
			_anim_sprite = AnimatedSprite2D.new()
			_anim_sprite.name = "PlayerAnim"
			_anim_sprite.sprite_frames = sf
			_anim_sprite.play("idle")
			if not _anim_sprite.animation_finished.is_connected(_on_anim_finished):
				_anim_sprite.animation_finished.connect(_on_anim_finished)
			add_child(_anim_sprite)
			print("[Player] 动画精灵加载成功")
			return

	# 后备：使用色块
	var sprite := Sprite2D.new()
	var texture := ImageTexture.new()
	var image := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.2, 0.8, 0.3))
	texture.set_image(image)
	sprite.texture = texture
	add_child(sprite)

func _play_animation(anim_name: String) -> void:
	if _anim_sprite == null or not is_instance_valid(_anim_sprite):
		return
	if _current_anim == anim_name:
		return
	if not _anim_sprite.sprite_frames or not _anim_sprite.sprite_frames.has_animation(anim_name):
		return
	_current_anim = anim_name
	_anim_sprite.play(anim_name)

func _on_anim_finished() -> void:
	if _current_anim in ["attack", "hurt", "dash"]:
		_play_animation("idle")

func _find_projectiles_container() -> void:
	var main := get_tree().current_scene
	if main:
		_projectiles_container = main.get_node_or_null("GameWorld/Projectiles")


func _get_animation_manager() -> Node:
	"""安全获取AnimationManager"""
	if get_tree() and get_tree().root:
		return get_tree().root.get_node_or_null("AnimationManager")
	return null

func _update_timers(delta: float) -> void:
	if _dash_cooldown_timer > 0:
		_dash_cooldown_timer -= delta
	
	if _is_invincible:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0:
			_is_invincible = false
	
	if _shoot_timer > 0:
		_shoot_timer -= delta
		if _shoot_timer <= 0:
			_can_shoot = true
	
	if move_direction == Vector2.ZERO:
		current_stamina = min(current_stamina + 5.0 * delta, max_stamina)

## 移动端摇杆方向（由 MobileControls 设置）
var mobile_move_direction: Vector2 = Vector2.ZERO


func _update_movement(_delta: float) -> void:
	var input_dir := Vector2.ZERO
	
	if OS.has_feature("mobile") or DisplayServer.is_touchscreen_available():
		input_dir = mobile_move_direction
	else:
		input_dir.x = Input.get_axis("move_left", "move_right")
		input_dir.y = Input.get_axis("move_up", "move_down")
	
	move_direction = input_dir.normalized()
	velocity = move_direction * get_actual_move_speed()

func _update_dash(delta: float) -> void:
	_dash_timer -= delta
	velocity = _dash_direction * DASH_SPEED
	
	if _dash_timer <= 0:
		_end_dash()

func _update_shooting(_delta: float) -> void:
	if _can_shoot:
		if auto_shoot:
			_auto_aim_and_shoot()
		elif Input.is_action_pressed("shoot"):
			_shoot()
			_can_shoot = false
			_shoot_timer = SHOOT_COOLDOWN

func _auto_aim_and_shoot() -> void:
	var target := _find_best_target()
	if target:
		aim_direction = (target.global_position - global_position).normalized()
		_shoot()
		_can_shoot = false
		_shoot_timer = SHOOT_COOLDOWN

func _find_best_target() -> Node:
	var enemies := get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return null
	
	var best_target: Node = null
	var best_score: float = -1.0
	
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy.has_method("is_dead") and enemy.is_dead():
			continue
		
		var dist := global_position.distance_to(enemy.global_position)
		if dist > AUTO_SHOOT_RANGE:
			continue
		
		var score := _calculate_target_score(enemy, dist)
		if score > best_score:
			best_score = score
			best_target = enemy
	
	return best_target

func _calculate_target_score(enemy: Node, distance: float) -> float:
	var score := 0.0
	
	var enemy_type: String = "normal"
	if "enemy_type" in enemy:
		var type_value = enemy.enemy_type
		match type_value:
			0: enemy_type = "melee"
			1: enemy_type = "ranged"
			2: enemy_type = "tank"
			3: enemy_type = "elite"
			4: enemy_type = "boss"
	
	match enemy_type:
		"boss": score += 1000.0
		"elite": score += 500.0
		"tank": score += 300.0
		"ranged": score += 200.0
		_: score += 100.0
	
	var health_percent := 1.0
	if "current_health" in enemy and "max_health" in enemy:
		health_percent = enemy.current_health / enemy.max_health
	score += (1.0 - health_percent) * 200.0
	
	score -= distance * 0.5
	
	return score

func _update_aim_direction() -> void:
	if auto_shoot and current_target:
		aim_direction = (current_target.global_position - global_position).normalized()
	else:
		var mouse_pos := get_global_mouse_position()
		aim_direction = (mouse_pos - global_position).normalized()

func _update_visuals() -> void:
	if _is_invincible:
		modulate.a = 0.5 if fmod(Time.get_ticks_msec(), 100) < 50 else 1.0
	else:
		modulate.a = 1.0
	
	if _is_dashing:
		scale = Vector2(1.2, 0.8)
		_play_animation("dash")
	else:
		scale = Vector2.ONE
		if move_direction != Vector2.ZERO:
			_play_animation("walk")
		elif _current_anim not in ["attack", "hurt", "dash"]:
			_play_animation("idle")

func _try_dash() -> void:
	if _is_dashing or _dash_cooldown_timer > 0:
		return
	
	if current_stamina < 20.0:
		return
	
	current_stamina -= 20.0
	_start_dash()

func _start_dash() -> void:
	_is_dashing = true
	_dash_timer = DASH_DURATION
	_dash_cooldown_timer = DASH_COOLDOWN
	_is_invincible = true
	
	if move_direction != Vector2.ZERO:
		_dash_direction = move_direction
	else:
		_dash_direction = aim_direction
	
	print("[Player] 冲刺")

func _end_dash() -> void:
	_is_dashing = false
	_is_invincible = false

func _shoot() -> void:
	"""
	发射子弹
	根据当前激活的被动技能修改子弹行为
	"""
	# 检查是否有弹幕技能激活
	var fire_mode: String = _get_current_fire_mode()

	match fire_mode:
		"fan":
			_shoot_fan()
		"spiral":
			_shoot_spiral()
		"spread":
			_shoot_spread()
		"double":
			_shoot_double()
		"triple":
			_shoot_triple()
		_:  # "normal"
			_shoot_normal()


func _get_current_fire_mode() -> String:
	"""
	获取当前射击模式
	根据已解锁的被动技能决定
	"""
	# 检查是否拥有扇形弹幕技能
	if has_skill("fan_shot"):
		return "fan"
	
	# 检查是否拥有圆形弹幕技能（改为螺旋射击）
	if has_skill("circular_burst"):
		return "spiral"
	
	# 检查是否拥有追踪导弹技能（双发）
	if has_skill("homing_missile"):
		return "double"
	
	# 检查是否拥有闪电风暴技能（三发）
	if has_skill("lightning_storm"):
		return "triple"
	
	# 检查是否拥有其他攻击技能
	if has_skill("fire_bullet") or has_skill("frost_arrow") or has_skill("lightning_chain"):
		return "spread"
	
	return "normal"


func _shoot_normal() -> void:
	"""普通单发射击"""
	_create_bullet(aim_direction, global_position + aim_direction * 15.0)


func _shoot_fan() -> void:
	"""扇形射击模式"""
	var bullet_count: int = 5
	var spread_angle: float = deg_to_rad(45.0)  # 总展开角度
	var base_angle: float = aim_direction.angle() - spread_angle / 2.0
	var angle_step: float = spread_angle / (bullet_count - 1) if bullet_count > 1 else 0.0

	for i in range(bullet_count):
		var angle: float = base_angle + angle_step * i
		var direction: Vector2 = Vector2(cos(angle), sin(angle))
		_create_bullet(direction, global_position + direction * 15.0, 0.6)  # 60%伤害


func _shoot_spiral() -> void:
	"""螺旋射击模式"""
	# 使用时间来旋转角度
	var time: float = Time.get_ticks_msec() / 1000.0
	var spiral_angle: float = time * 3.0  # 旋转速度

	# 发射3颗子弹，轻微螺旋
	for i in range(3):
		var angle: float = aim_direction.angle() + sin(spiral_angle + i * 0.5) * 0.3
		var direction: Vector2 = Vector2(cos(angle), sin(angle))
		_create_bullet(direction, global_position + direction * 15.0, 0.7)


func _shoot_spread() -> void:
	"""散射模式"""
	# 发射3颗子弹
	var angles: Array[float] = [-0.15, 0.0, 0.15]  # 相对偏移角度

	for angle_offset in angles:
		var angle: float = aim_direction.angle() + angle_offset
		var direction: Vector2 = Vector2(cos(angle), sin(angle))
		_create_bullet(direction, global_position + direction * 15.0, 0.8)


func _shoot_double() -> void:
	"""双发射击模式"""
	# 平行发射两颗子弹
	var perpendicular: Vector2 = Vector2(-aim_direction.y, aim_direction.x)
	var offset: float = 8.0

	_create_bullet(aim_direction, global_position + aim_direction * 15.0 + perpendicular * offset)
	_create_bullet(aim_direction, global_position + aim_direction * 15.0 - perpendicular * offset)


func _shoot_triple() -> void:
	"""三发射击模式"""
	# 发射三颗子弹
	var perpendicular: Vector2 = Vector2(-aim_direction.y, aim_direction.x)
	var offset: float = 10.0

	_create_bullet(aim_direction, global_position + aim_direction * 15.0)
	_create_bullet(aim_direction, global_position + aim_direction * 15.0 + perpendicular * offset, 0.8)
	_create_bullet(aim_direction, global_position + aim_direction * 15.0 - perpendicular * offset, 0.8)


func _create_bullet(direction: Vector2, spawn_pos: Vector2, damage_mult: float = 1.0) -> void:
	"""
	创建单颗子弹
	@param direction: 子弹方向
	@param spawn_pos: 生成位置
	@param damage_mult: 伤害倍率
	"""
	var bullet := Area2D.new()
	bullet.name = "PlayerBullet"

	var bullet_script: GDScript = load("res://src/projectiles/bullet_base.gd")
	bullet.set_script(bullet_script)
	bullet.set("direction", direction)
	bullet.set("speed", bullet_speed)
	# 使用包含加成的实际攻击力
	var final_damage: float = get_actual_damage() * damage_mult

	# 检查暴击
	if roll_crit():
		final_damage *= 1.5  # 暴击1.5倍伤害
		bullet.set("is_crit", true)

	bullet.set("damage", final_damage)
	bullet.set("is_player_bullet", true)
	bullet.global_position = spawn_pos

	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 5.0
	collision.shape = shape
	bullet.add_child(collision)

	# 根据技能类型设置子弹颜色
	var bullet_color: Color = _get_bullet_color()

	var sprite := Sprite2D.new()
	var texture := ImageTexture.new()
	var image := Image.create(10, 10, false, Image.FORMAT_RGBA8)
	image.fill(bullet_color)
	texture.set_image(image)
	sprite.texture = texture
	bullet.add_child(sprite)

	# 如果有追踪导弹技能，给子弹添加轻微追踪
	if has_skill("homing_missile"):
		_add_homing_to_bullet(bullet, direction)

	if _projectiles_container:
		_projectiles_container.add_child(bullet)
	else:
		get_tree().current_scene.add_child(bullet)


func _get_bullet_color() -> Color:
	"""
	根据当前技能获取子弹颜色
	"""
	if has_skill("fire_bullet"):
		return Color(1.0, 0.4, 0.1)  # 火焰橙
	if has_skill("frost_arrow"):
		return Color(0.5, 0.8, 1.0)  # 冰霜蓝
	if has_skill("lightning_chain"):
		return Color(1.0, 1.0, 0.4)  # 闪电黄
	if has_skill("shadow_slash"):
		return Color(0.5, 0.3, 0.8)  # 暗影紫
	if has_skill("lightning_storm"):
		return Color(0.7, 0.9, 1.0)  # 风暴青
	if has_skill("laser_beam"):
		return Color(0.3, 0.9, 0.9)  # 激光青

	return Color(0.2, 0.8, 0.9)  # 默认青色


func _add_homing_to_bullet(bullet: Area2D, original_direction: Vector2) -> void:
	"""
	给子弹添加轻微追踪能力
	"""
	# 保存原始物理处理方法
	var script: GDScript = GDScript.new()
	script.source_code = """
extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 600.0
var damage: float = 15.0
var is_player_bullet: bool = true
var is_crit: bool = false
var owner_node: Node = null
var lifetime: float = 3.0
var homing_strength: float = 1.5

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

	# 轻微追踪
	var target = _find_closest_enemy()
	if target and is_instance_valid(target):
		var target_dir: Vector2 = (target.global_position - global_position).normalized()
		direction = direction.lerp(target_dir, homing_strength * delta).normalized()

	position += direction * speed * delta

func _find_closest_enemy() -> Node:
	var enemies: Array = get_tree().get_nodes_in_group("enemies")
	var closest: Node = null
	var closest_dist: float = 200.0  # 追踪范围

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist: float = global_position.distance_to(enemy.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = enemy

	return closest

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage, owner_node)
		if owner_node and owner_node.has_method("apply_life_steal"):
			owner_node.apply_life_steal(damage)
	queue_free()

func _on_area_entered(area: Node) -> void:
	var parent = area.get_parent()
	if parent and parent.is_in_group("enemies") and parent.has_method("take_damage"):
		parent.take_damage(damage, owner_node)
		if owner_node and owner_node.has_method("apply_life_steal"):
			owner_node.apply_life_steal(damage)
	queue_free()
"""
	script.reload()

	# 只有在有追踪导弹技能时才替换脚本
	if has_skill("homing_missile"):
		bullet.set_script(script)
		bullet.set("homing_strength", 2.0)  # 更强的追踪

func take_damage(amount: float, source: Node = null) -> void:
	if _is_invincible or _is_dashing:
		return
	
	current_health = max(0, current_health - amount)
	damaged.emit(amount, source)
	
	print("[Player] 受伤: %.1f, 剩余: %.1f" % [amount, current_health])
	
	if current_health <= 0:
		die()
	else:
		_is_invincible = true
		_invincibility_timer = INVINCIBILITY_TIME
		_play_animation("hurt")
		if VFXManager:
			VFXManager.spawn_hit_spark(global_position)

func heal(amount: float) -> void:
	current_health = min(current_health + amount, max_health)
	print("[Player] 治疗: %.1f, 当前: %.1f" % [amount, current_health])

func die() -> void:
	died.emit()
	print("[Player] 死亡")
	
	var game := get_tree().current_scene
	if game and game.has_method("handle_player_death"):
		game.handle_player_death()

func gain_experience(amount: int) -> void:
	current_exp += amount
	print("[Player] 获得经验: %d, 当前: %d/%d" % [amount, current_exp, exp_required])
	
	while current_exp >= exp_required:
		_level_up()

func _level_up() -> void:
	current_exp -= exp_required
	level += 1
	exp_required = int(50 + level * 10)
	
	max_health += 10 + health_bonus
	current_health = max_health
	max_mana += 5
	current_mana = max_mana
	
	_is_leveling_up = true
	leveled_up.emit(level)
	print("[Player] 升级到 %d!" % level)
	_play_level_up_effect()


## 播放升级效果
func _play_level_up_effect() -> void:
	"""播放升级视觉效果并触发技能选择"""
	if _level_up_effect and is_instance_valid(_level_up_effect):
		_level_up_effect.play_level_up_effect(self)


## 创建升级效果节点
func _create_level_up_effect() -> void:
	"""创建升级效果节点"""
	# 检查是否已存在
	if _level_up_effect and is_instance_valid(_level_up_effect):
		return
	
	# 创建升级效果
	var effect_script := preload("res://src/effects/level_up_effect.gd")
	_level_up_effect = Node2D.new()
	_level_up_effect.set_script(effect_script)
	_level_up_effect.name = "LevelUpEffect"
	
	# 添加到场景
	var main := get_tree().current_scene
	if main:
		main.add_child(_level_up_effect)
	else:
		get_parent().add_child(_level_up_effect)
	
	# 连接信号
	if _level_up_effect.has_signal("skill_selection_completed"):
		_level_up_effect.skill_selection_completed.connect(_on_skill_selection_completed)


## 技能选择完成回调
func _on_skill_selection_completed(skill_id: String) -> void:
	"""技能选择完成"""
	_is_leveling_up = false
	
	if skill_id != "":
		_apply_skill_bonus(skill_id)
		skill_selected.emit(skill_id)


## 应用技能加成
func _apply_skill_bonus(skill_id: String) -> void:
	"""应用技能加成到玩家属性"""
	match skill_id:
		# 属性加成类
		"attack_boost", "fire_bullet", "frost_arrow", "lightning_chain", "shadow_slash":
			attack_bonus_percent += 0.1
			print("[Player] 攻击力提升 10%%")
		
		"health_boost":
			health_bonus += 20
			max_health += 20
			current_health = min(current_health + 20, max_health)
			print("[Player] 生命值提升 20")
		
		"speed_boost", "blink", "speed_aura":
			speed_bonus_percent += 0.05
			print("[Player] 移动速度提升 5%%")
		
		"crit_boost":
			crit_chance_bonus += 0.05
			print("[Player] 暴击率提升 5%%")
		
		"life_steal":
			life_steal_percent += 0.03
			print("[Player] 获得吸血 3%%")
		
		# 防御类
		"shield", "iron_wall", "reflect":
			print("[Player] 获得防御技能: %s" % skill_id)
		
		# 控制类
		"time_slow", "gravity_field":
			print("[Player] 获得控制技能: %s" % skill_id)
		
		# 辅助类
		"healing_aura":
			print("[Player] 获得治疗光环")
		
		# 新增弹幕技能
		"fan_shot":
			attack_bonus_percent += 0.05
			print("[Player] 获得扇形弹幕，攻击力提升 5%%")
		
		"circular_burst":
			attack_bonus_percent += 0.05
			print("[Player] 获得圆形弹幕，攻击力提升 5%%")
		
		"laser_beam":
			attack_bonus_percent += 0.08
			print("[Player] 获得激光束，攻击力提升 8%%")
		
		"screen_nuke":
			attack_bonus_percent += 0.1
			max_mana += 20
			current_mana = min(current_mana + 20, max_mana)
			print("[Player] 获得毁灭打击，攻击力提升 10%%，法力+20")
		
		"homing_missile":
			attack_bonus_percent += 0.05
			print("[Player] 获得追踪导弹，攻击力提升 5%%")
		
		"lightning_storm":
			attack_bonus_percent += 0.06
			crit_chance_bonus += 0.03
			print("[Player] 获得闪电风暴，攻击力提升 6%%，暴击率+3%%")
		
		_:
			print("[Player] 获得技能: %s" % skill_id)


## 获取实际移动速度（包含加成）
func get_actual_move_speed() -> float:
	"""获取包含加成的实际移动速度"""
	return move_speed * (1.0 + speed_bonus_percent)


## 获取实际攻击力（包含加成）
func get_actual_damage() -> float:
	"""获取包含加成的实际攻击力"""
	return bullet_damage * (1.0 + attack_bonus_percent)


## 检查是否暴击
func roll_crit() -> bool:
	"""检查是否触发暴击"""
	return randf() < crit_chance_bonus


## 应用吸血效果
func apply_life_steal(damage_dealt: float) -> void:
	"""根据造成伤害应用吸血效果"""
	if life_steal_percent > 0:
		var heal_amount := damage_dealt * life_steal_percent
		heal(heal_amount)

func get_health_percent() -> float:
	return current_health / max_health if max_health > 0 else 0.0

func get_mana_percent() -> float:
	return current_mana / max_mana if max_mana > 0 else 0.0

func get_stamina_percent() -> float:
	return current_stamina / max_stamina if max_stamina > 0 else 0.0

func get_exp_percent() -> float:
	return float(current_exp) / float(exp_required) if exp_required > 0 else 0.0


# =============================================================================
# 技能系统方法
# =============================================================================

## 初始化技能管理器
func _init_skill_manager() -> void:
	"""初始化技能管理器"""
	# 创建技能管理器
	var sm_script := preload("res://src/skills/skill_manager.gd")
	skill_manager = Node.new()
	skill_manager.set_script(sm_script)
	skill_manager.name = "SkillManager"
	add_child(skill_manager)
	
	# 设置技能持有者
	if skill_manager.has_method("initialize"):
		skill_manager.initialize(self)
	
	# 连接技能信号
	if skill_manager.has_signal("skill_acquired"):
		skill_manager.skill_acquired.connect(_on_skill_acquired)
	if skill_manager.has_signal("hotkey_bar_changed"):
		skill_manager.hotkey_bar_changed.connect(_on_hotkey_bar_changed)
	
	print("[Player] 技能管理器已初始化")


## 激活相机跟随
func _activate_camera() -> void:
	"""激活并配置相机"""
	var camera: Camera2D = find_child("Camera2D", true, false)
	if camera:
		camera.enabled = true
		camera.make_current()
		print("[Player] 相机跟随已激活")
	else:
		push_warning("[Player] 未找到 Camera2D 节点")


## 更新技能状态
func _update_skills(delta: float) -> void:
	"""每帧更新技能状态"""
	if skill_manager and is_instance_valid(skill_manager):
		# 技能管理器的 _process 会自动调用
		pass


## 处理技能快捷键输入
func _handle_skill_input() -> void:
	"""处理技能快捷键输入"""
	# 技能快捷键由 SkillManager 的 _input 处理
	# 这里额外处理一些玩家特定的逻辑
	pass


## 解锁技能
func unlock_skill(skill_id: String) -> bool:
	"""
	解锁指定技能
	@param skill_id: 技能ID
	@return: 是否成功解锁
	"""
	if skill_id in unlocked_skills:
		print("[Player] 技能已解锁: %s，尝试升级" % skill_id)
		# 如果已经解锁，尝试升级
		if skill_manager and skill_manager.has_method("upgrade_skill"):
			return skill_manager.upgrade_skill(skill_id)
		return false

	# 添加到已解锁列表
	unlocked_skills.append(skill_id)

	# 通过技能管理器获取技能
	if skill_manager and skill_manager.has_method("acquire_skill"):
		var success = skill_manager.acquire_skill(skill_id)
		if success:
			# 自动分配到第一个空闲槽位
			_auto_assign_skill_slot(skill_id)
			skill_unlocked.emit(skill_id)
			skills_changed.emit()
			print("[Player] 技能解锁成功: %s" % skill_id)
		return success

	print("[Player] 技能解锁成功（无管理器）: %s" % skill_id)
	skill_unlocked.emit(skill_id)
	skills_changed.emit()
	return true


## 别名方法，供game.gd调用
func learn_skill(skill_id: String) -> bool:
	"""unlock_skill的别名"""
	return unlock_skill(skill_id)


## 自动分配技能到快捷键槽位
func _auto_assign_skill_slot(skill_id: String) -> void:
	"""自动分配技能到第一个空闲槽位"""
	# 查找第一个空闲槽位
	for i in range(skill_hotkeys.size()):
		if skill_hotkeys[i].is_empty():
			skill_hotkeys[i] = skill_id
			print("[Player] 技能 %s 已分配到槽位 %d" % [skill_id, i + 1])
			
			# 同时更新技能管理器的快捷键栏
			if skill_manager and skill_manager.has_method("set_hotkey_slot"):
				var skill = skill_manager.get_skill(skill_id)
				if skill:
					skill_manager.set_hotkey_slot(i, skill)
			break


## 使用技能
func use_skill(skill_id: String, target_position: Vector2 = Vector2.ZERO) -> bool:
	"""
	使用指定技能
	@param skill_id: 技能ID
	@param target_position: 目标位置（默认为鼠标位置）
	@return: 是否成功使用
	"""
	if skill_manager and skill_manager.has_method("use_skill"):
		# 如果没有指定目标位置，使用鼠标位置
		if target_position == Vector2.ZERO:
			target_position = get_global_mouse_position()
		return skill_manager.use_skill(skill_id, target_position)
	
	print("[Player] 无法使用技能: %s（无技能管理器）" % skill_id)
	return false


## 使用快捷键槽位中的技能
func use_skill_slot(slot: int) -> bool:
	"""
	使用指定槽位的技能
	@param slot: 槽位索引（0-3）
	@return: 是否成功使用
	"""
	if slot < 0 or slot >= skill_hotkeys.size():
		return false

	var skill_id := skill_hotkeys[slot]
	if skill_id.is_empty():
		return false

	return use_skill(skill_id)


## 别名方法，供game.gd调用
func use_skill_at_slot(slot: int) -> bool:
	"""use_skill_slot的别名"""
	return use_skill_slot(slot)


## 检查技能是否已解锁
func has_skill(skill_id: String) -> bool:
	"""检查技能是否已解锁"""
	return skill_id in unlocked_skills


## 获取已解锁技能列表
func get_unlocked_skills() -> Array[String]:
	"""获取已解锁技能列表"""
	return unlocked_skills.duplicate()


## 获取技能信息
func get_skill_info(skill_id: String) -> Dictionary:
	"""获取技能信息"""
	if skill_manager and skill_manager.has_method("get_skill"):
		var skill = skill_manager.get_skill(skill_id)
		if skill and skill.has_method("get_skill_info"):
			return skill.get_skill_info()
	return {}


## 获取所有技能信息列表
func get_all_skill_infos() -> Array[Dictionary]:
	"""获取所有已解锁技能的信息列表"""
	var infos: Array[Dictionary] = []
	for skill_id in unlocked_skills:
		var info := get_skill_info(skill_id)
		if not info.is_empty():
			infos.append(info)
	return infos


## 获取快捷键栏技能列表
func get_hotkey_skills() -> Array[Dictionary]:
	"""获取快捷键栏技能信息"""
	var skills: Array[Dictionary] = []
	for i in range(skill_hotkeys.size()):
		var skill_id := skill_hotkeys[i]
		if skill_id.is_empty():
			skills.append({"slot": i + 1, "empty": true})
		else:
			var info := get_skill_info(skill_id)
			info["slot"] = i + 1
			info["empty"] = false
			skills.append(info)
	return skills


## 技能获取回调
func _on_skill_acquired(skill: Resource) -> void:
	"""技能管理器获取技能时的回调"""
	if skill and "skill_id" in skill:
		var skill_id: String = skill.skill_id
		if skill_id not in unlocked_skills:
			unlocked_skills.append(skill_id)
			skill_unlocked.emit(skill_id)
			skills_changed.emit()


## 快捷键栏变化回调
func _on_hotkey_bar_changed(slot: int, skill: Resource) -> void:
	"""快捷键栏变化时的回调"""
	if skill and "skill_id" in skill:
		skill_hotkeys[slot] = skill.skill_id
	else:
		skill_hotkeys[slot] = ""
	skills_changed.emit()


## 消耗法力值
func consume_mana(amount: float) -> bool:
	"""
	消耗法力值
	@param amount: 消耗量
	@return: 是否成功消耗
	"""
	if current_mana >= amount:
		current_mana -= amount
		return true
	return false


## 恢复法力值
func restore_mana(amount: float) -> void:
	"""恢复法力值"""
	current_mana = min(current_mana + amount, max_mana)
