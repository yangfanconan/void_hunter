extends Node

## Void Hunter - 存档管理器
## @description: 管理游戏存档的保存、加载和设置
## @version: 2.0.0

# =============================================================================
# 信号
# =============================================================================

signal save_completed(slot: int, success: bool)
signal load_completed(slot: int, success: bool)
signal settings_changed(key: String, value)

# =============================================================================
# 常量
# =============================================================================

const SAVE_DIR := "user://saves/"
const SETTINGS_PATH := "user://settings.cfg"
const MAX_SAVE_SLOTS := 3

# =============================================================================
# 私有变量
# =============================================================================

var _current_slot: int = 0
var _save_data: Dictionary = {}
var _settings: Dictionary = {}
var _initialized: bool = false

# =============================================================================
# 生命周期
# =============================================================================

func _ready() -> void:
	_initialize()

func _initialize() -> void:
	# 确保存档目录存在
	DirAccess.make_dir_recursive_absolute(SAVE_DIR.get_base_dir())
	# 加载设置
	load_settings()
	_initialized = true
	print("[SaveManager] 初始化完成")

# =============================================================================
# 公共方法 - 存档管理
# =============================================================================

## 保存游戏
func save_game(slot: int = -1) -> bool:
	var save_slot := slot if slot >= 0 else _current_slot
	if save_slot < 0 or save_slot >= MAX_SAVE_SLOTS:
		push_error("[SaveManager] 无效的存档槽位: %d" % save_slot)
		return false
	
	var file_path := SAVE_DIR + "save_%d.dat" % save_slot
	
	# 收集存档数据
	var data := _collect_save_data()
	data["timestamp"] = Time.get_datetime_string_from_system()
	data["slot"] = save_slot
	
	# 序列化并保存
	var json_string := JSON.stringify(data, "\t")
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_error("[SaveManager] 无法打开文件: %s" % file_path)
		save_completed.emit(save_slot, false)
		return false
	
	file.store_string(json_string)
	file.close()
	
	print("[SaveManager] 保存游戏到槽位 %d 成功" % save_slot)
	save_completed.emit(save_slot, true)
	return true


## 加载游戏
func load_game(slot: int = -1) -> bool:
	var load_slot := slot if slot >= 0 else _current_slot
	if load_slot < 0 or load_slot >= MAX_SAVE_SLOTS:
		push_error("[SaveManager] 无效的存档槽位: %d" % load_slot)
		return false
	
	var file_path := SAVE_DIR + "save_%d.dat" % load_slot
	
	if not FileAccess.file_exists(file_path):
		push_warning("[SaveManager] 存档文件不存在: %s" % file_path)
		load_completed.emit(load_slot, false)
		return false
	
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("[SaveManager] 无法打开文件: %s" % file_path)
		load_completed.emit(load_slot, false)
		return false
	
	var json_string := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var error := json.parse(json_string)
	if error != OK:
		push_error("[SaveManager] 存档解析失败: %s" % file_path)
		load_completed.emit(load_slot, false)
		return false
	
	_save_data = json.data
	_current_slot = load_slot
	print("[SaveManager] 从槽位 %d 加载游戏成功" % load_slot)
	load_completed.emit(load_slot, true)
	return true


## 检查是否有存档
func has_save(slot: int = -1) -> bool:
	var check_slot := slot if slot >= 0 else _current_slot
	var file_path := SAVE_DIR + "save_%d.dat" % check_slot
	return FileAccess.file_exists(file_path)


## 删除存档
func delete_save(slot: int) -> bool:
	var file_path := SAVE_DIR + "save_%d.dat" % slot
	if FileAccess.file_exists(file_path):
		DirAccess.remove_absolute(file_path)
		print("[SaveManager] 已删除槽位 %d 的存档" % slot)
		return true
	return false


## 自动保存
func auto_save() -> void:
	save_game(0)


## 获取存档数据
func get_save_data() -> Dictionary:
	return _save_data


## 设置存档数据
func set_save_data(key: String, value) -> void:
	_save_data[key] = value

# =============================================================================
# 公共方法 - 设置管理
# =============================================================================

## 保存设置
func save_settings(settings: Dictionary) -> bool:
	_settings = settings
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		push_error("[SaveManager] 无法保存设置")
		return false
	file.store_string(JSON.stringify(settings, "\t"))
	file.close()
	print("[SaveManager] 设置已保存")
	return true


## 加载设置
func load_settings() -> Dictionary:
	if not _settings.is_empty():
		return _settings
	
	if not FileAccess.file_exists(SETTINGS_PATH):
		_settings = _get_default_settings()
		return _settings
	
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		_settings = _get_default_settings()
		return _settings
	
	var json_string := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	if json.parse(json_string) == OK:
		_settings = json.data
	else:
		_settings = _get_default_settings()
	
	return _settings


## 获取设置值
func get_setting(key: String, default_value = null):
	var settings := load_settings()
	return settings.get(key, default_value)


## 设置单个设置值
func set_setting(key: String, value) -> void:
	_settings[key] = value
	save_settings(_settings)
	settings_changed.emit(key, value)

# =============================================================================
# 私有方法
# =============================================================================

func _collect_save_data() -> Dictionary:
	var data := _save_data.duplicate(true)
	
	# 收集游戏管理器数据
	if GameManager:
		data["game"] = GameManager.get_game_data()
	
	# 收集设置
	data["settings"] = _settings
	
	return data


func _get_default_settings() -> Dictionary:
	return {
		"master_volume": 1.0,
		"music_volume": 0.8,
		"sfx_volume": 1.0,
		"fullscreen": false,
		"language": "zh",
		"show_fps": false,
		"screen_shake": true,
		"particle_quality": 2,  # 0=低 1=中 2=高
		"controls": {},
		"records": {
			"best_time": 0.0,
			"best_kills": 0,
			"best_wave": 0,
		},
	}
