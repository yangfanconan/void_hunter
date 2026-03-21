## Void Hunter - HUD 控制器
## @description: 管理游戏界面显示，包括生命值、法力值、波次、击杀数等
## @author: Void Hunter Team
## @version: 1.0.0

extends Control

# =============================================================================
# 节点引用
# =============================================================================

@onready var _health_bar: ProgressBar = $TopLeft/HealthContainer/HealthBar
@onready var _health_label: Label = $TopLeft/HealthContainer/HealthLabel
@onready var _mana_bar: ProgressBar = $TopLeft/ManaContainer/ManaBar
@onready var _mana_label: Label = $TopLeft/ManaContainer/ManaLabel
@onready var _stamina_bar: ProgressBar = $TopLeft/StaminaContainer/StaminaBar
@onready var _stamina_label: Label = $TopLeft/StaminaContainer/StaminaLabel
@onready var _wave_label: Label = $TopRight/WaveLabel
@onready var _enemies_label: Label = $TopRight/EnemiesLabel
@onready var _time_label: Label = $TopRight/TimeLabel
@onready var _kills_label: Label = $TopRight/KillsLabel
@onready var _level_label: Label = $TopRight/LevelLabel
@onready var _exp_bar: ProgressBar = $ExpBar
@onready var _exp_label: Label = $ExpBar/ExpLabel

# =============================================================================
# 私有变量
# =============================================================================

var _player_ref: Node = null
var _player_stats: Resource = null
var _game_time: float = 0.0

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""节点就绪"""
	_update_display()


func _process(delta: float) -> void:
	"""每帧更新"""
	if not visible:
		return
	
	_game_time += delta
	_update_display()

# =============================================================================
# 公共方法
# =============================================================================

## 设置玩家引用
func set_player(player: Node) -> void:
	"""设置玩家引用并连接信号"""
	_player_ref = player
	
	if _player_ref == null:
		return
	
	# 获取玩家属性
	if _player_ref.has("stats"):
		_player_stats = _player_ref.stats
		
		# 连接属性变化信号
		if _player_stats and _player_stats.has_signal("health_changed"):
			if not _player_stats.health_changed.is_connected(_on_health_changed):
				_player_stats.health_changed.connect(_on_health_changed)
		
		if _player_stats and _player_stats.has_signal("mana_changed"):
			if not _player_stats.mana_changed.is_connected(_on_mana_changed):
				_player_stats.mana_changed.connect(_on_mana_changed)
		
		if _player_stats and _player_stats.has_signal("stamina_changed"):
			if not _player_stats.stamina_changed.is_connected(_on_stamina_changed):
				_player_stats.stamina_changed.connect(_on_stamina_changed)
		
		if _player_stats and _player_stats.has_signal("experience_changed"):
			if not _player_stats.experience_changed.is_connected(_on_experience_changed):
				_player_stats.experience_changed.connect(_on_experience_changed)
		
		if _player_stats and _player_stats.has_signal("leveled_up"):
			if not _player_stats.leveled_up.is_connected(_on_leveled_up):
				_player_stats.leveled_up.connect(_on_leveled_up)
		
		# 初始显示
		_update_player_stats()
	
	# 连接玩家信号
	if _player_ref.has_signal("stats_changed"):
		if not _player_ref.stats_changed.is_connected(_on_player_stats_changed):
			_player_ref.stats_changed.connect(_on_player_stats_changed)


## 更新生命值显示
func update_health(current: float, maximum: float) -> void:
	"""更新生命值显示"""
	if _health_label:
		_health_label.text = "HP: %d/%d" % [int(current), int(maximum)]
	if _health_bar:
		_health_bar.max_value = maximum
		_health_bar.value = current


## 更新法力值显示
func update_mana(current: float, maximum: float) -> void:
	"""更新法力值显示"""
	if _mana_label:
		_mana_label.text = "MP: %d/%d" % [int(current), int(maximum)]
	if _mana_bar:
		_mana_bar.max_value = maximum
		_mana_bar.value = current


## 更新体力值显示
func update_stamina(current: float, maximum: float) -> void:
	"""更新体力值显示"""
	if _stamina_label:
		_stamina_label.text = "体力: %d/%d" % [int(current), int(maximum)]
	if _stamina_bar:
		_stamina_bar.max_value = maximum
		_stamina_bar.value = current


## 更新经验值显示
func update_exp(current: float, maximum: float) -> void:
	"""更新经验值显示"""
	if _exp_bar:
		_exp_bar.max_value = maximum
		_exp_bar.value = current
	if _exp_label:
		_exp_label.text = "EXP: %d/%d" % [int(current), int(maximum)]

# =============================================================================
# 私有方法
# =============================================================================

func _update_display() -> void:
	"""更新所有显示"""
	# 更新波次
	if _wave_label:
		var wave := 1
		if GameManager:
			wave = GameManager.get_current_wave()
		_wave_label.text = "波次: %d" % wave
	
	# 更新时间
	if _time_label:
		var mins := int(_game_time) / 60
		var secs := int(_game_time) % 60
		_time_label.text = "时间: %02d:%02d" % [mins, secs]
	
	# 更新击杀数
	if _kills_label:
		var kills := 0
		if GameManager:
			kills = GameManager.get_total_kills()
		_kills_label.text = "击杀: %d" % kills
	
	# 更新等级
	if _level_label and _player_stats:
		if _player_stats.has("level"):
			_level_label.text = "等级: %d" % _player_stats.level


func _update_player_stats() -> void:
	"""更新玩家属性显示"""
	if _player_stats == null:
		return
	
	# 更新生命值
	if _player_stats.has("current_health") and _player_stats.has("max_health"):
		update_health(_player_stats.current_health, _player_stats.max_health)
	
	# 更新法力值
	if _player_stats.has("current_mana") and _player_stats.has("max_mana"):
		update_mana(_player_stats.current_mana, _player_stats.max_mana)
	
	# 更新体力值
	if _player_stats.has("current_stamina") and _player_stats.has("max_stamina"):
		update_stamina(_player_stats.current_stamina, _player_stats.max_stamina)
	
	# 更新经验值
	if _player_stats.has("current_experience") and _player_stats.has("experience_required"):
		update_exp(_player_stats.current_experience, _player_stats.experience_required)
	
	# 更新等级
	if _level_label and _player_stats.has("level"):
		_level_label.text = "等级: %d" % _player_stats.level

# =============================================================================
# 信号回调
# =============================================================================

func _on_health_changed(current: float, maximum: float) -> void:
	"""生命值变化回调"""
	update_health(current, maximum)


func _on_mana_changed(current: float, maximum: float) -> void:
	"""法力值变化回调"""
	update_mana(current, maximum)


func _on_stamina_changed(current: float, maximum: float) -> void:
	"""体力值变化回调"""
	update_stamina(current, maximum)


func _on_experience_changed(current: float, required: float) -> void:
	"""经验值变化回调"""
	update_exp(current, required)


func _on_leveled_up(new_level: int) -> void:
	"""升级回调"""
	if _level_label:
		_level_label.text = "等级: %d" % new_level
	
	# 播放升级动画
	_play_level_up_animation()


func _on_player_stats_changed(stats: Resource) -> void:
	"""玩家属性变化回调"""
	_player_stats = stats
	_update_player_stats()


func _play_level_up_animation() -> void:
	"""播放升级动画"""
	if _level_label:
		var tween := create_tween()
		tween.tween_property(_level_label, "scale", Vector2(1.5, 1.5), 0.2)
		tween.tween_property(_level_label, "scale", Vector2.ONE, 0.2)
		tween.parallel().tween_property(_level_label, "modulate", Color.YELLOW, 0.1)
		tween.tween_property(_level_label, "modulate", Color.WHITE, 0.2)
