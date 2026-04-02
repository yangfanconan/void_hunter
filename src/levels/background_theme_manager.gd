## Void Hunter - 地图背景主题管理器
## @description: 根据波次切换不同主题的地图背景
## @author: Void Hunter Team
## @version: 1.0.0

extends Node2D

# =============================================================================
# 信号定义
# =============================================================================

## 主题变化时触发
signal theme_changed(theme_name: String, wave: int)

## 主题过渡完成时触发
signal transition_completed()

# =============================================================================
# 枚举定义
# =============================================================================

## 背景主题类型
enum ThemeType {
	DUNGEON,		## 废弃地牢 (波次 1-5)
	LAVA_CAVE,		## 熔岩洞穴 (波次 6-10)
	ICE_FORTRESS,	## 冰霜要塞 (波次 11-15)
	CORRUPTED_ABYSS,## 腐化深渊 (波次 16-20)
	VOID_REALM		## 虚空领域 (波次 21+)
}

# =============================================================================
# 常量定义
# =============================================================================

## 主题配置
const THEME_CONFIG: Dictionary = {
	ThemeType.DUNGEON: {
		"name": "废弃地牢",
		"wave_range": [1, 5],
		"bg_color": Color(0.12, 0.12, 0.14),
		"grid_color": Color(0.18, 0.18, 0.22, 0.5),
		"accent_color": Color(0.3, 0.3, 0.35),
		"particle_color": Color(0.4, 0.4, 0.45),
		"ambient_light": Color(0.8, 0.8, 0.85, 0.3)
	},
	ThemeType.LAVA_CAVE: {
		"name": "熔岩洞穴",
		"wave_range": [6, 10],
		"bg_color": Color(0.15, 0.08, 0.06),
		"grid_color": Color(0.25, 0.12, 0.08, 0.5),
		"accent_color": Color(0.8, 0.3, 0.1),
		"particle_color": Color(1.0, 0.5, 0.2),
		"ambient_light": Color(1.0, 0.6, 0.3, 0.4)
	},
	ThemeType.ICE_FORTRESS: {
		"name": "冰霜要塞",
		"wave_range": [11, 15],
		"bg_color": Color(0.08, 0.12, 0.18),
		"grid_color": Color(0.15, 0.2, 0.3, 0.5),
		"accent_color": Color(0.4, 0.7, 1.0),
		"particle_color": Color(0.7, 0.9, 1.0),
		"ambient_light": Color(0.6, 0.8, 1.0, 0.3)
	},
	ThemeType.CORRUPTED_ABYSS: {
		"name": "腐化深渊",
		"wave_range": [16, 20],
		"bg_color": Color(0.1, 0.06, 0.14),
		"grid_color": Color(0.2, 0.1, 0.25, 0.5),
		"accent_color": Color(0.6, 0.2, 0.8),
		"particle_color": Color(0.8, 0.4, 1.0),
		"ambient_light": Color(0.7, 0.3, 0.9, 0.35)
	},
	ThemeType.VOID_REALM: {
		"name": "虚空领域",
		"wave_range": [21, 999],
		"bg_color": Color(0.05, 0.05, 0.08),
		"grid_color": Color(0.15, 0.1, 0.2, 0.4),
		"accent_color": Color(0.5, 0.3, 0.8),
		"particle_color": Color(0.6, 0.4, 1.0),
		"ambient_light": Color(0.5, 0.4, 0.8, 0.4)
	}
}

## 过渡动画持续时间
const TRANSITION_DURATION: float = 2.0

## 网格大小
const GRID_SIZE: int = 64

## 网格范围
const GRID_RANGE: int = 20

# =============================================================================
# 公共变量
# =============================================================================

## 当前主题
var current_theme: ThemeType = ThemeType.DUNGEON

## 当前波次
var current_wave: int = 1

## 是否正在过渡
var is_transitioning: bool = false

# =============================================================================
# 私有变量
# =============================================================================

var _floor_bg: ColorRect = null
var _grid_lines: Node2D = null
var _ambient_particles: Node2D = null
var _ambient_light: PointLight2D = null
var _tween: Tween = null

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""节点就绪时初始化"""
	_initialize_background()
	_setup_wave_signal()


func _process(delta: float) -> void:
	"""每帧更新"""
	# 更新环境粒子
	_update_ambient_particles(delta)
	
	# 更新彩虹背景（虚空领域）
	if current_theme == ThemeType.VOID_REALM:
		_update_void_realm_effect(delta)

# =============================================================================
# 公共方法
# =============================================================================

## 设置波次
func set_wave(wave: int) -> void:
	"""设置当前波次并检查是否需要切换主题"""
	current_wave = wave
	var new_theme := _get_theme_for_wave(wave)
	
	if new_theme != current_theme:
		_transition_to_theme(new_theme)


## 强制设置主题
func set_theme(theme: ThemeType) -> void:
	"""强制设置特定主题"""
	if theme != current_theme:
		_transition_to_theme(theme)


## 获取当前主题名称
func get_theme_name() -> String:
	"""获取当前主题名称"""
	return THEME_CONFIG[current_theme].get("name", "Unknown")


## 获取当前主题配置
func get_theme_config() -> Dictionary:
	"""获取当前主题配置"""
	return THEME_CONFIG[current_theme]

# =============================================================================
# 私有方法 - 初始化
# =============================================================================

func _initialize_background() -> void:
	"""初始化背景"""
	# 创建地板背景
	_create_floor_background()
	
	# 创建网格线
	_create_grid_lines()
	
	# 创建环境粒子
	_create_ambient_particles()
	
	# 创建环境光
	_create_ambient_light()
	
	# 应用初始主题
	_apply_theme(current_theme, false)


func _create_floor_background() -> void:
	"""创建地板背景"""
	_floor_bg = ColorRect.new()
	_floor_bg.name = "FloorBackground"
	_floor_bg.color = THEME_CONFIG[current_theme].bg_color
	_floor_bg.z_index = -100
	_floor_bg.custom_minimum_size = Vector2(4000, 4000)
	_floor_bg.position = Vector2(-2000, -2000)
	add_child(_floor_bg)


func _create_grid_lines() -> void:
	"""创建网格线"""
	_grid_lines = Node2D.new()
	_grid_lines.name = "GridLines"
	_grid_lines.z_index = -50
	add_child(_grid_lines)
	
	# 创建网格线
	var grid_color: Color = THEME_CONFIG[current_theme].grid_color
	
	# 垂直线
	for x in range(-GRID_RANGE, GRID_RANGE + 1):
		var line := Line2D.new()
		line.add_point(Vector2(x * GRID_SIZE, -GRID_RANGE * GRID_SIZE))
		line.add_point(Vector2(x * GRID_SIZE, GRID_RANGE * GRID_SIZE))
		line.width = 1.0
		line.default_color = grid_color
		_grid_lines.add_child(line)
	
	# 水平线
	for y in range(-GRID_RANGE, GRID_RANGE + 1):
		var line := Line2D.new()
		line.add_point(Vector2(-GRID_RANGE * GRID_SIZE, y * GRID_SIZE))
		line.add_point(Vector2(GRID_RANGE * GRID_SIZE, y * GRID_SIZE))
		line.width = 1.0
		line.default_color = grid_color
		_grid_lines.add_child(line)


func _create_ambient_particles() -> void:
	"""创建环境粒子"""
	_ambient_particles = Node2D.new()
	_ambient_particles.name = "AmbientParticles"
	_ambient_particles.z_index = -30
	add_child(_ambient_particles)
	
	# 创建一些漂浮的粒子
	for i in range(30):
		var particle := _create_ambient_particle()
		_ambient_particles.add_child(particle)


func _create_ambient_particle() -> Node2D:
	"""创建单个环境粒子"""
	var particle := Node2D.new()
	particle.name = "Particle"
	
	# 随机位置
	particle.position = Vector2(randf_range(-800, 800), randf_range(-600, 600))
	
	# 粒子精灵
	var sprite := Sprite2D.new()
	var texture := ImageTexture.new()
	var image := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	image.fill(THEME_CONFIG[current_theme].particle_color)
	texture.set_image(image)
	sprite.texture = texture
	sprite.centered = true
	particle.add_child(sprite)
	
	# 存储动画数据
	particle.set_meta("base_y", particle.position.y)
	particle.set_meta("phase", randf() * TAU)
	particle.set_meta("speed", randf_range(0.5, 1.5))
	
	return particle


func _create_ambient_light() -> void:
	"""创建环境光"""
	_ambient_light = PointLight2D.new()
	_ambient_light.name = "AmbientLight"
	_ambient_light.color = THEME_CONFIG[current_theme].ambient_light
	_ambient_light.energy = 0.5
	_ambient_light.texture = _create_light_texture()
	_ambient_light.position = Vector2(576, 320)  # 屏幕中心
	add_child(_ambient_light)


func _create_light_texture() -> ImageTexture:
	"""创建光源纹理"""
	var texture := ImageTexture.new()
	var image := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	
	# 创建渐变圆形
	var center := Vector2(64, 64)
	for x in range(128):
		for y in range(128):
			var dist: float = Vector2(x, y).distance_to(center)
			var alpha: float = clampf(1.0 - dist / 64.0, 0.0, 1.0)
			image.set_pixel(x, y, Color(1, 1, 1, alpha))
	
	texture.set_image(image)
	return texture


func _setup_wave_signal() -> void:
	"""设置波次信号连接"""
	# 连接 GameManager 的波次变化信号
	if GameManager:
		if not GameManager.wave_changed.is_connected(_on_wave_changed):
			GameManager.wave_changed.connect(_on_wave_changed)

# =============================================================================
# 私有方法 - 主题切换
# =============================================================================

func _get_theme_for_wave(wave: int) -> ThemeType:
	"""根据波次获取主题"""
	for theme in THEME_CONFIG.keys():
		var wave_range: Array = THEME_CONFIG[theme].get("wave_range", [1, 5])
		if wave >= wave_range[0] and wave <= wave_range[1]:
			return theme
	return ThemeType.VOID_REALM  # 默认返回虚空领域


func _transition_to_theme(new_theme: ThemeType) -> void:
	"""过渡到新主题"""
	if is_transitioning:
		return
	
	is_transitioning = true
	var old_theme := current_theme
	current_theme = new_theme
	
	print("[BackgroundTheme] 切换主题: %s -> %s" % [THEME_CONFIG[old_theme].name, THEME_CONFIG[new_theme].name])
	
	# 播放过渡动画
	_play_transition_animation(old_theme, new_theme)
	
	# 触发信号
	theme_changed.emit(THEME_CONFIG[new_theme].name, current_wave)


func _play_transition_animation(old_theme: ThemeType, new_theme: ThemeType) -> void:
	"""播放过渡动画"""
	var old_config: Dictionary = THEME_CONFIG[old_theme]
	var new_config: Dictionary = THEME_CONFIG[new_theme]
	
	# 淡出效果
	var fade_overlay := ColorRect.new()
	fade_overlay.color = Color(0, 0, 0, 0)
	fade_overlay.z_index = 200
	fade_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_overlay.custom_minimum_size = Vector2(4000, 4000)
	fade_overlay.position = Vector2(-2000, -2000)
	add_child(fade_overlay)
	
	# 淡入淡出序列
	var fade_tween := create_tween()
	fade_tween.tween_property(fade_overlay, "color:a", 1.0, TRANSITION_DURATION * 0.4)
	fade_tween.tween_callback(func(): _apply_theme(new_theme, true))
	fade_tween.tween_property(fade_overlay, "color:a", 0.0, TRANSITION_DURATION * 0.4)
	fade_tween.tween_callback(func(): 
		fade_overlay.queue_free()
		is_transitioning = false
		transition_completed.emit()
	)


func _apply_theme(theme: ThemeType, animate: bool = false) -> void:
	"""应用主题"""
	var config: Dictionary = THEME_CONFIG[theme]
	
	if animate:
		# 动画过渡
		if _floor_bg:
			var bg_tween := create_tween()
			bg_tween.tween_property(_floor_bg, "color", config.bg_color, 0.5)
		
		if _ambient_light:
			var light_tween := create_tween()
			light_tween.tween_property(_ambient_light, "color", config.ambient_light, 0.5)
		
		# 更新网格线颜色
		if _grid_lines:
			for line in _grid_lines.get_children():
				if line is Line2D:
					var line_tween := create_tween()
					line_tween.tween_property(line, "default_color", config.grid_color, 0.5)
		
		# 更新粒子颜色
		if _ambient_particles:
			for particle in _ambient_particles.get_children():
				var sprite := particle.get_child(0) as Sprite2D
				if sprite:
					var sprite_tween := create_tween()
					sprite_tween.tween_property(sprite, "modulate", config.particle_color, 0.5)
	else:
		# 直接应用
		if _floor_bg:
			_floor_bg.color = config.bg_color
		
		if _ambient_light:
			_ambient_light.color = config.ambient_light
		
		# 更新网格线颜色
		if _grid_lines:
			for line in _grid_lines.get_children():
				if line is Line2D:
					line.default_color = config.grid_color
		
		# 更新粒子颜色
		if _ambient_particles:
			for particle in _ambient_particles.get_children():
				var sprite := particle.get_child(0) as Sprite2D
				if sprite:
					sprite.modulate = config.particle_color

# =============================================================================
# 私有方法 - 更新
# =============================================================================

func _update_ambient_particles(delta: float) -> void:
	"""更新环境粒子"""
	if _ambient_particles == null:
		return
	
	var time := Time.get_ticks_msec() / 1000.0
	
	for particle in _ambient_particles.get_children():
		var phase: float = particle.get_meta("phase", 0.0)
		var speed: float = particle.get_meta("speed", 1.0)
		var base_y: float = particle.get_meta("base_y", 0.0)
		
		# 上下浮动
		particle.position.y = base_y + sin(time * speed + phase) * 20.0
		
		# 缓慢水平移动
		particle.position.x += delta * 10.0 * speed
		
		# 如果超出屏幕，重置位置
		if particle.position.x > 800:
			particle.position.x = -800
			particle.position.y = randf_range(-600, 600)
			particle.set_meta("base_y", particle.position.y)


func _update_void_realm_effect(delta: float) -> void:
	"""更新虚空领域的彩虹效果"""
	var time := Time.get_ticks_msec() / 1000.0
	
	# 色相循环
	var hue := fmod(time * 0.1, 1.0)
	var rainbow_color := Color.from_hsv(hue, 0.3, 0.15, 1.0)
	
	if _floor_bg:
		_floor_bg.color = rainbow_color
	
	# 更新粒子颜色
	if _ambient_particles:
		for particle in _ambient_particles.get_children():
			var sprite := particle.get_child(0) as Sprite2D
			if sprite:
				var particle_hue := fmod(hue + particle.get_meta("phase", 0.0) * 0.1, 1.0)
				sprite.modulate = Color.from_hsv(particle_hue, 0.6, 1.0, 1.0)

# =============================================================================
# 信号回调
# =============================================================================

func _on_wave_changed(wave: int) -> void:
	"""波次变化回调"""
	set_wave(wave)
