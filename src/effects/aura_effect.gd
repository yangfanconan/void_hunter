## Void Hunter - 光环效果
## @description: 持续跟随目标的光环视觉效果
## @author: Void Hunter Team
## @version: 1.0.0

extends Node2D

# =============================================================================
# 配置
# =============================================================================

## 光环类型
var aura_type: String = "void_aura"

## 目标节点
var target: Node = null

## 位置偏移
var offset: Vector2 = Vector2.ZERO

## 是否激活
var is_active: bool = true

## 粒子生成间隔
var particle_interval: float = 0.15

## 粒子计时器
var _particle_timer: float = 0.0

## 光环节点
var _aura_sprite: AnimatedSprite2D = null

# =============================================================================
# 生命周期
# =============================================================================

func _ready() -> void:
	_create_aura_sprite()


func _process(delta: float) -> void:
	if not is_active:
		return

	# 跟随目标位置
	if target and is_instance_valid(target):
		global_position = target.global_position + offset
	else:
		# 目标失效，停止效果
		queue_free()
		return

	# 生成粒子
	_particle_timer += delta
	if _particle_timer >= particle_interval:
		_particle_timer = 0.0
		_spawn_particle()

# =============================================================================
# 公共方法
# =============================================================================

## 设置光环参数
func setup(target_node: Node, type: String, pos_offset: Vector2 = Vector2.ZERO) -> void:
	target = target_node
	aura_type = type
	offset = pos_offset

	# 根据类型设置粒子间隔
	match aura_type:
		"void_aura":
			particle_interval = 0.2
		"fire_aura":
			particle_interval = 0.1
		_:
			particle_interval = 0.15

# =============================================================================
# 私有方法
# =============================================================================

func _create_aura_sprite() -> void:
	"""创建光环动画精灵"""
	_aura_sprite = AnimatedSprite2D.new()
	_aura_sprite.name = "AuraSprite"

	# 尝试从VFXManager获取SpriteFrames
	if VFXManager:
		var frames := _get_aura_frames()
		if frames:
			_aura_sprite.sprite_frames = frames
			var anim_name: String = frames.get_animation_names()[0] if frames.get_animation_names().size() > 0 else ""
			if anim_name != "":
				_aura_sprite.play(anim_name)

	# 如果没有动画帧，创建简单的圆形
	if _aura_sprite.sprite_frames == null:
		_create_simple_aura()

	add_child(_aura_sprite)


func _get_aura_frames() -> SpriteFrames:
	"""获取光环动画帧"""
	# VFXManager 会动态生成，这里创建简单的效果
	return null


func _create_simple_aura() -> void:
	"""创建简单的光环效果"""
	var sf := SpriteFrames.new()
	var anim_name := "default"

	sf.add_animation(anim_name)
	sf.set_animation_speed(anim_name, 8)
	sf.set_animation_loop(anim_name, true)

	# 创建简单的闪烁圆圈
	var size := 32

	for i in range(4):
		var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
		var progress := float(i) / 3.0
		var alpha := 0.5 + 0.3 * sin(progress * PI)

		# 根据类型设置颜色
		var color: Color
		match aura_type:
			"void_aura":
				color = Color(0.5, 0.0, 0.8, alpha)
			"fire_aura":
				color = Color(1.0, 0.4, 0.0, alpha)
			_:
				color = Color(1.0, 1.0, 1.0, alpha)

		# 绘制圆环
		var center := Vector2(size / 2.0, size / 2.0)
		var radius_inner := size * 0.3
		var radius_outer := size * 0.45

		for y in range(size):
			for x in range(size):
				var dist := Vector2(x, y).distance_to(center)
				if dist >= radius_inner and dist <= radius_outer:
					img.set_pixel(x, y, color)
				else:
					img.set_pixel(x, y, Color(0, 0, 0, 0))

		var tex := ImageTexture.create_from_image(img)
		sf.add_frame(anim_name, tex)

	_aura_sprite.sprite_frames = sf
	_aura_sprite.play(anim_name)


func _spawn_particle() -> void:
	"""生成粒子效果"""
	if not VFXManager:
		return

	# 在光环周围随机位置生成粒子
	var angle := randf() * TAU
	var radius := randf_range(10.0, 20.0)
	var particle_pos := global_position + Vector2(cos(angle), sin(angle)) * radius

	match aura_type:
		"void_aura":
			VFXManager.spawn_void_particle(particle_pos)
		"fire_aura":
			VFXManager.spawn_fire_particle(particle_pos)
		_:
			pass


func _exit_tree() -> void:
	"""离开场景树时清理"""
	if _aura_sprite:
		_aura_sprite.queue_free()