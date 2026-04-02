## Void Hunter - 全屏攻击技能
## @description: 对屏幕内所有敌人造成大量伤害
## @author: Void Hunter Team
## @version: 1.0.0

extends SkillBase
class_name SkillScreenNuke

# =============================================================================
# 配置参数
# =============================================================================

## 伤害倍率（相对于普通攻击）
@export var damage_multiplier: float = 2.0

## 视觉效果持续时间
@export var effect_duration: float = 1.0

## 是否有延迟
@export var has_delay: bool = true

## 延迟时间
@export var delay_time: float = 0.5

## 爆炸特效数量
@export var explosion_count: int = 15

# =============================================================================
# 初始化
# =============================================================================

func _init() -> void:
	skill_id = "screen_nuke"
	skill_name = "毁灭打击"
	description = "召唤毁灭性力量，对屏幕内所有敌人造成巨大伤害。消耗大量法力。"
	skill_type = SkillType.ACTIVE
	skill_category = SkillCategory.OFFENSIVE
	target_type = TargetType.SELF
	element = SkillElement.HOLY
	hotkey_slot = 4

	base_damage = 40.0
	base_cooldown = 15.0
	base_mana_cost = 80.0  # 高法力消耗
	effect_range = 2000.0  # 覆盖整个屏幕
	duration = effect_duration


# =============================================================================
# 技能效果
# =============================================================================

func _execute_self_effect() -> void:
	"""
	执行全屏攻击效果
	"""
	if owner_node == null:
		return

	# 播放开始音效
	AudioManager.play_sfx("nuke_charge")

	if has_delay:
		# 有延迟，先显示警告效果
		_show_warning_effect()
		await owner_node.get_tree().create_timer(delay_time).timeout

	# 执行全屏攻击
	_execute_nuke()


func _show_warning_effect() -> void:
	"""
	显示警告效果
	"""
	if owner_node == null:
		return

	# 创建全屏闪烁警告
	var flash: ColorRect = ColorRect.new()
	flash.name = "NukeWarning"
	flash.color = Color(1.0, 0.3, 0.3, 0.0)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.z_index = 100

	owner_node.get_tree().current_scene.add_child(flash)

	# 闪烁效果
	var tween: Tween = owner_node.create_tween()
	for i in range(3):
		tween.tween_property(flash, "color:a", 0.3, 0.1)
		tween.tween_property(flash, "color:a", 0.0, 0.1)

	tween.tween_callback(flash.queue_free)


func _execute_nuke() -> void:
	"""
	执行毁灭打击
	"""
	if owner_node == null:
		return

	# 播放爆炸音效
	AudioManager.play_sfx("nuke_explosion")

	# 创建全屏闪光
	_create_screen_flash()

	# 获取屏幕内所有敌人
	var targets: Array[Node] = _get_all_enemies_on_screen()

	# 对每个敌人造成伤害
	for target in targets:
		if target.has_method("take_damage"):
			target.take_damage(get_nuke_damage(), owner_node)
			skill_hit.emit(self, target, get_nuke_damage())

	# VFX: death explosions on nuked enemies
	for target in targets:
		if VFXManager:
			VFXManager.spawn_death_explosion(target.global_position, "large")

	# 创建随机爆炸效果
	_create_explosion_effects()

	# 屏幕震动
	_apply_screen_shake()


func _create_screen_flash() -> void:
	"""
	创建全屏闪光效果
	"""
	if owner_node == null:
		return

	var flash: ColorRect = ColorRect.new()
	flash.name = "NukeFlash"
	flash.color = Color(1.0, 1.0, 1.0, 0.9)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.z_index = 100

	owner_node.get_tree().current_scene.add_child(flash)

	# 快速淡出
	var tween: Tween = owner_node.create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.5)
	tween.tween_callback(flash.queue_free)


func _create_explosion_effects() -> void:
	"""
	创建随机爆炸效果
	"""
	if owner_node == null:
		return

	var viewport_rect: Rect2 = owner_node.get_viewport().get_visible_rect()
	var camera: Camera2D = owner_node.get_viewport().get_camera_2d()

	for i in range(get_explosion_count()):
		# 随机位置
		var random_offset: Vector2 = Vector2(
			randf_range(-viewport_rect.size.x / 2, viewport_rect.size.x / 2),
			randf_range(-viewport_rect.size.y / 2, viewport_rect.size.y / 2)
		)
		var spawn_pos: Vector2 = camera.global_position + random_offset if camera else random_offset

		# 延迟创建爆炸
		await owner_node.get_tree().create_timer(randf() * 0.3).timeout
		_create_single_explosion(spawn_pos)


func _create_single_explosion(pos: Vector2) -> void:
	"""
	创建单个爆炸效果
	"""
	if owner_node == null:
		return

	var explosion: Node2D = Node2D.new()
	explosion.global_position = pos

	# 创建爆炸圆形
	var circle: Node2D = Node2D.new()
	var sprite: Sprite2D = Sprite2D.new()
	var texture: ImageTexture = ImageTexture.new()
	var size: int = 60
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(1.0, 0.8, 0.2, 0.8))
	texture.set_image(image)
	sprite.texture = texture
	sprite.modulate = Color(1.0, 0.6, 0.1)
	circle.add_child(sprite)
	explosion.add_child(circle)

	owner_node.get_tree().current_scene.add_child(explosion)

	# 扩大并淡出
	var tween: Tween = owner_node.create_tween()
	tween.tween_property(circle, "scale", Vector2(2.0, 2.0), 0.3)
	tween.parallel().tween_property(circle, "modulate:a", 0.0, 0.3)
	tween.tween_callback(explosion.queue_free)


func _apply_screen_shake() -> void:
	"""
	应用屏幕震动效果
	"""
	if owner_node == null:
		return

	var camera: Camera2D = owner_node.get_viewport().get_camera_2d()
	if camera == null:
		return

	var original_offset: Vector2 = camera.offset
	var shake_intensity: float = 20.0
	var shake_duration: float = 0.3

	for i in range(int(shake_duration / 0.02)):
		camera.offset = original_offset + Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		await owner_node.get_tree().create_timer(0.02).timeout

	camera.offset = original_offset


func _get_all_enemies_on_screen() -> Array[Node]:
	"""
	获取屏幕内所有敌人
	"""
	var targets: Array[Node] = []
	var enemies: Array[Node] = owner_node.get_tree().get_nodes_in_group("enemies")

	var viewport_rect: Rect2 = owner_node.get_viewport().get_visible_rect()
	var camera: Camera2D = owner_node.get_viewport().get_camera_2d()
	var camera_pos: Vector2 = camera.global_position if camera else Vector2.ZERO

	# 扩大检测范围，确保边缘的敌人也能被击中
	var screen_rect: Rect2 = Rect2(
		camera_pos - viewport_rect.size / 2 - Vector2(100, 100),
		viewport_rect.size + Vector2(200, 200)
	)

	for enemy in enemies:
		if is_instance_valid(enemy) and screen_rect.has_point(enemy.global_position):
			if enemy.has_method("take_damage") or "current_health" in enemy:
				targets.append(enemy)

	return targets


# =============================================================================
# 属性获取
# =============================================================================

func get_nuke_damage() -> float:
	"""
	获取毁灭打击伤害
	"""
	return get_damage() * damage_multiplier * (1.0 + (current_level - 1) * 0.3)


func get_explosion_count() -> int:
	"""
	获取爆炸特效数量
	"""
	return explosion_count + (current_level - 1) * 5


# =============================================================================
# 升级效果
# =============================================================================

func _on_level_up(new_level: int) -> void:
	"""
	升级时增强毁灭打击
	"""
	match new_level:
		2:
			damage_multiplier = 2.5
			delay_time = 0.3
		3:
			damage_multiplier = 3.0
			base_mana_cost = 60.0  # 降低法力消耗
			has_delay = false
