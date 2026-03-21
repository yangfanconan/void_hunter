## Void Hunter - 物品栏界面
## @description: 玩家物品栏管理界面，包含背包、装备栏和快捷栏
## @author: Void Hunter Team
## @version: 0.2.0

extends Control
class_name Inventory

# =============================================================================
# 信号定义
# =============================================================================

## 物品被选中时触发
signal item_selected(item_id: String, slot_index: int)

## 物品被使用时触发
signal item_used(item_id: String, slot_index: int)

## 物品被丢弃时触发
signal item_dropped(item_id: String, slot_index: int)

## 物品栏关闭时触发
signal inventory_closed()

## 装备变更时触发
signal equipment_changed(slot_type: String, item_data: Dictionary)

## 快捷栏物品使用时触发
signal quick_slot_used(slot_index: int)

# =============================================================================
# 常量定义
# =============================================================================

## 物品栏格子数量
const INVENTORY_SIZE: int = 20

## 每行格子数量
const SLOTS_PER_ROW: int = 5

## 快捷栏格子数量
const QUICK_SLOT_COUNT: int = 3

## 装备槽类型
const EQUIP_SLOTS: Array[String] = ["weapon", "armor", "accessory"]

## 拖拽预览Z索引
const DRAG_PREVIEW_Z_INDEX: int = 100

# =============================================================================
# 导出变量
# =============================================================================

## 物品栏格子场景
@export var slot_scene: PackedScene

## 玩家引用
@export var player: Node

# =============================================================================
# 节点引用
# =============================================================================

@onready var grid_container: GridContainer = $Panel/MarginContainer/VBoxContainer/ScrollContainer/GridContainer
@onready var item_info_panel: Panel = $Panel/MarginContainer/VBoxContainer/ItemInfoPanel
@onready var button_close: Button = $Panel/MarginContainer/VBoxContainer/HBoxContainer/ButtonClose
@onready var button_use: Button = $Panel/MarginContainer/VBoxContainer/HBoxContainer/ButtonUse
@onready var button_drop: Button = $Panel/MarginContainer/VBoxContainer/HBoxContainer/ButtonDrop

# 装备槽节点
@onready var weapon_slot: Control = $Panel/MarginContainer/VBoxContainer/EquipmentContainer/WeaponSlot
@onready var armor_slot: Control = $Panel/MarginContainer/VBoxContainer/EquipmentContainer/ArmorSlot
@onready var accessory_slot: Control = $Panel/MarginContainer/VBoxContainer/EquipmentContainer/AccessorySlot

# 快捷栏节点
@onready var quick_slots_container: HBoxContainer = $QuickSlotsContainer

# 物品信息节点
@onready var item_name_label: Label = $Panel/MarginContainer/VBoxContainer/ItemInfoPanel/VBoxContainer/ItemName
@onready var item_desc_label: Label = $Panel/MarginContainer/VBoxContainer/ItemInfoPanel/VBoxContainer/ItemDescription
@onready var item_stats_label: Label = $Panel/MarginContainer/VBoxContainer/ItemInfoPanel/VBoxContainer/ItemStats

# =============================================================================
# 公共变量
# =============================================================================

## 物品数据列表
var items: Array[Dictionary] = []

## 装备数据
var equipped_items: Dictionary = {
	"weapon": {},
	"armor": {},
	"accessory": {}
}

## 快捷栏数据
var quick_slots: Array[Dictionary] = [{}, {}, {}]

## 当前选中的格子索引
var selected_slot_index: int = -1

## 当前选中的装备槽
var selected_equip_slot: String = ""

# =============================================================================
# 私有变量
# =============================================================================

var _slots: Array[Control] = []
var _equip_slot_nodes: Dictionary = {}
var _quick_slot_nodes: Array[Control] = []

# 拖拽相关
var _is_dragging: bool = false
var _drag_source_slot: int = -1
var _drag_source_equip: String = ""
var _drag_source_quick: int = -1
var _drag_preview: Control = null
var _drag_data: Dictionary = {}

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""
	节点就绪时初始化物品栏
	"""
	_initialize_inventory()
	_connect_signals()
	_setup_equipment_slots()
	_setup_quick_slots()


func _input(event: InputEvent) -> void:
	"""
	处理输入事件
	@param event: 输入事件
	"""
	# 处理快捷键使用
	if event.is_action_pressed("quick_slot_1"):
		use_quick_slot(0)
	elif event.is_action_pressed("quick_slot_2"):
		use_quick_slot(1)
	elif event.is_action_pressed("quick_slot_3"):
		use_quick_slot(2)
	
	# 取消拖拽
	if _is_dragging and event.is_action_pressed("ui_cancel"):
		_cancel_drag()

# =============================================================================
# 公共方法 - 开关物品栏
# =============================================================================

## 打开物品栏
func open_inventory() -> void:
	"""
	打开物品栏界面
	"""
	show()
	GameManager.set_game_state(GameManager.GameState.INVENTORY)
	_refresh_inventory()


## 关闭物品栏
func close_inventory() -> void:
	"""
	关闭物品栏界面
	"""
	hide()
	GameManager.set_game_state(GameManager.GameState.PLAYING)
	inventory_closed.emit()


## 切换物品栏
func toggle_inventory() -> void:
	"""
	切换物品栏显示状态
	"""
	if visible:
		close_inventory()
	else:
		open_inventory()

# =============================================================================
# 公共方法 - 物品操作
# =============================================================================

## 添加物品
func add_item(item_data: Dictionary) -> bool:
	"""
	添加物品到物品栏
	@param item_data: 物品数据
	@return: 是否成功添加
	"""
	# 首先尝试堆叠
	var item_id: String = item_data.get("id", "")
	var max_stack: int = item_data.get("max_stack", 1)
	
	if max_stack > 1:
		for i in range(items.size()):
			var slot_item: Dictionary = items[i]
			if not slot_item.is_empty() and slot_item.get("id") == item_id:
				var current_stack: int = slot_item.get("stack", 1)
				var add_stack: int = item_data.get("stack", 1)
				
				if current_stack + add_stack <= max_stack:
					slot_item["stack"] = current_stack + add_stack
					_refresh_slot(i)
					return true
	
	# 查找空格子
	for i in range(items.size()):
		var slot_item: Dictionary = items[i]
		if slot_item.is_empty():
			items[i] = item_data.duplicate()
			_refresh_slot(i)
			return true
	
	# 没有空格子，尝试添加到数组末尾
	if items.size() < INVENTORY_SIZE:
		items.append(item_data.duplicate())
		_refresh_slot(items.size() - 1)
		return true
	
	return false


## 移除物品
func remove_item(slot_index: int, count: int = 1) -> Dictionary:
	"""
	从物品栏移除物品
	@param slot_index: 格子索引
	@param count: 移除数量
	@return: 移除的物品数据
	"""
	if slot_index < 0 or slot_index >= items.size():
		return {}
	
	var item: Dictionary = items[slot_index]
	if item.is_empty():
		return {}
	
	var current_stack: int = item.get("stack", 1)
	
	if count >= current_stack:
		# 完全移除
		items[slot_index] = {}
		_refresh_slot(slot_index)
		return item
	else:
		# 部分移除
		var removed_item: Dictionary = item.duplicate()
		removed_item["stack"] = count
		item["stack"] = current_stack - count
		_refresh_slot(slot_index)
		return removed_item


## 获取物品
func get_item(slot_index: int) -> Dictionary:
	"""
	获取指定格子的物品
	@param slot_index: 格子索引
	@return: 物品数据
	"""
	if slot_index < 0 or slot_index >= items.size():
		return {}
	return items[slot_index]


## 清空物品栏
func clear_inventory() -> void:
	"""
	清空物品栏
	"""
	items.clear()
	for i in range(INVENTORY_SIZE):
		items.append({})
	selected_slot_index = -1
	_refresh_inventory()

# =============================================================================
# 公共方法 - 装备操作
# =============================================================================

## 装备物品
func equip_item(slot_index: int) -> bool:
	"""
	装备指定格子的物品
	@param slot_index: 格子索引
	@return: 是否成功装备
	"""
	if slot_index < 0 or slot_index >= items.size():
		return false
	
	var item: Dictionary = items[slot_index]
	if item.is_empty():
		return false
	
	# 确定装备槽类型
	var equip_slot_type: String = _get_equip_slot_type(item)
	if equip_slot_type.is_empty():
		return false
	
	# 检查是否已装备同类型物品
	var old_equipped: Dictionary = equipped_items[equip_slot_type]
	
	# 卸下旧装备效果
	if not old_equipped.is_empty() and player != null:
		_unequip_item_effects(old_equipped)
	
	# 装备新物品
	equipped_items[equip_slot_type] = item.duplicate()
	items[slot_index] = {}
	
	# 应用新装备效果
	if player != null:
		_equip_item_effects(item)
	
	# 如果旧槽位有物品，放到物品栏
	if not old_equipped.is_empty():
		items[slot_index] = old_equipped
	
	_refresh_slot(slot_index)
	_refresh_equipment_slot(equip_slot_type)
	
	# 触发信号
	equipment_changed.emit(equip_slot_type, equipped_items[equip_slot_type])
	
	return true


## 卸下装备
func unequip_item(slot_type: String) -> bool:
	"""
	卸下指定槽位的装备
	@param slot_type: 装备槽类型
	@return: 是否成功卸下
	"""
	if not equipped_items.has(slot_type):
		return false
	
	var item: Dictionary = equipped_items[slot_type]
	if item.is_empty():
		return false
	
	# 检查背包空间
	if not _has_empty_slot():
		push_warning("背包已满，无法卸下装备")
		return false
	
	# 移除装备效果
	if player != null:
		_unequip_item_effects(item)
	
	# 添加到背包
	add_item(item)
	
	# 清空装备槽
	equipped_items[slot_type] = {}
	_refresh_equipment_slot(slot_type)
	
	equipment_changed.emit(slot_type, {})
	
	return true


## 获取装备
func get_equipped(slot_type: String) -> Dictionary:
	"""
	获取指定槽位的装备
	@param slot_type: 装备槽类型
	@return: 装备数据
	"""
	return equipped_items.get(slot_type, {})

# =============================================================================
# 公共方法 - 快捷栏操作
# =============================================================================

## 设置快捷栏物品
func set_quick_slot(slot_index: int, inventory_index: int) -> bool:
	"""
	设置快捷栏物品
	@param slot_index: 快捷栏索引（0-2）
	@param inventory_index: 物品栏索引
	@return: 是否成功设置
	"""
	if slot_index < 0 or slot_index >= QUICK_SLOT_COUNT:
		return false
	
	if inventory_index < 0 or inventory_index >= items.size():
		return false
	
	var item: Dictionary = items[inventory_index]
	if item.is_empty():
		return false
	
	# 只能设置消耗品到快捷栏
	var item_type: int = item.get("type", -1)
	if item_type != ItemBase.ItemType.CONSUMABLE:
		return false
	
	quick_slots[slot_index] = {
		"item": item.duplicate(),
		"inventory_index": inventory_index
	}
	
	_refresh_quick_slot(slot_index)
	return true


## 使用快捷栏物品
func use_quick_slot(slot_index: int) -> bool:
	"""
	使用快捷栏物品
	@param slot_index: 快捷栏索引
	@return: 是否成功使用
	"""
	if slot_index < 0 or slot_index >= QUICK_SLOT_COUNT:
		return false
	
	var quick_data: Dictionary = quick_slots[slot_index]
	if quick_data.is_empty():
		return false
	
	var inventory_index: int = quick_data.get("inventory_index", -1)
	if inventory_index < 0 or inventory_index >= items.size():
		return false
	
	var item: Dictionary = items[inventory_index]
	if item.is_empty():
		# 快捷栏物品已被消耗，清除快捷栏
		quick_slots[slot_index] = {}
		_refresh_quick_slot(slot_index)
		return false
	
	# 使用物品
	use_item(inventory_index)
	
	# 更新快捷栏显示
	quick_data["item"] = item.duplicate()
	_refresh_quick_slot(slot_index)
	
	quick_slot_used.emit(slot_index)
	
	return true


## 清除快捷栏
func clear_quick_slot(slot_index: int) -> void:
	"""
	清除快捷栏格子
	@param slot_index: 快捷栏索引
	"""
	if slot_index < 0 or slot_index >= QUICK_SLOT_COUNT:
		return
	
	quick_slots[slot_index] = {}
	_refresh_quick_slot(slot_index)

# =============================================================================
# 公共方法 - 物品使用
# =============================================================================

## 使用物品
func use_item(slot_index: int) -> bool:
	"""
	使用指定格子的物品
	@param slot_index: 格子索引
	@return: 是否成功使用
	"""
	if slot_index < 0 or slot_index >= items.size():
		return false
	
	var item: Dictionary = items[slot_index]
	if item.is_empty():
		return false
	
	var item_type: int = item.get("type", -1)
	
	# 装备类型，进行装备
	if item_type == ItemBase.ItemType.EQUIPMENT:
		return equip_item(slot_index)
	
	# 消耗品，使用后减少数量
	if item_type == ItemBase.ItemType.CONSUMABLE:
		# 应用效果
		_apply_consumable_effect(item)
		
		# 减少数量
		var current_stack: int = item.get("stack", 1)
		if current_stack > 1:
			item["stack"] = current_stack - 1
			_refresh_slot(slot_index)
		else:
			items[slot_index] = {}
			_refresh_slot(slot_index)
		
		item_used.emit(item.get("id", ""), slot_index)
		return true
	
	return false

## 丢弃物品
func drop_item(slot_index: int) -> bool:
	"""
	丢弃指定格子的物品
	@param slot_index: 格子索引
	@return: 是否成功丢弃
	"""
	if slot_index < 0 or slot_index >= items.size():
		return false
	
	var item: Dictionary = items[slot_index]
	if item.is_empty():
		return false
	
	if not item.get("can_drop", true):
		return false
	
	# 生成掉落物
	if player != null:
		var drop_system: DropSystem = _get_drop_system()
		if drop_system != null:
			drop_system.spawn_specific_item(item.get("id", ""), player.global_position)
	
	# 从物品栏移除
	items[slot_index] = {}
	_refresh_slot(slot_index)
	
	item_dropped.emit(item.get("id", ""), slot_index)
	return true

# =============================================================================
# 私有方法 - 初始化
# =============================================================================

func _initialize_inventory() -> void:
	"""
	初始化物品栏
	"""
	# 初始化物品数组
	items.resize(INVENTORY_SIZE)
	for i in range(INVENTORY_SIZE):
		items[i] = {}
	
	# 创建格子
	_create_slots()
	
	# 隐藏物品信息面板
	item_info_panel.hide()


func _connect_signals() -> void:
	"""
	连接信号
	"""
	button_close.pressed.connect(_on_close_pressed)
	button_use.pressed.connect(_on_use_pressed)
	button_drop.pressed.connect(_on_drop_pressed)


func _setup_equipment_slots() -> void:
	"""
	设置装备槽
	"""
	_equip_slot_nodes = {
		"weapon": weapon_slot,
		"armor": armor_slot,
		"accessory": accessory_slot
	}
	
	for slot_type in _equip_slot_nodes:
		var slot: Control = _equip_slot_nodes[slot_type]
		if slot == null:
			continue
		
		# 设置槽位类型
		slot.set_meta("slot_type", slot_type)
		
		# 连接点击信号
		if slot.has_signal("gui_input"):
			slot.gui_input.connect(_on_equip_slot_gui_input.bind(slot_type))


func _setup_quick_slots() -> void:
	"""
	设置快捷栏
	"""
	if quick_slots_container == null:
		return
	
	# 创建快捷栏格子
	for i in range(QUICK_SLOT_COUNT):
		var slot: Control = _create_quick_slot_node(i)
		quick_slots_container.add_child(slot)
		_quick_slot_nodes.append(slot)


func _create_slots() -> void:
	"""
	创建物品栏格子
	"""
	# 清除现有格子
	for slot in _slots:
		if is_instance_valid(slot):
			slot.queue_free()
	_slots.clear()
	
	# 创建新格子
	for i in range(INVENTORY_SIZE):
		var slot: Control
		
		if slot_scene:
			slot = slot_scene.instantiate()
		else:
			slot = _create_default_slot(i)
		
		grid_container.add_child(slot)
		_slots.append(slot)
		
		# 设置槽位索引
		slot.set_meta("slot_index", i)
		
		# 连接输入事件
		slot.gui_input.connect(_on_slot_gui_input.bind(i))


func _create_default_slot(index: int) -> Control:
	"""
	创建默认格子控件
	@param index: 格子索引
	@return: 格子控件
	"""
	var slot: Panel = Panel.new()
	slot.custom_minimum_size = Vector2(64, 64)
	
	# 添加背景色
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	style.border_color = Color(0.4, 0.4, 0.4)
	style.set_border_width_all(2)
	slot.add_theme_stylebox_override("panel", style)
	
	# 添加图标
	var icon: TextureRect = TextureRect.new()
	icon.name = "Icon"
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 4
	icon.offset_top = 4
	icon.offset_right = -4
	icon.offset_bottom = -4
	slot.add_child(icon)
	
	# 添加数量标签
	var count_label: Label = Label.new()
	count_label.name = "CountLabel"
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	count_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	count_label.offset_left = -20
	count_label.offset_top = -20
	count_label.offset_right = -4
	count_label.offset_bottom = -4
	count_label.add_theme_font_size_override("font_size", 12)
	slot.add_child(count_label)
	
	# 添加稀有度边框
	var rarity_border: Panel = Panel.new()
	rarity_border.name = "RarityBorder"
	rarity_border.set_anchors_preset(Control.PRESET_FULL_RECT)
	rarity_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(rarity_border)
	
	return slot


func _create_quick_slot_node(index: int) -> Control:
	"""
	创建快捷栏格子节点
	@param index: 索引
	@return: 格子控件
	"""
	var slot: Panel = Panel.new()
	slot.custom_minimum_size = Vector2(48, 48)
	
	# 背景样式
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.15, 0.9)
	style.border_color = Color(0.5, 0.5, 0.5)
	style.set_border_width_all(2)
	slot.add_theme_stylebox_override("panel", style)
	
	# 快捷键标签
	var key_label: Label = Label.new()
	key_label.text = str(index + 1)
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	key_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	key_label.offset_left = 2
	key_label.offset_top = 2
	key_label.add_theme_font_size_override("font_size", 10)
	slot.add_child(key_label)
	
	# 图标
	var icon: TextureRect = TextureRect.new()
	icon.name = "Icon"
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 4
	icon.offset_top = 4
	icon.offset_right = -4
	icon.offset_bottom = -4
	slot.add_child(icon)
	
	# 设置元数据
	slot.set_meta("quick_index", index)
	
	# 连接点击
	slot.gui_input.connect(_on_quick_slot_gui_input.bind(index))
	
	return slot

# =============================================================================
# 私有方法 - 刷新显示
# =============================================================================

func _refresh_inventory() -> void:
	"""
	刷新整个物品栏
	"""
	for i in range(_slots.size()):
		_refresh_slot(i)
	
	for slot_type in _equip_slot_nodes:
		_refresh_equipment_slot(slot_type)
	
	for i in range(QUICK_SLOT_COUNT):
		_refresh_quick_slot(i)


func _refresh_slot(slot_index: int) -> void:
	"""
	刷新指定格子
	@param slot_index: 格子索引
	"""
	if slot_index < 0 or slot_index >= _slots.size():
		return
	
	var slot: Control = _slots[slot_index]
	var item: Dictionary = items[slot_index]
	
	# 更新图标
	var icon: TextureRect = slot.get_node_or_null("Icon")
	if icon:
		if not item.is_empty() and item.has("icon"):
			icon.texture = item["icon"]
			icon.show()
		else:
			icon.texture = null
			icon.hide()
	
	# 更新数量
	var count_label: Label = slot.get_node_or_null("CountLabel")
	if count_label:
		if not item.is_empty() and item.get("stack", 1) > 1:
			count_label.text = str(item.get("stack", 1))
			count_label.show()
		else:
			count_label.hide()
	
	# 更新稀有度边框
	_update_slot_rarity_border(slot, item)


func _refresh_equipment_slot(slot_type: String) -> void:
	"""
	刷新装备槽
	@param slot_type: 装备槽类型
	"""
	var slot: Control = _equip_slot_nodes.get(slot_type)
	if slot == null:
		return
	
	var item: Dictionary = equipped_items.get(slot_type, {})
	
	var icon: TextureRect = slot.get_node_or_null("Icon")
	if icon:
		if not item.is_empty() and item.has("icon"):
			icon.texture = item["icon"]
			icon.show()
		else:
			icon.texture = null
			icon.hide()
	
	_update_slot_rarity_border(slot, item)


func _refresh_quick_slot(slot_index: int) -> void:
	"""
	刷新快捷栏格子
	@param slot_index: 格子索引
	"""
	if slot_index < 0 or slot_index >= _quick_slot_nodes.size():
		return
	
	var slot: Control = _quick_slot_nodes[slot_index]
	var quick_data: Dictionary = quick_slots[slot_index]
	
	var icon: TextureRect = slot.get_node_or_null("Icon")
	if icon:
		if not quick_data.is_empty():
			var item: Dictionary = quick_data.get("item", {})
			if not item.is_empty() and item.has("icon"):
				icon.texture = item["icon"]
				icon.show()
			else:
				icon.texture = null
				icon.hide()
		else:
			icon.texture = null
			icon.hide()


func _update_slot_rarity_border(slot: Control, item: Dictionary) -> void:
	"""
	更新格子稀有度边框
	@param slot: 格子控件
	@param item: 物品数据
	"""
	var rarity_border: Panel = slot.get_node_or_null("RarityBorder")
	if rarity_border == null:
		return
	
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	
	if not item.is_empty():
		var rarity: int = item.get("rarity", 0)
		var rarity_color: Color = ItemBase.RARITY_COLORS.get(rarity, Color.WHITE)
		style.border_color = rarity_color
		style.set_border_width_all(3)
	else:
		style.set_border_width_all(0)
	
	rarity_border.add_theme_stylebox_override("panel", style)


func _update_item_info(item: Dictionary) -> void:
	"""
	更新物品信息面板
	@param item: 物品数据
	"""
	if item.is_empty():
		item_info_panel.hide()
		button_use.disabled = true
		button_drop.disabled = true
		return
	
	item_info_panel.show()
	
	# 更新名称
	if item_name_label:
		var rarity_color: Color = item.get("rarity_color", Color.WHITE)
		var rarity_name: String = item.get("rarity_name", "")
		item_name_label.text = item.get("name", "Unknown")
		item_name_label.add_theme_color_override("font_color", rarity_color)
	
	# 更新描述
	if item_desc_label:
		item_desc_label.text = item.get("description", "")
	
	# 更新属性
	if item_stats_label:
		var stats_text: String = ""
		var stat_bonuses: Dictionary = item.get("stat_bonuses", {})
		for stat_name in stat_bonuses:
			var value = stat_bonuses[stat_name]
			stats_text += stat_name + ": +" + str(value) + "\n"
		item_stats_label.text = stats_text
	
	# 更新按钮状态
	var item_type: int = item.get("type", -1)
	button_use.disabled = (item_type != ItemBase.ItemType.CONSUMABLE)
	button_drop.disabled = not item.get("can_drop", true)

# =============================================================================
# 私有方法 - 拖拽处理
# =============================================================================

func _on_slot_gui_input(event: InputEvent, slot_index: int) -> void:
	"""
	格子输入事件处理
	@param event: 输入事件
	@param slot_index: 格子索引
	"""
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if _is_dragging:
					_end_drag_to_slot(slot_index)
				else:
					_start_drag_from_slot(slot_index)
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				# 右键使用物品
				use_item(slot_index)
	elif event is InputEventMouseMotion and _is_dragging:
		_update_drag_preview(event.global_position)


func _on_equip_slot_gui_input(event: InputEvent, slot_type: String) -> void:
	"""
	装备槽输入事件处理
	@param event: 输入事件
	@param slot_type: 装备槽类型
	"""
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if _is_dragging:
					_end_drag_to_equip_slot(slot_type)
				else:
					_start_drag_from_equip_slot(slot_type)
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				# 右键卸下装备
				unequip_item(slot_type)


func _on_quick_slot_gui_input(event: InputEvent, slot_index: int) -> void:
	"""
	快捷栏输入事件处理
	@param event: 输入事件
	@param slot_index: 格子索引
	"""
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if _is_dragging:
				_end_drag_to_quick_slot(slot_index)


func _start_drag_from_slot(slot_index: int) -> void:
	"""
	从物品栏开始拖拽
	@param slot_index: 格子索引
	"""
	var item: Dictionary = items[slot_index]
	if item.is_empty():
		_select_slot(slot_index)
		return
	
	_is_dragging = true
	_drag_source_slot = slot_index
	_drag_source_equip = ""
	_drag_source_quick = -1
	_drag_data = item.duplicate()
	
	_create_drag_preview(item)
	_select_slot(slot_index)


func _start_drag_from_equip_slot(slot_type: String) -> void:
	"""
	从装备槽开始拖拽
	@param slot_type: 装备槽类型
	"""
	var item: Dictionary = equipped_items.get(slot_type, {})
	if item.is_empty():
		return
	
	_is_dragging = true
	_drag_source_slot = -1
	_drag_source_equip = slot_type
	_drag_source_quick = -1
	_drag_data = item.duplicate()
	
	_create_drag_preview(item)


func _create_drag_preview(item: Dictionary) -> void:
	"""
	创建拖拽预览
	@param item: 物品数据
	"""
	_drag_preview = Control.new()
	_drag_preview.z_index = DRAG_PREVIEW_Z_INDEX
	
	var icon: TextureRect = TextureRect.new()
	if item.has("icon"):
		icon.texture = item["icon"]
	icon.custom_minimum_size = Vector2(48, 48)
	_drag_preview.add_child(icon)
	
	add_child(_drag_preview)
	_update_drag_preview(get_global_mouse_position())


func _update_drag_preview(global_pos: Vector2) -> void:
	"""
	更新拖拽预览位置
	@param global_pos: 全局位置
	"""
	if _drag_preview:
		_drag_preview.global_position = global_pos - Vector2(24, 24)


func _end_drag_to_slot(slot_index: int) -> void:
	"""
	结束拖拽到物品栏格子
	@param slot_index: 格子索引
	"""
	if not _is_dragging:
		return
	
	# 从装备槽拖到物品栏
	if not _drag_source_equip.is_empty():
		_swap_equip_to_inventory(_drag_source_equip, slot_index)
	# 从物品栏拖到物品栏
	elif _drag_source_slot >= 0:
		_swap_inventory_slots(_drag_source_slot, slot_index)
	
	_cleanup_drag()


func _end_drag_to_equip_slot(slot_type: String) -> void:
	"""
	结束拖拽到装备槽
	@param slot_type: 装备槽类型
	"""
	if not _is_dragging:
		return
	
	# 从物品栏拖到装备槽
	if _drag_source_slot >= 0:
		var item: Dictionary = items[_drag_source_slot]
		if _can_equip_in_slot(item, slot_type):
			equip_item(_drag_source_slot)
	# 从装备槽拖到装备槽（交换）
	elif not _drag_source_equip.is_empty() and _drag_source_equip != slot_type:
		_swap_equipment_slots(_drag_source_equip, slot_type)
	
	_cleanup_drag()


func _end_drag_to_quick_slot(slot_index: int) -> void:
	"""
	结束拖拽到快捷栏
	@param slot_index: 快捷栏索引
	"""
	if not _is_dragging:
		return
	
	if _drag_source_slot >= 0:
		set_quick_slot(slot_index, _drag_source_slot)
	
	_cleanup_drag()


func _cancel_drag() -> void:
	"""
	取消拖拽
	"""
	_cleanup_drag()


func _cleanup_drag() -> void:
	"""
	清理拖拽状态
	"""
	_is_dragging = false
	_drag_source_slot = -1
	_drag_source_equip = ""
	_drag_source_quick = -1
	_drag_data = {}
	
	if _drag_preview and is_instance_valid(_drag_preview):
		_drag_preview.queue_free()
	_drag_preview = null


func _swap_inventory_slots(source: int, target: int) -> void:
	"""
	交换物品栏格子
	@param source: 源格子
	@param target: 目标格子
	"""
	var temp: Dictionary = items[source]
	items[source] = items[target]
	items[target] = temp
	
	_refresh_slot(source)
	_refresh_slot(target)


func _swap_equip_to_inventory(equip_slot: String, inv_slot: int) -> void:
	"""
	从装备槽交换到物品栏
	@param equip_slot: 装备槽类型
	@param inv_slot: 物品栏索引
	"""
	var equip_item: Dictionary = equipped_items[equip_slot]
	var inv_item: Dictionary = items[inv_slot]
	
	# 检查物品栏物品是否可以装备到该槽位
	if not inv_item.is_empty() and not _can_equip_in_slot(inv_item, equip_slot):
		return
	
	# 卸下装备效果
	if not equip_item.is_empty() and player != null:
		_unequip_item_effects(equip_item)
	
	# 交换
	equipped_items[equip_slot] = inv_item
	items[inv_slot] = equip_item
	
	# 应用新装备效果
	if not inv_item.is_empty() and player != null:
		_equip_item_effects(inv_item)
	
	_refresh_slot(inv_slot)
	_refresh_equipment_slot(equip_slot)
	equipment_changed.emit(equip_slot, equipped_items[equip_slot])


func _swap_equipment_slots(source_type: String, target_type: String) -> void:
	"""
	交换装备槽
	@param source_type: 源装备槽
	@param target_type: 目标装备槽
	"""
	var source_item: Dictionary = equipped_items[source_type]
	var target_item: Dictionary = equipped_items[target_type]
	
	# 检查是否可以交换
	if not source_item.is_empty() and not _can_equip_in_slot(source_item, target_type):
		return
	if not target_item.is_empty() and not _can_equip_in_slot(target_item, source_type):
		return
	
	# 交换
	equipped_items[source_type] = target_item
	equipped_items[target_type] = source_item
	
	_refresh_equipment_slot(source_type)
	_refresh_equipment_slot(target_type)
	
	equipment_changed.emit(source_type, equipped_items[source_type])
	equipment_changed.emit(target_type, equipped_items[target_type])

# =============================================================================
# 私有方法 - 工具函数
# =============================================================================

func _select_slot(slot_index: int) -> void:
	"""
	选中指定格子
	@param slot_index: 格子索引
	"""
	# 取消之前的选中
	if selected_slot_index >= 0 and selected_slot_index < _slots.size():
		var old_slot: Control = _slots[selected_slot_index]
		old_slot.modulate = Color.WHITE
	
	# 选中新的格子
	selected_slot_index = slot_index
	
	if slot_index >= 0 and slot_index < _slots.size():
		var slot: Control = _slots[slot_index]
		slot.modulate = Color(1.2, 1.2, 1.0)
		
		# 更新物品信息
		var item: Dictionary = items[slot_index]
		_update_item_info(item)
		
		item_selected.emit(item.get("id", ""), slot_index)


func _clear_selection() -> void:
	"""
	清除选中状态
	"""
	if selected_slot_index >= 0 and selected_slot_index < _slots.size():
		_slots[selected_slot_index].modulate = Color.WHITE
	
	selected_slot_index = -1
	item_info_panel.hide()
	button_use.disabled = true
	button_drop.disabled = true


func _get_equip_slot_type(item: Dictionary) -> String:
	"""
	获取物品对应的装备槽类型
	@param item: 物品数据
	@return: 装备槽类型
	"""
	var equip_slot: int = item.get("equip_slot", ItemBase.EquipSlot.NONE)
	
	match equip_slot:
		ItemBase.EquipSlot.WEAPON:
			return "weapon"
		ItemBase.EquipSlot.ARMOR:
			return "armor"
		ItemBase.EquipSlot.ACCESSORY:
			return "accessory"
	
	return ""


func _can_equip_in_slot(item: Dictionary, slot_type: String) -> bool:
	"""
	检查物品是否可以装备到指定槽位
	@param item: 物品数据
	@param slot_type: 槽位类型
	@return: 是否可以装备
	"""
	var item_slot_type: String = _get_equip_slot_type(item)
	return item_slot_type == slot_type


func _has_empty_slot() -> bool:
	"""
	检查是否有空格子
	@return: 是否有空格子
	"""
	for item in items:
		if item.is_empty():
			return true
	return false


func _apply_consumable_effect(item: Dictionary) -> void:
	"""
	应用消耗品效果
	@param item: 物品数据
	"""
	if player == null:
		return
	
	if "stats" in player and player.stats is PlayerStats:
		# 治疗效果
		var heal_amount: float = item.get("heal_amount", 0)
		if heal_amount > 0:
			player.stats.heal(heal_amount)
		
		# 法力恢复
		var mana_restore: float = item.get("mana_restore", 0)
		if mana_restore > 0:
			player.stats.restore_mana(mana_restore)
		
		# 经验值
		var exp_amount: int = item.get("exp_amount", 0)
		if exp_amount > 0:
			player.stats.add_experience(exp_amount)


func _equip_item_effects(item: Dictionary) -> void:
	"""
	应用装备效果
	@param item: 物品数据
	"""
	if player == null:
		return
	
	var stat_bonuses: Dictionary = item.get("stat_bonuses", {})
	
	for stat_name in stat_bonuses:
		var value = stat_bonuses[stat_name]
		
		if "stats" in player and player.stats is PlayerStats:
			if value is float and stat_name.ends_with("_percent"):
				player.stats.add_percent_bonus(stat_name.replace("_percent", ""), value)
			else:
				player.stats.add_flat_bonus(stat_name, value)


func _unequip_item_effects(item: Dictionary) -> void:
	"""
	移除装备效果
	@param item: 物品数据
	"""
	if player == null:
		return
	
	var stat_bonuses: Dictionary = item.get("stat_bonuses", {})
	
	for stat_name in stat_bonuses:
		var value = stat_bonuses[stat_name]
		
		if "stats" in player and player.stats is PlayerStats:
			if value is float and stat_name.ends_with("_percent"):
				player.stats.remove_percent_bonus(stat_name.replace("_percent", ""), value)
			else:
				player.stats.remove_flat_bonus(stat_name, value)


func _get_drop_system() -> DropSystem:
	"""
	获取掉落系统
	@return: 掉落系统实例
	"""
	var tree: SceneTree = get_tree()
	if tree == null:
		return null
	
	var drop_systems: Array[Node] = tree.get_nodes_in_group("drop_system")
	if drop_systems.is_empty():
		return null
	
	return drop_systems[0]

# =============================================================================
# 信号回调
# =============================================================================

func _on_close_pressed() -> void:
	"""
	关闭按钮按下
	"""
	AudioManager.play_ui_sound("button_click")
	close_inventory()


func _on_use_pressed() -> void:
	"""
	使用按钮按下
	"""
	if selected_slot_index < 0:
		return
	
	AudioManager.play_ui_sound("button_click")
	use_item(selected_slot_index)
	_clear_selection()


func _on_drop_pressed() -> void:
	"""
	丢弃按钮按下
	"""
	if selected_slot_index < 0:
		return
	
	AudioManager.play_ui_sound("button_click")
	drop_item(selected_slot_index)
	_clear_selection()

# =============================================================================
# 数据序列化
# =============================================================================

## 获取物品栏数据
func get_inventory_data() -> Dictionary:
	"""
	获取物品栏数据用于保存
	@return: 物品栏数据字典
	"""
	return {
		"items": items.duplicate(),
		"equipped": equipped_items.duplicate(),
		"quick_slots": quick_slots.duplicate()
	}


## 加载物品栏数据
func load_inventory_data(data: Dictionary) -> void:
	"""
	从保存数据加载物品栏
	@param data: 物品栏数据
	"""
	# 清空当前数据
	clear_inventory()
	for slot in equipped_items:
		equipped_items[slot] = {}
	for i in range(QUICK_SLOT_COUNT):
		quick_slots[i] = {}
	
	# 加载物品
	var loaded_items: Array = data.get("items", [])
	for i in range(mini(loaded_items.size(), INVENTORY_SIZE)):
		items[i] = loaded_items[i]
	
	# 加载装备
	var loaded_equipped: Dictionary = data.get("equipped", {})
	for slot in loaded_equipped:
		if equipped_items.has(slot):
			equipped_items[slot] = loaded_equipped[slot]
	
	# 加载快捷栏
	var loaded_quick: Array = data.get("quick_slots", [])
	for i in range(mini(loaded_quick.size(), QUICK_SLOT_COUNT)):
		quick_slots[i] = loaded_quick[i]
	
	# 刷新显示
	_refresh_inventory()
