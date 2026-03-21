## Void Hunter - 通知系统
## @description: 管理游戏内各种通知的显示，包括成就解锁、角色解锁、道具获得等
## @author: Void Hunter Team
## @version: 1.0.0

extends CanvasLayer
class_name NotificationSystem

# =============================================================================
# 信号定义
# =============================================================================

## 通知显示时触发
signal notification_shown(notification_type: String, message: String)

## 通知消失时触发
signal notification_hidden(notification_type: String)

# =============================================================================
# 常量定义
# =============================================================================

## 通知类型
enum NotificationType {
	ACHIEVEMENT,	## 成就解锁
	CHARACTER,		## 角色解锁
	ITEM,			## 道具获得
	SKILL,			## 技能升级
	WAVE,			## 波次开始
	LEVEL_UP,		## 升级
	WARNING,		## 警告
	INFO			## 普通信息
}

## 通知显示时间（秒）
const NOTIFICATION_DURATION: float = 3.0

## 通知动画时间（秒）
const ANIM_DURATION: float = 0.3

## 最大同时显示通知数
const MAX_NOTIFICATIONS: int = 5

## 通知间距
const NOTIFICATION_SPACING: int = 10

# =============================================================================
# 节点引用
# =============================================================================

## 通知容器
@onready var notification_container: VBoxContainer = $NotificationContainer

# =============================================================================
# 私有变量
# =============================================================================

var _active_notifications: Array[Control] = []
var _notification_queue: Array[Dictionary] = []

# 通知图标缓存
var _icon_cache: Dictionary = {}

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""
	节点就绪时初始化通知系统
	"""
	_initialize_system()
	_connect_signals()


# =============================================================================
# 公共方法
# =============================================================================

## 显示通知
func show_notification(
	type: NotificationType,
	title: String,
	message: String,
	icon: Texture2D = null,
	duration: float = NOTIFICATION_DURATION
) -> void:
	"""
	显示通知
	@param type: 通知类型
	@param title: 标题
	@param message: 消息内容
	@param icon: 图标（可选）
	@param duration: 显示时间
	"""
	var notification_data: Dictionary = {
		"type": type,
		"title": title,
		"message": message,
		"icon": icon,
		"duration": duration
	}
	
	# 如果当前显示的通知数量已达上限，加入队列
	if _active_notifications.size() >= MAX_NOTIFICATIONS:
		_notification_queue.append(notification_data)
	else:
		_create_notification(notification_data)


## 显示成就解锁通知
func show_achievement(achievement_name: String, description: String = "") -> void:
	"""
	显示成就解锁通知
	@param achievement_name: 成就名称
	@param description: 成就描述
	"""
	show_notification(
		NotificationType.ACHIEVEMENT,
		tr("NOTIFICATION_ACHIEVEMENT_UNLOCKED"),
		achievement_name,
		null,
		4.0
	)
	AudioManager.play_sfx("achievement_unlock")


## 显示角色解锁通知
func show_character_unlocked(character_name: String) -> void:
	"""
	显示角色解锁通知
	@param character_name: 角色名称
	"""
	show_notification(
		NotificationType.CHARACTER,
		tr("NOTIFICATION_CHARACTER_UNLOCKED"),
		character_name,
		null,
		4.0
	)
	AudioManager.play_sfx("character_unlock")


## 显示道具获得通知
func show_item_obtained(item_name: String, rarity: String = "common") -> void:
	"""
	显示道具获得通知
	@param item_name: 道具名称
	@param rarity: 稀有度
	"""
	show_notification(
		NotificationType.ITEM,
		tr("NOTIFICATION_ITEM_OBTAINED"),
		item_name + " (" + tr("RARITY_" + rarity.to_upper()) + ")",
		null,
		3.0
	)
	AudioManager.play_sfx("item_pickup")


## 显示技能升级通知
func show_skill_upgraded(skill_name: String, new_level: int) -> void:
	"""
	显示技能升级通知
	@param skill_name: 技能名称
	@param new_level: 新等级
	"""
	show_notification(
		NotificationType.SKILL,
		tr("NOTIFICATION_SKILL_UPGRADED"),
		skill_name + " Lv." + str(new_level),
		null,
		2.5
	)
	AudioManager.play_sfx("skill_upgrade")


## 显示波次开始通知
func show_wave_start(wave_number: int) -> void:
	"""
	显示波次开始通知
	@param wave_number: 波次号
	"""
	show_notification(
		NotificationType.WAVE,
		tr("NOTIFICATION_WAVE_START") % wave_number,
		"",
		null,
		2.0
	)


## 显示升级通知
func show_level_up(new_level: int) -> void:
	"""
	显示升级通知
	@param new_level: 新等级
	"""
	show_notification(
		NotificationType.LEVEL_UP,
		tr("NOTIFICATION_LEVEL_UP") % new_level,
		"",
		null,
		2.0
	)
	AudioManager.play_sfx("level_up")


## 显示警告通知
func show_warning(message: String) -> void:
	"""
	显示警告通知
	@param message: 警告消息
	"""
	show_notification(
		NotificationType.WARNING,
		tr("NOTIFICATION_WARNING"),
		message,
		null,
		4.0
	)
	AudioManager.play_sfx("warning")


## 显示普通信息通知
func show_info(message: String) -> void:
	"""
	显示普通信息通知
	@param message: 信息内容
	"""
	show_notification(
		NotificationType.INFO,
		"",
		message,
		null,
		2.0
	)


## 清除所有通知
func clear_all_notifications() -> void:
	"""
	清除所有通知
	"""
	for notification in _active_notifications:
		_hide_notification(notification, true)
	
	_active_notifications.clear()
	_notification_queue.clear()


# =============================================================================
# 私有方法 - 初始化
# =============================================================================

func _initialize_system() -> void:
	"""
	初始化通知系统
	"""
	# 设置通知容器位置（右上角）
	notification_container.anchors_preset = Control.PRESET_TOP_RIGHT
	notification_container.offset_left = -350
	notification_container.offset_top = 20
	notification_container.offset_right = -20


func _connect_signals() -> void:
	"""
	连接信号
	"""
	# 连接游戏管理器信号
	GameManager.achievement_unlocked.connect(_on_achievement_unlocked)


# =============================================================================
# 私有方法 - 通知创建
# =============================================================================

func _create_notification(data: Dictionary) -> Control:
	"""
	创建通知控件
	@param data: 通知数据
	@return: 通知控件
	"""
	var type: NotificationType = data.get("type", NotificationType.INFO)
	var title: String = data.get("title", "")
	var message: String = data.get("message", "")
	var icon: Texture2D = data.get("icon", null)
	var duration: float = data.get("duration", NOTIFICATION_DURATION)
	
	# 创建通知面板
	var notification := Panel.new()
	notification.custom_minimum_size = Vector2(320, 80)
	
	# 应用样式
	_apply_notification_style(notification, type)
	
	# 创建内容容器
	var content := HBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.add_theme_constant_override("separation", UITheme.SPACING_MD)
	content.offset_left = UITheme.SPACING_MD
	content.offset_right = -UITheme.SPACING_MD
	content.offset_top = UITheme.SPACING_SM
	content.offset_bottom = -UITheme.SPACING_SM
	notification.add_child(content)
	
	# 创建图标（如果有的话）
	if icon or type != NotificationType.INFO:
		var icon_rect := TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(UITheme.ICON_SIZE_LG, UITheme.ICON_SIZE_LG)
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.texture = icon if icon else _get_type_icon(type)
		content.add_child(icon_rect)
	
	# 创建文本容器
	var text_container := VBoxContainer.new()
	text_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_container.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_child(text_container)
	
	# 添加标题（如果有）
	if not title.is_empty():
		var title_label := Label.new()
		title_label.text = title
		title_label.add_theme_font_size_override("font_size", UITheme.FONT_SIZE_MD)
		title_label.add_theme_color_override("font_color", _get_type_color(type))
		title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text_container.add_child(title_label)
	
	# 添加消息
	if not message.is_empty():
		var message_label := Label.new()
		message_label.text = message
		message_label.add_theme_font_size_override("font_size", UITheme.FONT_SIZE_SM)
		message_label.add_theme_color_override("font_color", UITheme.COLOR_TEXT_SECONDARY)
		message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text_container.add_child(message_label)
	
	# 添加到容器
	notification_container.add_child(notification)
	_active_notifications.append(notification)
	
	# 播放进入动画
	_play_notification_in_animation(notification)
	
	# 设置自动消失
	var timer := get_tree().create_timer(duration)
	timer.timeout.connect(_hide_notification.bind(notification))
	
	# 发送信号
	notification_shown.emit(NotificationType.keys()[type], message)
	
	return notification


func _apply_notification_style(notification: Panel, type: NotificationType) -> void:
	"""
	应用通知样式
	@param notification: 通知控件
	@param type: 通知类型
	"""
	var style := StyleBoxFlat.new()
	style.bg_color = UITheme.COLOR_BG_PANEL
	style.border_color = _get_type_color(type)
	style.set_border_width_all(UITheme.BORDER_WIDTH)
	style.set_corner_radius_all(UITheme.BORDER_RADIUS_MEDIUM)
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 4
	style.shadow_offset = Vector2(2, 2)
	
	notification.add_theme_stylebox_override("panel", style)


func _get_type_color(type: NotificationType) -> Color:
	"""
	获取通知类型对应的颜色
	@param type: 通知类型
	@return: 颜色
	"""
	match type:
		NotificationType.ACHIEVEMENT:
			return Color.GOLD
		NotificationType.CHARACTER:
			return UITheme.COLOR_PRIMARY
		NotificationType.ITEM:
			return UITheme.COLOR_SECONDARY
		NotificationType.SKILL:
			return UITheme.COLOR_EXPERIENCE
		NotificationType.WAVE:
			return UITheme.COLOR_DANGER
		NotificationType.LEVEL_UP:
			return Color.YELLOW
		NotificationType.WARNING:
			return UITheme.COLOR_WARNING
		_:
			return UITheme.COLOR_TEXT_SECONDARY


func _get_type_icon(type: NotificationType) -> Texture2D:
	"""
	获取通知类型对应的图标
	@param type: 通知类型
	@return: 图标纹理
	"""
	# TODO: 加载实际图标资源
	# 这里返回null，实际使用时应该加载对应的图标
	return null


# =============================================================================
# 私有方法 - 动画
# =============================================================================

func _play_notification_in_animation(notification: Control) -> void:
	"""
	播放通知进入动画
	@param notification: 通知控件
	"""
	notification.modulate.a = 0.0
	notification.position.x = 50
	
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(notification, "modulate:a", 1.0, ANIM_DURATION)
	tween.parallel().tween_property(notification, "position:x", 0, ANIM_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _play_notification_out_animation(notification: Control) -> void:
	"""
	播放通知退出动画
	@param notification: 通知控件
	"""
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(notification, "modulate:a", 0.0, ANIM_DURATION)
	tween.parallel().tween_property(notification, "position:x", 50, ANIM_DURATION)
	tween.tween_callback(notification.queue_free)


func _hide_notification(notification: Control, immediate: bool = false) -> void:
	"""
	隐藏通知
	@param notification: 通知控件
	@param immediate: 是否立即隐藏
	"""
	if not is_instance_valid(notification):
		return
	
	_active_notifications.erase(notification)
	
	if immediate:
		notification.queue_free()
	else:
		_play_notification_out_animation(notification)
	
	# 处理队列中的下一个通知
	_process_queue()


func _process_queue() -> void:
	"""
	处理通知队列
	"""
	if _notification_queue.is_empty():
		return
	
	if _active_notifications.size() < MAX_NOTIFICATIONS:
		var next_notification: Dictionary = _notification_queue.pop_front()
		_create_notification(next_notification)


# =============================================================================
# 信号回调
# =============================================================================

func _on_achievement_unlocked(achievement_id: String) -> void:
	"""
	成就解锁回调
	@param achievement_id: 成就ID
	"""
	# TODO: 从成就系统获取成就名称和描述
	show_achievement(achievement_id)
