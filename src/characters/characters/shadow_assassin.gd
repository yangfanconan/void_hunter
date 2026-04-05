## Void Hunter - 暗影刺客
## @description: 高攻速型角色，拥有闪避被动技能
## @author: Void Hunter Team
## @version: 1.0.0

extends "res://src/characters/character_base.gd"
class_name ShadowAssassin

# =============================================================================
# 初始化
# =============================================================================

func _init() -> void:
	# 基础信息
	character_id = "shadow_assassin"
	character_name = "暗影刺客"
	description = "来自暗影组织的精英刺客，擅长快速移动和致命一击，但也因此牺牲了防御。"
	character_type = CharacterBase.CharacterType.HIGH_DPS
	icon = load("res://assets/icons/characters/shadow_assassin.png")
	portrait = load("res://assets/icons/characters/shadow_assassin.png")

	# 基础属性 - 高攻速、高攻击、低防御
	base_health = 70.0
	base_attack = 15.0
	base_defense = 2.0
	base_speed = 180.0
	base_mana = 40.0
	base_critical_chance = 0.10  # 较高的暴击率
	base_critical_damage = 1.8   # 较高的暴击伤害

	# 被动技能
	passive_name = "影步"
	passive_description = "在暗影中穿梭，受到攻击时有20%概率自动闪避，完全无视伤害。"
	passive_params = {
		"dodge_chance": 0.20,	# 闪避概率
		"dodge_cooldown": 0.5	# 闪避冷却（秒）
	}

	# 解锁条件 - 单局击杀500敌人
	unlock_condition = CharacterBase.UnlockCondition.KILL_ENEMIES
	unlock_value = 500
	is_default_unlocked = false
	is_hidden = false

# =============================================================================
# 重写被动技能方法
# =============================================================================

## 受伤时触发闪避判定
func on_damage_taken(damage_data: Dictionary) -> Dictionary:
	var result: Dictionary = super.on_damage_taken(damage_data)

	# 闪避逻辑在基类中处理
	# 成功闪避后可以添加额外效果

	if result.get("evaded", false):
		# 闪避成功，可以触发位移或特殊效果
		result["dodge_effect"] = true

	return result


## 获取闪避概率
func get_dodge_chance() -> float:
	"""获取当前闪避概率"""
	return passive_params.get("dodge_chance", 0.2)


## 尝试手动闪避
func try_manual_dodge() -> bool:
	"""
	尝试手动触发闪避效果（用于特殊技能配合）
	@return: 是否成功闪避
	"""
	if randf() < passive_params.get("dodge_chance", 0.2):
		passive_triggered.emit(passive_name, {"evaded": true, "manual": true})
		return true
	return false
