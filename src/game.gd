extends Node

const VERSION := "1.0.0"
const GAME_NAME := "Void Hunter: Endless Journey"

enum GameState { LOADING, MAIN_MENU, CHARACTER_SELECT, PLAYING, PAUSED, GAME_OVER }

var current_state: GameState = GameState.LOADING
var previous_state: GameState = GameState.LOADING

signal state_changed(new_state: GameState)
signal game_started()
signal game_paused()
signal game_resumed()
signal game_over(stats: Dictionary)

@onready var _main_menu: Control = $CanvasLayer/MainMenu
@onready var _game_world: Node2D = $GameWorld
@onready var _hud: Control = $HUD
@onready var _pause_menu: Control = $PauseMenu
@onready var _entities: Node2D = $GameWorld/Entities
@onready var _level_container: Node2D = $GameWorld/LevelGenerator

var _player: Node2D = null
var _current_level: Node = null
var _is_initialized: bool = false

func _ready() -> void:
	_setup_input_actions()
	await _initialize_systems()
	_change_state(GameState.MAIN_MENU)
	_is_initialized = true
	print("[Game] %s v%s 初始化完成" % [GAME_NAME, VERSION])

func _setup_input_actions() -> void:
	var actions := {
		"ui_up": [KEY_W, KEY_UP],
		"ui_down": [KEY_S, KEY_DOWN],
		"ui_left": [KEY_A, KEY_LEFT],
		"ui_right": [KEY_D, KEY_RIGHT],
		"attack": [MOUSE_BUTTON_LEFT, KEY_SPACE],
		"dash": [KEY_SHIFT],
		"skill_1": [KEY_1, KEY_Q],
		"skill_2": [KEY_2, KEY_E],
		"skill_3": [KEY_3, KEY_R],
		"skill_4": [KEY_4],
		"item_1": [KEY_Z],
		"item_2": [KEY_X],
		"item_3": [KEY_C],
		"inventory": [KEY_I, KEY_TAB],
		"pause": [KEY_ESCAPE],
		"toggle_auto_fire": [KEY_T],
	}
	
	for action_name: String in actions:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
			for key in actions[action_name]:
				var event: InputEvent
				if key is int:
					if key >= KEY_A and key <= KEY_Z or key in [KEY_SPACE, KEY_SHIFT, KEY_TAB, KEY_ESCAPE]:
						event = InputEventKey.new()
						event.keycode = key
					elif key >= MOUSE_BUTTON_LEFT and key <= MOUSE_BUTTON_RIGHT:
						event = InputEventMouseButton.new()
						event.button_index = key
					if event:
						InputMap.action_add_event(action_name, event)

func _initialize_systems() -> void:
	await get_tree().process_frame
	
	if GameManager:
		GameManager.set_game_reference(self)
	
	if ObjectPool:
		ObjectPool.warm_up_pools()
	
	if InputManager:
		InputManager.input_device_changed.connect(_on_input_device_changed)
	
	if RenderOptimizer:
		RenderOptimizer.set_target_fps(60)
	
	if MemoryManager:
		MemoryManager.low_memory_warning.connect(_on_low_memory)
	
	await get_tree().create_timer(0.1).timeout

func _change_state(new_state: GameState) -> void:
	if current_state == new_state:
		return
	
	previous_state = current_state
	current_state = new_state
	
	match new_state:
		GameState.MAIN_MENU:
			_show_main_menu()
		GameState.CHARACTER_SELECT:
			_show_character_select()
		GameState.PLAYING:
			_start_gameplay()
		GameState.PAUSED:
			_pause_gameplay()
		GameState.GAME_OVER:
			_show_game_over()
		GameState.LOADING:
			pass
	
	state_changed.emit(new_state)
	print("[Game] 状态切换: %s -> %s" % [GameState.keys()[previous_state], GameState.keys()[new_state]])

func _show_main_menu() -> void:
	get_tree().paused = false
	_main_menu.visible = true
	_game_world.visible = false
	_hud.visible = false
	_pause_menu.visible = false
	
	if _player:
		_player.queue_free()
		_player = null
	
	if _current_level:
		_current_level.queue_free()
		_current_level = null
	
	if _entities:
		for child in _entities.get_children():
			child.queue_free()

func _show_character_select() -> void:
	_main_menu.visible = false
	if GameManager:
		GameManager.start_character_selection()

func _start_gameplay() -> void:
	get_tree().paused = false
	_main_menu.visible = false
	_game_world.visible = true
	_hud.visible = true
	_pause_menu.visible = false
	
	if not _player:
		_spawn_player()
	
	if not _current_level:
		_generate_level()
	
	game_started.emit()

func _pause_gameplay() -> void:
	get_tree().paused = true
	_pause_menu.visible = true
	game_paused.emit()

func _show_game_over() -> void:
	get_tree().paused = true
	var stats := _collect_game_stats()
	game_over.emit(stats)

func _spawn_player() -> void:
	var player_scene := preload("res://scenes/player.tscn")
	if player_scene:
		_player = player_scene.instantiate()
		var spawn_pos: Vector2 = Vector2(576, 320)
		if $GameWorld/PlayerSpawn:
			spawn_pos = $GameWorld/PlayerSpawn.position
		_player.position = spawn_pos
		_entities.add_child(_player)
		print("[Game] 玩家生成完成")

func _generate_level() -> void:
	if LevelManager:
		LevelManager.start_new_game()
		_current_level = LevelManager.get_current_level_node()
		if _current_level and _level_container:
			_level_container.add_child(_current_level)
	print("[Game] 关卡生成完成")

func _collect_game_stats() -> Dictionary:
	var stats := {
		"survival_time": 0.0,
		"waves_reached": 1,
		"kills": 0,
		"damage_dealt": 0,
		"items_collected": 0,
		"skills_unlocked": 0,
	}
	
	if GameManager:
		stats.waves_reached = GameManager.current_wave
		stats.kills = GameManager.total_kills
	
	return stats

func _on_input_device_changed(device_type: int) -> void:
	var device_name := ["PC", "Mobile", "Gamepad"][device_type] if device_type < 3 else "Unknown"
	print("[Game] 输入设备切换: %s" % device_name)

func _on_low_memory() -> void:
	print("[Game] 收到低内存警告，执行清理...")
	if MemoryManager:
		MemoryManager.force_cleanup()

func _on_main_menu_new_game() -> void:
	_change_state(GameState.CHARACTER_SELECT)

func _on_main_menu_continue() -> void:
	if SaveManager and SaveManager.has_save():
		SaveManager.load_game()
		_change_state(GameState.PLAYING)
	else:
		print("[Game] 没有存档")

func _on_main_menu_settings() -> void:
	pass

func _on_main_menu_quit() -> void:
	get_tree().quit()

func _on_character_selected(character_id: String) -> void:
	if GameManager:
		GameManager.select_character_and_start(character_id)
	_change_state(GameState.PLAYING)

func _on_pause_resume() -> void:
	_change_state(GameState.PLAYING)

func _on_pause_settings() -> void:
	pass

func _on_pause_main_menu() -> void:
	_change_state(GameState.MAIN_MENU)

func _on_game_over_restart() -> void:
	_change_state(GameState.CHARACTER_SELECT)

func _on_game_over_main_menu() -> void:
	_change_state(GameState.MAIN_MENU)

func _input(event: InputEvent) -> void:
	if not _is_initialized:
		return
	
	if event.is_action_pressed("pause"):
		if current_state == GameState.PLAYING:
			_change_state(GameState.PAUSED)
		elif current_state == GameState.PAUSED:
			_change_state(GameState.PLAYING)
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST:
			if current_state == GameState.PLAYING:
				_change_state(GameState.PAUSED)
			elif current_state == GameState.PAUSED:
				_change_state(GameState.MAIN_MENU)
		NOTIFICATION_WM_CLOSE_REQUEST:
			if SaveManager and current_state == GameState.PLAYING:
				SaveManager.auto_save()

func start_new_game() -> void:
	_change_state(GameState.CHARACTER_SELECT)

func continue_game() -> void:
	_change_state(GameState.PLAYING)

func pause_game() -> void:
	if current_state == GameState.PLAYING:
		_change_state(GameState.PAUSED)

func resume_game() -> void:
	if current_state == GameState.PAUSED:
		_change_state(GameState.PLAYING)

func end_game() -> void:
	_change_state(GameState.GAME_OVER)

func get_current_state() -> GameState:
	return current_state

func is_playing() -> bool:
	return current_state == GameState.PLAYING

func is_paused() -> bool:
	return current_state == GameState.PAUSED

func get_player() -> Node2D:
	return _player

func get_entities_node() -> Node2D:
	return _entities

func get_level_container() -> Node2D:
	return _level_container
