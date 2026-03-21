## Void Hunter - 调试工具
## @description: 提供调试功能，包括无敌模式、经验调整等
## @author: Void Hunter Team
## @version: 1.0.0

extends CanvasLayer
class_name DebugTools

# =============================================================================
# 信号定义
# =============================================================================

## 调试命令执行时触发
signal debug_command_executed(command: String, result: String)

## 调试模式切换时触发
signal debug_mode_toggled(enabled: bool)

# =============================================================================
# 常量定义
# =============================================================================

## 控制台历史最大条数
const MAX_HISTORY: int = 100

## 命令前缀
const COMMAND_PREFIX: String = "/"

# =============================================================================
# 导出变量
# =============================================================================

## 是否启用调试模式
@export var debug_enabled: bool = true

## 是否显示调试信息
@export var show_debug_info: bool = true

## 是否显示FPS
@export var show_fps: bool = true

## 是否显示坐标
@export var show_position: bool = true

## 调试信息字体大小
@export var font_size: int = 16

## 控制台快捷键
@export var console_toggle_key: String = "ui_text_completion_accept"

# =============================================================================
# 公共变量
# =============================================================================

## 控制台是否可见
var console_visible: bool = false

## 命令历史
var command_history: Array[String] = []

## 玩家引用
var player: Node = null

## 调试无敌模式
var god_mode: bool = false

## 无限体力
var infinite_stamina: bool = false

## 无限法力
var infinite_mana: bool = false

## 调试速度倍率
var speed_multiplier: float = 1.0

# =============================================================================
# 私有变量
# =============================================================================

var _console: Control = null
var _console_input: LineEdit = null
var _console_output: RichTextLabel = null
var _info_label: Label = null
var _history_index: int = -1

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""
	节点就绪时初始化
	"""
	if not debug_enabled:
		queue_free()
		return
	
	_initialize_debug_tools()
	_create_ui()


func _process(delta: float) -> void:
	"""
	每帧更新
	@param delta: 帧间隔时间
	"""
	if not debug_enabled:
		return
	
	# 更新调试信息
	_update_debug_info(delta)
	
	# 处理调试快捷键
	_handle_shortcuts()
	
	# 应用调试效果
	_apply_debug_effects()


func _input(event: InputEvent) -> void:
	"""
	处理输入事件
	@param event: 输入事件
	"""
	if not debug_enabled:
		return
	
	# 控制台切换
	if event.is_action_pressed(console_toggle_key):
		toggle_console()
		get_viewport().set_input_as_handled()
	
	# 历史命令导航
	if console_visible and event is InputEventKey and event.pressed:
		if event.keycode == KEY_UP:
			_navigate_history(-1)
		elif event.keycode == KEY_DOWN:
			_navigate_history(1)

# =============================================================================
# 公共方法
# =============================================================================

## 切换调试模式
func toggle_debug_mode() -> void:
	"""
	切换调试模式
	"""
	debug_enabled = not debug_enabled
	debug_mode_toggled.emit(debug_enabled)
	
	if debug_enabled:
		show()
	else:
		hide()


## 切换控制台
func toggle_console() -> void:
	"""
	切换控制台显示
	"""
	console_visible = not console_visible
	
	if _console:
		_console.visible = console_visible
		
		if console_visible and _console_input:
			_console_input.grab_focus()


## 执行命令
func execute_command(command: String) -> String:
	"""
	执行调试命令
	@param command: 命令字符串
	@return: 执行结果
	"""
	var result: String = _parse_and_execute(command)
	
	# 添加到历史
	if not command.is_empty() and (command_history.is_empty() or command_history[-1] != command):
		command_history.append(command)
		if command_history.size() > MAX_HISTORY:
			command_history.pop_front()
	
	_history_index = command_history.size()
	
	debug_command_executed.emit(command, result)
	return result


## 打印到控制台
func print_to_console(text: String, color: Color = Color.WHITE) -> void:
	"""
	打印消息到控制台
	@param text: 消息文本
	@param color: 文本颜色
	"""
	if _console_output:
		_console_output.push_color(color)
		_console_output.add_text(text + "\n")
		_console_output.pop()


## 清除控制台
func clear_console() -> void:
	"""
	清除控制台内容
	"""
	if _console_output:
		_console_output.clear()


## 设置玩家引用
func set_player(player_node: Node) -> void:
	"""
	设置玩家引用
	@param player_node: 玩家节点
	"""
	player = player_node

# =============================================================================
# 私有方法 - 初始化
# =============================================================================

func _initialize_debug_tools() -> void:
	"""
	初始化调试工具
	"""
	# 查找玩家
	_find_player()
	
	# 设置控制台快捷键
	_setup_input_actions()


func _find_player() -> void:
	"""
	查找玩家节点
	"""
	var players: Array[Node] = get_tree().get_nodes_in_group("players")
	if not players.is_empty():
		player = players[0]


func _setup_input_actions() -> void:
	"""
	设置输入动作
	"""
	# 确保调试快捷键存在
	var debug_actions: Array[Dictionary] = [
		{"name": "debug_god_mode", "key": KEY_F1},
		{"name": "debug_heal", "key": KEY_F2},
		{"name": "debug_add_exp", "key": KEY_F3},
		{"name": "debug_level_up", "key": KEY_F4},
		{"name": "debug_spawn_enemy", "key": KEY_F5},
		{"name": "debug_clear_enemies", "key": KEY_F6},
		{"name": "debug_kill_all", "key": KEY_F7},
		{"name": "debug_next_wave", "key": KEY_F8},
		{"name": "debug_add_gold", "key": KEY_F9},
		{"name": "debug_toggle_info", "key": KEY_F10}
	]
	
	for action in debug_actions:
		if not InputMap.has_action(action.name):
			InputMap.add_action(action.name)
			var key_event: InputEventKey = InputEventKey.new()
			key_event.keycode = action.key
			InputMap.action_add_event(action.name, key_event)


func _create_ui() -> void:
	"""
	创建调试UI
	"""
	# 创建调试信息标签
	_info_label = Label.new()
	_info_label.name = "DebugInfo"
	_info_label.position = Vector2(10, 10)
	_info_label.add_theme_font_size_override("font_size", font_size)
	_info_label.add_theme_color_override("font_color", Color.GREEN)
	_info_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_info_label.add_theme_constant_override("outline_size", 2)
	add_child(_info_label)
	
	# 创建控制台
	_create_console()


func _create_console() -> void:
	"""
	创建控制台UI
	"""
	_console = Control.new()
	_console.name = "Console"
	_console.visible = false
	_console.anchor_right = 1.0
	_console.anchor_bottom = 1.0
	add_child(_console)
	
	# 控制台背景
	var background: ColorRect = ColorRect.new()
	background.color = Color(0, 0, 0, 0.8)
	background.position = Vector2(10, 10)
	background.size = Vector2(500, 300)
	_console.add_child(background)
	
	# 输出区域
	_console_output = RichTextLabel.new()
	_console_output.position = Vector2(15, 15)
	_console_output.size = Vector2(490, 250)
	_console_output.bbcode_enabled = true
	_console_output.scroll_following = true
	_console_output.add_theme_font_size_override("normal_font_size", font_size)
	_console.add_child(_console_output)
	
	# 输入框
	_console_input = LineEdit.new()
	_console_input.position = Vector2(15, 270)
	_console_input.size = Vector2(490, 30)
	_console_input.placeholder_text = "输入命令... (按Enter执行)"
	_console_input.add_theme_font_size_override("font_size", font_size)
	_console_input.text_submitted.connect(_on_command_submitted)
	_console.add_child(_console_input)

# =============================================================================
# 私有方法 - 更新
# =============================================================================

func _update_debug_info(_delta: float) -> void:
	"""
	更新调试信息显示
	"""
	if not show_debug_info or _info_label == null:
		return
	
	var info_text: String = ""
	
	if show_fps:
		info_text += "FPS: %d\n" % Engine.get_frames_per_second()
	
	if show_position and player and is_instance_valid(player):
		info_text += "Pos: (%.1f, %.1f)\n" % [player.global_position.x, player.global_position.y]
	
	# 添加调试状态
	if god_mode:
		info_text += "[GOD MODE]\n"
	if infinite_stamina:
		info_text += "[无限体力]\n"
	if infinite_mana:
		info_text += "[无限法力]\n"
	if speed_multiplier != 1.0:
		info_text += "速度: %.1fx\n" % speed_multiplier
	
	# 游戏状态
	info_text += "波次: %d\n" % GameManager.current_wave
	info_text += "击杀: %d\n" % GameManager.enemies_killed
	
	_info_label.text = info_text


func _handle_shortcuts() -> void:
	"""
	处理调试快捷键
	"""
	# 无敌模式
	if Input.is_action_just_pressed("debug_god_mode"):
		toggle_god_mode()
	
	# 恢复满血
	if Input.is_action_just_pressed("debug_heal"):
		debug_heal()
	
	# 增加经验
	if Input.is_action_just_pressed("debug_add_exp"):
		debug_add_experience(100)
	
	# 升级
	if Input.is_action_just_pressed("debug_level_up"):
		debug_level_up()
	
	# 生成敌人
	if Input.is_action_just_pressed("debug_spawn_enemy"):
		debug_spawn_enemy()
	
	# 清除敌人
	if Input.is_action_just_pressed("debug_clear_enemies"):
		debug_clear_enemies()
	
	# 击杀所有敌人
	if Input.is_action_just_pressed("debug_kill_all"):
		debug_kill_all_enemies()
	
	# 下一波
	if Input.is_action_just_pressed("debug_next_wave"):
		debug_next_wave()
	
	# 增加金币
	if Input.is_action_just_pressed("debug_add_gold"):
		debug_add_gold(1000)
	
	# 切换信息显示
	if Input.is_action_just_pressed("debug_toggle_info"):
		show_debug_info = not show_debug_info


func _apply_debug_effects() -> void:
	"""
	应用调试效果
	"""
	if player == null or not is_instance_valid(player):
		_find_player()
		return
	
	# 无敌模式
	if god_mode and "debug_god_mode" in player:
		player.debug_god_mode = true
	
	# 无限体力
	if infinite_stamina and "stats" in player and player.stats:
		player.stats.current_stamina = player.stats.max_stamina
	
	# 无限法力
	if infinite_mana and "stats" in player and player.stats:
		player.stats.current_mana = player.stats.max_mana
	
	# 速度倍率
	if speed_multiplier != 1.0 and "move_speed" in player:
		player.move_speed = player.BASE_MOVE_SPEED * speed_multiplier

# =============================================================================
# 私有方法 - 命令解析
# =============================================================================

func _parse_and_execute(command: String) -> String:
	"""
	解析并执行命令
	@param command: 命令字符串
	@return: 执行结果
	"""
	command = command.strip_edges()
	
	if command.is_empty():
		return ""
	
	# 移除命令前缀
	if command.begins_with(COMMAND_PREFIX):
		command = command.substr(COMMAND_PREFIX.length())
	
	var parts: PackedStringArray = command.split(" ", false, 2)
	var cmd: String = parts[0].to_lower()
	var args: PackedStringArray = parts.slice(1) if parts.size() > 1 else []
	
	# 执行命令
	match cmd:
		"help":
			return _cmd_help()
		"god", "invincible":
			return _cmd_god_mode(args)
		"heal":
			return _cmd_heal(args)
		"exp", "experience":
			return _cmd_add_exp(args)
		"level", "levelup":
			return _cmd_level_up()
		"gold":
			return _cmd_add_gold(args)
		"speed":
			return _cmd_speed(args)
		"spawn":
			return _cmd_spawn_enemy(args)
		"clear":
			return _cmd_clear_enemies()
		"kill":
			return _cmd_kill_all()
		"wave":
			return _cmd_next_wave()
		"stamina":
			return _cmd_infinite_stamina(args)
		"mana":
			return _cmd_infinite_mana(args)
		"info":
			return _cmd_toggle_info()
		"clearconsole", "cls":
			clear_console()
			return "控制台已清除"
		"stats":
			return _cmd_show_stats()
		"tp", "teleport":
			return _cmd_teleport(args)
		"list":
			return _cmd_list(args)
		_:
			return "未知命令: %s\n输入 'help' 查看可用命令" % cmd


func _cmd_help() -> String:
	"""
	显示帮助信息
	"""
	var help_text: String = """
[可用命令]
help - 显示此帮助
god [on/off] - 切换无敌模式
heal [amount] - 恢复生命值
exp <amount> - 增加经验值
level - 强制升级
gold <amount> - 增加金币
speed <multiplier> - 设置速度倍率
spawn [type] - 生成敌人
clear - 清除所有敌人
kill - 击杀所有敌人
wave - 跳到下一波
stamina [on/off] - 无限体力
mana [on/off] - 无限法力
info - 切换调试信息显示
stats - 显示玩家属性
tp <x> <y> - 传送到指定位置
list <type> - 列出指定类型
cls - 清除控制台

[快捷键]
F1 - 切换无敌模式
F2 - 恢复满血
F3 - 增加100经验
F4 - 强制升级
F5 - 生成敌人
F6 - 清除敌人
F7 - 击杀所有敌人
F8 - 下一波
F9 - 增加1000金币
F10 - 切换信息显示
"""
	return help_text

# =============================================================================
# 私有方法 - 命令实现
# =============================================================================

func _cmd_god_mode(args: PackedStringArray) -> String:
	"""
	无敌模式命令
	"""
	if args.is_empty():
		toggle_god_mode()
	else:
		god_mode = args[0].to_lower() in ["on", "true", "1", "yes"]
		if player and "debug_god_mode" in player:
			player.debug_god_mode = god_mode
	
	return "无敌模式: %s" % ("开启" if god_mode else "关闭")


func _cmd_heal(args: PackedStringArray) -> String:
	"""
	治疗命令
	"""
	if player == null or not is_instance_valid(player):
		return "错误: 玩家不存在"
	
	var amount: float = INF
	if not args.is_empty():
		amount = args[0].to_float()
	
	if "heal" in player:
		if is_inf(amount):
			player.heal(player.stats.max_health)
			return "已恢复满血"
		else:
			player.heal(amount)
			return "恢复 %.0f 生命值" % amount
	
	return "错误: 无法治疗"


func _cmd_add_exp(args: PackedStringArray) -> String:
	"""
	增加经验命令
	"""
	if args.is_empty():
		return "用法: exp <amount>"
	
	var amount: int = args[0].to_int()
	debug_add_experience(amount)
	return "增加 %d 经验值" % amount


func _cmd_level_up() -> String:
	"""
	升级命令
	"""
	debug_level_up()
	return "强制升级"


func _cmd_add_gold(args: PackedStringArray) -> String:
	"""
	增加金币命令
	"""
	if args.is_empty():
		return "用法: gold <amount>"
	
	var amount: int = args[0].to_int()
	debug_add_gold(amount)
	return "增加 %d 金币" % amount


func _cmd_speed(args: PackedStringArray) -> String:
	"""
	速度命令
	"""
	if args.is_empty():
		return "当前速度倍率: %.1f" % speed_multiplier
	
	speed_multiplier = args[0].to_float()
	return "速度倍率设置为: %.1f" % speed_multiplier


func _cmd_spawn_enemy(args: PackedStringArray) -> String:
	"""
	生成敌人命令
	"""
	var enemy_type: String = "melee"
	if not args.is_empty():
		enemy_type = args[0].to_lower()
	
	debug_spawn_enemy(enemy_type)
	return "生成敌人: %s" % enemy_type


func _cmd_clear_enemies() -> String:
	"""
	清除敌人命令
	"""
	debug_clear_enemies()
	return "已清除所有敌人"


func _cmd_kill_all() -> String:
	"""
	击杀所有敌人命令
	"""
	debug_kill_all_enemies()
	return "已击杀所有敌人"


func _cmd_next_wave() -> String:
	"""
	下一波命令
	"""
	debug_next_wave()
	return "跳到下一波"


func _cmd_infinite_stamina(args: PackedStringArray) -> String:
	"""
	无限体力命令
	"""
	if args.is_empty():
		infinite_stamina = not infinite_stamina
	else:
		infinite_stamina = args[0].to_lower() in ["on", "true", "1", "yes"]
	
	return "无限体力: %s" % ("开启" if infinite_stamina else "关闭")


func _cmd_infinite_mana(args: PackedStringArray) -> String:
	"""
	无限法力命令
	"""
	if args.is_empty():
		infinite_mana = not infinite_mana
	else:
		infinite_mana = args[0].to_lower() in ["on", "true", "1", "yes"]
	
	return "无限法力: %s" % ("开启" if infinite_mana else "关闭")


func _cmd_toggle_info() -> String:
	"""
	切换信息显示命令
	"""
	show_debug_info = not show_debug_info
	return "调试信息: %s" % ("显示" if show_debug_info else "隐藏")


func _cmd_show_stats() -> String:
	"""
	显示玩家属性
	"""
	if player == null or not is_instance_valid(player):
		return "错误: 玩家不存在"
	
	if "stats" not in player or player.stats == null:
		return "错误: 玩家属性不存在"
	
	var stats: PlayerStats = player.stats
	return """
[玩家属性]
等级: %d
经验: %d / %d
生命: %.0f / %.0f
法力: %.0f / %.0f
体力: %.0f / %.0f
攻击: %.0f
防御: %.0f
速度: %.0f
暴击率: %.0f%%
暴击伤害: %.0f%%
""" % [
		stats.level, stats.current_experience, stats.experience_required,
		stats.current_health, stats.max_health,
		stats.current_mana, stats.max_mana,
		stats.current_stamina, stats.max_stamina,
		stats.attack, stats.defense, stats.speed,
		stats.critical_chance * 100, stats.critical_damage * 100
	]


func _cmd_teleport(args: PackedStringArray) -> String:
	"""
	传送命令
	"""
	if args.size() < 2:
		return "用法: tp <x> <y>"
	
	var x: float = args[0].to_float()
	var y: float = args[1].to_float()
	
	if player and is_instance_valid(player):
		player.global_position = Vector2(x, y)
		return "传送到 (%.0f, %.0f)" % [x, y]
	
	return "错误: 玩家不存在"


func _cmd_list(args: PackedStringArray) -> String:
	"""
	列表命令
	"""
	if args.is_empty():
		return "用法: list <enemies|items|bullets>"
	
	var list_type: String = args[0].to_lower()
	
	match list_type:
		"enemies":
			var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
			return "敌人数量: %d" % enemies.size()
		"items":
			var items: Array[Node] = get_tree().get_nodes_in_group("items")
			return "物品数量: %d" % items.size()
		"bullets":
			var bullets: Array[Node] = get_tree().get_nodes_in_group("player_bullets") + \
									   get_tree().get_nodes_in_group("enemy_bullets")
			return "子弹数量: %d" % bullets.size()
		_:
			return "未知列表类型: %s" % list_type


func _on_command_submitted(command: String) -> void:
	"""
	命令提交回调
	"""
	if command.is_empty():
		return
	
	# 显示命令
	print_to_console("> " + command, Color.CYAN)
	
	# 执行并显示结果
	var result: String = execute_command(command)
	if not result.is_empty():
		print_to_console(result, Color.WHITE)
	
	# 清空输入
	if _console_input:
		_console_input.clear()

# =============================================================================
# 公共调试方法
# =============================================================================

## 切换无敌模式
func toggle_god_mode() -> void:
	"""
	切换无敌模式
	"""
	god_mode = not god_mode
	
	if player and "debug_god_mode" in player:
		player.debug_god_mode = god_mode
	
	print_to_console("无敌模式: %s" % ("开启" if god_mode else "关闭"), Color.YELLOW)


## 调试恢复满血
func debug_heal() -> void:
	"""
	恢复满血
	"""
	if player and is_instance_valid(player) and "heal" in player:
		player.heal(player.stats.max_health if player.stats else INF)
		print_to_console("已恢复满血", Color.GREEN)


## 调试增加经验
func debug_add_experience(amount: int) -> void:
	"""
	增加经验值
	@param amount: 经验值数量
	"""
	if player and is_instance_valid(player) and "stats" in player and player.stats:
		player.stats.add_experience(amount)
		print_to_console("增加 %d 经验值" % amount, Color.GREEN)


## 调试升级
func debug_level_up() -> void:
	"""
	强制升级
	"""
	if player and is_instance_valid(player) and "stats" in player and player.stats:
		var stats: PlayerStats = player.stats
		stats.add_experience(stats.experience_required - stats.current_experience + 1)
		print_to_console("强制升级", Color.GREEN)


## 调试增加金币
func debug_add_gold(amount: int) -> void:
	"""
	增加金币
	@param amount: 金币数量
	"""
	GameManager.gold_collected += amount
	print_to_console("增加 %d 金币" % amount, Color.GOLD)


## 调试生成敌人
func debug_spawn_enemy(enemy_type: String = "melee") -> void:
	"""
	生成敌人
	@param enemy_type: 敌人类型
	"""
	if player == null:
		return
	
	var spawn_pos: Vector2 = player.global_position + Vector2(randf_range(-100, 100), randf_range(-100, 100))
	
	# 使用WaveManager生成
	var wave_manager: Node = get_node_or_null("/root/Main/WaveManager")
	if wave_manager and "spawn_specific_enemy" in wave_manager:
		wave_manager.spawn_specific_enemy(enemy_type, spawn_pos)
		print_to_console("生成敌人: %s" % enemy_type, Color.YELLOW)


## 调试清除敌人
func debug_clear_enemies() -> void:
	"""
	清除所有敌人
	"""
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	print_to_console("已清除 %d 个敌人" % enemies.size(), Color.YELLOW)


## 调试击杀所有敌人
func debug_kill_all_enemies() -> void:
	"""
	击杀所有敌人
	"""
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and "die" in enemy:
			enemy.die(player)
	print_to_console("已击杀 %d 个敌人" % enemies.size(), Color.YELLOW)


## 调试下一波
func debug_next_wave() -> void:
	"""
	跳到下一波
	"""
	var wave_manager: Node = get_node_or_null("/root/Main/WaveManager")
	if wave_manager and "start_next_wave" in wave_manager:
		wave_manager.start_next_wave()
		print_to_console("跳到下一波", Color.YELLOW)


func _navigate_history(direction: int) -> void:
	"""
	导航命令历史
	@param direction: 方向 (-1向上, 1向下)
	"""
	if command_history.is_empty():
		return
	
	_history_index = clamp(_history_index + direction, -1, command_history.size() - 1)
	
	if _history_index == -1:
		if _console_input:
			_console_input.clear()
	elif _console_input:
		_console_input.text = command_history[_history_index]
		_console_input.caret_column = _console_input.text.length()
