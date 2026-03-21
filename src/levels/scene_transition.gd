## scene_transition.gd - 场景切换系统
## 实现平滑的淡入淡出过渡效果
## 支持环境音效渐变、玩家状态保持

class_name SceneTransition
extends CanvasLayer

# ==================== 信号定义 ====================
## 过渡开始信号
signal transition_started(transition_type: int)
## 过渡中间点信号（黑屏/完全遮罩时触发）
signal transition_midpoint()
## 过渡完成信号
signal transition_completed()
## 场景加载完成信号
signal scene_loaded(scene: Node)

# ==================== 枚举定义 ====================
## 过渡类型
enum TransitionType {
	FADE_TO_BLACK,      ## 淡出到黑屏
	FADE_FROM_BLACK,    ## 从黑屏淡入
	FADE_TO_WHITE,      ## 淡出到白屏
	FADE_FROM_WHITE,    ## 从白屏淡入
	CROSS_FADE,         ## 交叉淡入淡出
	SLIDE_LEFT,         ## 向左滑动
	SLIDE_RIGHT,        ## 向右滑动
	ZOOM_IN,            ## 放大过渡
	ZOOM_OUT,           ## 缩小过渡
	PIXELATE,           ## 像素化过渡
	DISSOLVE            ## 溶解过渡
}

## 过渡状态
enum TransitionState {
	IDLE,               ## 空闲
	FADING_OUT,         ## 淡出中
	LOADING,            ## 加载中
	FADING_IN           ## 淡入中
}

# ==================== 常量定义 ====================
## 默认过渡时间（秒）
const DEFAULT_TRANSITION_TIME: float = 1.0
## 最小过渡时间
const MIN_TRANSITION_TIME: float = 0.1
## 最大过渡时间
const MAX_TRANSITION_TIME: float = 3.0

# ==================== 成员变量 ====================
## 遮罩颜色
var _mask_color: Color = Color.BLACK
## 过渡时间
var _transition_time: float = DEFAULT_TRANSITION_TIME
## 当前状态
var _state: TransitionState = TransitionState.IDLE
## 过渡进度 (0-1)
var _progress: float = 0.0
## 目标场景路径
var _target_scene_path: String = ""
## 目标场景实例
var _target_scene: Node = null
## 是否保持玩家状态
var _preserve_player_state: bool = true
## 玩家状态数据
var _player_state_data: Dictionary = {}
## Tween动画器
var _tween: Tween = null
## 遮罩节点
var _color_rect: ColorRect = null
## 环境音效渐变器
var _audio_fader: AudioFader = null
## 纹理遮罩（用于溶解效果）
var _dissolve_texture: Texture2D = null
## 过渡回调
var _midpoint_callback: Callable = Callable()

# ==================== 初始化函数 ====================

## 初始化场景切换系统
func _ready() -> void:
	layer = 100  # 确保在最上层
	_setup_color_rect()
	_setup_audio_fader()


## 设置颜色遮罩
func _setup_color_rect() -> void:
	_color_rect = ColorRect.new()
	_color_rect.color = Color.TRANSPARENT
	_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_color_rect.anchor_right = 1.0
	_color_rect.anchor_bottom = 1.0
	_color_rect.size_flags_horizontal = Control.SIZE_FILL
	_color_rect.size_flags_vertical = Control.SIZE_FILL
	add_child(_color_rect)


## 设置音频渐变器
func _setup_audio_fader() -> void:
	_audio_fader = AudioFader.new()
	add_child(_audio_fader)

# ==================== 公共接口 ====================

## 切换到新场景（带过渡效果）
## @param scene_path: 场景路径
## @param transition_type: 过渡类型
## @param duration: 过渡时间
## @param preserve_player: 是否保持玩家状态
func transition_to_scene(
	scene_path: String,
	transition_type: TransitionType = TransitionType.FADE_TO_BLACK,
	duration: float = DEFAULT_TRANSITION_TIME,
	preserve_player: bool = true
) -> void:
	if _state != TransitionState.IDLE:
		push_warning("Scene transition already in progress")
		return
	
	_target_scene_path = scene_path
	_preserve_player_state = preserve_player
	_transition_time = clamp(duration, MIN_TRANSITION_TIME, MAX_TRANSITION_TIME)
	
	# 保存玩家状态
	if _preserve_player_state:
		_save_player_state()
	
	# 开始淡出
	_start_fade_out(transition_type)


## 切换到新场景实例（带过渡效果）
## @param scene_instance: 场景实例
## @param transition_type: 过渡类型
## @param duration: 过渡时间
func transition_to_scene_instance(
	scene_instance: Node,
	transition_type: TransitionType = TransitionType.FADE_TO_BLACK,
	duration: float = DEFAULT_TRANSITION_TIME
) -> void:
	if _state != TransitionState.IDLE:
		push_warning("Scene transition already in progress")
		return
	
	_target_scene = scene_instance
	_target_scene_path = ""
	_preserve_player_state = true
	_transition_time = clamp(duration, MIN_TRANSITION_TIME, MAX_TRANSITION_TIME)
	
	_save_player_state()
	_start_fade_out(transition_type)


## 执行简单淡出（不切换场景）
## @param transition_type: 过渡类型
## @param duration: 过渡时间
## @param callback: 完成回调
func fade_out(
	transition_type: TransitionType = TransitionType.FADE_TO_BLACK,
	duration: float = DEFAULT_TRANSITION_TIME,
	callback: Callable = Callable()
) -> void:
	if _state != TransitionState.IDLE:
		return
	
	_midpoint_callback = callback
	_transition_time = clamp(duration, MIN_TRANSITION_TIME, MAX_TRANSITION_TIME)
	_start_fade_out(transition_type, false)


## 执行简单淡入
## @param transition_type: 过渡类型
## @param duration: 过渡时间
func fade_in(
	transition_type: TransitionType = TransitionType.FADE_FROM_BLACK,
	duration: float = DEFAULT_TRANSITION_TIME
) -> void:
	if _state != TransitionState.IDLE:
		return
	
	_transition_time = clamp(duration, MIN_TRANSITION_TIME, MAX_TRANSITION_TIME)
	_start_fade_in(transition_type)


## 设置遮罩颜色
func set_mask_color(color: Color) -> void:
	_mask_color = color
	if _color_rect:
		_color_rect.color = color


## 设置溶解纹理
func set_dissolve_texture(texture: Texture2D) -> void:
	_dissolve_texture = texture


## 取消当前过渡
func cancel_transition() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
		_tween = null
	
	_state = TransitionState.IDLE
	_progress = 0.0
	
	if _color_rect:
		_color_rect.color = Color.TRANSPARENT

# ==================== 过渡执行 ====================

## 开始淡出
func _start_fade_out(transition_type: TransitionType, load_scene: bool = true) -> void:
	_state = TransitionState.FADING_OUT
	_progress = 0.0
	transition_started.emit(transition_type)
	
	# 启用鼠标捕获
	_color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# 根据过渡类型执行动画
	match transition_type:
		TransitionType.FADE_TO_BLACK, TransitionType.FADE_TO_WHITE:
			_do_fade_transition(transition_type, true, load_scene)
		
		TransitionType.SLIDE_LEFT, TransitionType.SLIDE_RIGHT:
			_do_slide_transition(transition_type, true, load_scene)
		
		TransitionType.ZOOM_IN:
			_do_zoom_transition(true, load_scene)
		
		TransitionType.DISSOLVE:
			_do_dissolve_transition(true, load_scene)
		
		_:
			_do_fade_transition(TransitionType.FADE_TO_BLACK, true, load_scene)


## 开始淡入
func _start_fade_in(transition_type: TransitionType) -> void:
	_state = TransitionState.FADING_IN
	_progress = 0.0
	
	# 根据过渡类型执行动画
	match transition_type:
		TransitionType.FADE_FROM_BLACK:
			_do_fade_in_animation(Color.BLACK)
		TransitionType.FADE_FROM_WHITE:
			_do_fade_in_animation(Color.WHITE)
		TransitionType.SLIDE_LEFT:
			_do_slide_in_animation(Vector2(-1, 0))
		TransitionType.SLIDE_RIGHT:
			_do_slide_in_animation(Vector2(1, 0))
		TransitionType.ZOOM_OUT:
			_do_zoom_in_animation()
		_:
			_do_fade_in_animation(Color.BLACK)


## 执行淡入淡出过渡
func _do_fade_transition(transition_type: TransitionType, is_out: bool, load_scene: bool) -> void:
	var target_color: Color
	if is_out:
		target_color = Color.BLACK if transition_type == TransitionType.FADE_TO_BLACK else Color.WHITE
		target_color.a = 1.0
	else:
		target_color = Color.TRANSPARENT
	
	if _tween and _tween.is_valid():
		_tween.kill()
	
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.set_trans(Tween.TRANS_SMOOTH)
	
	if is_out:
		_tween.tween_property(_color_rect, "color", target_color, _transition_time / 2)
		_tween.tween_callback(_on_fade_out_complete.bind(load_scene))
	else:
		_tween.tween_property(_color_rect, "color", target_color, _transition_time / 2)
		_tween.tween_callback(_on_fade_in_complete)


## 执行滑动过渡
func _do_slide_transition(transition_type: TransitionType, is_out: bool, load_scene: bool) -> void:
	var direction: Vector2 = Vector2.RIGHT if transition_type == TransitionType.SLIDE_LEFT else Vector2.LEFT
	var screen_size: Vector2 = get_viewport().get_visible_rect().size
	
	if _tween and _tween.is_valid():
		_tween.kill()
	
	# 设置遮罩初始状态
	_color_rect.color = _mask_color
	_color_rect.position = Vector2.ZERO if is_out else direction * screen_size
	
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.set_trans(Tween.TRANS_QUAD)
	
	if is_out:
		_tween.tween_property(_color_rect, "position", direction * screen_size, _transition_time / 2)
		_tween.tween_callback(_on_fade_out_complete.bind(load_scene))
	else:
		_tween.tween_property(_color_rect, "position", Vector2.ZERO, _transition_time / 2)
		_tween.tween_callback(_on_fade_in_complete)


## 执行缩放过渡
func _do_zoom_transition(is_out: bool, load_scene: bool) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	
	_color_rect.color = Color.BLACK
	
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.set_trans(Tween.TRANS_SMOOTH)
	
	if is_out:
		_tween.tween_property(_color_rect, "color:a", 1.0, _transition_time / 2)
		_tween.tween_callback(_on_fade_out_complete.bind(load_scene))
	else:
		_tween.tween_property(_color_rect, "color:a", 0.0, _transition_time / 2)
		_tween.tween_callback(_on_fade_in_complete)


## 执行溶解过渡
func _do_dissolve_transition(is_out: bool, load_scene: bool) -> void:
	# 简化的溶解效果：使用透明度变化
	if _tween and _tween.is_valid():
		_tween.kill()
	
	_color_rect.color = Color.BLACK
	
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.set_trans(Tween.TRANS_SMOOTH)
	
	if is_out:
		_tween.tween_property(_color_rect, "color:a", 1.0, _transition_time / 2)
		_tween.tween_callback(_on_fade_out_complete.bind(load_scene))
	else:
		_tween.tween_property(_color_rect, "color:a", 0.0, _transition_time / 2)
		_tween.tween_callback(_on_fade_in_complete)


## 执行淡入动画
func _do_fade_in_animation(from_color: Color) -> void:
	_color_rect.color = from_color
	
	if _tween and _tween.is_valid():
		_tween.kill()
	
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.set_trans(Tween.TRANS_SMOOTH)
	_tween.tween_property(_color_rect, "color", Color.TRANSPARENT, _transition_time / 2)
	_tween.tween_callback(_on_fade_in_complete)


## 执行滑入动画
func _do_slide_in_animation(direction: Vector2) -> void:
	var screen_size: Vector2 = get_viewport().get_visible_rect().size
	_color_rect.color = _mask_color
	_color_rect.position = Vector2.ZERO
	
	if _tween and _tween.is_valid():
		_tween.kill()
	
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.set_trans(Tween.TRANS_QUAD)
	_tween.tween_property(_color_rect, "position", -direction * screen_size, _transition_time / 2)
	_tween.tween_callback(_on_fade_in_complete)


## 执行缩放淡入动画
func _do_zoom_in_animation() -> void:
	_color_rect.color = Color.BLACK
	
	if _tween and _tween.is_valid():
		_tween.kill()
	
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.set_trans(Tween.TRANS_SMOOTH)
	_tween.tween_property(_color_rect, "color:a", 0.0, _transition_time / 2)
	_tween.tween_callback(_on_fade_in_complete)

# ==================== 回调函数 ====================

## 淡出完成回调
func _on_fade_out_complete(load_scene: bool) -> void:
	transition_midpoint.emit()
	
	# 执行回调
	if _midpoint_callback.is_valid():
		_midpoint_callback.call()
		_midpoint_callback = Callable()
	
	if load_scene:
		_state = TransitionState.LOADING
		_load_target_scene()
	else:
		# 直接开始淡入
		_start_fade_in(TransitionType.FADE_FROM_BLACK)


## 加载目标场景
func _load_target_scene() -> void:
	# 淡出环境音效
	_audio_fader.fade_out_all(_transition_time / 4)
	
	if _target_scene:
		# 使用预加载的场景实例
		_replace_scene(_target_scene)
		_target_scene = null
	elif _target_scene_path != "":
		# 从路径加载场景
		var resource_loader: ResourceLoader = ResourceLoader.load_threaded(_target_scene_path)
		
		# 等待加载完成
		while ResourceLoader.load_threaded_get_status(_target_scene_path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			await get_tree().process_frame
		
		var packed_scene: PackedScene = ResourceLoader.load_threaded_get(_target_scene_path)
		if packed_scene:
			_replace_scene(packed_scene.instantiate())
		else:
			push_error("Failed to load scene: " + _target_scene_path)
			cancel_transition()
			return
	else:
		push_warning("No target scene specified")
		cancel_transition()
		return
	
	# 恢复玩家状态
	if _preserve_player_state:
		_restore_player_state()
	
	# 加载完成，开始淡入
	scene_loaded.emit(get_tree().current_scene)
	_start_fade_in(TransitionType.FADE_FROM_BLACK)


## 替换当前场景
func _replace_scene(new_scene: Node) -> void:
	var tree: SceneTree = get_tree()
	var current_scene: Node = tree.current_scene
	
	# 移除当前场景
	if current_scene:
		current_scene.get_parent().remove_child(current_scene)
		current_scene.queue_free()
	
	# 添加新场景
	tree.root.add_child(new_scene)
	tree.current_scene = new_scene


## 淡入完成回调
func _on_fade_in_complete() -> void:
	_state = TransitionState.IDLE
	_progress = 1.0
	_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_color_rect.color = Color.TRANSPARENT
	
	transition_completed.emit()

# ==================== 玩家状态管理 ====================

## 保存玩家状态
func _save_player_state() -> void:
	var player: Node = _find_player_node()
	if not player:
		return
	
	_player_state_data = {
		"position": player.get("global_position") if player.has_method("get") else Vector2.ZERO,
		"health": player.get("health") if "health" in player else 100,
		"max_health": player.get("max_health") if "max_health" in player else 100,
		"inventory": player.get("inventory") if "inventory" in player else [],
		"skills": player.get("skills") if "skills" in player else [],
		"gold": player.get("gold") if "gold" in player else 0,
		"experience": player.get("experience") if "experience" in player else 0
	}


## 恢复玩家状态
func _restore_player_state() -> void:
	if _player_state_data.is_empty():
		return
	
	var player: Node = _find_player_node()
	if not player:
		return
	
	# 恢复状态
	if "global_position" in player and _player_state_data.has("position"):
		player.set("global_position", _player_state_data.position)
	
	if "health" in player and _player_state_data.has("health"):
		player.set("health", _player_state_data.health)
	
	if "max_health" in player and _player_state_data.has("max_health"):
		player.set("max_health", _player_state_data.max_health)
	
	if "inventory" in player and _player_state_data.has("inventory"):
		player.set("inventory", _player_state_data.inventory)
	
	if "skills" in player and _player_state_data.has("skills"):
		player.set("skills", _player_state_data.skills)
	
	if "gold" in player and _player_state_data.has("gold"):
		player.set("gold", _player_state_data.gold)
	
	if "experience" in player and _player_state_data.has("experience"):
		player.set("experience", _player_state_data.experience)


## 查找玩家节点
func _find_player_node() -> Node:
	var tree: SceneTree = get_tree()
	if not tree or not tree.current_scene:
		return null
	
	# 尝试多种方式查找玩家
	var player_groups: Array = tree.get_nodes_in_group("player")
	if player_groups.size() > 0:
		return player_groups[0]
	
	# 尝试从场景树查找
	return _recursive_find_player(tree.current_scene)


## 递归查找玩家节点
func _recursive_find_player(node: Node) -> Node:
	if node.is_in_group("player"):
		return node
	
	for child in node.get_children():
		var result: Node = _recursive_find_player(child)
		if result:
			return result
	
	return null

# ==================== 环境音效渐变 ====================

## AudioFader 内部类 - 处理音效渐变
class AudioFader extends Node:
	## 音频播放器列表
	var _audio_players: Array[AudioStreamPlayer] = []
	## 原始音量记录
	var _original_volumes: Dictionary = {}
	
	## 淡出所有音频
	func fade_out_all(duration: float) -> void:
		for player in _audio_players:
			if player and is_instance_valid(player):
				_fade_audio(player, 0.0, duration)
	
	## 淡入所有音频
	func fade_in_all(duration: float) -> void:
		for player in _audio_players:
			if player and is_instance_valid(player):
				var target_volume: float = _original_volumes.get(player, 0.0)
				_fade_audio(player, target_volume, duration)
	
	## 添加音频播放器
	func add_audio_player(player: AudioStreamPlayer) -> void:
		if player and not _audio_players.has(player):
			_audio_players.append(player)
			_original_volumes[player] = player.volume_db
	
	## 移除音频播放器
	func remove_audio_player(player: AudioStreamPlayer) -> void:
		_audio_players.erase(player)
		_original_volumes.erase(player)
	
	## 执行音频淡入淡出
	func _fade_audio(player: AudioStreamPlayer, target_volume: float, duration: float) -> void:
		var tween: Tween = create_tween()
		tween.tween_property(player, "volume_db", target_volume, duration)

# ==================== 获取器函数 ====================

## 获取当前状态
func get_state() -> TransitionState:
	return _state


## 获取过渡进度
func get_progress() -> float:
	return _progress


## 是否正在过渡
func is_transitioning() -> bool:
	return _state != TransitionState.IDLE


## 获取保存的玩家状态
func get_saved_player_state() -> Dictionary:
	return _player_state_data.duplicate()


## 清除保存的玩家状态
func clear_saved_player_state() -> void:
	_player_state_data.clear()
