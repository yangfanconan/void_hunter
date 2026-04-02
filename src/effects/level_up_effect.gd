## Void Hunter - 升级效果管理器
## @description: 管理玩家升级时的视觉效果、粒子效果和技能选择触发
## @author: Void Hunter Team
## @version: 1.0.0

extends Node2D

# =============================================================================
# 信号定义
# =============================================================================

## 升级效果完成时触发
signal effect_completed()

## 技能选择完成时触发
signal skill_selection_completed(skill_id: String)

# =============================================================================
# 预加载
# =============================================================================

## 属性变化浮动文字脚本
const StatChangePopupScript := preload("res://src/effects/stat_change_popup.gd")

# =============================================================================
# 常量定义 - 属性类型（与 StatChangePopup.StatType 对应）
# =============================================================================

## 攻击力
const STAT_ATTACK: int = 0
## 生命值
const STAT_HEALTH: int = 1
## 移动速度
const STAT_SPEED: int = 2
## 暴击率
const STAT_CRIT: int = 3
## 吸血
const STAT_LIFE_STEAL: int = 4
## 防御力
const STAT_DEFENSE: int = 5
## 法力值
const STAT_MANA: int = 6
## 通用
const STAT_GENERIC: int = 7

# =============================================================================
# 常量定义
# =============================================================================

## 效果持续时间
const EFFECT_DURATION: float = 1.5

## 光环扩展速度
const RING_EXPAND_SPEED: float = 300.0

## 粒子数量
const PARTICLE_COUNT: int = 30

## 光柱持续时间
const BEAM_DURATION: float = 1.0

# =============================================================================
# 公共变量
# =============================================================================

## 玩家引用
var player: Node = null

## 技能选择界面引用
var skill_selection_ui: Control = null

# =============================================================================
# 私有变量
# =============================================================================

var _is_playing: bool = false
var _effect_timer: float = 0.0
var _particles: Array[Node2D] = []
var _ring: Node2D = null
var _beam: Node2D = null
var _flash: ColorRect = null

# =============================================================================
# 生命周期方法
# =============================================================================

func _ready() -> void:
	"""节点就绪时初始化"""
	# 创建效果节点（初始隐藏）
	_create_effect_nodes()
	hide()


func _process(delta: float) -> void:
	"""每帧更新"""
	if _is_playing:
		_update_effect(delta)

# =============================================================================
# 公共方法
# =============================================================================

## 播放升级效果
func play_level_up_effect(player_node: Node) -> void:
	"""
	播放升级效果
	@param player_node: 升级的玩家节点
	"""
	player = player_node
	_is_playing = true
	_effect_timer = 0.0
	
	# 设置位置
	if player:
		global_position = player.global_position
	
	# 显示效果
	show()
	
	# 播放音效
	AudioManager.play_sfx("level_up", 1.0)
	
	# 启动各种效果
	_start_ring_effect()
	_start_particle_effect()
	_start_beam_effect()
	_start_flash_effect()
	
	# 屏幕震动
	_shake_screen()
	
	# 慢动作效果
	_start_slow_motion()
	
	print("[LevelUpEffect] 播放升级效果")


## 设置技能选择界面
func set_skill_selection(ui: Control) -> void:
	"""设置技能选择界面引用"""
	skill_selection_ui = ui


## 强制结束效果
func stop_effect() -> void:
	"""强制结束效果"""
	_is_playing = false
	_cleanup_effects()
	hide()
	effect_completed.emit()

# =============================================================================
# 私有方法 - 创建效果节点
# =============================================================================

func _create_effect_nodes() -> void:
	"""创建效果节点"""
	# 创建光环
	_ring = _create_ring()
	add_child(_ring)
	
	# 创建光柱
	_beam = _create_beam()
	add_child(_beam)
	
	# 创建闪光
	_flash = _create_flash()
	add_child(_flash)


func _create_ring() -> Node2D:
	"""创建光环效果"""
	var ring := Node2D.new()
	ring.name = "Ring"
	ring.z_index = 10
	
	# 使用 Line2D 创建圆环
	var line := Line2D.new()
	line.name = "RingLine"
	line.width = 4.0
	line.default_color = Color(1.0, 0.9, 0.3, 1.0)
	
	# 创建圆形
	var points: Array[Vector2] = []
	var segments := 32
	for i in range(segments + 1):
		var angle := (float(i) / segments) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * 20.0)
	line.points = points
	
	ring.add_child(line)
	ring.hide()
	
	return ring


func _create_beam() -> Node2D:
	"""创建光柱效果"""
	var beam := Node2D.new()
	beam.name = "Beam"
	beam.z_index = 5
	
	# 使用 Polygon2D 创建光柱
	var polygon := Polygon2D.new()
	polygon.name = "BeamPolygon"
	polygon.color = Color(1.0, 0.9, 0.3, 0.5)
	
	beam.add_child(polygon)
	beam.hide()
	
	return beam


func _create_flash() -> ColorRect:
	"""创建闪光效果"""
	var flash := ColorRect.new()
	flash.name = "Flash"
	flash.color = Color(1.0, 1.0, 0.8, 0.0)
	flash.z_index = 100
	
	# 设置为全屏
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.custom_minimum_size = Vector2(2000, 2000)
	flash.position = Vector2(-1000, -1000)
	
	flash.hide()
	
	return flash


func _create_particle() -> Node2D:
	"""创建单个粒子"""
	var particle := Node2D.new()
	particle.name = "Particle"
	
	# 粒子精灵
	var sprite := Sprite2D.new()
	var texture := ImageTexture.new()
	var image := Image.create(6, 6, false, Image.FORMAT_RGBA8)
	
	# 随机颜色（金色系）
	var hue := randf_range(0.1, 0.15)
	var color := Color.from_hsv(hue, 0.8, 1.0, 1.0)
	image.fill(color)
	texture.set_image(image)
	sprite.texture = texture
	sprite.centered = true
	
	particle.add_child(sprite)
	
	return particle

# =============================================================================
# 私有方法 - 启动效果
# =============================================================================

func _start_ring_effect() -> void:
	"""启动光环效果"""
	if _ring == null:
		return
	
	_ring.show()
	_ring.scale = Vector2.ZERO
	
	# 光环扩散动画
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(_ring, "scale", Vector2(5.0, 5.0), EFFECT_DURATION)
	
	# 同时淡出
	var line := _ring.get_node_or_null("RingLine")
	if line:
		var fade_tween := create_tween()
		fade_tween.tween_interval(EFFECT_DURATION * 0.5)
		fade_tween.tween_property(line, "default_color:a", 0.0, EFFECT_DURATION * 0.5)


func _start_particle_effect() -> void:
	"""启动粒子效果"""
	# 清理旧粒子
	for particle in _particles:
		if is_instance_valid(particle):
			particle.queue_free()
	_particles.clear()
	
	# 创建新粒子
	for i in range(PARTICLE_COUNT):
		var particle := _create_particle()
		add_child(particle)
		_particles.append(particle)
		
		# 随机初始位置
		var angle := randf() * TAU
		var dist := randf_range(10.0, 30.0)
		particle.position = Vector2(cos(angle), sin(angle)) * dist
		
		# 向外飞散动画
		var target_dist := randf_range(100.0, 200.0)
		var target_pos := Vector2(cos(angle), sin(angle)) * target_dist
		
		var tween := create_tween()
		tween.set_parallel(true)
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_QUAD)
		
		# 位置动画
		tween.tween_property(particle, "position", target_pos, EFFECT_DURATION)
		
		# 淡出动画
		var sprite := particle.get_child(0) as Sprite2D
		if sprite:
			tween.tween_property(sprite, "modulate:a", 0.0, EFFECT_DURATION).set_delay(EFFECT_DURATION * 0.5)
		
		# 删除粒子
		tween.tween_callback(particle.queue_free).set_delay(EFFECT_DURATION)


func _start_beam_effect() -> void:
	"""启动光柱效果"""
	if _beam == null:
		return
	
	_beam.show()
	
	var polygon := _beam.get_node_or_null("BeamPolygon") as Polygon2D
	if polygon == null:
		return
	
	# 创建光柱形状
	var width := 40.0
	var height := 400.0
	polygon.polygon = PackedVector2Array([
		Vector2(-width/2, 0),
		Vector2(width/2, 0),
		Vector2(width/4, -height),
		Vector2(-width/4, -height)
	])
	
	# 光柱上升动画
	var tween := create_tween()
	tween.set_parallel(true)
	
	# 上升
	tween.tween_property(_beam, "position:y", -height, BEAM_DURATION)
	
	# 淡出
	tween.tween_property(polygon, "color:a", 0.0, BEAM_DURATION * 0.7).set_delay(BEAM_DURATION * 0.3)
	
	# 隐藏
	tween.tween_callback(func(): _beam.hide()).set_delay(BEAM_DURATION)


func _start_flash_effect() -> void:
	"""启动闪光效果"""
	if _flash == null:
		return
	
	_flash.show()
	_flash.color.a = 0.0
	
	var tween := create_tween()
	tween.tween_property(_flash, "color:a", 0.5, 0.1)
	tween.tween_property(_flash, "color:a", 0.0, 0.3)
	tween.tween_callback(func(): _flash.hide())


func _shake_screen() -> void:
	"""屏幕震动"""
	var camera := _get_camera()
	if camera == null:
		return
	
	# 保存原始位置
	var original_offset := camera.offset
	
	# 震动动画
	var shake_tween := create_tween()
	for i in range(5):
		var shake_offset := Vector2(randf_range(-8, 8), randf_range(-8, 8))
		shake_tween.tween_property(camera, "offset", original_offset + shake_offset, 0.05)
		shake_tween.tween_property(camera, "offset", original_offset, 0.05)
	
	shake_tween.tween_property(camera, "offset", original_offset, 0.1)


func _start_slow_motion() -> void:
	"""启动慢动作效果"""
	# 短暂慢动作
	Engine.time_scale = 0.3
	
	var tween := create_tween()
	tween.tween_interval(0.3 * 0.5)  # 慢动作时间
	tween.tween_property(Engine, "time_scale", 1.0, 0.3)

# =============================================================================
# 私有方法 - 更新
# =============================================================================

func _update_effect(delta: float) -> void:
	"""更新效果"""
	_effect_timer += delta
	
	# 更新光环（跟随玩家）
	if player and is_instance_valid(player) and _ring:
		global_position = player.global_position
	
	# 检查效果是否完成
	if _effect_timer >= EFFECT_DURATION:
		_on_effect_complete()


func _on_effect_complete() -> void:
	"""效果完成回调"""
	_is_playing = false
	_cleanup_effects()
	
	# 显示技能选择界面
	_show_skill_selection()
	
	print("[LevelUpEffect] 升级效果完成")


func _show_skill_selection() -> void:
	"""显示技能选择界面"""
	if skill_selection_ui == null:
		# 尝试从场景中获取
		var main := get_tree().current_scene
		if main:
			skill_selection_ui = main.get_node_or_null("SkillSelection")
		
		if skill_selection_ui == null:
			# 创建技能选择界面
			skill_selection_ui = _create_skill_selection_ui()
			if skill_selection_ui == null:
				print("[LevelUpEffect] 无法创建技能选择界面")
				effect_completed.emit()
				return
	
	# 暂停游戏
	get_tree().paused = true
	
	# 连接信号
	if not skill_selection_ui.skill_selected.is_connected(_on_skill_selected):
		skill_selection_ui.skill_selected.connect(_on_skill_selected)
	if not skill_selection_ui.selection_skipped.is_connected(_on_selection_skipped):
		skill_selection_ui.selection_skipped.connect(_on_selection_skipped)
	
	# 显示技能选择
	if skill_selection_ui.has_method("show_skill_selection"):
		skill_selection_ui.show_skill_selection()
	else:
		skill_selection_ui.show()
		get_tree().paused = true


func _create_skill_selection_ui() -> Control:
	"""创建技能选择界面"""
	var ui_scene: PackedScene = load("res://scenes/ui/skill_selection.tscn")
	var ui: Control
	
	if ui_scene:
		ui = ui_scene.instantiate() as Control
	else:
		ui = Control.new()
		ui.anchors_preset = Control.PRESET_FULL_RECT
		ui.anchor_right = 1.0
		ui.anchor_bottom = 1.0
		var script: GDScript = load("res://src/ui/skill_selection.gd")
		if script:
			ui.set_script(script)
	
	ui.name = "SkillSelection"
	ui.process_mode = Node.PROCESS_MODE_ALWAYS
	ui.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var main := get_tree().current_scene
	if main:
		main.add_child(ui)
	
	return ui


func _on_skill_selected(skill_id: String) -> void:
	"""技能被选中"""
	print("[LevelUpEffect] 技能被选中: %s" % skill_id)
	
	# 应用技能效果
	_apply_skill_effect(skill_id)
	
	# 继续游戏
	_resume_game()
	
	skill_selection_completed.emit(skill_id)


func _on_selection_skipped() -> void:
	"""跳过选择"""
	print("[LevelUpEffect] 跳过技能选择")
	_resume_game()
	skill_selection_completed.emit("")


func _resume_game() -> void:
	"""恢复游戏"""
	get_tree().paused = false
	GameManager.set_game_state(GameManager.GameState.PLAYING)


## 主动技能ID列表（用于判断技能类型）
const ACTIVE_SKILLS: Array[String] = [
	"fire_bullet",      ## 火焰弹
	"frost_arrow",      ## 冰霜箭
	"lightning_chain",  ## 闪电链
	"shadow_slash",     ## 暗影斩
	"shield",           ## 魔法护盾
	"blink",            ## 闪现
	"iron_wall",        ## 铁壁
	"reflect",          ## 反射
	"time_slow",        ## 时间减缓
	"gravity_field",    ## 引力场
	"healing_aura",     ## 治愈光环
	"speed_aura"        ## 加速光环
]

func _apply_skill_effect(skill_id: String) -> void:
	"""应用技能效果"""
	if player == null or not is_instance_valid(player):
		return
	
	print("[LevelUpEffect] 应用技能效果: %s" % skill_id)
	
	# 获取玩家位置用于显示浮动文字
	var player_pos: Vector2 = player.global_position
	
	# 判断是否为主动技能
	var is_active_skill := skill_id in ACTIVE_SKILLS
	
	# 根据技能ID应用效果
	match skill_id:
		# ================== 属性加成类 ==================
		"attack_boost":
			if "attack_bonus_percent" in player:
				player.attack_bonus_percent += 0.1
			elif "bullet_damage" in player:
				player.bullet_damage *= 1.1
			print("[LevelUpEffect] 攻击力提升10%%")
			# 显示浮动文字
			_show_stat_popup(player_pos, STAT_ATTACK, 10.0, true)
		
		"health_boost":
			if "health_bonus" in player:
				player.health_bonus += 20
				player.max_health += 20
			else:
				player.max_health += 20
			player.current_health = min(player.current_health + 20, player.max_health)
			print("[LevelUpEffect] 生命值+20")
			# 显示浮动文字
			_show_stat_popup(player_pos, STAT_HEALTH, 20.0, false)
		
		"speed_boost":
			if "speed_bonus_percent" in player:
				player.speed_bonus_percent += 0.05
			elif "move_speed" in player:
				player.move_speed *= 1.05
			print("[LevelUpEffect] 移动速度提升5%%")
			# 显示浮动文字
			_show_stat_popup(player_pos, STAT_SPEED, 5.0, true)
		
		"crit_boost":
			if "crit_chance_bonus" in player:
				player.crit_chance_bonus += 0.05
			print("[LevelUpEffect] 暴击率+5%%")
			# 显示浮动文字
			_show_stat_popup(player_pos, STAT_CRIT, 5.0, true)
		
		"life_steal":
			if "life_steal_percent" in player:
				player.life_steal_percent += 0.03
			print("[LevelUpEffect] 吸血+3%%")
			# 显示浮动文字
			_show_stat_popup(player_pos, STAT_LIFE_STEAL, 3.0, true)
		
		# ================== 主动技能 - 攻击类 ==================
		"fire_bullet":
			_unlock_active_skill(skill_id, "火焰弹")
			_show_stat_popup(player_pos, STAT_GENERIC, 0.0, false, "获得技能: 火焰弹!")
		
		"frost_arrow":
			_unlock_active_skill(skill_id, "冰霜箭")
			_show_stat_popup(player_pos, STAT_GENERIC, 0.0, false, "获得技能: 冰霜箭!")
		
		"lightning_chain":
			_unlock_active_skill(skill_id, "闪电链")
			_show_stat_popup(player_pos, STAT_GENERIC, 0.0, false, "获得技能: 闪电链!")
		
		"shadow_slash":
			_unlock_active_skill(skill_id, "暗影斩")
			_show_stat_popup(player_pos, STAT_GENERIC, 0.0, false, "获得技能: 暗影斩!")
		
		# ================== 主动技能 - 防御类 ==================
		"shield":
			_unlock_active_skill(skill_id, "魔法护盾")
			_show_stat_popup(player_pos, STAT_DEFENSE, 0.0, false, "获得技能: 魔法护盾!")
		
		"blink":
			_unlock_active_skill(skill_id, "闪现")
			_show_stat_popup(player_pos, STAT_SPEED, 0.0, false, "获得技能: 闪现!")
		
		"iron_wall":
			_unlock_active_skill(skill_id, "铁壁")
			_show_stat_popup(player_pos, STAT_DEFENSE, 0.0, false, "获得技能: 铁壁!")
		
		"reflect":
			_unlock_active_skill(skill_id, "反射")
			_show_stat_popup(player_pos, STAT_DEFENSE, 0.0, false, "获得技能: 反射!")
		
		# ================== 控制技能 ==================
		"time_slow":
			_unlock_active_skill(skill_id, "时间减缓")
			_show_stat_popup(player_pos, STAT_MANA, 0.0, false, "获得技能: 时间减缓!")
		
		"gravity_field":
			_unlock_active_skill(skill_id, "引力场")
			_show_stat_popup(player_pos, STAT_MANA, 0.0, false, "获得技能: 引力场!")
		
		# ================== 辅助技能 ==================
		"healing_aura":
			_unlock_active_skill(skill_id, "治愈光环")
			_show_stat_popup(player_pos, STAT_HEALTH, 0.0, false, "获得技能: 治愈光环!")
		
		"speed_aura":
			_unlock_active_skill(skill_id, "加速光环")
			_show_stat_popup(player_pos, STAT_SPEED, 0.0, false, "获得技能: 加速光环!")
		
		_:
			# 检查是否为主动技能
			if is_active_skill:
				_unlock_active_skill(skill_id, skill_id)
			print("[LevelUpEffect] 未知技能: %s" % skill_id)
			_show_stat_popup(player_pos, STAT_GENERIC, 0.0, false, "获得新技能!")


## 解锁主动技能
func _unlock_active_skill(skill_id: String, skill_name: String) -> void:
	"""
	解锁主动技能
	@param skill_id: 技能ID
	@param skill_name: 技能名称（用于日志）
	"""
	if player == null or not is_instance_valid(player):
		print("[LevelUpEffect] 无法解锁技能: 玩家无效")
		return
	
	# 调用玩家的解锁技能方法
	if player.has_method("unlock_skill"):
		var success = player.unlock_skill(skill_id)
		if success:
			print("[LevelUpEffect] 技能解锁成功: %s (%s)" % [skill_name, skill_id])
		else:
			print("[LevelUpEffect] 技能解锁失败: %s (%s)" % [skill_name, skill_id])
	else:
		print("[LevelUpEffect] 玩家没有 unlock_skill 方法，无法解锁: %s" % skill_id)


## 显示属性变化浮动文字
func _show_stat_popup(pos: Vector2, stat_type: int, value: float, is_percent: bool, custom_text: String = "") -> void:
	"""
	显示属性变化浮动文字
	@param pos: 世界坐标位置
	@param stat_type: 属性类型 (StatType 枚举值)
	@param value: 数值
	@param is_percent: 是否为百分比
	@param custom_text: 自定义文本
	"""
	# 使用静态工厂方法创建浮动文字
	StatChangePopupScript.create_popup(
		get_tree().current_scene,
		pos,
		stat_type,
		value,
		is_percent,
		custom_text
	)

# =============================================================================
# 私有方法 - 工具
# =============================================================================

func _cleanup_effects() -> void:
	"""清理效果"""
	# 隐藏效果节点
	if _ring:
		_ring.hide()
	if _beam:
		_beam.hide()
	if _flash:
		_flash.hide()
	
	# 清理粒子
	for particle in _particles:
		if is_instance_valid(particle):
			particle.queue_free()
	_particles.clear()


func _get_camera() -> Camera2D:
	"""获取摄像机"""
	# 首先尝试从玩家获取
	if player and is_instance_valid(player):
		for child in player.get_children():
			if child is Camera2D:
				return child
	
	# 从场景中查找
	var cameras := get_tree().get_nodes_in_group("cameras")
	if not cameras.is_empty():
		return cameras[0]
	
	# 查找当前活动的摄像机
	return get_viewport().get_camera_2d()
