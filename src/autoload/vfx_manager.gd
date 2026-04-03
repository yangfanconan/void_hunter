## Void Hunter - 特效管理器
## @description: 管理所有视觉特效（命中火花、死亡爆炸、状态效果等）
## @version: 1.0.0

extends Node

# =============================================================================
# 特效定义
# =============================================================================

const VFX_DEFS := {
	"hit_spark": {"frames": 6, "fps": 15, "lifetime": 0.4, "size": 32},
	"explosion_small": {"frames": 6, "fps": 12, "lifetime": 0.5, "size": 48},
	"explosion_large": {"frames": 8, "fps": 10, "lifetime": 0.8, "size": 96},
	"death_effect": {"frames": 8, "fps": 10, "lifetime": 0.8, "size": 64},
	"burn": {"frames": 6, "fps": 8, "lifetime": 0.75, "size": 32},
	"freeze": {"frames": 4, "fps": 6, "lifetime": 0.67, "size": 32},
	"stun": {"frames": 4, "fps": 6, "lifetime": 0.67, "size": 24},
	"heal_sparkle": {"frames": 6, "fps": 10, "lifetime": 0.6, "size": 32},
	"dash_trail": {"frames": 4, "fps": 12, "lifetime": 0.33, "size": 64},
	"level_up_ring": {"frames": 4, "fps": 8, "lifetime": 0.5, "size": 128},
	"shield_pulse": {"frames": 6, "fps": 8, "lifetime": 0.75, "size": 64},
	"poison": {"frames": 6, "fps": 8, "lifetime": 0.75, "size": 32},
	"void_aura": {"frames": 6, "fps": 10, "lifetime": 1.5, "size": 48},
	"fire_aura": {"frames": 6, "fps": 12, "lifetime": 1.0, "size": 48},
	"void_particle": {"frames": 4, "fps": 15, "lifetime": 0.4, "size": 16},
	"fire_particle": {"frames": 4, "fps": 15, "lifetime": 0.3, "size": 16},
}

## 状态效果类型到 VFX ID 的映射
const STATUS_VFX_MAP := {
	"burn": "burn",
	"freeze": "freeze",
	"stun": "stun",
	"poison": "poison",
	"shield": "shield_pulse",
}

# =============================================================================
# 缓存与对象池
# =============================================================================

## SpriteFrames 缓存: effect_id -> SpriteFrames
var _frames_cache: Dictionary = {}

## 对象池: effect_id -> Array[Node2D]（可用实例）
var _pool: Dictionary = {}

## 活跃特效列表（用于跟踪和清理）
var _active_effects: Array[Node2D] = []

## 容器节点
var _vfx_container: Node2D = null

var _loaded := false

# =============================================================================
# 初始化
# =============================================================================

func _ready() -> void:
	name = "VFXManager"
	_vfx_container = Node2D.new()
	_vfx_container.name = "VFXContainer"
	add_child(_vfx_container)
	_loaded = true
	print("[VFXManager] 初始化完成")

# =============================================================================
# 公共接口
# =============================================================================

## 生成特效
func spawn_effect(effect_id: String, world_pos: Vector2, params: Dictionary = {}) -> Node2D:
	var def: Dictionary = VFX_DEFS.get(effect_id, {})
	if def.is_empty():
		# 如果没有定义，生成一个简单的闪光
		return _spawn_fallback_flash(world_pos, params)

	# 尝试从池中获取
	var vfx_node := _get_from_pool(effect_id)
	if vfx_node == null:
		vfx_node = _create_vfx_instance(effect_id, def)

	if vfx_node == null:
		return null

	# 设置位置和参数
	vfx_node.global_position = world_pos
	vfx_node.visible = true
	vfx_node.modulate = Color.WHITE

	if params.has("color"):
		vfx_node.modulate = params["color"]
	if params.has("scale"):
		vfx_node.scale = Vector2.ONE * params["scale"]
	if params.has("rotation"):
		vfx_node.rotation = params["rotation"]
	if params.has("flip_h"):
		for child in vfx_node.get_children():
			if child is AnimatedSprite2D:
				child.flip_h = params["flip_h"]

	# 添加到容器
	_vfx_container.add_child(vfx_node)
	_active_effects.append(vfx_node)

	# 播放动画
	var anim_sprite := _get_anim_sprite(vfx_node)
	if anim_sprite and anim_sprite.sprite_frames:
		var anim_name: String = anim_sprite.sprite_frames.get_animation_names()[0] if anim_sprite.sprite_frames.get_animation_names().size() > 0 else ""
		if anim_name != "":
			anim_sprite.play(anim_name)

	# 自动回收
	var lifetime: float = def.get("lifetime", 0.5)
	if params.has("lifetime"):
		lifetime = params["lifetime"]

	get_tree().create_timer(lifetime).timeout.connect(
		_return_to_pool.bind(vfx_node, effect_id)
	)

	return vfx_node

## 生成命中火花
func spawn_hit_spark(pos: Vector2, color: Color = Color.WHITE) -> Node2D:
	return spawn_effect("hit_spark", pos, {"color": color})

## 生成死亡爆炸
func spawn_death_explosion(pos: Vector2, size: String = "small") -> Node2D:
	match size:
		"large":
			return spawn_effect("explosion_large", pos)
		"death":
			return spawn_effect("death_effect", pos)
		_:
			return spawn_effect("explosion_small", pos)

## 生成状态效果
func spawn_status_vfx(pos: Vector2, status_type: String) -> Node2D:
	var vfx_id: String = STATUS_VFX_MAP.get(status_type, "")
	if vfx_id == "":
		return null
	return spawn_effect(vfx_id, pos)

## 生成治疗闪光
func spawn_heal_sparkle(pos: Vector2) -> Node2D:
	return spawn_effect("heal_sparkle", pos)

## 生成冲刺尾迹
func spawn_dash_trail(pos: Vector2, flip_h: bool = false) -> Node2D:
	return spawn_effect("dash_trail", pos, {"flip_h": flip_h, "scale": 0.8})

## 生成虚空光环效果
func spawn_void_aura(pos: Vector2, scale: float = 1.0) -> Node2D:
	return spawn_effect("void_aura", pos, {"scale": scale})

## 生成火焰光环效果
func spawn_fire_aura(pos: Vector2, scale: float = 1.0) -> Node2D:
	return spawn_effect("fire_aura", pos, {"scale": scale})

## 生成虚空粒子
func spawn_void_particle(pos: Vector2) -> Node2D:
	return spawn_effect("void_particle", pos)

## 生成火焰粒子
func spawn_fire_particle(pos: Vector2) -> Node2D:
	return spawn_effect("fire_particle", pos)

## 为目标创建持续光环效果
func create_aura_effect(target: Node, aura_type: String, offset: Vector2 = Vector2.ZERO) -> Node2D:
	"""为目标创建持续光环效果，跟随目标移动"""
	var aura_node := Node2D.new()
	aura_node.name = "Aura_%s" % aura_type
	aura_node.set_script(preload("res://src/effects/aura_effect.gd"))

	# 设置光环参数
	if aura_node.has_method("setup"):
		aura_node.call("setup", target, aura_type, offset)

	return aura_node

## 清理所有活跃特效
func clear_all() -> void:
	for vfx in _active_effects:
		if is_instance_valid(vfx):
			vfx.queue_free()
	_active_effects.clear()

	# 清理池
	for effect_id in _pool:
		for vfx in _pool[effect_id]:
			if is_instance_valid(vfx):
				vfx.queue_free()
	_pool.clear()

# =============================================================================
# 私有方法 - VFX 实例创建
# =============================================================================

func _create_vfx_instance(effect_id: String, def: Dictionary) -> Node2D:
	var node := Node2D.new()
	node.name = "VFX_%s" % effect_id
	node.set_meta("vfx_id", effect_id)

	# 获取或加载 SpriteFrames
	var sf := _get_or_load_frames(effect_id, def)

	var anim_sprite := AnimatedSprite2D.new()
	anim_sprite.name = "AnimatedSprite"

	if sf and sf.get_animation_names().size() > 0:
		anim_sprite.sprite_frames = sf
	else:
		# 后备：使用颜色方块动画
		anim_sprite.sprite_frames = _create_fallback_frames(effect_id, def)

	node.add_child(anim_sprite)

	return node

func _get_or_load_frames(effect_id: String, def: Dictionary) -> SpriteFrames:
	if _frames_cache.has(effect_id):
		return _frames_cache[effect_id]

	var frame_count: int = def.get("frames", 4)
	var fps: float = def.get("fps", 10.0)
	var size: int = def.get("size", 32)

	# 尝试从文件加载
	var path := "res://assets/sprites/vfx/%s.png" % effect_id
	var img := _load_image(path)

	if img == null:
		return null

	# 确保格式
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)


	var frame_w := img.get_width() / frame_count
	var frame_h := img.get_height()

	var sf := SpriteFrames.new()
	var anim_name := "default"
	sf.add_animation(anim_name)
	sf.set_animation_speed(anim_name, fps)
	sf.set_animation_loop(anim_name, false)

	for i in frame_count:
		var region := Rect2i(i * frame_w, 0, frame_w, frame_h)
		var frame_img := Image.create(frame_w, frame_h, false, Image.FORMAT_RGBA8)
		frame_img.blit_rect(img, region, Vector2i.ZERO)
		frame_img.resize(size, size, Image.INTERPOLATE_NEAREST)
		_remove_white_background(frame_img)
		var tex := ImageTexture.create_from_image(frame_img)
		sf.add_frame(anim_name, tex)

	_frames_cache[effect_id] = sf
	return sf

func _create_fallback_frames(effect_id: String, def: Dictionary) -> SpriteFrames:
	var sf := SpriteFrames.new()
	var anim_name := "default"
	var fps: float = def.get("fps", 10.0)
	var size: int = def.get("size", 32)

	sf.add_animation(anim_name)
	sf.set_animation_speed(anim_name, fps)
	sf.set_animation_loop(anim_name, false)

	# 根据特效类型选择颜色
	var colors := _get_vfx_colors(effect_id)

	for i in range(4):
		var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
		var progress := float(i) / 3.0
		var alpha := 1.0 - progress * 0.5
		var color := colors[0] if i < 2 else colors[1]
		color.a = alpha
		img.fill(color)
		var tex := ImageTexture.create_from_image(img)
		sf.add_frame(anim_name, tex)

	return sf

func _get_vfx_colors(effect_id: String) -> Array[Color]:
	match effect_id:
		"hit_spark":
			return [Color(1.0, 0.9, 0.3), Color(1.0, 0.5, 0.1)]
		"explosion_small", "explosion_large":
			return [Color(1.0, 0.6, 0.1), Color(1.0, 0.2, 0.0)]
		"death_effect":
			return [Color(0.5, 0.0, 0.5), Color(0.2, 0.0, 0.3)]
		"burn":
			return [Color(1.0, 0.4, 0.0), Color(1.0, 0.8, 0.0)]
		"freeze":
			return [Color(0.3, 0.7, 1.0), Color(0.8, 0.9, 1.0)]
		"stun":
			return [Color(1.0, 1.0, 0.0), Color(0.8, 0.8, 0.0)]
		"heal_sparkle":
			return [Color(0.2, 1.0, 0.3), Color(0.5, 1.0, 0.6)]
		"dash_trail":
			return [Color(0.3, 0.8, 1.0, 0.6), Color(0.1, 0.4, 0.8, 0.3)]
		"poison":
			return [Color(0.2, 0.8, 0.0), Color(0.5, 1.0, 0.0)]
		"void_aura", "void_particle":
			return [Color(0.5, 0.0, 0.8, 0.8), Color(0.2, 0.0, 0.5, 0.5)]
		"fire_aura", "fire_particle":
			return [Color(1.0, 0.4, 0.0, 0.8), Color(1.0, 0.8, 0.0, 0.5)]
		_:
			return [Color.WHITE, Color.GRAY]

func _spawn_fallback_flash(pos: Vector2, params: Dictionary) -> Node2D:
	var node := Node2D.new()
	node.global_position = pos
	node.name = "VFX_Flash"

	var rect := ColorRect.new()
	var size: float = params.get("size", 16.0)
	rect.size = Vector2(size, size)
	rect.position = Vector2(-size / 2, -size / 2)
	rect.color = params.get("color", Color(1.0, 1.0, 1.0, 0.8))
	node.add_child(rect)

	_vfx_container.add_child(node)

	# 闪一下就消失
	var tween := node.create_tween()
	tween.tween_property(rect, "color:a", 0.0, 0.2)
	tween.tween_callback(node.queue_free)

	return node

# =============================================================================
# 私有方法 - 对象池
# =============================================================================

func _get_from_pool(effect_id: String) -> Node2D:
	if not _pool.has(effect_id):
		_pool[effect_id] = []

	var pool: Array = _pool[effect_id]
	if pool.size() > 0:
		var node: Node2D = pool.pop_back()
		if is_instance_valid(node):
			# 从旧父节点移除（如果有）
			if node.get_parent():
				node.get_parent().remove_child(node)
			return node

	return null

func _return_to_pool(vfx: Node2D, effect_id: String) -> void:
	if not is_instance_valid(vfx):
		return

	# 从活跃列表移除
	var idx := _active_effects.find(vfx)
	if idx >= 0:
		_active_effects.remove_at(idx)

	# 停止动画
	var anim_sprite := _get_anim_sprite(vfx)
	if anim_sprite:
		anim_sprite.stop()

	# 从场景树移除
	if vfx.get_parent():
		vfx.get_parent().remove_child(vfx)

	# 放回池
	if not _pool.has(effect_id):
		_pool[effect_id] = []
	_pool[effect_id].append(vfx)

func _get_anim_sprite(node: Node2D) -> AnimatedSprite2D:
	for child in node.get_children():
		if child is AnimatedSprite2D:
			return child
	return null

func _load_image(path: String) -> Image:
	if not ResourceLoader.exists(path):
		return null

	var img := Image.new()
	var err := img.load(path)
	if err != OK:
		return null

	return img


## 移除白色背景
func _remove_white_background(img: Image, threshold: float = 0.92) -> void:
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	
	var w: int = img.get_width()
	var h: int = img.get_height()
	
	for y in range(h):
		for x in range(w):
			var pixel: Color = img.get_pixel(x, y)
			if pixel.r > threshold and pixel.g > threshold and pixel.b > threshold:
				pixel.a = 0.0
				img.set_pixel(x, y, pixel)
