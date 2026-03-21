## Void Hunter - 音效管理器
## @description: 全局音效和音乐管理单例，负责背景音乐、音效播放和音量控制
## @author: Void Hunter Team
## @version: 0.1.0

extends Node

# =============================================================================
# 信号定义
# =============================================================================

## 音量改变时触发
signal volume_changed(bus_name: String, volume_db: float)

## 背景音乐改变时触发
signal bgm_changed(track_name: String)

## 音效播放时触发（用于调试）
signal sfx_played(sound_name: String, position: Vector2)

# =============================================================================
# 常量定义
# =============================================================================

## 音频总线名称
const BUS_MASTER: String = "Master"
const BUS_MUSIC: String = "Music"
const BUS_SFX: String = "SFX"
const BUS_AMBIENT: String = "Ambient"

## 音量范围（分贝）
const MIN_VOLUME_DB: float = -40.0
const MAX_VOLUME_DB: float = 0.0
const MUTE_VOLUME_DB: float = -80.0

## 默认淡入淡出时间
const DEFAULT_FADE_TIME: float = 1.0

## 音频文件路径
const AUDIO_PATH: String = "res://assets/audio/"
const BGM_PATH: String = AUDIO_PATH + "bgm/"
const SFX_PATH: String = AUDIO_PATH + "sfx/"

# =============================================================================
# 枚举定义
# =============================================================================

## 音效类型
enum SoundType {
	BGM,		## 背景音乐
	SFX,		## 音效
	AMBIENT,	## 环境音
	UI			## UI音效
}

# =============================================================================
# 导出变量
# =============================================================================

## 是否启用调试日志
@export var debug_logging: bool = false

## 默认BGM音量
@export_range(0.0, 1.0) var default_bgm_volume: float = 0.8

## 默认SFX音量
@export_range(0.0, 1.0) var default_sfx_volume: float = 1.0

# =============================================================================
# 公共变量
# =============================================================================

## 当前BGM名称
var current_bgm_name: String = ""

## 是否正在播放BGM
var is_bgm_playing: bool = false

# =============================================================================
# 私有变量
# =============================================================================

var _bgm_player: AudioStreamPlayer
var _bgm_player_secondary: AudioStreamPlayer
var _ambient_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _audio_pool_size: int = 16
var _current_pool_index: int = 0

var _bgm_tween: Tween
var _cached_sounds: Dictionary = {}
var _volume_settings: Dictionary = {
	BUS_MASTER: 1.0,
	BUS_MUSIC: 0.8,
	BUS_SFX: 1.0,
	BUS_AMBIENT: 0.6
}

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""
	节点就绪时初始化音频管理器
	"""
	_initialize_audio_manager()


# =============================================================================
# 公共方法 - 初始化
# =============================================================================

## 初始化音频管理器
func initialize() -> void:
	"""
	手动初始化音频管理器
	"""
	_initialize_audio_manager()


# =============================================================================
# 公共方法 - 音量控制
# =============================================================================

## 设置总线音量
func set_bus_volume(bus_name: String, linear_volume: float) -> void:
	"""
	设置指定音频总线的音量
	@param bus_name: 总线名称
	@param linear_volume: 线性音量值 (0.0 - 1.0)
	"""
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		push_warning("找不到音频总线: " + bus_name)
		return
	
	# 限制音量范围
	linear_volume = clampf(linear_volume, 0.0, 1.0)
	
	# 保存设置
	_volume_settings[bus_name] = linear_volume
	
	# 转换为分贝并应用
	var volume_db: float = _linear_to_db(linear_volume)
	AudioServer.set_bus_volume_db(bus_index, volume_db)
	
	volume_changed.emit(bus_name, volume_db)
	
	if debug_logging:
		print("[AudioManager] 设置音量 %s: %.2f (%.2f dB)" % [bus_name, linear_volume, volume_db])


## 获取总线音量
func get_bus_volume(bus_name: String) -> float:
	"""
	获取指定音频总线的音量
	@param bus_name: 总线名称
	@return: 线性音量值 (0.0 - 1.0)
	"""
	return _volume_settings.get(bus_name, 1.0)


## 设置总线静音
func set_bus_mute(bus_name: String, is_mute: bool) -> void:
	"""
	设置指定音频总线的静音状态
	@param bus_name: 总线名称
	@param is_mute: 是否静音
	"""
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		push_warning("找不到音频总线: " + bus_name)
		return
	
	AudioServer.set_bus_mute(bus_index, is_mute)


## 切换总线静音
func toggle_bus_mute(bus_name: String) -> bool:
	"""
	切换指定音频总线的静音状态
	@param bus_name: 总线名称
	@return: 当前静音状态
	"""
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return false
	
	var current_mute: bool = AudioServer.is_bus_mute(bus_index)
	AudioServer.set_bus_mute(bus_index, not current_mute)
	return not current_mute


# =============================================================================
# 公共方法 - BGM播放
# =============================================================================

## 播放背景音乐
func play_bgm(bgm_name: String, fade_in: bool = true, fade_time: float = DEFAULT_FADE_TIME) -> void:
	"""
	播放背景音乐
	@param bgm_name: BGM文件名（不含扩展名）
	@param fade_in: 是否淡入
	@param fade_time: 淡入时间
	"""
	var bgm_path: String = BGM_PATH + bgm_name + ".ogg"
	
	if not ResourceLoader.exists(bgm_path):
		push_warning("找不到BGM文件: " + bgm_path)
		return
	
	# 如果正在播放同一首，忽略
	if current_bgm_name == bgm_name and is_bgm_playing:
		return
	
	var stream: AudioStream = _load_audio_stream(bgm_path)
	if stream == null:
		return
	
	# 交叉淡入淡出
	if is_bgm_playing:
		_crossfade_bgm(stream, bgm_name, fade_time)
	else:
		_play_bgm_immediate(stream, bgm_name, fade_in, fade_time)


## 停止背景音乐
func stop_bgm(fade_out: bool = true, fade_time: float = DEFAULT_FADE_TIME) -> void:
	"""
	停止背景音乐
	@param fade_out: 是否淡出
	@param fade_time: 淡出时间
	"""
	if not is_bgm_playing:
		return
	
	if fade_out:
		_fade_out_bgm(fade_time)
	else:
		_bgm_player.stop()
		is_bgm_playing = false
		current_bgm_name = ""


## 暂停背景音乐
func pause_bgm() -> void:
	"""
	暂停背景音乐
	"""
	if _bgm_player and is_bgm_playing:
		_bgm_player.stream_paused = true


## 恢复背景音乐
func resume_bgm() -> void:
	"""
	恢复背景音乐
	"""
	if _bgm_player and _bgm_player.stream_paused:
		_bgm_player.stream_paused = false


# =============================================================================
# 公共方法 - SFX播放
# =============================================================================

## 播放音效
func play_sfx(sound_name: String, volume_scale: float = 1.0, pitch_scale: float = 1.0, position: Variant = null) -> AudioStreamPlayer:
	"""
	播放音效
	@param sound_name: 音效文件名（不含扩展名）
	@param volume_scale: 音量缩放 (0.0 - 2.0)
	@param pitch_scale: 音调缩放 (0.5 - 2.0)
	@param position: 可选的2D位置（用于空间音效）
	@return: 音频播放器实例
	"""
	var sfx_path: String = SFX_PATH + sound_name + ".wav"
	
	# 尝试其他格式
	if not ResourceLoader.exists(sfx_path):
		sfx_path = SFX_PATH + sound_name + ".ogg"
	
	if not ResourceLoader.exists(sfx_path):
		push_warning("找不到SFX文件: " + sound_name)
		return null
	
	var stream: AudioStream = _load_audio_stream(sfx_path)
	if stream == null:
		return null
	
	var player: AudioStreamPlayer = _get_available_sfx_player()
	player.stream = stream
	player.volume_db = _linear_to_db(default_sfx_volume * volume_scale)
	player.pitch_scale = clampf(pitch_scale, 0.5, 2.0)
	player.bus = BUS_SFX
	player.play()
	
	if debug_logging:
		var pos_info: String = ""
		if position != null:
			pos_info = " at " + str(position)
		print("[AudioManager] 播放SFX: %s%s" % [sound_name, pos_info])
		sfx_played.emit(sound_name, position if position is Vector2 else Vector2.ZERO)
	
	return player


## 播放UI音效
func play_ui_sound(sound_name: String) -> void:
	"""
	播放UI音效
	@param sound_name: UI音效名称
	"""
	play_sfx("ui/" + sound_name, 1.0, 1.0)


## 播放随机变体音效
func play_sfx_variant(base_name: String, variant_count: int, volume_scale: float = 1.0) -> AudioStreamPlayer:
	"""
	播放随机变体音效（用于避免重复感）
	@param base_name: 基础音效名称
	@param variant_count: 变体数量
	@param volume_scale: 音量缩放
	@return: 音频播放器实例
	"""
	var variant_index: int = randi() % variant_count
	var variant_name: String = base_name + "_" + str(variant_index + 1)
	
	# 如果变体不存在，尝试播放基础音效
	var sfx_path: String = SFX_PATH + variant_name + ".wav"
	if not ResourceLoader.exists(sfx_path):
		return play_sfx(base_name, volume_scale, randf_range(0.9, 1.1))
	
	return play_sfx(variant_name, volume_scale, randf_range(0.9, 1.1))


# =============================================================================
# 公共方法 - 环境音
# =============================================================================

## 播放环境音
func play_ambient(sound_name: String, fade_in: bool = true, fade_time: float = 2.0) -> void:
	"""
	播放环境音
	@param sound_name: 环境音文件名
	@param fade_in: 是否淡入
	@param fade_time: 淡入时间
	"""
	var ambient_path: String = AUDIO_PATH + "ambient/" + sound_name + ".ogg"
	
	if not ResourceLoader.exists(ambient_path):
		push_warning("找不到环境音文件: " + ambient_path)
		return
	
	var stream: AudioStream = _load_audio_stream(ambient_path)
	if stream == null:
		return
	
	_ambient_player.stream = stream
	_ambient_player.bus = BUS_AMBIENT
	
	if fade_in:
		_ambient_player.volume_db = MUTE_VOLUME_DB
		_ambient_player.play()
		
		var tween: Tween = create_tween()
		tween.tween_property(_ambient_player, "volume_db", 
			_linear_to_db(_volume_settings[BUS_AMBIENT]), fade_time)
	else:
		_ambient_player.play()


## 停止环境音
func stop_ambient(fade_out: bool = true, fade_time: float = 2.0) -> void:
	"""
	停止环境音
	@param fade_out: 是否淡出
	@param fade_time: 淡出时间
	"""
	if not _ambient_player or not _ambient_player.playing:
		return
	
	if fade_out:
		var tween: Tween = create_tween()
		tween.tween_property(_ambient_player, "volume_db", MUTE_VOLUME_DB, fade_time)
		tween.tween_callback(_ambient_player.stop)
	else:
		_ambient_player.stop()


# =============================================================================
# 公共方法 - 音频设置
# =============================================================================

## 保存音频设置
func save_audio_settings() -> Dictionary:
	"""
	保存音频设置到字典
	@return: 音频设置字典
	"""
	return _volume_settings.duplicate()


## 加载音频设置
func load_audio_settings(settings: Dictionary) -> void:
	"""
	从字典加载音频设置
	@param settings: 音频设置字典
	"""
	for bus_name in settings.keys():
		set_bus_volume(bus_name, settings[bus_name])


# =============================================================================
# 私有方法
# =============================================================================

func _initialize_audio_manager() -> void:
	"""
	初始化音频管理器
	"""
	# 创建BGM播放器
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = BUS_MUSIC
	add_child(_bgm_player)
	
	# 创建备用BGM播放器（用于交叉淡入淡出）
	_bgm_player_secondary = AudioStreamPlayer.new()
	_bgm_player_secondary.bus = BUS_MUSIC
	add_child(_bgm_player_secondary)
	
	# 创建环境音播放器
	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.bus = BUS_AMBIENT
	add_child(_ambient_player)
	
	# 创建SFX播放器池
	for i in range(_audio_pool_size):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = BUS_SFX
		add_child(player)
		_sfx_players.append(player)
	
	# 应用默认音量
	for bus_name in _volume_settings.keys():
		set_bus_volume(bus_name, _volume_settings[bus_name])
	
	if debug_logging:
		print("[AudioManager] 初始化完成，SFX池大小: %d" % _audio_pool_size)


func _load_audio_stream(path: String) -> AudioStream:
	"""
	加载音频流
	@param path: 音频文件路径
	@return: 音频流实例
	"""
	# 检查缓存
	if _cached_sounds.has(path):
		return _cached_sounds[path]
	
	var stream: AudioStream = load(path)
	if stream == null:
		push_error("无法加载音频文件: " + path)
		return null
	
	# 缓存音频
	_cached_sounds[path] = stream
	return stream


func _get_available_sfx_player() -> AudioStreamPlayer:
	"""
	获取可用的SFX播放器
	@return: 可用的音频播放器
	"""
	# 查找未在播放的播放器
	for player in _sfx_players:
		if not player.playing:
			return player
	
	# 如果所有播放器都在使用，使用轮询方式
	_current_pool_index = (_current_pool_index + 1) % _audio_pool_size
	return _sfx_players[_current_pool_index]


func _play_bgm_immediate(stream: AudioStream, bgm_name: String, fade_in: bool, fade_time: float) -> void:
	"""
	立即播放BGM
	"""
	_bgm_player.stream = stream
	current_bgm_name = bgm_name
	
	if fade_in:
		_bgm_player.volume_db = MUTE_VOLUME_DB
		_bgm_player.play()
		
		if _bgm_tween:
			_bgm_tween.kill()
		_bgm_tween = create_tween()
		_bgm_tween.tween_property(_bgm_player, "volume_db", 
			_linear_to_db(default_bgm_volume), fade_time)
	else:
		_bgm_player.volume_db = _linear_to_db(default_bgm_volume)
		_bgm_player.play()
	
	is_bgm_playing = true
	bgm_changed.emit(bgm_name)


func _crossfade_bgm(new_stream: AudioStream, new_name: String, fade_time: float) -> void:
	"""
	交叉淡入淡出BGM
	"""
	# 交换播放器
	var old_player: AudioStreamPlayer = _bgm_player
	_bgm_player = _bgm_player_secondary
	_bgm_player_secondary = old_player
	
	# 设置新BGM
	_bgm_player.stream = new_stream
	_bgm_player.volume_db = MUTE_VOLUME_DB
	_bgm_player.play()
	
	# 创建交叉淡入淡出动画
	if _bgm_tween:
		_bgm_tween.kill()
	_bgm_tween = create_tween()
	
	# 同时淡出旧BGM和淡入新BGM
	_bgm_tween.tween_property(_bgm_player, "volume_db", 
		_linear_to_db(default_bgm_volume), fade_time)
	_bgm_tween.parallel().tween_property(_bgm_player_secondary, "volume_db", 
		MUTE_VOLUME_DB, fade_time)
	_bgm_tween.tween_callback(_bgm_player_secondary.stop)
	
	current_bgm_name = new_name
	bgm_changed.emit(new_name)


func _fade_out_bgm(fade_time: float) -> void:
	"""
	淡出BGM
	"""
	if _bgm_tween:
		_bgm_tween.kill()
	_bgm_tween = create_tween()
	
	_bgm_tween.tween_property(_bgm_player, "volume_db", MUTE_VOLUME_DB, fade_time)
	_bgm_tween.tween_callback(func():
		_bgm_player.stop()
		is_bgm_playing = false
		current_bgm_name = ""
	)


func _linear_to_db(linear: float) -> float:
	"""
	将线性音量转换为分贝
	@param linear: 线性音量值 (0.0 - 1.0)
	@return: 分贝值
	"""
	if linear <= 0.0:
		return MUTE_VOLUME_DB
	return log(linear) * 8.685889638  # 20 / ln(10)
