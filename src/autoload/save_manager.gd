## Void Hunter - 存档管理器
## @description: 全局存档管理单例，负责游戏进度的保存、加载和删除
## @author: Void Hunter Team
## @version: 1.1.0

extends Node

# =============================================================================
# 信号定义
# =============================================================================

## 存档保存完成时触发
signal save_completed(success: bool, slot_id: int)

## 存档加载完成时触发
signal load_completed(success: bool, slot_id: int)

## 存档删除完成时触发
signal save_deleted(slot_id: int)

## 自动保存完成时触发
signal auto_save_completed(success: bool)

# =============================================================================
# 常量定义
# =============================================================================

## 存档文件名前缀
const SAVE_FILE_PREFIX: String = "save_"
const SAVE_FILE_EXTENSION: String = ".sav"

## 自动存档文件名
const AUTO_SAVE_FILE: String = "autosave.sav"

## 设置文件名
const SETTINGS_FILE: String = "settings.cfg"

## 解锁数据文件名
const UNLOCK_FILE: String = "unlocks.json"

## 最大存档槽位数
const MAX_SAVE_SLOTS: int = 3

## 存档版本（用于兼容性检查）
const SAVE_VERSION: int = 1

# =============================================================================
# 枚举定义
# =============================================================================

## 存档类型
enum SaveType {
	MANUAL,		## 手动存档
	AUTO,		## 自动存档
	QUICK		## 快速存档
}

# =============================================================================
# 导出变量
# =============================================================================

## 是否启用自动保存
@export var auto_save_enabled: bool = true

## 自动保存间隔（秒）
@export var auto_save_interval: float = 300.0  # 5分钟

## 是否启用调试日志
@export var debug_logging: bool = false

# =============================================================================
# 公共变量
# =============================================================================

## 当前使用的存档槽位
var current_slot: int = 0

# =============================================================================
# 私有变量
# =============================================================================

var _save_directory: String = ""
var _auto_save_timer: Timer
var _last_auto_save_time: float = 0.0
var _is_saving: bool = false
var _is_loading: bool = false

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""
	节点就绪时初始化存档管理器
	"""
	_initialize_save_manager()


# =============================================================================
# 公共方法 - 初始化
# =============================================================================

## 初始化存档管理器
func initialize() -> void:
	"""
	手动初始化存档管理器
	"""
	_initialize_save_manager()


# =============================================================================
# 公共方法 - 存档操作
# =============================================================================

## 保存游戏
func save_game(save_data: Dictionary, slot_id: int = -1) -> bool:
	"""
	保存游戏进度
	@param save_data: 存档数据
	@param slot_id: 存档槽位ID（-1表示当前槽位）
	@return: 是否保存成功
	"""
	if _is_saving:
		push_warning("正在保存中，请稍后再试")
		return false
	
	if slot_id == -1:
		slot_id = current_slot
	
	# 验证槽位ID
	if not _is_valid_slot(slot_id):
		push_error("无效的存档槽位: %d" % slot_id)
		return false
	
	_is_saving = true
	
	# 添加元数据
	var full_save_data: Dictionary = _add_save_metadata(save_data, SaveType.MANUAL)
	
	# 保存到文件
	var success: bool = _write_save_file(slot_id, full_save_data)
	
	_is_saving = false
	
	if success:
		save_completed.emit(true, slot_id)
		if debug_logging:
			print("[SaveManager] 存档保存成功: 槽位 %d" % slot_id)
	else:
		save_completed.emit(false, slot_id)
		push_error("存档保存失败: 槽位 %d" % slot_id)
	
	return success


## 加载游戏
func load_game(slot_id: int = -1) -> Dictionary:
	"""
	加载游戏进度
	@param slot_id: 存档槽位ID（-1表示当前槽位）
	@return: 存档数据（失败时返回空字典）
	"""
	if _is_loading:
		push_warning("正在加载中，请稍后再试")
		return {}
	
	if slot_id == -1:
		slot_id = current_slot
	
	# 首先尝试加载自动存档
	if slot_id == -1:
		var auto_save: Dictionary = load_auto_save()
		if not auto_save.is_empty():
			return auto_save
	
	# 验证槽位ID
	if not _is_valid_slot(slot_id):
		push_error("无效的存档槽位: %d" % slot_id)
		return {}
	
	_is_loading = true
	
	var save_data: Dictionary = _read_save_file(slot_id)
	
	_is_loading = false
	
	if save_data.is_empty():
		load_completed.emit(false, slot_id)
		push_warning("存档加载失败或存档为空: 槽位 %d" % slot_id)
		return {}
	
	# 验证存档版本
	if not _validate_save_version(save_data):
		push_warning("存档版本不兼容: 槽位 %d" % slot_id)
		load_completed.emit(false, slot_id)
		return {}
	
	load_completed.emit(true, slot_id)
	current_slot = slot_id
	
	if debug_logging:
		print("[SaveManager] 存档加载成功: 槽位 %d" % slot_id)
	
	return save_data.get("data", {})


## 删除存档
func delete_save(slot_id: int) -> bool:
	"""
	删除存档
	@param slot_id: 存档槽位ID
	@return: 是否删除成功
	"""
	if not _is_valid_slot(slot_id):
		push_error("无效的存档槽位: %d" % slot_id)
		return false
	
	var file_path: String = _get_save_file_path(slot_id)
	
	if not FileAccess.file_exists(file_path):
		push_warning("存档不存在: 槽位 %d" % slot_id)
		return true
	
	var success: bool = DirAccess.remove_absolute(file_path) == OK
	
	if success:
		save_deleted.emit(slot_id)
		if debug_logging:
			print("[SaveManager] 存档删除成功: 槽位 %d" % slot_id)
	else:
		push_error("存档删除失败: 槽位 %d" % slot_id)
	
	return success


## 检查存档是否存在
func has_save(slot_id: int) -> bool:
	"""
	检查指定槽位是否有存档
	@param slot_id: 存档槽位ID
	@return: 是否存在存档
	"""
	if not _is_valid_slot(slot_id):
		return false
	
	return FileAccess.file_exists(_get_save_file_path(slot_id))


## 获取存档信息
func get_save_info(slot_id: int) -> Dictionary:
	"""
	获取存档的基本信息（不加载完整数据）
	@param slot_id: 存档槽位ID
	@return: 存档信息字典
	"""
	if not has_save(slot_id):
		return {}
	
	var save_data: Dictionary = _read_save_file(slot_id)
	if save_data.is_empty():
		return {}
	
	return {
		"slot_id": slot_id,
		"version": save_data.get("version", 0),
		"timestamp": save_data.get("timestamp", 0),
		"play_time": save_data.get("data", {}).get("game_time", 0),
		"level": save_data.get("data", {}).get("level_index", 0),
		"game_mode": save_data.get("data", {}).get("game_mode", 0)
	}


## 获取所有存档信息
func get_all_save_infos() -> Array[Dictionary]:
	"""
	获取所有存档槽位的信息
	@return: 存档信息数组
	"""
	var infos: Array[Dictionary] = []
	
	for slot_id in range(MAX_SAVE_SLOTS):
		var info: Dictionary = get_save_info(slot_id)
		if not info.is_empty():
			infos.append(info)
		else:
			infos.append({"slot_id": slot_id, "empty": true})
	
	return infos


# =============================================================================
# 公共方法 - 自动存档
# =============================================================================

## 执行自动保存
func perform_auto_save(save_data: Dictionary) -> bool:
	"""
	执行自动保存
	@param save_data: 存档数据
	@return: 是否保存成功
	"""
	var full_save_data: Dictionary = _add_save_metadata(save_data, SaveType.AUTO)
	var success: bool = _write_save_file(-1, full_save_data, true)
	
	_last_auto_save_time = Time.get_unix_time_from_system()
	auto_save_completed.emit(success)
	
	if debug_logging and success:
		print("[SaveManager] 自动保存成功")
	
	return success


## 加载自动存档
func load_auto_save() -> Dictionary:
	"""
	加载自动存档
	@return: 存档数据
	"""
	var auto_save_path: String = _get_save_directory() + AUTO_SAVE_FILE
	
	if not FileAccess.file_exists(auto_save_path):
		return {}
	
	var save_data: Dictionary = _read_json_file(auto_save_path)
	
	if save_data.is_empty():
		return {}
	
	if not _validate_save_version(save_data):
		return {}
	
	return save_data.get("data", {})


## 检查是否有自动存档
func has_auto_save() -> bool:
	"""
	检查是否存在自动存档
	@return: 是否存在自动存档
	"""
	return FileAccess.file_exists(_get_save_directory() + AUTO_SAVE_FILE)


# =============================================================================
# 公共方法 - 设置管理
# =============================================================================

## 保存游戏设置
func save_settings(settings: Dictionary) -> bool:
	"""
	保存游戏设置
	@param settings: 设置数据
	@return: 是否保存成功
	"""
	var settings_path: String = _get_save_directory() + SETTINGS_FILE
	var config: ConfigFile = ConfigFile.new()
	
	for section in settings.keys():
		var section_data: Variant = settings[section]
		if section_data is Dictionary:
			for key in section_data.keys():
				config.set_value(section, key, section_data[key])
		else:
			config.set_value("general", section, section_data)
	
	var error: int = config.save(settings_path)
	
	if error != OK:
		push_error("设置保存失败，错误码: %d" % error)
		return false
	
	if debug_logging:
		print("[SaveManager] 设置保存成功")
	
	return true


## 加载游戏设置
func load_settings() -> Dictionary:
	"""
	加载游戏设置
	@return: 设置数据
	"""
	var settings_path: String = _get_save_directory() + SETTINGS_FILE
	
	if not FileAccess.file_exists(settings_path):
		return {}
	
	var config: ConfigFile = ConfigFile.new()
	var error: int = config.load(settings_path)
	
	if error != OK:
		push_warning("设置加载失败，错误码: %d" % error)
		return {}
	
	var settings: Dictionary = {}
	for section in config.get_sections():
		settings[section] = {}
		for key in config.get_section_keys(section):
			settings[section][key] = config.get_value(section, key)
	
	return settings


# =============================================================================
# 公共方法 - 解锁数据
# =============================================================================

## 保存解锁数据
func save_unlock_data(unlock_data: Dictionary) -> bool:
	"""
	保存解锁数据
	@param unlock_data: 解锁数据
	@return: 是否保存成功
	"""
	var unlock_path: String = _get_save_directory() + UNLOCK_FILE
	return _write_json_file(unlock_path, unlock_data)


## 加载解锁数据
func load_unlock_data() -> Dictionary:
	"""
	加载解锁数据
	@return: 解锁数据
	"""
	var unlock_path: String = _get_save_directory() + UNLOCK_FILE
	
	if not FileAccess.file_exists(unlock_path):
		return {}
	
	return _read_json_file(unlock_path)


# =============================================================================
# 公共方法 - 数据清理
# =============================================================================

## 清除所有存档
func clear_all_saves() -> bool:
	"""
	清除所有存档（包括自动存档）
	@return: 是否清除成功
	"""
	var success: bool = true
	
	# 删除所有槽位存档
	for slot_id in range(MAX_SAVE_SLOTS):
		if has_save(slot_id):
			if not delete_save(slot_id):
				success = false
	
	# 删除自动存档
	var auto_save_path: String = _get_save_directory() + AUTO_SAVE_FILE
	if FileAccess.file_exists(auto_save_path):
		if DirAccess.remove_absolute(auto_save_path) != OK:
			success = false
	
	if debug_logging and success:
		print("[SaveManager] 所有存档已清除")
	
	return success


# =============================================================================
# 私有方法
# =============================================================================

func _initialize_save_manager() -> void:
	"""
	初始化存档管理器
	"""
	# 设置存档目录
	_save_directory = _get_save_directory()
	
	# 确保存档目录存在
	_ensure_save_directory()
	
	# 创建自动保存计时器
	if auto_save_enabled:
		_setup_auto_save_timer()
	
	if debug_logging:
		print("[SaveManager] 初始化完成，存档目录: %s" % _save_directory)


func _get_save_directory() -> String:
	"""
	获取存档目录路径
	@return: 存档目录路径
	"""
	# 使用用户数据目录
	var user_dir: String = "user://saves/"
	
	# 在编辑器中，使用项目目录下的saves文件夹
	if OS.is_debug_build():
		user_dir = "res://saves/"
	
	return user_dir


func _ensure_save_directory() -> void:
	"""
	确保存档目录存在
	"""
	var dir: DirAccess = DirAccess.open("user://")
	
	if dir == null:
		push_error("无法访问用户目录")
		return
	
	# 创建saves目录
	if not dir.dir_exists("saves"):
		var error: int = dir.make_dir("saves")
		if error != OK:
			push_error("无法创建存档目录，错误码: %d" % error)


func _setup_auto_save_timer() -> void:
	"""
	设置自动保存计时器
	"""
	_auto_save_timer = Timer.new()
	_auto_save_timer.wait_time = auto_save_interval
	_auto_save_timer.autostart = true
	_auto_save_timer.timeout.connect(_on_auto_save_timeout)
	add_child(_auto_save_timer)


func _is_valid_slot(slot_id: int) -> bool:
	"""
	验证存档槽位是否有效
	@param slot_id: 槽位ID
	@return: 是否有效
	"""
	return slot_id >= 0 and slot_id < MAX_SAVE_SLOTS


func _get_save_file_path(slot_id: int) -> String:
	"""
	获取存档文件路径
	@param slot_id: 槽位ID
	@return: 文件路径
	"""
	return _save_directory + SAVE_FILE_PREFIX + str(slot_id) + SAVE_FILE_EXTENSION


func _add_save_metadata(save_data: Dictionary, save_type: SaveType) -> Dictionary:
	"""
	添加存档元数据
	@param save_data: 原始存档数据
	@param save_type: 存档类型
	@return: 包含元数据的完整存档
	"""
	return {
		"version": SAVE_VERSION,
		"game_version": ProjectSettings.get_setting("application/config/version"),
		"timestamp": Time.get_unix_time_from_system(),
		"save_type": save_type,
		"data": save_data
	}


func _write_save_file(slot_id: int, save_data: Dictionary, is_auto_save: bool = false) -> bool:
	"""
	写入存档文件
	@param slot_id: 槽位ID
	@param save_data: 存档数据
	@param is_auto_save: 是否为自动存档
	@return: 是否成功
	"""
	var file_path: String
	
	if is_auto_save:
		file_path = _save_directory + AUTO_SAVE_FILE
	else:
		file_path = _get_save_file_path(slot_id)
	
	return _write_json_file(file_path, save_data)


func _read_save_file(slot_id: int) -> Dictionary:
	"""
	读取存档文件
	@param slot_id: 槽位ID
	@return: 存档数据
	"""
	var file_path: String = _get_save_file_path(slot_id)
	return _read_json_file(file_path)


func _write_json_file(file_path: String, data: Dictionary) -> bool:
	"""
	写入JSON文件
	@param file_path: 文件路径
	@param data: 数据字典
	@return: 是否成功
	"""
	var json_string: String = JSON.stringify(data, "  ")
	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	
	if file == null:
		push_error("无法打开文件进行写入: %s" % file_path)
		return false
	
	file.store_string(json_string)
	file.close()
	
	return true


func _read_json_file(file_path: String) -> Dictionary:
	"""
	读取JSON文件
	@param file_path: 文件路径
	@return: 数据字典
	"""
	if not FileAccess.file_exists(file_path):
		return {}
	
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	
	if file == null:
		push_error("无法打开文件进行读取: %s" % file_path)
		return {}
	
	var json_string: String = file.get_as_text()
	file.close()
	
	var json: JSON = JSON.new()
	var error: int = json.parse(json_string)
	
	if error != OK:
		push_error("JSON解析错误: %s (行 %d)" % [json.get_error_message(), json.get_error_line()])
		return {}
	
	var data: Variant = json.get_data()
	
	if not data is Dictionary:
		push_error("存档数据格式错误")
		return {}
	
	return data


func _validate_save_version(save_data: Dictionary) -> bool:
	"""
	验证存档版本
	@param save_data: 存档数据
	@return: 版本是否兼容
	"""
	var save_version: int = save_data.get("version", 0)
	return save_version == SAVE_VERSION


func _on_auto_save_timeout() -> void:
	"""
	自动保存计时器回调
	"""
	# 检查游戏状态，只有在游戏中才自动保存
	if GameManager.current_state == GameManager.GameState.PLAYING:
		var current_stats: Dictionary = GameManager.get_game_stats()
		perform_auto_save(current_stats)


func _on_application_pause(pause_status: bool) -> void:
	"""
	应用暂停/恢复时的处理
	@param pause_status: 是否暂停
	"""
	# 当应用进入后台时自动保存
	if pause_status and auto_save_enabled:
		if GameManager.current_state == GameManager.GameState.PLAYING:
			var current_stats: Dictionary = GameManager.get_game_stats()
			perform_auto_save(current_stats)
