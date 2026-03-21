extends Node

var _pools: Dictionary = {}

func _ready() -> void:
	print("[ObjectPool] 初始化完成")

func get_instance(scene: PackedScene, parent: Node) -> Node:
	if not scene:
		return null
	var instance := scene.instantiate()
	if parent:
		parent.add_child(instance)
	return instance

func return_instance(instance: Node) -> void:
	if instance and is_instance_valid(instance):
		instance.queue_free()

func warm_up_pools() -> void:
	print("[ObjectPool] 预热对象池")

func clear_all() -> void:
	_pools.clear()
