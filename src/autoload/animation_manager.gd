## Void Hunter - 动画管理器
## @description: 加载动画精灵表，切割帧，构建 SpriteFrames，缓存
## @version: 1.0.0

extends Node

# =============================================================================
# 动画配置
# =============================================================================

## 每个实体的动画定义：帧数、FPS、是否循环
const ANIM_CONFIG := {
	"player": {
		"idle": {"frames": 8, "fps": 8, "loop": true},
		"walk": {"frames": 8, "fps": 10, "loop": true},
		"attack": {"frames": 6, "fps": 12, "loop": false},
		"hurt": {"frames": 4, "fps": 10, "loop": false},
		"die": {"frames": 6, "fps": 8, "loop": false},
		"dash": {"frames": 4, "fps": 12, "loop": false},
	},
	"forest_slime": {
		"idle": {"frames": 4, "fps": 6, "loop": true},
		"walk": {"frames": 4, "fps": 8, "loop": true},
		"attack": {"frames": 4, "fps": 10, "loop": false},
		"hurt": {"frames": 2, "fps": 8, "loop": false},
		"die": {"frames": 4, "fps": 8, "loop": false},
	},
	"wolf": {
		"idle": {"frames": 4, "fps": 6, "loop": true},
		"walk": {"frames": 4, "fps": 8, "loop": true},
		"attack": {"frames": 4, "fps": 10, "loop": false},
		"hurt": {"frames": 2, "fps": 8, "loop": false},
		"die": {"frames": 4, "fps": 8, "loop": false},
	},
	"mushroom": {
		"idle": {"frames": 4, "fps": 6, "loop": true},
		"walk": {"frames": 4, "fps": 8, "loop": true},
		"attack": {"frames": 4, "fps": 10, "loop": false},
		"hurt": {"frames": 2, "fps": 8, "loop": false},
		"die": {"frames": 4, "fps": 8, "loop": false},
	},
	"scorpion": {
		"idle": {"frames": 4, "fps": 6, "loop": true},
		"walk": {"frames": 4, "fps": 8, "loop": true},
		"attack": {"frames": 4, "fps": 10, "loop": false},
		"hurt": {"frames": 2, "fps": 8, "loop": false},
		"die": {"frames": 4, "fps": 8, "loop": false},
	},
	"mummy": {
		"idle": {"frames": 4, "fps": 6, "loop": true},
		"walk": {"frames": 4, "fps": 8, "loop": true},
		"attack": {"frames": 4, "fps": 10, "loop": false},
		"hurt": {"frames": 2, "fps": 8, "loop": false},
		"die": {"frames": 4, "fps": 8, "loop": false},
	},
	"ghost": {
		"idle": {"frames": 4, "fps": 6, "loop": true},
		"walk": {"frames": 4, "fps": 8, "loop": true},
		"attack": {"frames": 4, "fps": 10, "loop": false},
		"hurt": {"frames": 2, "fps": 8, "loop": false},
		"die": {"frames": 4, "fps": 8, "loop": false},
	},
	"fire_imp": {
		"idle": {"frames": 4, "fps": 6, "loop": true},
		"walk": {"frames": 4, "fps": 8, "loop": true},
		"attack": {"frames": 4, "fps": 10, "loop": false},
		"hurt": {"frames": 2, "fps": 8, "loop": false},
		"die": {"frames": 4, "fps": 8, "loop": false},
	},
	"clockwork_soldier": {
		"idle": {"frames": 4, "fps": 6, "loop": true},
		"walk": {"frames": 4, "fps": 8, "loop": true},
		"attack": {"frames": 4, "fps": 10, "loop": false},
		"hurt": {"frames": 2, "fps": 8, "loop": false},
		"die": {"frames": 4, "fps": 8, "loop": false},
	},
	"shadow_crawler": {
		"idle": {"frames": 4, "fps": 6, "loop": true},
		"walk": {"frames": 4, "fps": 8, "loop": true},
		"attack": {"frames": 4, "fps": 10, "loop": false},
		"hurt": {"frames": 2, "fps": 8, "loop": false},
		"die": {"frames": 4, "fps": 8, "loop": false},
	},
	"skeleton": {
		"idle": {"frames": 4, "fps": 6, "loop": true},
		"walk": {"frames": 4, "fps": 8, "loop": true},
		"attack": {"frames": 4, "fps": 10, "loop": false},
		"hurt": {"frames": 2, "fps": 8, "loop": false},
		"die": {"frames": 4, "fps": 8, "loop": false},
	},
	"ice_slime": {
		"idle": {"frames": 4, "fps": 6, "loop": true},
		"walk": {"frames": 4, "fps": 8, "loop": true},
		"attack": {"frames": 4, "fps": 10, "loop": false},
		"hurt": {"frames": 2, "fps": 8, "loop": false},
		"die": {"frames": 4, "fps": 8, "loop": false},
	},
	"bone_dragon": {
		"idle": {"frames": 4, "fps": 6, "loop": true},
		"walk": {"frames": 4, "fps": 8, "loop": true},
		"attack": {"frames": 4, "fps": 10, "loop": false},
		"hurt": {"frames": 2, "fps": 8, "loop": false},
		"die": {"frames": 4, "fps": 8, "loop": false},
	},
	"boss": {
		"idle": {"frames": 6, "fps": 6, "loop": true},
		"walk": {"frames": 6, "fps": 8, "loop": true},
		"attack": {"frames": 6, "fps": 10, "loop": false},
		"hurt": {"frames": 4, "fps": 8, "loop": false},
		"die": {"frames": 8, "fps": 8, "loop": false},
		"phase2_idle": {"frames": 6, "fps": 6, "loop": true},
	},
	"player_bullet": {
		"fly": {"frames": 4, "fps": 10, "loop": true},
	},
	"enemy_bullet": {
		"fly": {"frames": 4, "fps": 10, "loop": true},
	},
	"fire_projectile": {
		"fly": {"frames": 4, "fps": 10, "loop": true},
	},
	"frost_projectile": {
		"fly": {"frames": 4, "fps": 10, "loop": true},
	},
	"lightning_projectile": {
		"fly": {"frames": 2, "fps": 10, "loop": true},
	},
}

## 实体类别到路径前缀的映射
const ENTITY_CATEGORIES := {
	"player": "characters",
	"forest_slime": "enemies/individual",
	"wolf": "enemies/individual",
	"mushroom": "enemies/individual",
	"scorpion": "enemies/individual",
	"mummy": "enemies/individual",
	"ghost": "enemies/individual",
	"fire_imp": "enemies/individual",
	"clockwork_soldier": "enemies/individual",
	"shadow_crawler": "enemies/individual",
	"skeleton": "enemies/individual",
	"ice_slime": "enemies/individual",
	"bone_dragon": "enemies/individual",
	"boss": "enemies",
	"player_bullet": "projectiles",
	"enemy_bullet": "projectiles",
	"fire_projectile": "projectiles",
	"frost_projectile": "projectiles",
	"lightning_projectile": "projectiles",
}

# =============================================================================
# 缓存
# =============================================================================

## 缓存: "entity_id/anim_name" -> SpriteFrames
var _sprite_frames_cache: Dictionary = {}
## 缓存: "entity_id/anim_name" -> Array[ImageTexture]
var _frame_textures_cache: Dictionary = {}
## 已加载的实体
var _loaded_entities: Dictionary = {}

var _loaded := false

# =============================================================================
# 初始化
# =============================================================================

func _ready() -> void:
	name = "AnimationManager"
	_loaded = true
	print("[AnimationManager] 初始化完成")

# =============================================================================
# 公共接口
# =============================================================================

## 获取 SpriteFrames（用于 AnimatedSprite2D）
func get_sprite_frames(entity_id: String, anim_name: String) -> SpriteFrames:
	var cache_key := "%s/%s" % [entity_id, anim_name]

	if _sprite_frames_cache.has(cache_key):
		return _sprite_frames_cache[cache_key]

	# 尝试加载
	var frames := _load_animation(entity_id, anim_name)
	if frames:
		_sprite_frames_cache[cache_key] = frames

	return frames

## 获取帧纹理数组（用于手动帧切换）
func get_frame_textures(entity_id: String, anim_name: String) -> Array[ImageTexture]:
	var cache_key := "%s/%s" % [entity_id, anim_name]

	if _frame_textures_cache.has(cache_key):
		return _frame_textures_cache[cache_key]

	# 加载并缓存
	_load_animation(entity_id, anim_name)

	if _frame_textures_cache.has(cache_key):
		return _frame_textures_cache[cache_key]

	return []

## 检查是否有某个动画
func has_animation(entity_id: String, anim_name: String) -> bool:
	var config: Dictionary = ANIM_CONFIG.get(entity_id, {})
	if not config.has(anim_name):
		return false

	var path := _get_animation_path(entity_id, anim_name)
	return ResourceLoader.exists(path)

## 获取实体可用的所有动画名
func get_available_animations(entity_id: String) -> Array[String]:
	var result: Array[String] = []
	var config: Dictionary = ANIM_CONFIG.get(entity_id, {})
	for anim_name in config.keys():
		if has_animation(entity_id, anim_name):
			result.append(anim_name)
	return result

## 预加载实体的所有动画
func preload_entity(entity_id: String) -> void:
	if _loaded_entities.has(entity_id):
		return

	var config: Dictionary = ANIM_CONFIG.get(entity_id, {})
	var loaded_count := 0

	for anim_name in config.keys():
		var cache_key := "%s/%s" % [entity_id, anim_name]
		if not _sprite_frames_cache.has(cache_key):
			var frames := _load_animation(entity_id, anim_name)
			if frames:
				loaded_count += 1

	if loaded_count > 0:
		_loaded_entities[entity_id] = true
		print("[AnimationManager] 预加载 %s: %d 个动画" % [entity_id, loaded_count])

## 获取动画配置
func get_animation_config(entity_id: String, anim_name: String) -> Dictionary:
	var entity_config: Dictionary = ANIM_CONFIG.get(entity_id, {})
	return entity_config.get(anim_name, {})

## 获取实体的完整 SpriteFrames（包含所有动画）
func get_entity_sprite_frames(entity_id: String) -> SpriteFrames:
	var config: Dictionary = ANIM_CONFIG.get(entity_id, {})
	if config.is_empty():
		return null

	var sf := SpriteFrames.new()

	for anim_name in config.keys():
		var frames := get_sprite_frames(entity_id, anim_name)
		if frames and frames.has_animation(anim_name):
			# 从加载的 SpriteFrames 中复制帧到合并的 SpriteFrames
			var anim_config: Dictionary = config[anim_name]
			var fps: float = anim_config.get("fps", 10.0)
			var loop: bool = anim_config.get("loop", true)

			sf.add_animation(anim_name)
			sf.set_animation_speed(anim_name, fps)
			sf.set_animation_loop(anim_name, loop)

			# 复制帧
			var frame_count := frames.get_frame_count(anim_name)
			for i in frame_count:
				var tex: Texture2D = frames.get_frame_texture(anim_name, i)
				sf.add_frame(anim_name, tex)

	if sf.get_animation_names().size() == 0:
		return null

	return sf

# =============================================================================
# 私有方法 - 加载
# =============================================================================

func _get_animation_path(entity_id: String, anim_name: String) -> String:
	var category: String = ENTITY_CATEGORIES.get(entity_id, "")
	match category:
		"characters":
			return "res://assets/sprites/characters/player/%s.png" % anim_name
		"enemies/individual":
			return "res://assets/sprites/enemies/individual/%s/%s.png" % [entity_id, anim_name]
		"enemies":
			return "res://assets/sprites/enemies/boss/%s.png" % anim_name
		"projectiles":
			return "res://assets/sprites/projectiles/%s.png" % entity_id
		_:
			return "res://assets/sprites/%s/%s.png" % [category, anim_name]

func _load_animation(entity_id: String, anim_name: String) -> SpriteFrames:
	var cache_key := "%s/%s" % [entity_id, anim_name]

	if _sprite_frames_cache.has(cache_key):
		return _sprite_frames_cache[cache_key]

	var path := _get_animation_path(entity_id, anim_name)
	var anim_config: Dictionary = get_animation_config(entity_id, anim_name)

	if anim_config.is_empty():
		return null

	var frame_count: int = anim_config.get("frames", 4)
	var fps: float = anim_config.get("fps", 10.0)
	var loop_anim: bool = anim_config.get("loop", true)
	var target_size: int = anim_config.get("size", 64)

	# 加载精灵表图片
	var img := _load_image(path)
	if img == null:
		return null

	# 确保格式为 RGBA8
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)


	# 计算帧尺寸
	var frame_w := img.get_width() / frame_count
	var frame_h := img.get_height()

	# 切割帧
	var textures: Array[ImageTexture] = []
	for i in frame_count:
		var region := Rect2i(i * frame_w, 0, frame_w, frame_h)
		var frame_img := Image.create(frame_w, frame_h, false, Image.FORMAT_RGBA8)
		frame_img.blit_rect(img, region, Vector2i.ZERO)

		# 缩放到目标尺寸
		frame_img.resize(target_size, target_size, Image.INTERPOLATE_NEAREST)

		# 移除白色背景（缩放后处理，避免处理大图）
		_remove_white_background(frame_img)

		var tex := ImageTexture.create_from_image(frame_img)
		textures.append(tex)

	# 缓存帧纹理
	_frame_textures_cache[cache_key] = textures

	# 构建 SpriteFrames
	var sf := SpriteFrames.new()
	sf.add_animation(anim_name)
	sf.set_animation_speed(anim_name, fps)
	sf.set_animation_loop(anim_name, loop_anim)

	for tex in textures:
		sf.add_frame(anim_name, tex)

	# 缓存 SpriteFrames
	_sprite_frames_cache[cache_key] = sf

	print("[AnimationManager] 加载: %s/%s (%d 帧, %d fps)" % [entity_id, anim_name, frame_count, int(fps)])
	return sf

func _load_image(path: String) -> Image:
	if not ResourceLoader.exists(path):
		return null

	var img := Image.new()
	var err := img.load(path)
	if err != OK:
		return null

	return img


## 移除白色背景（将接近白色的像素设为透明）
func _remove_white_background(img: Image, threshold: float = 0.92) -> void:
	"""移除图片中的白色/近白色背景"""
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	
	var w: int = img.get_width()
	var h: int = img.get_height()
	
	for y in range(h):
		for x in range(w):
			var pixel: Color = img.get_pixel(x, y)
			# 如果像素接近白色，设为透明
			if pixel.r > threshold and pixel.g > threshold and pixel.b > threshold:
				pixel.a = 0.0
				img.set_pixel(x, y, pixel)
	
	print("[AnimationManager] 已处理白色背景 (%dx%d)" % [w, h])
