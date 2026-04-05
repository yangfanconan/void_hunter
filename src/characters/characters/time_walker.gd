## Void Hunter - 时空行者
## @description: 控制型角色，拥有时间回溯被动技能
## @author: Void Hunter Team
## @version: 1.0.0

extends "res://src/characters/character_base.gd"
class_name TimeWalker

# =============================================================================
# 私有变量
# =============================================================================

var _has_revived: bool = false
var _revive_available: bool = true
var _slow_aura_active: bool = false

# =============================================================================
# 初始化
# =============================================================================

func _init() -> void:
	# 基础信息
	character_id = "time_walker"
	character_name = "时空行者"
	description = "来自未来时空的神秘旅者，掌握着操纵时间的禁忌力量。"
	character_type = CharacterBase.CharacterType.CONTROL
	icon = load("res://assets/icons/characters/time_walker.png")
	portrait = load("res://assets/icons/characters/time_walker.png")

	# 基础属性 - 均衡偏快
	base_health = 85.0
	base_attack = 12.0
	base_defense = 4.0
	base_speed = 170.0
	base_mana = 80.0
	base_critical_chance = 0.06
	base_critical_damage = 1.6

	# 被动技能
	passive_name = "时间回溯"
	passive_description = "死亡时有10%概率触发时间回溯，复活并恢复50%生命值。每次游戏只能触发一次。"
	passive_params = {
		"revive_chance": 0.1,			# 复活概率
		"revive_health_percent": 0.5,	# 复活后生命百分比
		"time_slow_aura": true,			# 周围敌人减速光环
		"slow_radius": 150.0,			# 减速范围
		"slow_amount": 0.2				# 减速量
	}

	# 解锁条件 - 到达虚空层（第10层）
	unlock_condition = CharacterBase.UnlockCondition.REACH_VOID_LEVEL
	unlock_value = 10
	is_default_unlocked = false
	is_hidden = false

# =============================================================================
# 重写被动技能方法
# =============================================================================

## 死亡时触发复活判定
func on_death() -> Dictionary:
	var effects: Dictionary = super.on_death()

	if _revive_available:
		var revive_chance: float = passive_params.get("revive_chance", 0.1)
		if randf() < revive_chance:
			effects["revive"] = true
			effects["revive_health_percent"] = passive_params.get("revive_health_percent", 0.5)
			_has_revived = true
			_revive_available = false
			passive_triggered.emit(passive_name, {"revived": true})

	return effects


## 获取时间减速光环效果
func get_time_slow_aura() -> Dictionary:
	"""
	获取时间减速光环数据
	@return: 光环数据
	"""
	if passive_params.get("time_slow_aura", false):
		return {
			"active": _slow_aura_active,
			"radius": passive_params.get("slow_radius", 150.0),
			"slow_amount": passive_params.get("slow_amount", 0.2)
		}
	return {}


## 激活/停用时间减速光环
func set_slow_aura_active(active: bool) -> void:
	"""设置时间减速光环状态"""
	_slow_aura_active = active
	if active:
		passive_triggered.emit(passive_name, {"slow_aura_activated": true})


## 检查是否可以复活
func can_revive() -> bool:
	"""检查是否还有复活机会"""
	return _revive_available


## 检查是否已经复活过
func has_used_revive() -> bool:
	"""检查是否已经使用过复活"""
	return _has_revived


## 重置复活状态（新游戏时）
func reset_revive() -> void:
	"""重置复活状态"""
	_has_revived = false
	_revive_available = true


## 技能冷却减少
func get_cooldown_reduction() -> float:
	"""
	获取技能冷却减少（时空行者额外效果）
	@return: 冷却减少百分比
	"""
	return 0.1  # 10%冷却减少


## 重置状态
func reset() -> void:
	super.reset()
	# 注意：不重置复活状态，因为每局只能复活一次
	_slow_aura_active = false
