## Void Hunter - 元素法师
## @description: 法术型角色，拥有法力恢复被动技能
## @author: Void Hunter Team
## @version: 1.0.0

extends "res://src/characters/character_base.gd"
class_name ElementalMage

# =============================================================================
# 初始化
# =============================================================================

func _init() -> void:
	# 基础信息
	character_id = "elemental_mage"
	character_name = "元素法师"
	description = "掌控元素之力的神秘法师，能够调动天地间的魔力为己所用。"
	character_type = CharacterBase.CharacterType.MAGIC
	icon = load("res://assets/icons/characters/elemental_mage.png")
	portrait = load("res://assets/icons/characters/elemental_mage.png")

	# 基础属性 - 低生命、低防御、高法力
	base_health = 80.0
	base_attack = 5.0		# 普通攻击较低
	base_defense = 3.0
	base_speed = 140.0
	base_mana = 100.0		# 较高的法力值
	base_critical_chance = 0.08
	base_critical_damage = 2.0  # 较高的暴击伤害

	# 被动技能
	passive_name = "魔力涌动"
	passive_description = "与元素共鸣，法力恢复速度提升50%，技能伤害提升10%。"
	passive_params = {
		"mana_regen_bonus": 0.5,	# 法力恢复加成50%
		"skill_damage_bonus": 0.1,	# 技能伤害加成10%
		"elemental_resonance": true	# 元素共鸣效果
	}

	# 解锁条件 - 收集10个不同技能
	unlock_condition = CharacterBase.UnlockCondition.COLLECT_SKILLS
	unlock_value = 10
	is_default_unlocked = false
	is_hidden = false

# =============================================================================
# 重写被动技能方法
# =============================================================================

## 获取法力恢复加成
func get_mana_regen_bonus() -> float:
	"""获取法力恢复加成"""
	return passive_params.get("mana_regen_bonus", 0.5)


## 获取技能伤害加成
func get_skill_damage_bonus() -> float:
	"""获取技能伤害加成"""
	return passive_params.get("skill_damage_bonus", 0.1)


## 获取修改后的属性
func get_modified_stats(base_stats: Dictionary) -> Dictionary:
	var modified: Dictionary = super.get_modified_stats(base_stats)

	# 应用法力恢复加成
	var base_mana_regen: float = modified.get("mana_regen", 2.0)
	modified["mana_regen"] = base_mana_regen * (1.0 + get_mana_regen_bonus())

	return modified


## 技能伤害计算
func modify_skill_damage(base_damage: float, skill_element: String = "") -> float:
	"""
	修改技能伤害
	@param base_damage: 基础技能伤害
	@param skill_element: 技能元素属性
	@return: 修改后的伤害
	"""
	var final_damage: float = base_damage * (1.0 + get_skill_damage_bonus())

	# 元素共鸣：相同元素连续使用可获得额外加成
	if passive_params.get("elemental_resonance", false):
		# 这里可以实现元素连击效果
		pass

	return final_damage


## 计算元素连击加成
func calculate_elemental_combo(elements_used: Array) -> float:
	"""
	计算元素连击加成
	@param elements_used: 已使用的元素列表
	@return: 连击加成百分比
	"""
	if elements_used.size() < 2:
		return 0.0

	# 检查是否有不同元素
	var unique_elements: Array = []
	for element in elements_used:
		if element not in unique_elements:
			unique_elements.append(element)

	# 使用多种元素获得加成
	var combo_bonus: float = (unique_elements.size() - 1) * 0.05  # 每种不同元素+5%
	return minf(combo_bonus, 0.25)  # 最多25%
