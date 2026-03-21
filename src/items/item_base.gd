## Void Hunter - 道具基类
## @description: 所有道具的基类，定义道具的基本属性和拾取行为
## @author: Void Hunter Team
## @version: 0.1.0

extends Area2D
class_name ItemBase

# =============================================================================
# 信号定义
# =============================================================================

## 道具被拾取时触发
signal picked_up(picker: Node)

## 道具被使用时触发
signal used(user: Node)

## 道具被丢弃时触发
signal dropped(position: Vector2)

## 道具效果结束时触发
signal effect_expired()

# =============================================================================
# 常量定义
# =============================================================================

## 自动拾取范围
const AUTO_PICKUP_RANGE: float = 30.0

## 磁铁吸引范围
const MAGNET_RANGE: float = 100.0

## 吸引速度
const ATTRACT_SPEED: float = 300.0

## 闪烁开始时间（剩余时间）
const FLASH_START_TIME: float = 5.0

## 默认存在时间
const DEFAULT_LIFETIME: float = 30.0

# =============================================================================
# 枚举定义
# =============================================================================

## 道具类型
enum ItemType {
	CONSUMABLE,		## 消耗品
	EQUIPMENT,		## 装备
	MATERIAL,		## 材料
	KEY_ITEM,		## 关键道具
	CURRENCY		## 货币
}

## 道具稀有度
enum ItemRarity {
	COMMON,			## 普通 - 白色
	UNCOMMON,		## 稀有 - 绿色
	RARE,			## 精良 - 蓝色
	EPIC,			## 史诗 - 紫色
	LEGENDARY		## 传说 - 橙色
}

## 拾取方式
enum PickupType {
	AUTO,			## 自动拾取
	MANUAL,			## 手动拾取
	CONTACT			## 接触拾取
}

## 装备槽位类型
enum EquipSlot {
	NONE,			## 不可装备
	WEAPON,			## 武器槽
	ARMOR,			## 防具槽
	ACCESSORY,		## 饰品槽
	ANY				## 任意槽位
}

## 稀有度颜色配置
const RARITY_COLORS: Dictionary = {
	ItemRarity.COMMON: Color.WHITE,
	ItemRarity.UNCOMMON: Color.GREEN,
	ItemRarity.RARE: Color.CYAN,
	ItemRarity.EPIC: Color.MEDIUM_PURPLE,
	ItemRarity.LEGENDARY: Color.ORANGE
}

## 稀有度名称配置
const RARITY_NAMES: Dictionary = {
	ItemRarity.COMMON: "普通",
	ItemRarity.UNCOMMON: "稀有",
	ItemRarity.RARE: "精良",
	ItemRarity.EPIC: "史诗",
	ItemRarity.LEGENDARY: "传说"
}

# =============================================================================
# 导出变量 - 基本信息
# =============================================================================

## 道具ID
@export var item_id: String = ""

## 道具名称
@export var item_name: String = "Unnamed Item"

## 道具描述
@export_multiline var description: String = ""

## 道具图标
@export var icon: Texture2D

## 道具类型
@export var item_type: ItemType = ItemType.CONSUMABLE

## 道具稀有度
@export var rarity: ItemRarity = ItemRarity.COMMON

## 拾取方式
@export var pickup_type: PickupType = PickupType.CONTACT

## 最大堆叠数量
@export var max_stack: int = 1

## 当前堆叠数量
@export var current_stack: int = 1

## 装备槽位类型
@export var equip_slot: EquipSlot = EquipSlot.NONE

## 是否已装备
@export var is_equipped: bool = false

## 是否可丢弃
@export var can_drop: bool = true

## 是否可出售
@export var sellable: bool = true

## 出售价格
@export var sell_price: int = 0

## 购买价格
@export var buy_price: int = 0

# =============================================================================
# 导出变量 - 效果
# =============================================================================

## 是否是临时效果
@export var is_temporary: bool = false

## 效果持续时间（如果是临时的）
@export var effect_duration: float = 10.0

## 治疗量
@export var heal_amount: float = 0.0

## 法力恢复量
@export var mana_restore: float = 0.0

## 属性加成
@export var stat_bonuses: Dictionary = {}

# =============================================================================
# 导出变量 - 世界属性
# =============================================================================

## 是否在世界中
@export var is_in_world: bool = true

## 存在时间（0表示永久）
@export var lifetime: float = DEFAULT_LIFETIME

## 是否启用磁铁效果
@export var magnet_enabled: bool = true

# =============================================================================
# 公共变量
# =============================================================================

## 道具持有者
var owner_node: Node = null

## 剩余存在时间
var remaining_lifetime: float = 0.0

## 是否正在被吸引
var is_being_attracted: bool = false

## 吸引目标
var attract_target: Node = null

# =============================================================================
# 私有变量
# =============================================================================

var _is_picked_up: bool = false
var _is_flashing: bool = false
var _sprite: Sprite2D
var _collision: CollisionShape2D

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""
	节点就绪时初始化道具
	"""
	_initialize_item()


func _physics_process(delta: float) -> void:
	"""
	物理帧更新
	@param delta: 帧间隔时间
	"""
	if not is_in_world or _is_picked_up:
		return
	
	# 更新存在时间
	_update_lifetime(delta)
	
	# 检查磁铁吸引
	_check_magnet_attraction(delta)
	
	# 更新吸引移动
	if is_being_attracted and attract_target != null:
		_move_towards_target(delta)


func _on_body_entered(body: Node) -> void:
	"""
	物体进入检测区域
	@param body: 进入的物体
	"""
	if pickup_type == PickupType.CONTACT and _is_valid_picker(body):
		pickup(body)


# =============================================================================
# 公共方法 - 初始化
# =============================================================================

## 初始化道具
func initialize() -> void:
	"""
	手动初始化道具
	"""
	_initialize_item()


# =============================================================================
# 公共方法 - 拾取与使用
# =============================================================================

## 拾取道具
func pickup(picker: Node) -> bool:
	"""
	拾取道具
	@param picker: 拾取者
	@return: 是否成功拾取
	"""
	if _is_picked_up:
		return false
	
	if not _is_valid_picker(picker):
		return false
	
	# 检查背包空间（如果有背包系统）
	# if not _check_inventory_space(picker):
	#     return false
	
	_is_picked_up = true
	owner_node = picker
	
	# 执行拾取效果
	_on_pickup(picker)
	
	# 应用即时效果
	_apply_immediate_effects(picker)
	
	# 如果是临时道具或消耗品，直接消耗
	if item_type == ItemType.CONSUMABLE or is_temporary:
		# 如果是临时效果，设置定时器
		if is_temporary:
			_start_temporary_effect(picker)
		else:
			_schedule_despawn()
	else:
		# 否则添加到背包
		_add_to_inventory(picker)
	
	picked_up.emit(picker)
	
	# 播放拾取音效
	AudioManager.play_sfx("item_pickup", 0.8)
	
	return true


## 使用道具
func use(user: Node) -> bool:
	"""
	使用道具
	@param user: 使用者
	@return: 是否成功使用
	"""
	if item_type == ItemType.KEY_ITEM:
		push_warning("关键道具不能直接使用")
		return false
	
	# 执行使用效果
	_on_use(user)
	
	# 应用效果
	_apply_effects(user)
	
	used.emit(user)
	
	# 减少堆叠
	current_stack -= 1
	
	if current_stack <= 0:
		_schedule_despawn()
	
	return true


## 丢弃道具
func drop(drop_position: Vector2) -> bool:
	"""
	丢弃道具
	@param drop_position: 丢弃位置
	@return: 是否成功丢弃
	"""
	if not can_drop:
		return false
	
	# 从背包移除
	_remove_from_inventory()
	
	# 设置位置
	global_position = drop_position
	
	# 重置状态
	is_in_world = true
	_is_picked_up = false
	owner_node = null
	remaining_lifetime = lifetime
	
	# 显示道具
	show()
	
	# 启用碰撞
	if _collision:
		_collision.disabled = false
	
	dropped.emit(drop_position)
	
	return true


## 设置堆叠数量
func set_stack_count(count: int) -> void:
	"""
	设置堆叠数量
	@param count: 数量
	"""
	current_stack = clampi(count, 1, max_stack)


## 增加堆叠
func add_stack(count: int = 1) -> bool:
	"""
	增加堆叠数量
	@param count: 增加数量
	@return: 是否成功
	"""
	if current_stack + count > max_stack:
		return false
	
	current_stack += count
	return true


## 获取道具信息
func get_item_info() -> Dictionary:
	"""
	获取道具信息字典
	@return: 道具信息
	"""
	return {
		"id": item_id,
		"name": item_name,
		"description": description,
		"type": ItemType.keys()[item_type],
		"rarity": ItemRarity.keys()[rarity],
		"rarity_name": get_rarity_name(),
		"rarity_color": get_rarity_color(),
		"stack": current_stack,
		"max_stack": max_stack,
		"sell_price": sell_price,
		"buy_price": buy_price,
		"equip_slot": EquipSlot.keys()[equip_slot],
		"is_equipped": is_equipped
	}


## 获取稀有度颜色
func get_rarity_color() -> Color:
	"""
	获取当前稀有度对应的颜色
	@return: 稀有度颜色
	"""
	return RARITY_COLORS.get(rarity, Color.WHITE)


## 获取稀有度名称
func get_rarity_name() -> String:
	"""
	获取当前稀有度对应的名称
	@return: 稀有度名称
	"""
	return RARITY_NAMES.get(rarity, "未知")


## 装备道具
func equip(target: Node) -> bool:
	"""
	装备道具到目标
	@param target: 装备目标
	@return: 是否成功装备
	"""
	if equip_slot == EquipSlot.NONE:
		return false
	
	if is_equipped:
		return false
	
	is_equipped = true
	
	# 应用装备效果
	_apply_equipment_effects(target)
	
	return true


## 卸下道具
func unequip(target: Node) -> bool:
	"""
	从目标卸下道具
	@param target: 卸下目标
	@return: 是否成功卸下
	"""
	if not is_equipped:
		return false
	
	is_equipped = false
	
	# 移除装备效果
	_remove_equipment_effects(target)
	
	return true


## 应用装备效果
func _apply_equipment_effects(target: Node) -> void:
	"""
	应用装备效果（子类重写）
	@param target: 目标
	"""
	_apply_effects(target)


## 移除装备效果
func _remove_equipment_effects(target: Node) -> void:
	"""
	移除装备效果
	@param target: 目标
	"""
	for stat_name in stat_bonuses.keys():
		var bonus_value: Variant = stat_bonuses[stat_name]
		_remove_stat_bonus(target, stat_name, bonus_value)


# =============================================================================
# 私有方法
# =============================================================================

func _initialize_item() -> void:
	"""
	初始化道具内部状态
	"""
	remaining_lifetime = lifetime
	
	# 获取组件
	for child in get_children():
		if child is Sprite2D:
			_sprite = child
		elif child is CollisionShape2D:
			_collision = child
	
	# 连接信号
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	
	# 设置碰撞层
	collision_layer = 16  # Item layer
	collision_mask = 1	 # Player layer


func _update_lifetime(delta: float) -> void:
	"""
	更新存在时间
	@param delta: 帧间隔时间
	"""
	if lifetime <= 0:
		return  # 永久道具
	
	remaining_lifetime -= delta
	
	# 开始闪烁
	if remaining_lifetime <= FLASH_START_TIME and not _is_flashing:
		_start_lifetime_flash()
	
	# 时间到，消失
	if remaining_lifetime <= 0:
		_expire()


func _check_magnet_attraction(delta: float) -> void:
	"""
	检查磁铁吸引
	@param delta: 帧间隔时间
	"""
	if not magnet_enabled:
		return
	
	# 查找附近的玩家
	var players: Array[Node] = get_tree().get_nodes_in_group("players")
	
	for player in players:
		if not is_instance_valid(player):
			continue
		
		var distance: float = global_position.distance_to(player.global_position)
		
		if distance <= MAGNET_RANGE:
			is_being_attracted = true
			attract_target = player
			return
	
	is_being_attracted = false
	attract_target = null


func _move_towards_target(delta: float) -> void:
	"""
	向目标移动
	@param delta: 帧间隔时间
	"""
	if attract_target == null or not is_instance_valid(attract_target):
		is_being_attracted = false
		return
	
	var direction: Vector2 = (attract_target.global_position - global_position).normalized()
	global_position += direction * ATTRACT_SPEED * delta
	
	# 检查是否到达
	var distance: float = global_position.distance_to(attract_target.global_position)
	if distance <= AUTO_PICKUP_RANGE:
		pickup(attract_target)


func _is_valid_picker(picker: Node) -> bool:
	"""
	检查是否是有效的拾取者
	@param picker: 拾取者
	@return: 是否有效
	"""
	return picker.is_in_group("players")


func _apply_immediate_effects(target: Node) -> void:
	"""
	应用即时效果
	@param target: 目标
	"""
	# 治疗效果
	if heal_amount > 0:
		_apply_heal(target, heal_amount)
	
	# 法力恢复
	if mana_restore > 0:
		_apply_mana_restore(target, mana_restore)
	
	# 给予金币（如果是货币）
	if item_type == ItemType.CURRENCY:
		GameManager.gold_collected += current_stack


func _apply_effects(target: Node) -> void:
	"""
	应用道具效果
	@param target: 目标
	"""
	_apply_immediate_effects(target)
	
	# 应用属性加成
	for stat_name in stat_bonuses.keys():
		var bonus_value: Variant = stat_bonuses[stat_name]
		_apply_stat_bonus(target, stat_name, bonus_value)


func _apply_heal(target: Node, amount: float) -> void:
	"""
	应用治疗效果
	@param target: 目标
	@param amount: 治疗量
	"""
	if target.has_method("heal"):
		target.heal(amount)
	elif "stats" in target and target.stats is PlayerStats:
		target.stats.heal(amount)


func _apply_mana_restore(target: Node, amount: float) -> void:
	"""
	应用法力恢复效果
	@param target: 目标
	@param amount: 恢复量
	"""
	if "stats" in target and target.stats is PlayerStats:
		target.stats.restore_mana(amount)


func _apply_stat_bonus(target: Node, stat_name: String, value: Variant) -> void:
	"""
	应用属性加成
	@param target: 目标
	@param stat_name: 属性名称
	@param value: 加成值
	"""
	if "stats" in target and target.stats is PlayerStats:
		if value is float:
			target.stats.add_percent_bonus(stat_name, value)
		else:
			target.stats.add_flat_bonus(stat_name, value)


func _remove_stat_bonus(target: Node, stat_name: String, value: Variant) -> void:
	"""
	移除属性加成
	@param target: 目标
	@param stat_name: 属性名称
	@param value: 加成值
	"""
	if "stats" in target and target.stats is PlayerStats:
		if value is float:
			target.stats.remove_percent_bonus(stat_name, value)
		else:
			target.stats.remove_flat_bonus(stat_name, value)


func _start_temporary_effect(target: Node) -> void:
	"""
	启动临时效果
	@param target: 目标
	"""
	# 应用属性加成
	for stat_name in stat_bonuses.keys():
		var bonus_value: Variant = stat_bonuses[stat_name]
		_apply_stat_bonus(target, stat_name, bonus_value)
	
	# 设置定时器
	await get_tree().create_timer(effect_duration).timeout
	
	# 移除属性加成
	for stat_name in stat_bonuses.keys():
		var bonus_value: Variant = stat_bonuses[stat_name]
		_remove_stat_bonus(target, stat_name, bonus_value)
	
	effect_expired.emit()
	_schedule_despawn()


func _start_lifetime_flash() -> void:
	"""
	启动存在时间闪烁效果
	"""
	_is_flashing = true
	
	var tween: Tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "modulate:a", 0.3, 0.2)
	tween.tween_property(self, "modulate:a", 1.0, 0.2)


func _add_to_inventory(picker: Node) -> void:
	"""
	添加到背包
	@param picker: 拾取者
	"""
	# 隐藏道具
	hide()
	
	# 禁用碰撞
	if _collision:
		_collision.disabled = true
	
	# 通知背包系统
	# 实际的背包管理逻辑在 InventoryManager 中
	pass


func _remove_from_inventory() -> void:
	"""
	从背包移除
	"""
	# 通知背包系统
	# 实际的背包管理逻辑在 InventoryManager 中
	pass


func _expire() -> void:
	"""
	道具过期消失
	"""
	_schedule_despawn()


func _schedule_despawn() -> void:
	"""
	安排销毁/归还对象池
	"""
	# 如果使用对象池，归还到池中
	if ObjectPool.has_pool("items"):
		ObjectPool.despawn(self, 0.1)
	else:
		await get_tree().process_frame
		queue_free()


# =============================================================================
# 虚方法 - 子类重写
# =============================================================================

func _on_pickup(picker: Node) -> void:
	"""
	拾取时的处理（子类重写）
	@param picker: 拾取者
	"""
	pass


func _on_use(user: Node) -> void:
	"""
	使用时的处理（子类重写）
	@param user: 使用者
	"""
	pass


# =============================================================================
# 对象池接口
# =============================================================================

func on_spawn() -> void:
	"""
	从对象池取出时的初始化
	"""
	_is_picked_up = false
	is_in_world = true
	remaining_lifetime = lifetime
	_is_flashing = false
	modulate = Color.WHITE
	show()
	
	if _collision:
		_collision.disabled = false


func on_despawn() -> void:
	"""
	归还到对象池时的清理
	"""
	_is_picked_up = false
	owner_node = null
	is_being_attracted = false
	attract_target = null
	current_stack = 1


func reset() -> void:
	"""
	重置道具状态
	"""
	on_despawn()
	on_spawn()
