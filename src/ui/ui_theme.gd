## Void Hunter - UI主题配置
## @description: 统一的UI样式、颜色和字体配置
## @author: Void Hunter Team
## @version: 1.0.0

extends Resource
class_name UITheme

# =============================================================================
# 颜色定义
# =============================================================================

## 主色调
const COLOR_PRIMARY: Color = Color(0.4, 0.6, 0.9)           ## 主色（蓝紫）
const COLOR_PRIMARY_DARK: Color = Color(0.3, 0.4, 0.7)      ## 主色深色
const COLOR_PRIMARY_LIGHT: Color = Color(0.5, 0.7, 1.0)     ## 主色浅色

## 辅助色
const COLOR_SECONDARY: Color = Color(0.9, 0.6, 0.3)         ## 辅助色（橙色）
const COLOR_SECONDARY_DARK: Color = Color(0.7, 0.4, 0.2)    ## 辅助色深色

## 状态颜色
const COLOR_SUCCESS: Color = Color(0.3, 0.8, 0.4)           ## 成功（绿色）
const COLOR_WARNING: Color = Color(0.9, 0.8, 0.2)           ## 警告（黄色）
const COLOR_DANGER: Color = Color(0.9, 0.3, 0.3)            ## 危险（红色）
const COLOR_INFO: Color = Color(0.3, 0.7, 0.9)              ## 信息（蓝色）

## 属性颜色
const COLOR_HEALTH: Color = Color(0.9, 0.25, 0.25)          ## 生命值（红色）
const COLOR_HEALTH_LOW: Color = Color(1.0, 0.1, 0.1)        ## 低生命值（亮红）
const COLOR_MANA: Color = Color(0.25, 0.5, 0.95)            ## 法力值（蓝色）
const COLOR_STAMINA: Color = Color(0.9, 0.7, 0.2)           ## 体力值（黄色）
const COLOR_EXPERIENCE: Color = Color(0.6, 0.3, 0.9)        ## 经验值（紫色）

## 文字颜色
const COLOR_TEXT_PRIMARY: Color = Color(1.0, 1.0, 1.0)      ## 主要文字（白色）
const COLOR_TEXT_SECONDARY: Color = Color(0.8, 0.8, 0.8)    ## 次要文字（灰色）
const COLOR_TEXT_DISABLED: Color = Color(0.5, 0.5, 0.5)     ## 禁用文字（深灰）
const COLOR_TEXT_LINK: Color = Color(0.4, 0.7, 1.0)         ## 链接文字（浅蓝）

## 背景颜色
const COLOR_BG_PRIMARY: Color = Color(0.1, 0.1, 0.15, 0.95)    ## 主要背景（深蓝黑）
const COLOR_BG_SECONDARY: Color = Color(0.15, 0.15, 0.2, 0.95) ## 次要背景
const COLOR_BG_PANEL: Color = Color(0.08, 0.08, 0.12, 0.9)     ## 面板背景
const COLOR_BG_OVERLAY: Color = Color(0, 0, 0, 0.7)            ## 遮罩层

## 边框颜色
const COLOR_BORDER: Color = Color(0.4, 0.4, 0.5)            ## 边框
const COLOR_BORDER_FOCUS: Color = COLOR_PRIMARY             ## 焦点边框
const COLOR_BORDER_HOVER: Color = Color(0.6, 0.6, 0.7)      ## 悬停边框

## 像素边框阴影颜色
const COLOR_PIXEL_SHADOW: Color = Color(0, 0, 0, 0.5)       ## 像素阴影
const COLOR_PIXEL_HIGHLIGHT: Color = Color(1, 1, 1, 0.2)    ## 像素高光

# =============================================================================
# 尺寸定义
# =============================================================================

## 圆角
const BORDER_RADIUS_SMALL: int = 4
const BORDER_RADIUS_MEDIUM: int = 8
const BORDER_RADIUS_LARGE: int = 12

## 边框宽度
const BORDER_WIDTH: int = 2

## 间距
const SPACING_XS: int = 4
const SPACING_SM: int = 8
const SPACING_MD: int = 16
const SPACING_LG: int = 24
const SPACING_XL: int = 32

## 按钮尺寸
const BUTTON_HEIGHT_SM: int = 28
const BUTTON_HEIGHT_MD: int = 40
const BUTTON_HEIGHT_LG: int = 52
const BUTTON_MIN_WIDTH: int = 120

## 图标尺寸
const ICON_SIZE_SM: int = 16
const ICON_SIZE_MD: int = 24
const ICON_SIZE_LG: int = 32
const ICON_SIZE_XL: int = 48

## 进度条
const PROGRESS_BAR_HEIGHT: int = 20
const PROGRESS_BAR_HEIGHT_SM: int = 12
const PROGRESS_BAR_HEIGHT_LG: int = 28

## 技能/物品槽
const SLOT_SIZE: int = 64
const SLOT_SIZE_SM: int = 48
const SLOT_SIZE_LG: int = 80

# =============================================================================
# 字体定义
# =============================================================================

## 字体大小
const FONT_SIZE_XS: int = 12
const FONT_SIZE_SM: int = 14
const FONT_SIZE_MD: int = 16
const FONT_SIZE_LG: int = 20
const FONT_SIZE_XL: int = 24
const FONT_SIZE_TITLE: int = 32
const FONT_SIZE_DISPLAY: int = 48

## 字体粗细
enum FontWeight {
	LIGHT,
	REGULAR,
	MEDIUM,
	BOLD,
	BLACK
}

# =============================================================================
# 动画时间
# =============================================================================

## 动画持续时间
const ANIM_DURATION_INSTANT: float = 0.1
const ANIM_DURATION_FAST: float = 0.2
const ANIM_DURATION_NORMAL: float = 0.3
const ANIM_DURATION_SLOW: float = 0.5

## 缓动曲线
const EASE_OUT: int = Tween.EaseType.EASE_OUT
const EASE_IN: int = Tween.EaseType.EASE_IN
const EASE_IN_OUT: int = Tween.EaseType.EASE_IN_OUT
const TRANS_QUAD: int = Tween.TransitionType.TRANS_QUAD
const TRANS_CUBIC: int = Tween.TransitionType.TRANS_CUBIC
const TRANS_ELASTIC: int = Tween.TransitionType.TRANS_ELASTIC

# =============================================================================
# 静态方法 - 样式生成
# =============================================================================

## 创建像素风格边框样式
static func create_pixel_border_style(
	control: Control,
	bg_color: Color = COLOR_BG_PANEL,
	border_color: Color = COLOR_BORDER
) -> void:
	"""
	为控件添加像素风格边框
	@param control: 目标控件
	@param bg_color: 背景颜色
	@param border_color: 边框颜色
	"""
	# 创建背景
	var bg := StyleBoxFlat.new()
	bg.bg_color = bg_color
	bg.border_color = border_color
	bg.set_border_width_all(BORDER_WIDTH)
	bg.set_corner_radius_all(0)  # 像素风格无圆角
	bg.shadow_color = COLOR_PIXEL_SHADOW
	bg.shadow_size = 4
	bg.shadow_offset = Vector2(4, 4)
	
	# 应用样式
	control.add_theme_stylebox_override("panel", bg)


## 创建按钮样式
static func create_button_style(
	button: Button,
	is_primary: bool = false,
	size: String = "md"
) -> void:
	"""
	为按钮创建样式
	@param button: 按钮控件
	@param is_primary: 是否为主要按钮
	@param size: 按钮尺寸 (sm/md/lg)
	"""
	# 确定颜色
	var normal_color: Color = COLOR_PRIMARY if is_primary else COLOR_BG_SECONDARY
	var hover_color: Color = normal_color.lightened(0.15)
	var pressed_color: Color = normal_color.darkened(0.15)
	var disabled_color: Color = Color(0.3, 0.3, 0.3)
	
	# 确定高度
	var height: int = BUTTON_HEIGHT_MD
	match size:
		"sm": height = BUTTON_HEIGHT_SM
		"lg": height = BUTTON_HEIGHT_LG
	
	# 创建各状态样式
	var normal_style := _create_button_stylebox(normal_color)
	var hover_style := _create_button_stylebox(hover_color)
	var pressed_style := _create_button_stylebox(pressed_color)
	var disabled_style := _create_button_stylebox(disabled_color, true)
	
	# 应用样式
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("disabled", disabled_style)
	
	# 设置字体颜色
	button.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
	button.add_theme_color_override("font_hover_color", COLOR_TEXT_PRIMARY)
	button.add_theme_color_override("font_pressed_color", COLOR_TEXT_SECONDARY)
	button.add_theme_color_override("font_disabled_color", COLOR_TEXT_DISABLED)
	
	# 设置最小尺寸
	button.custom_minimum_size.y = height


## 创建内部按钮样式盒子
static func _create_button_stylebox(bg_color: Color, is_disabled: bool = false) -> StyleBoxFlat:
	"""
	创建按钮样式盒子
	@param bg_color: 背景颜色
	@param is_disabled: 是否禁用
	@return: 样式盒子
	"""
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = COLOR_BORDER if not is_disabled else Color(0.3, 0.3, 0.3)
	style.set_border_width_all(BORDER_WIDTH)
	style.set_corner_radius_all(BORDER_RADIUS_SMALL)
	style.content_margin_left = SPACING_MD
	style.content_margin_right = SPACING_MD
	style.content_margin_top = SPACING_SM
	style.content_margin_bottom = SPACING_SM
	
	return style


## 创建进度条样式
static func create_progress_bar_style(
	progress_bar: ProgressBar,
	fill_color: Color = COLOR_PRIMARY,
	bg_color: Color = COLOR_BG_PANEL
) -> void:
	"""
	为进度条创建样式
	@param progress_bar: 进度条控件
	@param fill_color: 填充颜色
	@param bg_color: 背景颜色
	"""
	# 背景样式
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = bg_color
	bg_style.border_color = COLOR_BORDER
	bg_style.set_border_width_all(BORDER_WIDTH)
	bg_style.set_corner_radius_all(BORDER_RADIUS_SMALL)
	
	# 填充样式
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = fill_color
	fill_style.set_corner_radius_all(BORDER_RADIUS_SMALL - 2)
	
	progress_bar.add_theme_stylebox_override("background", bg_style)
	progress_bar.add_theme_stylebox_override("fill", fill_style)


## 创建面板样式
static func create_panel_style(panel: Control, with_shadow: bool = true) -> void:
	"""
	为面板创建样式
	@param panel: 面板控件
	@param with_shadow: 是否添加阴影
	"""
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_BG_PANEL
	style.border_color = COLOR_BORDER
	style.set_border_width_all(BORDER_WIDTH)
	style.set_corner_radius_all(BORDER_RADIUS_MEDIUM)
	style.content_margin_left = SPACING_MD
	style.content_margin_right = SPACING_MD
	style.content_margin_top = SPACING_MD
	style.content_margin_bottom = SPACING_MD
	
	if with_shadow:
		style.shadow_color = COLOR_PIXEL_SHADOW
		style.shadow_size = 8
		style.shadow_offset = Vector2(4, 4)
	
	panel.add_theme_stylebox_override("panel", style)


## 创建槽位样式
static func create_slot_style(slot: Control, is_empty: bool = true) -> void:
	"""
	为技能/物品槽位创建样式
	@param slot: 槽位控件
	@param is_empty: 是否为空槽位
	"""
	var style := StyleBoxFlat.new()
	
	if is_empty:
		style.bg_color = Color(0.1, 0.1, 0.15, 0.8)
		style.border_color = Color(0.3, 0.3, 0.4)
	else:
		style.bg_color = COLOR_BG_SECONDARY
		style.border_color = COLOR_PRIMARY
	
	style.set_border_width_all(BORDER_WIDTH)
	style.set_corner_radius_all(BORDER_RADIUS_SMALL)
	
	slot.add_theme_stylebox_override("panel", style)


# =============================================================================
# 静态方法 - 动画
# =============================================================================

## 淡入动画
static func fade_in(control: Control, duration: float = ANIM_DURATION_FAST) -> Tween:
	"""
	创建淡入动画
	@param control: 目标控件
	@param duration: 持续时间
	@return: Tween对象
	"""
	control.modulate.a = 0.0
	control.show()
	
	var tween := control.create_tween()
	tween.set_ease(EASE_OUT).set_trans(TRANS_QUAD)
	tween.tween_property(control, "modulate:a", 1.0, duration)
	
	return tween


## 淡出动画
static func fade_out(control: Control, duration: float = ANIM_DURATION_FAST, hide_on_complete: bool = true) -> Tween:
	"""
	创建淡出动画
	@param control: 目标控件
	@param duration: 持续时间
	@param hide_on_complete: 完成后是否隐藏
	@return: Tween对象
	"""
	var tween := control.create_tween()
	tween.set_ease(EASE_OUT).set_trans(TRANS_QUAD)
	tween.tween_property(control, "modulate:a", 0.0, duration)
	
	if hide_on_complete:
		tween.tween_callback(control.hide)
	
	return tween


## 滑入动画（从顶部）
static func slide_in_from_top(control: Control, duration: float = ANIM_DURATION_NORMAL) -> Tween:
	"""
	从顶部滑入动画
	@param control: 目标控件
	@param duration: 持续时间
	@return: Tween对象
	"""
	var target_position := control.position
	control.position.y = -control.size.y
	
	var tween := control.create_tween()
	tween.set_ease(EASE_OUT).set_trans(TRANS_CUBIC)
	tween.tween_property(control, "position:y", target_position.y, duration)
	
	return tween


## 滑出动画（到顶部）
static func slide_out_to_top(control: Control, duration: float = ANIM_DURATION_NORMAL) -> Tween:
	"""
	滑出到顶部动画
	@param control: 目标控件
	@param duration: 持续时间
	@return: Tween对象
	"""
	var tween := control.create_tween()
	tween.set_ease(EASE_IN).set_trans(TRANS_CUBIC)
	tween.tween_property(control, "position:y", -control.size.y - 20, duration)
	
	return tween


## 缩放弹跳动画
static func scale_bounce(control: Control, duration: float = ANIM_DURATION_NORMAL) -> Tween:
	"""
	缩放弹跳动画
	@param control: 目标控件
	@param duration: 持续时间
	@return: Tween对象
	"""
	var original_scale := control.scale
	control.scale = Vector2.ZERO
	
	var tween := control.create_tween()
	tween.set_ease(EASE_OUT).set_trans(TRANS_ELASTIC)
	tween.tween_property(control, "scale", original_scale, duration)
	
	return tween


## 抖动动画
static func shake(control: Control, intensity: float = 5.0, duration: float = 0.3) -> Tween:
	"""
	抖动动画
	@param control: 目标控件
	@param intensity: 抖动强度
	@param duration: 持续时间
	@return: Tween对象
	"""
	var original_position := control.position
	var tween := control.create_tween()
	
	for i in range(3):
		var offset := Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tween.tween_property(control, "position", original_position + offset, duration / 6)
		tween.tween_property(control, "position", original_position, duration / 6)
	
	return tween


## 脉冲动画
static func pulse(control: Control, scale_amount: float = 1.1, duration: float = ANIM_DURATION_NORMAL) -> Tween:
	"""
	脉冲动画
	@param control: 目标控件
	@param scale_amount: 缩放倍数
	@param duration: 持续时间
	@return: Tween对象
	"""
	var original_scale := control.scale
	var tween := control.create_tween()
	
	tween.set_ease(EASE_IN_OUT).set_trans(TRANS_QUAD)
	tween.tween_property(control, "scale", original_scale * scale_amount, duration / 2)
	tween.tween_property(control, "scale", original_scale, duration / 2)
	
	return tween


# =============================================================================
# 静态方法 - 工具
# =============================================================================

## 格式化时间
static func format_time(seconds: float) -> String:
	"""
	将秒数格式化为时间字符串
	@param seconds: 秒数
	@return: 格式化的时间字符串
	"""
	var mins := int(seconds) / 60
	var secs := int(seconds) % 60
	return "%02d:%02d" % [mins, secs]


## 格式化大数字
static func format_number(number: int) -> String:
	"""
	格式化大数字（添加逗号分隔）
	@param number: 数字
	@return: 格式化的字符串
	"""
	var str_num := str(number)
	var result := ""
	var count := 0
	
	for i in range(str_num.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = str_num[i] + result
		count += 1
	
	return result


## 获取生命值颜色
static func get_health_color(health_percent: float) -> Color:
	"""
	根据生命值百分比获取颜色
	@param health_percent: 生命值百分比 (0.0 - 1.0)
	@return: 颜色
	"""
	if health_percent > 0.6:
		return COLOR_SUCCESS
	elif health_percent > 0.3:
		return COLOR_WARNING
	else:
		return COLOR_DANGER


## 获取稀有度颜色
static func get_rarity_color(rarity: String) -> Color:
	"""
	根据稀有度获取颜色
	@param rarity: 稀有度名称
	@return: 颜色
	"""
	match rarity.to_lower():
		"common", "普通":
			return Color(0.7, 0.7, 0.7)
		"uncommon", "稀有":
			return COLOR_SUCCESS
		"rare", "精良":
			return COLOR_INFO
		"epic", "史诗":
			return Color(0.6, 0.3, 0.9)
		"legendary", "传说":
			return COLOR_SECONDARY
		_:
			return Color.WHITE
