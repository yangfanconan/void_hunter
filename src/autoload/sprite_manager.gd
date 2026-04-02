## Void Hunter - 精灵资源管理器
## @description: 加载即梦生成的美术素材，切割精灵图，提供游戏内使用
## @version: 1.0.0

extends Node

# =============================================================================
# 精灵图集配置
# =============================================================================

## 玩家精灵图：2行 (6+2帧)，每帧约 4096/6 = 682px 宽
const PLAYER_COLS := 6
const PLAYER_ROWS := 2
const PLAYER_FRAMES := [6, 2]

## 敌人精灵图：3行4列 = 12个敌人
const ENEMY_COLS := 4
const ENEMY_ROWS := 3

## 主题背景图：2行4列 = 8个背景
const THEME_COLS := 4
const THEME_ROWS := 2

## Boss精灵图：单个大图
## 技能图标图：网格布局
## 道具图标图：网格布局

# =============================================================================
# 缓存
# =============================================================================

var _player_textures: Array[ImageTexture] = []
var _enemy_textures: Array[ImageTexture] = []
var _boss_texture: ImageTexture = null
var _theme_textures: Array[ImageTexture] = []
var _skill_icons_texture: ImageTexture = null
var _item_icons_texture: ImageTexture = null
var _ui_elements_texture: ImageTexture = null

var _loaded := false

# =============================================================================
# 初始化
# =============================================================================

func _ready() -> void:
	name = "SpriteManager"
	_load_all_assets()

func _load_all_assets() -> void:
	# 加载玩家精灵
	_load_player_sprites()
	# 加载敌人精灵
	_load_enemy_sprites()
	# 加载Boss精灵
	_load_boss_sprite()
	# 加载主题背景
	_load_theme_backgrounds()
	# 加载技能图标
	_load_skill_icons()
	# 加载道具图标
	_load_item_icons()
	# 加载UI元素
	_load_ui_elements()

	_loaded = true
	print("[SpriteManager] 所有美术素材加载完成")

# =============================================================================
# 精灵切割工具
# =============================================================================

func _split_sprite_sheet(path: String, cols: int, rows: int) -> Array[ImageTexture]:
	var textures: Array[ImageTexture] = []
	var img := _load_image(path)
	if img == null:
		return textures

	var cell_w := img.get_width() / cols
	var cell_h := img.get_height() / rows

	for row in rows:
		for col in cols:
			var region := Rect2i(col * cell_w, row * cell_h, cell_w, cell_h)
			var frame := Image.create(cell_w, cell_h, false, Image.FORMAT_RGBA8)
			frame.blit_rect(img, region, Vector2i.ZERO)

			# 缩放到合理游戏尺寸 (64x64)
			var target_size := 64
			frame = _resize_nearest(frame, target_size, target_size)

			var tex := ImageTexture.create_from_image(frame)
			textures.append(tex)

	return textures

func _split_sprite_sheet_variable_rows(path: String, cols_per_row: Array[int]) -> Array[ImageTexture]:
	var textures: Array[ImageTexture] = []
	var img := _load_image(path)
	if img == null:
		return textures

	var total_rows := cols_per_row.size()
	var cell_w := img.get_width() / cols_per_row[0]
	var cell_h := img.get_height() / total_rows

	for row in total_rows:
		var cols := cols_per_row[row]
		var actual_cell_w := img.get_width() / cols
		for col in cols:
			var region := Rect2i(col * actual_cell_w, row * cell_h, actual_cell_w, cell_h)
			var frame := Image.create(actual_cell_w, cell_h, false, Image.FORMAT_RGBA8)
			frame.blit_rect(img, region, Vector2i.ZERO)

			# 缩放到 64x64
			frame = _resize_nearest(frame, 64, 64)

			var tex := ImageTexture.create_from_image(frame)
			textures.append(tex)

	return textures

func _load_full_texture(path: String, target_w: int = 128, target_h: int = 128) -> ImageTexture:
	var img := _load_image(path)
	if img == null:
		return null

	img = _resize_nearest(img, target_w, target_h)
	return ImageTexture.create_from_image(img)

func _load_image(path: String) -> Image:
	if not ResourceLoader.exists(path):
		print("[SpriteManager] 文件不存在: %s" % path)
		return null

	var img := Image.new()
	var err := img.load(path)
	if err != OK:
		print("[SpriteManager] 加载失败: %s (错误: %d)" % [path, err])
		return null

	# 确保格式统一为 RGBA8
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)

	# 移除白色背景（Dreamina 生成的图片没有透明通道）
	_remove_white_background(img)

	return img

func _resize_nearest(img: Image, w: int, h: int) -> Image:
	img.resize(w, h, Image.INTERPOLATE_NEAREST)
	return img

# =============================================================================
# 加载各资源
# =============================================================================

func _load_player_sprites() -> void:
	_player_textures = _split_sprite_sheet_variable_rows(
		"res://assets/sprites/characters/player_character_design.png",
		[6, 2]
	)
	print("[SpriteManager] 玩家精灵: %d 帧" % _player_textures.size())

func _load_enemy_sprites() -> void:
	_enemy_textures = _split_sprite_sheet(
		"res://assets/sprites/enemies/enemy_collection_design.png",
		ENEMY_COLS, ENEMY_ROWS
	)
	print("[SpriteManager] 敌人精灵: %d 个" % _enemy_textures.size())

func _load_boss_sprite() -> void:
	_boss_texture = _load_full_texture(
		"res://assets/sprites/enemies/boss_design.png", 128, 128
	)
	if _boss_texture:
		print("[SpriteManager] Boss精灵加载成功")

func _load_theme_backgrounds() -> void:
	_theme_textures = _split_sprite_sheet(
		"res://assets/sprites/tiles/theme_backgrounds.png",
		THEME_COLS, THEME_ROWS
	)
	print("[SpriteManager] 主题背景: %d 个" % _theme_textures.size())

func _load_skill_icons() -> void:
	_skill_icons_texture = _load_full_texture(
		"res://assets/sprites/skills/skill_icons.png", 512, 512
	)
	if _skill_icons_texture:
		print("[SpriteManager] 技能图标加载成功")

func _load_item_icons() -> void:
	_item_icons_texture = _load_full_texture(
		"res://assets/sprites/items/item_icons.png", 512, 512
	)
	if _item_icons_texture:
		print("[SpriteManager] 道具图标加载成功")

func _load_ui_elements() -> void:
	_ui_elements_texture = _load_full_texture(
		"res://assets/sprites/ui/ui_elements.png", 512, 512
	)
	if _ui_elements_texture:
		print("[SpriteManager] UI元素加载成功")

# =============================================================================
# 公共接口
# =============================================================================

## 获取玩家精灵帧（0-7）
func get_player_frame(index: int) -> ImageTexture:
	if index >= 0 and index < _player_textures.size():
		return _player_textures[index]
	if _player_textures.size() > 0:
		return _player_textures[0]
	return null

## 获取所有玩家帧（用于动画）
func get_player_all_frames() -> Array[ImageTexture]:
	return _player_textures

## 获取敌人精灵（0-11）
func get_enemy_sprite(index: int) -> ImageTexture:
	if index >= 0 and index < _enemy_textures.size():
		return _enemy_textures[index]
	if _enemy_textures.size() > 0:
		return _enemy_textures[0]
	return null

## 获取随机敌人精灵
func get_random_enemy_sprite() -> ImageTexture:
	if _enemy_textures.is_empty():
		return null
	return _enemy_textures[randi() % _enemy_textures.size()]

## 获取Boss精灵
func get_boss_sprite() -> ImageTexture:
	return _boss_texture

## 获取主题背景（0-7）
func get_theme_background(theme_id: int) -> ImageTexture:
	if theme_id >= 0 and theme_id < _theme_textures.size():
		return _theme_textures[theme_id]
	if _theme_textures.size() > 0:
		return _theme_textures[0]
	return null

## 获取技能图标图集
func get_skill_icons() -> ImageTexture:
	return _skill_icons_texture

## 获取道具图标图集
func get_item_icons() -> ImageTexture:
	return _item_icons_texture

## 获取UI元素图集
func get_ui_elements() -> ImageTexture:
	return _ui_elements_texture

## 根据敌人ID获取对应精灵
func get_enemy_sprite_by_id(enemy_id: String) -> ImageTexture:
	var mapping := {
		"forest_slime": 0,
		"wolf": 1,
		"mushroom": 2,
		"scorpion": 3,
		"mummy": 4,
		"ghost": 5,
		"fire_imp": 6,
		"clockwork_soldier": 7,
		"shadow_crawler": 8,
		"skeleton": 9,
		"ice_slime": 10,
		"bone_dragon": 11,
	}
	var idx: int = mapping.get(enemy_id, -1)
	if idx >= 0:
		return get_enemy_sprite(idx)
	return get_random_enemy_sprite()

# =============================================================================
# 技能/道具图标分割
# =============================================================================

var _skill_icon_textures: Dictionary = {}
var _item_icon_textures: Dictionary = {}
var _character_portraits: Dictionary = {}

## 获取技能图标
func get_skill_icon(skill_id: String) -> ImageTexture:
	if _skill_icon_textures.has(skill_id):
		return _skill_icon_textures[skill_id]

	# 尝试从单独文件加载
	var path := "res://assets/sprites/skills/icons/%s.png" % skill_id
	if ResourceLoader.exists(path):
		var img := _load_image(path)
		if img:
			var icon := ImageTexture.create_from_image(img)
			_skill_icon_textures[skill_id] = icon
			return icon

	# 后备：从图集切分
	return _get_skill_icon_from_atlas(skill_id)

## 获取道具图标
func get_item_icon(item_type: String) -> ImageTexture:
	if _item_icon_textures.has(item_type):
		return _item_icon_textures[item_type]

	var path := "res://assets/sprites/items/icons/%s.png" % item_type
	if ResourceLoader.exists(path):
		var img := _load_image(path)
		if img:
			var icon := ImageTexture.create_from_image(img)
			_item_icon_textures[item_type] = icon
			return icon

	return null

## 获取角色头像
func get_character_portrait(character_id: String) -> ImageTexture:
	if _character_portraits.has(character_id):
		return _character_portraits[character_id]

	var path := "res://assets/sprites/characters/%s/portrait.png" % character_id
	if ResourceLoader.exists(path):
		var img := _load_image(path)
		if img:
			var portrait := ImageTexture.create_from_image(img)
			_character_portraits[character_id] = portrait
			return portrait

	return null

func _get_skill_icon_from_atlas(skill_id: String) -> ImageTexture:
	if _skill_icons_texture == null:
		return null

	var mapping := {
		"fire_bullet": 0, "frost_arrow": 1, "lightning_chain": 2,
		"shadow_slash": 3, "laser_beam": 4, "circular_burst": 5,
		"homing_missile": 6, "lightning_storm": 7, "screen_nuke": 8,
		"fan_shot": 9, "shield": 10, "blink": 11,
		"iron_wall": 12, "reflect": 13, "gravity_field": 14,
		"time_slow": 15, "healing_aura": 16, "speed_aura": 17,
	}

	var idx: int = mapping.get(skill_id, -1)
	if idx < 0:
		return null

	var img := _skill_icons_texture.get_image()
	if img == null:
		return null

	var cols := 8
	var rows := 8
	var cell_w := img.get_width() / cols
	var cell_h := img.get_height() / rows
	var col := idx % cols
	var row := idx / cols

	var region := Rect2i(col * cell_w, row * cell_h, cell_w, cell_h)
	var icon_img := Image.create(cell_w, cell_h, false, Image.FORMAT_RGBA8)
	icon_img.blit_rect(img, region, Vector2i.ZERO)
	icon_img.resize(64, 64, Image.INTERPOLATE_NEAREST)

	var tex := ImageTexture.create_from_image(icon_img)
	_skill_icon_textures[skill_id] = tex
	return tex


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
