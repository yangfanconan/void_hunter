## Void Hunter - 连击/暴走系统
## @description: 管理连击计数、连杀奖励、暴走状态、爽感反馈
## @version: 2.1.0

extends Node

# =============================================================================
# 信号定义
# =============================================================================

signal combo_hit(count: int)                     ## 连击数变化
signal combo_milestone(milestone: int)           ## 连击里程碑 (10/25/50/100)
signal combo_broken(final_count: int)            ## 连击中断
signal kill_streak(count: int)                   ## 连杀数变化
signal rage_mode_activated(duration: float)      ## 暴走模式激活
signal rage_mode_deactivated()                   ## 暴走模式结束
signal massacre_triggered()                      ## 大屠杀触发 (短时间内击杀大量敌人)
signal screen_shake(intensity: float, duration: float)  ## 屏幕震动请求
signal slow_motion(duration: float, scale: float)       ## 慢动作请求
signal kill_event(kill_data: Dictionary)         ## 击杀事件
signal combo_decay_warning(remaining_time: float)       ## 连击即将中断警告
signal combo_multiplier_changed(multiplier: float)      ## 连击倍率变化

# =============================================================================
# 常量定义
# =============================================================================

## 连击超时时间（秒）
const COMBO_TIMEOUT: float = 3.0

## 连杀超时时间（秒）
const KILL_STREAK_TIMEOUT: float = 5.0

## 暴走模式需要的连击数
const RAGE_COMBO_THRESHOLD: int = 30

## 暴走模式持续时间
const RAGE_DURATION: float = 8.0

## 暴走模式击杀延长时间（秒）
const RAGE_KILL_EXTEND: float = 0.5

## 大屠杀判定窗口（秒）
const MASSACRE_WINDOW: float = 3.0

## 大屠杀判定数量
const MASSACRE_KILL_COUNT: int = 8

## 连击里程碑列表
const MILESTONES: Array[int] = [10, 25, 50, 100, 200, 500, 1000]

## 连杀里程碑列表
const KILL_STREAK_MILESTONES: Array[int] = [3, 5, 10, 15, 20, 30, 50]

## 连击倍率曲线: [最小连击, 倍率]
const COMBO_MULTIPLIER_TABLE: Array[Dictionary] = [
	{"min_combo": 0,   "multiplier": 1.0},
	{"min_combo": 5,   "multiplier": 1.1},
	{"min_combo": 10,  "multiplier": 1.2},
	{"min_combo": 25,  "multiplier": 1.4},
	{"min_combo": 50,  "multiplier": 1.7},
	{"min_combo": 100, "multiplier": 2.0},
	{"min_combo": 200, "multiplier": 2.5},
	{"min_combo": 500, "multiplier": 3.0},
]

# =============================================================================
# 连击奖励配置
# =============================================================================

## 连击奖励表: [最小连击, 攻击加成, 暴击率加成, 经验加成, 金币加成]
const COMBO_REWARDS: Array[Dictionary] = [
	{"min_combo": 5,   "attack_bonus": 0.05, "crit_bonus": 0.02, "exp_bonus": 0.0, "gold_bonus": 0.0},
	{"min_combo": 10,  "attack_bonus": 0.10, "crit_bonus": 0.05, "exp_bonus": 0.1, "gold_bonus": 0.0},
	{"min_combo": 25,  "attack_bonus": 0.20, "crit_bonus": 0.10, "exp_bonus": 0.2, "gold_bonus": 0.1},
	{"min_combo": 50,  "attack_bonus": 0.35, "crit_bonus": 0.15, "exp_bonus": 0.3, "gold_bonus": 0.2},
	{"min_combo": 100, "attack_bonus": 0.50, "crit_bonus": 0.25, "exp_bonus": 0.5, "gold_bonus": 0.3},
	{"min_combo": 200, "attack_bonus": 0.80, "crit_bonus": 0.35, "exp_bonus": 0.8, "gold_bonus": 0.5},
]

# =============================================================================
# 公共变量
# =============================================================================

## 当前连击数
var combo_count: int = 0

## 最高连击数（当局）
var max_combo: int = 0

## 连杀数
var kill_streak_count: int = 0

## 最高连杀（当局）
var max_kill_streak: int = 0

## 总击杀数（当局）
var total_kills: int = 0

## 是否在暴走模式
var is_rage_mode: bool = false

## 暴走模式剩余时间
var rage_timer: float = 0.0

## 暴走模式连击数
var rage_combo: int = 0

## 连击衰减警告阈值（剩余时间低于此值时发出信号）
var combo_decay_warning_time: float = 1.0

# =============================================================================
# 私有变量
# =============================================================================

var _combo_timer: float = 0.0
var _kill_streak_timer: float = 0.0
var _kill_timestamps: Array[float] = []
var _is_initialized: bool = false
var _rage_activations: int = 0          ## 暴走模式激活次数（当局）
var _massacre_count: int = 0            ## 大屠杀触发次数（当局）
var _longest_rage_combo: int = 0        ## 单次暴走中最高连击数
var _last_decay_warning_emitted: bool = false  ## 防止重复发出衰减警告

# =============================================================================
# 初始化
# =============================================================================

func initialize() -> void:
	_is_initialized = true
	_rage_activations = 0
	_massacre_count = 0
	_longest_rage_combo = 0
	print("[ComboSystem] 连击系统初始化完成")

# =============================================================================
# 公共方法
# =============================================================================

## 记录一次攻击命中
func register_hit() -> void:
	combo_count += 1
	_combo_timer = COMBO_TIMEOUT
	_last_decay_warning_emitted = false

	# 更新最高连击
	if combo_count > max_combo:
		max_combo = combo_count

	combo_hit.emit(combo_count)

	# 通知连击倍率变化
	combo_multiplier_changed.emit(get_combo_multiplier())

	# 检查里程碑
	_check_milestone()

	# 连击反馈
	_process_hit_feedback()

	# 检查暴走
	if not is_rage_mode and combo_count >= RAGE_COMBO_THRESHOLD:
		activate_rage_mode()

## 记录一次击杀
func register_kill(kill_data: Dictionary = {}) -> void:
	total_kills += 1
	kill_streak_count += 1
	_kill_streak_timer = KILL_STREAK_TIMEOUT

	if kill_streak_count > max_kill_streak:
		max_kill_streak = kill_streak_count

	# 记录击杀时间戳（用于大屠杀判定）
	_kill_timestamps.append(Time.get_ticks_msec() / 1000.0)
	_cleanup_old_kill_timestamps()

	# 触发击杀事件
	var enriched_data := kill_data.duplicate()
	enriched_data["combo"] = combo_count
	enriched_data["kill_streak"] = kill_streak_count
	enriched_data["total_kills"] = total_kills
	enriched_data["is_rage"] = is_rage_mode
	kill_event.emit(enriched_data)

	kill_streak.emit(kill_streak_count)

	# 检查连杀里程碑
	_check_kill_streak_milestone()

	# 连击增加
	register_hit()

	# 检查大屠杀
	_check_massacre()

	# 暴走模式下击杀延长暴走时间
	if is_rage_mode:
		rage_timer = minf(rage_timer + RAGE_KILL_EXTEND, RAGE_DURATION * 1.5)
		rage_combo += 1
		if rage_combo > _longest_rage_combo:
			_longest_rage_combo = rage_combo

	# 击杀反馈
	_process_kill_feedback(kill_data)

## 连击中断
func break_combo() -> void:
	if combo_count > 0:
		combo_broken.emit(combo_count)
	combo_count = 0
	_last_decay_warning_emitted = false

## 连杀中断
func break_kill_streak() -> void:
	kill_streak_count = 0

## 激活暴走模式
func activate_rage_mode() -> void:
	if is_rage_mode:
		return

	is_rage_mode = true
	rage_timer = RAGE_DURATION
	rage_combo = 0
	_rage_activations += 1

	rage_mode_activated.emit(RAGE_DURATION)

	# 暴走反馈
	screen_shake.emit(8.0, 0.3)
	slow_motion.emit(0.1, 0.3)  # 短暂慢动作

	print("[ComboSystem] 暴走模式激活! (第%d次)" % _rage_activations)

## 获取当前连击倍率
func get_combo_multiplier() -> float:
	var multiplier := 1.0
	for entry in COMBO_MULTIPLIER_TABLE:
		if combo_count >= entry["min_combo"]:
			multiplier = entry["multiplier"]

	# 暴走模式额外倍率
	if is_rage_mode:
		multiplier *= 1.5

	return multiplier

## 获取当前连击奖励
func get_current_rewards() -> Dictionary:
	var rewards := {
		"attack_bonus": 0.0,
		"crit_bonus": 0.0,
		"exp_bonus": 0.0,
		"gold_bonus": 0.0,
	}

	for reward in COMBO_REWARDS:
		if combo_count >= reward["min_combo"]:
			rewards["attack_bonus"] = reward["attack_bonus"]
			rewards["crit_bonus"] = reward["crit_bonus"]
			rewards["exp_bonus"] = reward["exp_bonus"]
			rewards["gold_bonus"] = reward["gold_bonus"]

	# 暴走模式额外奖励
	if is_rage_mode:
		rewards["attack_bonus"] += 0.5
		rewards["crit_bonus"] += 0.3

	return rewards

## 获取攻击力加成
func get_attack_bonus() -> float:
	var rewards := get_current_rewards()
	return rewards["attack_bonus"]

## 获取暴击率加成
func get_crit_bonus() -> float:
	var rewards := get_current_rewards()
	return rewards["crit_bonus"]

## 获取经验加成
func get_exp_bonus() -> float:
	var rewards := get_current_rewards()
	return rewards["exp_bonus"]

## 获取金币加成
func get_gold_bonus() -> float:
	var rewards := get_current_rewards()
	return rewards["gold_bonus"]

## 获取暴走模式激活次数（当局）
func get_rage_activations() -> int:
	return _rage_activations

## 获取大屠杀触发次数（当局）
func get_massacre_count() -> int:
	return _massacre_count

## 获取最长单次暴走连击
func get_longest_rage_combo() -> int:
	return _longest_rage_combo

## 获取暴走模式剩余时间比例 (0.0 ~ 1.0)
func get_rage_time_ratio() -> float:
	if not is_rage_mode:
		return 0.0
	return clampf(rage_timer / RAGE_DURATION, 0.0, 1.0)

## 获取连击计时器剩余时间
func get_combo_remaining_time() -> float:
	return maxf(_combo_timer, 0.0)

## 获取连击评分（用于结算界面）
func get_score() -> int:
	var base_score := max_combo * 100 + total_kills * 50 + max_kill_streak * 200
	# 暴走次数加分
	base_score += _rage_activations * 500
	# 大屠杀加分
	base_score += _massacre_count * 1000
	# 最长暴走连击加分
	base_score += _longest_rage_combo * 50
	return base_score

## 获取评级
func get_rank() -> String:
	var score := get_score()
	if score >= 50000: return "SSS"
	if score >= 30000: return "SS"
	if score >= 20000: return "S"
	if score >= 10000: return "A"
	if score >= 5000: return "B"
	if score >= 2000: return "C"
	return "D"

## 重置（新游戏开始时调用）
func reset() -> void:
	combo_count = 0
	max_combo = 0
	kill_streak_count = 0
	max_kill_streak = 0
	total_kills = 0
	is_rage_mode = false
	rage_timer = 0.0
	rage_combo = 0
	_combo_timer = 0.0
	_kill_streak_timer = 0.0
	_kill_timestamps.clear()
	_rage_activations = 0
	_massacre_count = 0
	_longest_rage_combo = 0
	_last_decay_warning_emitted = false

## 获取统计数据（用于结算界面）
func get_stats() -> Dictionary:
	return {
		"max_combo": max_combo,
		"total_kills": total_kills,
		"max_kill_streak": max_kill_streak,
		"score": get_score(),
		"rank": get_rank(),
		"rage_activations": _rage_activations,
		"massacre_count": _massacre_count,
		"longest_rage_combo": _longest_rage_combo,
		"total_rage_kills": 0,  # 可在暴走期间累计
	}

# =============================================================================
# 生命周期
# =============================================================================

func _process(delta: float) -> void:
	# 连击超时
	if _combo_timer > 0:
		_combo_timer -= delta

		# 连击即将中断时发出警告
		if _combo_timer > 0 and _combo_timer <= combo_decay_warning_time and not _last_decay_warning_emitted:
			_last_decay_warning_emitted = true
			combo_decay_warning.emit(_combo_timer)

		if _combo_timer <= 0:
			break_combo()

	# 连杀超时
	if _kill_streak_timer > 0:
		_kill_streak_timer -= delta
		if _kill_streak_timer <= 0:
			break_kill_streak()

	# 暴走模式计时
	if is_rage_mode:
		rage_timer -= delta
		if rage_timer <= 0:
			_deactivate_rage_mode()

# =============================================================================
# 私有方法
# =============================================================================

func _check_milestone() -> void:
	for milestone in MILESTONES:
		if combo_count == milestone:
			combo_milestone.emit(milestone)
			# 里程碑反馈：连击越高，反馈越强
			var shake_intensity: float = 3.0 + milestone * 0.02
			screen_shake.emit(shake_intensity, 0.2)
			slow_motion.emit(0.15, 0.5)
			print("[ComboSystem] 连击里程碑: %d!" % milestone)
			break

## 检查连杀里程碑
func _check_kill_streak_milestone() -> void:
	for milestone in KILL_STREAK_MILESTONES:
		if kill_streak_count == milestone:
			# 连杀里程碑使用较弱的反馈
			screen_shake.emit(2.0 + milestone * 0.1, 0.15)
			slow_motion.emit(0.1, 0.3)
			print("[ComboSystem] 连杀里程碑: %d杀!" % milestone)
			break

func _check_massacre() -> void:
	if _kill_timestamps.size() >= MASSACRE_KILL_COUNT:
		var latest: float = _kill_timestamps[-1]
		var oldest: float = _kill_timestamps[-MASSACRE_KILL_COUNT]
		if latest - oldest <= MASSACRE_WINDOW:
			_massacre_count += 1
			massacre_triggered.emit()
			screen_shake.emit(10.0, 0.5)
			slow_motion.emit(0.3, 0.3)
			print("[ComboSystem] 大屠杀! (第%d次)" % _massacre_count)

func _cleanup_old_kill_timestamps() -> void:
	var current_time: float = Time.get_ticks_msec() / 1000.0
	while _kill_timestamps.size() > 50:
		_kill_timestamps.pop_front()
	# 清理超过10秒的旧记录
	while not _kill_timestamps.is_empty() and current_time - _kill_timestamps[0] > 10.0:
		_kill_timestamps.pop_front()

func _deactivate_rage_mode() -> void:
	is_rage_mode = false
	rage_timer = 0.0
	rage_mode_deactivated.emit()
	print("[ComboSystem] 暴走模式结束. 暴走连击: %d" % rage_combo)

func _process_hit_feedback() -> void:
	# 根据连击数提供不同级别的反馈
	if combo_count >= 100:
		screen_shake.emit(2.0, 0.05)
	elif combo_count >= 50:
		screen_shake.emit(1.0, 0.03)
	elif combo_count >= 10:
		screen_shake.emit(0.5, 0.02)

func _process_kill_feedback(kill_data: Dictionary) -> void:
	# 击杀时的爽感反馈
	var is_elite: bool = kill_data.get("is_elite", false)
	var is_boss: bool = kill_data.get("is_boss", false)

	if is_boss:
		screen_shake.emit(15.0, 0.5)
		slow_motion.emit(0.5, 0.3)
	elif is_elite:
		screen_shake.emit(5.0, 0.2)
		slow_motion.emit(0.15, 0.5)
	else:
		# 普通击杀微震
		screen_shake.emit(1.0, 0.05)
