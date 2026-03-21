## Void Hunter - 伤害数字显示
## @description: 显示伤害、治疗、暴击等浮动数字效果
## @author: Void Hunter Team
## @version: 1.0.0

extends Node2D
class_name DamageNumber

# =============================================================================
# 信号定义
# =============================================================================

## 数字动画完成时触发
signal animation_finished()

# =============================================================================
# 常量定义
# =============================================================================

## 数字类型
enum NumberType {
	DAMAGE,		## 普通伤害
	CRITICAL,	## 暴击伤害
	HEALING,	## 治疗
	MANA,		## 法力恢复
	EXPERIENCE,	## 经验获得
	LEVEL_UP,	## 升级
	DODGE,		## 闪避
	MISS,		## 未命中
	STATUS		## 状态效果伤害
}

## 基础动画时间
const BASE_ANIM_DURATION: float = 1.0

## 数字飘动速度
const FLOAT_SPEED: float = -50.0

## 数字随机偏移范围
const RANDOM_OFFSET: float = 20.0

## 水平漂移范围
const DRIFT_RANGE: float = 30.0

# =============================================================================
# 私有变量
# =============================================================================

var _label: Label = null
var _number_type: NumberType = NumberType.DAMAGE
var _value: float = 0.0
var _start_position: Vector2 = Vector2.ZERO
var _current_position: Vector2 = Vector2.ZERO
var _drift_direction: float = 0.0
var _time_elapsed: float = 0.0
var _is_animating: bool = false

# =============================================================================
# 静态方法
# =============================================================================

## 创建并显示伤害数字
static func create(
	parent: Node,
	world_position: Vector2,
	value: float,
	type: NumberType = NumberType.DAMAGE
) -> DamageNumber:
	"""
	创建并显示伤害数字
	@param parent: 父节点
	@param world_position: 世界坐标位置
	@param value: 数值
	@param type: 数字类型
	@return: 创建的伤害数字实例
	"""
	var damage_number := DamageNumber.new()
	damage_number.setup(value, type)
	damage_number.global_position = world_position
	parent.add_child(damage_number)
	damage_number.start_animation()
	return damage_number


## 创建普通伤害数字
static func create_damage(parent: Node, world_position: Vector2, damage: float) -> DamageNumber:
	"""
	创建普通伤害数字
	@param parent: 父节点
	@param world_position: 世界坐标位置
	@param damage: 伤害值
	@return: 创建的伤害数字实例
	"""
	return create(parent, world_position, damage, NumberType.DAMAGE)


## 创建暴击伤害数字
static func create_critical(parent: Node, world_position: Vector2, damage: float) -> DamageNumber:
	"""
	创建暴击伤害数字
	@param parent: 父节点
	@param world_position: 世界坐标位置
	@param damage: 暴击伤害值
	@return: 创建的伤害数字实例
	"""
	return create(parent, world_position, damage, NumberType.CRITICAL)


## 创建治疗数字
static func create_healing(parent: Node, world_position: Vector2, healing: float) -> DamageNumber:
	"""
	创建治疗数字
	@param parent: 父节点
	@param world_position: 世界坐标位置
	@param healing: 治疗值
	@return: 创建的伤害数字实例
	"""
	return create(parent, world_position, healing, NumberType.HEALING)


## 创建经验数字
static func create_experience(parent: Node, world_position: Vector2, exp: int) -> DamageNumber:
	"""
	创建经验数字
	@param parent: 父节点
	@param world_position: 世界坐标位置
	@param exp: 经验值
	@return: 创建的伤害数字实例
	"""
	return create(parent, world_position, exp, NumberType.EXPERIENCE)


# =============================================================================
# 公共方法
# =============================================================================

## 设置伤害数字
func setup(value: float, type: NumberType = NumberType.DAMAGE) -> void:
	"""
	设置伤害数字
	@param value: 数值
	@param type: 数字类型
	"""
	_value = value
	_number_type = type
	
	_create_label()
	_apply_style()


## 开始动画
func start_animation() -> void:
	"""
	开始动画
	"""
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
	"""
	立即结束动画
	"""
	_is_animating = false
	animation_finished.emit()
	queue_free()


# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""
	节点就绪时初始化
	"""
	# 设置Z索引确保显示在最上层
	z_index = 100


func _process(delta: float) -> void:
	"""
	每帧更新动画
	@param delta: 帧间隔时间
	"""
	if not _is_animating:
		return
	
	_time_elapsed += delta
	
	# 计算动画进度
	var progress: float = _time_elapsed / BASE_ANIM_DURATION
	
	if progress >= 1.0:
		end_animation()
		return
	
	# 更新位置（向上飘动 + 水平漂移）
	_current_position.y += FLOAT_SPEED * delta
	_current_position.x += _drift_direction * delta * 0.5
	global_position = _current_position
	
	# 更新透明度（最后0.3秒淡出）
	if progress > 0.7:
		var fade_progress: float = (progress - 0.7) / 0.3
		_label.modulate.a = 1.0 - fade_progress
	
	# 更新缩放（开始时放大，然后缩小）
	if progress < 0.2:
		var scale_progress: float = progress / 0.2
		_label.scale = Vector2.ONE * lerp(1.5, 1.0, scale_progress)
	elif progress > 0.8:
		var shrink_progress: float = (progress - 0.8) / 0.2
		_label.scale = Vector2.ONE * lerp(1.0, 0.5, shrink_progress)


# =============================================================================
# 私有方法
# =============================================================================

func _create_label() -> void:
	"""
	创建标签
	"""
	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_CENTER)
	_label.offset_left = -50
	_label.offset_right = 50
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_label)
	
	# 设置文本
	_label.text = _format_value()


func _apply_style() -> void:
	"""
	应用样式
	"""
	# 根据类型设置颜色和大小
	match _number_type:
		NumberType.DAMAGE:
			_label.add_theme_font_size_override("font_size", UITheme.FONT_SIZE_LG)
			_label.add_theme_color_override("font_color", Color.WHITE)
			_label.add_theme_color_override("font_outline_color", Color.BLACK)
			_label.add_theme_constant_override("outline_size", 3)
		
		NumberType.CRITICAL:
			_label.add_theme_font_size_override("font_size", UITheme.FONT_SIZE_XL)
			_label.add_theme_color_override("font_color", Color.YELLOW)
			_label.add_theme_color_override("font_outline_color", Color.RED)
			_label.add_theme_constant_override("outline_size", 4)
		
		NumberType.HEALING:
			_label.add_theme_font_size_override("font_size", UITheme.FONT_SIZE_LG)
			_label.add_theme_color_override("font_color", UITheme.COLOR_SUCCESS)
			_label.add_theme_color_override("font_outline_color", Color.BLACK)
			_label.add_theme_constant_override("outline_size", 3)
		
		NumberType.MANA:
			_label.add_theme_font_size_override("font_size", UITheme.FONT_SIZE_MD)
			_label.add_theme_color_override("font_color", UITheme.COLOR_MANA)
			_label.add_theme_color_override("font_outline_color", Color.BLACK)
			_label.add_theme_constant_override("outline_size", 2)
		
		NumberType.EXPERIENCE:
			_label.add_theme_font_size_override("font_size", UITheme.FONT_SIZE_MD)
			_label.add_theme_color_override("font_color", UITheme.COLOR_EXPERIENCE)
			_label.add_theme_color_override("font_outline_color", Color.BLACK)
			_label.add_theme_constant_override("outline_size", 2)
		
		NumberType.LEVEL_UP:
			_label.add_theme_font_size_override("font_size", UITheme.FONT_SIZE_TITLE)
			_label.add_theme_color_override("font_color", Color.YELLOW)
			_label.add_theme_color_override("font_outline_color", Color.BLACK)
			_label.add_theme_constant_override("outline_size", 4)
		
		NumberType.DODGE:
			_label.add_theme_font_size_override("font_size", UITheme.FONT_SIZE_MD)
			_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
			_label.add_theme_color_override("font_outline_color", Color.BLACK)
			_label.add_theme_constant_override("outline_size", 2)
		
		NumberType.MISS:
			_label.add_theme_font_size_override("font_size", UITheme.FONT_SIZE_MD)
			_label.add_theme_color_override("font_color", Color.GRAY)
			_label.add_theme_color_override("font_outline_color", Color.BLACK)
			_label.add_theme_constant_override("outline_size", 2)
		
		NumberType.STATUS:
			_label.add_theme_font_size_override("font_size", UITheme.FONT_SIZE_SM)
			_label.add_theme_color_override("font_color", Color.ORANGE)
			_label.add_theme_color_override("font_outline_color", Color.BLACK)
			_label.add_theme_constant_override("outline_size", 2)


func _format_value() -> String:
	"""
	格式化数值显示
	@return: 格式化的字符串
	"""
	var formatted: String = ""
	
	match _number_type:
		NumberType.DAMAGE, NumberType.STATUS:
			formatted = str(int(_value))
		
		NumberType.CRITICAL:
			formatted = str(int(_value)) + "!"
		
		NumberType.HEALING, NumberType.MANA:
			formatted = "+" + str(int(_value))
		
		NumberType.EXPERIENCE:
			formatted = "+" + str(int(_value)) + " EXP"
		
		NumberType.LEVEL_UP:
			formatted = tr("UI_LEVEL_UP")
		
		NumberType.DODGE:
			formatted = tr("UI_DODGE")
		
		NumberType.MISS:
			formatted = tr("UI_MISS")
	
	return formatted


# =============================================================================
# 管理器类 - 伤害数字管理器
# =============================================================================

## 伤害数字管理器（用于批量管理和优化）
class DamageNumberManager extends Node:
	"""
	伤害数字管理器
	用于管理场景中所有的伤害数字，支持对象池优化
	"""
	
	## 对象池大小
	const POOL_SIZE: int = 20
	
	## 活跃的伤害数字列表
	var _active_numbers: Array[DamageNumber] = []
	
	## 伤害数字对象池
	var _number_pool: Array[DamageNumber] = []
	
	## 父节点引用
	var _parent: Node = null
	
	
	func _init(parent: Node) -> void:
		"""
		初始化管理器
		@param parent: 父节点
		"""
		_parent = parent
		_initialize_pool()
	
	
	func _initialize_pool() -> void:
		"""
		初始化对象池
		"""
		for i in range(POOL_SIZE):
			var damage_number := DamageNumber.new()
			damage_number.hide()
			_number_pool.append(damage_number)
	
	
	func spawn_number(
		world_position: Vector2,
		value: float,
		type: DamageNumber.NumberType = DamageNumber.NumberType.DAMAGE
	) -> DamageNumber:
		"""
		生成伤害数字
		@param world_position: 世界坐标
		@param value: 数值
		@param type: 类型
		@return: 伤害数字实例
		"""
		var damage_number: DamageNumber
		
		# 从对象池获取或创建新的
		if _number_pool.is_empty():
			damage_number = DamageNumber.new()
		else:
			damage_number = _number_pool.pop_back()
		
		# 设置并显示
		damage_number.setup(value, type)
		damage_number.global_position = world_position
		damage_number.show()
		_parent.add_child(damage_number)
		damage_number.start_animation()
		
		# 添加到活跃列表
		_active_numbers.append(damage_number)
		
		# 连接完成信号
		damage_number.animation_finished.connect(
			_on_number_finished.bind(damage_number),
			CONNECT_ONE_SHOT
		)
		
		return damage_number
	
	
	func _on_number_finished(damage_number: DamageNumber) -> void:
		"""
		伤害数字动画完成回调
		@param damage_number: 完成的伤害数字
		"""
		_active_numbers.erase(damage_number)
		
		# 回收到对象池
		if _number_pool.size() < POOL_SIZE:
			damage_number.get_parent().remove_child(damage_number)
			damage_number.hide()
			_number_pool.append(damage_number)
	
	
	func clear_all() -> void:
		"""
		清除所有活跃的伤害数字
		"""
		for damage_number in _active_numbers:
			if is_instance_valid(damage_number):
				damage_number.queue_free()
		
		_active_numbers.clear()
	
	
	func get_active_count() -> int:
		"""
		获取活跃的伤害数字数量
		@return: 数量
		"""
		return _active_numbers.size()
