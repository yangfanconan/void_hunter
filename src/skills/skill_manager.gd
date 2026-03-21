## Void Hunter - 技能管理器
## @description: 管理玩家的技能系统，包括技能获取、升级、使用和组合
## @author: Void Hunter Team
## @version: 1.0.0

extends Node
class_name SkillManager

# =============================================================================
# 信号定义
# =============================================================================

## 技能获得时触发
signal skill_acquired(skill: SkillBase)

## 技能移除时触发
signal skill_removed(skill_id: String)

## 技能升级时触发
signal skill_leveled_up(skill: SkillBase, new_level: int)

## 技能使用时触发
signal skill_used(skill: SkillBase)

## 组合激活时触发
signal combination_activated(combination_id: String, combination_data: Dictionary)

## 快捷键栏改变时触发
signal hotkey_bar_changed(slot: int, skill: SkillBase)

# =============================================================================
# 常量定义
# =============================================================================

## 快捷键栏位数量
const HOTKEY_SLOTS: int = 4

## 技能宝石场景路径
const SKILL_GEM_SCENE: String = "res://scenes/items/skill_gem.tscn"

# =============================================================================
# 导出变量
# =============================================================================

## 技能持有者
@export var owner: Node

## 技能组合系统
@export var combinations: SkillCombinations

# =============================================================================
# 公共变量
# =============================================================================

## 所有可用技能定义
var all_skills: Dictionary = {}

## 玩家拥有的技能
var owned_skills: Dictionary = {}

## 快捷键栏
var hotkey_bar: Array[SkillBase] = []

## 技能组合系统实例
var skill_combinations: SkillCombinations = null

# =============================================================================
# 私有变量
# =============================================================================

var _is_initialized: bool = false

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""
	节点就绪时初始化
	"""
	if owner == null:
		owner = get_parent()
	
	initialize(owner)


func _process(delta: float) -> void:
	"""
	每帧更新
	"""
	# 更新所有技能的冷却和持续效果
	for skill_id in owned_skills.keys():
		var skill: SkillBase = owned_skills[skill_id]
		if skill:
			skill.update(delta)


func _input(event: InputEvent) -> void:
	"""
	处理输入事件
	"""
	# 处理快捷键技能使用
	for i in range(HOTKEY_SLOTS):
		if event.is_action_pressed("skill_%d" % (i + 1)):
			use_hotkey_skill(i)
			return
	
	# 处理技能选择界面
	if event.is_action_pressed("skill_menu"):
		toggle_skill_menu()


# =============================================================================
# 初始化方法
# =============================================================================

## 初始化技能管理器
func initialize(skill_owner: Node) -> void:
	"""
	初始化技能管理器
	@param skill_owner: 技能持有者
	"""
	if _is_initialized:
		return
	
	owner = skill_owner
	
	# 初始化快捷键栏
	_init_hotkey_bar()
	
	# 加载所有技能定义
	_load_all_skills()
	
	# 初始化技能组合系统
	_init_combinations()
	
	_is_initialized = true


func _init_hotkey_bar() -> void:
	"""
	初始化快捷键栏
	"""
	hotkey_bar.clear()
	for i in range(HOTKEY_SLOTS):
		hotkey_bar.append(null)


func _load_all_skills() -> void:
	"""
	加载所有技能定义
	"""
	# 加载所有技能类
	all_skills = {
		# 攻击类
		"fire_bullet": _create_skill_instance("SkillFireBullet"),
		"frost_arrow": _create_skill_instance("SkillFrostArrow"),
		"lightning_chain": _create_skill_instance("SkillLightningChain"),
		"shadow_slash": _create_skill_instance("SkillShadowSlash"),
		
		# 防御类
		"shield": _create_skill_instance("SkillShield"),
		"blink": _create_skill_instance("SkillBlink"),
		"iron_wall": _create_skill_instance("SkillIronWall"),
		"reflect": _create_skill_instance("SkillReflect"),
		
		# 控制类
		"time_slow": _create_skill_instance("SkillTimeSlow"),
		"gravity_field": _create_skill_instance("SkillGravityField"),
		
		# 辅助类
		"healing_aura": _create_skill_instance("SkillHealingAura"),
		"speed_aura": _create_skill_instance("SkillSpeedAura")
	}


func _create_skill_instance(class_name_str: String) -> SkillBase:
	"""
	创建技能实例
	@param class_name_str: 技能类名
	@return: 技能实例
	"""
	var script_path: String = ""
	
	match class_name_str:
		"SkillFireBullet":
			script_path = "res://src/skills/skills/offensive/fire_bullet.gd"
		"SkillFrostArrow":
			script_path = "res://src/skills/skills/offensive/frost_arrow.gd"
		"SkillLightningChain":
			script_path = "res://src/skills/skills/offensive/lightning_chain.gd"
		"SkillShadowSlash":
			script_path = "res://src/skills/skills/offensive/shadow_slash.gd"
		"SkillShield":
			script_path = "res://src/skills/skills/defensive/shield.gd"
		"SkillBlink":
			script_path = "res://src/skills/skills/defensive/blink.gd"
		"SkillIronWall":
			script_path = "res://src/skills/skills/defensive/iron_wall.gd"
		"SkillReflect":
			script_path = "res://src/skills/skills/defensive/reflect.gd"
		"SkillTimeSlow":
			script_path = "res://src/skills/skills/control/time_slow.gd"
		"SkillGravityField":
			script_path = "res://src/skills/skills/control/gravity_field.gd"
		"SkillHealingAura":
			script_path = "res://src/skills/skills/support/healing_aura.gd"
		"SkillSpeedAura":
			script_path = "res://src/skills/skills/support/speed_aura.gd"
	
	if script_path.is_empty():
		return null
	
	var script: Resource = load(script_path)
	if script == null:
		return null
	
	var skill: SkillBase = script.new()
	return skill


func _init_combinations() -> void:
	"""
	初始化技能组合系统
	"""
	skill_combinations = SkillCombinations.new()
	skill_combinations.initialize(owner)
	
	# 连接信号
	skill_combinations.combination_activated.connect(_on_combination_activated)


# =============================================================================
# 技能获取与管理
# =============================================================================

## 获得技能
func acquire_skill(skill_id: String, level: int = 1) -> bool:
	"""
	获得技能
	@param skill_id: 技能ID
	@param level: 初始等级
	@return: 是否成功获得
	"""
	if skill_id in owned_skills:
		# 已经拥有该技能，尝试升级
		return upgrade_skill(skill_id)
	
	# 获取技能模板
	var template: SkillBase = all_skills.get(skill_id)
	if template == null:
		return false
	
	# 创建新技能实例
	var new_skill: SkillBase = template.duplicate()
	new_skill.initialize(owner)
	new_skill.unlock()
	
	# 设置等级
	for i in range(level - 1):
		new_skill.upgrade()
	
	# 添加到拥有列表
	owned_skills[skill_id] = new_skill
	
	# 添加到组合系统
	skill_combinations.add_skill(skill_id)
	
	# 连接信号
	new_skill.skill_upgraded.connect(_on_skill_upgraded)
	
	skill_acquired.emit(new_skill)
	
	# 播放音效
	AudioManager.play_sfx("skill_acquire")
	
	return true


## 移除技能
func remove_skill(skill_id: String) -> bool:
	"""
	移除技能
	@param skill_id: 技能ID
	@return: 是否成功移除
	"""
	if skill_id not in owned_skills:
		return false
	
	# 从快捷键栏移除
	var skill: SkillBase = owned_skills[skill_id]
	for i in range(HOTKEY_SLOTS):
		if hotkey_bar[i] == skill:
			set_hotkey_slot(i, null)
	
	# 从拥有列表移除
	owned_skills.erase(skill_id)
	
	# 从组合系统移除
	skill_combinations.remove_skill(skill_id)
	
	skill_removed.emit(skill_id)
	
	return true


## 升级技能
func upgrade_skill(skill_id: String) -> bool:
	"""
	升级技能
	@param skill_id: 技能ID
	@return: 是否成功升级
	"""
	if skill_id not in owned_skills:
		return false
	
	var skill: SkillBase = owned_skills[skill_id]
	var success: bool = skill.upgrade()
	
	if success:
		AudioManager.play_sfx("skill_upgrade")
	
	return success


## 通过宝石升级技能
func upgrade_skill_with_gem(skill_id: String) -> bool:
	"""
	通过拾取技能宝石升级技能
	@param skill_id: 技能ID
	@return: 是否成功升级
	"""
	return upgrade_skill(skill_id)


# =============================================================================
# 技能使用
# =============================================================================

## 使用技能
func use_skill(skill_id: String, target_position: Vector2 = Vector2.ZERO, target_node: Node = null) -> bool:
	"""
	使用技能
	@param skill_id: 技能ID
	@param target_position: 目标位置
	@param target_node: 目标节点
	@return: 是否成功使用
	"""
	if skill_id not in owned_skills:
		return false
	
	var skill: SkillBase = owned_skills[skill_id]
	
	if not skill.can_activate():
		return false
	
	var success: bool = skill.activate(target_position, target_node)
	
	if success:
		skill_used.emit(skill)
		
		# 记录技能使用（用于组合检测）
		skill_combinations.record_skill_use(skill_id)
		
		# 播放音效
		AudioManager.play_sfx("skill_use")
	
	return success


## 使用快捷键技能
func use_hotkey_skill(slot: int) -> bool:
	"""
	使用快捷键栏技能
	@param slot: 快捷键栏位（0-3）
	@return: 是否成功使用
	"""
	if slot < 0 or slot >= HOTKEY_SLOTS:
		return false
	
	var skill: SkillBase = hotkey_bar[slot]
	if skill == null:
		return false
	
	# 获取目标位置（鼠标位置）
	var target_position: Vector2 = _get_mouse_position()
	
	return use_skill(skill.skill_id, target_position)


## 获取鼠标位置（世界坐标）
func _get_mouse_position() -> Vector2:
	"""
	获取鼠标在世界中的位置
	@return: 世界坐标
	"""
	if owner == null:
		return Vector2.ZERO
	
	var camera: Camera2D = owner.get_viewport().get_camera_2d()
	if camera == null:
		return owner.get_global_mouse_position()
	
	return owner.get_global_mouse_position()


# =============================================================================
# 快捷键栏管理
# =============================================================================

## 设置快捷键栏位
func set_hotkey_slot(slot: int, skill: SkillBase) -> bool:
	"""
	设置快捷键栏位
	@param slot: 栏位（0-3）
	@param skill: 技能（null表示清空）
	@return: 是否成功设置
	"""
	if slot < 0 or slot >= HOTKEY_SLOTS:
		return false
	
	# 如果技能不为空，检查是否拥有该技能
	if skill != null and skill.skill_id not in owned_skills:
		return false
	
	hotkey_bar[slot] = skill
	
	# 更新技能的快捷键绑定
	if skill:
		skill.hotkey_slot = slot + 1
	
	hotkey_bar_changed.emit(slot, skill)
	
	return true


## 获取快捷键栏位技能
func get_hotkey_skill(slot: int) -> SkillBase:
	"""
	获取快捷键栏位技能
	@param slot: 栏位（0-3）
	@return: 技能实例
	"""
	if slot < 0 or slot >= HOTKEY_SLOTS:
		return null
	
	return hotkey_bar[slot]


## 自动填充快捷键栏
func auto_fill_hotkey_bar() -> void:
	"""
	自动填充快捷键栏
	"""
	var slot: int = 0
	for skill_id in owned_skills.keys():
		if slot >= HOTKEY_SLOTS:
			break
		
		var skill: SkillBase = owned_skills[skill_id]
		if skill.skill_type == SkillBase.SkillType.ACTIVE:
			# 只自动填充主动技能
			if hotkey_bar[slot] == null:
				set_hotkey_slot(slot, skill)
			slot += 1


# =============================================================================
# 技能查询
# =============================================================================

## 获取技能
func get_skill(skill_id: String) -> SkillBase:
	"""
	获取技能实例
	@param skill_id: 技能ID
	@return: 技能实例
	"""
	return owned_skills.get(skill_id)


## 检查是否拥有技能
func has_skill(skill_id: String) -> bool:
	"""
	检查是否拥有技能
	@param skill_id: 技能ID
	@return: 是否拥有
	"""
	return skill_id in owned_skills


## 获取所有拥有的技能
func get_all_owned_skills() -> Dictionary:
	"""
	获取所有拥有的技能
	@return: 技能字典
	"""
	return owned_skills.duplicate()


## 获取技能信息列表
func get_skill_info_list() -> Array[Dictionary]:
	"""
	获取所有技能信息列表
	@return: 技能信息数组
	"""
	var list: Array[Dictionary] = []
	
	for skill_id in owned_skills.keys():
		var skill: SkillBase = owned_skills[skill_id]
		if skill:
			list.append(skill.get_skill_info())
	
	return list


## 获取可用技能（用于技能选择界面）
func get_available_skills() -> Array[Dictionary]:
	"""
	获取可用技能（未拥有的技能）
	@return: 可用技能数组
	"""
	var available: Array[Dictionary] = []
	
	for skill_id in all_skills.keys():
		if skill_id not in owned_skills:
			var skill: SkillBase = all_skills[skill_id]
			if skill:
				available.append(skill.get_skill_info())
	
	return available


# =============================================================================
# 技能菜单
# =============================================================================

## 切换技能菜单
func toggle_skill_menu() -> void:
	"""
	切换技能选择菜单
	"""
	var skill_selection: SkillSelection = _get_skill_selection_ui()
	if skill_selection == null:
		return
	
	if skill_selection.visible:
		skill_selection.hide_skill_selection()
	else:
		# 显示技能选择界面
		var skills: Array[Dictionary] = _generate_skill_options()
		skill_selection.show_skill_selection(skills)


func _get_skill_selection_ui() -> SkillSelection:
	"""
	获取技能选择UI
	"""
	if owner == null:
		return null
	
	var ui: Node = owner.get_tree().current_scene.find_child("SkillSelection", true, false)
	if ui is SkillSelection:
		return ui
	
	return null


func _generate_skill_options() -> Array[Dictionary]:
	"""
	生成技能选项（升级时显示）
	"""
	var options: Array[Dictionary] = []
	
	# 获取未拥有的技能
	var available: Array[Dictionary] = get_available_skills()
	
	# 随机选择3个
	available.shuffle()
	for i in range(mini(3, available.size())):
		options.append(available[i])
	
	# 如果不足3个，添加可升级的技能
	if options.size() < 3:
		for skill_id in owned_skills.keys():
			var skill: SkillBase = owned_skills[skill_id]
			if skill and skill.current_level < SkillBase.MAX_SKILL_LEVEL:
				options.append(skill.get_skill_info())
				if options.size() >= 3:
					break
	
	return options


# =============================================================================
# 信号回调
# =============================================================================

func _on_skill_upgraded(skill: SkillBase, new_level: int) -> void:
	"""
	技能升级回调
	"""
	skill_leveled_up.emit(skill, new_level)


func _on_combination_activated(combination_id: String, combination_data: Dictionary) -> void:
	"""
	组合激活回调
	"""
	combination_activated.emit(combination_id, combination_data)
	
	# 播放组合激活音效
	AudioManager.play_sfx("combination_unlock")


# =============================================================================
# 序列化
# =============================================================================

## 序列化为字典
func to_dictionary() -> Dictionary:
	"""
	序列化技能管理器状态
	@return: 数据字典
	"""
	var skills_data: Dictionary = {}
	for skill_id in owned_skills.keys():
		var skill: SkillBase = owned_skills[skill_id]
		if skill:
			skills_data[skill_id] = skill.to_dictionary()
	
	var hotkey_data: Array = []
	for i in range(HOTKEY_SLOTS):
		if hotkey_bar[i]:
			hotkey_data.append(hotkey_bar[i].skill_id)
		else:
			hotkey_data.append("")
	
	return {
		"owned_skills": skills_data,
		"hotkey_bar": hotkey_data,
		"combinations": skill_combinations.to_dictionary() if skill_combinations else {}
	}


## 从字典加载
func from_dictionary(data: Dictionary) -> void:
	"""
	从字典加载技能管理器状态
	@param data: 数据字典
	"""
	# 清空现有技能
	owned_skills.clear()
	_init_hotkey_bar()
	
	# 加载技能
	var skills_data: Dictionary = data.get("owned_skills", {})
	for skill_id in skills_data.keys():
		var skill_data: Dictionary = skills_data[skill_id]
		acquire_skill(skill_id, skill_data.get("current_level", 1))
	
	# 加载快捷键栏
	var hotkey_data: Array = data.get("hotkey_bar", [])
	for i in range(mini(hotkey_data.size(), HOTKEY_SLOTS)):
		var skill_id: String = hotkey_data[i]
		if skill_id in owned_skills:
			set_hotkey_slot(i, owned_skills[skill_id])
	
	# 加载组合系统
	if skill_combinations:
		skill_combinations.from_dictionary(data.get("combinations", {}))
