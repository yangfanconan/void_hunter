extends Control
class_name SkillSelection

signal skill_selected(skill_id: String)
signal selection_skipped()
signal combination_selected(combination_id: String)

const OPTION_COUNT: int = 3
const SKILL_ICONS_PATH: String = "res://assets/icons/skills/"

var available_skills: Array[Dictionary] = []
var current_options: Array[Dictionary] = []
var skill_manager: Node = null
var combination_hints: Array[Dictionary] = []
var _option_panels: Array[Control] = []
var _is_combination_mode: bool = false
var _bg: ColorRect
var _panel: PanelContainer
var _title_label: Label
var _option_container: HBoxContainer
var _button_skip: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	hide()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("skill_1"):
		if _option_panels.size() > 0 and _option_panels[0].visible:
			_on_option_selected(0)
	elif event.is_action_pressed("skill_2"):
		if _option_panels.size() > 1 and _option_panels[1].visible:
			_on_option_selected(1)
	elif event.is_action_pressed("skill_3"):
		if _option_panels.size() > 2 and _option_panels[2].visible:
			_on_option_selected(2)
	elif event.is_action_pressed("ui_cancel"):
		_on_skip_pressed()

func _build_ui() -> void:
	_bg = ColorRect.new()
	_bg.color = Color(0, 0, 0, 0.7)
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(700, 440)
	_panel.anchor_left = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -350
	_panel.offset_top = -220
	_panel.offset_right = 350
	_panel.offset_bottom = 220
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.15, 0.97)
	panel_style.border_color = Color(0.4, 0.35, 0.6)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(12)
	_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	_title_label = Label.new()
	_title_label.text = "选择技能升级"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 22)
	_title_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.75))
	vbox.add_child(_title_label)

	var sep1 := HSeparator.new()
	vbox.add_child(sep1)

	_option_container = HBoxContainer.new()
	_option_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_option_container.add_theme_constant_override("separation", 16)
	vbox.add_child(_option_container)

	var sep2 := HSeparator.new()
	vbox.add_child(sep2)

	_button_skip = Button.new()
	_button_skip.text = "跳过"
	_button_skip.custom_minimum_size = Vector2(120, 40)
	vbox.add_child(_button_skip)
	_button_skip.pressed.connect(_on_skip_pressed)

	var hotkey_hint := Label.new()
	hotkey_hint.text = "快捷键: [1] [2] [3] 选择  |  [ESC] 跳过"
	hotkey_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hotkey_hint.modulate = Color(0.5, 0.5, 0.5)
	hotkey_hint.add_theme_font_size_override("font_size", 12)
	vbox.add_child(hotkey_hint)

func _ensure_panels() -> void:
	while _option_panels.size() < OPTION_COUNT:
		var idx := _option_panels.size()
		var p := _create_option_panel(idx)
		_option_container.add_child(p)
		_option_panels.append(p)

func show_skill_selection(skills: Array[Dictionary] = []) -> void:
	_is_combination_mode = false
	GameManager.set_game_state(GameManager.GameState.SKILL_SELECTION)
	get_tree().paused = true

	if skills.is_empty():
		current_options = _generate_random_options()
	else:
		current_options = skills

	_ensure_panels()
	_update_options_display()
	title_label_set("选择技能升级")
	show()

func show_combination_selection(combinations: Array[Dictionary]) -> void:
	_is_combination_mode = true
	GameManager.set_game_state(GameManager.GameState.SKILL_SELECTION)
	get_tree().paused = true
	current_options = combinations
	_ensure_panels()
	_update_options_display(true)
	title_label_set("选择组合技能")
	show()

func hide_skill_selection() -> void:
	hide()
	get_tree().paused = false
	GameManager.set_game_state(GameManager.GameState.PLAYING)

func set_available_skills(skills: Array[Dictionary]) -> void:
	available_skills = skills

func set_skill_manager(manager: Node) -> void:
	skill_manager = manager

func title_label_set(text: String) -> void:
	if _title_label:
		_title_label.text = text

func _create_option_panel(index: int) -> Control:
	var panel_node := PanelContainer.new()
	panel_node.custom_minimum_size = Vector2(210, 340)
	panel_node.name = "OptionPanel_%d" % index
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.22, 0.95)
	style.border_color = Color(0.35, 0.35, 0.5)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	panel_node.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel_node.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var hotkey_label := Label.new()
	hotkey_label.name = "HotkeyLabel"
	hotkey_label.text = "[%d]" % (index + 1)
	hotkey_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hotkey_label.add_theme_font_size_override("font_size", 14)
	hotkey_label.modulate = Color(0.6, 0.6, 0.7)
	vbox.add_child(hotkey_label)

	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(64, 64)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	vbox.add_child(icon)

	var name_label := Label.new()
	name_label.name = "NameLabel"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.75))
	vbox.add_child(name_label)

	var level_label := Label.new()
	level_label.name = "LevelLabel"
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", 13)
	level_label.modulate = Color(0.5, 0.75, 1.0)
	vbox.add_child(level_label)

	var type_container := HBoxContainer.new()
	type_container.name = "TypeContainer"
	type_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(type_container)

	var category_label := Label.new()
	category_label.name = "CategoryLabel"
	category_label.add_theme_font_size_override("font_size", 11)
	type_container.add_child(category_label)

	var element_label := Label.new()
	element_label.name = "ElementLabel"
	element_label.add_theme_font_size_override("font_size", 11)
	type_container.add_child(element_label)

	var desc_label := Label.new()
	desc_label.name = "DescLabel"
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	vbox.add_child(desc_label)

	var stats_label := Label.new()
	stats_label.name = "StatsLabel"
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	stats_label.add_theme_font_size_override("font_size", 11)
	stats_label.modulate = Color(0.6, 0.9, 0.6)
	vbox.add_child(stats_label)

	var button := Button.new()
	button.name = "SelectButton"
	button.text = "选择"
	button.custom_minimum_size.y = 36
	button.pressed.connect(_on_option_selected.bind(index))
	vbox.add_child(button)

	return panel_node

func _generate_random_options() -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	if available_skills.is_empty():
		available_skills = _get_default_skills()

	var new_skills: Array[Dictionary] = []
	var upgrade_skills: Array[Dictionary] = []
	for skill in available_skills:
		if skill.get("is_owned", false):
			upgrade_skills.append(skill)
		else:
			new_skills.append(skill)

	new_skills.shuffle()
	upgrade_skills.shuffle()

	var new_count: int = mini(2, new_skills.size())
	for i in range(new_count):
		options.append(new_skills[i])

	while options.size() < OPTION_COUNT and upgrade_skills.size() > 0:
		var idx: int = options.size() - new_count
		if idx >= 0 and idx < upgrade_skills.size():
			options.append(upgrade_skills[idx])
		else:
			break

	while options.size() < OPTION_COUNT and options.size() < new_skills.size():
		options.append(new_skills[options.size()])

	while options.size() < OPTION_COUNT:
		options.append({})

	return options

func _get_default_skills() -> Array[Dictionary]:
	return [
		{"id": "fire_bullet", "name": "火焰弹", "description": "发射火焰弹，造成燃烧伤害。", "type": "ACTIVE", "category": "OFFENSIVE", "element": "FIRE", "damage": 25, "cooldown": 2.5, "mana_cost": 15, "is_owned": false},
		{"id": "frost_arrow", "name": "冰霜箭", "description": "发射冰霜箭，减速敌人。", "type": "ACTIVE", "category": "OFFENSIVE", "element": "ICE", "damage": 20, "cooldown": 3.0, "mana_cost": 18, "is_owned": false},
		{"id": "lightning_chain", "name": "闪电链", "description": "连锁攻击多个敌人。", "type": "ACTIVE", "category": "OFFENSIVE", "element": "LIGHTNING", "damage": 30, "cooldown": 4.0, "mana_cost": 25, "is_owned": false},
		{"id": "shadow_slash", "name": "暗影斩", "description": "穿透敌人的暗影刃。", "type": "ACTIVE", "category": "OFFENSIVE", "element": "SHADOW", "damage": 35, "cooldown": 3.5, "mana_cost": 22, "is_owned": false},
		{"id": "shield", "name": "魔法护盾", "description": "生成临时护盾。", "type": "ACTIVE", "category": "DEFENSIVE", "element": "ARCANE", "cooldown": 12.0, "mana_cost": 30, "is_owned": false},
		{"id": "blink", "name": "闪现", "description": "瞬移到目标位置。", "type": "ACTIVE", "category": "DEFENSIVE", "element": "ARCANE", "cooldown": 8.0, "mana_cost": 20, "is_owned": false},
		{"id": "iron_wall", "name": "铁壁", "description": "短时间大幅提升防御。", "type": "ACTIVE", "category": "DEFENSIVE", "element": "PHYSICAL", "cooldown": 15.0, "mana_cost": 35, "is_owned": false},
		{"id": "reflect", "name": "反射", "description": "反弹敌人子弹。", "type": "ACTIVE", "category": "DEFENSIVE", "element": "ARCANE", "cooldown": 12.0, "mana_cost": 25, "is_owned": false},
		{"id": "time_slow", "name": "时间减缓", "description": "减缓周围敌人速度。", "type": "ACTIVE", "category": "CONTROL", "element": "ARCANE", "cooldown": 18.0, "mana_cost": 40, "is_owned": false},
		{"id": "gravity_field", "name": "引力场", "description": "将敌人吸向中心。", "type": "ACTIVE", "category": "CONTROL", "element": "ARCANE", "cooldown": 14.0, "mana_cost": 35, "is_owned": false},
		{"id": "healing_aura", "name": "治愈光环", "description": "持续恢复生命。", "type": "PASSIVE", "category": "SUPPORT", "element": "HOLY", "is_owned": false},
		{"id": "speed_aura", "name": "加速光环", "description": "提升移动和攻击速度。", "type": "PASSIVE", "category": "SUPPORT", "element": "HOLY", "is_owned": false}
	]

func _update_options_display(is_combination: bool = false) -> void:
	for i in range(_option_panels.size()):
		var panel_node: Control = _option_panels[i]
		var option: Dictionary = current_options[i] if i < current_options.size() else {}
		if is_combination:
			_update_combination_panel(panel_node, option)
		else:
			_update_option_panel(panel_node, option)

func _update_option_panel(panel_node: Control, option: Dictionary) -> void:
	var name_label: Label = panel_node.find_child("NameLabel", true, false)
	var level_label: Label = panel_node.find_child("LevelLabel", true, false)
	var category_label: Label = panel_node.find_child("CategoryLabel", true, false)
	var element_label: Label = panel_node.find_child("ElementLabel", true, false)
	var desc_label: Label = panel_node.find_child("DescLabel", true, false)
	var stats_label: Label = panel_node.find_child("StatsLabel", true, false)
	var button: Button = panel_node.find_child("SelectButton", true, false)
	var icon_rect: TextureRect = panel_node.find_child("Icon", true, false)

	if option.is_empty():
		panel_node.hide()
		return

	panel_node.show()

	# 加载技能图标
	if icon_rect:
		var skill_id: String = option.get("id", "")
		var icon_path: String = SKILL_ICONS_PATH + skill_id + ".png"
		if ResourceLoader.exists(icon_path):
			icon_rect.texture = load(icon_path)
		else:
			# 使用默认图标或生成占位图标
			icon_rect.texture = _generate_placeholder_icon(option)

	if name_label:
		name_label.text = option.get("name", "???")
	if level_label:
		if option.get("is_owned", false):
			level_label.text = "Lv.%d -> Lv.%d" % [int(option.get("level", 1)), int(option.get("level", 1)) + 1]
		else:
			level_label.text = "新技能"
	if category_label:
		category_label.text = _get_category_display_name(option.get("category", ""))
	if element_label:
		element_label.text = _get_element_display_name(option.get("element", ""))
	if desc_label:
		desc_label.text = option.get("description", "")
	if stats_label:
		var t := ""
		if option.has("damage"): t += "伤害:%d  " % int(option["damage"])
		if option.has("cooldown"): t += "冷却:%.1fs  " % float(option["cooldown"])
		if option.has("mana_cost"): t += "法力:%d" % int(option["mana_cost"])
		stats_label.text = t
	if button:
		button.disabled = false
		button.text = "升级" if option.get("is_owned", false) else "选择"


func _generate_placeholder_icon(option: Dictionary) -> ImageTexture:
	"""生成占位图标，根据元素类型显示不同颜色"""
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var element: String = option.get("element", "NONE")

	# 根据元素选择颜色
	var color: Color
	match element:
		"FIRE": color = Color(1.0, 0.3, 0.1, 0.8)
		"ICE": color = Color(0.3, 0.7, 1.0, 0.8)
		"LIGHTNING": color = Color(1.0, 1.0, 0.2, 0.8)
		"SHADOW": color = Color(0.4, 0.2, 0.6, 0.8)
		"HOLY": color = Color(1.0, 1.0, 0.8, 0.8)
		"ARCANE": color = Color(0.6, 0.3, 0.9, 0.8)
		"VOID": color = Color(0.3, 0.0, 0.5, 0.8)
		"PHYSICAL": color = Color(0.6, 0.5, 0.4, 0.8)
		_: color = Color(0.5, 0.5, 0.5, 0.8)

	# 绘制圆形背景
	var center := Vector2(32, 32)
	for y in range(64):
		for x in range(64):
			var dist := Vector2(x, y).distance_to(center)
			if dist <= 28:
				img.set_pixel(x, y, color)
			elif dist <= 30:
				img.set_pixel(x, y, Color(color.r, color.g, color.b, 0.5))
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))

	return ImageTexture.create_from_image(img)

func _update_combination_panel(panel_node: Control, option: Dictionary) -> void:
	var name_label: Label = panel_node.find_child("NameLabel", true, false)
	var level_label: Label = panel_node.find_child("LevelLabel", true, false)
	var desc_label: Label = panel_node.find_child("DescLabel", true, false)
	var button: Button = panel_node.find_child("SelectButton", true, false)
	var icon_rect: TextureRect = panel_node.find_child("Icon", true, false)

	if option.is_empty():
		panel_node.hide()
		return

	panel_node.show()

	# 加载组合技能图标
	if icon_rect:
		var combo_id: String = option.get("id", "")
		var icon_path: String = SKILL_ICONS_PATH + combo_id + ".png"
		if ResourceLoader.exists(icon_path):
			icon_rect.texture = load(icon_path)
		else:
			# 组合技能使用特殊颜色
			var combo_color := Color(0.8, 0.5, 0.9, 0.8)
			icon_rect.texture = _generate_placeholder_icon({"element": "ARCANE"})

	if name_label: name_label.text = option.get("name", "???")
	if level_label: level_label.text = "组合技能"
	if desc_label: desc_label.text = option.get("description", "")
	if button:
		button.disabled = false
		button.text = "激活"

func _get_category_display_name(category: String) -> String:
	match category:
		"OFFENSIVE": return "攻击"
		"DEFENSIVE": return "防御"
		"CONTROL": return "控制"
		"SUPPORT": return "辅助"
		_: return category

func _get_element_display_name(element: String) -> String:
	match element:
		"FIRE": return "火焰"
		"ICE": return "冰霜"
		"LIGHTNING": return "闪电"
		"SHADOW": return "暗影"
		"HOLY": return "神圣"
		"ARCANE": return "奥术"
		"PHYSICAL": return "物理"
		_: return element

func _on_option_selected(index: int) -> void:
	if index < 0 or index >= current_options.size():
		return
	var selected_option: Dictionary = current_options[index]
	if selected_option.is_empty():
		return
	if _is_combination_mode:
		combination_selected.emit(selected_option.get("combination_id", ""))
	else:
		skill_selected.emit(selected_option.get("id", ""))
	hide_skill_selection()

func _on_skip_pressed() -> void:
	selection_skipped.emit()
	hide_skill_selection()
