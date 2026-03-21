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
# 私有变量
# =============================================================================

var _master_volume: float = 1.0
var _music_volume: float = 0.8
var _sfx_volume: float = 1.0

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""节点就绪"""
	print("[AudioManager] 初始化完成")

# =============================================================================
# 公共方法 - 音效播放
# =============================================================================

## 播放音效
func play_sfx(sound_name: String, volume: float = 1.0) -> void:
	"""播放音效"""
	if _sfx_volume <= 0 or _master_volume <= 0:
		return
	var actual_volume: float = volume * _sfx_volume * _master_volume
	print("[AudioManager] 播放音效: %s (%.0f%%)" % [sound_name, actual_volume * 100])


## 播放音乐
func play_music(music_name: String, volume: float = 0.8) -> void:
	"""播放背景音乐"""
	var actual_volume: float = volume * _music_volume * _master_volume
	print("[AudioManager] 播放音乐: %s (%.0f%%)" % [music_name, actual_volume * 100])


## 停止音乐
func stop_music(_fade_time: float = 0.0) -> void:
	"""停止当前音乐"""
	print("[AudioManager] 停止音乐")


## 暂停音乐
func pause_music() -> void:
	"""暂停当前音乐"""
	print("[AudioManager] 暂停音乐")


## 恢复音乐
func resume_music() -> void:
	"""恢复播放音乐"""
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
