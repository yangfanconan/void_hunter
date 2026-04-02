extends Node

var _current_slot: int = 0
var _save_data: Dictionary = {}

func _ready() -> void:
	print("[SaveManager] 初始化完成")

func save_game(slot: int = -1) -> bool:
	var save_slot: int = slot if slot >= 0 else _current_slot
	print("[SaveManager] 保存游戏到槽位 %d" % save_slot)
	return true

func load_game(slot: int = -1) -> bool:
	var load_slot: int = slot if slot >= 0 else _current_slot
	print("[SaveManager] 从槽位 %d 加载游戏" % load_slot)
	return true

func has_save(_slot: int = -1) -> bool:
	return false


func delete_save(_slot: int) -> bool:
	return true

func auto_save() -> void:
	save_game(0)

func get_save_data() -> Dictionary:
	return _save_data

func set_save_data(key: String, value) -> void:
	_save_data[key] = value
