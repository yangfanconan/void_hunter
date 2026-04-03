## Void Hunter - 音频管理器
## @description: 管理游戏音效和音乐播放
## @author: Void Hunter Team
## @version: 1.0.0

extends Node

# =============================================================================
# 信号定义
# =============================================================================

signal volume_changed(bus: String, volume: float)

# =============================================================================
# 常量定义
# =============================================================================

## 音效路径
const SFX_PATH := "res://assets/audio/sfx/"
const MUSIC_PATH := "res://assets/audio/music/"

## 音效定义
const SFX_DEFINITIONS := {
	# UI音效
	"button_click": {"file": "ui/button_click.ogg", "volume": 0.8},
	"menu_open": {"file": "ui/menu_open.ogg", "volume": 0.7},
	"menu_close": {"file": "ui/menu_close.ogg", "volume": 0.7},

	# 游戏音效
	"wave_start": {"file": "game/wave_start.ogg", "volume": 0.9},
	"wave_complete": {"file": "game/wave_complete.ogg", "volume": 0.9},
	"game_over": {"file": "game/game_over.ogg", "volume": 1.0},
	"level_up": {"file": "game/level_up.ogg", "volume": 0.9},
	"victory": {"file": "game/victory.ogg", "volume": 1.0},

	# 成就音效
	"achievement_unlock": {"file": "ui/achievement_unlock.ogg", "volume": 1.0},

	# 战斗音效
	"hit": {"file": "combat/hit.ogg", "volume": 0.6},
	"hit_heavy": {"file": "combat/hit_heavy.ogg", "volume": 0.8},
	"death": {"file": "combat/death.ogg", "volume": 0.7},
	"explosion": {"file": "combat/explosion.ogg", "volume": 0.8},

	# 技能音效
	"skill_fire": {"file": "skills/fire.ogg", "volume": 0.7},
	"skill_ice": {"file": "skills/ice.ogg", "volume": 0.7},
	"skill_lightning": {"file": "skills/lightning.ogg", "volume": 0.7},
	"skill_shield": {"file": "skills/shield.ogg", "volume": 0.7},

	# 道具音效
	"item_pickup": {"file": "items/pickup.ogg", "volume": 0.8},
	"coin": {"file": "items/coin.ogg", "volume": 0.6},
	"heal": {"file": "items/heal.ogg", "volume": 0.8},

	# 玩家音效
	"player_hurt": {"file": "player/hurt.ogg", "volume": 0.9},
	"player_dash": {"file": "player/dash.ogg", "volume": 0.6},
}

# =============================================================================
# 私有变量
# =============================================================================

var _master_volume: float = 1.0
var _music_volume: float = 0.8
var _sfx_volume: float = 1.0

## 音效缓存
var _sfx_cache: Dictionary = {}

## 音乐播放器
var _music_player: AudioStreamPlayer = null

## 音效播放器池
var _sfx_players: Array[AudioStreamPlayer] = []

## 最大同时播放音效数
const MAX_SFX_PLAYERS: int = 8

## 当前音效播放器索引
var _current_sfx_index: int = 0

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""节点就绪"""
	_create_sfx_players()
	_create_music_player()
	print("[AudioManager] 初始化完成")

# =============================================================================
# 私有方法 - 初始化
# =============================================================================

func _create_sfx_players() -> void:
	"""创建音效播放器池"""
	for i in range(MAX_SFX_PLAYERS):
		var player := AudioStreamPlayer.new()
		player.name = "SFXPlayer_%d" % i
		add_child(player)
		_sfx_players.append(player)

func _create_music_player() -> void:
	"""创建音乐播放器"""
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	add_child(_music_player)

# =============================================================================
# 公共方法 - 音效播放
# =============================================================================

## 播放音效
func play_sfx(sound_name: String, volume: float = 1.0) -> void:
	"""播放音效"""
	if _sfx_volume <= 0 or _master_volume <= 0:
		return

	var actual_volume: float = volume * _sfx_volume * _master_volume

	# 获取音效定义
	var sfx_def: Dictionary = SFX_DEFINITIONS.get(sound_name, {})
	if sfx_def.is_empty():
		# 没有定义的音效，使用默认行为
		print("[AudioManager] 播放音效: %s (未定义)" % sound_name)
		return

	# 加载音效
	var stream: AudioStream = _get_or_load_sfx(sound_name, sfx_def)
	if stream == null:
		print("[AudioManager] 音效文件不存在: %s" % sound_name)
		return

	# 使用播放器池播放
	var player: AudioStreamPlayer = _sfx_players[_current_sfx_index]
	_current_sfx_index = (_current_sfx_index + 1) % MAX_SFX_PLAYERS

	player.stream = stream
	player.volume_db = linear_to_db(actual_volume * sfx_def.get("volume", 1.0))
	player.play()


func _get_or_load_sfx(sound_name: String, sfx_def: Dictionary) -> AudioStream:
	"""获取或加载音效"""
	if _sfx_cache.has(sound_name):
		return _sfx_cache[sound_name]

	var file_path: String = SFX_PATH + sfx_def.get("file", "")
	if not ResourceLoader.exists(file_path):
		return null

	var stream: AudioStream = load(file_path)
	_sfx_cache[sound_name] = stream
	return stream


## 播放音乐
func play_music(music_name: String, volume: float = 0.8) -> void:
	"""播放背景音乐"""
	if _music_player == null:
		return

	var actual_volume: float = volume * _music_volume * _master_volume
	print("[AudioManager] 播放音乐: %s (%.0f%%)" % [music_name, actual_volume * 100])

	var file_path: String = MUSIC_PATH + music_name + ".ogg"
	if not ResourceLoader.exists(file_path):
		print("[AudioManager] 音乐文件不存在: %s" % music_name)
		return

	var stream: AudioStream = load(file_path)
	_music_player.stream = stream
	_music_player.volume_db = linear_to_db(actual_volume)
	_music_player.play()


## 停止音乐
func stop_music(fade_time: float = 0.0) -> void:
	"""停止当前音乐"""
	if _music_player == null:
		return

	if fade_time > 0:
		var tween := create_tween()
		tween.tween_property(_music_player, "volume_db", -40.0, fade_time)
		tween.tween_callback(func(): _music_player.stop())
	else:
		_music_player.stop()

	print("[AudioManager] 停止音乐")


## 暂停音乐
func pause_music() -> void:
	"""暂停当前音乐"""
	if _music_player:
		_music_player.stream_paused = true
	print("[AudioManager] 暂停音乐")


## 恢复音乐
func resume_music() -> void:
	"""恢复播放音乐"""
	if _music_player:
		_music_player.stream_paused = false
	print("[AudioManager] 恢复音乐")

# =============================================================================
# 公共方法 - 音量控制
# =============================================================================

## 设置主音量
func set_master_volume(volume: float) -> void:
	"""设置主音量"""
	_master_volume = clamp(volume, 0.0, 1.0)
	volume_changed.emit("master", _master_volume)


## 设置音乐音量
func set_music_volume(volume: float) -> void:
	"""设置音乐音量"""
	_music_volume = clamp(volume, 0.0, 1.0)
	volume_changed.emit("music", _music_volume)


## 设置音效音量
func set_sfx_volume(volume: float) -> void:
	"""设置音效音量"""
	_sfx_volume = clamp(volume, 0.0, 1.0)
	volume_changed.emit("sfx", _sfx_volume)


## 获取主音量
func get_master_volume() -> float:
	"""获取主音量"""
	return _master_volume


## 获取音乐音量
func get_music_volume() -> float:
	"""获取音乐音量"""
	return _music_volume


## 获取音效音量
func get_sfx_volume() -> float:
	"""获取音效音量"""
	return _sfx_volume

# =============================================================================
# 公共方法 - 音量开关
# =============================================================================

## 静音
func mute() -> void:
	"""静音所有音频"""
	_master_volume = 0.0
	volume_changed.emit("master", 0.0)


## 取消静音
func unmute(volume: float = 1.0) -> void:
	"""取消静音"""
	_master_volume = clamp(volume, 0.0, 1.0)
	volume_changed.emit("master", _master_volume)


## 切换静音
func toggle_mute() -> bool:
	"""切换静音状态，返回是否静音"""
	if _master_volume > 0:
		mute()
		return true
	else:
		unmute()
		return false
