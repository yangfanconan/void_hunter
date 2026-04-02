## Void Hunter - 状态效果管理器
## @description: 管理所有状态效果（燃烧、冰冻、中毒、眩晕、击退、浮空等）
## @version: 2.0.0

extends Node

# =============================================================================
# 信号定义
# =============================================================================

signal status_applied(target: Node, effect_id: String, stacks: int)
signal status_removed(target: Node, effect_id: String)
signal status_tick(target: Node, effect_id: String, damage: float)
signal status_expired(target: Node, effect_id: String)

# =============================================================================
# 枚举定义
# =============================================================================

enum StatusType {
	BURN,			## 燃烧 - 持续火焰伤害
	FREEZE,			## 冰冻 - 减速+最终冻结
	POISON,			## 中毒 - 持续毒素伤害
	STUN,			## 眩晕 - 无法行动
	KNOCKBACK,		## 击退 - 强制位移
	LAUNCH,			## 浮空 - 击飞
	SLOW,			## 减速 - 移速降低
	BLEED,			## 流血 - 持续物理伤害
	ELECTRIC,		## 电击 - 间歇性伤害+麻痹
	SILENCE,		## 沉默 - 无法使用技能
	BLIND,			## 致盲 - 命中率降低
	WEAKEN,			## 虚弱 - 攻击力降低
	VULNERABLE,		## 易伤 - 受伤增加
	REGENERATION,	## 再生 - 持续回复
	SHIELD,			## 护盾 - 额外生命
	HASTE,			## 加速 - 移速攻速增加
	POWER_UP,		## 强化 - 攻击力增加
	INVINCIBLE,		## 无敌 - 免疫伤害
	RAGE,			## 暴走 - 攻击大幅增加，防御降低
	LIFESTEAL_AURA	## 吸血光环
}

## 效果稀有度颜色
const STATUS_COLORS: Dictionary = {
	StatusType.BURN: Color(1.0, 0.4, 0.1),
	StatusType.FREEZE: Color(0.5, 0.8, 1.0),
	StatusType.POISON: Color(0.4, 0.8, 0.2),
	StatusType.STUN: Color(1.0, 1.0, 0.3),
	StatusType.KNOCKBACK: Color(0.8, 0.8, 0.8),
	StatusType.LAUNCH: Color(1.0, 0.7, 0.3),
	StatusType.SLOW: Color(0.3, 0.5, 0.9),
	StatusType.BLEED: Color(0.8, 0.1, 0.1),
	StatusType.ELECTRIC: Color(0.6, 0.8, 1.0),
	StatusType.SILENCE: Color(0.5, 0.3, 0.7),
	StatusType.BLIND: Color(0.3, 0.3, 0.3),
	StatusType.WEAKEN: Color(0.6, 0.4, 0.8),
	StatusType.VULNERABLE: Color(1.0, 0.3, 0.5),
	StatusType.REGENERATION: Color(0.3, 1.0, 0.5),
	StatusType.SHIELD: Color(0.3, 0.6, 1.0),
	StatusType.HASTE: Color(0.9, 0.9, 0.3),
	StatusType.POWER_UP: Color(1.0, 0.6, 0.2),
	StatusType.INVINCIBLE: Color(1.0, 0.9, 0.5),
	StatusType.RAGE: Color(1.0, 0.2, 0.2),
	StatusType.LIFESTEAL_AURA: Color(0.8, 0.2, 0.4)
}

# =============================================================================
# 状态效果数据类
# =============================================================================

class StatusEffect:
	var id: StatusType
	var name: String
	var stacks: int = 1
	var max_stacks: int
	var duration: float
	var remaining: float
	var tick_interval: float
	var tick_timer: float
	var damage_per_tick: float
	var magnitude: float  ## 效果强度 (减速百分比、攻击加成等)
	var source: Node = null
	var is_permanent: bool = false

	func _init(p_id: StatusType, p_name: String, p_duration: float, p_max_stacks: int = 1) -> void:
		id = p_id
		name = p_name
		duration = p_duration
		remaining = p_duration
		max_stacks = p_max_stacks
		tick_interval = 0.5
		tick_timer = 0.0

	func is_expired() -> bool:
		return not is_permanent and remaining <= 0.0

# =============================================================================
# 公共变量
# =============================================================================

## 目标 -> 效果列表映射
var _effects: Dictionary = {}

## 是否显示调试信息
var debug_mode: bool = false

# =============================================================================
# 公共方法 - 效果应用
# =============================================================================

## 应用状态效果到目标
func apply_status(target: Node, status_type: StatusType, duration: float, \
		damage_per_tick: float = 0.0, magnitude: float = 0.0, stacks: int = 1, \
		source: Node = null, tick_interval: float = 0.5) -> void:
	if target == null or not is_instance_valid(target):
		return

	var effect := _create_effect(status_type, duration, damage_per_tick, magnitude, stacks, source, tick_interval)

	if not _effects.has(target):
		_effects[target] = []
		# 连接目标树退出信号自动清理
		if target is Node:
			target.tree_exiting.connect(_on_target_tree_exiting.bind(target))

	var target_effects: Array = _effects[target]

	# 检查是否已有同类效果
	var existing: StatusEffect = _find_effect(target, status_type)
	if existing != null:
		# 叠加或刷新
		_merge_effect(existing, effect)
	else:
		target_effects.append(effect)

	# 应用即时效果
	_apply_instant_effect(target, effect)

	status_applied.emit(target, StatusType.keys()[status_type], effect.stacks)

	if debug_mode:
		print("[StatusEffect] 对 %s 应用 %s x%d, 持续%.1fs" % [target.name, effect.name, effect.stacks, effect.remaining])

## 移除目标的所有状态效果
func remove_all_status(target: Node) -> void:
	if _effects.has(target):
		for effect in _effects[target]:
			_remove_effect_immediate(target, effect)
		_effects.erase(target)

## 移除指定类型状态效果
func remove_status(target: Node, status_type: StatusType) -> void:
	var effect := _find_effect(target, status_type)
	if effect != null:
		_remove_effect_immediate(target, effect)

## 检查目标是否有某状态
func has_status(target: Node, status_type: StatusType) -> bool:
	return _find_effect(target, status_type) != null

## 获取效果层数
func get_status_stacks(target: Node, status_type: StatusType) -> int:
	var effect := _find_effect(target, status_type)
	return effect.stacks if effect else 0

## 获取效果强度
func get_status_magnitude(target: Node, status_type: StatusType) -> float:
	var effect := _find_effect(target, status_type)
	return effect.magnitude if effect else 0.0

## 获取目标所有状态效果
func get_all_status(target: Node) -> Array:
	return _effects.get(target, [])

## 获取减速总比例
func get_total_slow(target: Node) -> float:
	var slow_effect := _find_effect(target, StatusType.SLOW)
	var freeze_effect := _find_effect(target, StatusType.FREEZE)
	var total_slow := 0.0
	if slow_effect:
		total_slow += slow_effect.magnitude
	if freeze_effect:
		total_slow += freeze_effect.magnitude * 0.5
	return minf(total_slow, 0.9)

## 检查目标是否被眩晕
func is_stunned(target: Node) -> bool:
	return has_status(target, StatusType.STUN)

## 检查目标是否被沉默
func is_silenced(target: Node) -> bool:
	return has_status(target, StatusType.SILENCE)

## 检查目标是否无敌
func is_invincible(target: Node) -> bool:
	return has_status(target, StatusType.INVINCIBLE)

## 获取攻击力加成
func get_attack_multiplier(target: Node) -> float:
	var mult := 1.0
	var power_up := _find_effect(target, StatusType.POWER_UP)
	if power_up:
		mult += power_up.magnitude
	var rage := _find_effect(target, StatusType.RAGE)
	if rage:
		mult += rage.magnitude
	var weaken := _find_effect(target, StatusType.WEAKEN)
	if weaken:
		mult -= weaken.magnitude
	return maxf(mult, 0.1)

## 获取受伤加成
func get_damage_taken_multiplier(target: Node) -> float:
	var mult := 1.0
	var vuln := _find_effect(target, StatusType.VULNERABLE)
	if vuln:
		mult += vuln.magnitude
	var rage := _find_effect(target, StatusType.RAGE)
	if rage:
		mult += rage.magnitude * 0.3  # 暴走时受伤增加
	return mult

## 获取移速加成
func get_speed_multiplier(target: Node) -> float:
	var mult := 1.0
	var haste := _find_effect(target, StatusType.HASTE)
	if haste:
		mult += haste.magnitude
	mult -= get_total_slow(target)
	return maxf(mult, 0.1)

## 获取护盾值
func get_shield_amount(target: Node) -> float:
	var shield := _find_effect(target, StatusType.SHIELD)
	return shield.magnitude if shield else 0.0

## 消耗护盾
func consume_shield(target: Node, amount: float) -> float:
	var shield := _find_effect(target, StatusType.SHIELD)
	if shield == null:
		return amount
	if shield.magnitude >= amount:
		shield.magnitude -= amount
		return 0.0
	else:
		var remaining := amount - shield.magnitude
		_remove_effect_immediate(target, shield)
		return remaining

# =============================================================================
# 生命周期
# =============================================================================

func _process(delta: float) -> void:
	for target in _effects.keys():
		if target == null or not is_instance_valid(target):
			_effects.erase(target)
			continue

		var effects: Array = _effects[target]
		var to_remove: Array = []

		for effect in effects:
			if effect.is_expired():
				to_remove.append(effect)
				continue

			# 更新持续时间
			if not effect.is_permanent:
				effect.remaining -= delta

			# 更新tick计时器
			effect.tick_timer -= delta
			if effect.tick_timer <= 0.0:
				effect.tick_timer = effect.tick_interval
				_process_tick(target, effect)

		# 移除过期效果
		for effect in to_remove:
			_remove_effect_immediate(target, effect)

# =============================================================================
# 私有方法 - 效果创建与合并
# =============================================================================

func _create_effect(status_type: StatusType, duration: float, damage: float, \
		magnitude: float, stacks: int, source: Node, tick_interval: float) -> StatusEffect:
	var effect := StatusEffect.new(status_type, StatusType.keys()[status_type], duration)
	effect.damage_per_tick = damage
	effect.magnitude = magnitude
	effect.stacks = stacks
	effect.source = source
	effect.tick_interval = tick_interval
	effect.tick_timer = tick_interval

	# 设置最大叠加层数
	match status_type:
		StatusType.BURN:
			effect.max_stacks = 5
		StatusType.POISON:
			effect.max_stacks = 10
		StatusType.BLEED:
			effect.max_stacks = 5
		StatusType.SHIELD:
			effect.is_permanent = true
		_:
			effect.max_stacks = 1

	return effect

func _merge_effect(existing: StatusEffect, new_effect: StatusEffect) -> void:
	# 刷新持续时间（取较大值）
	existing.remaining = maxf(existing.remaining, new_effect.duration)

	# 叠加层数
	existing.stacks = mini(existing.stacks + new_effect.stacks, existing.max_stacks)

	# 叠加伤害
	if new_effect.damage_per_tick > 0:
		existing.damage_per_tick = maxf(existing.damage_per_tick, new_effect.damage_per_tick)

	# 叠加强度
	if new_effect.magnitude > 0:
		existing.magnitude = maxf(existing.magnitude, new_effect.magnitude)

	# 更新来源
	if new_effect.source:
		existing.source = new_effect.source

func _find_effect(target: Node, status_type: StatusType) -> StatusEffect:
	var effects: Array = _effects.get(target, [])
	for effect in effects:
		if effect.id == status_type:
			return effect
	return null

# =============================================================================
# 私有方法 - 效果处理
# =============================================================================

func _apply_instant_effect(target: Node, effect: StatusEffect) -> void:
	match effect.id:
		StatusType.KNOCKBACK:
			_apply_knockback(target, effect)
		StatusType.LAUNCH:
			_apply_launch(target, effect)
		StatusType.STUN:
			if target.has_method("stun"):
				target.stun(effect.duration)
		StatusType.FREEZE:
			# 冰冻叠加到一定层数触发完全冻结
			if effect.stacks >= 3:
				if target.has_method("stun"):
					target.stun(effect.remaining)
				effect.magnitude = 0.8  # 80%减速

func _process_tick(target: Node, effect: StatusEffect) -> void:
	if target == null or not is_instance_valid(target):
		return

	match effect.id:
		StatusType.BURN:
			_deal_dot_damage(target, effect)
			_spawn_status_particle(target, STATUS_COLORS[StatusType.BURN])
		StatusType.POISON:
			_deal_dot_damage(target, effect)
			_spawn_status_particle(target, STATUS_COLORS[StatusType.POISON])
		StatusType.BLEED:
			_deal_dot_damage(target, effect)
		StatusType.ELECTRIC:
			_deal_dot_damage(target, effect)
			if randf() < 0.3:
				if target.has_method("stun"):
					target.stun(0.2)
		StatusType.REGENERATION:
			if target.has_method("heal"):
				target.heal(effect.magnitude)

func _deal_dot_damage(target: Node, effect: StatusEffect) -> void:
	var damage := effect.damage_per_tick * effect.stacks
	if target.has_method("take_damage"):
		target.take_damage(damage, effect.source)
	status_tick.emit(target, StatusType.keys()[effect.id], damage)

func _apply_knockback(target: Node, effect: StatusEffect) -> void:
	if target.has_method("knockback"):
		var source_pos := Vector2.ZERO
		if effect.source and is_instance_valid(effect.source):
			source_pos = effect.source.global_position
		var direction: Variant = (target.global_position - source_pos).normalized()
		target.knockback(direction, effect.magnitude)

func _apply_launch(target: Node, effect: StatusEffect) -> void:
	# 击飞效果 - 通过视觉表现模拟
	if target.has_method("knockback"):
		target.knockback(Vector2.UP, effect.magnitude)
	# 视觉：目标缩放Y轴变小+上移
	var tween := target.create_tween()
	tween.tween_property(target, "position:y", target.position.y - 30.0, 0.15)
	tween.tween_property(target, "position:y", target.position.y, 0.2)

func _remove_effect_immediate(target: Node, effect: StatusEffect) -> void:
	if _effects.has(target):
		_effects[target].erase(effect)
		if _effects[target].is_empty():
			_effects.erase(target)
	status_removed.emit(target, StatusType.keys()[effect.id])

# =============================================================================
# 视觉效果
# =============================================================================

func _spawn_status_particle(target: Node, color: Color) -> void:
	if target == null or not is_instance_valid(target):
		return

	# 简单的浮动文字效果
	var label := Label.new()
	label.text = "●"
	label.modulate = color
	label.position = target.global_position + Vector2(randf_range(-10, 10), -20)
	label.z_index = 100
	label.scale = Vector2(0.5, 0.5)

	get_tree().current_scene.add_child(label)

	var tween := label.create_tween()
	tween.tween_property(label, "position:y", label.position.y - 30.0, 0.5)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(label.queue_free)

# =============================================================================
# 便捷方法 - 快速应用状态
# =============================================================================

## 应用燃烧
func apply_burn(target: Node, damage: float, duration: float = 3.0, source: Node = null) -> void:
	apply_status(target, StatusType.BURN, duration, damage, 0.0, 1, source, 0.5)

## 应用冰冻
func apply_freeze(target: Node, slow_percent: float, duration: float = 2.0, source: Node = null) -> void:
	apply_status(target, StatusType.FREEZE, duration, 0.0, slow_percent, 1, source, 1.0)

## 应用中毒
func apply_poison(target: Node, damage: float, duration: float = 5.0, source: Node = null) -> void:
	apply_status(target, StatusType.POISON, duration, damage, 0.0, 1, source, 0.5)

## 应用眩晕
func apply_stun(target: Node, duration: float, source: Node = null) -> void:
	apply_status(target, StatusType.STUN, duration, 0.0, 0.0, 1, source, 1.0)

## 应用击退
func apply_knockback(target: Node, force: float, source: Node = null) -> void:
	apply_status(target, StatusType.KNOCKBACK, 0.2, 0.0, force, 1, source, 1.0)

## 应用浮空
func apply_launch(target: Node, force: float, source: Node = null) -> void:
	apply_status(target, StatusType.LAUNCH, 0.3, 0.0, force, 1, source, 1.0)

## 应用减速
func apply_slow(target: Node, slow_percent: float, duration: float = 2.0, source: Node = null) -> void:
	apply_status(target, StatusType.SLOW, duration, 0.0, slow_percent, 1, source, 1.0)

## 应用护盾
func apply_shield(target: Node, amount: float, source: Node = null) -> void:
	apply_status(target, StatusType.SHIELD, 999.0, 0.0, amount, 1, source, 1.0)

## 应用加速
func apply_haste(target: Node, speed_percent: float, duration: float = 5.0, source: Node = null) -> void:
	apply_status(target, StatusType.HASTE, duration, 0.0, speed_percent, 1, source, 1.0)

## 应用强化
func apply_power_up(target: Node, attack_percent: float, duration: float = 5.0, source: Node = null) -> void:
	apply_status(target, StatusType.POWER_UP, duration, 0.0, attack_percent, 1, source, 1.0)

## 应用无敌
func apply_invincible(target: Node, duration: float, source: Node = null) -> void:
	apply_status(target, StatusType.INVINCIBLE, duration, 0.0, 1.0, 1, source, 1.0)

## 应用暴走
func apply_rage(target: Node, attack_percent: float, duration: float = 8.0, source: Node = null) -> void:
	apply_status(target, StatusType.RAGE, duration, 0.0, attack_percent, 1, source, 1.0)

## 应用易伤
func apply_vulnerable(target: Node, percent: float, duration: float = 3.0, source: Node = null) -> void:
	apply_status(target, StatusType.VULNERABLE, duration, 0.0, percent, 1, source, 1.0)

## 应用再生
func apply_regen(target: Node, heal_per_tick: float, duration: float = 5.0, source: Node = null) -> void:
	apply_status(target, StatusType.REGENERATION, duration, 0.0, heal_per_tick, 1, source, 1.0)

# =============================================================================
# 信号回调
# =============================================================================

func _on_target_tree_exiting(target: Node) -> void:
	_effects.erase(target)
