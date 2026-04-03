## Void Hunter - 传送卷轴
## @description: 使用后传送到安全位置
## @version: 1.0.0

extends "res://src/items/item_base.gd"

func _ready() -> void:
	item_id = "consumable_teleport_scroll"
	item_name = "传送卷轴"
	description = "使用后传送到附近安全位置并获得短暂无敌"
	item_type = ItemType.CONSUMABLE
	rarity = ItemRarity.UNCOMMON
	max_stack = 10
	current_stack = 1

	sell_price = 30
	buy_price = 80

	super._ready()

func _apply_immediate_effects(target: Node) -> void:
	# 传送到随机安全位置
	var angle: float = randf() * TAU
	var distance: float = randf_range(100.0, 200.0)
	target.global_position += Vector2(cos(angle), sin(angle)) * distance

	# 短暂无敌
	var status_mgr = target.get_tree().current_scene.get_node_or_null("StatusEffectManager")
	if status_mgr and status_mgr.has_method("apply_invincible"):
		status_mgr.apply_invincible(target, 1.5, null)