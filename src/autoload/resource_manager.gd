## Void Hunter - 资源管理器
## @description: 处理场景异步加载、资源预加载、加载进度显示和后台资源加载
## @author: Void Hunter Team
## @version: 1.0.0

extends Node

# =============================================================================
# 信号定义
# =============================================================================

## 场景加载开始时触发
signal scene_load_started(scene_path: String)

## 场景加载进度更新时触发
signal scene_load_progress(scene_path: String, progress: float)

## 场景加载完成时触发
signal scene_load_completed(scene_path: String, scene: PackedScene)

## 场景加载失败时触发
signal scene_load_failed(scene_path: String, error: int)

## 场景切换完成时触发
signal scene_change_completed(scene_path: String)

## 资源预加载完成时触发
signal preload_completed(resource_path: String, resource: Resource)

## 资源预加载失败时触发
signal preload_failed(resource_path: String, error: int)

## 所有预加载完成时触发
signal all_preloads_completed()

## 后台加载任务完成时触发
signal background_task_completed(task_id: String, success: bool)

# =============================================================================
# 枚举定义
# =============================================================================

## 加载状态
enum LoadState {
	IDLE,			## 空闲
	LOADING,		## 正在加载
	CHANGING,		## 正在切换场景
	ERROR			## 加载错误
}

## 加载优先级
enum LoadPriority {
	LOW,			## 低优先级
	NORMAL,			## 正常优先级
	HIGH,			## 高优先级
	CRITICAL		## 关键优先级
}

## 后台任务状态
enum BackgroundTaskState {
	PENDING,		## 等待中
	RUNNING,		## 运行中
	COMPLETED,		## 已完成
	FAILED,			## 已失败
	CANCELLED		## 已取消
}

# =============================================================================
# 常量定义
# =============================================================================

## 场景路径前缀
const SCENE_PATH_PREFIX: String = "res://scenes/"

## 资源路径前缀
const RESOURCE_PATH_PREFIX: String = "res://resources/"

## 默认加载超时（秒）
const DEFAULT_LOAD_TIMEOUT: float = 30.0

## 后台加载帧预算（毫秒）
const BACKGROUND_FRAME_BUDGET_MS: float = 2.0

## 最大并行后台任务
const MAX_PARALLEL_BACKGROUND_TASKS: int = 3

## 预加载场景配置
const PRELOAD_SCENES: Array[Dictionary] = [
	{"path": "res://scenes/main_menu.tscn", "priority": LoadPriority.HIGH},
	{"path": "res://scenes/game.tscn", "priority": LoadPriority.HIGH},
	{"path": "res://scenes/pause_menu.tscn", "priority": LoadPriority.NORMAL}
]

## 预加载资源配置
const PRELOAD_RESOURCES: Array[Dictionary] = [
	{"path": "res://resources/game_data.tres", "priority": LoadPriority.HIGH},
	{"path": "res://resources/player_data.tres", "priority": LoadPriority.NORMAL}
]

# =============================================================================
# 导出变量
# =============================================================================

## 是否启用后台加载
@export var enable_background_loading: bool = true

## 是否启用预加载
@export var enable_preloading: bool = true

## 加载场景时显示加载界面
@export var show_loading_screen: bool = true

## 加载界面场景路径
@export var loading_screen_scene: PackedScene = null

## 是否缓存已加载的场景
@export var cache_loaded_scenes: bool = true

## 最大场景缓存数
@export var max_scene_cache: int = 5

## 场景切换过渡时间（秒）
@export var scene_transition_time: float = 0.5

# =============================================================================
# 公共变量
# =============================================================================

## 当前加载状态
var current_state: LoadState = LoadState.IDLE

## 当前加载进度（0.0-1.0）
var current_progress: float = 0.0

## 当前正在加载的场景路径
var current_loading_scene: String = ""

## 已缓存的场景
var cached_scenes: Dictionary = {}

## 已缓存的资源
var cached_resources: Dictionary = {}

## 预加载进度
var preload_progress: float = 0.0

# =============================================================================
# 私有变量
# =============================================================================

var _is_initialized: bool = false
var _scene_loader: ResourceLoader = null
var _load_start_time: float = 0.0
var _background_tasks: Dictionary = {}
var _background_queue: Array[Dictionary] = []
var _preload_queue: Array[Dictionary] = []
var _active_background_tasks: int = 0
var _loading_screen_node: Node = null
var _scene_tree: SceneTree = null

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""
	节点就绪时初始化
	"""
	_initialize_resource_manager()


func _process(delta: float) -> void:
	"""
	每帧更新
	"""
	# 处理后台加载队列
	if enable_background_loading:
		_process_background_queue()

# =============================================================================
# 公共方法 - 初始化
# =============================================================================

## 初始化资源管理器
func initialize() -> void:
	"""
	手动初始化资源管理器
	"""
	_initialize_resource_manager()


## 执行预加载
func do_preload() -> void:
	"""
	执行预加载（通常在游戏启动时调用）
	"""
	if not enable_preloading:
		return
	
	_start_preloading()

# =============================================================================
# 公共方法 - 场景加载
# =============================================================================

## 同步加载场景
func load_scene_sync(scene_path: String) -> PackedScene:
	"""
	同步加载场景
	@param scene_path: 场景路径
	@return: 场景资源
	"""
	# 检查缓存
	if cached_scenes.has(scene_path):
		return cached_scenes[scene_path]
	
	# 验证路径
	if not ResourceLoader.exists(scene_path):
		push_error("场景不存在: %s" % scene_path)
		return null
	
	# 同步加载
	var scene: PackedScene = load(scene_path)
	
	if scene and cache_loaded_scenes:
		_cache_scene(scene_path, scene)
	
	return scene


## 异步加载场景
func load_scene_async(scene_path: String, priority: LoadPriority = LoadPriority.NORMAL) -> void:
	"""
	异步加载场景
	@param scene_path: 场景路径
	@param priority: 加载优先级
	"""
	if current_state == LoadState.LOADING:
		push_warning("已有场景正在加载")
		return
	
	# 检查缓存
	if cached_scenes.has(scene_path):
		scene_load_completed.emit(scene_path, cached_scenes[scene_path])
		return
	
	# 验证路径
	if not ResourceLoader.exists(scene_path):
		push_error("场景不存在: %s" % scene_path)
		scene_load_failed.emit(scene_path, ERR_FILE_NOT_FOUND)
		return
	
	current_state = LoadState.LOADING
	current_loading_scene = scene_path
	current_progress = 0.0
	_load_start_time = Time.get_unix_time_from_system()
	
	scene_load_started.emit(scene_path)
	
	# 开始后台加载
	var error: int = ResourceLoader.load_threaded_request(scene_path, "", false)
	
	if error != OK:
		current_state = LoadState.ERROR
		scene_load_failed.emit(scene_path, error)
		return
	
	# 开始轮询加载状态
	_poll_scene_loading(scene_path)


## 切换到场景
func change_to_scene(scene_path: String, show_loading: bool = true) -> void:
	"""
	切换到指定场景
	@param scene_path: 场景路径
	@param show_loading: 是否显示加载界面
	"""
	if current_state == LoadState.LOADING:
		push_warning("已有场景正在加载")
		return
	
	show_loading_screen = show_loading
	
	# 检查缓存
	if cached_scenes.has(scene_path):
		_do_scene_change(scene_path, cached_scenes[scene_path])
		return
	
	# 异步加载
	load_scene_async(scene_path)


## 重新加载当前场景
func reload_current_scene() -> void:
	"""
	重新加载当前场景
	"""
	var current_scene_path: String = _scene_tree.current_scene.scene_file_path
	change_to_scene(current_scene_path, false)

# =============================================================================
# 公共方法 - 资源加载
# =============================================================================

## 同步加载资源
func load_resource_sync(resource_path: String) -> Resource:
	"""
	同步加载资源
	@param resource_path: 资源路径
	@return: 资源
	"""
	# 检查缓存
	if cached_resources.has(resource_path):
		return cached_resources[resource_path]
	
	# 验证路径
	if not ResourceLoader.exists(resource_path):
		push_error("资源不存在: %s" % resource_path)
		return null
	
	# 加载
	var resource: Resource = load(resource_path)
	
	if resource:
		cached_resources[resource_path] = resource
	
	return resource


## 异步加载资源
func load_resource_async(resource_path: String, priority: LoadPriority = LoadPriority.NORMAL, 
		callback: Callable = Callable()) -> String:
	"""
	异步加载资源
	@param resource_path: 资源路径
	@param priority: 加载优先级
	@param callback: 加载完成回调
	@return: 任务ID
	"""
	return queue_background_task(resource_path, 
		func(task_id: String, path: String):
			var resource: Resource = load_resource_sync(path)
			if callback.is_valid():
				callback.call(resource)
			return resource != null
	)

# =============================================================================
# 公共方法 - 后台加载
# =============================================================================

## 添加后台加载任务
func queue_background_task(resource_path: String, task_func: Callable, 
		priority: LoadPriority = LoadPriority.NORMAL) -> String:
	"""
	添加后台加载任务
	@param resource_path: 资源路径
	@param task_func: 任务函数
	@param priority: 优先级
	@return: 任务ID
	"""
	var task_id: String = _generate_task_id()
	
	_background_queue.append({
		"id": task_id,
		"resource_path": resource_path,
		"func": task_func,
		"priority": priority,
		"state": BackgroundTaskState.PENDING,
		"start_time": 0.0
	})
	
	# 按优先级排序
	_background_queue.sort_custom(func(a, b): return a["priority"] > b["priority"])
	
	return task_id


## 取消后台任务
func cancel_background_task(task_id: String) -> bool:
	"""
	取消后台任务
	@param task_id: 任务ID
	@return: 是否成功
	"""
	# 检查队列中的任务
	for i in range(_background_queue.size()):
		if _background_queue[i]["id"] == task_id:
			_background_queue.remove_at(i)
			return true
	
	# 检查运行中的任务
	if _background_tasks.has(task_id):
		_background_tasks[task_id]["state"] = BackgroundTaskState.CANCELLED
		return true
	
	return false


## 获取后台任务状态
func get_background_task_state(task_id: String) -> BackgroundTaskState:
	"""
	获取后台任务状态
	@param task_id: 任务ID
	@return: 任务状态
	"""
	if _background_tasks.has(task_id):
		return _background_tasks[task_id]["state"]
	
	for task in _background_queue:
		if task["id"] == task_id:
			return task["state"]
	
	return BackgroundTaskState.CANCELLED

# =============================================================================
# 公共方法 - 缓存管理
# =============================================================================

## 清除场景缓存
func clear_scene_cache() -> void:
	"""
	清除所有场景缓存
	"""
	cached_scenes.clear()


## 清除资源缓存
func clear_resource_cache() -> void:
	"""
	清除所有资源缓存
	"""
	cached_resources.clear()


## 清除未使用的缓存
func clear_unused_cache() -> void:
	"""
	清除未使用的缓存
	"""
	# 清理超出限制的场景缓存
	while cached_scenes.size() > max_scene_cache:
		var oldest_key: String = cached_scenes.keys()[0]
		cached_scenes.erase(oldest_key)


## 预热缓存
func warm_up_cache(scene_paths: Array[String]) -> void:
	"""
	预热缓存，提前加载指定场景
	@param scene_paths: 场景路径数组
	"""
	for path in scene_paths:
		if not cached_scenes.has(path):
			queue_background_task(path, 
				func(task_id: String, p: String):
					var scene: PackedScene = load_scene_sync(p)
					return scene != null
			)

# =============================================================================
# 公共方法 - 进度获取
# =============================================================================

## 获取当前加载进度
func get_load_progress() -> float:
	"""
	获取当前加载进度
	@return: 进度（0.0-1.0）
	"""
	return current_progress


## 获取预加载进度
func get_preload_progress() -> float:
	"""
	获取预加载进度
	@return: 进度（0.0-1.0）
	"""
	return preload_progress


## 是否正在加载
func is_loading() -> bool:
	"""
	检查是否正在加载
	@return: 是否正在加载
	"""
	return current_state == LoadState.LOADING

# =============================================================================
# 私有方法 - 初始化
# =============================================================================

func _initialize_resource_manager() -> void:
	"""
	初始化资源管理器
	"""
	if _is_initialized:
		return
	
	_is_initialized = true
	_scene_tree = get_tree()
	
	print("[ResourceManager] 初始化完成")

# =============================================================================
# 私有方法 - 场景加载
# =============================================================================

func _poll_scene_loading(scene_path: String) -> void:
	"""
	轮询场景加载状态
	@param scene_path: 场景路径
	"""
	var status: Array = [ResourceLoader.THREAD_LOAD_IN_PROGRESS]
	
	while status[0] == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		# 检查超时
		if Time.get_unix_time_from_system() - _load_start_time > DEFAULT_LOAD_TIMEOUT:
			current_state = LoadState.ERROR
			ResourceLoader.load_threaded_abort(scene_path)
			scene_load_failed.emit(scene_path, ERR_TIMEOUT)
			return
		
		# 获取加载状态
		status = ResourceLoader.load_threaded_get_status(scene_path)
		
		# 更新进度
		if status.size() > 1:
			current_progress = status[1]
			scene_load_progress.emit(scene_path, current_progress)
		
		# 等待一帧
		await get_tree().process_frame
	
	# 检查加载结果
	if status[0] == ResourceLoader.THREAD_LOAD_LOADED:
		var scene: PackedScene = ResourceLoader.load_threaded_get(scene_path)
		
		if scene:
			current_state = LoadState.IDLE
			current_progress = 1.0
			
			if cache_loaded_scenes:
				_cache_scene(scene_path, scene)
			
			scene_load_completed.emit(scene_path, scene)
			
			# 如果是场景切换，执行切换
			if show_loading_screen or scene_path == current_loading_scene:
				_do_scene_change(scene_path, scene)
		else:
			current_state = LoadState.ERROR
			scene_load_failed.emit(scene_path, ERR_PARSE_ERROR)
	else:
		current_state = LoadState.ERROR
		scene_load_failed.emit(scene_path, ERR_CANT_RESOLVE)


func _do_scene_change(scene_path: String, scene: PackedScene) -> void:
	"""
	执行场景切换
	@param scene_path: 场景路径
	@param scene: 场景资源
	"""
	current_state = LoadState.CHANGING
	
	# 显示加载界面
	if show_loading_screen and loading_screen_scene:
		_show_loading_screen()
	
	# 等待过渡时间
	if scene_transition_time > 0:
		await get_tree().create_timer(scene_transition_time).timeout
	
	# 切换场景
	var error: int = _scene_tree.change_scene_to_packed(scene)
	
	if error != OK:
		push_error("场景切换失败: %s, 错误码: %d" % [scene_path, error])
		current_state = LoadState.ERROR
		return
	
	# 隐藏加载界面
	_hide_loading_screen()
	
	current_state = LoadState.IDLE
	current_loading_scene = ""
	current_progress = 0.0
	
	scene_change_completed.emit(scene_path)

# =============================================================================
# 私有方法 - 预加载
# =============================================================================

func _start_preloading() -> void:
	"""
	开始预加载
	"""
	var total_tasks: int = PRELOAD_SCENES.size() + PRELOAD_RESOURCES.size()
	var completed_tasks: int = 0
	
	preload_progress = 0.0
	
	# 预加载场景
	for scene_info in PRELOAD_SCENES:
		var path: String = scene_info["path"]
		
		if ResourceLoader.exists(path):
			var scene: PackedScene = load_scene_sync(path)
			if scene:
				completed_tasks += 1
				preload_progress = float(completed_tasks) / float(total_tasks)
				preload_completed.emit(path, scene)
		else:
			preload_failed.emit(path, ERR_FILE_NOT_FOUND)
	
	# 预加载资源
	for resource_info in PRELOAD_RESOURCES:
		var path: String = resource_info["path"]
		
		if ResourceLoader.exists(path):
			var resource: Resource = load_resource_sync(path)
			if resource:
				completed_tasks += 1
				preload_progress = float(completed_tasks) / float(total_tasks)
				preload_completed.emit(path, resource)
		else:
			preload_failed.emit(path, ERR_FILE_NOT_FOUND)
	
	preload_progress = 1.0
	all_preloads_completed.emit()
	
	print("[ResourceManager] 预加载完成: %d/%d" % [completed_tasks, total_tasks])

# =============================================================================
# 私有方法 - 后台加载队列
# =============================================================================

func _process_background_queue() -> void:
	"""
	处理后台加载队列
	"""
	# 检查是否有空闲的加载槽
	if _active_background_tasks >= MAX_PARALLEL_BACKGROUND_TASKS:
		return
	
	# 检查队列是否为空
	if _background_queue.is_empty():
		return
	
	# 获取下一个任务
	var task: Dictionary = _background_queue.pop_front()
	
	# 启动任务
	_start_background_task(task)


func _start_background_task(task: Dictionary) -> void:
	"""
	启动后台任务
	@param task: 任务信息
	"""
	task["state"] = BackgroundTaskState.RUNNING
	task["start_time"] = Time.get_unix_time_from_system()
	
	_background_tasks[task["id"]] = task
	_active_background_tasks += 1
	
	# 执行任务
	_execute_background_task(task)


func _execute_background_task(task: Dictionary) -> void:
	"""
	执行后台任务
	@param task: 任务信息
	"""
	var task_func: Callable = task["func"]
	var task_id: String = task["id"]
	var resource_path: String = task["resource_path"]
	
	# 执行任务函数
	var success: bool = false
	
	if task_func.is_valid():
		success = task_func.call(task_id, resource_path)
	
	# 更新任务状态
	if _background_tasks.has(task_id):
		if _background_tasks[task_id]["state"] == BackgroundTaskState.CANCELLED:
			_background_tasks.erase(task_id)
			_active_background_tasks -= 1
			return
		
		_background_tasks[task_id]["state"] = BackgroundTaskState.COMPLETED if success else BackgroundTaskState.FAILED
		_active_background_tasks -= 1
		
		background_task_completed.emit(task_id, success)

# =============================================================================
# 私有方法 - 辅助函数
# =============================================================================

func _cache_scene(scene_path: String, scene: PackedScene) -> void:
	"""
	缓存场景
	@param scene_path: 场景路径
	@param scene: 场景资源
	"""
	# 检查缓存大小
	if cached_scenes.size() >= max_scene_cache:
		# 移除最旧的缓存
		var oldest_key: String = cached_scenes.keys()[0]
		cached_scenes.erase(oldest_key)
	
	cached_scenes[scene_path] = scene


func _generate_task_id() -> String:
	"""
	生成任务ID
	@return: 任务ID
	"""
	return "task_%d_%d" % [Time.get_ticks_msec(), randi() % 10000]


func _show_loading_screen() -> void:
	"""
	显示加载界面
	"""
	if loading_screen_scene == null:
		return
	
	_loading_screen_node = loading_screen_scene.instantiate()
	
	if _loading_screen_node:
		get_tree().root.add_child(_loading_screen_node)


func _hide_loading_screen() -> void:
	"""
	隐藏加载界面
	"""
	if _loading_screen_node and is_instance_valid(_loading_screen_node):
		_loading_screen_node.queue_free()
		_loading_screen_node = null

# =============================================================================
# 调试方法
# =============================================================================

## 获取调试信息
func get_debug_info() -> Dictionary:
	"""
	获取调试信息
	@return: 调试信息字典
	"""
	return {
		"current_state": LoadState.keys()[current_state],
		"current_progress": current_progress,
		"current_loading_scene": current_loading_scene,
		"cached_scenes_count": cached_scenes.size(),
		"cached_resources_count": cached_resources.size(),
		"background_queue_size": _background_queue.size(),
		"active_background_tasks": _active_background_tasks,
		"preload_progress": preload_progress
	}


## 获取缓存统计
func get_cache_statistics() -> Dictionary:
	"""
	获取缓存统计
	@return: 缓存统计字典
	"""
	var total_scene_size: int = 0
	var total_resource_size: int = 0
	
	for path in cached_scenes.keys():
		var scene: PackedScene = cached_scenes[path]
		if scene:
			total_scene_size += 1  # 无法获取实际大小
	
	return {
		"cached_scenes": cached_scenes.size(),
		"cached_resources": cached_resources.size(),
		"max_scene_cache": max_scene_cache,
		"background_queue_length": _background_queue.size()
	}
