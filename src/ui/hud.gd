## Void Hunter - HUD界面
## @description: 游戏内HUD，显示玩家状态、技能栏、波次信息和游戏统计
## @author: Void Hunter Team
## @version: 1.0.0

extends Control
class_name HUD

# =============================================================================
# 信号定义
# =============================================================================

## 技能按钮按下时触发
signal skill_button_pressed(skill_index: int)

## 物品按钮按下时触发
signal item_button_pressed(item_index: int)

## 暂停按钮按下时触发
signal pause_button_pressed()

# =============================================================================
# 节点引用 - 状态条
# =============================================================================

## 生命条
@onready var health_bar: ProgressBar = $LeftPanel/VBoxContainer/HealthContainer/HealthBar
@onready var health_label: Label = $LeftPanel/VBoxContainer/HealthContainer/HealthLabel
@onready var health_bar_bg: Panel = $LeftPanel/VBoxContainer/HealthContainer/HealthBar/BgPanel

## 法力条
@onready var mana_bar: ProgressBar = $LeftPanel/VBoxContainer/ManaContainer/ManaBar
@onready var mana_label: Label = $LeftPanel/VBoxContainer/ManaContainer/ManaLabel

## 体力条
@onready var stamina_bar: ProgressBar = $LeftPanel/VBoxContainer/StaminaContainer/StaminaBar
@onready var stamina_label: Label = $LeftPanel/VBoxContainer/StaminaContainer/StaminaLabel

## 经验条
@onready var exp_bar: ProgressBar = $BottomPanel/ExpContainer/ExpBar
@onready var exp_label: Label = $BottomPanel/ExpContainer/ExpLabel
@onready var level_label: Label = $LeftPanel/VBoxContainer/LevelContainer/LevelLabel

# =============================================================================
# 节点引用 - 技能/物品栏
# =============================================================================

## 技能槽
@onready var skill_slots: Array[Control] = [
	$BottomPanel/SkillBar/SkillSlot1,
	$BottomPanel/SkillBar/SkillSlot2,
	$BottomPanel/SkillBar/SkillSlot3,
	$BottomPanel/SkillBar/SkillSlot4
]

## 物品槽
@onready var item_slots: Array[Control] = [
	$BottomPanel/ItemBar/ItemSlot1,
	$BottomPanel/ItemBar/ItemSlot2,
	$BottomPanel/ItemBar/ItemSlot3
]

## 技能冷却遮罩
var skill_cooldown_overlays: Array[Panel] = []
var skill_cooldown_labels: Array[Label] = []

# =============================================================================
# 节点引用 - 信息面板
# =============================================================================

## 波次信息
@onready var wave_label: Label = $RightPanel/VBoxContainer/WaveInfo/WaveLabel
@onready var enemy_count_label: Label = $RightPanel/VBoxContainer/WaveInfo/EnemyCountLabel

## 统计信息
@onready var time_label: Label = $RightPanel/VBoxContainer/StatsContainer/TimeLabel
@onready var kill_count_label: Label = $RightPanel/VBoxContainer/StatsContainer/KillCountLabel

## 暂停按钮
@onready var pause_button: Button = $RightPanel/VBoxContainer/PauseButton

## 小地图
@onready var minimap: Control = $RightPanel/MinimapContainer

# =============================================================================
# 私有变量
# =============================================================================

var _player_stats: PlayerStats = null
var _wave_manager: WaveManager = null
var _skill_manager: Node = null
var _low_health_flash_tween: Tween = null
var _is_low_health: bool = false

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""
	节点就绪时初始化HUD
	"""
	_initialize_hud()
	_connect_signals()
	_apply_styles()
	_setup_skill_slots()


func _process(delta: float) -> void:
	"""
	每帧更新HUD
	@param delta: 帧间隔时间
	"""
	_update_game_time()
	_update_skill_cooldowns(delta)

# =============================================================================
# 公共方法
# =============================================================================

## 绑定玩家属性
func bind_player_stats(stats: PlayerStats) -> void:
	"""
	绑定玩家属性以更新显示
	@param stats: 玩家属性引用
	"""
	_player_stats = stats
	
	# 连接属性变化信号
	if _player_stats:
		_player_stats.health_changed.connect(_on_health_changed)
		_player_stats.mana_changed.connect(_on_mana_changed)
		_player_stats.stamina_changed.connect(_on_stamina_changed)
		_player_stats.experience_changed.connect(_on_experience_changed)
		_player_stats.leveled_up.connect(_on_leveled_up)
		_player_stats.stats_changed.connect(_on_stats_changed)
		
		# 初始更新
		_update_all_displays()


## 绑定波次管理器
func bind_wave_manager(manager: WaveManager) -> void:
	"""
	绑定波次管理器
	@param manager: 波次管理器引用
	"""
	_wave_manager = manager
	
	if _wave_manager:
		_wave_manager.wave_started.connect(_on_wave_started)
		_wave_manager.wave_completed.connect(_on_wave_completed)
		_wave_manager.enemy_spawned.connect(_on_enemy_spawned)
		_wave_manager.all_enemies_cleared.connect(_on_all_enemies_cleared)
		_update_wave_info()


## 绑定技能管理器
func bind_skill_manager(manager: Node) -> void:
	"""
	绑定技能管理器
	@param manager: 技能管理器引用
	"""
	_skill_manager = manager


## 更新生命值显示
func update_health(current: float, maximum: float) -> void:
	"""
	更新生命值条
	@param current: 当前生命值
	@param maximum: 最大生命值
	"""
	health_bar.max_value = maximum
	health_bar.value = current
	
	# 更新文本
	health_label.text = "%d / %d" % [int(current), int(maximum)]
	
	# 生命值低时效果
	var health_percent: float = current / maximum if maximum > 0 else 0
	_update_health_color(health_percent)


## 更新法力值显示
func update_mana(current: float, maximum: float) -> void:
	"""
	更新法力值条
	@param current: 当前法力值
	@param maximum: 最大法力值
	"""
	mana_bar.max_value = maximum
	mana_bar.value = current
	mana_label.text = "%d / %d" % [int(current), int(maximum)]


## 更新体力值显示
func update_stamina(current: float, maximum: float) -> void:
	"""
	更新体力值条
	@param current: 当前体力值
	@param maximum: 最大体力值
	"""
	stamina_bar.max_value = maximum
	stamina_bar.value = current
	stamina_label.text = "%d / %d" % [int(current), int(maximum)]


## 更新经验值显示
func update_experience(current: float, required: float, level: int) -> void:
	"""
	更新经验值条
	@param current: 当前经验值
	@param required: 升级所需经验值
	@param level: 当前等级
	"""
	exp_bar.max_value = required
	exp_bar.value = current
	exp_label.text = "%d / %d" % [int(current), int(required)]
	level_label.text = tr("UI_LEVEL") % level


## 更新波次信息
func update_wave_info(wave: int, enemy_count: int = 0) -> void:
	"""
	更新波次信息
	@param wave: 当前波次
	@param enemy_count: 剩余敌人数量
	"""
	wave_label.text = tr("UI_WAVE") % wave
	enemy_count_label.text = tr("UI_ENEMIES") % enemy_count


## 更新生存时间
func update_time(seconds: float) -> void:
	"""
	更新生存时间
	@param seconds: 生存秒数
	"""
	time_label.text = UITheme.format_time(seconds)


## 更新击杀数
func update_kill_count(count: int) -> void:
	"""
	更新击杀数
	@param count: 击杀数量
	"""
	kill_count_label.text = tr("UI_KILLS") % UITheme.format_number(count)


## 更新技能槽
func update_skill_slot(index: int, skill_icon: Texture2D = null, cooldown: float = 0.0) -> void:
	"""
	更新技能槽显示
	@param index: 技能槽索引 (0-3)
	@param skill_icon: 技能图标
	@param cooldown: 冷却时间
	"""
	if index < 0 or index >= skill_slots.size():
		return
	
	var slot: Control = skill_slots[index]
	var icon: TextureRect = slot.get_node_or_null("Icon")
	
	if icon and skill_icon:
		icon.texture = skill_icon
	
	# 更新冷却显示
	if cooldown > 0:
		_show_skill_cooldown(index, cooldown)
	else:
		_hide_skill_cooldown(index)


## 显示HUD
func show_hud() -> void:
	"""
	显示HUD（带动画）
	"""
	show()
	modulate.a = 0.0
	UITheme.fade_in(self)


## 隐藏HUD
func hide_hud() -> void:
	"""
	隐藏HUD（带动画）
	"""
	UITheme.fade_out(self).tween_callback(hide)


# =============================================================================
# 私有方法 - 初始化
# =============================================================================

func _initialize_hud() -> void:
	"""
	初始化HUD状态
	"""
	# 初始化显示
	health_bar.max_value = 100
	health_bar.value = 100
	mana_bar.max_value = 50
	mana_bar.value = 50
	stamina_bar.max_value = 100
	stamina_bar.value = 100
	exp_bar.max_value = 100
	exp_bar.value = 0
	
	# 设置初始值
	wave_label.text = tr("UI_WAVE") % 1
	enemy_count_label.text = tr("UI_ENEMIES") % 0
	time_label.text = "00:00"
	kill_count_label.text = tr("UI_KILLS") % 0
	level_label.text = tr("UI_LEVEL") % 1


func _connect_signals() -> void:
	"""
	连接信号
	"""
	# 技能槽点击
	for i in range(skill_slots.size()):
		var slot: Control = skill_slots[i]
		var button: Button = slot.get_node_or_null("Button")
		if button:
			button.pressed.connect(_on_skill_slot_pressed.bind(i))
	
	# 物品槽点击
	for i in range(item_slots.size()):
		var slot: Control = item_slots[i]
		var button: Button = slot.get_node_or_null("Button")
		if button:
			button.pressed.connect(_on_item_slot_pressed.bind(i))
	
	# 暂停按钮
	if pause_button:
		pause_button.pressed.connect(_on_pause_pressed)
	
	# 游戏管理器信号
	GameManager.game_state_changed.connect(_on_game_state_changed)


func _apply_styles() -> void:
	"""
	应用UI样式
	"""
	# 状态条样式
	UITheme.create_progress_bar_style(health_bar, UITheme.COLOR_HEALTH, UITheme.COLOR_BG_PANEL)
	UITheme.create_progress_bar_style(mana_bar, UITheme.COLOR_MANA, UITheme.COLOR_BG_PANEL)
	UITheme.create_progress_bar_style(stamina_bar, UITheme.COLOR_STAMINA, UITheme.COLOR_BG_PANEL)
	UITheme.create_progress_bar_style(exp_bar, UITheme.COLOR_EXPERIENCE, UITheme.COLOR_BG_PANEL)
	
	# 技能槽样式
	for slot in skill_slots:
		UITheme.create_slot_style(slot)
	
	# 物品槽样式
	for slot in item_slots:
		UITheme.create_slot_style(slot)
	
	# 暂停按钮样式
	if pause_button:
		UITheme.create_button_style(pause_button, false, "sm")


func _setup_skill_slots() -> void:
	"""
	设置技能槽的冷却遮罩
	"""
	skill_cooldown_overlays.clear()
	skill_cooldown_labels.clear()
	
	for i in range(skill_slots.size()):
		var slot: Control = skill_slots[i]
		
		# 创建冷却遮罩
		var overlay := Panel.new()
		overlay.name = "CooldownOverlay"
		overlay.modulate = Color(0, 0, 0, 0.7)
		overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.hide()
		
		# 创建样式
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0, 0, 0, 0.7)
		style.set_corner_radius_all(UITheme.BORDER_RADIUS_SMALL)
		overlay.add_theme_stylebox_override("panel", style)
		
		slot.add_child(overlay)
		skill_cooldown_overlays.append(overlay)
		
		# 创建冷却时间文本
		var label := Label.new()
		label.name = "CooldownLabel"
		label.set_anchors_preset(Control.PRESET_CENTER)
		label.position = slot.size / 2
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", UITheme.FONT_SIZE_LG)
		label.add_theme_color_override("font_color", Color.WHITE)
		
		slot.add_child(label)
		skill_cooldown_labels.append(label)
		
		# 设置快捷键提示
		var key_label: Label = slot.get_node_or_null("KeyLabel")
		if key_label:
			key_label.text = str(i + 1)


# =============================================================================
# 私有方法 - 更新
# =============================================================================

func _update_all_displays() -> void:
	"""
	更新所有显示
	"""
	if _player_stats == null:
		return
	
	update_health(_player_stats.current_health, _player_stats.max_health)
	update_mana(_player_stats.current_mana, _player_stats.max_mana)
	update_stamina(_player_stats.current_stamina, _player_stats.max_stamina)
	update_experience(_player_stats.current_experience, _player_stats.experience_required, _player_stats.level)


func _update_health_color(health_percent: float) -> void:
	"""
	更新生命值颜色
	@param health_percent: 生命值百分比
	"""
	var fill: StyleBoxFlat = health_bar.get_theme_stylebox("fill")
	if fill:
		fill.bg_color = UITheme.get_health_color(health_percent)
	
	# 低生命值闪烁效果
	if health_percent <= 0.3 and not _is_low_health:
		_start_low_health_flash()
		_is_low_health = true
	elif health_percent > 0.3 and _is_low_health:
		_stop_low_health_flash()
		_is_low_health = false


func _start_low_health_flash() -> void:
	"""
	开始低生命值闪烁效果
	"""
	if _low_health_flash_tween:
		_low_health_flash_tween.kill()
	
	_low_health_flash_tween = create_tween()
	_low_health_flash_tween.set_loops()
	_low_health_flash_tween.tween_property(health_bar, "modulate:a", 0.5, 0.3)
	_low_health_flash_tween.tween_property(health_bar, "modulate:a", 1.0, 0.3)


func _stop_low_health_flash() -> void:
	"""
	停止低生命值闪烁效果
	"""
	if _low_health_flash_tween:
		_low_health_flash_tween.kill()
		_low_health_flash_tween = null
		health_bar.modulate.a = 1.0


func _update_game_time() -> void:
	"""
	更新游戏时间
	"""
	if GameManager.current_state == GameManager.GameState.PLAYING:
		update_time(GameManager.game_time)
		update_kill_count(GameManager.enemies_killed)


func _update_wave_info() -> void:
	"""
	更新波次信息
	"""
	if _wave_manager:
		var info: Dictionary = _wave_manager.get_wave_info()
		update_wave_info(info.get("wave", 1), info.get("remaining", 0))


func _update_skill_cooldowns(delta: float) -> void:
	"""
	更新技能冷却显示
	@param delta: 帧间隔时间
	"""
	# TODO: 从技能管理器获取冷却信息
	# 这里暂时是框架，实际需要与技能系统集成
	pass


func _show_skill_cooldown(index: int, remaining_time: float) -> void:
	"""
	显示技能冷却
	@param index: 技能索引
	@param remaining_time: 剩余冷却时间
	"""
	if index >= skill_cooldown_overlays.size():
		return
	
	skill_cooldown_overlays[index].show()
	
	if remaining_time > 0:
		skill_cooldown_labels[index].text = "%.1f" % remaining_time
		skill_cooldown_labels[index].show()
	else:
		skill_cooldown_labels[index].hide()


func _hide_skill_cooldown(index: int) -> void:
	"""
	隐藏技能冷却
	@param index: 技能索引
	"""
	if index >= skill_cooldown_overlays.size():
		return
	
	skill_cooldown_overlays[index].hide()
	skill_cooldown_labels[index].hide()


# =============================================================================
# 信号回调 - 玩家属性
# =============================================================================

func _on_health_changed(current: float, maximum: float) -> void:
	"""
	生命值变化回调
	"""
	update_health(current, maximum)


func _on_mana_changed(current: float, maximum: float) -> void:
	"""
	法力值变化回调
	"""
	update_mana(current, maximum)


func _on_stamina_changed(current: float, maximum: float) -> void:
	"""
	体力值变化回调
	"""
	update_stamina(current, maximum)


func _on_experience_changed(current: float, required: float) -> void:
	"""
	经验值变化回调
	"""
	if _player_stats:
		update_experience(current, required, _player_stats.level)


func _on_leveled_up(new_level: int) -> void:
	"""
	升级回调
	"""
	if _player_stats:
		level_label.text = tr("UI_LEVEL") % new_level
	
	# 播放升级特效
	_play_level_up_effect()


func _on_stats_changed() -> void:
	"""
	属性变化回调
	"""
	_update_all_displays()


# =============================================================================
# 信号回调 - 波次
# =============================================================================

func _on_wave_started(wave_number: int) -> void:
	"""
	波次开始回调
	"""
	wave_label.text = tr("UI_WAVE") % wave_number
	UITheme.pulse(wave_label.get_parent())
	
	# 播放音效
	AudioManager.play_sfx("wave_start")


func _on_wave_completed(wave_number: int) -> void:
	"""
	波次完成回调
	"""
	# 播放完成特效
	UITheme.pulse(wave_label.get_parent())


func _on_enemy_spawned(_enemy: Node) -> void:
	"""
	敌人生成回调
	"""
	_update_wave_info()


func _on_all_enemies_cleared() -> void:
	"""
	所有敌人清除回调
	"""
	enemy_count_label.text = tr("UI_ENEMIES") % 0


# =============================================================================
# 信号回调 - 按钮
# =============================================================================

func _on_skill_slot_pressed(index: int) -> void:
	"""
	技能槽按下
	@param index: 技能索引
	"""
	AudioManager.play_ui_sound("button_click")
	skill_button_pressed.emit(index)


func _on_item_slot_pressed(index: int) -> void:
	"""
	物品槽按下
	@param index: 物品索引
	"""
	AudioManager.play_ui_sound("button_click")
	item_button_pressed.emit(index)


func _on_pause_pressed() -> void:
	"""
	暂停按钮按下
	"""
	AudioManager.play_ui_sound("button_click")
	pause_button_pressed.emit()


# =============================================================================
# 信号回调 - 游戏状态
# =============================================================================

func _on_game_state_changed(_old_state: GameManager.GameState, new_state: GameManager.GameState) -> void:
	"""
	游戏状态变化回调
	"""
	match new_state:
		GameManager.GameState.PAUSED:
			# 暂停时显示提示
			pass
		GameManager.GameState.PLAYING:
			# 恢复游戏
			pass


# =============================================================================
# 特效
# =============================================================================

func _play_level_up_effect() -> void:
	"""
	播放升级特效
	"""
	# 等级标签闪烁
	var tween := create_tween()
	tween.tween_property(level_label, "modulate", Color.YELLOW, 0.2)
	tween.tween_property(level_label, "modulate", Color.WHITE, 0.2)
	tween.tween_property(level_label, "modulate", Color.YELLOW, 0.2)
	tween.tween_property(level_label, "modulate", Color.WHITE, 0.2)
	
	# 经验条脉冲
	UITheme.pulse(exp_bar)
	
	# 播放音效
	AudioManager.play_sfx("level_up")
