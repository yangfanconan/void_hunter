## Void Hunter - 铁壁技能
## @description: 短时间大幅提升防御
## @author: Void Hunter Team
## @version: 1.0.0

extends SkillBase
class_name SkillIronWall

# =============================================================================
# 信号
# =============================================================================

signal iron_wall_activated()
signal iron_wall_deactivated()

# =============================================================================
# 配置参数
# =============================================================================

## 防御力提升百分比
@export var defense_bonus_percent: float = 0.5

## 伤害减免百分比
@export_range(0.0, 1.0) var damage_reduction_percent: float = 0.3

## 持续时间
@export var iron_wall_duration: float = 4.0

## 是否免疫控制效果
@export var cc_immunity: bool = false

## 是否反弹部分伤害
@export var thorns_percent: float = 0.0

# =============================================================================
# 内部变量
# =============================================================================

var _is_active: bool = false
var _duration_timer: float = 0.0
var _original_defense_bonus: float = 0.0
var _original_damage_reduction: float = 0.0

# =============================================================================
# 初始化
# =============================================================================

func _init() -> void:
	skill_id = "iron_wall"
	skill_name = "铁壁"
	description = "进入防御姿态，大幅提升防御力和伤害减免。"
	skill_type = SkillType.ACTIVE
	skill_category = SkillCategory.DEFENSIVE
	target_type = TargetType.SELF
	element = SkillElement.PHYSICAL
	hotkey_slot = 3
	
	base_cooldown = 15.0
	base_mana_cost = 35.0
	duration = iron_wall_duration


func initialize(owner: Node) -> void:
	super.initialize(owner)
	_is_active = false


func update(delta: float) -> void:
	super.update(delta)
	
	if _is_active:
		_duration_timer -= delta
		
		if _duration_timer <= 0:
			_deactivate_iron_wall()


# =============================================================================
# 技能效果
# =============================================================================

func _execute_self_effect() -> void:
	"""
	激活铁壁
	"""
	if _is_active:
		# 如果已经激活，刷新持续时间
		_duration_timer = get_duration()
		return
	
	_activate_iron_wall()


func _activate_iron_wall() -> void:
	"""
	激活铁壁效果
	"""
	_is_active = true
	_duration_timer = get_duration()
	
	# 应用属性加成
	_apply_stat_bonuses()
	
	# 创建视觉效果
	_create_iron_wall_visual()
	
	iron_wall_activated.emit()
	
	# 播放音效
	AudioManager.play_sfx("iron_wall")


func _deactivate_iron_wall() -> void:
	"""
	停用铁壁效果
	"""
	_is_active = false
	
	# 移除属性加成
	_remove_stat_bonuses()
	
	iron_wall_deactivated.emit()


func _apply_stat_bonuses() -> void:
	"""
	应用属性加成
	"""
	if owner_node == null:
		return
	
	if "stats" in owner_node:
		var stats: PlayerStats = owner_node.stats
		if stats:
			# 保存原始值
			_original_defense_bonus = stats.defense_bonus_percent
			_original_damage_reduction = stats.damage_reduction
			
			# 应用加成
			stats.defense_bonus_percent += get_defense_bonus()
			stats.damage_reduction += get_damage_reduction()


func _remove_stat_bonuses() -> void:
	"""
	移除属性加成
	"""
	if owner_node == null:
		return
	
	if "stats" in owner_node:
		var stats: PlayerStats = owner_node.stats
		if stats:
			# 恢复原始值
			stats.defense_bonus_percent = _original_defense_bonus
			stats.damage_reduction = _original_damage_reduction


# =============================================================================
# 视觉效果
# =============================================================================

func _create_iron_wall_visual() -> void:
	"""
	创建铁壁视觉效果
	"""
	if owner_node == null:
		return
	
	# 修改玩家颜色
	var tween: Tween = owner_node.create_tween()
	tween.tween_property(owner_node, "modulate", Color(0.7, 0.7, 0.8, 1.0), 0.2)
	
	# 持续时间结束后恢复
	await owner_node.get_tree().create_timer(get_duration()).timeout
	
	if is_instance_valid(owner_node):
		var restore_tween: Tween = owner_node.create_tween()
		restore_tween.tween_property(owner_node, "modulate", Color.WHITE, 0.2)


# =============================================================================
# 属性获取
# =============================================================================

func get_defense_bonus() -> float:
	"""
	获取防御力加成（受等级影响）
	"""
	return defense_bonus_percent + (current_level - 1) * 0.25


func get_damage_reduction() -> float:
	"""
	获取伤害减免（受等级影响）
	"""
	return damage_reduction_percent + (current_level - 1) * 0.15


func get_thorns_percent() -> float:
	"""
	获取反伤百分比
	"""
	return thorns_percent + (current_level - 1) * 0.1


# =============================================================================
# 公共方法
# =============================================================================

func is_iron_wall_active() -> bool:
	"""
	铁壁是否激活
	"""
	return _is_active


func has_cc_immunity() -> bool:
	"""
	是否免疫控制
	"""
	return _is_active and cc_immunity


# =============================================================================
# 升级效果
# =============================================================================

func _on_level_up(new_level: int) -> void:
	"""
	升级时增强铁壁
	"""
	match new_level:
		2:
			defense_bonus_percent = 0.75
			damage_reduction_percent = 0.45
			cc_immunity = true
		3:
			defense_bonus_percent = 1.0
			damage_reduction_percent = 0.6
			thorns_percent = 0.2
