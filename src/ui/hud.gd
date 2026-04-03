## Void Hunter - HUD 控制器
## @description: 管理游戏界面显示，包括生命值、法力值、波次、击杀数等
## @author: Void Hunter Team
## @version: 1.0.0

extends Control

# =============================================================================
# 信号定义
# =============================================================================

## 技能按钮点击
signal skill_button_pressed(slot: int)

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
@onready var _exp_label: Label = $ExpBar/ExpLabel if has_node("ExpBar/ExpLabel") else null

# 属性加成显示节点（使用 get_node_or_null 避免节点不存在时报错）
@onready var _stats_panel: Panel = get_node_or_null("StatsPanel")
@onready var _attack_bonus_label: Label = get_node_or_null("StatsPanel/VBoxContainer/AttackBonusLabel")
@onready var _health_bonus_label: Label = get_node_or_null("StatsPanel/VBoxContainer/HealthBonusLabel")
@onready var _speed_bonus_label: Label = get_node_or_null("StatsPanel/VBoxContainer/SpeedBonusLabel")
@onready var _crit_bonus_label: Label = get_node_or_null("StatsPanel/VBoxContainer/CritBonusLabel")
@onready var _life_steal_label: Label = get_node_or_null("StatsPanel/VBoxContainer/LifeStealLabel")

## 技能栏节点引用（使用 get_node_or_null 避免节点不存在时报错）
@onready var _skill_bar: HBoxContainer = get_node_or_null("BottomPanel/HBoxContainer/SkillBar")

# =============================================================================
# 公共变量
# =============================================================================

var _player_ref: Node = null
var _game_time: float = 0.0

# 上一次的属性值（用于检测变化）
var _last_attack_bonus: float = 0.0
var _last_health_bonus: int = 0
var _last_speed_bonus: float = 0.0
var _last_crit_bonus: float = 0.0
var _last_life_steal: float = 0.0

## 技能槽位节点缓存
var _skill_slots: Array[Control] = []

## 技能冷却遮罩
var _cooldown_masks: Array[ColorRect] = []

## 技能图标缓存
var _skill_icons: Array[TextureRect] = []

## 技能按钮缓存
var _skill_buttons: Array[Button] = []

## 当前技能信息缓存
var _current_skills: Array[Dictionary] = []

## 连击显示节点
var _combo_label: Label = null
var _combo_timer_bar: ProgressBar = null
var _combo_count: int = 0
var _kill_streak: int = 0

func _ready() -> void:
	# 初始化属性加成显示节点（如果存在）
	_init_stats_panel()
	# 创建连击显示
	_create_combo_display()
	_update_display()

func _process(delta: float) -> void:
	if not visible:
		return
	
	_game_time += delta
	_update_display()
	_update_from_player()
	_update_skill_cooldowns()  # 更新技能冷却显示

func set_player(player: Node) -> void:
	_player_ref = player
	_update_from_player()

func update_health(current: float, maximum: float) -> void:
	if _health_label:
		_health_label.text = "HP: %d/%d" % [int(current), int(maximum)]
	if _health_bar:
		_health_bar.max_value = maximum
		_health_bar.value = current

func update_mana(current: float, maximum: float) -> void:
	if _mana_label:
		_mana_label.text = "MP: %d/%d" % [int(current), int(maximum)]
	if _mana_bar:
		_mana_bar.max_value = maximum
		_mana_bar.value = current

func update_stamina(current: float, maximum: float) -> void:
	if _stamina_label:
		_stamina_label.text = "体力: %d/%d" % [int(current), int(maximum)]
	if _stamina_bar:
		_stamina_bar.max_value = maximum
		_stamina_bar.value = current

func update_exp(current: float, maximum: float) -> void:
	if _exp_bar:
		_exp_bar.max_value = maximum
		_exp_bar.value = current
	if _exp_label:
		_exp_label.text = "EXP: %d/%d" % [int(current), int(maximum)]

func _update_display() -> void:
	if _wave_label:
		var wave := 1
		if GameManager:
			wave = GameManager.get_current_wave()
		_wave_label.text = "波次: %d" % wave
	
	if _time_label:
		var mins := int(_game_time) / 60
		var secs := int(_game_time) % 60
		_time_label.text = "时间: %02d:%02d" % [mins, secs]
	
	if _kills_label:
		var kills := 0
		if GameManager:
			kills = GameManager.get_total_kills()
		_kills_label.text = "击杀: %d" % kills


## 初始化属性加成面板节点
func _init_stats_panel() -> void:
	"""初始化属性加成面板节点（如果场景中存在）"""
	if has_node("StatsPanel"):
		_stats_panel = $StatsPanel
		if has_node("StatsPanel/VBoxContainer/AttackBonusLabel"):
			_attack_bonus_label = $StatsPanel/VBoxContainer/AttackBonusLabel
		if has_node("StatsPanel/VBoxContainer/HealthBonusLabel"):
			_health_bonus_label = $StatsPanel/VBoxContainer/HealthBonusLabel
		if has_node("StatsPanel/VBoxContainer/SpeedBonusLabel"):
			_speed_bonus_label = $StatsPanel/VBoxContainer/SpeedBonusLabel
		if has_node("StatsPanel/VBoxContainer/CritBonusLabel"):
			_crit_bonus_label = $StatsPanel/VBoxContainer/CritBonusLabel
		if has_node("StatsPanel/VBoxContainer/LifeStealLabel"):
			_life_steal_label = $StatsPanel/VBoxContainer/LifeStealLabel


func _update_from_player() -> void:
	if _player_ref == null or not is_instance_valid(_player_ref):
		return
	
	if "current_health" in _player_ref:
		update_health(_player_ref.current_health, _player_ref.max_health)
	
	if "current_mana" in _player_ref:
		update_mana(_player_ref.current_mana, _player_ref.max_mana)
	
	if "current_stamina" in _player_ref:
		update_stamina(_player_ref.current_stamina, _player_ref.max_stamina)
	
	if "current_exp" in _player_ref:
		update_exp(_player_ref.current_exp, _player_ref.exp_required)
	
	if _level_label and "level" in _player_ref:
		_level_label.text = "等级: %d" % _player_ref.level
	
	# 更新属性加成显示
	_update_stat_bonuses()


## 更新属性加成显示
func _update_stat_bonuses() -> void:
	"""更新属性加成面板的显示"""
	if _player_ref == null or not is_instance_valid(_player_ref):
		return
	
	# 获取属性加成值
	var attack_bonus: float = _player_ref.get("attack_bonus_percent") if "attack_bonus_percent" in _player_ref else 0.0
	var health_bonus: int = _player_ref.get("health_bonus") if "health_bonus" in _player_ref else 0
	var speed_bonus: float = _player_ref.get("speed_bonus_percent") if "speed_bonus_percent" in _player_ref else 0.0
	var crit_bonus: float = _player_ref.get("crit_chance_bonus") if "crit_chance_bonus" in _player_ref else 0.0
	var life_steal: float = _player_ref.get("life_steal_percent") if "life_steal_percent" in _player_ref else 0.0
	
	# 检测是否有属性变化（用于高亮显示）
	var has_change: bool = (
		attack_bonus != _last_attack_bonus or
		health_bonus != _last_health_bonus or
		speed_bonus != _last_speed_bonus or
		crit_bonus != _last_crit_bonus or
		life_steal != _last_life_steal
	)
	
	# 更新上一次的值
	_last_attack_bonus = attack_bonus
	_last_health_bonus = health_bonus
	_last_speed_bonus = speed_bonus
	_last_crit_bonus = crit_bonus
	_last_life_steal = life_steal
	
	# 更新显示标签
	if _attack_bonus_label:
		if attack_bonus > 0:
			_attack_bonus_label.text = "攻击力: +%.0f%%" % (attack_bonus * 100)
			_attack_bonus_label.modulate = Color(1.0, 0.4, 0.4)  # 红色
		else:
			_attack_bonus_label.text = "攻击力: +0%"
			_attack_bonus_label.modulate = Color(0.7, 0.7, 0.7)  # 灰色
	
	if _health_bonus_label:
		if health_bonus > 0:
			_health_bonus_label.text = "生命值: +%d" % health_bonus
			_health_bonus_label.modulate = Color(0.4, 0.9, 0.5)  # 绿色
		else:
			_health_bonus_label.text = "生命值: +0"
			_health_bonus_label.modulate = Color(0.7, 0.7, 0.7)
	
	if _speed_bonus_label:
		if speed_bonus > 0:
			_speed_bonus_label.text = "移动速度: +%.0f%%" % (speed_bonus * 100)
			_speed_bonus_label.modulate = Color(1.0, 0.9, 0.4)  # 黄色
		else:
			_speed_bonus_label.text = "移动速度: +0%"
			_speed_bonus_label.modulate = Color(0.7, 0.7, 0.7)
	
	if _crit_bonus_label:
		if crit_bonus > 0:
			_crit_bonus_label.text = "暴击率: +%.0f%%" % (crit_bonus * 100)
			_crit_bonus_label.modulate = Color(1.0, 0.7, 0.3)  # 橙色
		else:
			_crit_bonus_label.text = "暴击率: +0%"
			_crit_bonus_label.modulate = Color(0.7, 0.7, 0.7)
	
	if _life_steal_label:
		if life_steal > 0:
			_life_steal_label.text = "吸血: +%.0f%%" % (life_steal * 100)
			_life_steal_label.modulate = Color(0.7, 0.4, 0.9)  # 紫色
		else:
			_life_steal_label.text = "吸血: +0%"
			_life_steal_label.modulate = Color(0.7, 0.7, 0.7)
	
	# 如果有属性变化，播放高亮动画
	if has_change and _stats_panel:
		_play_stat_change_animation()


## 播放属性变化高亮动画
func _play_stat_change_animation() -> void:
	"""播放属性变化时的高亮动画"""
	if _stats_panel == null:
		return
	
	# 创建缩放动画
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_stats_panel, "modulate", Color(1.2, 1.2, 1.0), 0.15)
	tween.tween_property(_stats_panel, "scale", Vector2(1.05, 1.05), 0.15)
	
	# 恢复
	tween.set_parallel(false)
	tween.tween_interval(0.1)
	tween.set_parallel(true)
	tween.tween_property(_stats_panel, "modulate", Color.WHITE, 0.2)
	tween.tween_property(_stats_panel, "scale", Vector2.ONE, 0.2)


# =============================================================================
# 技能显示方法
# =============================================================================

## 初始化技能栏
func _init_skill_bar() -> void:
	"""初始化技能栏显示"""
	# 查找技能槽位
	if _skill_bar == null:
		# 尝试通过路径查找
		_skill_bar = get_node_or_null("BottomPanel/HBoxContainer/SkillBar")
		if _skill_bar == null:
			_skill_bar = get_node_or_null("BottomPanel/SkillBar")
	
	if _skill_bar == null:
		print("[HUD] 未找到技能栏节点")
		return
	
	# 缓存技能槽位
	_skill_slots.clear()
	_cooldown_masks.clear()
	_skill_icons.clear()
	_skill_buttons.clear()
	_current_skills.clear()
	
	for i in range(4):  # 最多4个技能槽
		var slot_name := "SkillSlot%d" % (i + 1)
		var slot: Control = _skill_bar.get_node_or_null(slot_name)
		
		if slot:
			_skill_slots.append(slot)
			
			# 查找图标节点
			var icon: TextureRect = slot.get_node_or_null("Icon")
			if icon:
				_skill_icons.append(icon)
			else:
				_skill_icons.append(null)
			
			# 查找按钮节点
			var btn: Button = slot.get_node_or_null("Button")
			if btn:
				_skill_buttons.append(btn)
				# 连接按钮信号
				if not btn.pressed.is_connected(_on_skill_button_pressed.bind(i)):
					btn.pressed.connect(_on_skill_button_pressed.bind(i))
			else:
				_skill_buttons.append(null)
			
			# 创建冷却遮罩
			var mask := _create_cooldown_mask(slot)
			_cooldown_masks.append(mask)
			
			# 初始化当前技能信息
			_current_skills.append({"empty": true, "slot": i + 1})
		else:
			_skill_slots.append(null)
			_skill_icons.append(null)
			_skill_buttons.append(null)
			_cooldown_masks.append(null)
			_current_skills.append({"empty": true, "slot": i + 1})
	
	print("[HUD] 技能栏初始化完成，共 %d 个槽位" % _skill_slots.size())


## 创建冷却遮罩
func _create_cooldown_mask(slot: Control) -> ColorRect:
	"""为技能槽创建冷却遮罩"""
	if slot == null:
		return null
	
	var mask := ColorRect.new()
	mask.name = "CooldownMask"
	mask.color = Color(0.0, 0.0, 0.0, 0.6)
	mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mask.set_anchors_preset(Control.PRESET_FULL_RECT)
	mask.visible = false
	slot.add_child(mask)
	
	return mask


## 更新技能显示
func update_skills(skills: Array[Dictionary]) -> void:
	"""更新技能栏显示"""
	# 确保技能栏已初始化
	if _skill_slots.is_empty():
		_init_skill_bar()
	
	if _skill_slots.is_empty():
		return
	
	# 更新每个槽位
	for i in range(_skill_slots.size()):
		var slot: Control = _skill_slots[i]
		if slot == null:
			continue
		
		var skill_info: Dictionary = skills[i] if i < skills.size() else {"empty": true, "slot": i + 1}
		_current_skills[i] = skill_info
		
		var icon: TextureRect = _skill_icons[i]
		var btn: Button = _skill_buttons[i]
		
		if skill_info.get("empty", true):
			# 空槽位
			if icon:
				icon.texture = null
				icon.modulate = Color(0.3, 0.3, 0.3, 0.5)
			if btn:
				btn.disabled = true
			slot.modulate = Color(0.5, 0.5, 0.5)
		else:
			# 有技能
			if icon:
				# 设置技能图标
				var icon_texture = _get_skill_icon(skill_info.get("id", ""))
				if icon_texture:
					icon.texture = icon_texture
				else:
					# 使用默认颜色块
					icon.texture = _create_default_skill_icon(skill_info)
				icon.modulate = Color.WHITE
			
			if btn:
				btn.disabled = false
			
			slot.modulate = Color.WHITE


## 更新技能冷却显示
func update_skill_cooldown(slot_index: int, cooldown_progress: float, is_on_cooldown: bool) -> void:
	"""更新单个技能的冷却显示"""
	if slot_index < 0 or slot_index >= _cooldown_masks.size():
		return
	
	var mask: ColorRect = _cooldown_masks[slot_index]
	if mask == null:
		return
	
	if is_on_cooldown:
		mask.visible = true
		# 根据冷却进度调整遮罩高度
		var height_percent := 1.0 - cooldown_progress
		mask.anchor_top = 0.0
		mask.anchor_bottom = height_percent
		mask.offset_top = 0
		mask.offset_bottom = 0
	else:
		mask.visible = false


## 获取技能图标
func _get_skill_icon(skill_id: String) -> Texture2D:
	"""根据技能ID获取图标"""
	var icon_path := "res://assets/icons/skills/%s.png" % skill_id
	if ResourceLoader.exists(icon_path):
		return load(icon_path)
	return null


## 创建默认技能图标
func _create_default_skill_icon(skill_info: Dictionary) -> Texture2D:
	"""为没有图标的技能创建默认图标"""
	var image := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	
	# 根据元素类型选择颜色
	var color := _get_element_color(skill_info.get("element", "PHYSICAL"))
	image.fill(color)
	
	var texture := ImageTexture.new()
	texture.set_image(image)
	return texture


## 获取元素颜色
func _get_element_color(element: String) -> Color:
	"""根据元素类型返回颜色"""
	match element:
		"FIRE": return Color(1.0, 0.4, 0.2)
		"ICE": return Color(0.4, 0.8, 1.0)
		"LIGHTNING": return Color(1.0, 1.0, 0.4)
		"SHADOW": return Color(0.5, 0.3, 0.8)
		"HOLY": return Color(1.0, 1.0, 0.8)
		"ARCANE": return Color(0.7, 0.4, 1.0)
		"PHYSICAL": return Color(0.7, 0.7, 0.7)
		_: return Color(0.5, 0.5, 0.5)


## 技能按钮点击回调
func _on_skill_button_pressed(slot: int) -> void:
	"""技能按钮被点击"""
	skill_button_pressed.emit(slot)
	print("[HUD] 技能槽 %d 被点击" % (slot + 1))


## 设置玩家并连接技能信号
func set_player_with_skills(player: Node) -> void:
	"""设置玩家引用并连接技能变化信号"""
	set_player(player)
	
	if player == null:
		return
	
	# 初始化技能栏
	_init_skill_bar()
	
	# 连接技能变化信号
	if player.has_signal("skills_changed"):
		if not player.skills_changed.is_connected(_on_player_skills_changed):
			player.skills_changed.connect(_on_player_skills_changed)
	
	# 初始更新技能显示
	if player.has_method("get_hotkey_skills"):
		var skills = player.get_hotkey_skills()
		update_skills(skills)


## 玩家技能变化回调
func _on_player_skills_changed() -> void:
	"""玩家技能变化时的回调"""
	if _player_ref == null or not is_instance_valid(_player_ref):
		return
	
	if _player_ref.has_method("get_hotkey_skills"):
		var skills = _player_ref.get_hotkey_skills()
		update_skills(skills)


## 每帧更新技能冷却
func _update_skill_cooldowns() -> void:
	"""更新所有技能的冷却显示"""
	if _player_ref == null or not is_instance_valid(_player_ref):
		return
	
	# 获取技能管理器
	var sm = _player_ref.get("skill_manager")
	if sm == null:
		return
	
	# 更新每个槽位的冷却
	for i in range(_current_skills.size()):
		var skill_info: Dictionary = _current_skills[i]
		if skill_info.get("empty", true):
			continue
		
		var skill_id: String = skill_info.get("id", "")
		if skill_id.is_empty():
			continue
		
		# 获取技能实例
		var skill = null
		if sm.has_method("get_skill"):
			skill = sm.get_skill(skill_id)
		
		if skill == null:
			continue
		
		# 获取冷却信息
		var is_on_cooldown: bool = false
		var cooldown_progress: float = 1.0
		
		if "is_on_cooldown" in skill:
			is_on_cooldown = skill.is_on_cooldown
		if "get_cooldown_progress" in skill:
			cooldown_progress = skill.get_cooldown_progress()
		
		update_skill_cooldown(i, cooldown_progress, is_on_cooldown)

	# =============================================================================
	# 连击显示方法
	# =============================================================================

	func _create_combo_display() -> void:
		"""创建连击显示UI"""
		# 创建连击标签
		_combo_label = Label.new()
		_combo_label.name = "ComboLabel"
		_combo_label.text = ""
		_combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_combo_label.add_theme_font_size_override("font_size", 32)
		_combo_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
		_combo_label.add_theme_color_override("font_outline_color", Color(0.2, 0.1, 0.0))
		_combo_label.add_theme_constant_override("outline_size", 3)

		# 设置位置（屏幕顶部中央）
		_combo_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
		_combo_label.offset_top = 80
		_combo_label.offset_left = -100
		_combo_label.offset_right = 100

		add_child(_combo_label)

		# 创建连击计时器条
		_combo_timer_bar = ProgressBar.new()
		_combo_timer_bar.name = "ComboTimerBar"
		_combo_timer_bar.custom_minimum_size = Vector2(150, 6)
		_combo_timer_bar.value = 0
		_combo_timer_bar.max_value = 100

		# 设置位置
		_combo_timer_bar.set_anchors_preset(Control.PRESET_CENTER_TOP)
		_combo_timer_bar.offset_top = 120
		_combo_timer_bar.offset_left = -75
		_combo_timer_bar.offset_right = 75

		add_child(_combo_timer_bar)


	func update_combo(combo_count: int, kill_streak: int = 0) -> void:
		"""更新连击显示"""
		_combo_count = combo_count
		_kill_streak = kill_streak

		if _combo_label == null:
			return

		if combo_count > 0:
			var text: String = "%d COMBO" % combo_count
			if kill_streak > 3:
				text += " | 连杀 x%d" % kill_streak

			_combo_label.text = text

			# 根据连击数改变颜色和大小
			if combo_count >= 50:
				_combo_label.add_theme_font_size_override("font_size", 48)
				_combo_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
			elif combo_count >= 30:
				_combo_label.add_theme_font_size_override("font_size", 40)
				_combo_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.2))
			elif combo_count >= 10:
				_combo_label.add_theme_font_size_override("font_size", 36)
				_combo_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
			else:
				_combo_label.add_theme_font_size_override("font_size", 32)
				_combo_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))

			# 播放缩放动画
			_play_combo_animation()
		else:
			_combo_label.text = ""


	func update_combo_timer(remaining: float, max_time: float) -> void:
		"""更新连击计时器"""
		if _combo_timer_bar == null:
			return

		if max_time > 0 and remaining > 0:
			_combo_timer_bar.value = (remaining / max_time) * 100
			_combo_timer_bar.visible = true
		else:
			_combo_timer_bar.visible = false


	func show_rage_mode(active: bool) -> void:
		"""显示暴走模式"""
		if _combo_label == null:
			return

		if active:
			_combo_label.text = "★ RAGE MODE ★"
			_combo_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.5))
			_play_rage_animation()


	func _play_combo_animation() -> void:
		"""播放连击动画"""
		if _combo_label == null:
			return

		var tween := create_tween()
		_combo_label.scale = Vector2(1.3, 1.3)
		tween.tween_property(_combo_label, "scale", Vector2.ONE, 0.15)


	func _play_rage_animation() -> void:
		"""播放暴走动画"""
		if _combo_label == null:
			return

		var tween := create_tween()
		tween.set_loops()
		tween.tween_property(_combo_label, "modulate", Color(1.5, 0.5, 0.8), 0.3)
		tween.tween_property(_combo_label, "modulate", Color(1.0, 1.0, 1.0), 0.3)
