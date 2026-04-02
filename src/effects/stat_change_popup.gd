## Void Hunter - 属性变化浮动文字效果
## @description: 显示属性加成的浮动文字，如 "+10% 攻击力"、"+20 生命值" 等
## @author: Void Hunter Team
## @version: 1.0.0

extends Node2D
class_name StatChangePopup

# =============================================================================
# 信号定义
# =============================================================================

## 动画完成时触发
signal animation_finished()

# =============================================================================
# 常量定义
# =============================================================================

## 属性类型枚举
enum StatType {
	ATTACK,		## 攻击力
	HEALTH,		## 生命值
	SPEED,		## 移动速度
	CRIT,		## 暴击率
	LIFE_STEAL,	## 吸血
	DEFENSE,	## 防御力
	MANA,		## 法力值
	GENERIC		## 通用
}

## 动画持续时间
const ANIM_DURATION: float = 1.5

## 飘动速度（向上）
const FLOAT_SPEED: float = -60.0

## 水平漂移范围
const DRIFT_RANGE: float = 25.0

## 随机位置偏移
const RANDOM_OFFSET: float = 15.0

## 属性类型对应的颜色
const STAT_COLORS: Array[Color] = [
	Color(1.0, 0.3, 0.3),		## 红色 - 攻击力 (0)
	Color(0.3, 0.9, 0.4),		## 绿色 - 生命值 (1)
	Color(1.0, 0.9, 0.3),		## 黄色 - 速度 (2)
	Color(1.0, 0.6, 0.2),		## 橙色 - 暴击 (3)
	Color(0.7, 0.3, 0.9),		## 紫色 - 吸血 (4)
	Color(0.4, 0.7, 1.0),		## 蓝色 - 防御 (5)
	Color(0.3, 0.5, 1.0),		## 深蓝色 - 法力 (6)
	Color(1.0, 1.0, 1.0)		## 白色 - 通用 (7)
]

## 属性类型对应的中文名称
const STAT_NAMES: Array[String] = [
	"攻击力",		## (0)
	"生命值",		## (1)
	"移动速度",		## (2)
	"暴击率",		## (3)
	"吸血",			## (4)
	"防御力",		## (5)
	"法力值",		## (6)
	""				## 通用 (7)
]

# =============================================================================
# 私有变量
# =============================================================================

var _label: Label = null
var _stat_type: int = StatType.GENERIC
var _value: float = 0.0
var _is_percent: bool = false
var _custom_text: String = ""
var _start_position: Vector2 = Vector2.ZERO
var _current_position: Vector2 = Vector2.ZERO
var _drift_direction: float = 0.0
var _time_elapsed: float = 0.0
var _is_animating: bool = false

# =============================================================================
# 公共方法
# =============================================================================

## 设置浮动文字
func setup(
	stat_type: int,
	value: float,
	is_percent: bool = true,
	custom_text: String = ""
) -> void:
	"""
	设置浮动文字
	@param stat_type: 属性类型 (StatType 枚举值)
	@param value: 数值
	@param is_percent: 是否为百分比
	@param custom_text: 自定义文本
	"""
	_stat_type = stat_type
	_value = value
	_is_percent = is_percent
	_custom_text = custom_text

	_create_label()
	_apply_style()


## 开始动画
func start_animation() -> void:
	"""开始动画"""
	_is_animating = true
	_time_elapsed = 0.0

	# 设置初始位置（添加随机偏移）
	_start_position = global_position
	_current_position = _start_position
	_current_position.x += randf_range(-RANDOM_OFFSET, RANDOM_OFFSET)
	_current_position.y += randf_range(-RANDOM_OFFSET / 2, RANDOM_OFFSET / 2)
	global_position = _current_position

	# 随机漂移方向
	_drift_direction = randf_range(-DRIFT_RANGE, DRIFT_RANGE)


## 立即结束动画
func end_animation() -> void:
	"""立即结束动画"""
	_is_animating = false
	animation_finished.emit()
	queue_free()

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""节点就绪时初始化"""
	# 设置Z索引确保显示在最上层
	z_index = 110


func _process(delta: float) -> void:
	"""每帧更新动画"""
	if not _is_animating:
		return

	_time_elapsed += delta

	# 计算动画进度
	var progress: float = _time_elapsed / ANIM_DURATION

	if progress >= 1.0:
		end_animation()
		return

	# 更新位置（向上飘动 + 水平漂移）
	_current_position.y += FLOAT_SPEED * delta
	_current_position.x += _drift_direction * delta * 0.3
	global_position = _current_position

	# 更新透明度（最后0.4秒淡出）
	if progress > 0.6:
		var fade_progress: float = (progress - 0.6) / 0.4
		_label.modulate.a = 1.0 - fade_progress

	# 更新缩放（开始时弹跳放大）
	if progress < 0.15:
		var scale_progress: float = progress / 0.15
		_label.scale = Vector2.ONE * lerp(0.5, 1.2, scale_progress)
	elif progress < 0.25:
		var scale_progress: float = (progress - 0.15) / 0.1
		_label.scale = Vector2.ONE * lerp(1.2, 1.0, scale_progress)
	elif progress > 0.8:
		var shrink_progress: float = (progress - 0.8) / 0.2
		_label.scale = Vector2.ONE * lerp(1.0, 0.6, shrink_progress)

# =============================================================================
# 私有方法
# =============================================================================

func _create_label() -> void:
	"""创建标签"""
	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_CENTER)
	_label.offset_left = -100
	_label.offset_right = 100
	_label.offset_top = -20
	_label.offset_bottom = 20
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_label)

	# 设置文本
	_label.text = _format_text()


func _apply_style() -> void:
	"""应用样式"""
	# 获取颜色（确保索引在范围内）
	var color_index: int = clampi(_stat_type, 0, STAT_COLORS.size() - 1)
	var color: Color = STAT_COLORS[color_index]

	# 设置字体大小
	_label.add_theme_font_size_override("font_size", 22)

	# 设置字体颜色
	_label.add_theme_color_override("font_color", color)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 3)

	# 添加阴影效果（通过额外的阴影标签实现）
	var shadow_label := Label.new()
	shadow_label.text = _label.text
	shadow_label.add_theme_font_size_override("font_size", 22)
	shadow_label.add_theme_color_override("font_color", Color(0, 0, 0, 0.5))
	shadow_label.add_theme_constant_override("outline_size", 0)
	shadow_label.position = Vector2(2, 2)
	shadow_label.z_index = -1
	_label.add_child(shadow_label)


func _format_text() -> String:
	"""格式化文本显示"""
	# 如果有自定义文本，直接使用
	if not _custom_text.is_empty():
		return _custom_text

	# 获取属性名称（确保索引在范围内）
	var name_index: int = clampi(_stat_type, 0, STAT_NAMES.size() - 1)
	var stat_name: String = STAT_NAMES[name_index]

	# 格式化数值
	var value_text: String
	if _is_percent:
		value_text = "+%.0f%%" % (_value)
	else:
		value_text = "+%.0f" % (_value)

	# 组合文本
	if stat_name.is_empty():
		return value_text
	else:
		return "%s %s" % [value_text, stat_name]


# =============================================================================
# 静态工厂函数（通过脚本调用）
# =============================================================================

## 创建并显示属性变化浮动文字（静态方法，通过脚本调用）
static func create_popup(
	parent: Node,
	world_position: Vector2,
	stat_type: int,
	value: float,
	is_percent: bool = true,
	custom_text: String = ""
) -> Node2D:
	"""
	创建并显示属性变化浮动文字
	@param parent: 父节点
	@param world_position: 世界坐标位置
	@param stat_type: 属性类型 (StatType 枚举值)
	@param value: 数值
	@param is_percent: 是否为百分比值
	@param custom_text: 自定义文本（覆盖默认格式）
	@return: 创建的浮动文字实例
	"""
	# 使用脚本创建实例
	var script := load("res://src/effects/stat_change_popup.gd")
	var popup: Node2D = script.new() as Node2D
	popup.set_script(script)
	popup.setup(stat_type, value, is_percent, custom_text)
	popup.global_position = world_position
	parent.add_child(popup)
	popup.start_animation()
	return popup
