## Void Hunter - 掉落物节点
## @description: 管理敌人死亡后的道具掉落，包括金币、药水、稀有道具等
## @author: Void Hunter Team
## @version: 1.1.0

extends Area2D

# =============================================================================
# 信号定义
# =============================================================================

## 道具被拾取时触发
signal item_picked_up(item_data: Dictionary)

## 道具消失时触发
signal item_despawned()

# =============================================================================
# 枚举定义
# =============================================================================

## 掉落物类型
enum DropType {
	GOLD,			## 金币
	HEALTH_POTION,	## 生命药水
	MANA_POTION,	## 法力药水
	EXP_GEM,		## 经验宝石
	RARE_ITEM		## 稀有道具
}

# =============================================================================
# 常量定义
# =============================================================================

## 自动拾取范围
const PICKUP_RANGE: float = 80.0

## 吸引范围（磁铁效果）
const ATTRACT_RANGE: float = 150.0

## 吸引速度
const ATTRACT_SPEED: float = 400.0

## 存在时间（秒）
const DESPAWN_TIME: float = 30.0

## 闪烁警告时间（消失前）
const BLINK_WARNING_TIME: float = 5.0

## 弹跳力度
const BOUNCE_FORCE: float = 200.0

## 弹跳阻尼
const BOUNCE_DAMPING: float = 0.8

# =============================================================================
# 导出变量
# =============================================================================

## 掉落物类型
@export var drop_type: DropType = DropType.GOLD

## 掉落数量（金币数量/药水恢复量等）
@export var drop_value: int = 1

## 是否自动拾取
@export var auto_pickup: bool = true

# =============================================================================
# 公共变量
# =============================================================================

## 掉落物数据
var item_data: Dictionary = {}

## 当前速度
var velocity: Vector2 = Vector2.ZERO

## 是否正在被吸引
var is_being_attracted: bool = false

# =============================================================================
# 私有变量
# =============================================================================

var _despawn_timer: float = 0.0
var _is_blinking: bool = false
var _player: Node = null
var _sprite: Sprite2D = null
var _collision: Area2D = null
var _tween: Tween = null

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""节点就绪时初始化"""
	_initialize_drop()
	_find_player()


func _physics_process(delta: float) -> void:
	"""物理帧更新"""
	# 更新存在时间
	_update_despawn(delta)

	# 检查拾取
	if auto_pickup:
		_check_pickup(delta)

	# 应用移动
	_apply_movement(delta)


func _process(_delta: float) -> void:
	"""每帧更新视觉效果"""
	_update_visuals()

# =============================================================================
# 公共方法 - 初始化
# =============================================================================

## 初始化掉落物
func initialize(type: DropType, value: int = 1, start_velocity: Vector2 = Vector2.ZERO) -> void:
	"""初始化掉落物"""
	drop_type = type
	drop_value = value
	velocity = start_velocity
	_initialize_drop()


## 设置掉落物数据
func set_item_data(data: Dictionary) -> void:
	"""设置掉落物数据"""
	item_data = data


## 设置吸引目标（用于磁铁技能）
func set_target(target: Node) -> void:
	"""设置吸引目标"""
	_player = target
	if target != null:
		is_being_attracted = true


## 从掉落表创建
static func create_drop(drop_type: int, position: Vector2, value: int = 1) -> Node2D:
	"""静态方法：创建掉落物"""
	var drop_script: GDScript = preload("res://src/items/drop_item.gd")
	var drop: Area2D = Area2D.new()
	drop.set_script(drop_script)
	drop.global_position = position
	drop.set("drop_type", drop_type)
	drop.set("drop_value", value)

	# 随机弹跳方向
	var angle: float = randf() * TAU
	var speed: float = randf_range(100.0, BOUNCE_FORCE)
	drop.set("velocity", Vector2(cos(angle), sin(angle)) * speed)

	return drop

# =============================================================================
# 公共方法 - 拾取
# =============================================================================

## 强制拾取
func force_pickup() -> void:
	"""强制拾取（被玩家接触时调用）"""
	_do_pickup()

# =============================================================================
# 私有方法 - 初始化
# =============================================================================

func _initialize_drop() -> void:
	"""初始化掉落物内部状态"""
	_despawn_timer = DESPAWN_TIME
	_is_blinking = false

	# 确保有碰撞
	_ensure_collision()

	# 确保有视觉效果
	_ensure_visual()

	# 设置掉落物数据
	_setup_item_data()

	# 添加到掉落物组
	add_to_group("drop_items")
	add_to_group("drops")

	# 入场动画
	_play_spawn_animation()


func _ensure_collision() -> void:
	"""确保有碰撞形状"""
	for child in get_children():
		if child is CollisionShape2D:
			return

	# 创建碰撞形状
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape := CircleShape2D.new()
	shape.radius = 12.0
	collision.shape = shape
	add_child(collision)


func _ensure_visual() -> void:
	"""确保有视觉效果"""
	for child in get_children():
		if child is Sprite2D:
			_sprite = child
			return

	# 创建精灵
	_sprite = Sprite2D.new()
	_sprite.name = "Sprite"

	# 尝试从 SpriteManager 加载道具图标
	var type_name := _get_type_name()
	var icon_loaded := false
	if SpriteManager and SpriteManager.has_method("get_item_icon"):
		var icon: Variant = SpriteManager.get_item_icon(type_name)
		if icon:
			_sprite.texture = icon
			icon_loaded = true

	if not icon_loaded:
		# 后备：色块
		var texture := ImageTexture.new()
		var image: Image
		var color: Color

		match drop_type:
			DropType.GOLD:
				color = Color(1.0, 0.85, 0.0)
				image = Image.create(12, 12, false, Image.FORMAT_RGBA8)
			DropType.HEALTH_POTION:
				color = Color(1.0, 0.2, 0.2)
				image = Image.create(10, 14, false, Image.FORMAT_RGBA8)
			DropType.MANA_POTION:
				color = Color(0.2, 0.4, 1.0)
				image = Image.create(10, 14, false, Image.FORMAT_RGBA8)
			DropType.EXP_GEM:
				color = Color(0.5, 1.0, 0.5)
				image = Image.create(10, 10, false, Image.FORMAT_RGBA8)
			DropType.RARE_ITEM:
				color = Color(1.0, 0.5, 1.0)
				image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
			_:
				color = Color.WHITE
				image = Image.create(10, 10, false, Image.FORMAT_RGBA8)

		image.fill(color)
		texture.set_image(image)
		_sprite.texture = texture

	add_child(_sprite)


func _setup_item_data() -> void:
	"""设置掉落物数据"""
	item_data = {
		"type": drop_type,
		"value": drop_value,
		"type_name": _get_type_name()
	}

	# 根据类型设置额外数据
	match drop_type:
		DropType.GOLD:
			item_data["display_name"] = "金币"
			item_data["description"] = "获得 %d 金币" % drop_value
		DropType.HEALTH_POTION:
			item_data["display_name"] = "生命药水"
			item_data["description"] = "恢复 %d 点生命值" % drop_value
		DropType.MANA_POTION:
			item_data["display_name"] = "法力药水"
			item_data["description"] = "恢复 %d 点法力值" % drop_value
		DropType.EXP_GEM:
			item_data["display_name"] = "经验宝石"
			item_data["description"] = "获得 %d 点经验值" % drop_value
		DropType.RARE_ITEM:
			item_data["display_name"] = "稀有道具"
			item_data["description"] = "一个神秘的道具"


func _get_type_name() -> String:
	"""获取类型名称"""
	match drop_type:
		DropType.GOLD: return "gold"
		DropType.HEALTH_POTION: return "health_potion"
		DropType.MANA_POTION: return "mana_potion"
		DropType.EXP_GEM: return "exp_gem"
		DropType.RARE_ITEM: return "rare_item"
		_: return "unknown"


func _find_player() -> void:
	"""查找玩家"""
	var players := get_tree().get_nodes_in_group("players")
	if not players.is_empty():
		_player = players[0]

# =============================================================================
# 私有方法 - 更新
# =============================================================================

func _update_despawn(delta: float) -> void:
	"""更新存在时间"""
	_despawn_timer -= delta

	# 检查是否开始闪烁
	if _despawn_timer <= BLINK_WARNING_TIME and not _is_blinking:
		_is_blinking = true
		_start_blinking()

	# 检查是否消失
	if _despawn_timer <= 0:
		_despawn()


func _check_pickup(delta: float) -> void:
	"""检查拾取"""
	if _player == null or not is_instance_valid(_player):
		_find_player()
		return

	var distance: float = global_position.distance_to(_player.global_position)

	# 检查是否在吸引范围内
	if distance <= ATTRACT_RANGE:
		is_being_attracted = true
		# 向玩家移动，距离越近速度越快
		var direction: Vector2 = (_player.global_position - global_position).normalized()
		var speed_multiplier: float = 1.0 + (1.0 - distance / ATTRACT_RANGE) * 2.0
		velocity = direction * ATTRACT_SPEED * speed_multiplier
	else:
		is_being_attracted = false

	# 检查是否在拾取范围内
	if distance <= PICKUP_RANGE:
		_do_pickup()


func _apply_movement(delta: float) -> void:
	"""应用移动"""
	if is_being_attracted:
		# 被吸引时直接移动
		global_position += velocity * delta
	else:
		# 正常物理移动
		global_position += velocity * delta

		# 应用阻尼
		velocity = velocity * BOUNCE_DAMPING

		# 如果速度很小，停止移动
		if velocity.length() < 5.0:
			velocity = Vector2.ZERO


func _update_visuals() -> void:
	"""更新视觉效果"""
	if _sprite == null:
		return

	# 悬浮动画
	var time := Time.get_ticks_msec() / 1000.0
	var bob_offset := sin(time * 3.0) * 2.0
	_sprite.position.y = bob_offset

	# 旋转（金币旋转效果）
	if drop_type == DropType.GOLD:
		_sprite.rotation += 0.02

	# 稀有道具发光效果
	if drop_type == DropType.RARE_ITEM:
		var glow: float = 0.7 + sin(time * 2.0) * 0.3
		_sprite.modulate.a = glow


func _do_pickup() -> void:
	"""执行拾取"""
	# 应用效果
	_apply_pickup_effect()

	# 触发信号
	item_picked_up.emit(item_data)

	# 播放拾取音效
	AudioManager.play_sfx("pickup", 0.5)

	# 拾取特效
	if VFXManager:
		VFXManager.spawn_heal_sparkle(global_position)

	# 拾取动画后删除
	_play_pickup_animation()


func _apply_pickup_effect() -> void:
	"""应用拾取效果"""
	if _player == null or not is_instance_valid(_player):
		_find_player()
		if _player == null:
			return

	match drop_type:
		DropType.GOLD:
			# 金币
			GameManager.add_gold(drop_value)

		DropType.HEALTH_POTION:
			# 生命药水
			if _player.has_method("heal"):
				_player.heal(drop_value)

		DropType.MANA_POTION:
			# 法力药水
			if _player.has_method("restore_mana"):
				_player.restore_mana(drop_value)
			elif "current_mana" in _player and "max_mana" in _player:
				_player.current_mana = min(_player.current_mana + drop_value, _player.max_mana)

		DropType.EXP_GEM:
			# 经验宝石
			if _player.has_method("gain_experience"):
				_player.gain_experience(drop_value)

		DropType.RARE_ITEM:
			# 稀有道具 - 通知掉落系统生成一个随机稀有装备
			_notify_rare_item_pickup()


## 稀有道具拾取处理
func _notify_rare_item_pickup() -> void:
	"""稀有道具拾取：查找场景中的掉落系统并生成一件随机装备"""
	var drop_systems: Array[Node] = get_tree().get_nodes_in_group("drop_system")
	for ds in drop_systems:
		if ds.has_method("spawn_drop"):
			# 生成一件装备（使用精英级别稀有度权重）
			ds.spawn_drop(global_position, "elite", false, false)
			break


func _despawn() -> void:
	"""消失"""
	item_despawned.emit()
	queue_free()

# =============================================================================
# 私有方法 - 动画
# =============================================================================

func _play_spawn_animation() -> void:
	"""播放生成动画"""
	scale = Vector2.ZERO

	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(self, "scale", Vector2.ONE, 0.3)


func _play_pickup_animation() -> void:
	"""播放拾取动画"""
	if _tween:
		_tween.kill()

	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
	_tween.tween_property(self, "modulate:a", 0.0, 0.2)

	_tween.tween_callback(queue_free)


func _start_blinking() -> void:
	"""开始闪烁"""
	if _sprite == null:
		return

	# 创建闪烁动画
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(_sprite, "modulate:a", 0.3, 0.2)
	tween.tween_property(_sprite, "modulate:a", 1.0, 0.2)

# =============================================================================
# 掉落表工具
# =============================================================================

## 根据掉落表生成掉落物
static func generate_drops_from_table(drop_table: Array, position: Vector2) -> Array:
	"""
	根据掉落表生成掉落物
	@param drop_table: 掉落表，格式为 [{"type": int, "chance": 0.5, "value": 10}, ...]
	@param position: 掉落位置
	@return: 生成的掉落物数组
	"""
	var drops: Array = []

	for entry in drop_table:
		var chance: float = entry.get("chance", 1.0)
		if randf() <= chance:
			var type: int = entry.get("type", 0)  # 默认金币
			var value: int = entry.get("value", 1)
			var min_value: int = entry.get("min_value", value)
			var max_value: int = entry.get("max_value", value)

			# 随机值
			if min_value != max_value:
				value = randi_range(min_value, max_value)

			var drop := create_drop(type, position, value)
			drops.append(drop)

	return drops


## 获取默认敌人掉落表
static func get_default_enemy_drop_table(enemy_type: String) -> Array:
	"""
	获取默认敌人掉落表
	@param enemy_type: 敌人类型
	@return: 掉落表
	"""
	var table: Array = []

	# 使用整数代替枚举
	# 0 = GOLD, 1 = HEALTH_POTION, 2 = MANA_POTION, 3 = EXP_GEM, 4 = RARE_ITEM
	match enemy_type:
		"normal", "melee", "ranged":
			table = [
				{"type": 0, "chance": 0.8, "min_value": 1, "max_value": 3},
				{"type": 1, "chance": 0.1, "value": 15},
				{"type": 2, "chance": 0.1, "value": 10},
				{"type": 3, "chance": 0.3, "min_value": 5, "max_value": 10}
			]
		"tank":
			table = [
				{"type": 0, "chance": 1.0, "min_value": 3, "max_value": 6},
				{"type": 1, "chance": 0.2, "value": 20},
				{"type": 2, "chance": 0.15, "value": 15},
				{"type": 3, "chance": 0.5, "min_value": 10, "max_value": 20}
			]
		"elite":
			table = [
				{"type": 0, "chance": 1.0, "min_value": 8, "max_value": 15},
				{"type": 1, "chance": 0.5, "value": 30},
				{"type": 2, "chance": 0.4, "value": 25},
				{"type": 3, "chance": 1.0, "min_value": 25, "max_value": 50},
				{"type": 4, "chance": 0.1, "value": 1}
			]
		"boss":
			table = [
				{"type": 0, "chance": 1.0, "min_value": 30, "max_value": 50},
				{"type": 1, "chance": 1.0, "value": 50},
				{"type": 2, "chance": 1.0, "value": 40},
				{"type": 3, "chance": 1.0, "min_value": 100, "max_value": 200},
				{"type": 4, "chance": 0.5, "value": 1}
			]
		_:
			table = [
				{"type": 0, "chance": 0.5, "value": 1}
			]

	return table
